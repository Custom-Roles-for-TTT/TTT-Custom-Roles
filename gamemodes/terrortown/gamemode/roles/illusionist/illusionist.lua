AddCSLuaFile()

local player = player

local PlayerIterator = player.Iterator

-------------
-- CONVARS --
-------------

local illusionist_hides_monsters = GetConVar("ttt_illusionist_hides_monsters")
local illusionist_traitor_credits = GetConVar("ttt_illusionist_traitor_credits")

-----------------
-- ALIVE CHECK --
-----------------

ROLE_ON_ROLE_ASSIGNED[ROLE_ILLUSIONIST] = function(ply)
    SetGlobalBool("ttt_illusionist_alive", true)
end

hook.Add("Initialize", "Illusionist_Initialize", function()
    SetGlobalBool("ttt_illusionist_alive", false)
end)

hook.Add("TTTBeginRound", "Illusionist_TTTBeginRound", function()
    local alive = player.IsRoleLiving(ROLE_ILLUSIONIST)
    SetGlobalBool("ttt_illusionist_alive", alive)
    if alive then
        local traitor_credits = illusionist_traitor_credits:GetInt()
        timer.Simple(1.5, function()
            for _, v in PlayerIterator() do
                if v:IsTraitorTeam() or (v:IsMonsterTeam() and illusionist_hides_monsters:GetBool()) then
                    v:QueueMessage(MSG_PRINTBOTH, "There is " .. ROLE_STRINGS_EXT[ROLE_ILLUSIONIST] .. ".")
                    if traitor_credits > 0 then
                        v:AddCredits(traitor_credits)
                    end
                end
            end
        end)
    end
end)

hook.Add("TTTEndRound", "Illusionist_TTTEndRound", function()
    SetGlobalBool("ttt_illusionist_alive", false)
end)

hook.Add("PlayerDeath", "Illusionist_PlayerDeath", function(victim, infl, attacker)
    if not victim:IsIllusionist() then return end
    local alive = player.IsRoleLiving(ROLE_ILLUSIONIST)
    if not alive then
        SetGlobalBool("ttt_illusionist_alive", false)
        for _, v in PlayerIterator() do
            if v:IsActiveTraitorTeam() or (v:IsActiveMonsterTeam() and illusionist_hides_monsters:GetBool()) then
                v:QueueMessage(MSG_PRINTBOTH, "The " .. ROLE_STRINGS[ROLE_ILLUSIONIST] .. " has been killed!")
            end
        end
    end
end)

hook.Add("TTTPlayerSpawnForRound", "Illusionist_TTTPlayerSpawnForRound", function(ply, dead_only)
    if ply:IsIllusionist() and not GetGlobalBool("ttt_illusionist_alive", false) then
        SetGlobalBool("ttt_illusionist_alive", true)
        if GetRoundState() == ROUND_ACTIVE then
            for _, v in PlayerIterator() do
                if v:IsActiveTraitorTeam() or (v:IsActiveMonsterTeam() and illusionist_hides_monsters:GetBool()) then
                    v:QueueMessage(MSG_PRINTBOTH, string.Capitalize(ROLE_STRINGS_EXT[ROLE_ILLUSIONIST]) .. " has appeared!")
                end
            end
        end
    end
end)

hook.Add("TTTPlayerRoleChanged", "Illusionist_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if not ply:Alive() or ply:IsSpec() then return end
    if newRole ~= oldRole and newRole == ROLE_ILLUSIONIST and not GetGlobalBool("ttt_illusionist_alive", false) then
        SetGlobalBool("ttt_illusionist_alive", true)
        if GetRoundState() == ROUND_ACTIVE then
            for _, v in PlayerIterator() do
                if v:IsActiveTraitorTeam() or (v:IsActiveMonsterTeam() and illusionist_hides_monsters:GetBool()) then
                    v:QueueMessage(MSG_PRINTBOTH, string.Capitalize(ROLE_STRINGS_EXT[ROLE_ILLUSIONIST]) .. " has appeared!")
                end
            end
        end
    end
end)

---------------
-- TEAM CHAT --
---------------

hook.Add("TTTTeamChatTargets", "Illusionist_TTTTeamChatTargets", function(sender, msg, targets, from_chat)
    if IsIllusionistBlocking() and (sender:IsTraitorTeam() or (sender:IsMonsterTeam() and illusionist_hides_monsters:GetBool())) then
        sender:PrintMessage(HUD_PRINTTALK, "The " .. ROLE_STRINGS[ROLE_ILLUSIONIST] .. " is preventing you from communicating with your allies.")
        return false
    end
end)