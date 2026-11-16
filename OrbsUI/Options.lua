-- OrbsForever designer: a movable window styled after the PartyPlates designer,
-- with a sidebar of sections, search, a live orb preview, per-setting and
-- per-section reset, and a list of everything changed from the defaults.
-- Controls are built from FIELDS below.

local _, O = ...
BINDING_HEADER_ORBSUI = "OrbsForever"
_G["BINDING_NAME_CLICK OrbsUI_Slot_health1:LeftButton"] = "Use health potion slot"
_G["BINDING_NAME_CLICK OrbsUI_Slot_power1:LeftButton"] = "Use mana potion slot"
_G["BINDING_NAME_CLICK OrbsUI_Slot_health2:LeftButton"] = "Use food slot"
_G["BINDING_NAME_CLICK OrbsUI_Slot_power2:LeftButton"] = "Use water slot"

local GOLD = { 0.88, 0.73, 0.47 }
local W, H = 820, 660
local NAV_W = 176
local PREVIEW_H = 132
local CONTENT_X = NAV_W + 20
local CONTENT_W = W - CONTENT_X - 44
local REFRESH_ICON = "Interface\\Buttons\\UI-RefreshButton"

------------------------------------------------------------------------
-- Schema
------------------------------------------------------------------------

local SECTIONS = {
    { key = "orb", label = "Orb", icon = "Interface\\Icons\\INV_Shield_06" },
    { key = "colours", label = "Colours", icon = "Interface\\Icons\\INV_Misc_Gem_Variety_01" },
    { key = "text", label = "Text", icon = "Interface\\Icons\\INV_Misc_Note_01" },
    { key = "effects", label = "Effects", icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
    { key = "slots", label = "Consumable slots", icon = "Interface\\Icons\\INV_Potion_51" },
    { key = "moving", label = "Moving", icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { key = "changes", divider = true, label = "Changes", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01" },
}

local function hasMana() return O.C.HasMana() end

local FIELDS = {
    -- Orb
    { key = "style", section = "orb", type = "choice", label = "Surface",
      choices = { { "Sphere", "Globe 3D" }, { "GradV", "Vertical" }, { "GradH", "Left to right" },
                  { "GradRadial", "Centre" }, { "Flat", "Flat" } },
      tip = "The liquid inside the orb. Globe 3D is a shaded sphere; the gradients fade from light to dark." },
    { key = "bezel", section = "orb", type = "choice", label = "Frame",
      choices = { { "Ornate", "Antique gold" }, { "Thin", "Fine rim" }, { "None", "Frameless" } } },
    { key = "gloss", section = "orb", type = "toggle", label = "Glass highlight",
      tip = "A soft reflection across the top of each orb." },
    { key = "animateGlobe", section = "orb", type = "toggle", label = "Animate 3D globe",
      tip = "Slowly swirls the liquid. Only used by the Globe 3D surface.",
      enabled = function(db) return db.style == "Sphere" end },
    { key = "size", section = "orb", type = "range", label = "Orb size", min = 100, max = 260, step = 10 },
    { key = "scale", section = "orb", type = "range", label = "Scale", min = 0.6, max = 1.6, step = 0.1,
      tip = "Scales the orbs, their text and their slots together." },

    -- Colours
    { key = "healthColor", section = "colours", type = "color", label = "Health colour" },
    { key = "powerColor", section = "colours", type = "color", label = "Mana / power colour",
      tip = "Choosing a colour turns on \"Use custom mana / power colour\". Cancel in the picker restores the previous colour." },
    { key = "customPowerColor", section = "colours", type = "toggle", label = "Use custom mana / power colour",
      tip = "Overrides the automatic colour for your resource and \"Always use blue for power\". Turn off to go back to automatic colours." },
    { key = "blue", section = "colours", type = "toggle", label = "Always use blue for power",
      tip = "Shows rage, energy and other resources in mana blue.",
      enabled = function(db) return not db.customPowerColor end },

    -- Text
    { key = "text", section = "text", type = "choice", label = "Display",
      choices = { { "percent", "Percentage" }, { "combined", "Percent + value" }, { "current", "Current" },
                  { "both", "Current / max" }, { "none", "Hidden" } },
      get = function(db) if db.text == "percent" and db.valueBelowPercent then return "combined" end return db.text end },
    { key = "textOrder", section = "text", type = "choice", label = "Order",
      choices = { { "percentFirst", "Percentage above value" }, { "valueFirst", "Value above percentage" } },
      enabled = function(db) return db.text == "combined" end,
      tip = "Which line sits on top when both the percentage and the value are shown." },
    { key = "valueFormat", section = "text", type = "choice", label = "Value in Percent + value",
      choices = { { "both", "Current / maximum" }, { "current", "Current only" } },
      enabled = function(db) return db.text == "combined" end },
    { key = "font", section = "text", type = "choice", label = "Font",
      choices = { { "dialogue", "Dialogue UI" }, { "default", "Game default" }, { "quest", "Quest text" },
                  { "arial", "Arial Narrow" }, { "skurri", "Skurri" }, { "morpheus", "Morpheus" } },
      tip = "Dialogue UI matches the DialogueUI addon when it is installed, and falls back to quest text." },
    { key = "fontOutline", section = "text", type = "choice", label = "Font edge",
      choices = { { "shadow", "Soft shadow" }, { "thin", "Thin outline" }, { "thick", "Thick outline" }, { "none", "None" } } },
    { key = "fontSize", section = "text", type = "range", label = "Percentage font size", min = 10, max = 28, step = 1 },
    { key = "valueFontSize", section = "text", type = "range", label = "Value font size", min = 10, max = 28, step = 1 },
    { key = "lineGap", section = "text", type = "range", label = "Gap between lines", min = 0, max = 24, step = 1,
      enabled = function(db) return db.text == "combined" end },
    { key = "separatorPadding", section = "text", type = "range", label = "Spaces on each side of /", min = 0, max = 6, step = 1 },
    { key = "healthLabel", section = "text", type = "toggle", label = "Show health label",
      tip = "Shows HEALTH under the health orb." },
    { key = "powerLabel", section = "text", type = "toggle", label = "Show mana / power label",
      tip = "Shows the name of your resource under the power orb." },

    -- Effects
    { key = "pulse", section = "effects", type = "toggle", label = "Low-health pulse",
      tip = "A red glow pulses around the health orb when your health is low." },
    { key = "threshold", section = "effects", type = "range", label = "Pulse below %", min = 5, max = 60, step = 5, parent = "pulse" },
    { key = "damageFlash", section = "effects", type = "toggle", label = "Flash health on damage" },
    { key = "animateDamage", section = "effects", type = "toggle", label = "Animate health loss",
      tip = "Lost health drains away as an amber band instead of vanishing at once." },
    { key = "incomingHeals", section = "effects", type = "toggle", label = "Show incoming heals",
      tip = "Shows heals being cast on you as a pale band on the health orb. It turns solid when the heal lands. Potions, food and heal-over-time effects are not predicted by the game." },
    { key = "manaOnly", section = "effects", type = "toggle", label = "Always track mana (druid forms)",
      tip = "Keeps the power orb on mana when your form or spec uses another resource, such as a druid in Cat or Bear Form. Does nothing for characters without mana.",
      enabled = function() return hasMana() end },

    -- Slots
    { key = "slots", section = "slots", type = "toggle", label = "Consumable slots",
      tip = "Clickable potion slots next to each orb, filled automatically from your bags." },
    { key = "secondSlot", section = "slots", type = "toggle", label = "Add food and water slots", parent = "slots" },
    { key = "slotPosition", section = "slots", type = "choice", label = "Placement", parent = "slots",
      choices = { { "Side", "Beside orb" }, { "Top", "Above orb" }, { "Bottom", "Below orb" }, { "Ring", "Around edge" } } },
    { key = "slotDistance", section = "slots", type = "range", label = "Distance from orb", min = -80, max = 160, step = 2, parent = "slots" },
    { key = "slotGap", section = "slots", type = "range", label = "Gap between slots", min = 0, max = 100, step = 2, parent = "slots" },
    { key = "healthSlotAngle", section = "slots", type = "range", label = "Health slots angle", min = 0, max = 360, step = 1, parent = "slots",
      tip = "0 right / 90 top / 180 left / 270 bottom. Moving this switches placement to Around edge.", ring = true },
    { key = "powerSlotAngle", section = "slots", type = "range", label = "Mana slots angle", min = 0, max = 360, step = 1, parent = "slots",
      tip = "0 right / 90 top / 180 left / 270 bottom. Moving this switches placement to Around edge.", ring = true },

    -- Moving
    { key = "locked", section = "moving", type = "toggle", label = "Lock orb positions",
      tip = "Unlock to drag the orbs. You can also type /orbs unlock." },
    { key = "editMode", section = "moving", type = "toggle", label = "Move with Edit Mode",
      tip = "Opening the game's Edit Mode unlocks the orbs so you can drag them with the rest of the HUD. Each Edit Mode layout keeps its own orb positions." },
    { key = "hidePlayer", section = "moving", type = "toggle", label = "Fade Blizzard player frame",
      tip = "Hides the default player portrait, since the orbs replace it." },
}
local FIELD = {}
for _, f in ipairs(FIELDS) do FIELD[f.key] = f end
O.FIELDS, O.SECTIONS = FIELDS, SECTIONS

------------------------------------------------------------------------
-- State and small helpers
------------------------------------------------------------------------

local designer
local rows = {}          -- every control row, in schema order
local pages = {}         -- section key -> { scroll, child }
local navButtons = {}
local current = "orb"
local refreshing = false
local query = ""
local preview = {}
local dynamic = {}       -- per-section refreshers

local function Copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = Copy(x) end
    return t
end

local function Same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then
        if type(a) == "number" then return math.abs(a - b) < 0.0001 end
        return a == b
    end
    for k, v in pairs(a) do if not Same(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

local function Get(f) return f.get and f.get(O.db) or O.db[f.key] end
local function IsDefault(key)
    local f = FIELD[key]
    local v = f and Get(f) or O.db[key]
    return Same(v, O.defaults[key])
end

local function Backdrop(f, bg, border)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f:SetBackdropColor(unpack(bg))
    f:SetBackdropBorderColor(unpack(border))
end

local function Label(parent, text, font)
    local l = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    l:SetJustifyH("LEFT")
    l:SetText(text)
    return l
end

local function Button(parent, text, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(text)
    if b:GetFontString() then b:GetFontString():SetFontObject("GameFontHighlightSmall") end
    b:SetScript("OnClick", onClick)
    return b
end

local function Tooltip(frame, title, body)
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if body then GameTooltip:AddLine(body, nil, nil, nil, true) end
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function SectionLabel(key)
    for _, s in ipairs(SECTIONS) do if s.key == key then return s.label end end
    return key
end

local function ValueText(f, v)
    if f.type == "toggle" then return v and "On" or "Off" end
    if f.type == "choice" then
        for _, c in ipairs(f.choices) do if c[1] == v then return c[2] end end
        return tostring(v)
    end
    if f.type == "color" then
        local r, g, b = math.floor(v[1] * 255 + 0.5), math.floor(v[2] * 255 + 0.5), math.floor(v[3] * 255 + 0.5)
        return ("|TInterface\\Buttons\\WHITE8X8:12:12:0:0:8:8:0:8:0:8:%d:%d:%d|t %d, %d, %d"):format(r, g, b, r, g, b)
    end
    if f.step and f.step < 1 then return ("%.1f"):format(v) end
    return tostring(v)
end

local function RowEnabled(f)
    local db = O.db
    local p = f.parent
    while p do
        if not db[p] then return false end
        p = FIELD[p].parent
    end
    if f.enabled and not f.enabled(db) then return false end
    return true
end

local function Matches(f)
    if query == "" then return true end
    return f.label:lower():find(query, 1, true) ~= nil
        or SectionLabel(f.section):lower():find(query, 1, true) ~= nil
        or (f.tip and f.tip:lower():find(query, 1, true) ~= nil)
end

-- Applies several settings at once with a single refresh.
local function ChangeMany(values)
    local last
    for k, v in pairs(values) do
        O.db[k] = Copy(v)
        last = k
    end
    if values.text ~= nil then O.db.valueBelowPercent = false end
    if last then O.Change(last, O.db[last]) end
end

local function ResetField(key) O.Change(key, Copy(O.defaults[key])) end

local function PickColour(key)
    ColorPickerFrame:Hide()
    local old = Copy(O.db[key])
    local oldCustom = O.db.customPowerColor
    local function changed()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        if key == "powerColor" then O.db.customPowerColor = true end
        O.Change(key, { r, g, b })
    end
    local function cancel()
        if key == "powerColor" then O.db.customPowerColor = oldCustom end
        O.Change(key, old)
    end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({ r = old[1], g = old[2], b = old[3], hasOpacity = false,
            swatchFunc = changed, cancelFunc = cancel })
    else
        ColorPickerFrame.func = changed
        ColorPickerFrame.cancelFunc = cancel
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame:SetColorRGB(old[1], old[2], old[3])
        ColorPickerFrame:Show()
    end
end

local function PowerColour()
    if O.db.customPowerColor then return unpack(O.db.powerColor) end
    local _, token = UnitPowerType("player")
    if O.db.manaOnly and hasMana() then token = "MANA" end
    if not O.db.blue and PowerBarColor and token and PowerBarColor[token] then
        local c = PowerBarColor[token]
        return c.r, c.g, c.b
    end
    return 0.10, 0.43, 1
end

------------------------------------------------------------------------
-- Control rows
------------------------------------------------------------------------

local sliderCount = 0

-- Builds one row for field f on page `page` at vertical offset y; returns its height.
local function BuildRow(page, f, y)
    local row = CreateFrame("Frame", nil, page)
    row:SetPoint("TOPLEFT", 8, y)
    row:SetSize(CONTENT_W - 16, 30)
    local r = { field = f, frame = row, controls = {} }

    local reset = CreateFrame("Button", nil, row)
    reset:SetSize(16, 16)
    reset:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -4)
    reset:SetNormalTexture(REFRESH_ICON)
    reset:SetHighlightTexture(REFRESH_ICON)
    reset:GetHighlightTexture():SetAlpha(0.5)
    reset:SetScript("OnClick", function() ResetField(f.key) end)
    Tooltip(reset, "Reset to default", "Default: " .. ValueText(f, O.defaults[f.key]))
    r.reset = reset

    local height
    if f.type == "toggle" then
        local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", 0, 0)
        local t = Label(row, f.label)
        t:SetPoint("LEFT", cb, "RIGHT", 4, 1)
        cb:SetHitRectInsets(0, -(t:GetStringWidth() + 10), 0, 0)
        cb:SetScript("OnClick", function(self) O.Change(f.key, self:GetChecked() and true or false) end)
        if f.tip then Tooltip(cb, f.label, f.tip) end
        r.text = t
        r.controls = { cb }
        r.update = function(v) cb:SetChecked(v) end
        height = 28

    elseif f.type == "range" then
        local t = Label(row, f.label)
        t:SetPoint("TOPLEFT", 4, -2)
        local value = Label(row, "", "GameFontNormal")
        value:SetPoint("LEFT", t, "RIGHT", 8, 0)
        value:SetTextColor(unpack(GOLD))
        sliderCount = sliderCount + 1
        local s = CreateFrame("Slider", "OrbsUIOptionSlider" .. sliderCount, row, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", 6, -22)
        s:SetSize(math.min(380, CONTENT_W - 80), 16)
        s:SetMinMaxValues(f.min, f.max)
        s:SetValueStep(f.step)
        if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
        local low, high = _G[s:GetName() .. "Low"], _G[s:GetName() .. "High"]
        if low then low:SetText(f.min) end
        if high then high:SetText(f.max) end
        local text = _G[s:GetName() .. "Text"]
        if text then text:SetText("") end
        s:SetScript("OnValueChanged", function(_, v)
            if refreshing then return end
            v = math.floor(v / f.step + 0.5) * f.step
            if not Same(v, O.db[f.key]) then
                if f.ring then O.db.slotPosition = "Ring" end
                O.Change(f.key, v)
            end
        end)
        if f.tip then Tooltip(s, f.label, f.tip) end
        r.text = t
        r.controls = { s }
        r.update = function(v)
            s:SetValue(v)
            value:SetText(ValueText(f, v))
        end
        height = 54

    elseif f.type == "choice" then
        local t = Label(row, f.label)
        t:SetPoint("TOPLEFT", 4, -2)
        local n = #f.choices
        local perRow = n <= 5 and n or 3
        local bw = math.min(150, math.floor((CONTENT_W - 50) / perRow) - 4)
        local buttons = {}
        for i, c in ipairs(f.choices) do
            local col, line = (i - 1) % perRow, math.floor((i - 1) / perRow)
            local b = Button(row, c[2], bw, function() O.Change(f.key, c[1]) end)
            b:SetPoint("TOPLEFT", 4 + col * (bw + 4), -20 - line * 26)
            b.value = c[1]
            buttons[i] = b
            if f.tip then Tooltip(b, f.label, f.tip) end
        end
        r.text = t
        r.controls = buttons
        r.update = function(v)
            for _, b in ipairs(buttons) do
                local on = b.value == v
                if on then b:LockHighlight() else b:UnlockHighlight() end
                local fs = b:GetFontString()
                if fs then
                    if on then fs:SetTextColor(unpack(GOLD)) else fs:SetTextColor(0.85, 0.85, 0.85) end
                end
            end
        end
        height = 24 + math.ceil(n / perRow) * 26

    elseif f.type == "color" then
        -- The whole row is the button: swatch plus label.
        local b = CreateFrame("Button", nil, row)
        b:SetSize(260, 26)
        b:SetPoint("TOPLEFT", 2, 0)
        b:SetNormalFontObject("GameFontHighlight")
        b:SetText(f.label)
        local sw = CreateFrame("Frame", nil, b, "BackdropTemplate")
        sw:SetSize(22, 22)
        sw:SetPoint("LEFT", 0, 0)
        Backdrop(sw, { 1, 1, 1, 1 }, { 0, 0, 0, 1 })
        local t = b:GetFontString()
        if t then
            t:ClearAllPoints()
            t:SetPoint("LEFT", sw, "RIGHT", 8, 0)
        else
            t = Label(row, "")
        end
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.06)
        b:SetScript("OnClick", function() PickColour(f.key) end)
        Tooltip(b, f.label, f.tip or "Click to choose a colour.")
        r.text = t
        r.controls = { b }
        r.update = function(v) sw:SetBackdropColor(v[1], v[2], v[3], 1) end
        height = 30
    end

    row:SetHeight(height)
    r.height = height
    rows[#rows + 1] = r
    return height
end

local function UpdateRow(r)
    local f = r.field
    local enabled = RowEnabled(f)
    r.update(Get(f))
    for _, c in ipairs(r.controls) do
        if c.SetEnabled then c:SetEnabled(enabled) end
    end
    local tc = enabled and 1 or 0.5
    r.text:SetTextColor(tc, tc, tc)
    r.reset:SetShown(not IsDefault(f.key))
    r.frame:SetAlpha(Matches(f) and 1 or 0.25)
end

------------------------------------------------------------------------
-- Preview
------------------------------------------------------------------------

local function PreviewOrb(box, key, percent)
    local o = CreateFrame("Frame", nil, box)
    o.key, o.percent = key, percent
    local function tex(parent, layer)
        local t = parent:CreateTexture(nil, layer or "ARTWORK")
        t:SetAllPoints(o)
        return t
    end
    o.background = tex(o, "BACKGROUND")
    o.background:SetTexture(O.media .. "Empty")
    local bar = CreateFrame("StatusBar", nil, o)
    bar:SetAllPoints(o)
    bar:SetOrientation("VERTICAL")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(percent / 100)
    bar:SetStatusBarTexture(O.media .. "Flat")
    if bar.CreateMaskTexture then
        local mask = bar:CreateMaskTexture()
        mask:SetTexture(O.media .. "OrbMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(o)
        bar:GetStatusBarTexture():AddMaskTexture(mask)
    end
    o.bar = bar
    local overlay = CreateFrame("Frame", nil, o)
    overlay:SetAllPoints(o)
    overlay:SetFrameLevel(bar:GetFrameLevel() + 2)
    o.rim = tex(overlay)
    o.rim:SetTexture(O.media .. "RimShadow")
    o.gloss = tex(overlay)
    o.gloss:SetTexture(O.media .. "Gloss")
    o.bezel = tex(overlay, "OVERLAY")
    o.value = overlay:CreateFontString(nil, "OVERLAY")
    o.value:SetTextColor(1, 0.96, 0.87)
    o.secondary = overlay:CreateFontString(nil, "OVERLAY")
    o.secondary:SetTextColor(0.94, 0.84, 0.69)
    o.label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    o.label:SetPoint("TOP", o, "BOTTOM", 0, -5)
    o.label:SetTextColor(0.72, 0.65, 0.52)
    return o
end

local function DrawPreviewOrb(o)
    local db = O.db
    local size = db.size
    o:SetSize(size, size)
    -- Drawn at a fixed height so every size fits the preview box.
    o:SetScale((PREVIEW_H - 28) / size)
    local style = db.style
    o.bar:SetStatusBarTexture(O.media .. style)
    if o.key == "health" then o.bar:SetStatusBarColor(unpack(db.healthColor))
    else o.bar:SetStatusBarColor(PowerColour()) end
    o.rim:SetShown(style == "Sphere")
    o.gloss:SetShown(db.gloss)
    o.bezel:SetTexture(O.media .. (db.bezel == "Thin" and "ThinBezel" or "Bezel"))
    o.bezel:SetShown(db.bezel ~= "None")

    local maximum = 1000
    local currentValue = o.percent * 10
    local padding = string.rep(" ", db.separatorPadding)
    local pair = ("%d" .. padding .. "/" .. padding .. "%d"):format(currentValue, maximum)
    local mode = Get(FIELD.text)
    local main, second
    if mode == "percent" then main = o.percent .. "%"
    elseif mode == "combined" then
        main = o.percent .. "%"
        second = db.valueFormat == "current" and tostring(currentValue) or pair
    elseif mode == "current" then main = tostring(currentValue)
    elseif mode == "both" then main = pair
    else main = "" end
    local numericOnly = mode == "current" or mode == "both"
    O.C.ApplyFont(o.value, numericOnly and db.valueFontSize or db.fontSize)
    O.C.ApplyFont(o.secondary, db.valueFontSize)
    O.C.ApplyFont(o.label, math.max(10, math.floor(db.fontSize * 0.65)))
    o.value:SetText(main)
    o.secondary:SetText(second or "")
    o.secondary:SetShown(second ~= nil)
    local direction = db.textOrder == "valueFirst" and -1 or 1
    o.value:ClearAllPoints()
    o.secondary:ClearAllPoints()
    o.value:SetPoint("CENTER", 0, second and direction * (db.valueFontSize + db.lineGap) / 2 or 0)
    o.secondary:SetPoint("CENTER", 0, -direction * (db.fontSize + db.lineGap) / 2)
    local _, token = UnitPowerType("player")
    o.label:SetText(o.key == "health" and "HEALTH" or (_G[token or ""] or token or "POWER"))
    o.label:SetShown(o.key == "health" and db.healthLabel or o.key == "power" and db.powerLabel)
end

local function BuildPreview(p)
    local box = CreateFrame("Frame", nil, p, "BackdropTemplate")
    box:SetPoint("TOPLEFT", CONTENT_X, -64)
    box:SetSize(W - CONTENT_X - 16, PREVIEW_H)
    Backdrop(box, { 0.09, 0.11, 0.08, 1 }, { 0.30, 0.25, 0.16, 1 })
    if box.SetClipsChildren then box:SetClipsChildren(true) end
    local bgArt = box:CreateTexture(nil, "BACKGROUND", nil, 1)
    bgArt:SetPoint("TOPLEFT", 1, -1)
    bgArt:SetPoint("BOTTOMRIGHT", -1, 1)
    bgArt:SetTexture("Interface\\Buttons\\WHITE8X8")
    if bgArt.SetGradient and CreateColor then
        pcall(bgArt.SetGradient, bgArt, "VERTICAL", CreateColor(0.05, 0.07, 0.05, 1), CreateColor(0.16, 0.20, 0.13, 1))
    else
        bgArt:SetVertexColor(0.1, 0.13, 0.09)
    end

    local cap = Label(box, "PREVIEW", "GameFontNormalSmall")
    cap:SetPoint("TOPLEFT", 10, -8)
    cap:SetTextColor(unpack(GOLD))

    preview.health = PreviewOrb(box, "health", 72)
    preview.power = PreviewOrb(box, "power", 58)
    preview.box = box

    local peek = Button(box, "Hold to peek", 110, nil)
    peek:SetPoint("BOTTOMRIGHT", -10, 8)
    peek:SetScript("OnMouseDown", function() designer:SetAlpha(0.05) end)
    peek:SetScript("OnMouseUp", function() designer:SetAlpha(1) end)
    peek:SetScript("OnHide", function() if designer then designer:SetAlpha(1) end end)
    Tooltip(peek, "Peek at your screen", "Hold to make this window see-through, so you can check your real orbs against your HUD.")

    local flash = Button(box, "Preview damage flash", 150, function() O.orbs.health:FlashDamage() end)
    flash:SetPoint("BOTTOMRIGHT", peek, "TOPRIGHT", 0, 4)
    Tooltip(flash, "Preview damage flash", "Flashes your real health orb as if you were hit.")
    preview.flash = flash
end

local function RefreshPreview()
    if not preview.health then return end
    -- Orbs sit side by side, centred in the space left of the buttons.
    local scale = (PREVIEW_H - 28) / O.db.size
    local spacing = 150 / scale
    preview.health:ClearAllPoints()
    preview.health:SetPoint("CENTER", preview.box, "LEFT", 140 / scale, -2 / scale)
    preview.power:ClearAllPoints()
    preview.power:SetPoint("CENTER", preview.box, "LEFT", 140 / scale + spacing, -2 / scale)
    DrawPreviewOrb(preview.health)
    DrawPreviewOrb(preview.power)
    preview.flash:SetEnabled(O.db.damageFlash)
end

------------------------------------------------------------------------
-- Pages
------------------------------------------------------------------------

local function NewPage(p, key)
    local scroll = CreateFrame("ScrollFrame", nil, p, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", CONTENT_X, -(64 + PREVIEW_H + 10))
    scroll:SetPoint("BOTTOMRIGHT", -32, 44)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(CONTENT_W, 10)
    scroll:SetScrollChild(child)
    scroll:Hide()
    pages[key] = { scroll = scroll, child = child }
    return child
end

local function Note(child, text, y)
    local note = Label(child, text, "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 12, y)
    note:SetWidth(CONTENT_W - 40)
    note:SetTextColor(0.7, 0.7, 0.7)
    return note
end

-- Extra controls that are not plain settings, appended under a section's rows.
local EXTRAS = {}

EXTRAS.colours = function(child, y)
    local b = Button(child, "Reset colours", 130, function()
        O.db.healthColor = Copy(O.defaults.healthColor)
        O.db.powerColor = Copy(O.defaults.powerColor)
        O.db.blue = false
        O.Change("customPowerColor", false)
    end)
    b:SetPoint("TOPLEFT", 12, y - 6)
    Tooltip(b, "Reset colours", "Restores the default health colour and automatic power colours.")
    return 34
end

EXTRAS.text = function(child, y)
    local sample = Note(child, "", y - 6)
    dynamic.text = function()
        local gap = string.rep(" ", O.db.separatorPadding)
        sample:SetText("Value spacing example: 123" .. gap .. "/" .. gap .. "456")
    end
    return 24
end

EXTRAS.slots = function(child, y)
    local sub = Label(child, "SLOT ITEMS", "GameFontNormalSmall")
    sub:SetPoint("TOPLEFT", 12, y - 6)
    sub:SetTextColor(unpack(GOLD))
    y = y - 26
    local pinLabels = {}
    for i, key in ipairs({ "health1", "power1", "health2", "power2" }) do
        local auto = Button(child, "Auto", 60, function() O.Pin(key, nil) end)
        auto:SetPoint("TOPLEFT", 12, y - (i - 1) * 26)
        Tooltip(auto, "Choose automatically", "Clears the pinned item so this slot picks the best match from your bags.")
        local l = Label(child, "", "GameFontHighlight")
        l:SetPoint("LEFT", auto, "RIGHT", 10, 0)
        l:SetWidth(CONTENT_W - 110)
        l:SetWordWrap(false)
        pinLabels[key] = l
    end
    Note(child, "Auto scans matching bag items. Drag an item onto a slot to pin it; shift-right-click a slot to clear it.", y - 4 * 26 - 4)
    dynamic.slots = function()
        for key, l in pairs(pinLabels) do
            local pinned = O.db.pins[key]
            local id = O.buttons[key].itemID
            local itemName = id and O.C.ItemInfo(id)
            l:SetText("|cffe0ba78" .. O.slotCategories[key] .. "|r  " .. (pinned and "Pinned: " or "Auto: ") ..
                (id and (itemName or ("Item " .. id)) or "|cff888888No match|r"))
        end
    end
    return 26 + 4 * 26 + 40
end

EXTRAS.moving = function(child, y)
    local reset = Button(child, "Reset positions", 130, O.ResetPositions)
    reset:SetPoint("TOPLEFT", 12, y - 6)
    Tooltip(reset, "Reset positions", "Puts the orbs back in their default places for the current layout.")
    local lock = Button(child, "Unlock / lock movers", 160, function() O.Change("locked", not O.db.locked) end)
    lock:SetPoint("LEFT", reset, "RIGHT", 8, 0)
    Note(child, "Type /orbs unlock and /orbs lock to do the same from chat.", y - 38)
    return 60
end

local function BuildFieldPages(p)
    for _, s in ipairs(SECTIONS) do
        if s.key ~= "changes" then
            local child = NewPage(p, s.key)
            local y = -6
            local title = Label(child, s.label, "GameFontNormalLarge")
            title:SetPoint("TOPLEFT", 10, y)
            title:SetTextColor(unpack(GOLD))
            y = y - 30
            for _, f in ipairs(FIELDS) do
                if f.section == s.key then
                    y = y - BuildRow(child, f, y) - 4
                end
            end
            if EXTRAS[s.key] then y = y - EXTRAS[s.key](child, y) end
            child:SetHeight(-y + 10)
        end
    end
end

StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["ORBSUI_RESET_ALL"] = {
    text = "Reset every OrbsForever setting to its default? Orb positions and pinned items are kept.",
    button1 = YES or "Yes", button2 = NO or "No",
    OnAccept = function()
        local values = {}
        for _, f in ipairs(FIELDS) do values[f.key] = O.defaults[f.key] end
        ChangeMany(values)
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

local function BuildChangesPage(p)
    local child = NewPage(p, "changes")
    local title = Label(child, "Changes from the defaults", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -6)
    title:SetTextColor(unpack(GOLD))
    local resetAll = Button(child, "Reset everything", 130, function() StaticPopup_Show("ORBSUI_RESET_ALL") end)
    resetAll:SetPoint("TOPRIGHT", child, "TOPRIGHT", -16, -6)

    local empty = Label(child, "Everything is at its default.", "GameFontHighlightSmall")
    empty:SetPoint("TOPLEFT", 14, -40)
    empty:SetTextColor(0.6, 0.6, 0.6)
    local pool = {}

    dynamic.changes = function()
        local n = 0
        for _, f in ipairs(FIELDS) do
            if not IsDefault(f.key) then
                n = n + 1
                local r = pool[n]
                if not r then
                    r = CreateFrame("Frame", nil, child)
                    r:SetSize(CONTENT_W - 30, 24)
                    r.reset = CreateFrame("Button", nil, r)
                    r.reset:SetSize(16, 16)
                    r.reset:SetPoint("LEFT", 0, 0)
                    r.reset:SetNormalTexture(REFRESH_ICON)
                    r.reset:SetHighlightTexture(REFRESH_ICON)
                    r.reset:SetScript("OnClick", function() ResetField(r.key) end)
                    Tooltip(r.reset, "Reset to default")
                    r.section = Label(r, "", "GameFontHighlightSmall")
                    r.section:SetPoint("LEFT", r.reset, "RIGHT", 8, 0)
                    r.section:SetWidth(110)
                    r.section:SetTextColor(unpack(GOLD))
                    r.text = Label(r, "", "GameFontHighlight")
                    r.text:SetPoint("LEFT", r.section, "RIGHT", 6, 0)
                    pool[n] = r
                end
                r.key = f.key
                r.section:SetText(SectionLabel(f.section))
                r.text:SetText(f.label .. ":  |cffffd200" .. ValueText(f, Get(f)) ..
                    "|r  |cff888888(default " .. ValueText(f, O.defaults[f.key]) .. ")|r")
                r:ClearAllPoints()
                r:SetPoint("TOPLEFT", 12, -40 - (n - 1) * 26)
                r:Show()
            end
        end
        for i = n + 1, #pool do pool[i]:Hide() end
        empty:SetShown(n == 0)
        child:SetHeight(60 + n * 26)
    end
end

------------------------------------------------------------------------
-- Navigation and search
------------------------------------------------------------------------

local function SectionMatchCount(key)
    local n = 0
    for _, f in ipairs(FIELDS) do
        if f.section == key and Matches(f) then n = n + 1 end
    end
    return n
end

local function SectionChangeCount(key)
    local n = 0
    for _, f in ipairs(FIELDS) do
        if f.section == key and not IsDefault(f.key) then n = n + 1 end
    end
    return n
end

local function SelectSection(key)
    current = key
    for k, page in pairs(pages) do page.scroll:SetShown(k == key) end
    designer.resetSection:SetShown(key ~= "changes")
    O.RefreshOptions()
end

local function RefreshNav()
    for _, b in ipairs(navButtons) do
        local key = b.key
        local selected = key == current
        b.selected:SetShown(selected)
        local extra = ""
        if key == "changes" then
            local total = 0
            for _, f in ipairs(FIELDS) do if not IsDefault(f.key) then total = total + 1 end end
            if total > 0 then extra = "  |cffffd200" .. total .. "|r" end
        elseif SectionChangeCount(key) > 0 then
            extra = "  |cff888888•|r"
        end
        b.text:SetText(b.label .. extra)
        local dim = query ~= "" and key ~= "changes" and SectionMatchCount(key) == 0
        b:SetAlpha(dim and 0.35 or 1)
        if selected then b.text:SetTextColor(unpack(GOLD)) else b.text:SetTextColor(0.9, 0.9, 0.9) end
    end
end

local function OnSearch(text)
    query = strtrim((text or ""):lower())
    if query ~= "" and current ~= "changes" and SectionMatchCount(current) == 0 then
        for _, s in ipairs(SECTIONS) do
            if s.key ~= "changes" and SectionMatchCount(s.key) > 0 then
                SelectSection(s.key)
                return
            end
        end
    end
    O.RefreshOptions()
end

------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------

function O.CreateOptions()
    local p = CreateFrame("Frame", "OrbsUIOptions", UIParent, "BackdropTemplate")
    designer = p
    O.options = p
    p:SetSize(W, H)
    p:SetPoint("CENTER")
    p:SetScale(math.min(1, (UIParent:GetHeight() - 40) / H))
    p:SetFrameStrata("DIALOG")
    p:SetClampedToScreen(true)
    p:EnableMouse(true)
    p:SetMovable(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving)
    p:SetScript("OnDragStop", p.StopMovingOrSizing)
    Backdrop(p, { 0.035, 0.033, 0.032, 0.98 }, { 0.42, 0.34, 0.22, 1 })
    p:Hide()
    tinsert(UISpecialFrames, "OrbsUIOptions")

    local title = Label(p, "OrbsForever", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -16)
    title:SetTextColor(unpack(GOLD))
    local sub = Label(p, "HEALTH & POWER ORB DESIGNER", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetTextColor(0.7, 0.62, 0.45)

    local close = CreateFrame("Button", nil, p, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() p:Hide() end)

    -- Search
    local ok, search = pcall(CreateFrame, "EditBox", "OrbsUIOptionsSearch", p, "SearchBoxTemplate")
    if not ok or not search then
        search = CreateFrame("EditBox", "OrbsUIOptionsSearch", p, "InputBoxTemplate")
    end
    search:SetSize(220, 22)
    search:SetPoint("TOPRIGHT", -44, -18)
    search:SetAutoFocus(false)
    search:HookScript("OnTextChanged", function(self) OnSearch(self:GetText()) end)
    search:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)
    if search.Instructions then search.Instructions:SetText("Search settings") end
    Tooltip(search, "Search", "Type to find a setting. Sections without a match fade out, and the open section dims settings that don't match.")

    -- Sidebar
    local nav = CreateFrame("Frame", nil, p, "BackdropTemplate")
    nav:SetPoint("TOPLEFT", 12, -64)
    nav:SetPoint("BOTTOMLEFT", 12, 12)
    nav:SetWidth(NAV_W)
    Backdrop(nav, { 0.06, 0.055, 0.05, 1 }, { 0.25, 0.2, 0.13, 1 })
    local navY = -6
    p.tabs = {}
    for _, s in ipairs(SECTIONS) do
        local b = CreateFrame("Button", nil, nav)
        b:SetSize(NAV_W - 8, 31)
        if s.divider then
            local line = nav:CreateTexture(nil, "ARTWORK")
            line:SetColorTexture(0.42, 0.34, 0.22, 0.6)
            line:SetHeight(1)
            line:SetPoint("TOPLEFT", 10, navY - 5)
            line:SetPoint("TOPRIGHT", -10, navY - 5)
            navY = navY - 11
        end
        b:SetPoint("TOPLEFT", 4, navY)
        navY = navY - 33
        b.selected = b:CreateTexture(nil, "BACKGROUND")
        b.selected:SetAllPoints()
        b.selected:SetColorTexture(0.42, 0.34, 0.22, 0.45)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.06)
        local icon = b:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22)
        icon:SetPoint("LEFT", 6, 0)
        icon:SetTexture(s.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        b.text = Label(b, s.label, "GameFontHighlight")
        b.text:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        b.key, b.label = s.key, s.label
        b:SetScript("OnClick", function() SelectSection(s.key) end)
        navButtons[#navButtons + 1] = b
        p.tabs[s.key] = b
    end

    BuildPreview(p)
    BuildFieldPages(p)
    BuildChangesPage(p)
    p.pages = {}
    for k, page in pairs(pages) do p.pages[k] = page.scroll end

    -- Footer
    p.resetSection = Button(p, "Reset this section", 140, function()
        local values = {}
        for _, f in ipairs(FIELDS) do
            if f.section == current then values[f.key] = O.defaults[f.key] end
        end
        ChangeMany(values)
    end)
    p.resetSection:SetPoint("BOTTOMLEFT", CONTENT_X, 14)
    p.status = Label(p, "", "GameFontHighlightSmall")
    p.status:SetPoint("LEFT", p.resetSection, "RIGHT", 14, 0)
    p.status:SetWidth(W - CONTENT_X - 180)
    p.status:SetTextColor(0.65, 0.65, 0.65)

    p:SetScript("OnShow", function() O.RefreshOptions() end)
    p:SetScript("OnHide", function(self) self:SetAlpha(1) end)

    -- Entry under Options > AddOns that opens the designer.
    local categoryPanel = CreateFrame("Frame")
    categoryPanel.name = "OrbsForever"
    local t = categoryPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 20, -20)
    t:SetText("OrbsForever")
    local d = categoryPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    d:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -10)
    d:SetText("Style your health and power orbs with a live preview.")
    local open = CreateFrame("Button", nil, categoryPanel, "UIPanelButtonTemplate")
    open:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -16)
    open:SetSize(220, 30)
    open:SetText("Open the OrbsForever designer")
    open:SetScript("OnClick", function() O.OpenOptions() end)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(categoryPanel, "OrbsForever")
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(categoryPanel)
    end

    SelectSection("orb")
end

function O.RefreshOptions()
    if not designer or not designer:IsShown() then return end
    refreshing = true
    for _, r in ipairs(rows) do
        if r.field.section == current then UpdateRow(r) end
    end
    if dynamic[current] then dynamic[current]() end
    RefreshNav()
    RefreshPreview()
    designer.status:SetText(InCombatLockdown() and "In combat: changes are saved and apply after combat." or
        "Changes save automatically. Drag bag items onto slots to pin. Key bindings: Game Menu > Key Bindings > OrbsForever.")
    refreshing = false
end

function O.OpenOptions()
    if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then InterfaceOptionsFrame:Hide() end
    if GameMenuFrame then GameMenuFrame:Hide() end
    designer:Show()
end
