# Coby's Public Order Whisper

<p align="center">
  <img src="https://raw.githubusercontent.com/HackyThings/CobySuite-PublicOrderWhisper/main/.publish-meta/icon/public-order-whisper-224.jpg" width="160" alt="Coby's Public Order Whisper">
</p>

A whisper button on public crafting orders in WoW Midnight (12.1).

Public orders have no reply button. Coby's Public Order Whisper puts a chat bubble after every customer's name: one click whispers them your message, with the item they asked for linked in, so you can offer to craft it as a personal order.

## Features

- A bubble on every public order placed by another player, in the order list and on an open order.
- One message you write once, filled in per order: `{item}` (a link to the item, at the quality asked for when the game has that link), `{name}` (their name, without the realm) and `{tip}` (their tip, 0g when there is none).
- The bubble turns **green** once you have whispered that player, and flashes **red** (dropping the green) if the game says they are offline or don't exist. Green clears when you log out or reload.
- A per-player cooldown (60 seconds, up to 120, or off) so a double click never whispers anyone twice.
- Optional: put the whisper in your chat box first, to edit it before you press Enter. That click doesn't mark the bubble or start the cooldown.
- Ready-made messages to start from, and Send test to myself to see how yours reads.

## Quick Start

1. At a profession table, open the crafting orders and pick the **Public** tab.
2. Hover a bubble to see who it whispers and your message.
3. Click it. The player gets your message.

WoW whispers hold 255 bytes; some characters use more than one, and an item link takes about 100. A message that would run over is not sent, and chat says so. The settings measure an example for you.

## Install

**CurseForge:** https://www.curseforge.com/wow/addons/public-order-whisper

**Manual:** Drop the `PublicOrderWhisper` folder into your `Interface/AddOns/`. No dependencies.

## Slash Commands

```
/pow settings              Open or close the settings window
/pow guide                 Open or close the feature guide
/pow changelog             Open or close the changelog: what changed in each version
/pow debug                 Open or close the debug log window
/pow message               Show the current whisper message
/pow message <text>        Set the whisper message
/pow cooldown              Show the whisper cooldown
/pow cooldown <seconds>    Set the per-player cooldown (0 = off)
/pow selftest              Whisper the current message to yourself
/pow reset                 Restore every setting to its default
/pow version               Print the addon version
/pow help                  Show this help
```

`/pow` on its own opens the settings; `/publicorderwhisper` works the same as `/pow`.

## Guide and What's New

`/pow guide` (or **Guide** in the settings) opens a short guide; it opens by itself for new players. `/pow changelog` lists what changed; after later updates it opens by itself.

## Settings

Open with `/pow settings`, the gear beside the close button of the crafting orders list, the minimap addon list, or Options > AddOns. Changes wait for **Apply**; Cancel drops them.

- **Message:** your whisper, the placeholder chips, an example as the customer sees it, its length in bytes, Send test to myself, and ready-made messages.
- **Bubbles:** show the bubble in the order list, on an open order, or both.
- **Sending:** send right away or put it in your chat box first, a chat line after each whisper, the green mark, and the cooldown.

## Troubleshooting

**No bubble on the order list.** Only the Public tab gets bubbles, and only on other players' orders. Check Bubbles in `/pow settings`. A row reached in combat gets its bubble when combat ends. If it still fails, `/pow debug` shows why.

**Chat says the whisper is too long.** A real order's item link can be longer than the example. Chat gives the size in bytes: shorten the message by at least the difference.

**The bubble flashed red.** The player is offline or doesn't exist; public orders can outlast their customer's session.

**"Secret number value" errors from MoneyFrame with another crafting-order addon.** That error comes from the other addon. This addon hides it only when it comes from the crafting orders window, and notes it in `/pow debug`; every other error still shows. With an error addon such as BugSack, that addon shows it instead.

## License

GPL-2.0. See [LICENSE](LICENSE).

## Issues / Feedback

Found a bug? Run `/pow debug`, press **Copy Last 250** and send the text with a line about what you were doing. The log holds the addon version, your WoW build and your settings.

- **Email:** hackythings@gmail.com
- **BugSack errors:** whisper them to **Figment-Illidan** in game.
- **CurseForge:** comment on the [project page](https://www.curseforge.com/wow/addons/public-order-whisper) for questions and feedback.
- **GitHub:** [open an issue](https://github.com/HackyThings/CobySuite-PublicOrderWhisper/issues) for bugs you can reproduce.
