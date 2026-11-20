-- Strict enough to catch unsupported calls and protected mutation in these flows.
-- This is a behavioural test double, not an emulator of WoW's renderer/taint system.
O = {}
frames, timers, messages = {}, {}, {}
combat = false
local methods = {}
local function noop() end
local function safe(self)
    assert(not (combat and self.protected), "protected mutation in combat: " .. (self.name or self.kind))
end
local function widget(kind, name, parent)
    local w = setmetatable({ kind = kind, name = name, parent = parent, scripts = {}, events = {},
        attributes = {}, shown = true, alpha = 1, scale = 1, width = 100, height = 100 }, { __index = methods })
    if name then _G[name] = w end
    return w
end
function CreateFrame(kind, name, parent, template)
    local w = widget(kind, name, parent)
    w.protected = template == "SecureActionButtonTemplate"
    frames[#frames + 1] = w
    if template == "OptionsSliderTemplate" then
        widget("FontString", name .. "Low", w)
        widget("FontString", name .. "High", w)
    end
    return w
end
for _, method in ipairs({ "SetClampedToScreen", "RegisterForDrag", "SetFrameStrata", "SetOrientation",
    "SetAllPoints", "SetVertexColor", "SetFont", "SetTextColor", "SetBackdrop", "SetBackdropColor",
    "SetBackdropBorderColor", "SetValueStep", "SetObeyStepOnDrag", "SetJustifyH", "SetTexCoord",
    "SetHighlightTexture", "RegisterForClicks", "SetOwner", "AddLine", "SetHyperlink", "SetWordWrap", "SetEnabled",
    "SetNormalTexture", "SetHitRectInsets", "LockHighlight", "UnlockHighlight", "SetAutoFocus", "ClearFocus",
    "SetColorTexture", "SetNormalFontObject", "SetFontObject", "SetClipsChildren",
    "EnableKeyboard", "SetPropagateKeyboardInput", "Raise" }) do methods[method] = noop end
function methods:SetHeight(h) self.height = h end
function methods:SetScrollChild(c) self.scrollChild = c end
function methods:GetStringWidth() return #(self.text or "") * 6 end
function methods:GetHighlightTexture() return widget("Texture", nil, self) end
function methods:GetFontString()
    if not self.fontString then self.fontString = widget("FontString", nil, self) end
    return self.fontString
end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
function methods:SetFont(file, size, flags)
    self.fontFile, self.fontSize, self.fontFlags = file, size, flags
    return true
end
function methods:GetFont() return self.fontFile or "font.ttf", 12, "" end
function methods:SetShadowColor(...) self.shadowColor = { ... } end
function methods:SetShadowOffset(...) self.shadowOffset = { ... } end
function methods:SetPoint(...)
    safe(self); self.point = { ... }
    if self.protected and type(self.point[2]) == "table" and self.point[2] ~= UIParent then self.point[2].protected = true end
end
function methods:ClearAllPoints() safe(self); self.point = nil end
function methods:SetSize(w, h) safe(self); self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScale(s) safe(self); self.scale = s end
function methods:GetEffectiveScale() return self.scale end
function methods:GetCenter() return 500, 240 end
function methods:SetMovable() safe(self) end
function methods:EnableMouse(on) safe(self); self.mouse = on ~= false end
function methods:IsMouseEnabled() return self.mouse ~= false end
function methods:StartMoving() safe(self) end
function methods:StopMovingOrSizing() end
function methods:SetShown(b) safe(self); self.shown = b end
function methods:Show() self:SetShown(true); if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() self:SetShown(false) end
function methods:IsShown() return self.shown end
function methods:SetAlpha(a) self.alpha = a end
function methods:GetAlpha() return self.alpha end
function methods:SetFrameLevel(n) self.level = n end
function methods:GetFrameLevel() return self.level or 1 end
function methods:GetName() return self.name end
function methods:SetScript(e, fn) self.scripts[e] = fn end
function methods:HookScript(e, fn)
    local old = self.scripts[e]
    self.scripts[e] = function(...) if old then old(...) end; fn(...) end
end
function methods:RegisterEvent(e) self.events[e] = true end
function methods:UnregisterEvent(e) self.events[e] = nil end
function methods:CreateTexture() return widget("Texture", nil, self) end
function methods:CreateMaskTexture() return widget("Mask", nil, self) end
function methods:CreateFontString() return widget("FontString", nil, self) end
function methods:SetTexture(t) self.texture = t end
function methods:IsObjectLoaded() return self.texture ~= unloadedTexture end
function methods:AddMaskTexture(m) self.mask = m end
function methods:SetStatusBarTexture(t)
    if not self.fill then self.fill = widget("Texture", nil, self) end
    self.fill.texture = t
end
function methods:GetStatusBarTexture() return self.fill end
function methods:SetMinMaxValues(a, b) self.min, self.max = a, b end
function methods:SetValue(v, interpolation)
    self.value = v
    self.interpolation = interpolation
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v) end
end
function methods:SetStatusBarColor(...) self.color = { ... } end
function methods:SetText(t) self.text = t end
function methods:SetFormattedText(fmt, ...) self.format, self.args = fmt, { ... } end
function methods:GetText() return self.text end
function methods:ClearLines() self.lineCount = 0 end
function methods:NumLines() return self.lineCount or 0 end
function methods:SetBagItem(bagID, slot)
    local item = items[GetContainerItemID(bagID, slot)]
    local lines = item and item.tooltip or {}
    self.lineCount = #lines
    for i, line in ipairs(lines) do
        local text = type(line) == "table" and line.leftText or line
        local fs = widget("FontString", self.name .. "TextLeft" .. i, self)
        fs:SetText(text)
    end
