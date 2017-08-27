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
local HushatarCollectible = RegisterMod("Bestiary - Hushatar", 1);
Isaac.DebugString("Bestiary - Hushatar loading...");

HushatarCollectible.COLLECTIBLE_HUSHATAR = Isaac.GetItemIdByName("Hush Avatar");
HushatarCollectible.ENTITY_HUSHATAR = Isaac.GetEntityTypeByName("Hush Avatar");
HushatarCollectible.VARIANT_HUSHATAR = Isaac.GetEntityVariantByName("Hush Avatar");

--Hushatar item init
HushatarCollectible.TEAR_DMG = 4.5;
HushatarCollectible.TEAR_INTERVAL = 120;
HushatarCollectible.TEAR_SPEED = 12;
HushatarCollectible.TEAR_FALLING_SPD = -8;
HushatarCollectible.FAMILIAR_RANGE = 220;
HushatarCollectible.FAMILIAR_VELOCITY = 5.5;
HushatarCollectible.FAMILIAR_PRECISION = 5;
HushatarCollectible.tearDelay = 120;
HushatarCollectible.debugFrame = true;

-- NEW RUN CALLBACK
function HushatarCollectible:PostPlayerInit()  
  local player = Isaac.GetPlayer(0);
  local currentRoom = Game():GetRoom();
  HushatarCollectible.lastRoom = currentRoom:GetDecorationSeed();
end

-- POST UPDATE CALLBACK
function HushatarCollectible:onUpdate()  
  -- Begining of run
  if Game():GetFrameCount() == 1 then
      -- Debug spawn
	  Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, HushatarCollectible.COLLECTIBLE_HUSHATAR, Vector(200, 150), Vector(0,0), nil);      
  end   
end

-- FAMILIAR INIT CALLBACK
function HushatarCollectible:onFamiliarInit(familiar)
  --familiar.IsFollower = true;
  HushatarCollectible.debugFrame = true;
end

-- FAMILIAR UPDATE CALLBACK
function HushatarCollectible:onFamiliarUpdate(familiar)
  --familiar:FollowParent();  
  local sprite = familiar:GetSprite();

   --Bounce off walls
  familiar.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS;
  if HushatarCollectible.debugFrame then --makes sure familiar has initial velocity
    familiar.Velocity = Vector(5, -5);
    HushatarCollectible.debugFrame = false;
  else 
    familiar.Velocity = familiar.Velocity:Resized(HushatarCollectible.FAMILIAR_VELOCITY);
  end

  if HushatarCollectible.tearDelay < HushatarCollectible.TEAR_INTERVAL then
    HushatarCollectible.tearDelay = HushatarCollectible.tearDelay + 1;
    --finish anim
    if sprite:IsFinished("Hit") then
      sprite:Play("Idle", true);      
    end
  else
    --check if enemy is in range
    local hasTarget = false;
    for j, entity in pairs(Isaac.GetRoomEntities()) do
      if entity:IsVulnerableEnemy() and
        entity.Position:Distance(familiar.Position) < HushatarCollectible.FAMILIAR_RANGE and
        (math.floor(entity.Position.X / HushatarCollectible.FAMILIAR_PRECISION) == math.floor(familiar.Position.X / HushatarCollectible.FAMILIAR_PRECISION) or
        math.floor(entity.Position.Y / HushatarCollectible.FAMILIAR_PRECISION) == math.floor(familiar.Position.Y / HushatarCollectible.FAMILIAR_PRECISION)) then     

        hasTarget = true;
        break;
      end
    end
    if hasTarget then
      sprite:Play("Hit", true);
      playSound(familiar.Position, SoundEffect.SOUND_SATAN_BLAST, 2, 0.6);
      HushatarCollectible.tearDelay = 0;
      HushatarCollectible:FireTear(familiar, Vector(0, -1));
      HushatarCollectible:FireTear(familiar, Vector(0, 1));
      HushatarCollectible:FireTear(familiar, Vector(1, 0));
      HushatarCollectible:FireTear(familiar, Vector(-1, 0));
    end
  end
end

