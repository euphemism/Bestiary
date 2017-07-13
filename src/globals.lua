local sfx = SFXManager()
local music = MusicManager()
local game = Game()
local rng = RNG()

local function getEntity(name, subt)
    if subt == nil then
        subt = 0
    end
    
    return { id = Isaac.GetEntityTypeByName(name), variant = Isaac.GetEntityVariantByName(name), subtype = subt }
end

local Entities = {
    PIT_BAT = getEntity("Pit Bat")
}