end
function methods:SetChecked(v) self.checked = v end
function methods:GetChecked() return self.checked end
function methods:SetAttribute(k, v) safe(self); self.attributes[k] = v end
function methods:SetDesaturated(v) self.desaturated = v end
function methods:SetCooldown(a, b) self.cooldown = { a, b } end
function methods:Clear() self.cooldown = nil end
UIParent = widget("Frame", "UIParent")
UIParent.width, UIParent.height = 1920, 1080
PlayerFrame = widget("Frame", "PlayerFrame")
GameTooltip = widget("Frame", "GameTooltip")
ColorPickerFrame = widget("Frame", "ColorPickerFrame")
function ColorPickerFrame:GetColorRGB() return 0.8, 0.1, 0.2 end
function ColorPickerFrame:SetupColorPickerAndShow(info) self.info = info end
STANDARD_TEXT_FONT = "font.ttf"
UISpecialFrames, SlashCmdList, StaticPopupDialogs = {}, {}, {}
tinsert = table.insert
function print(msg) messages[#messages + 1] = msg end
C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
function flush()
    local pending = timers; timers = {}
    for _, fn in ipairs(pending) do fn() end
end
function fire(event, ...)
    for _, f in ipairs(frames) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end end
end
function InCombatLockdown() return combat end
health, maxhealth, power, maxpower, powerKind, powerToken = 760, 1000, 580, 1000, 0, "MANA"
function UnitHealth() return health end
function UnitHealthMax() return maxhealth end
function UnitGetIncomingHeals() return incomingHeal end
function UnitPower() return power end
function UnitPowerMax(_, kind) if kind == 0 and manaMax ~= nil then return manaMax end return maxpower end
function UnitPowerType() return powerKind, powerToken end
function UnitLevel() return 30 end
PowerBarColor = { MANA = { r = .1, g = .43, b = 1 }, RAGE = { r = 1, g = .1, b = .1 } }
function GetBuildInfo() return "test", "1", "today", 16001 end
function GetBindingKey() return nil end
function GetBindingText(s) return s end
function GetCursorInfo() return "item", cursorItem end
function ClearCursor() cursorItem = nil end
function IsShiftKeyDown() return shift end
bag = { 118, 858, 929, 13446, 2455, 117, 159, 99999 }
items = {
    [118] = { level = 5, required = 1, spell = 100 },
    [858] = { level = 15, required = 5, spell = 101 },
    [929] = { level = 25, required = 15, spell = 102 },
    [13446] = { level = 55, required = 45, spell = 103 },
    [2455] = { level = 15, required = 5, spell = 104 },
    [117] = { level = 5, required = 1, spell = 105 },
    [159] = { level = 5, required = 1, spell = 106 },
    [99999] = { level = 27, required = 15, spell = 102 },
}
cooldownEnabled = true
function GetItemInfo(id)
    local i = items[id]
    if not i or i.uncached then return nil end
    return "Item " .. id, "item:" .. id, 1, i.level, i.required, "Consumable", "Potion", 20, "", 134400, 0, i.class or 0, i.subclass or 1
end
function GetItemSpell(id) if items[id] then return "Spell", items[id].spell end end
function GetItemCount(id)
    for _, candidate in ipairs(bag) do if id == candidate then return 3 end end
    return 0
end
function IsUsableItem(id) return items[id] and not items[id].unusable or false end
function GetContainerNumSlots(b) return b == 0 and #bag or 0 end
function GetContainerItemID(_, s) return bag[s] end
function GetItemCooldown() return 100, 30, cooldownEnabled end
if modern then
    C_Item = { GetItemInfo = GetItemInfo, GetItemSpell = GetItemSpell, GetItemCount = GetItemCount,
        IsUsableItem = IsUsableItem, GetItemCooldown = GetItemCooldown }
    C_Item.RequestLoadItemDataByID = function(id) requestedItem = id end
    C_TooltipInfo = { GetBagItem = function(bagID, slot)
        local item = items[C_Container.GetContainerItemID(bagID, slot)]
        local lines = {}
        for _, line in ipairs(item and item.tooltip or {}) do
            lines[#lines + 1] = type(line) == "table" and line or { leftText = line }
        end
        return { lines = lines }
    end }
    C_Container = { GetContainerNumSlots = GetContainerNumSlots, GetContainerItemID = GetContainerItemID }
    GetItemInfo, GetItemSpell, GetItemCount, IsUsableItem, GetItemCooldown = nil, nil, nil, nil, nil
    GetContainerNumSlots, GetContainerItemID = nil, nil
    Settings = { RegisterCanvasLayoutCategory = function(p) return p end, RegisterAddOnCategory = function(p) registered = p end }
    Enum = { StatusBarInterpolation = { ExponentialEaseOut = 1 } }
else
    function InterfaceOptions_AddCategory(p) registered = p end
end
local secretMT = {}
for _, op in ipairs({ "__add", "__sub", "__mul", "__div", "__lt", "__le", "__tostring" }) do
    secretMT[op] = function() error("secret value inspected by Lua") end
end
function secret() return setmetatable({}, secretMT) end
function issecretvalue(v) return type(v) == "table" and getmetatable(v) == secretMT end
CurveConstants = { ScaleTo100 = {} }
function UnitHealthPercent() return secret() end
function UnitPowerPercent() return secret() end
date = os.date
playerName, targetExists, targetIsPlayer, targetFriendly = "Trolala", false, false, false
function UnitName() return playerName end
function UnitExists() return targetExists end
function UnitIsUnit() return targetIsPlayer end
function UnitIsFriend() return targetFriendly end
spellDescriptions = { [331] = "Heals a friendly target for 307 to 343.", [403] = "Causes 13 to 15 Nature damage to target." }
function GetSpellDescription(id) return spellDescriptions[id] end
