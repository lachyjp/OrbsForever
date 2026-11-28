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
add("healthstone", { 5512, 5511, 5509, 5510, 9421, 19004, 19005, 19006, 19007, 19008,
    19009, 19010, 19011, 19012, 19013, 22103, 22104, 22105 })
add("bandage", { 1251, 2581, 3530, 3531, 6450, 6451, 8544, 8545, 14529, 14530, 21990, 21991 })
add("gem", { 5514, 5513, 8007, 8008, 22044 })
add("rune", { 12662, 20520 })
-- Each orb's slots fill in this order as the slot count goes up.
O.MAX_SLOTS = 4
O.MAX_STROKE = 8
local order = {
    health = { "heal", "food", "healthstone", "bandage" },
    power = { "mana", "water", "gem", "rune" },
}
local categories, slotKeys = {}, {}
for _, kind in ipairs({ "health", "power" }) do
    for i, category in ipairs(order[kind]) do
        local key = kind .. i
        categories[key] = category
        slotKeys[#slotKeys + 1] = key
    end
end
O.slotCategories = categories
O.slotKeys = slotKeys
O.slotLabels = { heal = "health potion", mana = "mana potion", food = "food", water = "water",
    healthstone = "healthstone", bandage = "bandage", gem = "mana gem", rune = "rune" }
function O.SlotCount(kind)
    return kind == "health" and O.db.healthSlots or O.db.powerSlots
end
local function slotInfo(key)
    return key:match("^(%a+)(%d+)$")
end
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
                    for _, category in ipairs({ "heal", "mana", "food", "water", "healthstone", "bandage", "gem", "rune" }) do
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
    for _, key in ipairs(slotKeys) do
        local kind, index = slotInfo(key)
        if tonumber(index) <= O.SlotCount(kind) then
            local id = O.buttons[key].itemID
            O.Message(key .. ": " .. (O.db.pins[key] and "Pinned " or "Auto ") .. (id and tostring(id) or "empty"))
        end
    end
end
-- Key bindings use the CLICK commands declared in Bindings.xml, so they also
-- show under Key Bindings > Orbs. One key per slot; binding a key that already
-- does something else takes it over, as the game's own menu does.
function O.SlotCommand(key) return "CLICK OrbsUI_Slot_" .. key .. ":LeftButton" end
function O.SlotKey(key)
    local binding = GetBindingKey(O.SlotCommand(key))
    return binding
end
function O.BindSlot(key, binding)
    if InCombatLockdown() then
        O.Message("Key bindings can't be changed in combat.")
        return false
    end
    local command = O.SlotCommand(key)
    local old = { GetBindingKey(command) }
    for _, k in ipairs(old) do SetBinding(k) end
    if binding then
        local previous = GetBindingAction(binding)
        if previous and previous ~= "" and previous ~= command then
            O.Message(GetBindingText(binding, "KEY_") .. " no longer does: " .. (_G["BINDING_NAME_" .. previous] or previous))
        end
        SetBinding(binding, command)
    end
    SaveBindings(GetCurrentBindingSet())
    O.RefreshSlotVisuals()
    if O.RefreshOptions then O.RefreshOptions() end
    return true
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
        local s = b.style or O.slotStyles.Ornate
        if s.edge == "orb" then b.edge:SetColorTexture(unpack(O.slotTint[b.kind]))
        elseif s.edge then b.edge:SetColorTexture(unpack(s.edge)) end
        if s.emptyBorder then b.border:SetTexture(id and s.border or s.emptyBorder) end
        b.icon:SetShown(id ~= nil or not (s.emptyBorder or b.hideEmptyIcon))
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
-- Slot looks. inset: icon inset from the 38px button; edge/inner: solid
-- frames behind the icon; border: artwork drawn over it.
local WHITE = "Interface\\Buttons\\WHITE8X8"
local slotStyles = {
    -- stroke: the setting holding this look's frame thickness in pixels;
    -- layout(n) returns the inset, inner and border for that thickness.
    Ornate = { stroke = "slotStrokeOrnate",
        layout = function(n) return math.max(1, n - 1), nil, "SlotBorder" .. n end },
    Blizzard = { inset = 1, crop = 0, border = "Interface\\Buttons\\UI-Quickslot2", borderSize = 70,
        emptyBorder = "Interface\\Buttons\\UI-Quickslot", pushed = true, hotkeyInside = true },
    Clean = { crop = 0.08, edge = { 0, 0, 0, 1 }, stroke = "slotStrokeClean",
        layout = function(n) return n end },
    OrbColour = { crop = 0.08, edge = "orb", stroke = "slotStrokeOrb",
        layout = function(n) return n + 2, n end },
    Round = { round = true, stroke = "slotStrokeRound",
        layout = function(n) return n, nil, "SlotRing" .. n end },
    None = { inset = 0 },
    -- Copies the frame, mask and highlights from the game's own action buttons,
    -- so it matches whatever this client draws (gold frame on modern clients).
    Native = { inset = 1, crop = 0, pushed = true, hotkeyInside = true, native = true },
}
O.slotStyles = slotStyles
local DEPRESS = "Interface\\Buttons\\UI-Quickslot-Depress"
local HILIGHT = "Interface\\Buttons\\ButtonHilight-Square"
local function media(file) return file:find("\\", 1, true) and file or O.media .. file end
local function copyTexture(dst, src)
    local atlas = src.GetAtlas and src:GetAtlas()
    if atlas then dst:SetAtlas(atlas) return true end
    local file = src:GetTexture()
    if not file then return false end
    dst:SetTexture(file)
    if src.GetTexCoord then dst:SetTexCoord(src:GetTexCoord()) end
    return true
end
local function size(f)
    local w, h = f:GetWidth(), f:GetHeight()
    if type(w) == "number" and type(h) == "number" and w > 0 and h > 0 then return w, h end
end
-- Returns false when no action button is available to copy.
local function styleNative(b)
    local src = _G.ActionButton1
    local sw = src and size(src)
    local normal = src and src.GetNormalTexture and src:GetNormalTexture()
    if not sw or not normal or not copyTexture(b.border, normal) then return false end
    local scale = 38 / sw
    local icon = src.icon or src.Icon or _G[(src:GetName() or "") .. "Icon"]
    -- Copy the game's own anchors, scaled, so art that sits off-centre on
    -- purpose (the frame's shadow edge, the icon mask) lines up the same way.
    local function layout(dst, region, fallback)
        local n = region and region.GetNumPoints and region:GetNumPoints() or 0
        dst:ClearAllPoints()
        if n == 0 then fallback(); return end
        for i = 1, n do
            local point, rel, relPoint, x, y = region:GetPoint(i)
            local target = (icon and rel == icon) and b.icon or b
            if target == dst then target = b end
            dst:SetPoint(point, target, relPoint or point, (x or 0) * scale, (y or 0) * scale)
        end
        local w, h = size(region)
        if n == 1 and w then dst:SetSize(w * scale, h * scale) end
    end
    layout(b.icon, icon, function()
        local iw = icon and size(icon)
        local inset = iw and (sw - iw) / 2 * scale or 1
        b.icon:SetPoint("TOPLEFT", inset, -inset)
        b.icon:SetPoint("BOTTOMRIGHT", -inset, inset)
    end)
    layout(b.border, normal, function() b.border:SetAllPoints(b) end)
    b.border:Show()
    local pushed = src.GetPushedTexture and src:GetPushedTexture()
    if pushed and copyTexture(b:GetPushedTexture(), pushed) then
        layout(b:GetPushedTexture(), pushed, function() b:GetPushedTexture():SetAllPoints(b) end)
    end
    if b.mask and src.IconMask and copyTexture(b.mask, src.IconMask) then
        layout(b.mask, src.IconMask, function() b.mask:SetAllPoints(b.icon) end)
    end
    b.hideEmptyIcon = false
    if src.SlotBackground and copyTexture(b.inner, src.SlotBackground) then
        layout(b.inner, src.SlotBackground, function() b.inner:SetAllPoints(b.icon) end)
        b.inner:Show()
        b.hideEmptyIcon = true
    end
    return true
end
function O.StyleSlot(b)
    local s = slotStyles[O.db.slotStyle] or slotStyles.Ornate
    local crop = s.crop or 0.07
    b.style = s
    b.hideEmptyIcon = false
    b.border:SetTexCoord(0, 1, 0, 1)
    b:GetPushedTexture():SetTexture(DEPRESS)
    b:GetPushedTexture():SetTexCoord(0, 1, 0, 1)
    b:GetHighlightTexture():SetTexture(HILIGHT)
    b:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
    local inset, inner, border = s.inset, s.inner, s.border
    if s.stroke then
        local n = math.floor(math.max(1, math.min(O.MAX_STROKE, O.db[s.stroke] or 2)))
        inset, inner, border = s.layout(n)
    end
    b.icon:ClearAllPoints()
    b.icon:SetPoint("TOPLEFT", inset or 0, -(inset or 0))
    b.icon:SetPoint("BOTTOMRIGHT", -(inset or 0), inset or 0)
    b.icon:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
    b.edge:SetAllPoints(b)
    b.edge:SetShown(s.edge ~= nil)
    b.inner:ClearAllPoints()
    b.inner:SetPoint("TOPLEFT", inner or 0, -(inner or 0))
    b.inner:SetPoint("BOTTOMRIGHT", -(inner or 0), inner or 0)
    b.inner:SetColorTexture(0, 0, 0, 1)
    b.inner:SetShown(inner ~= nil)
    b.border:ClearAllPoints()
    if s.borderSize then
        b.border:SetPoint("CENTER")
        b.border:SetSize(s.borderSize, s.borderSize)
    else b.border:SetAllPoints(b) end
    if border then b.border:SetTexture(media(border)) end
    b.border:SetShown(border ~= nil)
    b:GetPushedTexture():ClearAllPoints()
    b:GetPushedTexture():SetAllPoints(b)
    b:GetPushedTexture():SetAlpha(s.pushed and 1 or 0)
    b.count:ClearAllPoints()
    b.hotkey:ClearAllPoints()
    if s.hotkeyInside then
        b.count:SetPoint("BOTTOMRIGHT", -2, 2)
        b.hotkey:SetPoint("TOPRIGHT", -2, -2)
        b.hotkey:SetFontObject("NumberFontNormalSmallGray")
    else
        b.count:SetPoint("BOTTOMRIGHT", -3, 3)
        b.hotkey:SetPoint("TOP", 0, 12)
        b.hotkey:SetFontObject("GameFontNormalSmall")
    end
    if b.mask then
        -- The circle in OrbMask spans 89% of the texture, so pad it out to the icon edge.
        local pad = s.round and 2 or 0
        b.mask:ClearAllPoints()
        b.mask:SetPoint("TOPLEFT", b.icon, "TOPLEFT", -pad, pad)
        b.mask:SetPoint("BOTTOMRIGHT", b.icon, "BOTTOMRIGHT", pad, -pad)
        b.mask:SetTexture(s.round and O.media .. "OrbMask" or WHITE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    end
    if b.cooldown.SetSwipeTexture then b.cooldown:SetSwipeTexture(s.round and O.media .. "OrbMask" or WHITE) end
    if b.cooldown.SetUseCircularEdge then b.cooldown:SetUseCircularEdge(s.round == true) end
    if s.native and not styleNative(b) then
        -- No action button to copy from: fall back to the classic grey frame.
        b.style = nil
        local saved = O.db.slotStyle
        O.db.slotStyle = "Blizzard"
        O.StyleSlot(b)
        O.db.slotStyle = saved
    end
end
-- Orb colour edges follow the orb's fill, including druid form changes.
local slotTint = { health = { 1, 0.16, 0.20, 1 }, power = { 0.10, 0.43, 1, 1 } }
O.slotTint = slotTint
function O.TintSlots(kind, r, g, b)
    local t = slotTint[kind]
    if t[1] == r and t[2] == g and t[3] == b then return end
    t[1], t[2], t[3] = r, g, b
    if not O.buttons then return end
    for _, button in pairs(O.buttons) do
        if button.kind == kind and button.style and button.style.edge == "orb" then
            button.edge:SetColorTexture(r, g, b, 1)
        end
    end
end
function O.StyleSlots()
    if not O.buttons then return end
    for _, b in pairs(O.buttons) do O.StyleSlot(b) end
    O.RefreshSlotVisuals()
end
-- Slots spread along the orb's edge, centred on the chosen angle, one slot
-- width plus the gap apart.
function O.EdgeSlotPoint(size, padding, gap, degrees, index, count)
    local radius = math.max(1, size * 0.476 + 19 + padding)
    local angle = degrees * math.pi / 180
    if count and count > 1 then
        local step = 2 * math.asin(math.min(1, (38 + gap) / (2 * radius)))
        angle = angle - (index - (count + 1) / 2) * step
    end
    return math.cos(angle) * radius, math.sin(angle) * radius
end
function O.LayoutSlots()
    if InCombatLockdown() then O.pending = true; return end
    for key, b in pairs(O.buttons) do
        local kind, index = slotInfo(key)
        index = tonumber(index)
        local health = kind == "health"
        local count = O.SlotCount(kind)
        local orb = O.orbs[kind]
        b:ClearAllPoints()
        b:SetScale(O.db.scale)
        local offset = (math.min(index, count) - (count + 1) / 2) * (38 + O.db.slotGap)
        local distance = O.db.slotDistance
        if O.db.slotPosition == "Ring" then
            local angle = health and O.db.healthSlotAngle or O.db.powerSlotAngle
            local x, y = O.EdgeSlotPoint(O.db.size, distance, O.db.slotGap, angle, index, count)
            b:SetPoint("CENTER", orb, "CENTER", x, y)
        elseif O.db.slotPosition == "Top" then b:SetPoint("BOTTOM", orb, "TOP", offset, distance + 14)
        elseif O.db.slotPosition == "Bottom" then
            local showLabel = health and O.db.healthLabel or not health and O.db.powerLabel
            b:SetPoint("TOP", orb, "BOTTOM", offset, -distance - (showLabel and 14 or 0))
        elseif health then b:SetPoint("LEFT", orb, "RIGHT", distance, -offset)
        else b:SetPoint("RIGHT", orb, "LEFT", -distance, -offset) end
        local enabled = O.db.slots and index <= count
        b:SetAttribute("type1", enabled and "item" or nil)
        b:SetShown(enabled)
    end
end
function O.CreateSlots()
    O.buttons = {}
    for _, key in ipairs(slotKeys) do
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
        b.kind = slotInfo(key)
        b.edge = b:CreateTexture(nil, "BACKGROUND", nil, -2)
        b.inner = b:CreateTexture(nil, "BACKGROUND", nil, -1)
        b.icon = b:CreateTexture(nil, "BACKGROUND")
        b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
        b.cooldown:SetAllPoints(b.icon)
        local overlay = CreateFrame("Frame", nil, b)
        overlay:SetAllPoints(b)
        overlay:SetFrameLevel(b.cooldown:GetFrameLevel() + 2)
        b.border = overlay:CreateTexture(nil, "ARTWORK")
        b.count = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        b.hotkey = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
        -- One mask clips the icon and highlight; Round swaps in a circle.
        if b.CreateMaskTexture then
            b.mask = b:CreateMaskTexture()
            b.mask:SetAllPoints(b.icon)
            b.icon:AddMaskTexture(b.mask)
            b.inner:AddMaskTexture(b.mask)
            b:GetHighlightTexture():AddMaskTexture(b.mask)
        end
        O.StyleSlot(b)
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
            else GameTooltip:SetText("Orbs: " .. O.slotLabels[categories[key]]) end
            GameTooltip:AddLine(O.db.pins[key] and "Pinned item" or "Automatic selection", 0.9, 0.76, 0.5)
            GameTooltip:AddLine("Drag an item here to pin it. Shift-right-click to return to Auto.", 0.8, 0.8, 0.8, true)
            if InCombatLockdown() then GameTooltip:AddLine("Assignments update after combat.", 1, 0.5, 0.2) end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end
