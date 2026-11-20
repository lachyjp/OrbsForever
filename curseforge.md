SUMMARY

Diablo-style health and mana orbs with a live-preview designer, combat effects and one-click potion slots.

DESCRIPTION

# Orbs

Replace your player frame with two glowing, Diablo-style orbs: health on one side, mana or your resource on the other. Style them in a designer with a live preview, and keep potions one click away.

## Features

- **Two movable orbs.** Drag them anywhere, or move them with the rest of your HUD in Edit Mode. Each Edit Mode layout remembers its own positions.
- **Five surfaces.** An animated 3D globe, three gradients or flat liquid, framed in antique gold, a fine rim or nothing at all, with an optional glass highlight.
- **Your colours.** Pick any health colour. The power orb follows your resource (mana, rage, energy and more), or you can force blue or pick your own.
- **Numbers your way.** Percentage, current value, current / maximum, or percentage and value on two lines. Choose the font, outline, sizes and spacing.
- **Combat feedback.** A flash when you're hit, an amber trail as health drains away, and a low-health pulse.
- **Potion slots.** Health and mana potion slots beside the orbs, plus optional food and water slots. Auto picks the best item in your bags. Drag an item on to pin it, and bind keys under Key Bindings > Orbs.
- **Druid friendly.** Optionally keep the power orb on mana in Cat and Bear Form.
- **Combat safe.** Secure buttons and native status bars. Changes made in combat apply as soon as it ends.
- **Lightweight.** No libraries and no other addons needed.

## The designer

Type **/orbs** to open it. Settings are grouped into Orb, Colours, Text, Effects, Consumable slots and Moving, with a preview that updates as you go.

- Search any setting by name.
- Reset a single setting, a whole section, or everything.
- The **Changes** page lists everything you've changed from the defaults.
- **Hold to peek** makes the window see-through so you can check your real orbs.

## Commands

- **/orbs**: open the designer
- **/orbs unlock** / **/orbs lock**: move the orbs / lock them
- **/orbs reset**: put the orbs back in their default positions
- **/orbs items**: explain which bag items each slot picked
- **/orbs debug**: client details for bug reports

## Notes

- Settings, positions and pinned items are saved per character.
- The addon folder is named **OrbsUI**. Keep that name if you install by hand.

## Found a bug?

Type `/console scriptErrors 1`, reproduce the problem, and post the first Lua error along with the output of `/orbs debug`.
