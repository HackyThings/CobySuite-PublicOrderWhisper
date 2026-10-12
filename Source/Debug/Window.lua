-------------------------------------------------------------------------------
-- PublicOrderWhisper Debug Window: thin wrapper around CobySuite.Debug.NewWindow
-------------------------------------------------------------------------------

PublicOrderWhisper.DebugWindow = CobySuite_PublicOrderWhisper.Debug.NewWindow({
  windowName = "PublicOrderWhisperDebugWindow",
  title = CobySuite_PublicOrderWhisper.Utilities.WrapColor(PublicOrderWhisper.BRAND_COLOR, "Coby's Public Order Whisper") .. " debug log",
  icon = PublicOrderWhisper.ICON,
  logger = PublicOrderWhisper.Debug,
})
