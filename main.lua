local kuriEnemies = RegisterMod("Kuri's Enemies", 1)
local sfx = SFXManager()
local music = MusicManager()
local game = Game()
local rng = RNG()

local function getEntity(name, subt)
    if subt == nil then
        subt = 0
    end
    
    return { id = Isaac.GetEntityTypeByName(name), variant = Isaac.GetEntityVariantByName(name), subtype = subt }
end

local Entities = {
    PIT_BAT = getEntity("Pit Bat")
}

function kuriEnemies:newGame(fromSave)
    if not fromSave then
        rng:SetSeed(game:GetSeeds():GetStartSeed(), 0)
    end
end

kuriEnemies:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, kuriEnemies.newGame)

--<<<PIT BAT>>>--
function kuriEnemies:pitBatControl(bat)
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

kuriEnemies:AddCallback(ModCallbacks.MC_NPC_UPDATE, kuriEnemies.pitBatControl, Entities.PIT_BAT.id)

function kuriEnemies:populatePits()
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

kuriEnemies:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, kuriEnemies.populatePits)