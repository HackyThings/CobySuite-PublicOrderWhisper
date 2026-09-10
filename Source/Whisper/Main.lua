-------------------------------------------------------------------------------
-- PublicOrderWhisper: button injection + whisper logic
--
-- Hooks two locations in the Blizzard Professions crafting orders UI:
--   1. BrowseFrame OrderList: chat bubble icon after the customer name on
--      every row of the public orders list
--   2. OrderView OrderInfo: chat bubble icon next to the customer name on
--      the order details
-- plus a settings gear in the window's title bar, left of the close X,
-- shown only while the orders list is.
--
-- Only public orders placed by someone else get a button. The configured
-- message template has {item} replaced with the order's item link (at the
-- requested quality tier when the order asks for one), {name} with the
-- customer's name and {tip} with the tip offered.
-------------------------------------------------------------------------------

local Config = PublicOrderWhisper.Config
local Debug = PublicOrderWhisper.Debug
local U = CobySuite.Utilities
local UI = CobySuite.UI
local Whisper = PublicOrderWhisper.Whisper

local orderViewButton   -- button on the order detail view
local currentOrder      -- order currently shown in OrderView
local browseFrame       -- ProfessionsFrame.OrdersPage.BrowseFrame, set by SetupHooks
local refreshRowButtons -- Coalesce handle that re-lays the row buttons next frame

local whisperedPlayers = {}   -- [customerName] = true  (session-scoped)
local pendingWhispers  = {}   -- [customerName] = expireTime (failure detection window)
local lastWhisperTime  = {}   -- [customerName] = GetTime() (cooldown)
local relayAfterCombat = false -- a row needed a new button during combat
local UpdateAllVisibleButtons -- forward declaration (called by SendWhisperForOrder, defined below)

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local ROW_ICON_SIZE   = 20
local DETAIL_BTN_SIZE = 26
local FAILURE_WINDOW  = 3     -- seconds after a send in which a "player not found" counts
local FAILURE_FLASH   = 1.5   -- seconds the icon stays red after a failure

local TEX_NORMAL    = "Interface\\ChatFrame\\UI-ChatIcon-Chat-Up"
local TEX_HIGHLIGHT = "Interface\\ChatFrame\\UI-ChatIcon-Chat-Highlight"
local TEX_PUSHED    = "Interface\\ChatFrame\\UI-ChatIcon-Chat-Down"

-- The settings gear sits in the window's title bar, left of the close X
-- (or of the minimize button when Blizzard shows it), sized to the X.
local SETTINGS_BUTTON_GAP = -4    -- from the neighbour's left edge (in the gear's scaled space)
local SETTINGS_BUTTON_FALLBACK = { x = -12, y = -40 }   -- page top-right, if the title bar is missing

-- The test whisper and the settings preview use a real item link when the
-- client has it cached; the id is requested at load so it usually is.
local SAMPLE_ITEM_ID = 2589       -- Linen Cloth
local SAMPLE_ITEM_TEXT = "[Example Item]"
local SAMPLE_TIP_COPPER = 1500000 -- 150g

local COLOR_WHISPERED = U.Colors.SUCCESS_GREEN
local COLOR_DEFAULT   = U.Colors.HIGHLIGHT_WHITE
local COLOR_FAILED    = U.Colors.WARNING_RED

-- Locale-safe pattern for the "No player named X is currently playing"
-- system message: the format string with its %s turned into a capture.
local FAILURE_PATTERN = U.EscapePattern(ERR_CHAT_PLAYER_NOT_FOUND_S):gsub("%%%%s", "(.+)")

-------------------------------------------------------------------------------
-- Chat output. Errors always print; the per-whisper confirmation is gated by
-- the "chat line for each whisper" setting.
-------------------------------------------------------------------------------
local Message = PublicOrderWhisper.Utilities.Message

local function Notify(text)
  if Config.Get(Config.Options.CHAT_FEEDBACK) then
    Message(text)
  end
