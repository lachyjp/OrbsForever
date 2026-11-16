local _, O = ...
O.media = "Interface\\AddOns\\OrbsUI\\Media\\"
O.C = {}
local C = O.C
function C.Font()
    local choice = O.db.font
    local object
    if choice == "dialogue" then
        object = DUIFont_Quest_Gossip or DUIFont_Quest_Paragraph or QuestFont or GameFontNormal
    elseif choice == "quest" then object = QuestFont or GameFontNormal
    elseif choice == "default" then object = GameFontNormal end
    if object and object.GetFont then
        local file = object:GetFont()
        if file then return file end
    end
    local builtins = { arial = "Fonts\\ARIALN.TTF", skurri = "Fonts\\skurri.ttf", morpheus = "Fonts\\MORPHEUS.TTF" }
    return builtins[choice] or STANDARD_TEXT_FONT
end
function C.ApplyFont(text, size)
    local style = O.db.fontOutline
    local flags = style == "thin" and "OUTLINE" or style == "thick" and "THICKOUTLINE" or ""
    if not text:SetFont(C.Font(), size, flags) then text:SetFont(STANDARD_TEXT_FONT, size, flags) end
    text:SetShadowColor(0, 0, 0, style == "none" and 0 or 0.85)
    text:SetShadowOffset(1, -1)
end
function C.Secret(value)
    return issecretvalue and issecretvalue(value) or false
end
function C.ItemInfo(id)
    return (C_Item and C_Item.GetItemInfo or GetItemInfo)(id)
end
function C.ItemCount(id)
    return (C_Item and C_Item.GetItemCount or GetItemCount)(id, false, false)
end
function C.ItemSpell(id)
    return (C_Item and C_Item.GetItemSpell or GetItemSpell)(id)
end
function C.BagSize(bag)
    return (C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots)(bag)
end
function C.BagID(bag, slot)
    return (C_Container and C_Container.GetContainerItemID or GetContainerItemID)(bag, slot)
end
function C.Cooldown(id)
    if C_Item and C_Item.GetItemCooldown then return C_Item.GetItemCooldown(id) end
    if GetItemCooldown then return GetItemCooldown(id) end
    if C_Container and C_Container.GetItemCooldown then return C_Container.GetItemCooldown(id) end
    return 0, 0, 0
end
local requestedItems = {}
function C.RequestItem(id)
    if not requestedItems[id] and C_Item and C_Item.RequestLoadItemDataByID then
        requestedItems[id] = true
        C_Item.RequestLoadItemDataByID(id)
    end
end
local scanner
function C.BagTooltip(bag, slot)
    if InCombatLockdown() then return {} end
    if C_TooltipInfo and C_TooltipInfo.GetBagItem then
        local ok, data = pcall(C_TooltipInfo.GetBagItem, bag, slot)
        if ok and not C.Secret(data) and data and not C.Secret(data.lines) then return data.lines or {} end
        return {}
    end
    if not scanner then scanner = CreateFrame("GameTooltip", "OrbsUIScanTooltip", UIParent, "GameTooltipTemplate") end
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner:ClearLines()
    scanner:SetBagItem(bag, slot)
    local lines = {}
    for i = 1, scanner:NumLines() do
        local fs = _G["OrbsUIScanTooltipTextLeft" .. i]
        if fs then lines[#lines + 1] = { leftText = fs:GetText() } end
    end
    scanner:Hide()
    return lines
end
function C.Register(frame, event)
    -- Beta clients do not all expose the same events.
    local ok = pcall(frame.RegisterEvent, frame, event)
    return ok
end
-- Readable false only when the character definitely has no mana pool (warrior, rogue...).
function C.HasMana()
    local maximum = UnitPowerMax("player", 0)
    return C.Secret(maximum) or maximum > 0
end
function C.Power()
    -- "Always track mana" keeps druid forms (and specs like Shadow) on mana. Classes
    -- without mana ignore it rather than showing a permanently empty orb.
    if O.db.manaOnly and C.HasMana() then return 0, "MANA" end
    local kind, token = UnitPowerType("player")
    if C.Secret(kind) or C.Secret(token) then return 0, "MANA" end
    return kind, token
end
function C.Percent(health, kind, current, maximum)
    if not C.Secret(current) and not C.Secret(maximum) then
        return maximum > 0 and current / maximum * 100 or 0
    end
    if CurveConstants and CurveConstants.ScaleTo100 then
        if health and UnitHealthPercent then
            return UnitHealthPercent("player", true, CurveConstants.ScaleTo100)
        elseif not health and UnitPowerPercent then
            return UnitPowerPercent("player", kind, false, CurveConstants.ScaleTo100)
        end
    end
end
