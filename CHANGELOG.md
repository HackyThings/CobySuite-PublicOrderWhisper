# Changelog

All notable changes to Public Order Whisper are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), version numbering follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-09-09

Initial release of Public Order Whisper, built for World of Warcraft Midnight patch 12.1.

- Chat bubble after the customer's name on every row of the Public tab of the crafting orders list, and next to the name when you open an order. Click it to whisper that player your message. Your own orders get no bubble.
- `{item}` in the message becomes a link to the crafted item at the quality the order asks for (recraft orders link the item being recrafted), `{name}` the customer's name and `{tip}` the tip offered.
- The bubble turns green for players you have whispered this session, flashes red when the game reports the player could not be found, and a per-player cooldown (60 seconds by default) refuses repeat clicks.
- Settings window (`/pow settings`, the gear beside the close button of the crafting orders window, the minimap addon list, or Options > AddOns) with a live preview of the message, a test whisper to yourself, toggles for each bubble and the green mark, a cooldown slider, and a "put the whisper in my chat box" mode that lets you edit before pressing Enter.
- Whispers that would run past WoW's 255-character limit with the item link are held back with a chat message instead of failing silently.
- `/pow message <text>`, `/pow cooldown <seconds>`, `/pow test`, `/pow reset`, `/pow debug`, `/pow version`, `/pow help`.

[Unreleased]: https://github.com/HackyThings/CobySuite-PublicOrderWhisper/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/HackyThings/CobySuite-PublicOrderWhisper/releases/tag/v1.0.0
