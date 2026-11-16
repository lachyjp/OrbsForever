local _, O = ...
local C = O.C
-- Catalog and use-spell matches are locale-independent. Tooltip effects cover
-- uncatalogued food, drinks and potions on English clients, including beta items.
local catalog = {}
local function add(category, ids)
    for _, id in ipairs(ids) do catalog[id] = category end
end
add("heal", { 118, 858, 929, 1710, 3928, 13446, 22829, 33447, 18839 })
add("mana", { 2455, 3385, 3827, 6149, 13443, 13444, 22832, 33448, 18841 })
add("food", { 117, 414, 422, 1707, 2070, 2287, 3770, 3771, 4599, 8952,
    4604, 4605, 4606, 4607, 4608, 8948, 4540, 4541, 4542, 4544, 4601, 8950,
    4656, 16169, 17404, 19304, 20857, 22895, 5349, 1113, 1114, 1487, 8075, 8076, 22813 })
add("water", { 159, 1179, 1205, 1708, 1645, 8766, 18300, 28399, 27860,
    5350, 2288, 2136, 3772, 8077, 8078, 8079, 30703, 22018 })
local categories = { health1 = "heal", health2 = "food", power1 = "mana", power2 = "water" }
O.slotCategories = categories
O.catalog = catalog
local spellCategories = {}
local function learnSpells()
    for id, category in pairs(catalog) do
        local _, spell = C.ItemSpell(id)
        if spell then
            spellCategories[spell] = spellCategories[spell] or {}
            spellCategories[spell][category] = true
        end
    end
end
function O.ClassifyItem(id, class, subclass, bag, slot)
    if catalog[id] then return { [catalog[id]] = true }, "catalog" end
    if class ~= 0 then return {}, "not a consumable" end
    local found = {}
    if subclass == 1 or subclass == 5 then
        for _, line in ipairs(C.BagTooltip(bag, slot)) do
            local text = line.leftText
            if not C.Secret(text) and type(text) == "string" then
                text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
                local effect = text:match("%f[%a]restores?%s+(.+)")
                if effect then
                    -- Stop before a later sentence describing a well-fed buff.
                    effect = effect:match("^(.-)%.%s") or effect
                    if effect:find("%f[%a]health%f[%A]") then found[subclass == 5 and "food" or "heal"] = true end
                    if effect:find("%f[%a]mana%f[%A]") then found[subclass == 5 and "water" or "mana"] = true end
                end
            end
        end
    end
    if next(found) then return found, "tooltip effect" end
    local _, spell = C.ItemSpell(id)
    if spell and spellCategories[spell] then return spellCategories[spell], "use spell" end
    return {}, "unrecognised effect; drag to pin"
