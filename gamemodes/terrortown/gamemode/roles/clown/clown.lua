AddCSLuaFile()

local hook = hook
local net = net
local player = player
local resource = resource
local table = table
local util = util

util.AddNetworkString("TTT_ClownTeamChange")
util.AddNetworkString("TTT_ClownActivate")

resource.AddSingleFile("sound/clown.wav")

-------------
-- CONVARS --
-------------

local clown_activation_credits = CreateConVar("ttt_clown_activation_credits", "0", FCVAR_NONE, "The number of credits to give the clown when they are activated", 0, 10)

local clown_use_traps_when_active = GetConVar("ttt_clown_use_traps_when_active")
local clown_heal_on_activate = GetConVar("ttt_clown_heal_on_activate")
local clown_heal_bonus = GetConVar("ttt_clown_heal_bonus")
local clown_damage_bonus = GetConVar("ttt_clown_damage_bonus")

----------------
-- WIN CHECKS --
----------------

local function HandleClownWinBlock(win_type)
    if win_type == WIN_NONE then return win_type end

    local clown = player.GetLivingRole(ROLE_CLOWN)
    if not IsPlayer(clown) then return win_type end

    local killer_clown_active = clown:IsRoleActive()
    if not killer_clown_active then
        SetClownTeam(true)
        clown:QueueMessage(MSG_PRINTBOTH, "KILL THEM ALL!")
        clown:AddCredits(clown_activation_credits:GetInt())
        if clown_heal_on_activate:GetBool() then
            local heal_bonus = clown_heal_bonus:GetInt()
            local health = clown:GetMaxHealth() + heal_bonus

            clown:SetHealth(health)
            if heal_bonus > 0 then
                clown:PrintMessage(HUD_PRINTTALK, "You have been fully healed (with a bonus)!")
            else
                clown:PrintMessage(HUD_PRINTTALK, "You have been fully healed!")
            end
        end
        net.Start("TTT_ClownActivate")
        net.WriteEntity(clown)
        net.Broadcast()

        -- Give the clown their shop items if purchase was delayed
        if clown.bought and GetConVar("ttt_clown_shop_delay"):GetBool() then
            clown:GiveDelayedShopItems()
        end

        -- Enable traitor buttons for them, if that's enabled
        TRAITOR_BUTTON_ROLES[ROLE_CLOWN] = clown_use_traps_when_active:GetBool()

        return WIN_NONE
    end

    local traitor_alive, innocent_alive, indep_alive, monster_alive, _ = player.AreTeamsLiving(true)
    -- If there are independents alive, check if any of them are non-clowns
    if indep_alive then
        player.ExecuteAgainstTeamPlayers(ROLE_TEAM_INDEPENDENT, true, true, function(ply)
            if not ply:IsClown() then
                indep_alive = false
                return true
            end
        end)
    end

    -- Clown wins if they are the only role left
    if not traitor_alive and not innocent_alive and not monster_alive then
        return WIN_CLOWN
    end

    return WIN_NONE
end

hook.Add("TTTWinCheckBlocks", "Clown_TTTWinCheckBlocks", function(win_blocks)
    table.insert(win_blocks, HandleClownWinBlock)
end)

hook.Add("TTTPrintResultMessage", "Clown_TTTPrintResultMessage", function(type)
    if type == WIN_CLOWN then
        LANG.Msg("win_clown", { role = ROLE_STRINGS_PLURAL[ROLE_CLOWN] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_CLOWN] .. " wins.\n")
        return true
    end
end)

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTPrepareRound", "Clown_RoleFeatures_PrepareRound", function()
    -- Disable traitor buttons for clown until they are activated (and the setting is enabled)
    TRAITOR_BUTTON_ROLES[ROLE_CLOWN] = false
end)

-------------------
-- ROLE TRACKING --
-------------------

-- Disable tracking that clown was active at the start of a new round
hook.Add("TTTPrepareRound", "Clown_PrepareRound", function()
    SetClownTeam(false)
end)

------------
-- DAMAGE --
------------

-- Scale a clown's damage
hook.Add("ScalePlayerDamage", "Clown_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    -- Only apply damage scaling after the round starts
    if GetRoundState() < ROUND_ACTIVE then return end

    local att = dmginfo:GetAttacker()
    -- Clowns deal extra damage when they are active
    if not IsPlayer(att) or not att:IsClown() or not att:IsRoleActive() then return end

    local bonus = clown_damage_bonus:GetFloat()
    dmginfo:ScaleDamage(1 + bonus)
end)