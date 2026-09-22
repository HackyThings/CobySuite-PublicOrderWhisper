-------------------------------------------------------------------------------
-- PublicOrderWhisper Debug Logger: thin wrapper around CobySuite.Debug.NewLogger
-------------------------------------------------------------------------------

PublicOrderWhisper.Debug = CobySuite_PublicOrderWhisper.Debug.NewLogger({
  addonName = "PublicOrderWhisper",
  categories = {
    "INIT", "CONFIG", "WHISPER", "DIAG",
  },
  savedVariable = "PUBLIC_ORDER_WHISPER_DEBUG_LOG",
  sessionHeader = function(lines)
    CobySuite_PublicOrderWhisper.Debug.AppendConfigSnapshot(lines, "PUBLIC_ORDER_WHISPER_CONFIG")
  end,
})
