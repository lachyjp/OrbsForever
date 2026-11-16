local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
combat = false
health, maxhealth, power, maxpower = 760, 1000, 580, 1000
powerKind, powerToken = 0, "MANA"
function UnitHealthPercent() return secret() end
function UnitPowerPercent() return secret() end
local h, p = O.orbs.health, O.orbs.power
O.Change("text", "percent")
O.Change("valueBelowPercent", true)
check(h.secondary.shown and h.secondary.args[1] == 760, "health number beneath percentage")
check(p.secondary.shown and p.secondary.args[1] == 580, "mana number beneath percentage")
check(h.secondary.fontSize < h.value.fontSize, "secondary values have smaller type")
check(h.value.format == "%.0f%%", "percentage retained on first line")
O.Change("text", "both")
check(not h.secondary.shown and not p.secondary.shown, "stacked numbers hidden outside percentage mode")
O.Change("text", "percent")
O.Change("valueBelowPercent", false)
check(not h.secondary.shown, "number toggle disabled")
O.Change("valueBelowPercent", true)
health, power = secret(), secret()
O.Update()
check(issecretvalue(h.secondary.args[1]) and issecretvalue(p.secondary.args[1]), "restricted numbers go directly to native text")
local oldHealthPercent = UnitHealthPercent
UnitHealthPercent = nil; O.Update()
check(not h.secondary.shown and h.value.format == "%s", "missing percent API does not duplicate current text")
UnitHealthPercent = oldHealthPercent

DUIFont_Quest_Gossip = { GetFont = function() return "DialogueCustom.ttf", 16, "" end }
O.Change("font", "dialogue")
check(h.value.fontFile == "DialogueCustom.ttf" and p.secondary.fontFile == "DialogueCustom.ttf", "dialogue font applied to both values")
check(h.label.fontFile == "DialogueCustom.ttf", "dialogue font applied to orb labels")
O.Change("fontOutline", "shadow")
check(h.value.fontFlags == "" and h.value.shadowColor[4] > 0, "dialogue-style shadow")
O.Change("fontOutline", "thick")
check(h.value.fontFlags == "THICKOUTLINE", "thick outline")
O.Change("fontOutline", "none")
check(h.value.fontFlags == "" and h.value.shadowColor[4] == 0, "plain text has no outline or shadow")
DUIFont_Quest_Gossip = nil
QuestFont = { GetFont = function() return "Quest.ttf" end }
O.Change("font", "dialogue")
check(h.value.fontFile == "Quest.ttf", "dialogue fallback without DialogueUI")
QuestFont = nil
O.Apply()
check(h.value.fontFile == STANDARD_TEXT_FONT, "safe default if no font object is available")
for _, choice in ipairs({ "arial", "skurri", "morpheus" }) do
    O.Change("font", choice)
    check(h.value.fontFile:find("Fonts\\", 1, true) == 1, "built-in font choice " .. choice)
end
O.Change("font", "dialogue")
O.Change("fontOutline", "shadow")

O.Change("damageFlash", true)
h.scripts.OnUpdate(h, 1)
fire("UNIT_COMBAT", "player", "HEAL", "", 100, 1)
check(not h.hitFlash.shown, "healing does not flash")
fire("UNIT_COMBAT", "target", "WOUND", "", 100, 1)
fire("UNIT_COMBAT", "player", "WOUND", "", 0, 1)
check(not h.hitFlash.shown, "other units and zero damage do not flash")
combat = true
fire("UNIT_COMBAT", "player", "WOUND", "", secret(), 1)
check(h.hitFlash.shown and h.hitRim.shown, "damage event flashes with restricted amount")
h.scripts.OnUpdate(h, .15)
check(h.hitFlash.alpha > 0 and h.hitFlash.alpha < .24, "damage flash fades")
fire("UNIT_COMBAT", "player", "WOUND", "", 10, 1)
check(h.flashRemaining == .35, "repeated hit restarts flash")
h.scripts.OnUpdate(h, .4)
check(not h.hitFlash.shown and not h.hitRim.shown, "flash ends cleanly")
fire("UNIT_COMBAT", "player", secret(), "", secret(), 1)
fire("UNIT_COMBAT", secret(), "WOUND", "", secret(), 1)
check(not h.hitFlash.shown, "restricted event classification is never inspected")
combat = false
O.Change("damageFlash", false)
fire("UNIT_COMBAT", "player", "WOUND", "", 10, 1)
check(not h.hitFlash.shown, "flash toggle respected")
O.Change("damageFlash", true)
health, maxhealth = 1000, 1000; O.Update()
health = 800; fire("UNIT_HEALTH", "player")
check(h.hitFlash.shown, "readable health drop provides fallback damage flash")
h.scripts.OnUpdate(h, .4)
health = 900; fire("UNIT_HEALTH", "player")
check(not h.hitFlash.shown, "readable healing does not trigger fallback")
health, maxhealth = 450, 500; fire("UNIT_HEALTH", "player")
check(not h.hitFlash.shown, "changed maximum is not mistaken for damage")

health, maxhealth, power, maxpower = 1000, 1000, 500, 1000
O.Change("animateDamage", true)
flush()
check(h.trail.value == 1000, "damage trail starts at current health")
health = 800; fire("UNIT_HEALTH", "player")
check(h.bar.value == 800 and h.trail.value == 1000, "real fill drops immediately while trail holds")
flush()
if modern then
    check(h.trail.value == 800 and h.trail.interpolation == 1, "native eased health decrease")
else
    check(h.trailTarget == 800, "legacy decrease has an animation target")
    h.scripts.OnUpdate(h, .1)
    check(h.trail.value > 800 and h.trail.value < 1000, "legacy trail moves smoothly toward new health")
    h.scripts.OnUpdate(h, 2)
    check(h.trail.value == 800 and h.trailTarget == nil, "legacy animation completes")
end
health = 700; fire("UNIT_HEALTH", "player")
O.Change("animateDamage", false)
flush()
check(not h.trail.shown and h.trailTarget == nil and not h.trailQueued, "disabling animation cancels queued work")
health = 650; fire("UNIT_HEALTH", "player")
check(h.bar.value == 650 and not h.trailQueued, "animation off updates health immediately")
O.Change("animateDamage", true)
health, maxhealth = secret(), secret()
combat = true; fire("UNIT_HEALTH", "player"); flush()
check(issecretvalue(h.trail.value), "restricted health forwarded to native damage trail")
check(h.trailTarget == nil, "restricted health never enters Lua animation arithmetic")
combat = false
health, maxhealth = 1000, 1000
O.Apply()
return checks
