local name, O = ...
O.version = "1.1.0"
O.defaults = {
    locked = true, size = 160, scale = 1, style = "Sphere", bezel = "Ornate",
    gloss = true, text = "percent", fontSize = 18, manaOnly = false, blue = false,
    healthColor = { 1, 0.16, 0.20 }, powerColor = { 0.10, 0.43, 1 }, customPowerColor = false,
    pulse = true, threshold = 30, incomingHeals = true,
    valueBelowPercent = false, damageFlash = true, animateDamage = true,
    font = "dialogue", fontOutline = "shadow",
    slots = true, healthSlots = 1, powerSlots = 1, slotPosition = "Side", hidePlayer = false,
    healthLabel = true, powerLabel = true, slotDistance = 12, slotGap = 10,
    animateGlobe = true, healthSlotAngle = 0, powerSlotAngle = 180,
    valueFontSize = 13, textOrder = "percentFirst", valueFormat = "both", lineGap = 3, separatorPadding = 1,
    positions = { health = { -260, 170 }, power = { 260, 170 } }, pins = {},
    editMode = true, layoutPositions = {},
}
function O.Message(message) print("|cffe5c58cOrbs:|r " .. message) end
local function defaults(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then target[k] = {} end
            defaults(target[k], v)
        elseif type(target[k]) ~= type(v) then target[k] = v end
    end
end
function O.Apply()
    if InCombatLockdown() then
        O.pending = true
        return
    end
    O.pending = false
    for _, orb in pairs(O.orbs) do orb:Apply() end
    O.LayoutSlots()
    O.RefreshSlots()
    if PlayerFrame then
        if O.db.hidePlayer then
            if O.playerAlpha == nil then O.playerAlpha = PlayerFrame:GetAlpha() end
            PlayerFrame:SetAlpha(0)
        elseif O.playerAlpha ~= nil then
            PlayerFrame:SetAlpha(O.playerAlpha)
            O.playerAlpha = nil
        end
    end
    O.Update()
end
function O.Change(key, value)
    O.db[key] = value
    if key == "text" then O.db.valueBelowPercent = false end
    O.Apply()
    if O.RefreshOptions then O.RefreshOptions() end
    if InCombatLockdown() then O.Message("Change saved; it will apply after combat.") end
end
function O.ResetPositions()
    O.db.positions = { health = { -260, 170 }, power = { 260, 170 } }
    O.db.layoutPositions = {}
    O.Apply()
end
function O.Update(healthChanged)
    if not O.orbs then return end
    O.orbs.health:Update(healthChanged)
    O.orbs.power:Update()
end
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, unit, action, extra, amount)
    if event == "ADDON_LOADED" then
        if unit ~= name then return end
        OrbsUIDB = type(OrbsUIDB) == "table" and OrbsUIDB or {}
        -- Saved settings without a recorded version come from before 1.1.0.
        O.previousVersion = OrbsUIDB.lastVersion or (next(OrbsUIDB) and "1.0" or nil)
        if OrbsUIDB.valueFontSize == nil and type(OrbsUIDB.fontSize) == "number" then
            OrbsUIDB.valueFontSize = (OrbsUIDB.text == "current" or OrbsUIDB.text == "both") and OrbsUIDB.fontSize
                or math.max(10, math.floor(OrbsUIDB.fontSize * 0.72))
        end
        if OrbsUIDB.secondSlot ~= nil then
            -- 1.0.x had an on/off second slot; carry it over to the slot counts.
            local count = OrbsUIDB.secondSlot and 2 or 1
            OrbsUIDB.healthSlots = OrbsUIDB.healthSlots or count
            OrbsUIDB.powerSlots = OrbsUIDB.powerSlots or count
            OrbsUIDB.secondSlot = nil
        end
        defaults(OrbsUIDB, O.defaults)
        O.db = OrbsUIDB
        O.db.size = math.max(100, math.min(260, O.db.size))
        O.db.scale = math.max(0.6, math.min(1.6, O.db.scale))
        O.db.fontSize = math.max(10, math.min(28, O.db.fontSize))
        O.db.valueFontSize = math.max(10, math.min(28, O.db.valueFontSize))
        O.db.lineGap = math.max(0, math.min(24, O.db.lineGap))
        O.db.separatorPadding = math.floor(math.max(0, math.min(6, O.db.separatorPadding)))
        O.db.threshold = math.max(5, math.min(60, O.db.threshold))
        O.db.slotDistance = math.max(-80, math.min(160, O.db.slotDistance))
        O.db.slotGap = math.max(0, math.min(100, O.db.slotGap))
        O.db.healthSlots = math.floor(math.max(1, math.min(O.MAX_SLOTS, O.db.healthSlots)))
        O.db.powerSlots = math.floor(math.max(1, math.min(O.MAX_SLOTS, O.db.powerSlots)))
        O.db.healthSlotAngle = math.max(0, math.min(360, O.db.healthSlotAngle))
        O.db.powerSlotAngle = math.max(0, math.min(360, O.db.powerSlotAngle))
        frame:UnregisterEvent("ADDON_LOADED")
        C_Timer.After(0, function()
            if InCombatLockdown() then O.initPending = true; return end
            O.Init()
        end)
        O.C.Register(frame, "PLAYER_REGEN_ENABLED")
        return
    end
    if event == "PLAYER_REGEN_ENABLED" and O.initPending then O.Init(); return end
    if not O.orbs then return end
    if event == "CHAT_MSG_ADDON" then O.ReceiveVersion(unit, action, extra, amount); return end
    if event == "GROUP_ROSTER_UPDATE" then O.BroadcastVersion(); return end
    if event == "UNIT_COMBAT" then
        if not O.C.Secret(unit) and unit == "player" and not O.C.Secret(action) and action == "WOUND" then
            if O.C.Secret(amount) or (type(amount) == "number" and amount > 0) then
                O.orbs.health:FlashDamage()
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        O.Apply()
    elseif event == "PLAYER_REGEN_DISABLED" then
        for _, orb in pairs(O.orbs) do orb:StopMovingOrSizing() end
    elseif event == "BAG_UPDATE_DELAYED" or event == "BAG_UPDATE" or event == "GET_ITEM_INFO_RECEIVED"
        or event == "ITEM_DATA_LOAD_RESULT" or event == "PLAYER_LEVEL_UP" then
        O.QueueScan()
    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" or event == "UPDATE_BINDINGS" then
        O.RefreshSlotVisuals()
    elseif event == "PLAYER_ENTERING_WORLD" then
        O.Apply()
    elseif not O.C.Secret(unit) and unit == "player" then
        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_HEAL_PREDICTION" then
            O.orbs.health:Update(event == "UNIT_HEALTH")
        else O.orbs.power:Update() end
    end
