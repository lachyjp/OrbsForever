local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
fire("ADDON_LOADED", "OrbsUI"); flush()
check(O.orbs.health.bar.value == 760, "health initial value")
check(O.orbs.power.bar.value == 580, "power initial value")
check(registered.name == "OrbsForever", "settings registration")
check(O.buttons.health1.itemID == 99999, "strongest usable item, including matching use spell")
check(O.buttons.power1.itemID == 2455, "mana category")
check(O.buttons.health2.itemID == 117 and O.buttons.power2.itemID == 159, "food and water")
check(not O.buttons.health2.shown, "second slots initially hidden")
O.Change("secondSlot", true)
check(O.buttons.health2.shown, "second slots enabled")
O.Pin("health1", 118)
check(O.buttons.health1.attributes.item1 == "item:118", "pin overrides automatic choice")
combat = true
fire("PLAYER_REGEN_DISABLED")
O.Pin("health1", 858)
O.Change("size", 200)
O.Change("slots", false)
O.Change("locked", false)
check(O.buttons.health1.itemID == 118, "combat pin keeps the live item unchanged")
check(O.orbs.health.width == 160 and O.buttons.health1.shown, "combat layout deferred")
health = 190; fire("UNIT_HEALTH", "player")
check(O.orbs.health.bar.value == 190, "combat health updates continue")
check(O.orbs.health.low, "readable low health triggers pulse")
combat = false; fire("PLAYER_REGEN_ENABLED")
check(O.buttons.health1.itemID == 858 and O.orbs.health.width == 200, "queued changes applied on leaving combat")
check(not O.buttons.health1.shown, "queued visibility applied")
check(O.buttons.health1.attributes.type1 == nil, "disabled slots have no secure use action")
check(O.buttons.health1.attributes.useOnKeyDown == false, "secure click explicitly fires on release")
O.Pin("health1", nil)
check(O.buttons.health1.itemID == 99999, "clear pin returns to auto")
items[99999].unusable = true; O.RefreshSlots()
check(O.buttons.health1.itemID == 99999, "temporary unusability does not remove the selected item")
items[99999].required = 60; O.RefreshSlots()
check(O.buttons.health1.itemID == 929, "level-ineligible item excluded")
items[929].uncached = true; O.RefreshSlots()
check(O.buttons.health1.itemID == 858, "uncached item is skipped")
items[929].uncached = false; fire("GET_ITEM_INFO_RECEIVED", 929); flush()
check(O.buttons.health1.itemID == 929, "cache completion refreshes selection")
cursorItem = 118; O.buttons.health1.scripts.OnReceiveDrag()
check(O.db.pins.health1 == 118 and cursorItem == nil, "drag pins and clears cursor")
shift = true; O.buttons.health1.scripts.PostClick(O.buttons.health1, "RightButton", false)
check(O.db.pins.health1 == nil, "shift-right clears assignment")
check(O.buttons.health1.attributes["shift-type2"] == "", "clear action cannot use an item")
O.Pin("health1", 118)
bag = { 2455 }; fire("BAG_UPDATE_DELAYED"); flush()
check(O.buttons.health1.itemID == 118 and O.buttons.health1.icon.desaturated, "exhausted pin persists with zero count")
cooldownEnabled = false; O.RefreshSlotVisuals()
check(O.buttons.health1.cooldown.cooldown == nil, "boolean false cooldown disabled")
cooldownEnabled = 0; O.RefreshSlotVisuals()
check(O.buttons.health1.cooldown.cooldown == nil, "legacy numeric zero cooldown disabled")
O.OpenOptions()
for _, style in ipairs({ "Sphere", "GradV", "GradH", "GradRadial", "Flat" }) do
    O.Change("style", style)
    local frame = O.orbs.health.globeFrame
    local expected = style == "Sphere" and (frame and string.format("Sphere%02d", frame) or "Sphere") or style
    check(O.orbs.health.bar.fill.texture == O.media .. expected, "style texture " .. style)
end
O.Change("scale", 1.4)
O.orbs.health.scripts.OnDragStop(O.orbs.health)
check(math.abs(O.db.positions.health[1] - (500 * 1.4 - 960)) < .01, "drag positions account for scale")
O.ResetPositions()
check(O.db.positions.health[1] == -260, "reset positions")
powerKind, powerToken = 1, "RAGE"; O.Update()
check(O.orbs.power.bar.color[1] == 1, "rage color")
O.Change("blue", true)
check(O.orbs.power.bar.color[3] == 1, "forced blue color")
O.Change("manaOnly", true)
check(O.C.Power() == 0, "explicit mana mode")
maxpower, power = 0, 0; O.Update()
check(O.orbs.power.bar.max == 1 and O.orbs.power.bar.value == 0, "zero-capacity resource stays empty")
O.Change("hidePlayer", true)
check(PlayerFrame.alpha == 0, "fade Blizzard frame")
O.Change("hidePlayer", false)
check(PlayerFrame.alpha == 1, "restore Blizzard frame alpha")
health, maxhealth, power, maxpower = secret(), secret(), secret(), secret()
combat = true
for _, textMode in ipairs({ "percent", "current", "both", "none" }) do
    O.db.text = textMode
    O.Update()
    check(not O.orbs.health.low, "restricted values do not drive pulse: " .. textMode)
end
UnitHealthPercent, UnitPowerPercent = nil, nil
O.db.text = "percent"; O.Update()
check(O.orbs.health.value.format == "%s", "restricted percentage fallback uses native current text")
combat = false
bag = {}; O.Pin("health1", nil); O.RefreshSlots()
check(O.buttons.health1.itemID == nil and O.buttons.health1.attributes.item1 == nil, "empty bag clears secure item")

