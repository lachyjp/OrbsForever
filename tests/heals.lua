local count = 0
local function check(ok, message) assert(ok, message); count = count + 1 end
combat = false
local h = O.orbs.health
local band = h.incoming
O.Change("incomingHeals", true)

-- The band is stacked on the top edge of the health fill, not drawn from the bottom.
local fill = h.bar:GetStatusBarTexture()
check(band.point and band.point[2] == fill and band.point[3] == "TOPRIGHT", "band anchored to the top of the health fill")
check(band.height == O.db.size, "band is as tall as the orb")

-- Readable prediction: the band holds only the incoming amount.
health, maxhealth, incomingHeal = 500, 1000, 120
O.Update(true)
check(band.shown and band.value == 120 and band.max == 1000, "readable incoming heal shown as its own amount")

-- Restricted prediction and health: passed straight through, no Lua arithmetic.
health, maxhealth, incomingHeal = secret(), secret(), secret()
combat = true
O.Update(true)
check(band.shown and issecretvalue(band.value) and issecretvalue(band.max), "secret incoming heal reaches the native band")
h.scripts.OnUpdate(h, 0.01)
check(band.shown and issecretvalue(band.value), "per-frame poll keeps a secret prediction")
combat = false

-- Nothing incoming.
health, maxhealth, incomingHeal = 500, 1000, 0
O.Update(true)
check(not band.shown, "no band without an incoming heal")

-- Readable zero falls back to the player's own heal cast.
spellDescriptions[331] = "Heals a friendly target for 307 to 343."
fire("UNIT_SPELLCAST_START", "player", "cast-1", 331)
check(band.shown and band.value == 325, "self-cast estimate used when the API reports nothing")
fire("UNIT_SPELLCAST_FAILED", "player", "cast-1", 331)
check(not band.shown, "cancelled cast clears the estimate")

-- Option off hides the band even with a prediction.
incomingHeal = 200
O.Change("incomingHeals", false)
check(not band.shown, "option off hides the band")
O.Change("incomingHeals", true)
check(band.shown and band.value == 200, "option on restores the band")

-- Changing orb size keeps the band sized to the orb.
O.Change("size", 180)
check(band.height == 180, "band follows orb size")
O.Change("size", 200)
incomingHeal = nil
O.Update(true)
return count
