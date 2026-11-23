local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
check(addonPrefixes.OrbsVersion, "version prefix registered")
check(O.VersionNumber("1.10.0") > O.VersionNumber("1.9.9") and O.VersionNumber("1.1") == O.VersionNumber("1.1.0"),
    "versions compare numerically")
check(O.VersionNumber("beta") == nil and O.VersionNumber(nil) == nil, "unknown versions ignored")

-- Update note: once per account, never on a fresh install.
OrbsUIGlobal = nil
check(O.CheckUpdated(nil) == nil and OrbsUIGlobal.lastVersion == O.version, "fresh install stays quiet")
OrbsUIGlobal = nil
local note = O.CheckUpdated("1.0")
check(note and note:find("Consumable slots", 1, true), "first login after updating explains the new feature")
check(O.CheckUpdated("1.0") == nil, "note not repeated on later logins or other characters")
OrbsUIGlobal.lastVersion = "1.0.3"
check(O.CheckUpdated(nil) ~= nil, "account-wide version catches updates on new characters")

-- Patch available.
local before = #messages
O.ReceiveVersion("OrbsVersion", "9.0.0", "GUILD", "Someone")
check(#messages == before + 1 and messages[#messages]:find("patch is available", 1, true), "newer version announced")
O.ReceiveVersion("OrbsVersion", "9.1.0", "PARTY", "Other")
check(#messages == before + 1, "patch notice shown once per session")
O.ReceiveVersion("OtherAddon", "99.0.0", "GUILD", "Someone")
O.ReceiveVersion("OrbsVersion", secret(), "GUILD", "Someone")
check(#messages == before + 1, "other prefixes and restricted text ignored")

-- Older senders get our version back, throttled.
local sent = #addonMessages
O.ReceiveVersion("OrbsVersion", "1.0.3", "GUILD", "Old")
check(#addonMessages == sent + 1 and addonMessages[#addonMessages].message == O.version, "older version answered")
O.ReceiveVersion("OrbsVersion", "1.0.3", "GUILD", "Old2")
check(#addonMessages == sent + 1, "replies throttled per channel")
O.ReceiveVersion("OrbsVersion", "1.0.3", "WHISPER", "Old3")
check(#addonMessages == sent + 1, "only guild and group channels answered")
now = now + 120; inGuild, inGroup = true, true
fire("GROUP_ROSTER_UPDATE")
check(addonMessages[#addonMessages].channel == "PARTY", "joining a group shares the version")
fire("CHAT_MSG_ADDON", "OrbsVersion", "1.0.3", "PARTY", "Old4")
check(#addonMessages == sent + 3, "event path reaches the version check")
inGuild, inGroup = false, false
return checks
