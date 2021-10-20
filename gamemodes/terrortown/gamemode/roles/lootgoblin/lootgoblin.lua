AddCSLuaFile()

util.AddNetworkString("TTT_UpdateLootGoblinWins")

resource.AddSingleFile("lootgoblin/cackle1.wav")
resource.AddSingleFile("lootgoblin/cackle2.wav")
resource.AddSingleFile("lootgoblin/cackle3.wav")
resource.AddSingleFile("lootgoblin/jingle1.wav")
resource.AddSingleFile("lootgoblin/jingle2.wav")
resource.AddSingleFile("lootgoblin/jingle3.wav")
resource.AddSingleFile("lootgoblin/jingle4.wav")
resource.AddSingleFile("lootgoblin/jingle5.wav")
resource.AddSingleFile("lootgoblin/jingle6.wav")
resource.AddSingleFile("lootgoblin/jingle7.wav")
resource.AddSingleFile("lootgoblin/jingle8.wav")

-------------
-- CONVARS --
-------------

local lootgoblin_activation_timer = CreateConVar("ttt_lootgoblin_activation_timer", "30")
local lootgoblin_announce = CreateConVar("ttt_lootgoblin_announce", "4")
local lootgoblin_size = CreateConVar("ttt_lootgoblin_size", "0.5")
local lootgoblin_cackle_timer_min = CreateConVar("ttt_lootgoblin_cackle_timer_min", "4")
local lootgoblin_cackle_timer_max = CreateConVar("ttt_lootgoblin_cackle_timer_max", "12")
local lootgoblin_weapons_dropped = CreateConVar("ttt_lootgoblin_weapons_dropped", "8")
CreateConVar("ttt_lootgoblin_notify_mode", "4", FCVAR_NONE, "The logic to use when notifying players that the lootgoblin is killed", 0, 4)
CreateConVar("ttt_lootgoblin_notify_sound", "1")
CreateConVar("ttt_lootgoblin_notify_confetti", "1")

-----------
-- KARMA --
-----------

-- The loot goblin has no karma, positive or negative
hook.Add("TTTKarmaGivePenalty", "LootGoblin_TTTKarmaGivePenalty", function(ply, penalty, victim)
    if IsPlayer(victim) and (ply:IsLootGoblin() or victim:IsLootGoblin())  then
        return true
    end
end)
hook.Add("TTTKarmaGiveReward", "LootGoblin_TTTKarmaGiveReward", function(ply, reward, victim)
    if IsPlayer(victim) and (ply:IsLootGoblin() or victim:IsLootGoblin()) then
        return true
    end
end)

----------------------
-- HELPER FUNCTIONS --
----------------------

