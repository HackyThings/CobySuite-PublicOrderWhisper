-------------------------------------------------------------------------------
-- PublicOrderWhisper Settings Window
--
-- The shell comes from CobySuite.UI.CreateWindow (solid background, drag,
-- saved position, Escape through UISpecialFrames, combat-safe close). The
-- form is built with CobySuite.UI.CreateFormLayout. Changes apply the
-- moment a control changes (no Stage/Apply), written through Config.Set.
-- The addon is also listed under Options > AddOns with a button that opens
-- this window (CobySuite.UI.RegisterSettingsCategory).
-------------------------------------------------------------------------------

local Config = PublicOrderWhisper.Config
local U = CobySuite.Utilities
local UI = CobySuite.UI

local WINDOW_W  = 480
local WINDOW_H  = 540   -- three sections and the footer button, no slack below
local PANEL_PAD = 16
local FORM_START_Y = -1              -- first header 15px higher than the builder default
local SECTION_GAP = 4                -- between a section's last row and the next header
local SECTION_DIVIDER_OFFSET = -7    -- divider 3px further below the section title than the default
local MESSAGE_BOX_HEIGHT = 64        -- three wrapped lines of the message at the larger font
local MESSAGE_FONT_SCALE = 1.1
local HINT_ROW = 18                  -- the placeholder legend under the message box
local PREVIEW_HEIGHT = 72            -- five wrapped lines: a 255-character message plus a link fits
local PREVIEW_ROW = 80
local TEST_BUTTON_ROW = 30
local FOOTER_BUTTON = { width = 130, height = 22, x = 12, y = 10 }
local RESET_POPUP = { width = 380, height = 120, textPad = 24 }

local frame
local widgets = {}
local resetPopup

-------------------------------------------------------------------------------
-- Preview: the template with sample values, as the customer would read it
-------------------------------------------------------------------------------
local function UpdatePreview(template)
  if not widgets.preview then return end
  template = template or Config.Get(Config.Options.WHISPER_MESSAGE) or ""
  if strtrim(template) == "" then
    widgets.preview:SetText(U.WrapColor("FF4C4C", "No message set; the whisper buttons will do nothing."))
    return
  end
  local Whisper = PublicOrderWhisper.Whisper
  local values = Whisper.SampleValues and Whisper.SampleValues() or {}
  local text = U.ExpandPlaceholders(template, values)
  local length = #text
  local suffix = ""
  if length > Config.MAX_MESSAGE_LENGTH then
    suffix = U.WrapColor("FF4C4C", (" (%d characters; WoW allows %d)"):format(length, Config.MAX_MESSAGE_LENGTH))
  end
  widgets.preview:SetText(U.WrapColor("AAAAAA", "Preview: ") .. text .. suffix)
end

-- keepFocusedMessage: leave the message box alone while it is being edited
-- (a slash command or reset arriving mid-edit must not clobber the typing).
local function Refresh(keepFocusedMessage)
  if not (keepFocusedMessage and widgets.message.EditBox:HasFocus()) then
    widgets.message:SetCommittedValue(Config.Get(Config.Options.WHISPER_MESSAGE))
  end
  widgets.showListButtons:SetChecked(Config.Get(Config.Options.SHOW_LIST_BUTTONS))
  widgets.showDetailButton:SetChecked(Config.Get(Config.Options.SHOW_DETAIL_BUTTON))
  widgets.markWhispered:SetChecked(Config.Get(Config.Options.MARK_WHISPERED))
  widgets.openInChat:SetChecked(Config.Get(Config.Options.OPEN_IN_CHAT))
  widgets.chatFeedback:SetChecked(Config.Get(Config.Options.CHAT_FEEDBACK))
  widgets.cooldown:SetValue(Config.Get(Config.Options.WHISPER_COOLDOWN))
  UpdatePreview()
end

-------------------------------------------------------------------------------
-- Reset confirmation (a custom popup, never StaticPopupDialogs)
-------------------------------------------------------------------------------
local function ShowResetPopup()
  if not resetPopup then
    -- A child of the settings window: it closes with it, opens centred on
    -- it, and can be dragged anywhere on screen.
    resetPopup = UI.CreateDialogPopup({
      name = "PublicOrderWhisperResetPopup",
      title = "Reset settings?",
      width = RESET_POPUP.width,
      height = RESET_POPUP.height,
      confirmText = "Reset",
      parent = frame,
      point = { "CENTER", frame, "CENTER", 0, 0 },
      movable = true,
    })
    local body = resetPopup:CreateFontString(nil, "OVERLAY", U.Fonts.BODY)
    body:SetPoint("TOP", resetPopup.Title, "BOTTOM", 0, -8)
    body:SetWidth(RESET_POPUP.width - 2 * RESET_POPUP.textPad)
    body:SetWordWrap(true)
    body:SetText("Every Public Order Whisper setting goes back to its default.")
    resetPopup.ConfirmButton:SetScript("OnClick", function()
      Config.Reset()   -- the ConfigChanged listener below refreshes the widgets
      resetPopup:Hide()
      PublicOrderWhisper.Utilities.Message("Settings restored to defaults.")
    end)
  end
  resetPopup:Show()
