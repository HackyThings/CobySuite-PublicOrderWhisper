-------------------------------------------------------------------------------
-- PublicOrderWhisper Debug Window: thin wrapper around CobySuite.Debug.NewWindow
-------------------------------------------------------------------------------

PublicOrderWhisper.DebugWindow = CobySuite_PublicOrderWhisper.Debug.NewWindow({
  windowName = "PublicOrderWhisperDebugWindow",
  title = "Coby's Public Order Whisper Debug Log",
  logger = PublicOrderWhisper.Debug,
})
