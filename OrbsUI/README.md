# Orbs

Diablo-style health and mana / power orbs for World of Warcraft, with original art, a live-preview designer and clickable consumable slots. No libraries or other addons required.

## Features

- **Two movable orbs.** Health on one side, mana, rage, energy or any other resource on the other. Drag them anywhere, or move them with the rest of your HUD in Edit Mode. Each Edit Mode layout remembers its own orb positions.
- **Five surfaces and three frames.** An animated 3D globe, three gradients or flat liquid, framed in antique gold, a fine rim or nothing at all, with an optional glass highlight.
- **Your colours.** Pick any health colour. Power follows your resource type automatically, or always use blue, or pick your own.
- **Numbers your way.** Percentage, current value, current / maximum, percentage plus value on two lines, or hidden. Choose the line order, font, outline, both font sizes, line gap and separator spacing.
- **Combat feedback.** A flash when you take damage, an amber trail as health drains away, and a low-health pulse with an adjustable threshold.
- **Consumable slots.** Up to four slots per orb, set separately for health and mana. Health slots fill with a health potion, food, healthstone and bandage, and mana slots with a mana potion, water, mana gem and rune. Auto fills them with the best match in your bags. Drag an item onto a slot to pin it, and bind keys under Key Bindings > Orbs. Place them beside, above or below each orb, or anywhere around its rim.
- **Druid friendly.** Optionally keep the power orb on mana in Cat and Bear Form.
- **Combat safe.** Uses secure buttons and native status bars, handles restricted combat values, and saves changes made in combat to apply afterwards.

## The designer

Type `/orbs`, or open Game Menu > Options > AddOns > Orbs.

The sidebar has **Orb**, **Colours**, **Text**, **Effects**, **Consumable slots** and **Moving** sections, and a **Changes** page that lists everything you've changed from the defaults. The preview at the top updates as you go. Hold **Hold to peek** to see your real orbs through the window.

- Search for a setting by name. Sections without a match fade out.
- Each changed setting has a reset icon. **Reset this section** resets the open section, and **Reset everything** on the Changes page resets all settings without touching orb positions or pinned items.
- Hover any setting for a description.

## Commands

| Command | What it does |
| --- | --- |
| `/orbs` | Open the designer |
| `/orbs unlock` / `/orbs lock` | Drag the orbs / lock them in place |
| `/orbs reset` | Move the orbs back to their default positions |
| `/orbs items` | Explain which bag items Auto picked for each slot, and why |
| `/orbs debug` | Print client details to include in a bug report |

## Consumable slots

- Auto picks the highest-level matching item you're able to use, and refreshes when your bags change, you level up or combat ends.
- Drag an item from your bags onto a slot to pin it. A pinned item stays even when you run out, shown greyed out.
- Shift-right-click a slot, or click **Auto** in the designer, to go back to automatic.
- In combat, the slot keeps its current item. New pins and other changes apply as soon as combat ends.
- Auto recognises common consumables in every language, and uncatalogued food, drink and potions on English clients. Anything else can be pinned by hand.

## Notes

- Settings, positions and pinned items are saved per character.
- **Fade Blizzard player frame** makes the default player frame transparent. Another unit frame addon may override this.
- The addon folder is named `OrbsUI` so that existing settings and key bindings carry over. Keep that name when installing.

## Reporting a problem

Turn on Lua errors with `/console scriptErrors 1`, reproduce the problem, and include the first error plus the output of `/orbs debug`.
