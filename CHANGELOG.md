# Changelog

All notable changes to Coby's Public Order Whisper are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), version numbering follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.3] - 2026-10-01

### Added

- **Guide:** `/pow guide`, or the new **Guide** button in the settings window, opens a short guide to the whisper bubbles, your message and its placeholders, the green and red colors, the cooldown and the settings. It opens by itself once for new players; if you already use Coby's Public Order Whisper, nothing pops up.
- **What's New:** `/pow changelog` shows what changed in each version. After later updates it opens by itself with the versions since you last played.

### Changed

- **New name:** the addon is now called **Coby's Public Order Whisper**, to match the other Coby addons in the AddOns list. Only the name changed: the addon's folder, your saved settings, your message and every `/pow` command stay as they are.
- The commands now match the other Coby addons: `/pow options` opens the settings too, `/pow tutorial` the guide, and `/pow whatsnew` or `/pow news` the changelog. Every command you used before still works.
- Typing just `/pow` now opens the settings, as in the other Coby addons. `/pow help` lists every command.
- The settings window shows the addon's icon in its title.

### Fixed

- Resizing the settings window from its corner now stops at the edge of the screen, so the window can no longer be stretched out of reach.

## [1.0.2] - 2026-09-29

### Changed

- **Windows no longer stay on top of the game's own windows.** Public Order Whisper's windows now sit with the game's panels: clicking any window brings it to the front, and a window opens in front. Only questions that need an answer, such as confirmations, stay above everything.
- The settings window can now be made bigger by dragging its bottom-right corner, and it remembers its size.
- Settings sections sit closer together, so each group reads as one block.
- The command list in chat (`/pow help`) is easier to read: commands in gold and their descriptions in white.

### Fixed

- **Blocked-action errors after opening the settings from the game's menu:** pressing **Open Settings** on the Public Order Whisper page under Options > AddOns brought the game menu back behind the settings window, and the game blamed Public Order Whisper for SpellStopCasting, SpellStopTargeting and an unnamed protected action ("Public Order Whisper has been blocked from an action only available to the Blizzard UI"). The button now just closes Options and opens the settings window.

## [1.0.1] - 2026-09-21

### Changed

- The command that whispers the message to yourself is now `/pow selftest`. `/pow test` no longer does it and points you to the new name.
- Redesigned settings window, with Message, Buttons and Sending as categories on the left.
- Changes take effect when you press Apply. Cancel, or closing the window, throws them away. Defaults (which replaces "Reset to defaults") fills in every default for you to check, and nothing changes until you press Apply.
- The preview follows the message as you type, and "Send a test whisper to yourself" sends the message as it reads in the box, so you can try a change before applying it.
- Message length is counted in bytes, the unit of WoW's 255 limit: accented letters count as two. The message box counter, the preview, `/pow message` and the "too long" chat line all use bytes, so a message the box accepts is not refused later for its accents (the item link still adds to it).
- `/pow help` is in color: the command, what you fill in and its description each stand out.

### Fixed

- The whisper bubble always whispers the customer of the order it sits on, including after more orders load into the list or the window is resized, and its tooltip names that customer. A bubble whose row now shows a personal order or your own hides instead of sending.
- Whispering the same player twice within a few seconds (cooldown off or short) no longer hides a failure: if the second whisper finds the player offline, the bubble still flashes red and chat still says so.
- Only the known "secret number value" MoneyFrame error from the crafting orders list is hidden now. The same error anywhere else, and every other error, reaches your error display again, and `/pow debug` records the first hidden one, then the total at 10, 100 and 1000. With an error addon such as BugSack, that addon keeps showing it.
- The settings window opens during combat. Before, the first open of a session had to wait until combat ended.
- If the public orders list cannot be read as expected (another addon reshaped it), the debug log says so once instead of filling up with the same line.
- `/pow cooldown` refuses anything that is not a real number, and a damaged saved setting goes back to its default at login.
- Works correctly beside other Coby addons of different versions: each addon now carries its own private copy of the shared code, so an older one can no longer replace a newer one's.

## [1.0.0] - 2026-09-09

Initial release of Public Order Whisper, built for World of Warcraft Midnight patch 12.1.

- Chat bubble after the customer's name on every row of the Public tab of the crafting orders list, and next to the name when you open an order. Click it to whisper that player your message. Your own orders get no bubble.
- `{item}` in the message becomes a link to the crafted item at the quality the order asks for (recraft orders link the item being recrafted), `{name}` the customer's name and `{tip}` the tip offered.
- The bubble turns green for players you have whispered this session, flashes red when the game reports the player could not be found, and a per-player cooldown (60 seconds by default) refuses repeat clicks.
- Settings window (`/pow settings`, the gear beside the close button of the crafting orders window, the minimap addon list, or Options > AddOns) with a live preview of the message, a test whisper to yourself, toggles for each bubble and the green mark, a cooldown slider, and a "put the whisper in my chat box" mode that lets you edit before pressing Enter.
- Whispers that would run past WoW's 255-character limit with the item link are held back with a chat message instead of failing silently.
- `/pow message <text>`, `/pow cooldown <seconds>`, `/pow test`, `/pow reset`, `/pow debug`, `/pow version`, `/pow help`.

[Unreleased]: https://github.com/HackyThings/CobySuite-PublicOrderWhisper/compare/v1.0.3...HEAD
[1.0.3]: https://github.com/HackyThings/CobySuite-PublicOrderWhisper/releases/tag/v1.0.3
[1.0.2]: https://github.com/HackyThings/CobySuite-PublicOrderWhisper/releases/tag/v1.0.2
[1.0.1]: https://github.com/HackyThings/CobySuite-PublicOrderWhisper/releases/tag/v1.0.1
[1.0.0]: https://github.com/HackyThings/CobySuite-PublicOrderWhisper/releases/tag/v1.0.0
