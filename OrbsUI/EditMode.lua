local _, O = ...
-- Native Edit Mode integration. Addon frames cannot join Blizzard's layout
-- system itself, so the orbs unlock while the Edit Mode window is open and
-- keep a separate saved position for each Edit Mode layout.
function O.LayoutKey()
    if not (O.db and O.db.editMode and C_EditMode and C_EditMode.GetLayouts) then return end
    local ok, info = pcall(C_EditMode.GetLayouts)
    if ok and type(info) == "table" and type(info.activeLayout) == "number" then
        return "layout" .. info.activeLayout
    end
end
function O.Position(key)
    local layout = O.LayoutKey()
    local saved = layout and O.db.layoutPositions[layout]
    return saved and saved[key] or O.db.positions[key]
end
function O.SavePosition(key, pos)
    -- The plain position is the fallback for layouts that have no saved copy yet.
    O.db.positions[key] = pos
    local layout = O.LayoutKey()
    if layout then
        O.db.layoutPositions[layout] = O.db.layoutPositions[layout] or {}
        O.db.layoutPositions[layout][key] = { pos[1], pos[2] }
    end
end
function O.Unlocked()
    return not O.db.locked or (O.editModeOpen and O.db.editMode) or false
end
function O.SetEditMode(active)
    active = active and true or false
    if O.editModeOpen == active then return end
    O.editModeOpen = active
    if not active and O.orbs then
        for _, orb in pairs(O.orbs) do orb:StopMovingOrSizing() end
    end
    if O.orbs then O.Apply() end
end
function O.InitEditMode()
    local manager = EditModeManagerFrame
    if manager and manager.HookScript then
        manager:HookScript("OnShow", function() O.SetEditMode(true) end)
        manager:HookScript("OnHide", function() O.SetEditMode(false) end)
        O.editModeOpen = manager:IsShown() and true or false
    end
    local events = CreateFrame("Frame")
    O.C.Register(events, "EDIT_MODE_LAYOUTS_UPDATED")
    -- Fires when the active layout changes; place the orbs for the new layout.
    events:SetScript("OnEvent", function() C_Timer.After(0, O.Apply) end)
end
