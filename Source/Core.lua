PublicOrderWhisper = {
  Debug = {},
  Config = {},
  Utilities = {},
  Whisper = {},
  Data = {},
}

PublicOrderWhisper.BRAND_COLOR = "00CED1"
PublicOrderWhisper.ICON = "Interface\\Icons\\UI_Chat"   -- the TOC's IconTexture

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
-- Registered through CobySuite.Slash, which generates help and version, with
-- the suite's standard commands (settings, guide, changelog, debug, test)
-- from CobySuite.Slash.StandardCommands and this addon's own in extra.
-- There is no main window, so there is no standard show; "show" stays an
-- unlisted alias of settings, as it was. A bare /pow opens the settings.
-- Everything else loads after Core.lua, so each command resolves its module
-- per call. The handler is kept as PublicOrderWhisper.HandleSlash for the
-- test suites.
-------------------------------------------------------------------------------
local function Message(text)
  PublicOrderWhisper.Utilities.Message(text)
end

local function White(text)
  return CobySuite_PublicOrderWhisper.Utilities.WrapColor(CobySuite_PublicOrderWhisper.Utilities.Colors.HIGHLIGHT_WHITE, text)
end

-- The settings window: /pow settings (and show), and the compartment below
local function ToggleSettings()
  if PublicOrderWhisper.Config.ToggleSettings then
    PublicOrderWhisper.Config.ToggleSettings()
  end
end

PublicOrderWhisper.HandleSlash = CobySuite_PublicOrderWhisper.Slash.Register({
  key = "PUBLICORDERWHISPER",
  slashes = { "/pow", "/publicorderwhisper" },
  title = "Coby's Public Order Whisper",
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
  onEmpty = ToggleSettings,   -- the suite's standard: a bare command opens settings when there is no main window
  commands = CobySuite_PublicOrderWhisper.Slash.StandardCommands({
    settings = ToggleSettings,
    guide = function() if PublicOrderWhisper.Guide then PublicOrderWhisper.Guide.Toggle() end end,
    changelog = function() if PublicOrderWhisper.WhatsNew then PublicOrderWhisper.WhatsNew.Toggle() end end,
    debug = function() if PublicOrderWhisper.DebugWindow then PublicOrderWhisper.DebugWindow:Toggle() end end,
    -- Development only: the suites are stripped from release builds, and
    -- the test command is hidden from help there. The whisper this command
    -- sent in 1.0.0 is /pow selftest; in a release build the fallback above
    -- says so
    tests = function() return PublicOrderWhisper.Tests end,
    extra = {
      -- "show" opened the settings before the standard commands; it still
      -- does, with no line of its own in the help
      { name = "show", run = ToggleSettings },
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
            Message(("That message is %d bytes and the limit is %d (some characters use more than one byte)."):format(#rest, Config.MAX_MESSAGE_LENGTH))
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
    },
  }),
})

-------------------------------------------------------------------------------
-- Addon compartment (the addon list on the minimap)
-- The shared launcher with only its compartment half: no minimap button and
-- no LibDataBroker object. The global functions named in the TOC route to it.
-- A left or right click opens the settings window.
-------------------------------------------------------------------------------
local launcher = CobySuite_PublicOrderWhisper.UI.CreateLauncher({
  name = ADDON_NAME,
  minimapButton = false,
  broker = false,
  onLeftClick = ToggleSettings,
  onRightClick = ToggleSettings,
  compartmentTooltipAnchor = "ANCHOR_LEFT",
  -- The suite's one launcher tooltip shape; no main window, so either
  -- click opens the settings and the key reads "Click"
  tooltip = CobySuite_PublicOrderWhisper.UI.LauncherTooltip({
    title = "Coby's Public Order Whisper",
    brandColor = PublicOrderWhisper.BRAND_COLOR,
    icon = PublicOrderWhisper.ICON,
    leftClick = "Open settings",
  }),
})

-- The launcher's tooltip, for the in-game screenshot catalog (Source/Tests)
PublicOrderWhisper.Launcher = launcher

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
  -- Settings saved before this login mean a player of an earlier release:
  -- What's New records the version instead of opening the new-player guide
  PublicOrderWhisper.hadSavedConfig = type(PUBLIC_ORDER_WHISPER_CONFIG) == "table"
    and next(PUBLIC_ORDER_WHISPER_CONFIG) ~= nil
  if PublicOrderWhisper.Config.InitializeData then
    PublicOrderWhisper.Config.InitializeData()
  end
  PublicOrderWhisper.Debug.Log("INIT", "PublicOrderWhisper v%s loaded", VERSION)
end)

EventUtil.RegisterOnceFrameEventAndCallback("PLAYER_LOGIN", function()
  -- A fresh install opens the guide; an update, the changelog
  if PublicOrderWhisper.WhatsNew then PublicOrderWhisper.WhatsNew.OnLogin() end
  PublicOrderWhisper.Debug.Log("INIT", "PLAYER_LOGIN complete")
end)
