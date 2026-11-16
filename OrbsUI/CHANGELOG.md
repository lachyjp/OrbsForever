# Changelog

## 1.0.0

First public release.

- New designer window (`/orbs`): sidebar sections, setting search, a live orb preview, a reset icon on each setting, Reset this section, and a Changes page listing everything that differs from the defaults.
- Choices are now rows of buttons instead of buttons you click through, and settings that don't apply are greyed out.
- Removed the chat message on login.
- Fixed the incoming heal band never appearing on clients that report heal prediction as a restricted value. The band now sits on top of the health fill and shows just the incoming amount.
- The heal diagnostic log is only recorded while `/orbs heals` is running, instead of on every spell cast.
- Moved the buff, debuff, tooltip and loot-frame tweaks out of OrbsForever into a separate addon. OrbsForever is now just the orbs and their consumable slots.
