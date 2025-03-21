AddCSLuaFile()

local hook = hook
local net = net
local player = player
local table = table
local util = util

local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_ClownTeamChange")
util.AddNetworkString("TTT_ClownActivate")

-------------
-- CONVARS --
-------------

local clown_activation_credits = CreateConVar("ttt_clown_activation_credits", "0", FCVAR_NONE, "The number of credits to give the clown when they are activated", 0, 10)

local clown_use_traps_when_active = GetConVar("ttt_clown_use_traps_when_active")
local clown_heal_on_activate = GetConVar("ttt_clown_heal_on_activate")
local clown_heal_bonus = GetConVar("ttt_clown_heal_bonus")
local clown_damage_bonus = GetConVar("ttt_clown_damage_bonus")
local clown_activation_pct = GetConVar("ttt_clown_activation_pct")

-------------------
-- ROLE FEATURES --
-------------------

local function ActivateClown(clown)
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
        net.WritePlayer(clown)
    net.Broadcast()

    -- Give the clown their shop items if purchase was delayed
    if clown.bought and GetConVar("ttt_clown_shop_delay"):GetBool() then
        clown:GiveDelayedShopItems()
    end

    -- Enable traitor buttons for them, if that's enabled
    TRAITOR_BUTTON_ROLES[ROLE_CLOWN] = clown_use_traps_when_active:GetBool()
end

hook.Add("TTTPrepareRound", "Clown_RoleFeatures_PrepareRound", function()
    -- Disable traitor buttons for clown until they are activated (and the setting is enabled)
    TRAITOR_BUTTON_ROLES[ROLE_CLOWN] = false
end)

-- Activate the clown when a certain percentage of players have died
hook.Add("PostPlayerDeath", "Clown_ActivationPercent_PostPlayerDeath", function(ply)
    -- If they've already been activated, don't bother with this
    if INDEPENDENT_ROLES[ROLE_CLOWN] then return end

    local activation_pct = clown_activation_pct:GetFloat()
    if activation_pct <= 0 then return end

    local total_players = 0
    local living_players = 0
    local clowns = {}
    for _, p in PlayerIterator() do
        -- Keep track of the clowns
        if p:IsClown() then
            table.insert(clowns, p)
        -- Ignore players who were spectator the whole time
        elseif p:GetRole() ~= ROLE_NONE and not p:IsClown() then
            total_players = total_players + 1
        end

        -- Count the number of living non-clowns
        if p:Alive() and not p:IsSpec() and not p:IsClown() then
            living_players = living_players + 1
        end
    end

    local living_pct = living_players / total_players
    if living_pct <= activation_pct then
        for _, clown in ipairs(clowns) do
            ActivateClown(clown)
        end
    end
end)

----------------
-- WIN CHECKS --
----------------

local function HandleClownWinBlock(win_type)
    if win_type == WIN_NONE then return win_type end

    -- Activate every clown that hasn't already been activated
    local activated = false
    local living_clowns = {}
    for _, ply in PlayerIterator() do
        if not IsPlayer(ply) then continue end
        if not ply:Alive() or ply:IsSpec() then continue end
        if not ply:IsClown() then continue end
        table.insert(living_clowns, ply)

        if not ply:IsRoleActive() then
            ActivateClown(ply)
            activated = true
        end
    end

    -- If we don't have any clowns then don't bother continuing
    if #living_clowns == 0 then return win_type end

    -- Block the previous win if we just activated a clown
    if activated then
        return WIN_NONE
    end

    -- Special logic for cupid wins
    if win_type == WIN_CUPID then
        for _, clown in ipairs(living_clowns) do
            -- If the clown is a lover, let the cupid/lover win pass
            local lover = clown:GetNWString("TTTCupidLover", "")
            if #lover > 0 then
                return win_type
            end
        end
    end

    local traitor_alive, innocent_alive, indep_alive, monster_alive, _ = player.TeamLivingCount(true)
    -- If there are independents alive, check if any of them are non-clowns
    if indep_alive > 0 then
        player.ExecuteAgainstTeamPlayers(ROLE_TEAM_INDEPENDENT, true, true, function(ply)
            if ply:IsClown() then
                indep_alive = indep_alive - 1
            end
        end)
    end

    -- Clown wins if they are the only role left
    if traitor_alive <= 0 and innocent_alive <= 0 and monster_alive <= 0 and indep_alive <= 0 then
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