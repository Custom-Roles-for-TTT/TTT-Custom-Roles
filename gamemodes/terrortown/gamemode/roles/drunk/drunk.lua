AddCSLuaFile()

local plymeta = FindMetaTable("Player")

util.AddNetworkString("TTT_DrunkSober")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_drunk_sober_time", "180")
CreateConVar("ttt_drunk_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that the drunk sobers up", 0, 4)
CreateConVar("ttt_drunk_innocent_chance", "0.7")
CreateConVar("ttt_drunk_become_clown", "0")
CreateConVar("ttt_drunk_any_role", "0")
for role = 0, ROLE_MAX do
    if role ~= ROLE_DRUNK and role ~= ROLE_GLITCH then
        CreateConVar("ttt_drunk_can_be_" .. ROLE_STRINGS_RAW[role], "1")
    end
end

hook.Add("TTTSyncGlobals", "Drunk_TTTSyncGlobals", function()
    SetGlobalBool("ttt_drunk_become_clown", GetConVar("ttt_drunk_become_clown"):GetBool())
end)

-----------------------
-- ROLE CHANGE LOGIC --
-----------------------

hook.Add("Initialize", "Drunk_RoleChange_Initialize", function()
    SetGlobalFloat("ttt_drunk_remember", -1)
end)

local function GetTraitorTeamDrunkExcludes()
    local excludes = {}
    -- Exclude any roles whose predicate fails
    for r, pred in pairs(ROLE_SELECTION_PREDICATE) do
        if TRAITOR_ROLES[r] and not pred() then
            excludes[r] = true
        end
    end

    return excludes
end

local function GetInnocentTeamDrunkExcludes()
    -- Exclude detectives from the innocent list
    local excludes = table.Copy(DETECTIVE_ROLES)
    -- Also exclude any roles whose predicate fails
    for r, pred in pairs(ROLE_SELECTION_PREDICATE) do
        if INNOCENT_ROLES[r] and not pred() then
            excludes[r] = true
        end
    end

    -- Always exclude the glitch because a glitch suddenly appearing
    -- in the middle of a round makes it obvious who is not a real traitor
    excludes[ROLE_GLITCH] = true

    return excludes
end

local function GetJesterTeamDrunkExcludes()
    local excludes = {}
    -- Exclude any roles whose predicate fails
    for r, pred in pairs(ROLE_SELECTION_PREDICATE) do
        if JESTER_ROLES[r] and not pred() then
            excludes[r] = true
        end
    end

    return excludes
end

local function GetIndependentTeamDrunkExcludes()
    -- Exclude the drunk since they already are one
    local excludes = {}
    excludes[ROLE_DRUNK] = true

    -- Also exclude any roles whose predicate fails
    for r, pred in pairs(ROLE_SELECTION_PREDICATE) do
        if INDEPENDENT_ROLES[r] and not pred() then
            excludes[r] = true
        end
    end

    -- Also exclude the mad scientist if zombies aren't independent (same as spawning logic)
    if not INDEPENDENT_ROLES[ROLE_ZOMBIE] then
        excludes[ROLE_MADSCIENTIST] = true
    end

    return excludes
end

local function GetMonsterTeamDrunkExcludes()
    local excludes = {}
    -- Exclude any roles whose predicate fails
    for r, pred in pairs(ROLE_SELECTION_PREDICATE) do
        if MONSTER_ROLES[r] and not pred() then
            excludes[r] = true
        end
    end

    return excludes
end

local function GetDetectiveTeamDrunkExcludes()
    local excludes = {}
    -- Exclude any roles whose predicate fails
    for r, pred in pairs(ROLE_SELECTION_PREDICATE) do
        if DETECTIVE_ROLES[r] and not pred() then
            excludes[r] = true
        end
    end

    return excludes
end

