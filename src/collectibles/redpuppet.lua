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