function HushatarCollectible:FireTear(familiar, vector)
  local tear = nil;
  local player = Game():GetPlayer(0);
  local oldPlyerDamage = player.Damage;
  player.Damage = HushatarCollectible.TEAR_DMG;
  tear = player:FireTear(familiar.Position, vector * HushatarCollectible.TEAR_SPEED, false, false, false);  
  tear:ChangeVariant(TearVariant.METALLIC);
  player.Damage = oldPlyerDamage;
  --apply tear effects
  if tear ~= nil then
    tear.TearFlags = 68719476737;--continuum + spectral
    --tear.Color = Color(0,0,0,0.9,128,32,128);
    tear.FallingSpeed = HushatarCollectible.TEAR_FALLING_SPD;
    tear.Scale = 1;
  end
end

-- ON CACHE
function HushatarCollectible:onCache(player, cacheFlag)  
  if cacheFlag == CacheFlag.CACHE_FAMILIARS then
    player:CheckFamiliar(HushatarCollectible.VARIANT_HUSHATAR, player:GetCollectibleNum(HushatarCollectible.COLLECTIBLE_HUSHATAR), RNG());
  end    
end

HushatarCollectible:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, HushatarCollectible.PostPlayerInit);
HushatarCollectible:AddCallback(ModCallbacks.MC_POST_UPDATE, HushatarCollectible.onUpdate);
HushatarCollectible:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, HushatarCollectible.onCache);

HushatarCollectible:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, HushatarCollectible.onFamiliarUpdate, HushatarCollectible.VARIANT_HUSHATAR);
HushatarCollectible:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, HushatarCollectible.onFamiliarInit, HushatarCollectible.VARIANT_HUSHATAR);
local LittlePeepCollectible = RegisterMod("Bestiary - Little peep", 1);
Isaac.DebugString("Bestiary - Little peep loading...");

LittlePeepCollectible.COLLECTIBLE_HUSHATAR = Isaac.GetItemIdByName("Little Peep");
LittlePeepCollectible.ENTITY_HUSHATAR = Isaac.GetEntityTypeByName("Little Peep");
LittlePeepCollectible.VARIANT_HUSHATAR = Isaac.GetEntityVariantByName("Little Peep");

--Little peep item init
LittlePeepCollectible.PUDDLE_DMG = 5;
LittlePeepCollectible.PUDDLE_SIZE = 1;
LittlePeepCollectible.PUDDLE_TIMEOUT = 200;
LittlePeepCollectible.TEAR_INTERVAL = 120;
LittlePeepCollectible.FAMILIAR_RANGE = 35;
LittlePeepCollectible.FAMILIAR_VELOCITY = 4.5;
LittlePeepCollectible.tearDelay = 120;
LittlePeepCollectible.debugFrame = true;

-- NEW RUN CALLBACK
function LittlePeepCollectible:PostPlayerInit()  
  local player = Isaac.GetPlayer(0);
  local currentRoom = Game():GetRoom();
  LittlePeepCollectible.lastRoom = currentRoom:GetDecorationSeed();
end

-- POST UPDATE CALLBACK
function LittlePeepCollectible:onUpdate()  
  -- Begining of run
  if Game():GetFrameCount() == 1 then
      -- Debug spawn
	  Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, LittlePeepCollectible.COLLECTIBLE_HUSHATAR, Vector(150, 150), Vector(0,0), nil);      
  end   
end

-- FAMILIAR INIT CALLBACK
function LittlePeepCollectible:onFamiliarInit(familiar)
  --familiar.IsFollower = true;
  LittlePeepCollectible.debugFrame = true;
end

-- FAMILIAR UPDATE CALLBACK
function LittlePeepCollectible:onFamiliarUpdate(familiar)
  --familiar:FollowParent();  
  local sprite = familiar:GetSprite();

   --Bounce off walls
  familiar.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS;
  if LittlePeepCollectible.debugFrame then --makes sure familiar has initial velocity
    familiar.Velocity = Vector(5, -5);
    LittlePeepCollectible.debugFrame = false;
  else 
    familiar.Velocity = familiar.Velocity:Resized(LittlePeepCollectible.FAMILIAR_VELOCITY);
  end

  if LittlePeepCollectible.tearDelay < LittlePeepCollectible.TEAR_INTERVAL then
    LittlePeepCollectible.tearDelay = LittlePeepCollectible.tearDelay + 1;
    --finish anim
    if sprite:IsFinished("Hit") then
      sprite:Play("Idle", true);      
    end
  else
    --check if enemy is in range
    local hasTarget = false;
    for j, entity in pairs(Isaac.GetRoomEntities()) do
      if entity:IsVulnerableEnemy() and entity.Position:Distance(familiar.Position) < LittlePeepCollectible.FAMILIAR_RANGE and not entity:IsFlying() then 
        hasTarget = true;
        break;
      end
    end
    if hasTarget then
      sprite:Play("Hit", true);
      playSound(familiar.Position, SoundEffect.SOUND_BOSS_GURGLE_ROAR, 2, 1.2);
      LittlePeepCollectible.tearDelay = 0;
      local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_LEMON_MISHAP, 0, familiar.Position, Vector(0, 0), familiar):ToEffect();
      creep.Scale = LittlePeepCollectible.PUDDLE_SIZE;
      creep.CollisionDamage = LittlePeepCollectible.PUDDLE_DMG;
      creep:Update();
    end
  end
