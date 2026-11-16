local count = 0
local function check(value) assert(value); count = count + 1 end
local function click(text)
    for _, f in ipairs(frames) do
        if f.text == text and f.scripts.OnClick then f.scripts.OnClick(f); return end
    end
    error("Missing button: " .. text)
end
local setup = ColorPickerFrame.SetupColorPickerAndShow
for _, legacy in ipairs({ false, true }) do
    ColorPickerFrame.SetupColorPickerAndShow = legacy and nil or setup
    if legacy then ColorPickerFrame.SetupColorPickerAndShow = nil end
    ColorPickerFrame.SetColorRGB = function() end
    O.db.customPowerColor = false
    local oldHealth = O.db.healthColor[1]
    click("Health colour")
    local changed = legacy and ColorPickerFrame.func or ColorPickerFrame.info.swatchFunc
    local cancel = legacy and ColorPickerFrame.cancelFunc or ColorPickerFrame.info.cancelFunc
    changed()
    check(O.orbs.health.bar.color[1] == 0.8)
    check(not O.db.customPowerColor)
    cancel()
    check(O.db.healthColor[1] == oldHealth)
    click("Mana / power colour")
    changed = legacy and ColorPickerFrame.func or ColorPickerFrame.info.swatchFunc
    cancel = legacy and ColorPickerFrame.cancelFunc or ColorPickerFrame.info.cancelFunc
    changed()
    check(O.db.customPowerColor and O.orbs.power.bar.color[1] == 0.8)
    O.db.blue = true; O.Update()
    check(O.orbs.power.bar.color[2] == 0.1)
    cancel()
    check(not O.db.customPowerColor)
    changed()
    click("Reset colours")
    check(not O.db.customPowerColor and not O.db.blue)
    check(O.db.healthColor[1] == 1 and O.db.powerColor[3] == 1)
end
ColorPickerFrame.SetupColorPickerAndShow = setup
O.Change("powerColor", { 0.2, 0.3, 0.4 })
O.Change("customPowerColor", true)
return count
