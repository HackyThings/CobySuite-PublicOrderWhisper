-------------------------------------------------------------------------------
-- WhatsNew: the changelog window and what its login shows, on the shared
-- CobySuite.UI.CreateWhatsNewWindow (the suite's standard, as Recollect's):
-- one collapsible section per version of Data/Changelog.lua, /pow changelog
-- any time. At login PUBLIC_ORDER_WHISPER_WINDOW_STATE.lastVersion says what
-- the player last ran: none opens the feature guide on a fresh install, but
-- an existing install (settings saved by 1.0.2 or earlier, existingInstall)
-- only records the version; an older version opens this window with every
-- version since then open, else nothing; either window waits for combat to
-- end. Core.lua's PLAYER_LOGIN calls
-- OnLogin.
-------------------------------------------------------------------------------
local U = CobySuite_PublicOrderWhisper.Utilities

local WhatsNew = {}
PublicOrderWhisper.WhatsNew = WhatsNew

local changelog = CobySuite_PublicOrderWhisper.UI.CreateWhatsNewWindow({
  name = "PublicOrderWhisperChangelogWindow",
  title = "Coby's Public Order Whisper: What's New",
  icon = PublicOrderWhisper.ICON,
  intro = "What changed in each version of Coby's Public Order Whisper, newest first. Click a version to open or close it.",
  footer = "Open this window any time with " .. U.WrapColor(U.Colors.HELP_COMMAND, "/pow changelog"),
  entries = PublicOrderWhisper.Data.Changelog,
  version = PublicOrderWhisper.VERSION,
  state = function() return PUBLIC_ORDER_WHISPER_WINDOW_STATE end,
  onFirstRun = function() if PublicOrderWhisper.Guide then PublicOrderWhisper.Guide.Show() end end,
  existingInstall = function() return PublicOrderWhisper.hadSavedConfig == true end,
  combatMessage = function(text) PublicOrderWhisper.Utilities.Message(text) end,
  onShow = function(what) PublicOrderWhisper.Debug.Log("INIT", "Login shows the %s", what) end,
})

-- The window's instance, for the suites
WhatsNew._test = { instance = changelog }

function WhatsNew.Toggle() changelog:Toggle() end
function WhatsNew.OnLogin() changelog:OnLogin() end
