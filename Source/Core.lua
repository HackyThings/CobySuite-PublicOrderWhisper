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
-- The handler is kept as PublicOrderWhisper.HandleSlash for the test suites.
-------------------------------------------------------------------------------
local function Message(text)
  PublicOrderWhisper.Utilities.Message(text)
end

local function White(text)
  return CobySuite_PublicOrderWhisper.Utilities.WrapColor("FFFFFF", text)
end

PublicOrderWhisper.HandleSlash = CobySuite_PublicOrderWhisper.Slash.Register({
  key = "PUBLICORDERWHISPER",
  slashes = { "/pow", "/publicorderwhisper" },
  title = "Public Order Whisper",
  version = VERSION,
  message = Message,
  -- An unknown command, which in a release build includes "test": 1.0.0 sent
  -- the test whisper with it, so say where that went
  fallback = function(_, cmd)
    if cmd == "test" then
      Message("The test whisper is now " .. CobySuite_PublicOrderWhisper.Utilities.WrapColor(CobySuite_PublicOrderWhisper.Utilities.Colors.HELP_COMMAND, "/pow selftest") .. ".")
    else
      Message(("Unknown command '%s'. Type %s for the list."):format(cmd,
        CobySuite_PublicOrderWhisper.Utilities.WrapColor(CobySuite_PublicOrderWhisper.Utilities.Colors.HELP_COMMAND, "/pow help")))
    end
  end,
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
          -- The limit is in bytes, the unit # measures
          Message(("That message is %d bytes and the limit is %d (accented letters count as two)."):format(#rest, Config.MAX_MESSAGE_LENGTH))
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
          if CobySuite_PublicOrderWhisper.Utilities.IsFiniteNumber(seconds) and seconds >= 0 and seconds <= Config.MAX_COOLDOWN then
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
      name = "selftest", help = "Whisper the current message to yourself",
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
      name = "debug", help = "Open or close the debug log window",
      run = function()
        if PublicOrderWhisper.DebugWindow then
          PublicOrderWhisper.DebugWindow:Toggle()
        end
      end,
    },
    -- Development only: the suites are stripped from release builds, and
    -- available() hides the command from help there. The whisper this
    -- command sent in 1.0.0 is /pow selftest; in a release build the
    -- fallback above says so
    {
      name = "test", usage = "test [suite]",
      help = "Open the in-game test window, optionally running one suite",
      available = function() return PublicOrderWhisper.Tests ~= nil end,
      run = function(rest)
        local tests = PublicOrderWhisper.Tests
        if not tests then return end
        tests.Window:Show()
        local suite = rest and rest:match("^%s*(%S+)")
        if suite then tests.RunSuite(suite) end
      end,
    },
  },
})

-------------------------------------------------------------------------------
-- Addon compartment (the addon list on the minimap)
-- The shared launcher with only its compartment half: no minimap button and
-- no LibDataBroker object. The global functions named in the TOC route to it.
-- A left or right click opens the settings window.
-------------------------------------------------------------------------------
local function ToggleSettings()
  if PublicOrderWhisper.Config.ToggleSettings then
    PublicOrderWhisper.Config.ToggleSettings()
  end
end

local launcher = CobySuite_PublicOrderWhisper.UI.CreateLauncher({
  name = ADDON_NAME,
  minimapButton = false,
  broker = false,
  onLeftClick = ToggleSettings,
  onRightClick = ToggleSettings,
  compartmentTooltipAnchor = "ANCHOR_LEFT",
  tooltip = {
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
  },
})

function PublicOrderWhisper_OnAddonCompartmentClick(_, button)
  launcher:OnCompartmentClick(button)
end

function PublicOrderWhisper_OnAddonCompartmentEnter(_, menuItem)
  launcher:OnCompartmentEnter(menuItem)
end

function PublicOrderWhisper_OnAddonCompartmentLeave()
  launcher:OnCompartmentLeave()
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
