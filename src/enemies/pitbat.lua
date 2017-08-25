local pitBatMod = RegisterMod("Bestiary - Pit Bat", 1)

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

function pitBatMod:cellToIndex(gridWidth, cellX, cellY)
	return cellY * gridWidth + cellX
end

function pitBatMod:getGridEntityAtCell(room, cellX, cellY)
	return room:getGridEntity(pitBatMod.cellToIndex(room:GetGridWidth(), cellX, cellY))
end

function pitBatMod:generatePitTable()
		local room = game:GetLevel():GetCurrentRoom()
		local gridSize = room:GetGridSize()
		local roomWidth = room:GetGridWidth()
		local roomHeight = room:GetGridHeight()

		local pitTable = {}
		
		for col = 1, roomWidth do
			pitTable[col] = {}
			
			for row = 1, roomHeight do
				entity = getGridEntityAtCell(room, col - 1, row - 1)

				pitTable[col][row] = not not entity:ToPit()  -- boolean logic with nil is funny, I think this is an okay way of doing this.
            end
		end
		
		return pitTable
end

function pitBatMod:extractPitEdgeCellsHelper(pitTable, visitedTable, cellX, cellY, width, height)
	indices = {}
	visitedTable[cellX][cellY] = true
	
	leftIndices = pitBatMod.extractPitEdgeCellsHelper(pitTable, visitedTable
end

-- Returns an "array" of grid indices containing pit edge cells.
function pitBatMod:extractPitEdgeCells(pitTable)
	width = #pitTable
	height = #pitTable[1]

	visitedTable = {}  -- First need to populate this with false, as we have not visited any cells.
	indices = {}
	
	for i = 1, width do
		visitedTable[i] = {}
		
		for j = 1, height do
			visitedTable[i][j] = false
		end
	end
	
	for col = 1, width do
		for row = 1, height do
			if not visited[col][row] then
				newIndices = pitBatMod.extractPitEdgeCellsHelper(pitTable, visitedTable,
						col, row, width, height)
						
				indices = array_concat(indices, newIndices)
			end
			
	return indices
end

--extractPitEdgeCells({}, 5, 4, cellX, cellY, {})

function pitBatMod:populatePits()
    local room = game:GetLevel():GetCurrentRoom()
    local spawnCount = 0
    
    if not room:IsClear() then
        for i = 0, room:GetGridSize() do
            if spawnCount >= 2 then
                break
            end
            
            if room:GetGridEntity(i) and rng:RandomInt(30) == 1 then
                if room:GetGridEntity(i):ToPit() then
                    spawnCount = spawnCount + 1
                    Isaac.Spawn(Entities.PIT_BAT.id, Entities.PIT_BAT.variant, 0, room:GetGridPosition(i), Vector(0, 0), nil)
                end
            end
        end
    end
end

pitBatMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, pitBatMod.populatePits)