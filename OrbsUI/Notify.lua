-- Chat notices: what's new after an update, and a patch-available warning when
-- a guild or group member runs a newer Orbs. Versions are shared over a hidden
-- addon channel, since addons cannot check CurseForge themselves.
local _, O = ...
local PREFIX = "OrbsVersion"

-- One short line per release that adds something worth finding in the menu.
O.whatsNew = {
    ["1.1.0"] = "Each orb can now have up to four consumable slots. Find it in /orbs > Consumable slots > Health orb slots and Mana orb slots.",
}

-- "1.10.2" -> 1010002, so versions compare as numbers. Unknown text -> nil.
function O.VersionNumber(version)
    if type(version) ~= "string" then return nil end
    local major, minor, patch = version:match("^(%d+)%.(%d+)%.?(%d*)$")
    if not major then return nil end
    return tonumber(major) * 1000000 + tonumber(minor) * 1000 + (tonumber(patch) or 0)
end

-- The last version seen is saved for the whole account, so the note shows on the
-- first login after an update and not again on other characters.
-- Returns the note to print, or nil.
function O.CheckUpdated(previous)
    OrbsUIGlobal = type(OrbsUIGlobal) == "table" and OrbsUIGlobal or {}
    previous = OrbsUIGlobal.lastVersion or previous
    OrbsUIGlobal.lastVersion = O.version
    O.db.lastVersion = O.version
    if not previous or previous == O.version then return nil end
    local note = O.whatsNew[O.version]
    return "Updated to " .. O.version .. "." .. (note and (" " .. note) or "")
end

local registerPrefix = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
local sendMessage = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
local lastSent = {}
local warned = false

local function send(channel)
    if not sendMessage then return end
    local now = GetTime and GetTime() or 0
    if lastSent[channel] and now - lastSent[channel] < 60 then return end
    lastSent[channel] = now
    pcall(sendMessage, PREFIX, O.version, channel)
end

local function groupChannel()
    if LE_PARTY_CATEGORY_INSTANCE and IsInGroup and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
end

function O.BroadcastVersion()
    if IsInGuild and IsInGuild() then send("GUILD") end
    local channel = groupChannel()
    if channel then send(channel) end
end

function O.ReceiveVersion(prefix, message, channel, sender)
    local C = O.C
    if C.Secret(prefix) or C.Secret(message) or prefix ~= PREFIX then return end
    local theirs, mine = O.VersionNumber(message), O.VersionNumber(O.version)
    if not theirs or not mine or theirs == mine then return end
    if theirs > mine then
        if not warned then
            warned = true
            O.Message("A patch is available: Orbs " .. message .. " is out (you have " .. O.version ..
                "). Update it from CurseForge.")
        end
    elseif not C.Secret(channel) and (channel == "GUILD" or channel == "PARTY" or channel == "RAID"
        or channel == "INSTANCE_CHAT") then
        -- Let someone on an older version know, at most once a minute per channel.
        send(channel)
    end
end

function O.InitNotify(frame, previous)
    if registerPrefix then pcall(registerPrefix, PREFIX) end
    O.C.Register(frame, "CHAT_MSG_ADDON")
    O.C.Register(frame, "GROUP_ROSTER_UPDATE")
    local note = O.CheckUpdated(previous)
    -- Wait a few seconds so the notes are not buried under login spam.
    C_Timer.After(8, function()
        if note then O.Message(note) end
        O.BroadcastVersion()
    end)
end
