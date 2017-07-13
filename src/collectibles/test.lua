
local TestCollectible = RegisterMod("Bestiary - Test Collectible", 1);
Isaac.DebugString("Should be called anyway");
--Isaac.DebugString("Test mod loading..." .. amIDefined);

-- NEW RUN CALLBACK
function TestCollectible:newRun()
  local player = Isaac.GetPlayer(0);
  local currentRoom = Game():GetRoom();
  TestCollectible.lastRoom = currentRoom:GetDecorationSeed();
end

-- POST UPDATE CALLBACK
function TestCollectible:onUpdate()
  local currentRoom = Game():GetRoom();
  
  -- Begining of run
  if Game():GetFrameCount() == 1 then
      -- Debug spawn
	  Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_BLOOD_MARTYR, Vector(280, 250), Vector(0,0), nil);
      
  end
end

TestCollectible:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, TestCollectible.newRun);
TestCollectible:AddCallback(ModCallbacks.MC_POST_UPDATE, TestCollectible.onUpdate);