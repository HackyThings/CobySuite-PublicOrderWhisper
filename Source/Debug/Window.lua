-------------------------------------------------------------------------------
-- PublicOrderWhisper Debug Window: thin wrapper around CobySuite.Debug.NewWindow
-------------------------------------------------------------------------------

PublicOrderWhisper.DebugWindow = CobySuite_PublicOrderWhisper.Debug.NewWindow({
  windowName = "PublicOrderWhisperDebugWindow",
  title = "Public Order Whisper Debug Log",
  logger = PublicOrderWhisper.Debug,
})
