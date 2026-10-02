-------------------------------------------------------------------------------
-- Data.Changelog: the in-game changelog (UI/WhatsNew.lua, /pow changelog),
-- one entry per version, newest first. Shown after an update with every
-- version newer than the one the player last ran opened.
--
-- An entry: version (the TOC's), title (a few words), date ("2026-10-02"
-- once released; nil shows "Beta"), and the lists new, changed and fixed,
-- each a line a player reads (the CHANGELOG.md style: what changed for
-- them, no internals), short enough to fit on one line: "Feature: what it
-- does", the part before the first ": " shown in blue, and {/pow} for a
-- command in gold. Braces always mean a command here, so the message
-- placeholders are named in words. Keep it in step with CHANGELOG.md:
-- /release adds the entry.
-------------------------------------------------------------------------------
PublicOrderWhisper.Data = PublicOrderWhisper.Data or {}

PublicOrderWhisper.Data.Changelog = {
  {
    version = "1.0.4",
    title = "Ready-made messages",
    date = "2026-10-01",
    new = {
      "Ready-made messages: pick one under Message, then make it yours",
      "Chips: buttons that put item, name or tip into your message",
    },
    changed = {
      "Settings: redesigned, with Message, Bubbles and Sending pages",
      "Message: shows your whisper as the customer reads it, sized in bytes",
      "Send test to myself: uses the text in the box before you apply it",
      "Tip: an order with no tip now reads 0g",
    },
    fixed = {
      "Bubbles: with no message set, the tooltip no longer says Click to send",
      "Orders whose item link is empty now say your item",
      "Minimap addon list: tooltip matches the other Coby addons",
    },
  },
  {
    version = "1.0.3",
    title = "A new name and a guide",
    date = "2026-10-01",
    new = {
      "Guide: the bubbles, your message and the cooldown, {/pow guide}",
      "What's New: {/pow changelog}, and after each update",
    },
    changed = {
      "New name: Coby's Public Order Whisper; your settings stay",
      "Commands: {/pow} opens the settings, {/pow help} lists the rest",
      "Settings: the addon's icon in the title",
    },
    fixed = {
      "Settings window: resizing stops at the screen edge",
    },
  },
  {
    version = "1.0.2",
    title = "Windows and a fix",
    date = "2026-09-29",
    changed = {
      "Windows: sit with the game's own; a click brings one to the front",
      "Settings: drag the corner to resize, and the size is kept",
      "Settings: each group of options reads as one block",
      "Command list: easier to read in {/pow help}",
    },
    fixed = {
      "Options > AddOns: Open Settings no longer causes blocked-action errors",
    },
  },
  {
    version = "1.0.1",
    title = "New settings window",
    date = "2026-09-21",
    changed = {
      "Test whisper: now {/pow selftest}",
      "Settings: Message, Buttons and Sending, with Apply, Cancel and Defaults",
      "Preview and test whisper: use the text in the box as you type",
      "Message length: counted in bytes, so accented letters count as two",
    },
    fixed = {
      "Bubbles: always whisper the customer of the order they sit on",
      "Offline players: a quick second whisper still flashes red",
      "Errors: only the known crafting orders list error is hidden",
      "Settings: open in combat too",
      "Cooldown: refuses anything that isn't a number",
      "Works beside other Coby addons of any version",
    },
  },
  {
    version = "1.0.0",
    title = "First release",
    date = "2026-09-09",
    new = {
      "Chat bubble: on every public order, and on an order you open",
      "One click: whispers your message with the item linked in",
      "Placeholders: the item link, the customer's name and the tip",
      "Green bubble: players you've whispered this session",
      "Red flash: the player is offline or doesn't exist",
      "Cooldown: per player, 60 seconds unless you change it",
      "Chat box mode: edit the whisper before you send it",
    },
  },
}