local cackles = {
    Sound("lootgoblin/cackle1.wav"),
    Sound("lootgoblin/cackle2.wav"),
    Sound("lootgoblin/cackle3.wav")
}
local lootGoblinActive = false
local function StartGoblinTimers()
    local goblinTime = lootgoblin_activation_timer:GetInt()
    SetGlobalFloat("ttt_lootgoblin_activate", CurTime() + goblinTime)
    for _, v in ipairs(player.GetAll()) do
        if v:IsActiveLootGoblin() then
            v:PrintMessage(HUD_PRINTTALK, "You will transform into a goblin in " .. tostring(goblinTime) .. " seconds!")
        end
    end
    timer.Create("LootGoblinActivate", goblinTime, 1, function()
        lootGoblinActive = true
        local revealMode = lootgoblin_announce:GetInt()
        for _, v in ipairs(player.GetAll()) do
            if v:IsActiveLootGoblin() then
                v:SetNWBool("LootGoblinActive", true)
                v:PrintMessage(HUD_PRINTTALK, "You have transformed into a goblin!")
                v:SetPlayerScale(lootgoblin_size:GetFloat())
                -- TODO: Speed/jump boost?
            elseif revealMode == JESTER_NOTIFY_EVERYONE or
                    (v:IsActiveTraitorTeam() and (revealMode == JESTER_NOTIFY_TRAITOR or JESTER_NOTIFY_DETECTIVE_AND_TRAITOR)) or
                    (not v:IsActiveDetectiveLike() and (revealMode == JESTER_NOTIFY_DETECTIVE or JESTER_NOTIFY_DETECTIVE_AND_TRAITOR)) then
                v:PrintMessage(HUD_PRINTTALK, "A loot goblin has been spotted!")
                v:PrintMessage(HUD_PRINTCENTER, "A loot goblin has been spotted!")
            end
        end

        local min = lootgoblin_cackle_timer_min:GetInt()
        local max = lootgoblin_cackle_timer_max:GetInt()
        timer.Create("LootGoblinCackle", math.random(min, max), 0, function()
            for _, v in ipairs(player.GetAll()) do
                if v:IsActiveLootGoblin() and not v:GetNWBool("LootGoblinKilled", false) then
                    local idx = math.random(1, #cackles)
                    local chosen_sound = cackles[idx]
                    sound.Play(chosen_sound, v:GetPos())
                end
            end
            timer.Adjust("LootGoblinCackle", math.random(min, max), 0, nil)
        end)
    end)
end

----------------
-- WIN CHECKS --
----------------

local function HandleLootGoblinWinChecks(win_type)
    if win_type == WIN_NONE then return end

    local hasLootGoblin = false
    for _, v in ipairs(player.GetAll()) do
        if v:IsActiveLootGoblin() and not v:GetNWBool("LootGoblinKilled", false) then
            hasLootGoblin = true
        end
    end
    if not hasLootGoblin then return end

    net.Start("TTT_UpdateLootGoblinWins")
    net.WriteBool(true)
    net.Broadcast()
end
hook.Add("TTTWinCheckComplete", "LootGoblin_TTTWinCheckComplete", HandleLootGoblinWinChecks)

------------
-- TIMERS --
------------

hook.Add("TTTBeginRound", "LootGoblin_TTTBeginRound", function()
    local hasLootGoblin = false
    for _, v in ipairs(player.GetAll()) do
        if v:IsLootGoblin() then
            hasLootGoblin = true
        end
    end

    if hasLootGoblin then
        StartGoblinTimers()
    end
end)

---------------
-- FOOTSTEPS --
---------------

-- Play a jingling sound whenever an activated loot goblin takes a step
local footsteps = {
    Sound("lootgoblin/jingle1.wav"),
    Sound("lootgoblin/jingle2.wav"),
    Sound("lootgoblin/jingle3.wav"),
    Sound("lootgoblin/jingle4.wav"),
    Sound("lootgoblin/jingle5.wav"),
    Sound("lootgoblin/jingle6.wav"),
    Sound("lootgoblin/jingle7.wav"),
    Sound("lootgoblin/jingle8.wav")
}
hook.Add( "PlayerFootstep", "LootGoblin_PlayerFootstep", function( ply, pos, foot, snd, volume, rf )
    if ply:IsActiveLootGoblin() and ply:IsRoleActive() and not ply:GetNWBool("LootGoblinKilled", false) then
        local idx = math.random(1, #footsteps)
        local chosen_sound = footsteps[idx]
        sound.Play(chosen_sound, pos, volume, 100, 1)
    end
end)

-----------
-- DEATH --
-----------

hook.Add("PlayerDeath", "LootGoblin_PlayerDeath", function(victim, infl, attacker)
    if victim:IsLootGoblin() then
        if victim:IsRoleActive() and not victim:GetNWBool("LootGoblinKilled", false) then
            JesterTeamKilledNotification(attacker, victim,
            -- getkillstring
                    function()
                        return "The " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. " has been killed!"
                    end)
            local lootTable = {}
            timer.Create("LootGoblinWeaponDrop", 0.05, lootgoblin_weapons_dropped:GetInt(), function()
                if #lootTable == 0 then -- Rebuild the loot table if we run out
                    for _, v in ipairs(weapons.GetList()) do
                        if v and not v.AutoSpawnable and v.CanBuy and v.AllowDrop then
                            table.insert(lootTable, WEPS.GetClass(v))
                        end
                    end
                end

                local ragdoll = victim.server_ragdoll or victim:GetRagdollEntity()
                local pos = ragdoll:GetPos() + Vector(0, 0, 25)

                local idx = math.random(1, #lootTable)
                local wep = lootTable[idx]
                table.remove(lootTable, idx)
                local ent = ents.Create(wep)
                ent:SetPos(pos)
                ent:Spawn()

                local phys = ent:GetPhysicsObject()
                if phys:IsValid() then phys:ApplyForceCenter(Vector(math.Rand(-100, 100), math.Rand(-100, 100), 300) * phys:GetMass()) end
            end)
        end

        local lootGoblinCount = 0
        for _, v in pairs(player.GetAll()) do
            if v:IsActiveLootGoblin() then
                lootGoblinCount = lootGoblinCount + 1
            end
        end
        if lootGoblinCount <= 1 then
            timer.Pause("LootGoblinActivate")
        end
    end
end)

-------------
-- CLEANUP --
-------------

hook.Add("TTTPrepareRound", "LootGoblin_PrepareRound", function()
    for _, v in pairs(player.GetAll()) do
        v:SetNWBool("LootGoblinActive", false)
        v:SetNWBool("LootGoblinKilled", false)
        v:ResetPlayerScale()
    end
end)

hook.Add("TTTPlayerSpawnForRound", "LootGoblin_TTTPlayerSpawnForRound", function(ply, deadOnly)
    if ply:IsLootGoblin() then
        if lootGoblinActive then
            if ply:IsRoleActive() then
                ply:SetNWBool("LootGoblinKilled", true)
            else
                ply:SetNWBool("LootGoblinActive", true)
                ply:PrintMessage(HUD_PRINTTALK, "You have transformed into a goblin!")
                ply:SetPlayerScale(lootgoblin_size:GetFloat())
            end
        else
            timer.UnPause("LootGoblinActivate")
            local remaining = timer.TimeLeft("LootGoblinActivate")
            SetGlobalFloat("ttt_lootgoblin_activate", CurTime() + remaining)
        end
    end
end)

hook.Add("TTTPlayerRoleChanged", "LootGoblin_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_LOOTGOBLIN then
        ply:SetNWBool("LootGoblinActive", false)
        ply:ResetPlayerScale()
    elseif newRole == ROLE_LOOTGOBLIN then
        if lootGoblinActive then
            ply:SetNWBool("LootGoblinActive", true)
            ply:PrintMessage(HUD_PRINTTALK, "You have transformed into a goblin!")
            ply:SetPlayerScale(lootgoblin_size:GetFloat())
        elseif not timer.Exists("LootGoblinActivate") then
            StartGoblinTimers()
        else
            timer.UnPause("LootGoblinActivate")
            local remaining = timer.TimeLeft("LootGoblinActivate")
            SetGlobalFloat("ttt_lootgoblin_activate", CurTime() + remaining)
        end
    end
end)

hook.Add("TTTEndRound", "LootGoblin_TTTEndRound", function()
    timer.Remove("LootGoblinActivate")
    timer.Remove("LootGoblinCackle")
    lootGoblinActive = false
end)