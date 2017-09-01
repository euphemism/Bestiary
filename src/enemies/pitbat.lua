local pitBatMod = RegisterMod("Bestiary - Pit Bat", 1)

local MAX_BAT_COUNT_PER_ROOM = 2

function pitBatMod:newGame(fromSave)
    if not fromSave then
        rng:SetSeed(game:GetSeeds():GetStartSeed(), 0)
    end
end

pitBatMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, pitBatMod.newGame)

--<<<PIT BAT>>>--
function pitBatMod:pitBatControl(bat)
    if bat.Variant == Entities.PIT_BAT.variant then
        local player = Isaac.GetPlayer(0)
        local data = bat:GetData()
        local sprite = bat:GetSprite()
        
        if sprite:IsPlaying("Appear") or sprite:IsFinished("Appear") then
            data.awake = false
            bat.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            bat.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
        end
        
        if not data.awake and (bat.Position:DistanceSquared(player.Position) <= 100^2 or bat.FrameCount >= 3600) then
            data.awake = true
            bat.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            sprite:Play("Reveal", true)
        else
            if sprite:IsEventTriggered("Charge") then
                sprite:Play("Charge", true)
                sfx:Play(SoundEffect.SOUND_SHAKEY_KID_ROAR, 1, 0, false, 1.3)
                
                bat.Velocity = (player.Position - bat.Position):Resized(8)
            elseif sprite:IsPlaying("Charge") then
                bat.Velocity = (bat.Velocity + (player.Position - bat.Position):Resized(3 * player.MoveSpeed)):Resized(10)
                
                if sprite:IsEventTriggered("Move") then
                    sprite:Play("Move", true)
                end
            elseif sprite:IsPlaying("Move") then
                bat.Velocity = bat.Velocity:Resized(math.max(4, bat.Velocity:Length() * 0.8))
                bat:AddVelocity((player.Position - bat.Position):Normalized())
            end
        end
    end
end

pitBatMod:AddCallback(ModCallbacks.MC_NPC_UPDATE, pitBatMod.pitBatControl, Entities.PIT_BAT.id)

function pitBatMod:getPitEdgeCells(room, walkableCellsGrid)

    local width = #walkableCellsGrid
    local height = #walkableCellsGrid[1]
    local indices = {}
    local offsets = {{-1, 0}, {1, 0}, {0, 1}, {-1, -1}, {1, -1}, {1, 1}, {-1, 1}}

    local gridEntityTypes = getGridEntityTypes(getGridEntities(room))
    
    for x = 1, width do
        for y = 1, height do
            if not walkableCellsGrid[x][y] and gridEntityTypes[x][y] == GridEntityType.GRID_PIT then

                --  Check cell above to see if it's a pit.  If not, this is a cell at the top of
                -- a column of cells.  We don't want to spawn bats here, it looks bad.
                if gridEntityTypes[x][y - 1] == GridEntityType.GRID_PIT then
                    for _, offset in pairs(offsets) do
                        local xOffset, yOffset = table.unpack(offset)
                        local currentX, currentY = clamp(x + xOffset, y + yOffset, width, height)

                        if walkableCellsGrid[currentX][currentY] then
                            table.insert(indices, cellToGridIndex(width, x - 1, y - 1))
                            break
                        end
                    end
                end
            end
        end
    end
    
    return indices
end

function pitBatMod:populatePits()
    local room = game:GetLevel():GetCurrentRoom()

    if not room:IsClear() then
        local spawnCount = 0
        local tiles = getWalkableTiles(room)
        local walkable = {}
        
        for x = 1, room:GetGridWidth() do
            walkable[x] = {}

            for y = 1, room:GetGridHeight() do
                walkable[x][y] = false
            end
        end
        
        for _, tile in pairs(tiles) do
            x, y = gridIndexToCell(room:GetGridWidth(), tile)
            walkable[x][y] = true
        end

        pitEdgeCells = pitBatMod:getPitEdgeCells(room, walkable)

        for i = 1, #pitEdgeCells do
            if spawnCount >= MAX_BAT_COUNT_PER_ROOM then
                break
            end
            
            if rng:RandomInt(30) == 1 then --  This needs to be fixed.  More or less guaranteed spawning.
                spawnCount = spawnCount + 1

                Isaac.Spawn(Entities.PIT_BAT.id, Entities.PIT_BAT.variant, 0,
                        room:GetGridPosition(pitEdgeCells[i]), Vector(0, 0), nil)
            end
        end
    end
end

pitBatMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, pitBatMod.populatePits)