function plymeta:SoberDrunk(team)
    if not self:IsActiveDrunk() then return false end

    local role = nil
    -- If any role is allowed
    if GetConVar("ttt_drunk_any_role"):GetBool() then
        local role_options = {}
        -- Get the role options by team, if one was given
        if team then
            if team == ROLE_TEAM_TRAITOR then
                role_options = GetTeamRoles(TRAITOR_ROLES, GetTraitorTeamDrunkExcludes())
            elseif team == ROLE_TEAM_INNOCENT then
                role_options = GetTeamRoles(INNOCENT_ROLES, GetInnocentTeamDrunkExcludes())
            elseif team == ROLE_TEAM_JESTER then
                role_options = GetTeamRoles(JESTER_ROLES, GetJesterTeamDrunkExcludes())
            elseif team == ROLE_TEAM_INDEPENDENT then
                role_options = GetTeamRoles(INDEPENDENT_ROLES, GetIndependentTeamDrunkExcludes())
            elseif team == ROLE_TEAM_MONSTER then
                role_options = GetTeamRoles(MONSTER_ROLES, GetMonsterTeamDrunkExcludes())
            elseif team == ROLE_TEAM_DETECTIVE then
                role_options = GetTeamRoles(DETECTIVE_ROLES, GetDetectiveTeamDrunkExcludes())
            end
        -- Or build a list of the options based on what team is randomly chosen (innocent vs. everything else)
        else
            if math.random() <= GetConVar("ttt_drunk_innocent_chance"):GetFloat() then
                role_options = GetTeamRoles(INNOCENT_ROLES, GetInnocentTeamDrunkExcludes())
            else
                local excludes = GetIndependentTeamDrunkExcludes()
                -- Add every non-innocent role (except those that are excluded)
                for r = 0, ROLE_MAX do
                    if not INNOCENT_ROLES[r] and not excludes[r] then
                        table.insert(role_options, r)
                    end
                end
            end
        end

        -- If there are role options, remove any that shouldn't be used
        if #role_options > 0 then
            -- Remove any used roles
            for _, p in ipairs(player.GetAll()) do
                if p:IsCustom() then
                    table.RemoveByValue(role_options, p:GetRole())
                end
            end

            -- Keep track of which ones are explicitly allowed because removing from tables that you are iterating over causes the iteration to skip elements
            local allowed_options = {}

            -- Remove any roles that are not enabled or allowed
            for _, r in ipairs(role_options) do
                local rolestring = ROLE_STRINGS_RAW[r]
                if GetConVar("ttt_drunk_can_be_" .. rolestring):GetBool() and (DEFAULT_ROLES[r] or GetConVar("ttt_" .. rolestring .. "_enabled"):GetBool()) then
                    table.insert(allowed_options, r)
                end
            end

            role_options = allowed_options
        end

        -- Choose one of the roles, if there are any
        if #role_options > 0 then
            role = role_options[math.random(1, #role_options)]
        end
    end

    -- If a role hasn't already been chosen, fall back to the either-or logic
    if not role then
        -- If a team is given, use it to choose one of the basic options
        if team then
            role = team == ROLE_TEAM_TRAITOR and ROLE_TRAITOR or ROLE_INNOCENT
        -- If not, use randomization
        elseif math.random() <= GetConVar("ttt_drunk_innocent_chance"):GetFloat() then
            role = ROLE_INNOCENT
        else
            role = ROLE_TRAITOR
        end
    end

    self:DrunkRememberRole(role)
    return true
end

function plymeta:DrunkRememberRole(role, hidecenter)
    if not self:IsActiveDrunk() then return false end

    self:SetNWBool("WasDrunk", true)
    self:SetRole(role)
    self:PrintMessage(HUD_PRINTTALK, "You have remembered that you are " .. ROLE_STRINGS_EXT[role] .. ".")
    if not hidecenter then self:PrintMessage(HUD_PRINTCENTER, "You have remembered that you are " .. ROLE_STRINGS_EXT[role] .. ".") end
    self:SetDefaultCredits()

    local mode = GetConVar("ttt_drunk_notify_mode"):GetInt()
    if mode > 0 then
        for _, v in pairs(player.GetAll()) do
            if self ~= v then
                if (v:IsTraitorTeam() and (mode == JESTER_NOTIFY_DETECTIVE_AND_TRAITOR or mode == JESTER_NOTIFY_TRAITOR)) or -- the enums here are the same as for the jester notifications so we can just use those
                        (v:IsDetectiveLike() and (mode == JESTER_NOTIFY_DETECTIVE_AND_TRAITOR or mode == JESTER_NOTIFY_DETECTIVE)) or
                        mode == JESTER_NOTIFY_EVERYONE then
                    v:PrintMessage(HUD_PRINTTALK, ROLE_STRINGS_EXT[ROLE_DRUNK] .. " has remembered their role.")
                end
            end
        end
    end

    -- Update role health
    SetRoleMaxHealth(self)
    if self:Health() > self:GetMaxHealth() then
        self:SetHealth(self:GetMaxHealth())
    end

    -- Start role special logic checks
    self:BeginRoleChecks()

    -- Give loadout weapons
    hook.Run("PlayerLoadout", self)

    net.Start("TTT_DrunkSober")
    net.WriteString(self:Nick())
    net.WriteString(ROLE_STRINGS_EXT[role])
    net.Broadcast()

    SendFullStateUpdate()
    return true
end

ROLE_ON_ROLE_ASSIGNED[ROLE_DRUNK] = function(ply)
    SetGlobalFloat("ttt_drunk_remember", CurTime() + GetConVar("ttt_drunk_sober_time"):GetInt())
    timer.Create("drunkremember", GetConVar("ttt_drunk_sober_time"):GetInt(), 1, function()
        for _, p in pairs(player.GetAll()) do
            if p:IsActiveDrunk() then
                p:SoberDrunk()
            elseif p:IsDrunk() and not p:Alive() and not timer.Exists("waitfordrunkrespawn") then
                timer.Create("waitfordrunkrespawn", 0.1, 0, function()
                    local dead_drunk = false
                    for _, p2 in pairs(player.GetAll()) do
                        if p2:IsActiveDrunk() then
                            p2:SoberDrunk()
                        elseif p2:IsDrunk() and not p2:Alive() then
                            dead_drunk = true
                        end
                    end
                    if timer.Exists("waitfordrunkrespawn") and not dead_drunk then timer.Remove("waitfordrunkrespawn") end
                end)
            end
        end
    end)
end

local function StopDrunkTimers()
    if timer.Exists("drunkremember") then timer.Remove("drunkremember") end
    if timer.Exists("waitfordrunkrespawn") then timer.Remove("waitfordrunkrespawn") end
end

local unblockable_wins = {WIN_TIMELIMIT}
local function HandleDrunkWinBlock(win_type)
    if win_type == WIN_NONE then return win_type end
    if table.HasValue(unblockable_wins, win_type) then return win_type end

    local drunk = player.GetLivingRole(ROLE_DRUNK)
    if not IsPlayer(drunk) then return win_type end

    -- Make the drunk a clown
    if GetConVar("ttt_drunk_become_clown"):GetBool() then
        StopDrunkTimers()
        drunk:DrunkRememberRole(ROLE_CLOWN, true)
        return WIN_NONE
    end

    -- Change the drunk to whichever team is about to lose
    local innocent_alive, traitor_alive, _, _, _ = player.AreTeamsLiving()
    if not traitor_alive then
        StopDrunkTimers()
        drunk:SoberDrunk(ROLE_TEAM_TRAITOR)
        return WIN_NONE
    elseif not innocent_alive then
        StopDrunkTimers()
        drunk:SoberDrunk(ROLE_TEAM_INNOCENT)
        return WIN_NONE
    end
end

hook.Add("TTTWinCheckBlocks", "Drunk_TTTWinCheckBlocks", function(win_blocks)
    table.insert(win_blocks, HandleDrunkWinBlock)
end)

hook.Add("TTTPrepareRound", "Drunk_PrepareRound", function()
    for _, v in pairs(player.GetAll()) do
        v:SetNWBool("WasDrunk", false)
    end
end)

hook.Add("TTTEndRound", "Drunk_TTTEndRound", function()
    StopDrunkTimers()
end)

-----------
-- KARMA --
-----------

-- Drunk loses karma because they aren't supposed to meta-game the system to choose what team they join
hook.Add("TTTKarmaShouldGivePenalty", "Drunk_TTTKarmaShouldGivePenalty", function(attacker, victim)
    if attacker:IsDrunk() then
        return true
    end
end)