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

function pitBatMod:generatePitTable()
    local room = game:GetLevel():GetCurrentRoom()
    local pitTable = {}

    for col = 1, room:GetGridWidth() do
        pitTable[col] = {}

        for row = 1, room:GetGridHeight() do
            gridEntity = getGridEntityAtCell(room, col - 1, row - 1)

            if gridEntity then
                pitTable[col][row] = not not gridEntity:ToPit()  -- boolean logic with nil is funny, I think this is an okay way of doing this.
            else
                pitTable[col][row] = false
            end
        end
    end

    return pitTable
end

function pitBatMod:extractPitEdgeCellsHelper(pitTable, visitedTable, cellX, cellY, width, height, indices)
    isPit = pitTable[cellX][cellY]

    if visitedTable[cellX][cellY] or not isPit then
        return isPit and 0 or 1 --  Return 0 if pit, 1 if not.
    end

    visitedTable[cellX][cellY] = true
    numberOfNonPitNeighbors = 0

    function clamp(x, y)
        if not ((1 <= x) and (x <= width)) then
            x = (x < 1) and 1 or width
        end

        if not ((1 <= y) and (y <= height)) then
            y = (y < 1) and 1 or height
        end

        return x, y
    end

    for xOffset = -1, 1 do
        for yOffset = -1, 1 do
            if (xOffset ~= 0) or (yOffset ~= 0) then
                x, y = clamp(cellX + xOffset, cellY + yOffset)

                numberOfNonPitNeighbors = numberOfNonPitNeighbors + pitBatMod:extractPitEdgeCellsHelper(
                        pitTable, visitedTable, x, y, width, height, indices)            
            end
        end    
    end

    if numberOfNonPitNeighbors > 0 then
        table.insert(indices, cellToGridIndex(width, cellX - 1, cellY - 1))
    end

    return isPit and 0 or 1
end

-- Returns an "array" of grid indices containing pit edge cells.
function pitBatMod:extractPitEdgeCells(pitTable)
    width = #pitTable
    height = #pitTable[1]

    indices = {}
    visitedTable = {}  -- First need to populate this with false, as we have not visited any cells.

    for i = 1, width do
        visitedTable[i] = {}

        for j = 1, height do
            visitedTable[i][j] = false
        end
    end
    
    for col = 1, width do
        for row = 1, height do
            if pitTable[col][row] and not visitedTable[col][row] then
                pitBatMod:extractPitEdgeCellsHelper(pitTable, visitedTable,
                        col, row, width, height, indices)
            end
        end
    end
    
    return indices
end

function pitBatMod:populatePits()
    local room = game:GetLevel():GetCurrentRoom()
    local spawnCount = 0

    if not room:IsClear() then
        pitEdgeCells = pitBatMod:extractPitEdgeCells(pitBatMod:generatePitTable())

        for i = 1, #pitEdgeCells do
            if spawnCount >= MAX_BAT_COUNT_PER_ROOM then
                break
            end
            
            if rng:RandomInt(30) == 1 then --  30 is some magic number.  Dunno.
                spawnCount = spawnCount + 1

                Isaac.Spawn(Entities.PIT_BAT.id, Entities.PIT_BAT.variant, 0,
                        room:GetGridPosition(pitEdgeCells[i]), Vector(0, 0), nil)
            end
        end
    end
end

pitBatMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, pitBatMod.populatePits)