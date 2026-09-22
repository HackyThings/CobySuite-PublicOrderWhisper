-------------------------------------------------------------------------------
-- PublicOrderWhisper Settings Window
--
-- The suite's standard settings window (CobySuite.UI.CreateSettingsWindow):
-- a sidebar with Message, Buttons and Sending, staged edits that Apply
-- writes through Config.Set, Cancel, and Defaults (with its own confirm
-- popup). The message preview and the test whisper follow the staged text,
-- so they show what Apply would save. Built at load, so opening it never
-- creates frames in combat; the controls are painted from config on every
-- show, and a ConfigChanged event (/pow message, /pow cooldown, /pow reset)
-- repaints an open window. The addon is also listed under Options > AddOns
-- with a button that opens this window (CobySuite.UI.RegisterSettingsCategory).
-------------------------------------------------------------------------------

local Config = PublicOrderWhisper.Config
local Opt = Config.Options
local U = CobySuite_PublicOrderWhisper.Utilities
local UI = CobySuite_PublicOrderWhisper.UI

local WINDOW_W = 640
local WINDOW_H = 440
local MESSAGE_BOX_HEIGHT = 64        -- three wrapped lines of the message at the larger font
local MESSAGE_FONT_SCALE = 1.1
local LEGEND_ROW = 34                -- the placeholder legend under the message box, up to two lines
local PREVIEW_HEIGHT = 72            -- five wrapped lines: a 255-byte message plus a link fits
local PREVIEW_ROW = 80

-------------------------------------------------------------------------------
-- Preview: the template with sample values, as the customer would read it
-------------------------------------------------------------------------------
local function PreviewText(template)
  template = template or ""
  if strtrim(template) == "" then
    return U.WrapColor("FF4C4C", "No message set; the whisper buttons will do nothing.")
  end
  local Whisper = PublicOrderWhisper.Whisper
  local values = Whisper.SampleValues and Whisper.SampleValues() or {}
  local text = U.ExpandPlaceholders(template, values)
  local length = #text   -- bytes, the unit of WoW's limit
  local suffix = ""
  if length > Config.MAX_MESSAGE_LENGTH then
    suffix = U.WrapColor("FF4C4C", (" (%d bytes and WoW allows %d; accented letters count as two)"):format(length, Config.MAX_MESSAGE_LENGTH))
  end
  return U.WrapColor("AAAAAA", "Preview: ") .. text .. suffix
end

local function BuildMessage(panel, window)
  local layout = panel.layout
  local textWidth = layout.inputX(0) - layout.pad

  panel:Section("Message")

  -- The limit and the counter are in bytes, WoW's unit for a whisper, so
  -- the box and the send check agree on text with accented letters
  local messageRow = panel:MultiLine{
    key         = Opt.WHISPER_MESSAGE,
    tooltip     = "What the whisper says. Press Apply to save it. {item}, {name} and {tip} are filled in per order. The counter shows bytes: accented letters count as two.",
    height      = MESSAGE_BOX_HEIGHT,
    fontScale   = MESSAGE_FONT_SCALE,
    maxBytes    = Config.MAX_MESSAGE_LENGTH,
    placeholder = "Type the whisper",
    validate    = function(text) return text ~= "" end,
  }
  window.MessageBox = messageRow.Box   -- for the WhisperSuite

  panel:Custom{
    height = LEGEND_ROW,
    build = function(row)
      local legend = row:CreateFontString(nil, "OVERLAY", U.Fonts.DATA)
      legend:SetPoint("TOPLEFT", row, "TOPLEFT", layout.pad, -2)
      legend:SetWidth(textWidth)
      legend:SetJustifyH("LEFT")
      legend:SetWordWrap(true)
      legend:SetText("{item} = crafted item link, {name} = customer's name, {tip} = the tip on the order")
      local c = U.Colors.LABEL_GRAY
      legend:SetTextColor(c[1], c[2], c[3])
      row.Legend = legend
    end,
  }

  panel:Custom{
    height = PREVIEW_ROW,
    build = function(row)
      local preview = row:CreateFontString(nil, "OVERLAY", U.Fonts.BODY)
      preview:SetPoint("TOPLEFT", row, "TOPLEFT", layout.pad, -2)
      preview:SetWidth(textWidth)
      preview:SetHeight(PREVIEW_HEIGHT)
      preview:SetJustifyH("LEFT")
      preview:SetJustifyV("TOP")
      preview:SetWordWrap(true)
      row.Preview = preview
    end,
    refresh = function(row, w)
      row.Preview:SetText(PreviewText(w:Get(Opt.WHISPER_MESSAGE)))
    end,
  }

  panel:Button{
    text    = "Send a test whisper to yourself",
    width   = 220,
    tooltip = "Whispers you the message with an example item, your own name and a 150g tip, so you can see how it reads.",
    onClick = function(w)
      if PublicOrderWhisper.Whisper.SendTest then
        PublicOrderWhisper.Whisper.SendTest(w:Get(Opt.WHISPER_MESSAGE))
      end
    end,
  }
end

local function BuildButtons(panel)
  panel:Section("Buttons")
  panel:Checkbox{
    key = Opt.SHOW_LIST_BUTTONS, label = "Whisper icon in the order list (Public tab)",
    tooltip = "The chat bubble after the customer's name in the Public tab of the crafting orders list.",
  }
  panel:Checkbox{
    key = Opt.SHOW_DETAIL_BUTTON, label = "Whisper icon on the order details page",
    tooltip = "The chat bubble next to the customer's name on the page that opens when you click a public order.",
  }
  panel:Checkbox{
    key = Opt.MARK_WHISPERED, label = "Turn the icon green for players whispered this session",
    tooltip = "A green chat bubble means you already whispered that player since logging in. Off: the icon never changes colour.",
  }
end

local function BuildSending(panel)
  panel:Section("Sending")
  panel:Checkbox{
    key = Opt.OPEN_IN_CHAT, label = "Put the whisper in my chat box instead of sending it",
    tooltip = "Clicking an icon fills your chat box with the whisper, ready to edit. Press Enter to send it. While this is on, clicks do not turn the icon green, start the cooldown or flash red for an offline player. Off: the whisper is sent right away.",
  }
  panel:Checkbox{
    key = Opt.CHAT_FEEDBACK, label = "Print a chat line for each whisper sent",
    tooltip = "A short confirmation in your chat window after each whisper. Errors and failed whispers are always printed.",
  }
  panel:Slider{
    key = Opt.WHISPER_COOLDOWN, label = "Cooldown per player",
    tooltip = "How long after whispering someone the icon refuses to whisper them again. Off sends every click.",
    min = 0, max = Config.MAX_COOLDOWN, step = 1,
    format = function(v) if v <= 0 then return "Off" end return ("%d s"):format(v) end,
  }
end

local window = UI.CreateSettingsWindow({
  name    = "PublicOrderWhisperOptionsWindow",
  title   = U.WrapColor(PublicOrderWhisper.BRAND_COLOR, "Public Order Whisper") .. " Settings",
  config  = Config,
  width   = WINDOW_W,
  height  = WINDOW_H,
  persist = {
    svTable = function() return PUBLIC_ORDER_WHISPER_WINDOW_STATE end,
    key = "options",
  },
  watch   = { bus = PublicOrderWhisper.EventBus, event = PublicOrderWhisper.Events.ConfigChanged },
  message = function(text) PublicOrderWhisper.Utilities.Message(text) end,
  categories = {
    { key = "message", label = "Message", build = BuildMessage },
    { key = "buttons", label = "Buttons", build = BuildButtons },
    { key = "sending", label = "Sending", build = BuildSending },
  },
})

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
