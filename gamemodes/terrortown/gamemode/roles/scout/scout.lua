AddCSLuaFile()

-------------
-- CONVARS --
-------------

local scout_alert_targets = CreateConVar("ttt_scout_alert_targets", "0")
local scout_hidden_roles = CreateConVar("ttt_scout_hidden_roles", "")

local scout_reveal_jesters = GetConVar("ttt_scout_reveal_jesters")
local scout_reveal_independents = GetConVar("ttt_scout_reveal_independents")
local scout_reveal_monsters = GetConVar("ttt_scout_reveal_monsters")
local scout_delay_intel = GetConVar("ttt_scout_delay_intel")

-------------------
-- ROLE FEATURES --
-------------------

local rolesToReveal = {}

local function RevealRoles(ply, delay_intel)
    if ply:IsRoleAbilityDisabled() then return end

    local sid64 = ply:SteamID64()
    if not rolesToReveal[sid64] then return end
    if #rolesToReveal[sid64] == 0 then
        ply:QueueMessage(MSG_PRINTBOTH, "There are no roles of note in play this round.")
        return
    end
    local message = "The following roles are in play: "
    if delay_intel > 0 then
        message = "As of " .. delay_intel .. " seconds ago, the following roles were in play: "
    end
    message = message .. util.FormattedList(rolesToReveal[sid64], function(str) return ROLE_STRINGS[str] end) .. "."
    ply:QueueMessage(MSG_PRINTBOTH, message)

    if scout_alert_targets:GetBool() then
        for _, p in player.Iterator() do
            local role = p:GetRole()
            if table.HasValue(rolesToReveal[sid64], role) then
                p:QueueMessage(MSG_PRINTBOTH, "The " .. ROLE_STRINGS[ROLE_SCOUT] .. " knows your role is in play.")
            end
        end
    end
end

local function GatherIntel(ply)
    local hiddenRoles = {}
    local hiddenRolesString = scout_hidden_roles:GetString()
    if #hiddenRolesString > 0 then
        hiddenRoles = string.Explode(",", hiddenRolesString)
    end

    local currentRoles = {}
    for _, p in player.Iterator() do
        local role = p:GetRole()
        if table.HasValue(hiddenRoles, ROLE_STRINGS_RAW[role]) then continue end
        if (p:IsTraitorTeam() and not p:IsTraitor()) or
            (scout_reveal_jesters:GetBool() and p:IsJesterTeam()) or
            (scout_reveal_independents:GetBool() and p:IsIndependentTeam()) or
            (scout_reveal_monsters:GetBool() and p:IsMonsterTeam()) then
            if not table.HasValue(currentRoles, role) then
                table.insert(currentRoles, role)
            end
        end
    end
    local sid64 = ply:SteamID64()
    rolesToReveal[sid64] = currentRoles

    local delay_intel = scout_delay_intel:GetInt()
    if delay_intel == 0 then
        RevealRoles(ply, 0)
    else
        ply:QueueMessage(MSG_PRINTBOTH, "Your intel is on it's way. You will learn which roles are in play in " .. delay_intel .. " seconds.")
        timer.Create("Scout_RevealRoles_" .. sid64, delay_intel, 1, function()
            RevealRoles(ply, delay_intel)
        end)
    end
end

hook.Add("TTTBeginRound", "Scout_TTTBeginRound", function()
    for _, p in player.Iterator() do
        if p:IsScout() then
            GatherIntel(p)
        end
    end
end)

ROLE_ON_ROLE_ASSIGNED[ROLE_SCOUT] = function(ply)
    if GetRoundState() == ROUND_ACTIVE then
        GatherIntel(ply)
    end
end

-------------
-- CLEANUP --
-------------

local function CleanupTimers(ply)
    local sid64 = ply:SteamID64()
    if timer.Exists("Scout_RevealRoles_" .. sid64) then timer.Remove("Scout_RevealRoles_" .. sid64) end
end

hook.Add("TTTPrepareRound", "Scout_TTTPrepareRound", function()
    for _, p in player.Iterator() do
        CleanupTimers(p)
    end
end)

hook.Add("TTTPlayerRoleChanged", "Scout_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_SCOUT and newRole ~= ROLE_SCOUT then
        CleanupTimers(ply)
    end
end)