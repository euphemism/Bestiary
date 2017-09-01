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

--  Clamps coordinates (1-indexed) within specified bounds.
function clamp(x, y, width, height)
    local newX = x
    local newY = y

    if not ((1 <= x) and (x <= width)) then
        newX = (x < 1) and 1 or width
    end

    if not ((1 <= y) and (y <= height)) then
        newY = (y < 1) and 1 or height
    end

    return newX, newY
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
    local indices = {}

    for _, slot in pairs(DoorSlot) do
        local door = room:GetDoor(slot)
        
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
--  Checks if the entity is something Isaac can walk across.
--  Spikes aren't included. 
function isWalkableTile(entityType)  
    return entityType == GridEntityType.GRID_NULL or
            entityType == GridEntityType.GRID_DECORATION or
            entityType == GridEntityType.GRID_POOP or
            entityType == GridEntityType.GRID_SPIDERWEB or
            entityType == GridEntityType.GRID_PRESSURE_PLATE
end

-- Returns a two dimensional array of GridEntity; false for nil entities.
function getGridEntities(room)
    local width = room:GetGridWidth()
    local height = room:GetGridHeight()
    
    local entities = {}

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
    local width = #gridEntities
    local height = #gridEntities[1]

    local types = {}

    for x = 1, width do
        types[x] = {}

        for y = 1, height do
            types[x][y] = getGridEntityType(gridEntities[x][y])
        end
    end
    
    return types
end

--[[
--  Takes in a two dimensional array, 
--  start coordinates (1-indexed), offsets for the cells to be searched around the current cell,
--  a matching function for the elements of the grid,
--  and a set of optional arguments to pass along to the matching function.
--  The matching function will receive an element of the grid, and its xy-coordinates.
--  The matching function must return true or false.
--  Returns array of contiguous indices matched by the matching function and found from starting position.
]]--
function gridFloodFill(grid, startX, startY, offsets, matchingFunction, ...)   
    local width = #grid
    local height = #grid[1]
    local indices = {}
    local visited = {}
    
    for x = 1, width do
        visited[x] = {}

        for y = 1, height do
            visited[x][y] = false
        end
    end
    
    local stack = {{startX, startY}}

    while #stack > 0 do
        local x, y = table.unpack(stack[#stack])
        table.remove(stack, #stack)
        
        visited[x][y] = true

        if matchingFunction(grid[x][y], x, y, arg and table.unpack(arg)) then
            table.insert(indices, cellToGridIndex(width, x, y))

            for _, offset in pairs(offsets) do
                local xOffset, yOffset = table.unpack(offset)
                local curX, curY = clamp(x + xOffset, y + yOffset, width, height)

                if not visited[curX][curY] then
                    table.insert(stack, {curX, curY})
                end
            end
        end
    end

    return indices
end

-- Returns an array of grid indices of cells that are directly reachable from the doors.
function getWalkableTiles(room)
    local doors = getDoorIndices(room)
    local width = room:GetGridWidth()
    local height = room:GetGridHeight()

    local tileX, tileY = nil, nil
    local offsets = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}} -- Four-way flood fill.

    for _, door in pairs(doors) do --  This bit finds a walkable tile in front of a door.
        local doorX, doorY = gridIndexToCell(width, door)

        for __, offset in pairs(offsets) do
            local xOffset, yOffset = table.unpack(offset)
            local x, y = clamp(doorX + xOffset, doorY + yOffset, width, height)

            if isWalkableTile(getGridEntityType(getGridEntityAtCell(room, x, y))) then
                tileX, tileY = x, y

                break
            end
        end

        if tileX then
            break
        end
    end

    if tileX then
        local grid = getGridEntityTypes(getGridEntities(room))

        --  tileX, tileY are in game coordinates, need to add 1 because Lua is 1-indexed.
        return gridFloodFill(grid, tileX + 1, tileY + 1, offsets, isWalkableTile)
    else
        --  Some sort of error handling is needed, but I don't think this should ever be hit.
        Isaac.DebugString("ERROR: getWalkableTiles() No walkable tile found in front of any doors.")
    end
end

function gridEntityToString(gridEntity)
    
    local t = {[GridEntityType.GRID_NULL] = "null",
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