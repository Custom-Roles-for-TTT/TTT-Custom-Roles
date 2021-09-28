AddCSLuaFile()

-------------
-- CONVARS --
-------------

CreateConVar("ttt_lootgoblin_activation_timer", "30")
CreateConVar("ttt_lootgoblin_announce", "1")
CreateConVar("ttt_lootgoblin_size", "0.5")
CreateConVar("ttt_lootgoblin_cackle_timer_min", "4")
CreateConVar("ttt_lootgoblin_cackle_timer_max", "12")
CreateConVar("ttt_lootgoblin_weapons_dropped", "8")
CreateConVar("ttt_lootgoblin_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that the lootgoblin is killed", 0, 4)
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

------------
-- TIMERS --
------------

local cackles = {
    Sound("lootgoblin/cackle1.wav"),
    Sound("lootgoblin/cackle2.wav"),
    Sound("lootgoblin/cackle3.wav")
}
hook.Add("TTTBeginRound", "LootGoblin_TTTBeginRound", function()
    local hasLootGoblin = false
    for _, v in ipairs(player.GetAll()) do
        if v:IsLootGoblin() then
            hasLootGoblin = true
        end
    end

    if hasLootGoblin then
        local goblinTime = GetConVar("ttt_lootgoblin_activation_timer"):GetInt()
        for _, v in ipairs(player.GetAll()) do
            if v:IsActiveLootGoblin() then
                v:PrintMessage(HUD_PRINTTALK, "You will transform into a goblin in " .. tostring(goblinTime) .. " seconds!")
            end
        end
        timer.Create("LootGoblinActivate", goblinTime, 1, function()
            local revealMode = GetConVar("ttt_lootgoblin_announce"):GetInt()
            for _, v in ipairs(player.GetAll()) do
                if v:IsActiveLootGoblin() then
                    v:SetNWBool("LootGoblinActive", true)
                    v:PrintMessage(HUD_PRINTTALK, "You have transformed into a goblin!")

                    local scale = GetConVar("ttt_lootgoblin_size"):GetFloat()
                    v:SetStepSize(v:GetStepSize() * scale)
                    v:SetModelScale(v:GetModelScale() * scale, 1)
                    v:SetViewOffset(v:GetViewOffset() * scale)
                    v:SetViewOffsetDucked(v:GetViewOffsetDucked() * scale)
                    local a, b = v:GetHull()
                    v:SetHull(a * scale, b * scale)
                    a, b = v:GetHullDuck()
                    v:SetHullDuck(a * scale, b * scale)
                    -- TODO: Speed/jump boost?
                elseif revealMode == ANNOUNCE_REVEAL_ALL or (v:IsActiveTraitorTeam() and revealMode == ANNOUNCE_REVEAL_TRAITORS) or (not v:IsActiveTraitorTeam() and revealMode == ANNOUNCE_REVEAL_INNOCENTS) then
                    v:PrintMessage(HUD_PRINTTALK, "A loot goblin has been spotted!")
                    v:PrintMessage(HUD_PRINTCENTER, "A loot goblin has been spotted!")
                end
            end
            local min = GetConVar("ttt_lootgoblin_cackle_timer_min"):GetInt()
            local max = GetConVar("ttt_lootgoblin_cackle_timer_max"):GetInt()
            timer.Create("LootGoblinCackle", math.random(min, max), 0, function()
                for _, v in ipairs(player.GetAll()) do
                    if v:IsActiveLootGoblin() then
                        local idx = math.random(1, #cackles)
                        local chosen_sound = cackles[idx]
                        sound.Play(chosen_sound, v:GetPos())
                    end
                end
                timer.Adjust("LootGoblinCackle", math.random(min, max), 0, nil)
            end)
        end)
    end
end)

hook.Add("TTTEndRound", "LootGoblin_TTTEndRound", function()
    timer.Remove("LootGoblinActivate")
    timer.Remove("LootGoblinCackle")
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
    if ply:IsActiveLootGoblin() and ply:GetNWBool("LootGoblinActive", false) then
        local idx = math.random(1, #footsteps)
        local chosen_sound = footsteps[idx]
        sound.Play(chosen_sound, pos, volume, 100, 1)
    end
end)

-----------
-- DEATH --
-----------

hook.Add("PlayerDeath", "LootGoblin_PlayerDeath", function(victim, infl, attacker)
    if victim:IsLootGoblin() and victim:GetNWBool("LootGoblinActive", false) then
        JesterTeamKilledNotification(ROLE_LOOTGOBLIN, attacker, victim,
        -- getkillstring
                function()
                    return "The " .. ROLE_STRINGS[ROLE_LOOTGOBLIN] .. " has been killed!"
                end)
        local lootTable = {}
        timer.Create("LootGoblinWeaponDrop", 0.05, GetConVar("ttt_lootgoblin_weapons_dropped"):GetInt(), function()
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
end)

-------------
-- CLEANUP --
-------------

hook.Add("TTTPrepareRound", "LootGoblin_PrepareRound", function()
    for _, v in pairs(player.GetAll()) do
        v:SetNWBool("LootGoblinActive", false)
    end
end)

-- TODO: Extra cleanup for role change, respawn...

-- TODO: Win logic