end
function O.PickItems()
    learnSpells()
    local best, scores, seen = {}, {}, {}
    O.itemDiagnostics = {}
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        for slot = 1, C.BagSize(bag) do
            local id = C.BagID(bag, slot)
            if id and not seen[id] then
                seen[id] = true
                local itemName, _, _, level, required, _, _, _, _, _, _, class, subclass = C.ItemInfo(id)
                if not itemName then
                    C.RequestItem(id)
                    O.itemDiagnostics[#O.itemDiagnostics + 1] = "Item " .. id .. ": waiting for item data"
                elseif class == 0 or catalog[id] then
                    local matched, reason = O.ClassifyItem(id, class, subclass, bag, slot)
                    local labels = {}
                    for _, category in ipairs({ "heal", "mana", "food", "water" }) do
                        if matched[category] then labels[#labels + 1] = category end
                    end
                    local eligible = (required or 0) <= UnitLevel("player")
                    O.itemDiagnostics[#O.itemDiagnostics + 1] = itemName .. " (#" .. id .. "): " ..
                        (#labels > 0 and table.concat(labels, "/") or "no match") .. " / " .. reason ..
                        (eligible and "" or " / requires level " .. required)
                    -- IsUsableItem is a current-state check, not stable eligibility:
                    -- food, water and potions must stay assigned even when temporarily unusable.
                    local score = (level or 0) * 1000 + (required or 0)
                    if eligible then
                        for category in pairs(matched) do
                            if not scores[category] or score > scores[category] or
                                (score == scores[category] and id > best[category]) then
                                best[category], scores[category] = id, score
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end
function O.DiagnoseItems()
    if InCombatLockdown() then O.Message("Run /orbs items after combat to inspect Auto selection."); return end
    O.RefreshSlots()
    O.Message("Auto selection: " .. #O.itemDiagnostics .. " consumables or uncached items in bags.")
    for _, message in ipairs(O.itemDiagnostics) do O.Message(message) end
    for _, key in ipairs({ "health1", "health2", "power1", "power2" }) do
        local id = O.buttons[key].itemID
        O.Message(key .. ": " .. (O.db.pins[key] and "Pinned " or "Auto ") .. (id and tostring(id) or "empty"))
    end
end
function O.Pin(key, id)
    O.db.pins[key] = id
    if InCombatLockdown() then
        O.pending = true
        O.Message("Assignment saved; the button keeps its current item until combat ends.")
    else O.RefreshSlots() end
    if O.RefreshOptions then O.RefreshOptions() end
end
function O.QueueScan()
    if O.scanQueued then return end
    O.scanQueued = true
    C_Timer.After(0.15, function()
        O.scanQueued = false
        O.RefreshSlots()
    end)
end
function O.RefreshSlots()
    if not O.buttons then return end
    if InCombatLockdown() then
        O.pending = true
        O.RefreshSlotVisuals()
        return
    end
    local best = O.PickItems()
    for key, b in pairs(O.buttons) do
        b.itemID = O.db.pins[key] or best[categories[key]]
        b:SetAttribute("item1", b.itemID and ("item:" .. b.itemID) or nil)
    end
    O.RefreshSlotVisuals()
    if O.RefreshOptions then O.RefreshOptions() end
end
function O.RefreshSlotVisuals()
    if not O.buttons then return end
    for _, b in pairs(O.buttons) do
        local id = b.itemID
        if id then
            local _, _, _, _, _, _, _, _, _, icon = C.ItemInfo(id)
            b.icon:SetTexture(icon or 134400)
            local count = C.ItemCount(id)
            b.count:SetText(count)
            if not C.Secret(count) then b.icon:SetDesaturated(count == 0) end
            local start, duration, enabled = C.Cooldown(id)
            if C.Secret(start) or C.Secret(duration) or C.Secret(enabled) then
                b.cooldown:SetCooldown(start, duration)
            elseif enabled ~= 0 and enabled ~= false and duration and duration > 0 then
                b.cooldown:SetCooldown(start, duration)
            else b.cooldown:Clear() end
        else
            b.icon:SetTexture(O.media .. "SlotEmpty")
            b.icon:SetDesaturated(false)
            b.count:SetText("")
            b.cooldown:Clear()
        end
        local binding = GetBindingKey("CLICK " .. b:GetName() .. ":LeftButton")
        b.hotkey:SetText(binding and GetBindingText(binding, "KEY_") or "")
    end
end
function O.EdgeSlotPoint(size, padding, gap, degrees, second, paired)
    local radius = math.max(1, size * 0.476 + 19 + padding)
    local angle = degrees * math.pi / 180
    if paired then
        local spread = math.asin(math.min(1, (38 + gap) / (2 * radius)))
        angle = angle + (second and -spread or spread)
    end
    return math.cos(angle) * radius, math.sin(angle) * radius
end
function O.LayoutSlots()
    if InCombatLockdown() then O.pending = true; return end
    for key, b in pairs(O.buttons) do
        local health = key:find("health", 1, true) == 1
        local second = key:sub(-1) == "2"
        local orb = O.orbs[health and "health" or "power"]
        b:ClearAllPoints()
        b:SetScale(O.db.scale)
        local spacing = (38 + O.db.slotGap) / 2
        local offset = second and spacing or -spacing
        if not O.db.secondSlot then offset = 0 end
        local distance = O.db.slotDistance
        if O.db.slotPosition == "Ring" then
            local angle = health and O.db.healthSlotAngle or O.db.powerSlotAngle
            local x, y = O.EdgeSlotPoint(O.db.size, distance, O.db.slotGap, angle, second, O.db.secondSlot)
            b:SetPoint("CENTER", orb, "CENTER", x, y)
        elseif O.db.slotPosition == "Top" then b:SetPoint("BOTTOM", orb, "TOP", offset, distance + 14)
        elseif O.db.slotPosition == "Bottom" then
            local showLabel = health and O.db.healthLabel or not health and O.db.powerLabel
            b:SetPoint("TOP", orb, "BOTTOM", offset, -distance - (showLabel and 14 or 0))
        elseif health then b:SetPoint("LEFT", orb, "RIGHT", distance, -offset)
        else b:SetPoint("RIGHT", orb, "LEFT", -distance, -offset) end
        local enabled = O.db.slots and (not second or O.db.secondSlot)
        b:SetAttribute("type1", enabled and "item" or nil)
        b:SetShown(enabled)
    end
end
function O.CreateSlots()
    O.buttons = {}
    for _, key in ipairs({ "health1", "health2", "power1", "power2" }) do
        local b = CreateFrame("Button", "OrbsUI_Slot_" .. key, UIParent, "SecureActionButtonTemplate")
        O.buttons[key] = b
        b:SetSize(38, 38)
        b:SetFrameStrata("MEDIUM")
        b:RegisterForClicks("AnyUp")
        b:SetAttribute("useOnKeyDown", false)
        b:RegisterForDrag("LeftButton")
        b:SetAttribute("type1", "item")
        b:SetAttribute("type2", "")
        b:SetAttribute("shift-type2", "")
        b.icon = b:CreateTexture(nil, "BACKGROUND")
        b.icon:SetPoint("TOPLEFT", 3, -3)
        b.icon:SetPoint("BOTTOMRIGHT", -3, 3)
        b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
        b.cooldown:SetAllPoints(b.icon)
        local overlay = CreateFrame("Frame", nil, b)
        overlay:SetAllPoints(b)
        overlay:SetFrameLevel(b.cooldown:GetFrameLevel() + 2)
        b.border = overlay:CreateTexture(nil, "ARTWORK")
        b.border:SetAllPoints(b)
        b.border:SetTexture(O.media .. "SlotBorder")
        b.count = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        b.count:SetPoint("BOTTOMRIGHT", -3, 3)
        b.hotkey = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        b.hotkey:SetPoint("TOP", 0, 12)
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b:SetScript("OnReceiveDrag", function()
            local cursorType, id = GetCursorInfo()
            if cursorType == "item" then O.Pin(key, id); ClearCursor() end
        end)
        b:HookScript("PostClick", function(_, button, down)
            if down then return end
            if button == "RightButton" and IsShiftKeyDown() then O.Pin(key, nil) end
        end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.itemID then GameTooltip:SetHyperlink("item:" .. self.itemID)
            else GameTooltip:SetText("OrbsForever: " .. categories[key]) end
            GameTooltip:AddLine(O.db.pins[key] and "Pinned item" or "Automatic selection", 0.9, 0.76, 0.5)
            GameTooltip:AddLine("Drag an item here to pin it. Shift-right-click to return to Auto.", 0.8, 0.8, 0.8, true)
            if InCombatLockdown() then GameTooltip:AddLine("Assignments update after combat.", 1, 0.5, 0.2) end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end
