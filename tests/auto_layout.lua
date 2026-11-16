local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
combat = false
O.db.pins = {}
O.Change("slots", true)
O.Change("secondSlot", true)
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
O.Change("secondSlot", false)
check(O.buttons.health1.point[4] == 0 and not O.buttons.health2.shown, "single slot remains centred")
O.Change("secondSlot", true)
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
return checks