end

-------------------------------------------------------------------------------
-- Order checks
-------------------------------------------------------------------------------
local function IsPublicOrder(order)
  return order.orderType == Enum.CraftingOrderType.Public
end

-- Your own public orders show in the list too; there is nobody to whisper.
local function IsOwnOrder(order)
  return order.customerGuid ~= nil and order.customerGuid == UnitGUID("player")
end

local function CanWhisper(order)
  return order ~= nil
     and IsPublicOrder(order)
     and order.customerName ~= nil and order.customerName ~= ""
     and not IsOwnOrder(order)
end

-------------------------------------------------------------------------------
-- Extract order data from a row's elementData
-------------------------------------------------------------------------------
local function GetOrderFromElementData(elementData)
  if not elementData then return nil end
  if elementData.orderID then return elementData end
  if elementData.data and elementData.data.orderID then return elementData.data end
  if elementData.option and elementData.option.orderID then return elementData.option end
  return nil
end

-------------------------------------------------------------------------------
-- Find the customer name FontString on a row (the cell whose text is the
-- name). Blizzard's table builder gives the cells no keys, so the text is
-- the only handle. An exact match wins: the item cell is built before the
-- customer cell, and a customer named like a word of the item ("Silk" on a
-- Silk item) would otherwise put the bubble on the item.
-------------------------------------------------------------------------------
local function FindFontString(row, accept)
  for _, child in ipairs({row:GetChildren()}) do
    for _, region in ipairs({child:GetRegions()}) do
      if region:IsObjectType("FontString") and accept(region:GetText()) then
        return region
      end
    end
  end
  for _, region in ipairs({row:GetRegions()}) do
    if region:IsObjectType("FontString") and accept(region:GetText()) then
      return region
    end
  end
  return nil
end

local function FindPlayerNameRegion(row, customerName)
  return FindFontString(row, function(text) return text == customerName end)
      or FindFontString(row, function(text) return text ~= nil and text:find(customerName, 1, true) ~= nil end)
end

-------------------------------------------------------------------------------
-- Placeholder values for the settings preview and the test whisper
-------------------------------------------------------------------------------
function Whisper.SampleValues()
  local _, link = C_Item.GetItemInfo(SAMPLE_ITEM_ID)
  return {
    item = link or SAMPLE_ITEM_TEXT,
    name = UnitName("player"),
    tip  = U.FormatMoneyText(SAMPLE_TIP_COPPER),
  }
end