end

-- ON CACHE
function LittlePeepCollectible:onCache(player, cacheFlag)  
  if cacheFlag == CacheFlag.CACHE_FAMILIARS then
    player:CheckFamiliar(LittlePeepCollectible.VARIANT_HUSHATAR, player:GetCollectibleNum(LittlePeepCollectible.COLLECTIBLE_HUSHATAR), RNG());
  end    
end

LittlePeepCollectible:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, LittlePeepCollectible.PostPlayerInit);
LittlePeepCollectible:AddCallback(ModCallbacks.MC_POST_UPDATE, LittlePeepCollectible.onUpdate);
LittlePeepCollectible:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, LittlePeepCollectible.onCache);

LittlePeepCollectible:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, LittlePeepCollectible.onFamiliarUpdate, LittlePeepCollectible.VARIANT_HUSHATAR);
LittlePeepCollectible:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, LittlePeepCollectible.onFamiliarInit, LittlePeepCollectible.VARIANT_HUSHATAR);
local RedPuppetCollectible = RegisterMod("Bestiary - RedPuppet", 1);
Isaac.DebugString("Bestiary - RedPuppet loading...");

RedPuppetCollectible.COLLECTIBLE_REDPUPPET = Isaac.GetItemIdByName("Red Puppet");
RedPuppetCollectible.ENTITY_REDPUPPET = Isaac.GetEntityTypeByName("Red Puppet");
RedPuppetCollectible.VARIANT_REDPUPPET = Isaac.GetEntityVariantByName("Red Puppet");

--RedPuppet item init
RedPuppetCollectible.TEAR_DMG_FACTOR = 0.9;
RedPuppetCollectible.TEAR_INTERVAL = 9;
RedPuppetCollectible.TEAR_FALLING_SPD = 0.5;
RedPuppetCollectible.TEAR_COUNT = 12;
RedPuppetCollectible.FAMILIAR_VELOCITY = 4;
RedPuppetCollectible.TEAR_SPEED = 7;
RedPuppetCollectible.tearDelay = 9;
RedPuppetCollectible.playerCharge = 0;
RedPuppetCollectible.playerWasCharging = false;
RedPuppetCollectible.debugFrame = true;

-- NEW RUN CALLBACK
function RedPuppetCollectible:PostPlayerInit()  
  local player = Isaac.GetPlayer(0);
  local currentRoom = Game():GetRoom();
  RedPuppetCollectible.lastRoom = currentRoom:GetDecorationSeed();
end

-- POST UPDATE CALLBACK
function RedPuppetCollectible:onUpdate()  
  -- Begining of run
  if Game():GetFrameCount() == 1 then
      -- Debug spawn
	  Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, RedPuppetCollectible.COLLECTIBLE_REDPUPPET, Vector(250, 150), Vector(0,0), nil);      
  end 
end

-- FAMILIAR INIT CALLBACK
function RedPuppetCollectible:onFamiliarInit(familiar)
  --familiar.IsFollower = true;
  RedPuppetCollectible.debugFrame = true;
end

