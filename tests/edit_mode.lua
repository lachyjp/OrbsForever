local count = 0
local function check(ok, message) assert(ok, message); count = count + 1 end
local h = O.orbs.health
O.Change("locked", true)
check(not O.Unlocked() and not h.hint.shown and not h.editGlow.shown, "locked without Edit Mode")
-- Simulate the native Edit Mode window and layout API.
local active = 1
C_EditMode = { GetLayouts = function() return { activeLayout = active, layouts = {} } end }
EditModeManagerFrame = CreateFrame("Frame", "EditModeManagerFrame", UIParent)
EditModeManagerFrame:Hide()
O.InitEditMode()
EditModeManagerFrame:Show()
check(O.editModeOpen and O.Unlocked(), "opening Edit Mode unlocks the orbs")
check(h.hint.shown and h.editGlow.shown and h.hint.text == "ORBSFOREVER HEALTH", "Edit Mode highlight and label shown")
check(O.db.locked, "Edit Mode does not change the saved lock setting")
local originalScale = O.db.scale
O.Change("scale", 1)
h.scripts.OnDragStop(h)
check(O.db.layoutPositions.layout1.health[1] == 500 - 960, "drag saved for the active layout")
active = 2
check(O.Position("health")[1] == 500 - 960, "unsaved layout falls back to the last position")
O.SavePosition("health", { 100, 200 })
check(O.db.layoutPositions.layout2.health[1] == 100, "second layout keeps its own position")
active = 1
fire("EDIT_MODE_LAYOUTS_UPDATED"); flush()
check(h.point[4] == 500 - 960, "switching layout moves the orb to that layout's position")
active = 2
fire("EDIT_MODE_LAYOUTS_UPDATED"); flush()
check(h.point[4] == 100, "switching back restores the other layout")
EditModeManagerFrame:Hide(); EditModeManagerFrame.scripts.OnHide(EditModeManagerFrame)
check(not O.editModeOpen and not O.Unlocked() and not h.editGlow.shown, "closing Edit Mode locks the orbs again")
EditModeManagerFrame:Show()
O.Change("editMode", false)
check(not O.Unlocked() and not h.editGlow.shown, "option off ignores Edit Mode")
check(O.Position("health")[1] == 100, "option off uses the plain saved position")
O.Change("editMode", true)
O.ResetPositions()
check(next(O.db.layoutPositions) == nil and O.Position("health")[1] == -260, "reset clears layout positions")
EditModeManagerFrame:Hide(); EditModeManagerFrame.scripts.OnHide(EditModeManagerFrame)
C_EditMode, EditModeManagerFrame = nil, nil
O.Change("scale", originalScale)
return count
