local bestiaryMod = RegisterMod("Bestiary - Globals", 1);
local sfx = SFXManager()
local music = MusicManager()
local game = Game()
local rng = RNG()

bestiaryMod.enemyCount = 0;

-- UPDATE CALLBACK
function bestiaryMod:onUpdate()
  bestiaryMod.enemyCount = 0;
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    --count enemies
    if entity:IsVulnerableEnemy() then
      bestiaryMod.enemyCount = bestiaryMod.enemyCount + 1;
    end
  end     
end

-- Helper function, taken from https://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua
function array_concat(...) 
    local t = {}
    for n = 1,select("#",...) do
        local arg = select(n,...)
        if type(arg)=="table" then
            for _,v in ipairs(arg) do
                t[#t+1] = v
            end
        else
            t[#t+1] = arg
        end
    end
    return t
end

function cellToGridIndex(gridWidth, cellX, cellY)
    return cellY * gridWidth + cellX
end

function gridIndexToCell(gridWidth, index)
    return index % gridWidth, index // gridWidth
end

function getGridEntityAtCell(room, cellX, cellY)
    return room:GetGridEntity(cellToGridIndex(room:GetGridWidth(), cellX, cellY))
end

function getDoorIndices(room)
    indices = {}

    for _, slot in pairs(DoorSlot) do
        door = room:GetDoor(slot)
        
        if door then
            table.insert(indices, door:GetGridIndex())
        end
    end
    
    return indices
end

--  GridEntity:GetType() is broken.
function getGridEntityType(gridEntity)
    if gridEntity then
        return gridEntity.Desc.Type
    else
        return GridEntityType.GRID_NULL --  The game doesn't seem to use this, so we will to represent nil.
    end
end

--  Takes in a GridEntityType
--  Walkable entities are ones that are null, or are decorations or spiderwebs 
function isWalkableTile(entityType)  
    return entityType == GridEntityType.GRID_NULL or
            entityType == GridEntityType.GRID_DECORATION or
            entityType == GridEntityType.GRID_SPIDERWEB
end

-- Returns a two dimensional array of GridEntity; false for nil entities.
function getGridEntities(room)
    width = room:GetGridWidth()
    height = room:GetGridHeight()
    
    entities = {}

    for x = 1, width do
        entities[x] = {}

        for y = 1, height do
            entities[x][y] = getGridEntityAtCell(room, x - 1, y - 1) or false
        end
    end
    
    return entities
end

-- Takes in a two dimensional array of GridEntity, where false stands in for a non-entity.
-- Returns a two dimensional array of GridEntityType; GridEntityType.GRID_NULL for non-entity/floor tiles.
function getGridEntityTypes(gridEntities)
    width = #gridEntities
    height = #gridEntities[1]

    types = {}

    for x = 1, width do
        types[x] = {}

        for y = 1, height do
            types[x][y] = getGridEntityType(gridEntities[x][y])
        end
    end
    
    return types
end

function gridEntityToString(gridEntity)
    
    t = {[GridEntityType.GRID_NULL] = "null",
            [GridEntityType.GRID_DECORATION] = "decoration",
            [GridEntityType.GRID_ROCK] = "rock",
            [GridEntityType.GRID_ROCKB] = "rock b",
            [GridEntityType.GRID_ROCKT] = "rock t",
            [GridEntityType.GRID_ROCK_BOMB] = "rock bomb",
            [GridEntityType.GRID_ROCK_ALT] = "rock alt",
            [GridEntityType.GRID_PIT] = "pit",
            [GridEntityType.GRID_SPIKES] = "spikes",
            [GridEntityType.GRID_SPIKES_ONOFF] = "spikes on/off",
            [GridEntityType.GRID_SPIDERWEB] = "spiderweb",
            [GridEntityType.GRID_LOCK] = "lock",
            [GridEntityType.GRID_TNT] = "tnt",
            [GridEntityType.GRID_FIREPLACE] = "fireplace",
            [GridEntityType.GRID_POOP] = "poop",
            [GridEntityType.GRID_WALL] = "wall",
            [GridEntityType.GRID_DOOR] = "door",
            [GridEntityType.GRID_TRAPDOOR] = "trapdoor",
            [GridEntityType.GRID_STAIRS] = "stairs",
            [GridEntityType.GRID_GRAVITY] = "gravity",
            [GridEntityType.GRID_PRESSURE_PLATE] = "pressure plate",
            [GridEntityType.GRID_STATUE] = "statue",
            [GridEntityType.GRID_SS] = "ss"}
            
    return t[gridEntity and gridEntity.Desc.Type or nil] or "unknown"
end

local function getEntity(name, subt)
    if subt == nil then
        subt = 0
    end
    
    return { id = Isaac.GetEntityTypeByName(name), variant = Isaac.GetEntityVariantByName(name), subtype = subt }
end

function playSound(position, sound, pitch, volume)
  --play sound hack
  local sound_entity = Isaac.Spawn(EntityType.ENTITY_FLY, 0, 0, position, Vector(0,0), nil):ToNPC();
  sound_entity:PlaySound(sound , volume, 0, false, pitch);
  sound_entity:Remove();
end

local Entities = {
    PIT_BAT = getEntity("Pit Bat")
}

bestiaryMod:AddCallback(ModCallbacks.MC_POST_UPDATE, bestiaryMod.onUpdate);