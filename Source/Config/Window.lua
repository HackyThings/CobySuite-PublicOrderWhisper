-------------------------------------------------------------------------------
-- PublicOrderWhisper Settings Window
--
-- The suite's standard settings window (CobySuite.UI.CreateSettingsWindow):
-- a sidebar with Message, Bubbles and Sending, staged edits that Apply
-- writes through Config.Set, Cancel, Defaults (with its own confirm popup)
-- and a Guide button that opens the feature guide (UI/Guide.lua).
--
-- The Message page reads the box's draft, not the staged value: the
-- examples, the byte meter and the test whisper follow what the box shows,
-- and an emptied box (which stages nothing) says so and sends no test.
-- Built at load, so opening it never creates frames in combat; the controls
-- are painted from config on every show, and a ConfigChanged event
-- (/pow message, /pow cooldown, /pow reset) repaints an open window. The
-- addon is also listed under Options > AddOns with a button that opens this
-- window (CobySuite.UI.RegisterSettingsCategory).
-------------------------------------------------------------------------------

local Config = PublicOrderWhisper.Config
local Opt = Config.Options
local U = CobySuite_PublicOrderWhisper.Utilities
local UI = CobySuite_PublicOrderWhisper.UI

local MESSAGE_BOX_HEIGHT = 64        -- three wrapped lines of the message at the larger font
local MESSAGE_FONT_SCALE = 1.1
local SKETCH_HEIGHT = 22             -- the little order row and order header on the Bubbles tiles
local TILE_HEIGHT = 92

local ICONS = "Interface\\Icons\\"
local BUBBLE = "Interface\\ChatFrame\\UI-ChatIcon-Chat-Up"
-- The name the examples greet: a customer's whisper, not one to yourself
local SAMPLE_CUSTOMER = "Customer"

-- Ready-made messages for the Start from list, in the order shown. The first
-- is the default message.
local STARTERS = {
  { label = "Friendly (the default)", text = Config.Defaults[Opt.WHISPER_MESSAGE] },
  { label = "Short and direct",       text = "I can make {item} for you. Send it to me as a personal order." },
  { label = "Greets them by name",    text = "Hi {name}! I can craft {item} for you, just send me a personal order." },
}

-------------------------------------------------------------------------------
-- The message box's draft and the examples built from it
-------------------------------------------------------------------------------
local window   -- the settings window, made below
local rows = {}  -- rows the suites and the screenshot catalog reach

-- The box's text as staging folds it (newlines to spaces, trimmed); "" when
-- empty or before the box exists
local function Draft()
  return rows.message and rows.message.GetDraft() or ""
end

-- The draft filled in for an order from SAMPLE_CUSTOMER with tipCopper (nil:
-- the sample 150g)
local function SampleMessage(tipCopper)
  local Whisper = PublicOrderWhisper.Whisper
  local values = Whisper.SampleValues and Whisper.SampleValues(SAMPLE_CUSTOMER, tipCopper) or {}
  return U.ExpandPlaceholders(Draft(), values)
end

-- The line the customer reads, as their chat shows a whisper from you
local function WhisperLine(message)
  local from = "[" .. (UnitName("player") or "You") .. "]"
  local prefix = CHAT_WHISPER_GET and CHAT_WHISPER_GET:format(from) or (from .. " whispers: ")
  return prefix .. message
end

local function WhisperColor()
  local info = ChatTypeInfo and ChatTypeInfo.WHISPER
  if info and info.r then return { info.r, info.g, info.b } end
  return { 1, 0.5, 1 }
end

local function HasDraft() return Draft() ~= "" end
-- Placeholders match in any case ({TIP} is filled in too), as the expander does
local function UsesTip() return Draft():lower():find("{tip}", 1, true) ~= nil end

-- A ready-made message into the box, staged (Cancel puts the saved one back)
local function UseStarter(text)
  window.MessageBox:SetCommittedValue(text)
  window:Stage(Opt.WHISPER_MESSAGE, text)
end

