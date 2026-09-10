PublicOrderWhisper = {
  Debug = {},
  Config = {},
  Utilities = {},
  Whisper = {},
}

PublicOrderWhisper.BRAND_COLOR = "00CED1"

-------------------------------------------------------------------------------
-- EventBus event constants
-------------------------------------------------------------------------------
PublicOrderWhisper.Events = {
  ConfigChanged  = "public_order_whisper_config_changed",
  WhisperSent    = "public_order_whisper_sent",
  WhisperFailed  = "public_order_whisper_failed",
}

-------------------------------------------------------------------------------
-- Addon metadata
-------------------------------------------------------------------------------
local ADDON_NAME = "PublicOrderWhisper"
local VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "1.0.0"
PublicOrderWhisper.VERSION = VERSION

-------------------------------------------------------------------------------
-- Slash commands
--
-- Registered through CobySuite.Slash, which generates help and version.
-- Utilities.Message is defined in a later file, so it is resolved per call.
-------------------------------------------------------------------------------
local function Message(text)
  PublicOrderWhisper.Utilities.Message(text)
end

local function White(text)
  return CobySuite.Utilities.WrapColor("FFFFFF", text)
end

CobySuite.Slash.Register({
  key = "PUBLICORDERWHISPER",
  slashes = { "/pow", "/publicorderwhisper" },
  title = "Public Order Whisper",
  version = VERSION,
  message = Message,
  commands = {
    {
      name = "settings", aliases = { "config", "show" }, help = "Open the settings window",
      run = function()
        if PublicOrderWhisper.Config.ToggleSettings then
          PublicOrderWhisper.Config.ToggleSettings()
        end
      end,
    },
    {
      name = "message", aliases = { "msg" }, help = "Show the current whisper message",
      run = function(rest)
        local Config = PublicOrderWhisper.Config
        if rest == "" then
          local current = Config.Get(Config.Options.WHISPER_MESSAGE)
          Message("Current message: " .. White(current or "(none)"))
          Message("{item} = crafted item link, {name} = customer's name, {tip} = tip offered.")
        elseif #rest > Config.MAX_MESSAGE_LENGTH then
          Message(("That message is %d characters; the limit is %d."):format(#rest, Config.MAX_MESSAGE_LENGTH))
        else
          Config.Set(Config.Options.WHISPER_MESSAGE, rest)
          Message("Message updated: " .. White(rest))
        end
      end,
    },
    { usage = "message <text>", help = "Set the whisper message" },
    {
      name = "cooldown", aliases = { "cd" }, help = "Show the whisper cooldown",
      run = function(rest)
        local Config = PublicOrderWhisper.Config
        if rest == "" then
          local current = Config.Get(Config.Options.WHISPER_COOLDOWN)
          Message("Whisper cooldown: " .. White(current > 0 and (current .. "s") or "off"))
        else
          local seconds = tonumber(rest)
          if seconds and seconds >= 0 and seconds <= Config.MAX_COOLDOWN then
            seconds = math.floor(seconds)
            Config.Set(Config.Options.WHISPER_COOLDOWN, seconds)
            Message("Whisper cooldown set to " .. White(seconds > 0 and (seconds .. "s") or "off"))
          else
            Message(("Invalid value. Usage: /pow cooldown <0-%d>"):format(Config.MAX_COOLDOWN))
          end
        end
      end,
    },
    { usage = "cooldown <seconds>", help = "Set the per-player cooldown (0 = off)" },
    {
      name = "test", help = "Whisper the current message to yourself",
      run = function()
        if PublicOrderWhisper.Whisper.SendTest then
          PublicOrderWhisper.Whisper.SendTest()
        end
      end,
    },
    {
      name = "reset", help = "Restore every setting to its default",
      run = function()
        PublicOrderWhisper.Config.Reset()
        Message("Settings restored to defaults.")
      end,
    },
    {
      name = "debug", help = "Toggle the debug window",
      run = function()
        if PublicOrderWhisper.DebugWindow then
          PublicOrderWhisper.DebugWindow:Toggle()
        end
      end,
    },
  },
  fallback = function(_, cmd)
    Message("Unknown command: " .. cmd .. ". Type /pow help for a list.")
  end,
})

-------------------------------------------------------------------------------
-- Addon compartment (the addon list on the minimap)
-- Global functions named in the TOC. Click opens the settings window.
-------------------------------------------------------------------------------
function PublicOrderWhisper_OnAddonCompartmentClick()
  if PublicOrderWhisper.Config.ToggleSettings then
    PublicOrderWhisper.Config.ToggleSettings()
  end
end

function PublicOrderWhisper_OnAddonCompartmentEnter(_, menuItem)
  GameTooltip:SetOwner(menuItem, "ANCHOR_LEFT")
  CobySuite.UI.PopulateBrandedTooltip(GameTooltip, {
    brandColor = PublicOrderWhisper.BRAND_COLOR,
    title = "Public Order Whisper",
    subtitle = "v" .. VERSION,
    body = {
      "Whisper the players behind public crafting orders from the order list.",
    },
    keys = {
      { key = "Click", desc = "Settings" },
      { key = "/pow", desc = "Commands" },
    },
  })
end

function PublicOrderWhisper_OnAddonCompartmentLeave()
  GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- Startup sequence
-------------------------------------------------------------------------------
EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, function()
  if PublicOrderWhisper.Config.InitializeData then
    PublicOrderWhisper.Config.InitializeData()
  end
  PublicOrderWhisper.Debug.Log("INIT", "PublicOrderWhisper v%s loaded", VERSION)
end)

EventUtil.RegisterOnceFrameEventAndCallback("PLAYER_LOGIN", function()
  PublicOrderWhisper.Debug.Log("INIT", "PLAYER_LOGIN complete")
end)
