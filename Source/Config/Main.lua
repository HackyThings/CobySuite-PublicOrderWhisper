local Config = PublicOrderWhisper.Config

---------------------------------------------------------------------------
-- Shared config base via CobySuite.Config.New
---------------------------------------------------------------------------
local base = CobySuite_PublicOrderWhisper.Config.New({
  savedVariable = "PUBLIC_ORDER_WHISPER_CONFIG",
  options = {
    WHISPER_MESSAGE    = "whisper_message",     -- template; {item}, {name} and {tip} are replaced per order
    WHISPER_COOLDOWN   = "whisper_cooldown",    -- seconds before the same player can be whispered again (0 = off)
    SHOW_LIST_BUTTONS  = "show_list_buttons",   -- whisper icon on every row of the public order list
    SHOW_DETAIL_BUTTON = "show_detail_button",  -- whisper icon next to the customer name on the order details
    MARK_WHISPERED     = "mark_whispered",      -- tint the icon green for players whispered this session
    CHAT_FEEDBACK      = "chat_feedback",       -- print a chat line for each whisper sent
    OPEN_IN_CHAT       = "open_in_chat",        -- put the whisper in the chat box to edit instead of sending it
  },
  defaults = {
    ["whisper_message"]    = "Hi! I can craft {item} for you. Send me a personal order!",
    ["whisper_cooldown"]   = 60,
    ["show_list_buttons"]  = true,
    ["show_detail_button"] = true,
    ["mark_whispered"]     = true,
    ["chat_feedback"]      = true,
    ["open_in_chat"]       = false,
  },
  -- Set refuses a failing value and InitializeData puts the default back for
  -- a failing saved one (a hand-edited or damaged file). Everything 1.0.0
  -- could save passes: its slider and /pow cooldown stored whole seconds.
  validate = {
    ["whisper_message"]    = { type = "string" },
    ["whisper_cooldown"]   = { type = "number", min = 0, max = 120, integer = true },
    ["show_list_buttons"]  = { type = "boolean" },
    ["show_detail_button"] = { type = "boolean" },
    ["mark_whispered"]     = { type = "boolean" },
    ["chat_feedback"]      = { type = "boolean" },
    ["open_in_chat"]       = { type = "boolean" },
  },
  debug = PublicOrderWhisper.Debug,
  onSet = function(name, old, value)
    PublicOrderWhisper.EventBus:Fire(PublicOrderWhisper.Events.ConfigChanged, name, value, old)
  end,
  onReset = function()
    PublicOrderWhisper.EventBus:Fire(PublicOrderWhisper.Events.ConfigChanged)
  end,
})

-- Install onto PublicOrderWhisper.Config namespace
Config.Options       = base.Options
Config.Defaults      = base.Defaults
Config.CheckValue    = base.CheckValue
Config.Get           = base.Get
Config.Set           = base.Set
Config.Reset         = base.Reset

-- The longest whisper WoW sends, in bytes (an accented letter takes two;
-- treated as bytes until checked against the live server). The settings box
-- and the slash command cap the template here, and the whisper module checks
-- the built message, item link included.
Config.MAX_MESSAGE_LENGTH = 255
Config.MAX_COOLDOWN = 120

---------------------------------------------------------------------------
-- InitializeData: wraps base with addon-specific SavedVariable init
---------------------------------------------------------------------------
function Config.InitializeData()
  base.InitializeData()

  if type(PUBLIC_ORDER_WHISPER_WINDOW_STATE) ~= "table" then
    PUBLIC_ORDER_WHISPER_WINDOW_STATE = {}
  end

  PublicOrderWhisper.Debug.Log("CONFIG", "Config initialized")
end