-------------------------------------------------------------------------------
-- Message
-------------------------------------------------------------------------------
local function BuildMessage(panel, w)
  panel:Section("Your whisper", { icon = ICONS .. "INV_Misc_Note_01" })

  -- The limit and the counter are in bytes, WoW's unit for a whisper
  rows.message = panel:MultiLine{
    key         = Opt.WHISPER_MESSAGE,
    tooltip     = "What the customer reads. Press Apply to save it.",
    description = "The counter is in bytes. Some characters use more than one byte.",
    height      = MESSAGE_BOX_HEIGHT,
    fontScale   = MESSAGE_FONT_SCALE,
    maxBytes    = Config.MAX_MESSAGE_LENGTH,
    placeholder = "Write your whisper here",
    validate    = function(text) return text ~= "" end,
    tokens = {
      { text = "{item}", label = "{item} Item link",
        tooltip = "The crafted item as a link, at the quality the order asks for when the game knows it." },
      { text = "{name}", label = "{name} Their name",
        tooltip = "The customer's name, without the realm when they're on yours." },
      { text = "{tip}", label = "{tip} Tip",
        tooltip = "The tip on the order, in gold and silver. An order with no tip reads 0g." },
    },
  }
  w.MessageBox = rows.message.Box   -- for the WhisperSuite

  rows.emptyNote = panel:Note{
    text = "Enter a message to apply. Until then your saved one stays.",
    color = U.Colors.WARNING_RED,
    visibleWhen = function() return not HasDraft() end,
  }

  rows.example = panel:Preview{
    caption = "Example",
    text = function() return WhisperLine(SampleMessage()) end,
    color = WhisperColor,
    visibleWhen = HasDraft,
  }
  rows.noTipExample = panel:Preview{
    caption = "Example of an order with no tip",
    text = function() return WhisperLine(SampleMessage(0)) end,
    color = WhisperColor,
    visibleWhen = function() return HasDraft() and UsesTip() end,
  }

  rows.meter = panel:Meter{
    label = "Length",
    value = function() return #SampleMessage() end,
    max = Config.MAX_MESSAGE_LENGTH,
    warnAt = 0.8,
    format = function(used, max)
      local text = ("Sample message: %d / %d bytes"):format(used, max)
      if used > max then return U.WrapColor(U.Colors.WARNING_RED, text) end
      return text
    end,
    description = "Actual length varies by order. A whisper that runs over is not sent, and chat says so.",
    visibleWhen = HasDraft,
  }

  rows.testButton = panel:Button{
    text = "Send test to myself",
    width = 180,
    icon = BUBBLE,
    tooltip = "Whispers you the message in the box, with a sample item and a 150g tip, even before you press Apply.",
    enabledWhen = function() return HasDraft() end,
    onClick = function()
      local draft = Draft()
      if draft ~= "" and PublicOrderWhisper.Whisper.SendTest then
        PublicOrderWhisper.Whisper.SendTest(draft)
      end
    end,
  }

  panel:Section("Ready-made messages", { icon = ICONS .. "INV_Misc_Book_09" })
  rows.starter = panel:DropdownAction{
    label = "Start from",
    options = function()
      local labels, values = {}, {}
      for i, starter in ipairs(STARTERS) do
        labels[i], values[i] = starter.label, starter.text
      end
      return labels, values
    end,
    buttonText = "Use this message",
    buttonTooltip = "Puts this message in the box. Nothing is saved until you press Apply.",
    onClick = function(text) UseStarter(text) end,
    description = "Pick one, then make it yours.",
  }
end

-------------------------------------------------------------------------------
-- Bubbles
-------------------------------------------------------------------------------
-- A tile's sketch: a strip with gray words and the bubble where the addon
-- puts it. Regions only, since a tile's first paint may come in combat.
local function Sketch(frame, parts)
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  local c = U.Colors.CONTENT_BG
  bg:SetColorTexture(c[1], c[2], c[3], 0.6)
  local x = 6
  for _, part in ipairs(parts) do
    if part == "bubble" then
      local bubble = frame:CreateTexture(nil, "ARTWORK")
      bubble:SetSize(14, 14)
      bubble:SetPoint("LEFT", frame, "LEFT", x, 0)
      bubble:SetTexture(BUBBLE)
      frame.Bubble = bubble
      x = x + 14 + 8
    else
      local text = frame:CreateFontString(nil, "OVERLAY", U.Fonts.DATA)
      text:SetPoint("LEFT", frame, "LEFT", x, 0)
      text:SetText(part.text)
      local color = part.color or U.Colors.LABEL_GRAY
      text:SetTextColor(color[1], color[2], color[3])
      x = x + math.ceil(text:GetStringWidth()) + (part.gap or 6)
    end
  end
end

-- An unchecked tile's bubble is gray, as if it were not there
local function PaintSketch(frame, on)
  if frame.Bubble then frame.Bubble:SetDesaturated(not on) end
  frame:SetAlpha(on and 1 or 0.5)
end

local function BuildBubbles(panel)
  panel:Section("Where the bubble shows", { icon = PublicOrderWhisper.ICON })
  rows.tiles = panel:ToggleTiles{
    height = TILE_HEIGHT,
    options = {
      {
        key = Opt.SHOW_LIST_BUTTONS,
        title = "In the order list",
        description = "After the customer's name on each public order.",
        tooltip = "The bubble on every row of the Public tab.",
        previewHeight = SKETCH_HEIGHT,
        preview = function(frame)
          Sketch(frame, { { text = "Crafted item", gap = 14 }, { text = "Customer", color = U.Colors.HIGHLIGHT_WHITE }, "bubble" })
        end,
        previewPaint = PaintSketch,
      },
      {
        key = Opt.SHOW_DETAIL_BUTTON,
        title = "On an open order",
        description = "Beside the customer's name when you open an order.",
        tooltip = "The bubble on the page that opens when you click a public order.",
        previewHeight = SKETCH_HEIGHT,
        preview = function(frame)
          Sketch(frame, { { text = "Customer:", color = U.Colors.STATUS_GOLD }, { text = "Name", color = U.Colors.HIGHLIGHT_WHITE }, "bubble" })
        end,
        previewPaint = PaintSketch,
      },
    },
  }
  panel:Note{
    text = "Both bubbles are off, so there is nothing to click. Send test to myself still works.",
    color = U.Colors.CAUTION_ORANGE,
    visibleWhen = function(get) return not get(Opt.SHOW_LIST_BUTTONS) and not get(Opt.SHOW_DETAIL_BUTTON) end,
  }
  panel:Note{
    text = "Your own orders never get a bubble, and personal or guild orders don't either.",
  }
