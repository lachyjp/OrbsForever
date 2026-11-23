local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function near(a, b) return math.abs(a - b) < .001 end
combat = false
O.Change("animateGlobe", true)
O.Change("style", "Sphere")
local h, p = O.orbs.health, O.orbs.power
unloadedTexture = O.media .. "Sphere32"
O.Apply()
local waitingTime = h.globeTime
h.scripts.OnUpdate(h, 1)
p.scripts.OnUpdate(p, 1)
check(h.bar.fill.texture == O.media .. "Sphere" and p.bar.fill.texture == O.media .. "Sphere", "both orbs stay static while any animation frame is loading")
check(h.globeTime == waitingTime and h.globeFrame == nil, "loading does not advance animation time")
unloadedTexture = nil
h.scripts.OnUpdate(h, .2)
p.scripts.OnUpdate(p, .2)
check(h.bar.fill.texture == O.media .. "Sphere" and h.globeFrame == nil, "loaded frames still warm up on screen before animating")
h.scripts.OnUpdate(h, .3)
check(h.bar.fill.texture == O.media .. string.format("Sphere%02d", h.globeFrame), "animation starts only once all frames are loaded")
local originalValue, originalMask = h.bar.value, h.bar.fill.mask
local firstTexture = h.bar.fill.texture
h.scripts.OnUpdate(h, .0625)
check(h.bar.fill.texture ~= firstTexture, "globe artwork advances")
check(h.globeFrame == math.floor(h.globeTime * 16) + 1, "globe advances at sixteen frames per second")
check(h.bar.value == originalValue and h.bar.fill.mask == originalMask, "art animation preserves native fill and mask")
local frame = h.globeFrame
h.scripts.OnUpdate(h, 4)
check(h.globeFrame == frame, "globe loop wraps seamlessly every four seconds")
O.Change("animateGlobe", false)
h.scripts.OnUpdate(h, .5)
check(h.bar.fill.texture == O.media .. "Sphere", "animation toggle restores static globe")
O.Change("animateGlobe", true)
O.Change("style", "GradH")
h.scripts.OnUpdate(h, .5)
check(h.bar.fill.texture == O.media .. "GradH", "other styles remain static")
O.Change("style", "Sphere")
health, maxhealth = secret(), secret()
combat = true; O.Update(); h.scripts.OnUpdate(h, .125)
check(issecretvalue(h.bar.value) and h.globeAnimated, "motion works without inspecting restricted health")
combat = false; health, maxhealth = 760, 1000

O.Change("slotDistance", -30)
O.Change("slotPosition", "Side")
check(O.buttons.health2.point[4] == -30, "negative padding works in side placement")
O.Change("healthSlots", 1); O.Change("powerSlots", 1)
O.Change("slotPosition", "Ring")
local radius = O.db.size * .476 + 19 - 30
for _, degrees in ipairs({ 0, 90, 180, 270, 360 }) do
    O.Change("healthSlotAngle", degrees)
    local point = O.buttons.health1.point
    check(point[1] == "CENTER" and near(point[4], radius * math.cos(degrees * math.pi / 180)) and
        near(point[5], radius * math.sin(degrees * math.pi / 180)), "cardinal edge placement " .. degrees)
end
O.Change("healthSlotAngle", 45)
O.Change("powerSlotAngle", 225)
check(near(O.buttons.health1.point[4], -O.buttons.power1.point[4]) and
    near(O.buttons.health1.point[5], -O.buttons.power1.point[5]), "orb angles are independently configurable")
O.Change("healthSlots", 2); O.Change("powerSlots", 2)
O.Change("slotGap", 10)
local a, b = O.buttons.health1.point, O.buttons.health2.point
check(near(math.sqrt(a[4]^2 + a[5]^2), radius) and near(math.sqrt(b[4]^2 + b[5]^2), radius), "paired slots sit on same circular edge")
check(near(math.sqrt((a[4]-b[4])^2 + (a[5]-b[5])^2), 48), "paired centre spacing preserves slot gap")
O.Change("slotDistance", -80)
for _, button in pairs(O.buttons) do
    check(button.point[4] == button.point[4] and button.point[5] == button.point[5], "deep negative padding never creates NaN")
end
combat = true
local previous = O.buttons.health1.point
O.Change("healthSlotAngle", 120)
check(O.buttons.health1.point == previous, "angle changes deferred during combat")
combat = false; fire("PLAYER_REGEN_ENABLED")
check(O.buttons.health1.point ~= previous, "angle applied after combat")
O.Change("slotPosition", "Side")
-- Exercise the actual options slider callback, including automatic Ring selection.
for _, f in ipairs(frames) do
    if f.kind == "Slider" and f.min == 0 and f.max == 360 then
        f:SetValue(121)
        check(O.db.slotPosition == "Ring", "moving an angle slider activates edge placement")
        break
    end
end
O.Change("powerSlots", 3)
O.Change("slotPosition", "Ring")
local p1, p2, p3 = O.buttons.power1.point, O.buttons.power2.point, O.buttons.power3.point
check(near(math.sqrt((p1[4]-p2[4])^2 + (p1[5]-p2[5])^2), 38 + O.db.slotGap) and
    near(math.sqrt((p2[4]-p3[4])^2 + (p2[5]-p3[5])^2), 38 + O.db.slotGap), "three ring slots evenly spaced")
local mid = O.db.powerSlotAngle * math.pi / 180
check(near(math.atan2(p2[5], p2[4]) % (2 * math.pi), mid % (2 * math.pi)), "middle ring slot sits on the chosen angle")
O.Change("slotPosition", "Side")
O.Change("slotDistance", -24)
O.Change("slotGap", 42)
O.Change("slotPosition", "Ring")
return checks
