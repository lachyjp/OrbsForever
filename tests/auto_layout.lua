local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
combat = false
O.db.pins = {}
O.Change("slots", true)
O.Change("healthSlots", 2); O.Change("powerSlots", 2)
O.Change("healthLabel", false)
check(not O.orbs.health.label.shown and O.orbs.power.label.shown, "health label toggle is independent")
O.Change("powerLabel", false)
check(not O.orbs.power.label.shown and O.orbs.health.value.format == "%.0f%%", "labels hidden without hiding values")
O.Change("healthLabel", true)
O.Change("powerLabel", true)
check(O.orbs.health.label.shown and O.orbs.power.label.shown, "labels restored")
O.Change("slotPosition", "Side")
O.Change("slotDistance", 60)
O.Change("slotGap", 42)
check(O.buttons.health1.point[4] == 60 and O.buttons.power2.point[4] == -60, "orb padding mirrored across sides")
check(O.buttons.health1.point[5] == 40 and O.buttons.health2.point[5] == -40, "food spacing matches requested edge gap")
O.Change("slotPosition", "Top")
check(O.buttons.health1.point[5] == 74 and O.buttons.power2.point[5] == 74, "top padding includes key-label clearance")
O.Change("slotPosition", "Bottom")
check(O.buttons.health2.point[5] == -74, "bottom padding clears visible labels")
O.Change("healthLabel", false)
check(O.buttons.health2.point[5] == -60 and O.buttons.power2.point[5] == -74, "hidden label removes only its own clearance")
O.Change("healthSlots", 1); O.Change("powerSlots", 1)
check(O.buttons.health1.point[4] == 0 and not O.buttons.health2.shown, "single slot remains centred")
O.Change("healthSlots", 2); O.Change("powerSlots", 2)
combat = true
local oldPoint = O.buttons.health2.point
O.Change("slotDistance", 100)
check(O.buttons.health2.point == oldPoint, "padding mutations deferred during combat")
combat = false; fire("PLAYER_REGEN_ENABLED")
check(O.buttons.health2.point[5] == -100, "padding applied after combat")

items[95001] = { level = 20, required = 10, subclass = 5, spell = 95001,
    tooltip = { "Freshly cooked food", "Use: Restores 61.2 health over 18 sec. Must remain seated while eating." } }
items[95002] = { level = 20, required = 10, subclass = 5, spell = 95002,
    tooltip = { "Spring water", "Use: Restores 400 mana over 21 sec. Must remain seated while drinking." } }
items[95003] = { level = 25, required = 15, subclass = 5, spell = 95003,
    tooltip = { "Conjured refreshment", "Use: Restores 600 health and 800 mana over 30 sec." } }
items[95004] = { level = 99, required = 10, subclass = 5, spell = 95004,
    tooltip = { "Buff food", "Use: Increases maximum health by 100 and mana by 100." } }
items[95005] = { level = 80, required = 60, subclass = 5, spell = 95005,
    tooltip = { "High-level water", "Use: Restores 5000 mana over 30 sec." } }
items[95006] = { level = 21, required = 10, subclass = 5, spell = 95006,
    tooltip = { "Buffed food", "Use: Restores 100 health over 18 sec. Eating also increases mana regeneration." } }
items[95007] = { level = 27, required = 15, subclass = 1, spell = 95007,
    tooltip = { "Rejuvenation potion", "|cff00ff00Use: Restores 200 to 300 health and 100 to 150 mana.|r" } }
items[95008] = { level = 99, required = 1, class = 15, subclass = 5, spell = 95008,
    tooltip = { "Non-consumable", "Use: Restores 600 health and 800 mana." } }
