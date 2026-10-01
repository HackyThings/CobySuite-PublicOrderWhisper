-------------------------------------------------------------------------------
-- Guide: the feature guide (CobySuite.UI.CreateGuideWindow), the suite's
-- standard guide, as Recollect's. /pow guide and the settings window's Guide
-- button open it, and so does the first login of a fresh install
-- (UI/WhatsNew.lua). Built at load, so opening it in combat creates nothing.
-- Keep the text in step with the README.
--
-- The sections follow a new player's first session: the first whisper, then
-- the message, then what happens after a click, and last the settings. Each
-- body is short bullets: commands and the names of buttons and options in
-- gold, a caveat in gray.
-------------------------------------------------------------------------------
local Guide = {}
PublicOrderWhisper.Guide = Guide

local U = CobySuite_PublicOrderWhisper.Utilities
local ICONS = "Interface\\Icons\\"
local BULLET = "\226\128\162 "

-- A command, button or option name, in the slash help's gold
local function Key(text) return U.WrapColor(U.Colors.HELP_COMMAND, text) end
-- A caveat, in gray
local function Note(text) return U.WrapColor(U.Colors.LABEL_GRAY, text) end
-- Bulleted lines, one paragraph
local function Bullets(lines)
  local out = {}
  for i, line in ipairs(lines) do out[i] = BULLET .. line end
  return table.concat(out, "\n")
end

Guide.SECTIONS = {
  {
    key = "start",
    title = "Start here",
    icon = PublicOrderWhisper.ICON,
    summary = "Your first whisper, from the Public tab",
    body = {
      Bullets({
        "At a profession table, open the crafting orders and pick the " .. Key("Public") .. " tab",
        "Every order someone else placed has a chat bubble after the customer's name. Your own orders have none",
        "Hover a bubble to see who it whispers and what it says",
        "Click it: that player gets your message, with the item they asked for linked in",
        "Open an order and the same bubble sits next to the customer's name",
      }),
      Note("Whisper yourself first to see how the message reads."),
    },
    try = { { "/pow selftest", "Whisper your message to yourself" } },
  },
  {
    key = "message",
    title = "Your message",
    icon = ICONS .. "INV_Misc_Note_01",
    summary = "Write it once; each order fills in its own details",
    body = {
      Bullets({
        "Write it in the settings, under " .. Key("Message") .. ". The preview below the box shows it with an example item",
        Key("{item}") .. " becomes a link to the crafted item, at the quality the order asks for",
        Key("{name}") .. " becomes the customer's name, " .. Key("{tip}") .. " the tip on the order",
        Key("Send a test whisper to yourself") .. " tries the text in the box, before you press Apply",
      }),
      Note("A whisper holds 255 bytes. The item link takes about 100, and an accented letter counts as two. A message that runs over is not sent, and chat says so."),
    },
    try = {
      { "/pow message", "Show the current message" },
      { "/pow message <text>", "Set a new message from chat" },
    },
  },
  {
    key = "after",
    title = "After you click",
    icon = ICONS .. "INV_Misc_PocketWatch_01",
    summary = "Green, red, and the cooldown",
    body = {
      Bullets({
        "The bubble turns " .. U.WrapColor(U.Colors.SUCCESS_GREEN, "green") .. " for every player you've whispered since logging in",
        "It flashes " .. U.WrapColor(U.Colors.WARNING_RED, "red") .. " when the game says the player is offline or doesn't exist, and the green mark goes away",
        "Clicking the same player again too soon is refused, and chat says how long to wait. The cooldown is 60 seconds unless you change it: up to 120, or 0 for none",
      }),
      Note("Public orders can outlast their customer's session, so a red flash is common."),
    },
    try = { { "/pow cooldown <seconds>", "Set the cooldown (0 turns it off)" } },
  },
  {
    key = "settings",
    title = "Settings",
    icon = ICONS .. "INV_Misc_Gear_01",
    summary = "Edit before sending, and choose which bubbles show",
    body = {
      Bullets({
        "Open them with /pow settings, the gear beside the crafting orders window's close button, the minimap addon list, or Options > AddOns",
        Key("Buttons") .. ": the bubble in the list, the bubble on an open order, and the green mark",
        Key("Sending") .. ": a chat line for each whisper, and the cooldown",
        Key("Put the whisper in my chat box instead of sending it") .. " lets you edit each whisper first, and Enter sends it",
        "Changes wait for " .. Key("Apply") .. ". Cancel or closing the window drops them",
      }),
      Note("In chat box mode the bubble doesn't turn green, start the cooldown or flash red, since the addon can't tell whether you sent it."),
    },
    try = {
      { "/pow settings", "Open the settings window" },
      { "/pow reset", "Put every setting back to its default" },
    },
  },
}

local guide = CobySuite_PublicOrderWhisper.UI.CreateGuideWindow({
  name = "PublicOrderWhisperGuideWindow",
  title = "Coby's Public Order Whisper Guide",
  icon = PublicOrderWhisper.ICON,
  intro = "New here? Start with the first section. Click any heading to open or close it.",
  footer = "Open this guide any time with " .. U.WrapColor(U.Colors.HELP_COMMAND, "/pow guide"),
  sections = Guide.SECTIONS,
  persist = { svTable = function() return PUBLIC_ORDER_WHISPER_WINDOW_STATE end, key = "guideWindow" },
})

-- The window, for the suites
Guide._test = { window = guide }

function Guide.Toggle() guide:Toggle() end

-- Shows the guide at its first section (a fresh install's first login)
function Guide.Show() guide:OpenSection(Guide.SECTIONS[1].key) end