end

-------------------------------------------------------------------------------
-- Sending
-------------------------------------------------------------------------------
local function BuildSending(panel)
  panel:Section("When you click a bubble", { icon = BUBBLE })
  panel:Radio{
    key = Opt.OPEN_IN_CHAT,
    options = {
      { value = false, label = "Send it right away",
        description = "The customer gets your whisper the moment you click." },
      { value = true, label = "Put it in my chat box first",
        description = "Your chat box opens with the whisper, ready to change. Press Enter to send it." },
    },
  }
  panel:Checkbox{
    key = Opt.CHAT_FEEDBACK, label = "Confirm each whisper in chat",
    description = "A short line after each whisper, or when one is waiting in your chat box. Problems always print.",
  }

  panel:Section("Keeping track", { icon = ICONS .. "INV_Misc_PocketWatch_01" })
  panel:Legend{
    items = {
      { icon = BUBBLE, color = U.Colors.HIGHLIGHT_WHITE, label = "Ready" },
      { icon = BUBBLE, color = U.Colors.SUCCESS_GREEN, label = "Whispered this session" },
      { icon = BUBBLE, color = U.Colors.WARNING_RED, label = "Offline or not found" },
    },
  }
  panel:Checkbox{
    key = Opt.MARK_WHISPERED, label = "Turn the bubble green after a whisper",
    description = "Green clears when you log out or reload. A failed whisper still flashes red when this is off.",
  }
  rows.cooldown = panel:Slider{
    key = Opt.WHISPER_COOLDOWN, label = "Wait before whispering the same player again",
    tooltip = "Stops a double click from whispering someone twice. Off lets every click through.",
    min = 0, max = Config.MAX_COOLDOWN, step = 1,
    minLabel = "Off", maxLabel = "2 min",
    format = function(v) if v <= 0 then return "Off" end return ("%d s"):format(v) end,
  }
  panel:Note{
    text = "Composing creates no new green marks or cooldowns. Marks and cooldowns from earlier whispers stay.",
    visibleWhen = function(get) return get(Opt.OPEN_IN_CHAT) and true or false end,
  }
end

window = UI.CreateSettingsWindow({
  name    = "PublicOrderWhisperOptionsWindow",
  title   = U.WrapColor(PublicOrderWhisper.BRAND_COLOR, "Coby's Public Order Whisper") .. " Settings",
  icon    = PublicOrderWhisper.ICON,
  config  = Config,
  size    = "compact",
  persist = {
    svTable = function() return PUBLIC_ORDER_WHISPER_WINDOW_STATE end,
    key = "options",
  },
  watch   = { bus = PublicOrderWhisper.EventBus, event = PublicOrderWhisper.Events.ConfigChanged },
  message = function(text) PublicOrderWhisper.Utilities.Message(text) end,
  footerButtons = {
    {
      text = "Guide", width = 80,
      tooltip = "Open the feature guide: the whisper bubbles, your message, and what the colors mean.",
      onClick = function() if PublicOrderWhisper.Guide then PublicOrderWhisper.Guide.Toggle() end end,
    },
  },
  categories = {
    { key = "message", label = "Message", build = BuildMessage },
    { key = "buttons", label = "Bubbles", build = BuildBubbles },
    { key = "sending", label = "Sending", build = BuildSending },
  },
})

-- The page's pieces, for the suites
Config._window = { window = window, rows = rows, Draft = Draft, UseStarter = UseStarter, STARTERS = STARTERS }

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------
function Config.ToggleSettings()
  window:Toggle()
end

function Config.OpenSettings()
  window:Open()
end

-------------------------------------------------------------------------------
-- Options > AddOns entry (registered once this addon has finished loading)
-------------------------------------------------------------------------------
EventUtil.ContinueOnAddOnLoaded("PublicOrderWhisper", function()
  UI.RegisterSettingsCategory({
    name        = "Coby's Public Order Whisper",
    brandColor  = PublicOrderWhisper.BRAND_COLOR,
    version     = PublicOrderWhisper.VERSION,
    description = {
      "Adds a whisper button to public crafting orders that sends your message, with the item link, to the player who placed the order.",
      "The settings live in the addon's own settings window.",
    },
    slash       = "/pow settings",
    onOpen      = Config.OpenSettings,
  })
end)
