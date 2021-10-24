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
local lootgoblin_cackle_enabled = CreateConVar("ttt_lootgoblin_cackle_enabled", "1")
local lootgoblin_weapons_dropped = CreateConVar("ttt_lootgoblin_weapons_dropped", "8")
local lootgoblin_jingle_enabled = CreateConVar("ttt_lootgoblin_jingle_enabled", "1")
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
local defaultJumpPower = 160
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

                local scale = lootgoblin_size:GetFloat()
                v:SetPlayerScale(scale)
                local jumpPower = defaultJumpPower
                -- Compensate the jump power of smaller players so they have roughly the same jump height as normal
                -- In testing, scales >= 1 all seem to work fine with the default jump power and that's not the intent of this role anyway
                if scale < 1 then
                    -- Derived formula is y = -120x + 280
                    -- We take the base jump power out of this as a known constant and then
                    -- give a small jump boost of 5 extra power to "round up" the jump estimates
                    -- so that smaller sizes can still clear jump+crouch blocks
                    jumpPower = jumpPower + (-(120 * scale) + 125)
                end
                v:SetJumpPower(jumpPower)
                -- TODO: Speed boost?
            elseif revealMode == JESTER_NOTIFY_EVERYONE or
                    (v:IsActiveTraitorTeam() and (revealMode == JESTER_NOTIFY_TRAITOR or JESTER_NOTIFY_DETECTIVE_AND_TRAITOR)) or
                    (not v:IsActiveDetectiveLike() and (revealMode == JESTER_NOTIFY_DETECTIVE or JESTER_NOTIFY_DETECTIVE_AND_TRAITOR)) then
                v:PrintMessage(HUD_PRINTTALK, "A loot goblin has been spotted!")
                v:PrintMessage(HUD_PRINTCENTER, "A loot goblin has been spotted!")
            end
        end

        if lootgoblin_cackle_enabled:GetBool() then
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
        end
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
    if player.IsRoleLiving(ROLE_LOOTGOBLIN) then
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
hook.Add("PlayerFootstep", "LootGoblin_PlayerFootstep", function(ply, pos, foot, snd, volume, rf)
    if ply:IsActiveLootGoblin() and ply:IsRoleActive() and not ply:GetNWBool("LootGoblinKilled", false) and lootgoblin_jingle_enabled:GetBool() then
        local idx = math.random(1, #footsteps)
        local chosen_sound = footsteps[idx]
        sound.Play(chosen_sound, pos, volume, 100, 1)
    end
end)

-----------
-- DEATH --
-----------

local function PauseIfSingleGoblin()
    if not timer.Exists("LootGoblinActivate") then return end
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if not player.IsRoleLiving(ROLE_LOOTGOBLIN) then
        timer.Pause("LootGoblinActivate")
    end
end

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

        PauseIfSingleGoblin()
    end
end)

-------------
-- CLEANUP --
-------------

local function ResetPlayer(ply)
    ply:SetNWBool("LootGoblinActive", false)
    ply:ResetPlayerScale()
    ply:SetJumpPower(defaultJumpPower)
    PauseIfSingleGoblin()
end

hook.Add("TTTPrepareRound", "LootGoblin_PrepareRound", function()
    for _, v in pairs(player.GetAll()) do
        v:SetNWBool("LootGoblinKilled", false)
        ResetPlayer(v)
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
        elseif timer.Exists("LootGoblinActivate") then
            timer.UnPause("LootGoblinActivate")
            local remaining = timer.TimeLeft("LootGoblinActivate")
            SetGlobalFloat("ttt_lootgoblin_activate", CurTime() + remaining)
        end
    end
end)

hook.Add("TTTPlayerRoleChanged", "LootGoblin_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_LOOTGOBLIN then
        ResetPlayer(ply)
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