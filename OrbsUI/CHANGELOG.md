# Changelog

## 1.2.0

- New **Look** setting for consumable slots, under /orbs > Consumable slots. Choose Antique gold (the original), Action bar (copies the frame from your game's own action buttons), Classic grey (the original 2004 button frame), Thin black edge, Orb colour (edged in each orb's colour), Round, or Icon only.
- Antique gold, Round, Thin black edge and Orb colour each have their own **thickness** slider (1 to 8 pixels).

## 1.1.0

- Each orb can now have up to four consumable slots, set with the new **Health orb slots** and **Mana orb slots** sliders. Keep a mana potion, conjured water and a mana gem in separate slots, for example.
- Extra slots fill automatically with food, healthstones and bandages (health) or water, mana gems and runes (mana). Drag any item onto a slot to pin it.
- Orbs now tells you in chat when a guild or group member has a newer version, and after an update says what's new and where to find it.

## 1.0.3

- Renamed from OrbsForever to Orbs, since it runs on Classic and Retail as well as WoW Forever. Your settings are kept.

## 1.0.2

- Fixed another source of "OrbsForever has been blocked from an action only available to the Blizzard UI" when pressing Escape. The add-on no longer reassigns the game's popup dialog table.

## 1.0.1

- Fixed pressing Escape triggering "OrbsForever has been blocked from an action only available to the Blizzard UI". The designer now closes on Escape with its own key handler instead of joining the game's Escape list.
- Opening the designer no longer hides the game menu or the Options window from add-on code (which could cause the same error). The designer opens on top of them.

## 1.0.0

First public release.

- New designer window (`/orbs`): sidebar sections, setting search, a live orb preview, a reset icon on each setting, Reset this section, and a Changes page listing everything that differs from the defaults.
- Choices are now rows of buttons instead of buttons you click through, and settings that don't apply are greyed out.
- Removed the chat message on login.
- Fixed the incoming heal band never appearing on clients that report heal prediction as a restricted value. The band now sits on top of the health fill and shows just the incoming amount.
- The heal diagnostic log is only recorded while `/orbs heals` is running, instead of on every spell cast.
- Moved the buff, debuff, tooltip and loot-frame tweaks out of OrbsForever into a separate addon. OrbsForever is now just the orbs and their consumable slots.
