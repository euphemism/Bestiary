local RedPuppetCollectible = RegisterMod("Bestiary - RedPuppet", 1);
Isaac.DebugString("Bestiary - RedPuppet loading...");

RedPuppetCollectible.COLLECTIBLE_REDPUPPET = Isaac.GetItemIdByName("Red Puppet");
RedPuppetCollectible.ENTITY_REDPUPPET = Isaac.GetEntityTypeByName("Red Puppet");
RedPuppetCollectible.VARIANT_REDPUPPET = Isaac.GetEntityVariantByName("Red Puppet");

--RedPuppet item init
RedPuppetCollectible.playerCouldShot = false;
RedPuppetCollectible.tearDamageFactor = 0.9;
RedPuppetCollectible.tearInterval = 9;
RedPuppetCollectible.tearDelay = 9;
RedPuppetCollectible.tearSpeed = 7;
RedPuppetCollectible.tearFallingSpeed = 0.5;
RedPuppetCollectible.tearCount = 12;
RedPuppetCollectible.familiarVelocity = 4;
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
    familiar.Velocity = familiar.Velocity:Resized(RedPuppetCollectible.familiarVelocity);
  end
  --finish anim
  if sprite:IsFinished("Hit") then
    sprite:Play("Idle", true);      
  end

  local player = Game():GetPlayer(0);
  --check if player fired
  if player.FireDelay == player.MaxFireDelay then
    if RedPuppetCollectible.tearDelay < RedPuppetCollectible.tearInterval then
      RedPuppetCollectible.tearDelay = RedPuppetCollectible.tearDelay + 1;
      
    else      
      sprite:Play("Hit", true);
      playSound(familiar.Position, SoundEffect.SOUND_LITTLE_HORN_COUGH, 1.5, 0.6);
      RedPuppetCollectible.tearDelay = 0;

      for i = 1, RedPuppetCollectible.tearCount do
        RedPuppetCollectible:FireTear(familiar, Vector(math.cos(i / RedPuppetCollectible.tearCount * math.pi * 2), math.sin(i / RedPuppetCollectible.tearCount * math.pi * 2)));
      end     
    end
  end
  
end

function RedPuppetCollectible:FireTear(familiar, vector)
  local tear = nil;
  local player = Game():GetPlayer(0);
  local oldPlyerDamage = player.Damage;
  player.Damage = player.Damage * RedPuppetCollectible.tearDamageFactor;
  tear = player:FireTear(familiar.Position, vector * RedPuppetCollectible.tearSpeed, false, false, false);  
  player.Damage = oldPlyerDamage;
  --apply tear effects
  if tear ~= nil then
    tear.FallingSpeed = RedPuppetCollectible.tearFallingSpeed;
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