-- FAMILIAR UPDATE CALLBACK
function RedPuppetCollectible:onFamiliarUpdate(familiar)
  --familiar:FollowParent();  
  local sprite = familiar:GetSprite();

   --Bounce off walls
  familiar.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS;
  if RedPuppetCollectible.debugFrame then --makes sure familiar has initial velocity
    familiar.Velocity = Vector(-5, -5);
    RedPuppetCollectible.debugFrame = false;
  else 
    familiar.Velocity = familiar.Velocity:Resized(RedPuppetCollectible.FAMILIAR_VELOCITY);
  end
  --finish anim
  if sprite:IsFinished("Hit") then
    sprite:Play("Idle", true);      
  end

  local player = Game():GetPlayer(0);
  local chargeItemFired = false;  

  if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) or 
    player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) or
    player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) or
    player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) or
    player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then
    if player:GetShootingInput().X ~= 0 or player:GetShootingInput().Y ~= 0 then
      RedPuppetCollectible.playerCharge = RedPuppetCollectible.playerCharge + 1;
      if RedPuppetCollectible.playerCharge > player.MaxFireDelay * 1.5 then -- prevent spam charging
        RedPuppetCollectible.playerWasCharging = true;   
      end   
    else
      if RedPuppetCollectible.playerWasCharging then
        chargeItemFired = true;
      end
      RedPuppetCollectible.playerWasCharging = false;
      RedPuppetCollectible.playerCharge = 0;
    end
  end 

  --check if player fired
  if player.FireDelay == player.MaxFireDelay or chargeItemFired then
    if RedPuppetCollectible.tearDelay < RedPuppetCollectible.TEAR_INTERVAL then
      RedPuppetCollectible.tearDelay = RedPuppetCollectible.tearDelay + 1;
    else      
      RedPuppetCollectible:TriggerEffect(player, familiar, sprite);
    end
  end  
end

function RedPuppetCollectible:TriggerEffect(player, familiar, sprite) 
  sprite:Play("Hit", true);
  playSound(familiar.Position, SoundEffect.SOUND_LITTLE_HORN_COUGH, 1.5, 0.6);
  RedPuppetCollectible.tearDelay = 0;

  for i = 1, RedPuppetCollectible.TEAR_COUNT do
    local shootVector = Vector(math.cos(i / RedPuppetCollectible.TEAR_COUNT * math.pi * 2), math.sin(i / RedPuppetCollectible.TEAR_COUNT * math.pi * 2));
    if player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) then
      local angle = shootVector:GetAngleDegrees();
      local laser = EntityLaser.ShootAngle(2, familiar.Position, angle, 8, Vector(0,0), familiar);
      laser:SetOneHit(true);
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then      
      local angle = shootVector:GetAngleDegrees();
      local laser = EntityLaser.ShootAngle(1, familiar.Position, angle, 8, Vector(0,0), familiar);
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then
      player:FireBomb(familiar.Position, shootVector * RedPuppetCollectible.TEAR_SPEED);
      local laser = EntityLaser.ShootAngle(1, familiar.Position, angle, 8, Vector(0,0), familiar);
    elseif player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then
      player:FireTechXLaser(familiar.Position, shootVector * RedPuppetCollectible.TEAR_SPEED, 10);
    else
      RedPuppetCollectible:FireTear(familiar, shootVector);
    end        
  end  
end

function RedPuppetCollectible:FireTear(familiar, vector)
  local tear = nil;
  local player = Game():GetPlayer(0);
  local oldPlyerDamage = player.Damage;
  player.Damage = player.Damage * RedPuppetCollectible.TEAR_DMG_FACTOR;
  tear = player:FireTear(familiar.Position, vector * RedPuppetCollectible.TEAR_SPEED, false, false, false);  
  player.Damage = oldPlyerDamage;
  --apply tear effects
  if tear ~= nil then
    tear.FallingSpeed = RedPuppetCollectible.TEAR_FALLING_SPD;
    --tear.Scale = 1;
  end
end

-- ON CACHE
function RedPuppetCollectible:onCache(player, cacheFlag)  
  if cacheFlag == CacheFlag.CACHE_FAMILIARS then
    player:CheckFamiliar(RedPuppetCollectible.VARIANT_REDPUPPET, player:GetCollectibleNum(RedPuppetCollectible.COLLECTIBLE_REDPUPPET), RNG());
  end    
end

RedPuppetCollectible:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, RedPuppetCollectible.PostPlayerInit);
RedPuppetCollectible:AddCallback(ModCallbacks.MC_POST_UPDATE, RedPuppetCollectible.onUpdate);
RedPuppetCollectible:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, RedPuppetCollectible.onCache);

RedPuppetCollectible:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, RedPuppetCollectible.onFamiliarUpdate, RedPuppetCollectible.VARIANT_REDPUPPET);
RedPuppetCollectible:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, RedPuppetCollectible.onFamiliarInit, RedPuppetCollectible.VARIANT_REDPUPPET);
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