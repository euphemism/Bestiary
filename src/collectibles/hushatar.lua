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