-- Real-time power: energy regen between throttled events reaches the orb every frame.
local p = O.orbs.power
O.db.manaOnly, O.db.blue = false, false
powerKind, powerToken, power, maxpower, health, maxhealth = 3, "ENERGY", 40, 100, 1000, 1000
fire("UNIT_DISPLAYPOWER", "player")
check(p.bar.value == 40 and p.bar.interpolation == nil, "power set directly, without easing")
power = 41; p.scripts.OnUpdate(p, .016)
check(p.bar.value == 41, "power polled between events")
check(p.value.args[1] == 41, "power text follows polled value")
p.value.args = nil; p.scripts.OnUpdate(p, .016)
check(p.value.args == nil, "unchanged power skips redraw")
maxpower = 120; p.scripts.OnUpdate(p, .016)
check(p.bar.max == 120, "polled maximum change applies")
local healthUpdates, oldHealthUpdate = 0, O.orbs.health.Update
O.orbs.health.Update = function(...) healthUpdates = healthUpdates + 1; return oldHealthUpdate(...) end
fire("UNIT_POWER_UPDATE", "player")
check(healthUpdates == 0, "power events leave the health orb alone")
O.orbs.health.Update = oldHealthUpdate
combat = true; power, maxpower = secret(), secret()
p.scripts.OnUpdate(p, .016)
check(issecretvalue(p.bar.value), "restricted power forwarded every frame without comparison")
combat = false; power, maxpower = 50, 100

-- Always track mana is ignored by characters without a mana pool.
manaMax = 0
O.Change("manaOnly", true)
check(O.C.Power() == 3 and p.bar.value == 50, "no-mana class keeps its own resource")
manaMax = 800
O.Update()
check(O.C.Power() == 0, "mana user stays on mana in forms")
manaMax, O.db.manaOnly = nil, false

-- Incoming heals: pale band above current health, solid once the heal lands.
local h = O.orbs.health
health, maxhealth, incomingHeal = 600, 1000, nil
fire("UNIT_HEAL_PREDICTION", "player")
check(not h.incoming.shown, "no prediction without incoming heals")
incomingHeal = 250; fire("UNIT_HEAL_PREDICTION", "player")
check(h.incoming.shown and h.incoming.value == 250 and h.incoming.max == 1000, "incoming heal drawn above health as its own amount")
check(h.incoming.color[4] < 1 and h.incoming.color[1] >= O.db.healthColor[1], "incoming heal is a pale health tint")
check(h.incoming:GetFrameLevel() < h.bar:GetFrameLevel(), "solid health draws over the prediction")
incomingHeal = 900; fire("UNIT_HEAL_PREDICTION", "player")
check(h.incoming.value == 900, "overheal passed through; the round mask clips it at full health")
health, incomingHeal = 850, 0; fire("UNIT_HEALTH", "player")
check(not h.incoming.shown and h.bar.value == 850, "landed heal turns solid")
incomingHeal = 100
O.Change("incomingHeals", false)
check(not h.incoming.shown, "incoming heal toggle respected")
O.Change("incomingHeals", true)
combat = true; incomingHeal = secret(); fire("UNIT_HEAL_PREDICTION", "player")
check(h.incoming.shown and issecretvalue(h.incoming.value), "restricted prediction passed to the native band")
combat, incomingHeal = false, nil
health, maxhealth = 500, 1000; O.Update()
incomingHeal = 200; h.scripts.OnUpdate(h, .016)
check(h.incoming.shown and h.incoming.value == 200, "prediction polled without the heal event")
SlashCmdList.ORBSUI("heals")
check(O.healWatch and messages[#messages]:find("Cast a heal", 1, true), "heal diagnostic starts")
incomingHeal = 0; h.scripts.OnUpdate(h, .016)
check(messages[#messages]:find("Incoming heal: 0", 1, true) and not h.incoming.shown, "heal diagnostic reports changes")
flush(); check(not O.healWatch, "heal diagnostic ends")
incomingHeal = nil

-- Fallback when the client predicts nothing: estimate the heal being cast on yourself.
health, maxhealth = 500, 1000; O.Update()
fire("UNIT_SPELLCAST_SENT", "player", "Trolala", "cast1", 331)
fire("UNIT_SPELLCAST_START", "player", "cast1", 331)
check(h.incoming.shown and h.incoming.value == 325, "self-cast heal estimated from spell description")
fire("UNIT_SPELLCAST_STOP", "player", "cast1", 331)
check(h.incoming.shown, "estimate held until the heal lands")
health = 825; fire("UNIT_HEALTH", "player"); flush()
check(not h.incoming.shown and h.bar.value == 825, "landed estimate turns solid")
fire("UNIT_SPELLCAST_SENT", "player", "Somebody", "cast2", 331)
fire("UNIT_SPELLCAST_START", "player", "cast2", 331)
check(not h.incoming.shown, "heals on other players are not shown")
fire("UNIT_SPELLCAST_SENT", "player", "", "cast3", 403)
fire("UNIT_SPELLCAST_START", "player", "cast3", 403)
check(not h.incoming.shown, "damage spells are not heals")
fire("UNIT_SPELLCAST_SENT", "player", "", "cast4", 331)
fire("UNIT_SPELLCAST_START", "player", "cast4", 331)
check(h.incoming.shown, "untargeted heal lands on yourself")
fire("UNIT_SPELLCAST_INTERRUPTED", "player", "cast4", 331)
check(not h.incoming.shown, "interrupted heal clears immediately")
check(O.db.healLog == nil or not O.db.healLog[#O.db.healLog]:find("interrupted", 1, true), "casts only logged during /orbs heals")
return checks