-------------------------------------------------------------------------------
-- Resolve the order's item link.
--
-- Resolution order:
--   1. Quality-tier item ID via GetRecipeQualityItemIDs (when minQuality set)
--   2. GetRecipeOutputItemData with the mapped quality ID from GetQualitiesForRecipe
--   3. outputItemHyperlink from the order data
--   4. recraftItemHyperlink for recraft orders
--   5. Generic C_Item.GetItemInfo fallback (base quality, last resort)
-------------------------------------------------------------------------------
local function ResolveItemLink(order)
  local itemDisplay
  local source = "none"

  if order.spellID and order.minQuality and order.minQuality > 0 then
    -- Quality-tier item IDs: array indexed 1-5, matching minQuality directly
    local ok, qualityItemIDs = pcall(C_TradeSkillUI.GetRecipeQualityItemIDs, order.spellID)
    if ok and qualityItemIDs and qualityItemIDs[order.minQuality] then
      local qualityItemID = qualityItemIDs[order.minQuality]
      local _, link = C_Item.GetItemInfo(qualityItemID)
      if link then
        itemDisplay = link
        source = ("QualityItemIDs(q%d, itemID=%d)"):format(order.minQuality, qualityItemID)
      end
    end

    -- overrideQualityID expects an internal quality ID, not the 1-5 tier index
    if not itemDisplay or itemDisplay == "" then
      local qok, qualityIDs = pcall(C_TradeSkillUI.GetQualitiesForRecipe, order.spellID)
      local overrideQID = qok and qualityIDs and qualityIDs[order.minQuality]
      if overrideQID then
        local ok2, outputData = pcall(C_TradeSkillUI.GetRecipeOutputItemData,
          order.spellID, nil, nil, overrideQID)
        if ok2 and outputData and outputData.hyperlink and outputData.hyperlink ~= "" then
          itemDisplay = outputData.hyperlink
          source = ("RecipeOutputItemData(q%d, qid=%d)"):format(order.minQuality, overrideQID)
        end
      end
    end
  end

  if not itemDisplay or itemDisplay == "" then
    itemDisplay = order.outputItemHyperlink
    if itemDisplay and itemDisplay ~= "" then
      source = "outputItemHyperlink"
    end
  end

  -- Recraft orders store the link in recraftItemHyperlink instead
  if (not itemDisplay or itemDisplay == "") and order.recraftItemHyperlink then
    itemDisplay = order.recraftItemHyperlink
    source = "recraftItemHyperlink"
  end

  -- Last resort: generic lookup (may not reflect the requested quality)
  if (not itemDisplay or itemDisplay == "") and order.itemID then
    local name, link = C_Item.GetItemInfo(order.itemID)
    itemDisplay = link or name
    source = "C_Item.GetItemInfo(fallback)"
  end

  Debug.Log("WHISPER", "Item link resolved via %s: %s (orderID=%s, itemID=%s, spellID=%s, minQuality=%s, isRecraft=%s)",
    source, tostring(itemDisplay), tostring(order.orderID),
    tostring(order.itemID), tostring(order.spellID), tostring(order.minQuality),
    tostring(order.isRecraft))

  return itemDisplay or "your item"
end

-------------------------------------------------------------------------------
-- Build the whisper message for an order. nil when no message is configured.
-------------------------------------------------------------------------------
local function BuildMessage(order)
  local template = Config.Get(Config.Options.WHISPER_MESSAGE)
  if not template or strtrim(template) == "" then
    return nil
  end
  return U.ExpandPlaceholders(template, {
    item = ResolveItemLink(order),
    name = Ambiguate(order.customerName, "short"),
    tip  = U.FormatMoneyText(order.tipAmount),
  })
end

