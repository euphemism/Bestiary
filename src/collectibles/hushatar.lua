local HushatarCollectible = RegisterMod("Bestiary - Hushatar", 1);
Isaac.DebugString("Bestiary - Hushatar loading...");

HushatarCollectible.COLLECTIBLE_HUSHATAR = Isaac.GetItemIdByName("Hush Avatar");
HushatarCollectible.ENTITY_HUSHATAR = Isaac.GetEntityTypeByName("Hush Avatar");
HushatarCollectible.VARIANT_HUSHATAR = Isaac.GetEntityVariantByName("Hush Avatar");

--Hushatar item init
HushatarCollectible.shootDamage = 3.65;
HushatarCollectible.shootInterval = 110;
HushatarCollectible.shootDelay = 110;

function HushatarCollectible:playSound(position, sound, pitch, volume)
  --play sound hack
  local sound_entity = Isaac.Spawn(EntityType.ENTITY_FLY, 0, 0, position, Vector(0,0), nil):ToNPC();
  sound_entity:PlaySound(sound , volume, 0, false, pitch);
  sound_entity:Remove();
end

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
  familiar.IsFollower = true;    
end

-- FAMILIAR UPDATE CALLBACK
function HushatarCollectible:onFamiliarUpdate(familiar)
  familiar:FollowParent();  
  local sprite = familiar:GetSprite();
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