-------------------------------------------------------------------------------
-- PublicOrderWhisper Debug Logger: thin wrapper around CobySuite.Debug.NewLogger
-------------------------------------------------------------------------------

PublicOrderWhisper.Debug = CobySuite.Debug.NewLogger({
  addonName = "PublicOrderWhisper",
  categories = {
    "INIT", "CONFIG", "WHISPER", "DIAG",
  },
  savedVariable = "PUBLIC_ORDER_WHISPER_DEBUG_LOG",
  sessionHeader = function(lines)
    CobySuite.Debug.AppendConfigSnapshot(lines, "PUBLIC_ORDER_WHISPER_CONFIG")
  end,
})
