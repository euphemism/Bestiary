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