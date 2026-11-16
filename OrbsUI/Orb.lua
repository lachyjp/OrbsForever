local _, O = ...
local C = O.C
local styles = { Sphere = true, GradV = true, GradH = true, GradRadial = true, Flat = true }
local globeFrames = {}
for i = 1, 64 do globeFrames[i] = O.media .. string.format("Sphere%02d", i) end
-- Hidden textures report loaded before the GPU has ever drawn them, so the
-- first loop flashed white as each frame was uploaded. Instead, draw every
-- frame for real, tucked under the opaque Empty background, and only start
-- animating once they have all been on screen for a short warm-up.
local GLOBE_WARMUP = 0.5
local globeWarm, globeHost
local globeWarmTime = 0
local function globeReady(host, dt)
    if globeWarmTime >= GLOBE_WARMUP then return true end
    if not globeWarm then
        if not host then return false end
        globeWarm, globeHost = {}, host
        for i, path in ipairs(globeFrames) do
            local t = host:CreateTexture(nil, "BACKGROUND", nil, -8)
            t:SetSize(4, 4)
            t:SetPoint("CENTER")
            t:SetTexture(path)
            globeWarm[i] = t
        end
    end
    for _, t in ipairs(globeWarm) do
        if t.IsObjectLoaded and not t:IsObjectLoaded() then
            globeWarmTime = 0
            return false
        end
    end
    -- Both orbs poll every frame; only the host's clock advances the warm-up.
    if host == globeHost then globeWarmTime = globeWarmTime + (dt or 0) end
    return globeWarmTime >= GLOBE_WARMUP
end
local function interpolation()
    return Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut
end
local function texture(frame, file, layer)
    local t = frame:CreateTexture(nil, layer or "ARTWORK")
    t:SetAllPoints(frame)
    t:SetTexture(O.media .. file)
    return t
