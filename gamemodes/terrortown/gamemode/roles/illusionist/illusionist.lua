AddCSLuaFile()

local player = player
local timer = timer

local AddHook = hook.Add
local RemoveHook = hook.Remove
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

AddHook("Initialize", "Illusionist_Initialize", function()
    SetGlobalBool("ttt_illusionist_alive", false)
end)

local function Illusionist_TTTBeginRound()
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
end

local function Illusionist_TTTEndRound()
    SetGlobalBool("ttt_illusionist_alive", false)
end

local function Illusionist_PlayerDeath(victim, infl, attacker)
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
end

local function Illusionist_TTTPlayerSpawnForRound(ply, dead_only)
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
end

AddHook("TTTPlayerRoleChanged", "Illusionist_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
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

local function Illusionist_TTTTeamChatTargets(sender, msg, targets, from_chat)
    if (sender:IsTraitorTeam() or (sender:IsMonsterTeam() and illusionist_hides_monsters:GetBool())) and IsIllusionistBlocking() then
        sender:PrintMessage(HUD_PRINTTALK, "The " .. ROLE_STRINGS[ROLE_ILLUSIONIST] .. " is preventing you from communicating with your allies.")
        return false
    end
end

local function Illusionist_TTTTeamVoiceChatTargets(sender, targets, state)
    if not state and (sender:IsTraitorTeam() or (sender:IsMonsterTeam() and illusionist_hides_monsters:GetBool())) and IsIllusionistBlocking() then
        sender:PrintMessage(HUD_PRINTTALK, "The " .. ROLE_STRINGS[ROLE_ILLUSIONIST] .. " is preventing you from communicating with your allies.")
        return false
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_ILLUSIONIST] = function()
    AddHook("PlayerDeath", "Illusionist_PlayerDeath", Illusionist_PlayerDeath)
    AddHook("TTTBeginRound", "Illusionist_TTTBeginRound", Illusionist_TTTBeginRound)
    AddHook("TTTEndRound", "Illusionist_TTTEndRound", Illusionist_TTTEndRound)
    AddHook("TTTPlayerSpawnForRound", "Illusionist_TTTPlayerSpawnForRound", Illusionist_TTTPlayerSpawnForRound)
    AddHook("TTTTeamChatTargets", "Illusionist_TTTTeamChatTargets", Illusionist_TTTTeamChatTargets)
    AddHook("TTTTeamVoiceChatTargets", "Illusionist_TTTTeamVoiceChatTargets", Illusionist_TTTTeamVoiceChatTargets)
end

ROLE_UNREGISTER_HOOKS[ROLE_ILLUSIONIST] = function()
    RemoveHook("PlayerDeath", "Illusionist_PlayerDeath")
    RemoveHook("TTTBeginRound", "Illusionist_TTTBeginRound")
    RemoveHook("TTTEndRound", "Illusionist_TTTEndRound")
    RemoveHook("TTTPlayerSpawnForRound", "Illusionist_TTTPlayerSpawnForRound")
    RemoveHook("TTTTeamChatTargets", "Illusionist_TTTTeamChatTargets")
    RemoveHook("TTTTeamVoiceChatTargets", "Illusionist_TTTTeamVoiceChatTargets")
end