end

-------------------------------------------------------------------------------
-- Settings changed elsewhere (/pow message, /pow cooldown, /pow reset): keep
-- an open window in step, or a stale message box would commit the old text
-- back over the new value on its next Enter or focus loss.
-------------------------------------------------------------------------------
local configListener = {}

function configListener:ReceiveEvent()
  if frame and frame:IsShown() then
    Refresh(true)
  end
end

PublicOrderWhisper.EventBus:Register(configListener, { PublicOrderWhisper.Events.ConfigChanged })

-------------------------------------------------------------------------------
-- Frame construction
-------------------------------------------------------------------------------
local function BuildFrame()
  if frame then return frame end

  local f = UI.CreateWindow({
    name = "PublicOrderWhisperOptionsWindow",
    title = U.WrapColor(PublicOrderWhisper.BRAND_COLOR, "Public Order Whisper") .. " Settings",
    width = WINDOW_W,
    height = WINDOW_H,
    escapeCloses = true,
    persist = {
      svTable = function() return PUBLIC_ORDER_WHISPER_WINDOW_STATE end,
      key = "options",
      defaults = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
      fixedSize = true,   -- fixed layout: ignore any saved size
    },
  })
  f:SetScript("OnShow", function() Refresh() end)

  local content = CreateFrame("Frame", nil, f)
  content:SetPoint("TOPLEFT", 8, -28)
  content:SetSize(WINDOW_W - 16, WINDOW_H - 28 - 8)

  -- Label x, row height are the builder defaults.
  local form = UI.CreateFormLayout(content, {
    width          = WINDOW_W - 16,
    dividerPadding = PANEL_PAD,
    startY         = FORM_START_Y,
  })

  ---------------------------------------------------------------------------
  form:Section("Message", { dividerOffset = SECTION_DIVIDER_OFFSET })

  widgets.message = form:MultiLineInput{
    tooltip      = "What the whisper says. Press Enter or click elsewhere to save; Escape puts the saved text back. {item}, {name} and {tip} are filled in per order.",
    height       = MESSAGE_BOX_HEIGHT,
    fontScale    = MESSAGE_FONT_SCALE,
    maxLetters   = Config.MAX_MESSAGE_LENGTH,
    placeholder  = "Type the whisper",
    initialValue = Config.Get(Config.Options.WHISPER_MESSAGE),
    validate     = function(text) return text ~= "" end,
    onCommit     = function(text)
      -- The shared commit runs on every Enter and focus loss; only a real
      -- change is written, so an unchanged box never re-saves or logs.
      if text ~= Config.Get(Config.Options.WHISPER_MESSAGE) then
        Config.Set(Config.Options.WHISPER_MESSAGE, text)
      end
      UpdatePreview(text)
    end,
    onChange     = UpdatePreview,
  }
  -- An emptied box is put back to the saved text on focus loss without a
  -- commit or a user text change, so the preview is refreshed here too.
  widgets.message.EditBox:HookScript("OnEditFocusLost", function() UpdatePreview() end)

  form:Custom(function(parent, y, layout)
    local hint = parent:CreateFontString(nil, "OVERLAY", U.Fonts.DATA)
    hint:SetPoint("LEFT", parent, "TOPLEFT", layout.labelX, y)
    hint:SetText("{item} = crafted item link, {name} = customer's name, {tip} = the tip on the order")
    local c = U.Colors.LABEL_GRAY
    hint:SetTextColor(c[1], c[2], c[3])
    return y - HINT_ROW
  end)

  form:Custom(function(parent, y, layout)
    local preview = parent:CreateFontString(nil, "OVERLAY", U.Fonts.BODY)
    preview:SetPoint("TOPLEFT", parent, "TOPLEFT", layout.labelX, y + 7)
    preview:SetWidth(layout.width - 2 * layout.labelX)
    preview:SetHeight(PREVIEW_HEIGHT)
    preview:SetJustifyH("LEFT")
    preview:SetJustifyV("TOP")
    preview:SetWordWrap(true)
    widgets.preview = preview
    return y - PREVIEW_ROW
  end)

  form:Custom(function(parent, y, layout)
    UI.CreateButton(parent, {
      size    = { 220, 22 },
      text    = "Send a test whisper to yourself",
      tooltip = "Whispers you the message with an example item, your own name and a 150g tip, so you can see how it reads.",
      point   = { "LEFT", parent, "TOPLEFT", layout.labelX, y },
      onClick = function()
        if PublicOrderWhisper.Whisper.SendTest then
          PublicOrderWhisper.Whisper.SendTest()
        end
      end,
    })
    return y - TEST_BUTTON_ROW
  end)

  ---------------------------------------------------------------------------
  form:Section("Buttons", { gap = SECTION_GAP, dividerOffset = SECTION_DIVIDER_OFFSET })

  widgets.showListButtons = form:Checkbox{
    label        = "Whisper icon in the order list (Public tab)",
    tooltip      = "The chat bubble after the customer's name in the Public tab of the crafting orders list.",
    optionKey    = "SHOW_LIST_BUTTONS",
    initialValue = Config.Get(Config.Options.SHOW_LIST_BUTTONS),
    onChange     = function(v) Config.Set(Config.Options.SHOW_LIST_BUTTONS, v) end,
  }

  widgets.showDetailButton = form:Checkbox{
    label        = "Whisper icon on the order details page",
    tooltip      = "The chat bubble next to the customer's name on the page that opens when you click a public order.",
    optionKey    = "SHOW_DETAIL_BUTTON",
    initialValue = Config.Get(Config.Options.SHOW_DETAIL_BUTTON),
    onChange     = function(v) Config.Set(Config.Options.SHOW_DETAIL_BUTTON, v) end,
  }

  widgets.markWhispered = form:Checkbox{
    label        = "Turn the icon green for players whispered this session",
    tooltip      = "A green chat bubble means you already whispered that player since logging in. Off: the icon never changes colour.",
    optionKey    = "MARK_WHISPERED",
    initialValue = Config.Get(Config.Options.MARK_WHISPERED),
    onChange     = function(v) Config.Set(Config.Options.MARK_WHISPERED, v) end,
  }

  ---------------------------------------------------------------------------
  form:Section("Sending", { gap = SECTION_GAP, dividerOffset = SECTION_DIVIDER_OFFSET })

  widgets.openInChat = form:Checkbox{
    label        = "Put the whisper in my chat box instead of sending it",
    tooltip      = "Clicking an icon fills your chat box with the whisper, ready to edit. Press Enter to send it. Off: the whisper is sent right away.",
    optionKey    = "OPEN_IN_CHAT",
    initialValue = Config.Get(Config.Options.OPEN_IN_CHAT),
    onChange     = function(v) Config.Set(Config.Options.OPEN_IN_CHAT, v) end,
  }

  widgets.chatFeedback = form:Checkbox{
    label        = "Print a chat line for each whisper sent",
    tooltip      = "A short confirmation in your chat window after each whisper. Errors and failed whispers are always printed.",
    optionKey    = "CHAT_FEEDBACK",
    initialValue = Config.Get(Config.Options.CHAT_FEEDBACK),
    onChange     = function(v) Config.Set(Config.Options.CHAT_FEEDBACK, v) end,
  }

  widgets.cooldown = form:Slider{
    label        = "Cooldown per player",
    tooltip      = "How long after whispering someone the icon refuses to whisper them again. Off sends every click.",
    min          = 0,
    max          = Config.MAX_COOLDOWN,
    step         = 1,
    initialValue = Config.Get(Config.Options.WHISPER_COOLDOWN),
    format       = function(v) if v <= 0 then return "Off" end return ("%d s"):format(v) end,
    optionKey    = "WHISPER_COOLDOWN",
    onChange     = function(v) Config.Set(Config.Options.WHISPER_COOLDOWN, v) end,
  }

  ---------------------------------------------------------------------------
  UI.CreateButton(f, {
    size    = { FOOTER_BUTTON.width, FOOTER_BUTTON.height },
    text    = "Reset to defaults",
    point   = { "BOTTOMLEFT", FOOTER_BUTTON.x, FOOTER_BUTTON.y },
    onClick = ShowResetPopup,
  })

  frame = f
  return f
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------
local function CanBuild()
  if not frame and InCombatLockdown() then
    -- Root rule: no CreateFrame in combat. The window is built lazily, so
    -- refuse the first open until combat ends rather than deferring it.
    PublicOrderWhisper.Utilities.Message("The settings window opens after combat.")
    return false
  end
  return true
end

function Config.ToggleSettings()
  if not CanBuild() then return end
  BuildFrame():Toggle()
end

function Config.OpenSettings()
  if not CanBuild() then return end
  local f = BuildFrame()
  if not f:IsShown() then f:Toggle() end
end

-------------------------------------------------------------------------------
-- Options > AddOns entry (registered once this addon has finished loading)
-------------------------------------------------------------------------------
EventUtil.ContinueOnAddOnLoaded("PublicOrderWhisper", function()
  UI.RegisterSettingsCategory({
    name        = "Public Order Whisper",
    brandColor  = PublicOrderWhisper.BRAND_COLOR,
    version     = PublicOrderWhisper.VERSION,
    description = {
      "Adds a chat bubble to every public crafting order at a profession table. Click it to whisper the player who placed the order your message, with the item link filled in.",
      "The message, the whisper icons, the cooldown and the send behaviour live in the addon's own settings window.",
    },
    slash       = "/pow settings",
    onOpen      = Config.OpenSettings,
  })
end)