end
function O.CreateOrb(key)
    local f = CreateFrame("Frame", "OrbsUI_" .. key, UIParent)
    f.key = key
    f:SetFrameStrata("LOW")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if O.Unlocked() and not InCombatLockdown() then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if InCombatLockdown() then return end
        local x, y = self:GetCenter()
        local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
        O.SavePosition(key, { x * scale - UIParent:GetWidth() / 2, y * scale })
        self:Apply()
        O.LayoutSlots()
    end)
    f.background = texture(f, "Empty", "BACKGROUND")
    -- A round-masked fill drawn behind the main bar; only the part above current health shows.
    local function underlay(r, g, b, a, level)
        local u = CreateFrame("StatusBar", nil, f)
        u:SetAllPoints(f)
        u:SetOrientation("VERTICAL")
        u:SetMinMaxValues(0, 1)
        u:SetValue(0)
        u:SetStatusBarTexture(O.media .. "Sphere")
        u:SetStatusBarColor(r, g, b, a)
        if level then u:SetFrameLevel(level) end
        if u.CreateMaskTexture then
            u.orbMask = u:CreateMaskTexture()
            u.orbMask:SetTexture(O.media .. "OrbMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            u.orbMask:SetAllPoints(f)
            u:GetStatusBarTexture():AddMaskTexture(u.orbMask)
        end
        return u
    end
    if key == "health" then
        f.trail = underlay(1, 0.56, 0.25)
        f.trailMask = f.trail.orbMask
        -- Incoming heals sit above the amber trail, so a heal landing mid-animation stays readable.
        f.incoming = underlay(1, 1, 1, 0.5, f.trail:GetFrameLevel() + 1)
        f.incoming:Hide()
    end
    local bar = CreateFrame("StatusBar", nil, f)
    if f.incoming then bar:SetFrameLevel(f.incoming:GetFrameLevel() + 1) end
    bar:SetAllPoints(f)
    bar:SetOrientation("VERTICAL")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetStatusBarTexture(O.media .. "Flat")
    f.bar = bar
    if bar.CreateMaskTexture then
        f.mask = bar:CreateMaskTexture()
        f.mask:SetTexture(O.media .. "OrbMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        f.mask:SetAllPoints(f)
        bar:GetStatusBarTexture():AddMaskTexture(f.mask)
    end
    local overlay = CreateFrame("Frame", nil, f)
    overlay:SetAllPoints(f)
    overlay:SetFrameLevel(bar:GetFrameLevel() + 2)
    f.rim = texture(overlay, "RimShadow")
    f.gloss = texture(overlay, "Gloss")
    f.bezel = texture(overlay, "Bezel", "OVERLAY")
    f.glow = texture(overlay, "Glow", "OVERLAY")
    f.glow:SetVertexColor(1, 0.08, 0.08)
    f.glow:Hide()
    f.hitFlash = texture(overlay, "OrbMask", "OVERLAY")
    f.hitFlash:SetVertexColor(1, 0.55, 0.42)
    f.hitFlash:Hide()
    f.hitRim = texture(overlay, "Glow", "OVERLAY")
    f.hitRim:SetVertexColor(1, 0.35, 0.22)
    f.hitRim:Hide()
    f.value = overlay:CreateFontString(nil, "OVERLAY")
    f.value:SetPoint("CENTER", 0, 0)
    f.value:SetTextColor(1, 0.96, 0.87)
    f.secondary = overlay:CreateFontString(nil, "OVERLAY")
    f.secondary:SetPoint("TOP", f.value, "BOTTOM", 0, -3)
    f.secondary:SetTextColor(0.94, 0.84, 0.69)
    f.secondary:Hide()
    f.label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.label:SetPoint("TOP", f, "BOTTOM", 0, -5)
    f.label:SetTextColor(0.72, 0.65, 0.52)
    f.hint = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.hint:SetPoint("BOTTOM", f, "TOP", 0, 6)
    f.hint:SetText("DRAG TO MOVE")
    -- Blue Edit Mode-style highlight while the native Edit Mode window is open.
    f.editGlow = texture(overlay, "Glow", "OVERLAY")
    f.editGlow:SetVertexColor(0.35, 0.7, 1)
    f.editGlow:Hide()
    function f:Apply()
        local db = O.db
        self:SetSize(db.size, db.size)
        self:SetScale(db.scale)
        self:ClearAllPoints()
        local pos = O.Position(key)
        self:SetPoint("CENTER", UIParent, "BOTTOM", pos[1] / db.scale, pos[2] / db.scale)
        local unlocked = O.Unlocked()
        local editing = unlocked and O.editModeOpen and db.editMode or false
        self:EnableMouse(unlocked)
        self.hint:SetText(editing and (key == "health" and "ORBSFOREVER HEALTH" or "ORBSFOREVER POWER") or "DRAG TO MOVE")
        self.hint:SetShown(unlocked)
        self.editGlow:SetShown(editing)
        local style = styles[db.style] and db.style or "Sphere"
        self.bar:SetStatusBarTexture(O.media .. style)
        self.globeAnimated = style == "Sphere" and db.animateGlobe
        self.globeTime = self.globeTime or 0
        self.globeFrame = nil
        if self.globeAnimated and globeReady(self) then
            self.globeFrame = math.floor(self.globeTime * 16) % 64 + 1
            self.bar:GetStatusBarTexture():SetTexture(globeFrames[self.globeFrame])
        end
        if self.trail then
            self.animateDamage = db.animateDamage
            self.trail:SetStatusBarTexture(O.media .. style)
            self.trail:SetShown(db.animateDamage)
            self.trailInitialized = false
            self.trailTarget, self.trailValue, self.trailMaximum = nil, nil, nil
            -- Invalidate any delayed update created by a previous configuration.
            self.trailGeneration = (self.trailGeneration or 0) + 1
            self.trailQueued = false
        end
        if self.incoming then
            -- The band sits on top of the health fill and its own value is only the
            -- incoming amount, so restricted values reach the native bar without any
            -- Lua arithmetic. Anything past full health falls outside the round mask.
            self.incoming:SetStatusBarTexture(O.media .. "Flat")
            local fill = self.bar:GetStatusBarTexture()
            self.incoming:ClearAllPoints()
            self.incoming:SetPoint("BOTTOMLEFT", fill, "TOPLEFT", 0, 0)
            self.incoming:SetPoint("BOTTOMRIGHT", fill, "TOPRIGHT", 0, 0)
            self.incoming:SetHeight(db.size)
        end
        self.gloss:SetShown(db.gloss)
        self.rim:SetShown(style == "Sphere")
        self.bezel:SetTexture(O.media .. (db.bezel == "Thin" and "ThinBezel" or "Bezel"))
        self.bezel:SetShown(db.bezel ~= "None")
        local numericOnly = db.text == "current" or db.text == "both"
        C.ApplyFont(self.value, numericOnly and db.valueFontSize or db.fontSize)
        C.ApplyFont(self.label, math.max(10, math.floor(db.fontSize * 0.65)))
        self.label:SetShown(key == "health" and db.healthLabel or key == "power" and db.powerLabel)
        self.stacked = db.text == "combined" or (db.valueBelowPercent and db.text == "percent")
        self.value:ClearAllPoints()
        self.secondary:ClearAllPoints()
        local direction = db.textOrder == "valueFirst" and -1 or 1
        self.value:SetPoint("CENTER", 0, self.stacked and direction * (db.valueFontSize + db.lineGap) / 2 or 0)
        self.secondary:SetPoint("CENTER", 0, -direction * (db.fontSize + db.lineGap) / 2)
        C.ApplyFont(self.secondary, db.valueFontSize)
        local padding = string.rep(" ", db.separatorPadding)
        self.valuePairFormat = "%s" .. padding .. "/" .. padding .. "%s"
        if not db.damageFlash then
            self.flashRemaining = nil
            self.hitFlash:Hide()
            self.hitRim:Hide()
        end
    end
    function f:FlashDamage()
        if key ~= "health" or not O.db.damageFlash then return end
        self.flashRemaining = 0.35
        self.hitFlash:SetAlpha(0.24)
        self.hitRim:SetAlpha(0.95)
        self.hitFlash:Show()
        self.hitRim:Show()
    end
    function f:SetTrail(current, maximum, immediate)
        if not C.Secret(maximum) and maximum <= 0 then maximum, current = 1, 0 end
        local readable = not C.Secret(current) and not C.Secret(maximum)
        self.trail:SetMinMaxValues(0, maximum)
        if immediate or interpolation() or not readable then
            if not immediate and interpolation() then self.trail:SetValue(current, interpolation())
            else self.trail:SetValue(current) end
            self.trailTarget = nil
            if readable then self.trailValue, self.trailMaximum = current, maximum
            else self.trailValue, self.trailMaximum = nil, nil end
        elseif self.trailValue == nil or self.trailMaximum ~= maximum or current >= self.trailValue then
            self.trail:SetValue(current)
            self.trailValue, self.trailMaximum, self.trailTarget = current, maximum, nil
        else
            self.trailTarget = current
        end
        self.trailInitialized = true
    end
    function f:QueueTrail()
        if self.trailQueued then return end
        self.trailQueued = true
        local generation = self.trailGeneration
        C_Timer.After(0.12, function()
            if self.trailGeneration ~= generation then return end
            self.trailQueued = false
            if not self.animateDamage then return end
            -- Re-read and forward directly, including secret values, to the native bar.
            self:SetTrail(UnitHealth("player"), UnitHealthMax("player"), false)
        end)
    end
    -- Heals being cast on the player (by anyone) show as a pale band above current
    -- health; when they land, UNIT_HEALTH fills that band solid and the prediction clears.
    -- The game does not predict potions, food or heal-over-time ticks.
    -- Some clients return the prediction as a restricted (secret) value: it is passed
    -- straight to the band, which is stacked on the fill, so no Lua maths is needed.
    function f:SetIncoming(_, maximum, r, g, b)
        local incoming = O.db.incomingHeals and UnitGetIncomingHeals and UnitGetIncomingHeals("player")
        self.lastIncoming = incoming
        -- Clients without working prediction fall back to the heal the player is casting on themself.
        if O.db.incomingHeals and not C.Secret(incoming) and (not incoming or incoming <= 0) then
            incoming = O.CastHealEstimate and O.CastHealEstimate()
        end
        if not O.db.incomingHeals or incoming == nil
            or (not C.Secret(incoming) and incoming <= 0)
            or (not C.Secret(maximum) and maximum <= 0) then
            self.incoming:Hide()
            return
        end
        self.incoming:SetMinMaxValues(0, maximum)
        self.incoming:SetValue(incoming)
        -- Same hue as the health fill, lifted towards white and see-through.
        self.incoming:SetStatusBarColor(r + (1 - r) * 0.35, g + (1 - g) * 0.35, b + (1 - b) * 0.35, 0.55)
        self.incoming:Show()
    end
    function f:Update(healthChanged)
        local health = key == "health"
        local kind, token = C.Power()
        local current, maximum
        if health then current, maximum = UnitHealth("player"), UnitHealthMax("player")
        else current, maximum = UnitPower("player", kind), UnitPowerMax("player", kind) end
        if health then
            if not C.Secret(current) and not C.Secret(maximum) then
                if healthChanged and self.lastHealth and self.lastMaximum == maximum and current < self.lastHealth then
                    self:FlashDamage()
                end
                self.lastHealth, self.lastMaximum = current, maximum
            else self.lastHealth, self.lastMaximum = nil, nil end
            if self.animateDamage then
                if not self.trailInitialized then self:SetTrail(current, maximum, true)
                else self:QueueTrail() end
            end
        end
        -- Pass restricted values directly to native widgets, never through Lua arithmetic.
        if not C.Secret(maximum) and maximum <= 0 then
            self.bar:SetMinMaxValues(0, 1)
            current = 0
        else self.bar:SetMinMaxValues(0, maximum) end
        -- Health shows the true value immediately; the amber trail animates the lost portion.
        -- Power is polled every frame (see OnUpdate), so it is set directly: easing each
        -- small step would make steady energy regen look like a series of pulses.
        self.bar:SetValue(current)
        if not health then
            if C.Secret(current) or C.Secret(maximum) then self.lastPower, self.lastPowerMax = nil, nil
            else self.lastPower, self.lastPowerMax = current, maximum end
            self.lastPowerKind = kind
        end
        local r, g, b
        if health then r, g, b = unpack(O.db.healthColor)
        elseif O.db.customPowerColor then r, g, b = unpack(O.db.powerColor)
        elseif not O.db.blue and PowerBarColor and PowerBarColor[token] then
            local c = PowerBarColor[token]
            r, g, b = c.r, c.g, c.b
        else r, g, b = 0.10, 0.43, 1 end
        self.bar:SetStatusBarColor(r, g, b)
        if self.incoming then self:SetIncoming(current, maximum, r, g, b) end
        self.label:SetText(health and "HEALTH" or (_G[token] or token or "POWER"))
        local percent = C.Percent(health, kind, current, maximum)
        local mode = O.db.text
        local hasPercent = C.Secret(percent) or percent ~= nil
        local combined = self.stacked and (mode == "percent" or mode == "combined") and hasPercent
        self.secondary:SetShown(combined)
        if combined then
            if mode == "combined" and O.db.valueFormat == "both" then
                self.secondary:SetFormattedText(self.valuePairFormat, current, maximum)
            else self.secondary:SetFormattedText("%s", current) end
        end
        if mode == "none" then self.value:SetText("")
        elseif mode == "current" then self.value:SetFormattedText("%s", current)
        elseif mode == "both" then self.value:SetFormattedText(self.valuePairFormat, current, maximum)
        elseif not C.Secret(percent) and percent == nil then self.value:SetFormattedText("%s", current)
        else self.value:SetFormattedText("%.0f%%", percent) end
        self.low = false
        if health and O.db.pulse and not C.Secret(percent) and percent ~= nil then
            self.low = percent > 0 and percent < O.db.threshold
        end
        self.glow:SetShown(self.low)
    end
    -- UNIT_POWER_UPDATE is throttled, but the client predicts regen between server
    -- updates. Read power every frame, as Blizzard's own player frame does, and only
    -- redraw when it moves. Restricted values cannot be compared, so redraw those always.
    function f:PollPower()
        local kind = C.Power()
        if kind ~= self.lastPowerKind then self:Update(); return end
        local current, maximum = UnitPower("player", kind), UnitPowerMax("player", kind)
        if C.Secret(current) or C.Secret(maximum)
            or current ~= self.lastPower or maximum ~= self.lastPowerMax then
            self:Update()
        end
    end
    local elapsed = 0
    f:SetScript("OnUpdate", function(self, dt)
        if key == "power" and O.db then self:PollPower() end
        -- Not every client sends UNIT_HEAL_PREDICTION, so also poll the prediction itself.
        if self.incoming and O.db and O.db.incomingHeals and UnitGetIncomingHeals then
            local incoming = UnitGetIncomingHeals("player")
            if C.Secret(incoming) or incoming ~= self.lastIncoming then
                self:SetIncoming(UnitHealth("player"), UnitHealthMax("player"), unpack(O.db.healthColor))
                if O.healWatch and not C.Secret(incoming) then
                    O.Message("Incoming heal: " .. tostring(incoming) .. (self.incoming:IsShown() and " (band shown)" or " (band hidden)"))
                end
            end
        end
        if self.globeAnimated and globeReady(self, dt) then
            self.globeTime = (self.globeTime + dt) % 4
            local index = math.floor(self.globeTime * 16) + 1
            if index ~= self.globeFrame then
                self.globeFrame = index
                -- Change the artwork, not the native fill geometry or secret resource value.
                self.bar:GetStatusBarTexture():SetTexture(globeFrames[index])
            end
        end
        if self.low then
            elapsed = elapsed + dt
            self.glow:SetAlpha(0.3 + 0.45 * (0.5 + 0.5 * math.sin(elapsed * 5)))
        end
        if self.flashRemaining then
            self.flashRemaining = math.max(0, self.flashRemaining - dt)
            local fade = (self.flashRemaining / 0.35) ^ 2
            self.hitFlash:SetAlpha(0.24 * fade)
            self.hitRim:SetAlpha(0.95 * fade)
            if self.flashRemaining == 0 then
                self.flashRemaining = nil
                self.hitFlash:Hide()
                self.hitRim:Hide()
            end
        end
        -- Older clients lack native interpolation. Only public numbers reach this path.
        if self.trailTarget then
            self.trailValue = self.trailTarget + (self.trailValue - self.trailTarget) * math.exp(-dt * 9)
            if math.abs(self.trailValue - self.trailTarget) < 0.25 then
                self.trailValue = self.trailTarget
                self.trailTarget = nil
            end
            self.trail:SetValue(self.trailValue)
        end
    end)
    return f
end

-- Heal-cast fallback lives here rather than its own file, so updates only need /reload.
do
    -- Fallback heal prediction: some clients have no (or an empty) UnitGetIncomingHeals,
    -- so while the player casts a heal on themself, estimate it from the spell's description.
    local LOG_SIZE = 40
    local pendingTargets, cast = {}, nil
    local function log(text)
        if not (O.db and O.healWatch) then return end
        -- Kept in the saved settings so a test can be read back after /reload.
        local entries = type(O.db.healLog) == "table" and O.db.healLog or {}
        O.db.healLog = entries
        entries[#entries + 1] = date("%H:%M:%S ") .. text
        while #entries > LOG_SIZE do table.remove(entries, 1) end
    end
    O.HealLog = log
    local function description(spellID)
        if C_Spell and C_Spell.GetSpellDescription then return C_Spell.GetSpellDescription(spellID) end
        if GetSpellDescription then return GetSpellDescription(spellID) end
    end
    local function number(text) return tonumber((text:gsub(",", ""))) end
    -- "Heals a friendly target for 307 to 343." -> 325; "Heals ... for 120." -> 120.
    function O.HealAmount(spellID)
        local text = description(spellID)
        if C.Secret(text) or type(text) ~= "string" then return nil end
        local low, high = text:match("[Hh]eal[^%d]-(%d[%d,]*) to (%d[%d,]*)")
        if low then return (number(low) + number(high)) / 2 end
        local single = text:match("[Hh]eals?[^%d]-for (%d[%d,]*)")
        return single and number(single)
    end
    function O.CastHealEstimate()
        return cast and cast.amount
    end
    local function isSelf(target)
        if C.Secret(target) then return false end
        if type(target) == "string" and target ~= "" then
            return target:match("^[^-]+") == UnitName("player")
        end
        -- No explicit target: the spell lands on the player unless a friendly target is selected.
        return not UnitExists("target") or UnitIsUnit("target", "player") or not UnitIsFriend("player", "target")
    end
    local function refresh()
        if O.orbs then O.orbs.health:Update() end
    end
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(_, event, unit, a, b, c)
        if C.Secret(unit) or unit ~= "player" or not O.db then return end
        if event == "UNIT_SPELLCAST_SENT" then
            -- unit, target name, cast GUID, spell ID
            if not C.Secret(b) and b then pendingTargets[b] = a end
            return
        end
        local castGUID, spellID = a, b
        if C.Secret(castGUID) or C.Secret(spellID) then return end
        if event == "UNIT_SPELLCAST_START" then
            local target = castGUID and pendingTargets[castGUID]
            pendingTargets = {}
            local amount = spellID and O.HealAmount(spellID)
            local api = UnitGetIncomingHeals and UnitGetIncomingHeals("player")
            log(string.format("start %s target=%s self=%s estimate=%s api=%s event=%s",
                tostring(spellID), tostring(target), tostring(isSelf(target)), tostring(amount),
                C.Secret(api) and "secret" or tostring(api), tostring(O.healEvent)))
            if amount and amount > 0 and isSelf(target) then
                cast = { guid = castGUID, amount = amount }
                refresh()
            end
        elseif cast and (castGUID == cast.guid or castGUID == nil) then
            log(event:gsub("UNIT_SPELLCAST_", ""):lower() .. " " .. tostring(spellID))
            if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
                cast = nil
                refresh()
            elseif not cast.ending then
                -- A finished cast's heal reaches health a moment later; hold the band until then
                -- so it turns solid instead of blinking out first.
                cast.ending = true
                local finished = cast
                C_Timer.After(0.4, function()
                    if cast == finished then cast = nil; refresh() end
                end)
            end
        end
    end)
    function O.InitHeals()
        for _, event in ipairs({ "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
            "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_SUCCEEDED" }) do
            C.Register(frame, event)
        end
        log(string.format("loaded v%s api=%s event=%s", O.version, tostring(UnitGetIncomingHeals ~= nil), tostring(O.healEvent)))
    end
end
