local Utilities = PublicOrderWhisper.Utilities

---------------------------------------------------------------------------
-- Addon-specific: chat output (branded prefix)
---------------------------------------------------------------------------
Utilities.Message = CobySuite_PublicOrderWhisper.Chat.NewMessenger({
  prefix = "[Public Order Whisper]",
  color = PublicOrderWhisper.BRAND_COLOR,
})
