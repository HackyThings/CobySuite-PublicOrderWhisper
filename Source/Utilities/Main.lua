local Utilities = PublicOrderWhisper.Utilities

---------------------------------------------------------------------------
-- Addon-specific: chat output (branded prefix)
---------------------------------------------------------------------------
Utilities.Message = CobySuite_PublicOrderWhisper.Chat.NewMessenger({
  prefix = "[Coby's Public Order Whisper]",
  color = PublicOrderWhisper.BRAND_COLOR,
  -- a notice (second argument true) prints only while the chat line for each whisper is on
  gate = function(verboseOnly)
    local Config = PublicOrderWhisper.Config
    return not verboseOnly or Config.Get(Config.Options.CHAT_FEEDBACK)
  end,
})