bag = { 95001, 95002, 95004, 95005, 95008 }
O.RefreshSlots()
check(O.buttons.health2.itemID == 95001, "uncatalogued cooked food recognised by effect")
check(O.buttons.power2.itemID == 95002, "uncatalogued water recognised by effect")
check(O.buttons.health1.itemID == nil and O.buttons.power1.itemID == nil, "food and drink cannot populate potion slots")
bag[#bag + 1] = 95003; O.RefreshSlots()
check(O.buttons.health2.itemID == 95003 and O.buttons.power2.itemID == 95003, "combined refreshment fills both matching categories")
bag = { 95006 }; O.RefreshSlots()
check(O.buttons.health2.itemID == 95006 and O.buttons.power2.itemID == nil, "well-fed mana buff is not classified as drinking")
bag = { 95007 }; O.RefreshSlots()
check(O.buttons.health1.itemID == 95007 and O.buttons.power1.itemID == 95007, "uncatalogued combined potion recognised")
items[95007].unusable = true; fire("BAG_UPDATE", 0); flush()
check(O.buttons.health1.itemID == 95007, "temporarily unusable item stays assigned after bag refresh")
items[95007].uncached = true; O.RefreshSlots()
check(O.buttons.health1.itemID == nil, "uncached item cannot be guessed")
if modern then check(requestedItem == 95007, "missing item data explicitly requested") end
items[95007].uncached = false; fire("ITEM_DATA_LOAD_RESULT", 95007, true); flush()
check(O.buttons.health1.itemID == 95007, "async item load repopulates auto slot")
bag = { 95001, 95002 }; O.RefreshSlots()
O.Pin("health2", 117)
check(O.buttons.health2.itemID == 117, "manual pin overrides expanded automatic detection")
O.Pin("health2", nil)
check(O.buttons.health2.itemID == 95001, "Auto button returns to detected food")
combat = true
bag = { 95003 }; fire("BAG_UPDATE", 0); flush()
check(O.buttons.health2.itemID == 95001, "bag changes cannot mutate secure items in combat")
combat = false; fire("PLAYER_REGEN_ENABLED")
check(O.buttons.health2.itemID == 95003, "automatic selection catches up after combat")
O.DiagnoseItems()
check(messages[#messages]:find("power2: Auto 95003", 1, true), "diagnostics describe the actual chosen item")
local oldLevel = UnitLevel
UnitLevel = function() return 1 end
O.RefreshSlots()
check(O.buttons.health2.itemID == nil, "required levels are enforced")
UnitLevel = oldLevel; fire("PLAYER_LEVEL_UP", 30); flush()
check(O.buttons.health2.itemID == 95003, "level-up refreshes eligible items")
items[95003].tooltip = { { leftText = secret() } }
O.RefreshSlots()
check(O.buttons.health2.itemID == nil, "restricted tooltip text is not inspected")

-- Three mana slots: potion, conjured water and mana gem each get their own slot.
O.Change("slotPosition", "Side")
O.Change("powerSlots", 3)
items[8079] = { level = 25, required = 15, subclass = 5, spell = 107 }
items[5514] = { level = 28, required = 18, subclass = 0, spell = 108 }
bag = { 2455, 8079, 5514 }; O.RefreshSlots()
check(O.buttons.power1.itemID == 2455 and O.buttons.power2.itemID == 8079 and O.buttons.power3.itemID == 5514,
    "mana potion, water and mana gem fill separate slots")
check(O.buttons.power3.shown and not O.buttons.power4.shown and not O.buttons.health3.shown, "slot counts are per orb")
check(O.buttons.power3.attributes.type1 == "item" and O.buttons.power4.attributes.type1 == nil, "hidden slots have no secure action")
check(O.buttons.power1.point[5] == 80 and O.buttons.power2.point[5] == 0 and O.buttons.power3.point[5] == -80,
    "three slots centred on the orb")
O.DiagnoseItems()
check(messages[#messages]:find("power3: Auto 5514", 1, true), "diagnostics list every active slot")
O.Pin("power4", 2455)
O.Change("powerSlots", 4)
check(O.buttons.power4.shown and O.buttons.power4.itemID == 2455, "fourth slot accepts pinned items")
O.Pin("power4", nil)
O.Change("powerSlots", 3)
O.OpenOptions()
local listed
for _, f in ipairs(frames) do
    if f.key == "slots" and f.scripts and f.scripts.OnClick then f.scripts.OnClick(f); listed = true; break end
end
check(listed, "slot items page opens with per-orb slot counts")

-- Slot looks: every style applies, and the default stays the gold frame.
local b = O.buttons.health1
check(O.db.slotStyle == "Ornate" and b.border.texture:find("SlotBorder") and b.border.shown, "default slot look is antique gold")
O.Change("slotStyle", "Blizzard")
check(O.buttons.power1.border.texture == [[Interface\Buttons\UI-Quickslot2]] and b.border.width == 70, "action bar look uses the game's slot frame")
check(b.hotkey.point[1] == "TOPRIGHT" and b:GetPushedTexture().alpha == 1, "action bar look puts the key inside and shows the press")
O.buttons.health4.itemID = nil; O.RefreshSlotVisuals()
check(O.buttons.health4.border.texture == [[Interface\Buttons\UI-Quickslot]] and not O.buttons.health4.icon.shown, "empty action bar slot shows the empty frame")
O.Change("slotStyle", "Clean")
check(not b.border.shown and b.edge.shown and b.edge.colorTexture[1] == 0, "thin black edge look")
O.Change("slotStyle", "OrbColour")
check(b.edge.colorTexture[1] == O.db.healthColor[1] and b.inner.shown, "orb colour edge follows the health colour")
O.TintSlots("power", 0.2, 0.3, 0.9)
check(O.buttons.power1.edge.colorTexture[3] == 0.9, "orb colour edge follows power colour changes")
O.Change("slotStyle", "Round")
check(b.border.texture:find("SlotRing") and b.mask.texture:find("OrbMask") and b.cooldown.swipe:find("OrbMask"), "round look masks the icon and cooldown")
O.Change("slotStyle", "None")
check(not b.border.shown and not b.edge.shown and b.icon.points[1][2] == 0 and not b.mask.texture:find("OrbMask"), "icon only look")
O.Change("slotStyle", "Ornate")
check(b.border.texture:find("SlotBorder") and b:GetPushedTexture().alpha == 0 and b.hotkey.point[1] == "TOP", "switching back restores antique gold")
-- Action bar look copies the game's own action button.
ActionButton1 = CreateFrame("CheckButton", "ActionButton1")
ActionButton1:SetSize(45, 45)
local normal = ActionButton1:CreateTexture(); normal:SetAtlas("UI-HUD-ActionBar-IconFrame"); normal:SetSize(46, 45)
normal:SetPoint("TOPLEFT")
local pushedTex = ActionButton1:CreateTexture(); pushedTex:SetAtlas("UI-HUD-ActionBar-IconFrame-Down")
function ActionButton1:GetNormalTexture() return normal end
function ActionButton1:GetPushedTexture() return pushedTex end
ActionButton1.icon = ActionButton1:CreateTexture(); ActionButton1.icon:SetSize(45, 45)
ActionButton1.IconMask = ActionButton1:CreateTexture(); ActionButton1.IconMask:SetAtlas("UI-HUD-ActionBar-IconFrame-Mask")
ActionButton1.IconMask:SetPoint("CENTER", ActionButton1.icon, "CENTER", 0, 0)
ActionButton1.IconMask:SetSize(64, 64)
ActionButton1.SlotBackground = ActionButton1:CreateTexture(); ActionButton1.SlotBackground:SetAtlas("UI-HUD-ActionBar-IconFrame-Background")
O.Change("slotStyle", "Native")
check(b.border.atlas == "UI-HUD-ActionBar-IconFrame" and b.border.shown and math.abs(b.border.width - 46 * 38 / 45) < 0.01,
    "action bar look copies and scales the game's button frame")
check(b.border.point[1] == "TOPLEFT" and b.border.point[2] == b, "action bar frame keeps the game's top-left anchor")
check(b.mask.point[2] == b.icon and math.abs(b.mask.width - 64 * 38 / 45) < 0.01, "icon mask anchors to the icon like the game's")
check(b.mask.atlas == "UI-HUD-ActionBar-IconFrame-Mask" and b.inner.atlas == "UI-HUD-ActionBar-IconFrame-Background" and b.inner.shown,
    "action bar look copies the icon mask and slot background")
check(b:GetPushedTexture().atlas == "UI-HUD-ActionBar-IconFrame-Down" and b.hotkey.point[1] == "TOPRIGHT", "action bar look copies the press and keeps keys inside")
O.RefreshSlotVisuals()
check(not O.buttons.health4.icon.shown and O.buttons.power1.icon.shown, "empty action bar slot shows just the slot background")
O.Change("slotStyle", "Ornate")
check(b.border.texture:find("SlotBorder") and b.border.atlas == nil and b.mask.atlas == nil and not b.inner.shown, "leaving action bar look clears copied art")
ActionButton1 = nil
O.Change("slotStyle", "Native")
check(O.db.slotStyle == "Native" and b.style == O.slotStyles.Blizzard, "action bar look falls back to classic grey without action buttons")
O.Change("slotStyle", "Ornate")
-- Frame thickness is per look.
O.Change("slotStyle", "Ornate")
check(b.border.texture:find("SlotBorder4$") and b.icon.points[1][2] == 3, "antique gold defaults to a 4px frame")
O.Change("slotStrokeOrnate", 7)
check(b.border.texture:find("SlotBorder7$") and b.icon.points[1][2] == 6, "antique gold thickness swaps the frame art and icon inset")
O.Change("slotStyle", "Clean"); O.Change("slotStrokeClean", 5)
check(b.icon.points[1][2] == 5 and O.db.slotStrokeOrnate == 7, "thin edge thickness is stored separately")
O.Change("slotStyle", "OrbColour"); O.Change("slotStrokeOrb", 3)
check(b.inner.points[1][2] == 3 and b.icon.points[1][2] == 5, "orb colour thickness moves the black line and icon")
O.Change("slotStyle", "Round"); O.Change("slotStrokeRound", 1)
check(b.border.texture:find("SlotRing1$") and b.icon.points[1][2] == 1, "round rim thickness")
O.Change("slotStyle", "Ornate")
-- Slot key bindings from the designer.
local cmd = "CLICK OrbsUI_Slot_health1:LeftButton"
bindings["Q"] = "ACTIONBUTTON1"
local before = #frames
O.SlotKeyClick("health1", nil, "LeftButton")
local catcher = frames[before + 1]
check(catcher and catcher.shown and catcher.scripts.OnKeyDown, "set key shows the key catcher")
catcher.scripts.OnKeyDown(catcher, "LSHIFT")
check(catcher.shown, "modifier alone keeps waiting")
shift = true
catcher.scripts.OnKeyDown(catcher, "Q")
shift = false
check(not catcher.shown, "catcher hides after a key")
check(bindings["SHIFT-Q"] == cmd and savedBindings == 2, "set key binds the slot with modifiers and saves")
check(O.SlotKey("health1") == "SHIFT-Q", "slot reports its key")
O.SlotKeyClick("health1", nil, "LeftButton"); O.SlotKeyFinish("F")
check(bindings["F"] == cmd and bindings["SHIFT-Q"] == nil, "rebinding replaces the old key")
O.SlotKeyClick("health1", nil, "LeftButton"); O.SlotKeyFinish("Q")
check(bindings["Q"] == cmd and #messages > 0 and messages[#messages]:find("no longer does"), "taking over a key says what it replaced")
O.SlotKeyClick("health1", nil, "LeftButton"); catcher.scripts.OnKeyDown(catcher, "ESCAPE")
check(not catcher.shown and bindings["Q"] == cmd, "escape cancels without changing the key")
O.SlotKeyClick("health1", nil, "LeftButton"); O.SlotKeyClick("health1", nil, "MiddleButton")
check(bindings["BUTTON3"] == cmd, "mouse buttons can be bound")
O.SlotKeyClick("health1", nil, "RightButton")
check(O.SlotKey("health1") == nil, "right-click clears the key")
combat = true
O.SlotKeyClick("health1", nil, "LeftButton")
check(O.BindSlot("health1", "Z") == false and bindings["Z"] == nil, "no binding changes in combat")
combat = false
return checks