-------------------------------------------------------------------------------
-- Send whisper for a given order
-------------------------------------------------------------------------------
local function SendWhisperForOrder(order)
  if not order then
    Debug.Warn("WHISPER", "SendWhisperForOrder: no order data")
    return
  end

  local customerName = order.customerName
  if not customerName or customerName == "" then
    Message("Cannot whisper: this order has no customer name.")
    return
  end

  local cooldown = Config.Get(Config.Options.WHISPER_COOLDOWN) or 0
  local lastTime = lastWhisperTime[customerName]
  if cooldown > 0 and lastTime and (GetTime() - lastTime) < cooldown then
    local remaining = math.ceil(cooldown - (GetTime() - lastTime))
    Message(("Cooldown: wait %ds before whispering %s again."):format(remaining, customerName))
    return
  end

  local message = BuildMessage(order)
  if not message then
    Message("No message configured. Set one in /pow settings.")
    return
  end

  if #message > Config.MAX_MESSAGE_LENGTH then
    Message(("Whisper not sent: with the item link it is %d characters and WoW allows %d. Shorten the message in /pow settings.")
      :format(#message, Config.MAX_MESSAGE_LENGTH))
    Debug.Warn("WHISPER", "Message too long for %s (%d chars)", customerName, #message)
    return
  end

  if Config.Get(Config.Options.OPEN_IN_CHAT) then
    CobySuite.Chat.ComposeWhisper(customerName, message)
    Debug.Log("WHISPER", "Opened in chat box for %s: %s", customerName, message)
    Notify("Whisper to " .. customerName .. " is in your chat box. Press Enter to send it.")
    return
  end

  C_ChatInfo.SendChatMessage(message, "WHISPER", nil, customerName)
  Debug.Log("WHISPER", "Sent to %s: %s", customerName, message)
  Notify("Whispered " .. customerName .. ".")

  -- Track this whisper
  whisperedPlayers[customerName] = true
  lastWhisperTime[customerName] = GetTime()
  pendingWhispers[customerName] = GetTime() + FAILURE_WINDOW
  C_Timer.After(FAILURE_WINDOW + 0.5, function()
    if pendingWhispers[customerName] then
      pendingWhispers[customerName] = nil
    end
  end)

  PublicOrderWhisper.EventBus:Fire(PublicOrderWhisper.Events.WhisperSent, customerName)
  UpdateAllVisibleButtons(customerName)
end

-------------------------------------------------------------------------------
-- Test whisper: the current message with sample values, sent to yourself.
-- Skips the cooldown, the tracking and the chat-box setting so the result
-- is always a whisper you can read back.
-------------------------------------------------------------------------------
function Whisper.SendTest()
  local template = Config.Get(Config.Options.WHISPER_MESSAGE)
  if not template or strtrim(template) == "" then
    Message("No message configured. Set one in /pow settings.")
    return
  end
  local message = U.ExpandPlaceholders(template, Whisper.SampleValues())
  if #message > Config.MAX_MESSAGE_LENGTH then
    Message(("Test not sent: with the item link the message is %d characters and WoW allows %d.")
      :format(#message, Config.MAX_MESSAGE_LENGTH))
    return
  end
  C_ChatInfo.SendChatMessage(message, "WHISPER", nil, UnitName("player"))
  Debug.Log("WHISPER", "Test whisper sent: %s", message)
end

-------------------------------------------------------------------------------
-- Button tooltip (built per hover, so it follows the settings)
-------------------------------------------------------------------------------
local function BuildWhisperTooltip(tooltip, customerName)
  tooltip:SetText("Whisper " .. (customerName and Ambiguate(customerName, "short") or ""), 1, 1, 1)
  local template = Config.Get(Config.Options.WHISPER_MESSAGE)
  if template and strtrim(template) ~= "" then
    tooltip:AddLine(template, 0.8, 0.8, 0.8, true)
  else
    tooltip:AddLine("No message set. Open /pow settings.", 1, 0.3, 0.3, true)
  end
  tooltip:AddLine(" ")
  if Config.Get(Config.Options.OPEN_IN_CHAT) then
    tooltip:AddLine("Click to put the whisper in your chat box.", 0.5, 0.8, 1.0)
  else
    tooltip:AddLine("Click to send.", 0.5, 0.8, 1.0)
  end
  if customerName and whisperedPlayers[customerName] then
    tooltip:AddLine("Already whispered this session.", 0, 1, 0)
  end
end

-------------------------------------------------------------------------------
-- Chat-bubble icon buttons and their tinting
-------------------------------------------------------------------------------
local function CreateChatBubbleButton(parent, size)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetSize(size, size)
  btn:SetNormalTexture(TEX_NORMAL)
  btn:SetHighlightTexture(TEX_HIGHLIGHT)
  btn:SetPushedTexture(TEX_PUSHED)
  return btn
end

local function TintChatBubble(btn, r, g, b)
  local norm = btn:GetNormalTexture()
  if norm then norm:SetVertexColor(r, g, b) end
  local push = btn:GetPushedTexture()
  if push then push:SetVertexColor(r, g, b) end
end

local function UpdateButtonColor(btn, customerName)
  if whisperedPlayers[customerName] and Config.Get(Config.Options.MARK_WHISPERED) then
    TintChatBubble(btn, unpack(COLOR_WHISPERED))
  else
    TintChatBubble(btn, unpack(COLOR_DEFAULT))
  end
end

-- Run fn on every visible button that belongs to customerName.
local function ForEachButtonOf(customerName, fn)
  if orderViewButton and orderViewButton:IsShown() and currentOrder
     and currentOrder.customerName == customerName then
    fn(orderViewButton)
  end
  local scrollBox = browseFrame and browseFrame.OrderList and browseFrame.OrderList.ScrollBox
  if scrollBox then
    scrollBox:ForEachFrame(function(row)
      local btn = row._powWhisperBtn
      if btn and btn:IsShown() and btn._powOrder and btn._powOrder.customerName == customerName then
        fn(btn)
      end
    end)
  end
end

UpdateAllVisibleButtons = function(customerName)
  ForEachButtonOf(customerName, function(btn)
    UpdateButtonColor(btn, customerName)
  end)
end

-------------------------------------------------------------------------------
-- Browse list rows
-------------------------------------------------------------------------------
local function SetupRowWhisperButton(row, order)
  if not Config.Get(Config.Options.SHOW_LIST_BUTTONS) or not CanWhisper(order) then
    if row._powWhisperBtn then row._powWhisperBtn:Hide() end
    return
  end

  local customerName = order.customerName
  local nameRegion = FindPlayerNameRegion(row, customerName)
  if not nameRegion then
    Debug.Warn("WHISPER", "Could not find the customer name cell for %s", customerName)
    if row._powWhisperBtn then row._powWhisperBtn:Hide() end
    return
  end

  local btn = row._powWhisperBtn
  if not btn then
    if InCombatLockdown() then
      -- Root rule: no CreateFrame in combat. Blizzard keeps the orders
      -- window open through combat and a scroll or search still re-lays
      -- the rows, so a never-used row waits for PLAYER_REGEN_ENABLED.
      relayAfterCombat = true
      return
    end
    btn = CreateChatBubbleButton(row, ROW_ICON_SIZE)
    btn:SetFrameLevel(row:GetFrameLevel() + 5)
    btn:SetScript("OnClick", function(b)
      if b._powOrder then
        SendWhisperForOrder(b._powOrder)
      end
    end)
    UI.AddDynamicTooltip(btn, function(tooltip, b)
      BuildWhisperTooltip(tooltip, b._powOrder and b._powOrder.customerName)
    end)
    row._powWhisperBtn = btn
  end

  btn:ClearAllPoints()
  btn:SetPoint("RIGHT", nameRegion, "RIGHT", -2, 0)
  btn._powOrder = order
  btn:Show()
  UpdateButtonColor(btn, customerName)
end

-------------------------------------------------------------------------------
-- Order view (details): chat bubble icon next to the customer name
-------------------------------------------------------------------------------
local function CreateOrderViewButton(orderInfo)
  local btn = CreateChatBubbleButton(orderInfo, DETAIL_BTN_SIZE)

  -- Blizzard's social dropdown follows the customer name; sit after it.
  if orderInfo.SocialDropdown then
    btn:SetPoint("LEFT", orderInfo.SocialDropdown, "RIGHT", 4, 0)
  elseif orderInfo.PostedByValue then
    btn:SetPoint("LEFT", orderInfo.PostedByValue, "RIGHT", 6, 0)
  else
    btn:SetPoint("TOP", orderInfo, "TOP", 0, -60)
  end

  btn:SetScript("OnClick", function()
    SendWhisperForOrder(currentOrder)
  end)
  UI.AddDynamicTooltip(btn, function(tooltip)
    BuildWhisperTooltip(tooltip, currentOrder and currentOrder.customerName)
  end)
  btn:Hide()

  orderViewButton = btn
  Debug.Log("INIT", "Order detail whisper button created")
  return btn
end

local function RefreshOrderViewButton()
  if not orderViewButton then return end
  local show = Config.Get(Config.Options.SHOW_DETAIL_BUTTON) and CanWhisper(currentOrder)
  orderViewButton:SetShown(show)
  if show then
    UpdateButtonColor(orderViewButton, currentOrder.customerName)
  end
end

-------------------------------------------------------------------------------
-- Settings gear placement: left of the minimize button when Blizzard shows
-- it, else left of the close X; page top-right if neither exists.
-------------------------------------------------------------------------------
local settingsButton

local function PositionSettingsButton()
  if not settingsButton then return end
  local minimize = ProfessionsFrame.MaximizeMinimize
  local closeButton = ProfessionsFrame.CloseButton
  local neighbour = (minimize and minimize:IsShown() and minimize) or closeButton
  settingsButton:ClearAllPoints()
  if neighbour then
    settingsButton:SetPoint("RIGHT", neighbour, "LEFT", SETTINGS_BUTTON_GAP, 0)
  else
    settingsButton:SetPoint("TOPRIGHT", browseFrame, "TOPRIGHT", SETTINGS_BUTTON_FALLBACK.x, SETTINGS_BUTTON_FALLBACK.y)
  end
end

-------------------------------------------------------------------------------
-- Hook into Blizzard Professions UI
-------------------------------------------------------------------------------
local function SetupHooks()
  local ordersPage = ProfessionsFrame and ProfessionsFrame.OrdersPage
  if not ordersPage then
    Debug.Warn("INIT", "ProfessionsFrame.OrdersPage not found")
    return
  end

  -- Order view (details) button
  local orderView = ordersPage.OrderView
  if orderView then
    if orderView.OrderInfo then
      CreateOrderViewButton(orderView.OrderInfo)
    else
      Debug.Warn("INIT", "OrderView.OrderInfo not found; detail button not created")
    end

    hooksecurefunc(orderView, "SetOrder", function(_, order)
      currentOrder = order
      RefreshOrderViewButton()
    end)
  end

  -- Browse list: a whisper button on each row, and the settings gear
  browseFrame = ordersPage.BrowseFrame
  if browseFrame and browseFrame.OrderList then
    local scrollBox = browseFrame.OrderList.ScrollBox
    if scrollBox then
      -- One refresh on the next frame no matter how many hooks fire before it
      refreshRowButtons = U.Coalesce(0, function()
        if not browseFrame:IsShown() then return end
        scrollBox:ForEachFrame(function(row)
          local elementData = row.GetElementData and row:GetElementData()
          if elementData then
            SetupRowWhisperButton(row, GetOrderFromElementData(elementData))
          end
        end)
      end)
      local function ScheduleButtonRefresh()
        refreshRowButtons:Call()
      end

      -- Data changes (orders loaded, tab switch, refresh) and scrolling
      hooksecurefunc(scrollBox, "SetDataProvider", ScheduleButtonRefresh)
      if scrollBox.SetScrollPercentage then
        hooksecurefunc(scrollBox, "SetScrollPercentage", ScheduleButtonRefresh)
      end
      Debug.Log("INIT", "Button refresh hooks registered for browse list")
    end

    -- Settings gear in the title bar, sized to the close X. Parented to the
    -- browse frame so it shows only with the orders list.
    local closeButton = ProfessionsFrame.CloseButton
    settingsButton = UI.CreateSettingsGearButton(browseFrame, {
      name = "PublicOrderWhisperSettingsButton",
      height = closeButton and closeButton:GetHeight() or nil,
      tooltip = "Public Order Whisper settings",
      tooltipAnchor = "ANCHOR_LEFT",
      onClick = Config.ToggleSettings,
    })
    PositionSettingsButton()

    -- Returning to the list: hide the detail button, re-anchor the gear,
    -- and re-lay the rows (a setting toggled while an order was open was
    -- dropped by the IsShown guard above, and Blizzard's refresh after a
    -- "load more" appends in place without a data-provider swap)
    hooksecurefunc(browseFrame, "Show", function()
      currentOrder = nil
      RefreshOrderViewButton()
      PositionSettingsButton()
      if refreshRowButtons then refreshRowButtons:Call() end
    end)
  end

  Debug.Log("INIT", "All hooks installed; whisper ready")
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_Professions", SetupHooks)

-- Rows that needed a new button during combat are laid out once it ends.
local regenFrame = CreateFrame("Frame")
regenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
regenFrame:SetScript("OnEvent", function()
  if relayAfterCombat then
    relayAfterCombat = false
    if refreshRowButtons then refreshRowButtons:Call() end
  end
end)

-- Warm the item cache for the settings preview and the test whisper.
C_Item.RequestLoadItemDataByID(SAMPLE_ITEM_ID)

-------------------------------------------------------------------------------
-- Settings changes: re-lay the buttons that a toggled option affects
-------------------------------------------------------------------------------
local configListener = {}

function configListener:ReceiveEvent(event, name)
  if event ~= PublicOrderWhisper.Events.ConfigChanged then return end
  local O = Config.Options
  if name == nil or name == O.SHOW_LIST_BUTTONS or name == O.MARK_WHISPERED then
    if refreshRowButtons then refreshRowButtons:Call() end
  end
  if name == nil or name == O.SHOW_DETAIL_BUTTON or name == O.MARK_WHISPERED then
    RefreshOrderViewButton()
  end
end

PublicOrderWhisper.EventBus:Register(configListener, { PublicOrderWhisper.Events.ConfigChanged })

-------------------------------------------------------------------------------
-- Whisper failure detection via CHAT_MSG_SYSTEM
--
-- When a whisper fails (player offline / does not exist), WoW prints a
-- system message. Within a short window after sending, that reverts the
-- tracking, flashes the icon red and tells the user.
-------------------------------------------------------------------------------
local failureFrame = CreateFrame("Frame")
failureFrame:RegisterEvent("CHAT_MSG_SYSTEM")
failureFrame:SetScript("OnEvent", function(_, event, message)
  if event ~= "CHAT_MSG_SYSTEM" then return end
  if not next(pendingWhispers) then return end

  -- string.match rather than message:match: system responses to our own
  -- whispers can be secret strings that forbid __index access.
  local failedName = string.match(message, FAILURE_PATTERN)
  if not failedName then return end

  local expireTime = pendingWhispers[failedName]
  if not expireTime then return end
  pendingWhispers[failedName] = nil
  if GetTime() > expireTime then return end

  whisperedPlayers[failedName] = nil

  Debug.Warn("WHISPER", "Whisper failed for %s: %s", failedName, message)
  Message(U.WrapColor("FF4C4C", failedName) .. " appears to be offline or does not exist.")
  PublicOrderWhisper.EventBus:Fire(PublicOrderWhisper.Events.WhisperFailed, failedName, message)

  ForEachButtonOf(failedName, function(btn)
    TintChatBubble(btn, unpack(COLOR_FAILED))
  end)
  C_Timer.After(FAILURE_FLASH, function()
    UpdateAllVisibleButtons(failedName)
  end)
end)

-------------------------------------------------------------------------------
-- Taint error suppression: MoneyFrame secret-value arithmetic
--
-- Addons that hook the crafting orders table builder (e.g. RECraft) call
-- tableBuilder:Arrange() inside a hooksecurefunc posthook, tainting the row
-- OnLineEnter execution context. When the tainted handler shows a tooltip
-- with a gold value, MoneyFrame_Update fails with:
--   "attempt to perform arithmetic on a secret number value"
--
-- The error is dropped in the global error handler rather than by wrapping
-- MoneyFrame_Update (which would itself spread taint to every MoneyFrame
-- caller). Error management addons (BugGrabber, Swatter) chain the handler
-- the same way; no Blizzard function is replaced.
-------------------------------------------------------------------------------
do
  local origErrorHandler = geterrorhandler()
  seterrorhandler(function(err, ...)
    if type(err) == "string"
       and err:find("MoneyFrame", 1, true)
       and err:find("secret number value", 1, true) then
      return
    end
    return origErrorHandler(err, ...)
  end)
end