end)
function O.Init()
    O.initPending = nil
    O.orbs = { health = O.CreateOrb("health"), power = O.CreateOrb("power") }
    O.CreateSlots()
    O.CreateOptions()
    O.InitEditMode()
    O.Apply()
    for _, event in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_COMBAT", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER",
        "UNIT_DISPLAYPOWER", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "BAG_UPDATE_DELAYED",
        "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT", "BAG_UPDATE", "PLAYER_LEVEL_UP",
        "SPELL_UPDATE_COOLDOWN", "BAG_UPDATE_COOLDOWN", "UPDATE_BINDINGS" }) do
        O.C.Register(frame, event)
    end
    O.healEvent = O.C.Register(frame, "UNIT_HEAL_PREDICTION")
    O.InitHeals()
    O.InitNotify(frame, O.previousVersion)
end
SLASH_ORBSUI1 = "/orbs"
SlashCmdList.ORBSUI = function(message)
    if not O.orbs then return end
    message = (message or ""):lower():match("^%s*(.-)%s*$")
    if message == "lock" then O.Change("locked", true)
    elseif message == "unlock" then O.Change("locked", false)
    elseif message == "reset" then O.ResetPositions()
    elseif message == "items" then O.DiagnoseItems()
    elseif message == "heals" then
        -- Report heal-prediction support, then print each change for 20 seconds.
        local h = O.orbs.health
        O.Message(string.format("Heal prediction API: %s; event: %s; option: %s; now: %s",
            tostring(UnitGetIncomingHeals ~= nil), tostring(O.healEvent), tostring(O.db.incomingHeals),
            tostring(UnitGetIncomingHeals and UnitGetIncomingHeals("player"))))
        O.Message("Cast a heal on yourself now; changes print for 20 seconds.")
        O.healWatch = true
        h.lastIncoming = -1
        C_Timer.After(20, function() O.healWatch = nil; O.Message("Heal watch finished.") end)
    elseif message == "debug" then
        local version, build, _, interface = GetBuildInfo()
        O.Message(string.format("Client %s (%s), interface %s; masks: %s; secret values: %s; heal prediction: %s; edit mode: %s (%s)",
            version, build, interface, tostring(O.orbs.health.mask ~= nil), tostring(issecretvalue ~= nil),
            tostring(UnitGetIncomingHeals ~= nil), tostring(EditModeManagerFrame ~= nil), tostring(O.LayoutKey())))
    else O.OpenOptions() end
end
