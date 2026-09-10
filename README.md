# Public Order Whisper

<p align="center">
  <img src="https://raw.githubusercontent.com/HackyThings/CobySuite-PublicOrderWhisper/main/.publish-meta/icon/public-order-whisper-224.jpg" width="160" alt="Public Order Whisper">
</p>

A whisper button on public crafting orders in WoW Midnight (12.1).

You are at your profession table, the Public tab of the crafting orders list is open, and there is an order you could fill right now if only it were a personal order with a proper tip. Public Order Whisper puts a chat bubble after every customer's name. Click it and that player gets your message, with the item they asked for linked in, so you can offer to craft it for them directly.

## The Problem

Public orders are anonymous by design: you cannot reply to one, and reaching the customer means reading the name, typing a whisper, finding the item to link, and doing it again for the next order. Most crafters do not bother. Public Order Whisper turns all of that into one click with a message you write once.

## How It Works

1. **Open the crafting orders at a profession table and pick the Public tab.** Every order placed by someone else shows a chat bubble after the customer's name. Your own orders get none. The same bubble sits next to the customer's name when you open an order.
2. **Hover the bubble** to see the message that will be sent.
3. **Click it.** The player is whispered your message. `{item}` in the message becomes a link to the item they asked for, at the quality tier they asked for; `{name}` becomes their name and `{tip}` the tip they offered.
4. **The bubble turns green** for everyone you have whispered this session, so you do not message the same person twice by accident. A per-player cooldown (60 seconds by default, up to 120) refuses repeat clicks in the meantime.
5. **Offline or misspelt?** If the game reports that the player could not be found, the bubble flashes red and the green mark is removed.
6. **Prefer to edit before sending?** Turn on "Put the whisper in my chat box" in the settings. Each click then fills your chat box with the whisper, ready to change, and Enter sends it.

Placeholders in the message:

| Placeholder | Becomes |
|-------------|---------|
| `{item}` | A link to the crafted item, at the requested quality when the order sets one (recraft orders link the item being recrafted) |
| `{name}` | The customer's character name, without the realm |
| `{tip}` | The tip the customer set on the order, before the consortium cut, as plain text (for example "150g 25s") |

WoW whispers are limited to 255 characters, and an item link counts for about 100 of them. The settings window shows a preview with a real link so you can see how the message reads and whether it fits; a message that would run over is not sent, and the addon tells you so.

## Install

**CurseForge:** https://www.curseforge.com/wow/addons/public-order-whisper

**Manual:** Drop the `PublicOrderWhisper` folder into your `Interface/AddOns/`. No dependencies.

## Slash Commands

```
/pow settings          Open the settings window
/pow message <text>    Set the whisper message ({item}, {name}, {tip})
/pow message           Show the current message
/pow cooldown <sec>    Per-player cooldown in seconds, 0 to turn it off
/pow test              Whisper the current message to yourself
/pow reset             Restore every setting to its default
/pow debug             Toggle the debug log window
/pow version           Print the addon version
/pow help              Command list
```

`/publicorderwhisper` works the same as `/pow`.

## Settings

Open with `/pow settings`, the gear beside the close button of the crafting orders window, the addon's entry in the minimap addon list, or Options > AddOns > Public Order Whisper. Every option applies the moment you change it.

**Message**
- The whisper text, with a live preview and a button that whispers it to you as a test.

**Buttons**
- Whisper icon in the order list, Public tab (default on)
- Whisper icon on the order details page, the one that opens when you click an order (default on)
- Turn the icon green for players whispered this session (default on)

**Sending**
- Put the whisper in my chat box instead of sending it (default off. The click fills your chat box with the whisper so you can edit it; Enter sends.)
- Print a chat line for each whisper sent (default on. Errors and failed whispers are always printed.)
- Cooldown per player (default 60 seconds, up to 120. Off sends every click.)

## Troubleshooting

**There is no bubble on the order list.**

- Only the Public tab gets bubbles, and only on orders placed by other players.
- Check that "Whisper icon in the order list" is on in `/pow settings`.
- Run `/pow debug`. If the log says the customer name cell could not be found, another addon has reshaped the order list or a WoW patch changed it. The log is what I need to fix it (see below).

**The whisper was not sent and chat says it is too long.**

- The item link is long. Shorten the message in `/pow settings`; the preview shows the length with a real link.

**The bubble flashed red.**

- The game reported that the player is offline or does not exist. Public orders can outlive their customer's session.

**I see "attempt to perform arithmetic on a secret number value" errors from MoneyFrame with another crafting-order addon installed.**

- That error comes from the other addon rebuilding Blizzard's order table. Public Order Whisper quietly drops that specific error so it does not spam you; nothing else is affected.

## License

GPL-2.0. See [LICENSE](LICENSE).

## Issues / Feedback

For bug reports, the cleanest path is the debug log. It is self-contained: it includes the addon version, your WoW build, a snapshot of every setting, and a timestamped event timeline. No need to paste anything else.

**How to capture and send:**

1. Reproduce the issue.
2. Run `/pow debug` to open the debug window. Copy the last ~250 entries.
3. Email them to **hackythings@gmail.com** with a sentence about what you were doing.

**Other channels:**

- **BugSack errors:** whisper the report straight to **Figment-Illidan** in-game. BugSack copies the stack trace for you. Mention how to reproduce if you can.
- **CurseForge comments:** drop a note on the [project page](https://www.curseforge.com/wow/addons/public-order-whisper). Best for general feedback and quick questions.
- **GitHub issues:** [open one here](https://github.com/HackyThings/CobySuite-PublicOrderWhisper/issues). Best for reproducible bugs and feature proposals where back-and-forth helps. Attach the debug-log paste here too if it is relevant.
