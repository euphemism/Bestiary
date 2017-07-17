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
HushatarCollectible.tearDamage = 4.5;
HushatarCollectible.tearInterval = 120;
HushatarCollectible.tearDelay = 120;
HushatarCollectible.tearSpeed = 12;
HushatarCollectible.tearFallingSpeed = -8;
HushatarCollectible.attackRange = 220;
HushatarCollectible.familiarVelocity = 5.5;
HushatarCollectible.attackPrecision = 5;
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
  
  for playerNum = 1, Game():GetNumPlayers() do
    local player = Game():GetPlayer(playerNum);    
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
    familiar.Velocity = familiar.Velocity:Resized(HushatarCollectible.familiarVelocity);
  end

  if HushatarCollectible.tearDelay < HushatarCollectible.tearInterval then
    HushatarCollectible.tearDelay = HushatarCollectible.tearDelay + 1;
    --finish anim
    if sprite:IsFinished("Hit") then
      sprite:Play("Idle", true);      
    end
  else
    --check if enemy is in range
    local hasTarget = false;
    for j, entity in pairs(Isaac.GetRoomEntities()) do
      --enemy in range
      if entity:IsVulnerableEnemy() and
        entity.Position:Distance(familiar.Position) < HushatarCollectible.attackRange and
        (math.floor(entity.Position.X / HushatarCollectible.attackPrecision) == math.floor(familiar.Position.X / HushatarCollectible.attackPrecision) or
        math.floor(entity.Position.Y / HushatarCollectible.attackPrecision) == math.floor(familiar.Position.Y / HushatarCollectible.attackPrecision)) then     

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
  player.Damage = HushatarCollectible.tearDamage;
  tear = player:FireTear(familiar.Position, vector * HushatarCollectible.tearSpeed, false, false, false);  
  tear:ChangeVariant(TearVariant.METALLIC);
  player.Damage = oldPlyerDamage;
  --apply tear effects
  if tear ~= nil then
    tear.TearFlags = 68719476737;--continuum + spectral
    --tear.Color = Color(0,0,0,0.9,128,32,128);
    tear.FallingSpeed = HushatarCollectible.tearFallingSpeed;
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