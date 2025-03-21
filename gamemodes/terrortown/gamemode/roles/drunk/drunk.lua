AddCSLuaFile()

local plymeta = FindMetaTable("Player")

local hook = hook
local ipairs = ipairs
local math = math
local net = net
local pairs = pairs
local player = player
local table = table
local timer = timer
local util = util

local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_DrunkSober")

-------------
-- CONVARS --
-------------

local drunk_sober_time = CreateConVar("ttt_drunk_sober_time", "180", FCVAR_NONE, "Time in seconds for the drunk to remember their role", 0, 300)
local drunk_notify_mode = CreateConVar("ttt_drunk_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that the drunk sobers up", 0, 4)
local drunk_innocent_chance = CreateConVar("ttt_drunk_innocent_chance", "0.7", FCVAR_NONE, "Chance that the drunk will become an innocent role when remembering their role", 0, 1)
local drunk_traitor_chance = CreateConVar("ttt_drunk_traitor_chance", "0", FCVAR_NONE, "Chance that the drunk will become a traitor role when remembering their role and \"all roles\" logic is enabled. If disabled (0), player chance of becoming a traitor is equal to every other non-innocent role", 0, 1)
local drunk_join_losing_team = CreateConVar("ttt_drunk_join_losing_team", "0")

local drunk_become_clown = GetConVar("ttt_drunk_become_clown")
local drunk_any_role = GetConVar("ttt_drunk_any_role")
local drunk_any_role_include_disabled = GetConVar("ttt_drunk_any_role_include_disabled")

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

    -- Always exclude the evil twin because a twin suddenly appearing
    -- in the middle of a round without a counterpart will cause issues
    excludes[ROLE_EVILTWIN] = true

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

    -- Always exclude the good twin because a twin suddenly appearing
    -- in the middle of a round without a counterpart will cause issues
    excludes[ROLE_GOODTWIN] = true

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

function plymeta:DrunkJoinLosingTeam()
    if not self:IsActiveDrunk() then return false end

    local players = 0
    local innocentHealth = 0
    local traitorHealth = 0
    for _, v in PlayerIterator() do
        if IsValid(v) and v:GetRole() ~= ROLE_NONE then
            players = players + 1
            if v:IsActiveInnocentTeam() then
                innocentHealth = innocentHealth + v:Health()
            end
            if v:IsActiveTraitorTeam() then
                traitorHealth = traitorHealth + v:Health()
            end
        end
    end

    -- Find the average number of jesters and independents that spawn in each round
    local jestersIndependents
    local singleJesIndMax = GetConVar("ttt_single_jester_independent_max_players"):GetInt()
    local indChance = GetConVar("ttt_independent_chance"):GetFloat()
    if GetConVar("ttt_multiple_jesters_independents"):GetBool() then
        -- Multiple jesters and independents
        jestersIndependents = math.ceil(players * math.Round(GetConVar("ttt_jester_independent_pct"):GetFloat(), 3))
        jestersIndependents = math.min(jestersIndependents, GetConVar("ttt_jester_independent_max"):GetInt()) * GetConVar("ttt_jester_independent_chance"):GetFloat()
    elseif not GetConVar("ttt_single_jester_independent"):GetBool() or (singleJesIndMax > 0 and players > singleJesIndMax) then
        -- One jester AND one independent
        jestersIndependents = GetConVar("ttt_jester_chance"):GetFloat() + indChance
    else
        -- One jester OR one independent
        jestersIndependents = indChance
    end

    -- Find the average number of monsters that spawn in each round
    local monsters = 0
    if #GetTeamRoles(MONSTER_ROLES) > 0 then
        monsters = math.ceil(players * math.Round(GetConVar("ttt_monster_pct"):GetFloat(), 3))
        monsters = math.min(monsters, GetConVar("ttt_monster_max"):GetInt()) * GetConVar("ttt_monster_chance"):GetFloat()
    end

    -- Find the number of traitors that spawn in each round
    local traitors = math.ceil(players * math.Round(GetConVar("ttt_traitor_pct"):GetFloat(), 3))
    traitors = math.min(traitors, GetConVar("ttt_traitor_max"):GetInt())

    -- Find the average percentage of players that are traitors in each round ignoring jesters, independents, and monsters
    local traitorPct = traitors / (players - jestersIndependents - monsters)

    -- If a role pack is enabled calculate the expected ratio of innocents to traitors
    local rolePack = GetConVar("ttt_role_pack"):GetString()
    if #rolePack > 0 then
        local json = file.Read("rolepacks/" .. rolePack .. "/roles.json", "DATA")
        if json then
            local rolePackTable = util.JSONToTable(json)
            if rolePackTable then
                local filledSlotCount = 0

                local rolePackInnocents = 0
                local rolePackTraitors = 0
                local rolePackMonsters = 0
                local rolePackJestersIndependents = 0

                for _, slot in ipairs(rolePackTable.slots) do
                    -- If the slot is empty then we don't need to do any calculations
                    if #slot == 0 then continue end

                    -- If we have already filled enough slots for each player then don't include later slots in the calculation
                    if filledSlotCount >= players then
                        break
                    end
                    filledSlotCount = filledSlotCount + 1

                    -- Calculate the number of roles and their weights within this slot that belong to each team
                    local slotInnocents = 0
                    local slotTraitors = 0
                    local slotMonsters = 0
                    local slotJestersIndependents = 0
                    for _, roleslot in ipairs(slot) do
                        local role = ROLE_NONE
                        for r = ROLE_INNOCENT, ROLE_MAX do
                            if ROLE_STRINGS_RAW[r] == roleslot.role then
                                role = r
                                break
                            end
                        end
                        if role > ROLE_NONE then
                            if INNOCENT_ROLES[role] then
                                slotInnocents = slotInnocents + roleslot.weight
                            elseif TRAITOR_ROLES[role] then
                                slotTraitors = slotTraitors + roleslot.weight
                            elseif MONSTER_ROLES[role] then
                                slotMonsters = slotMonsters + roleslot.weight
                            else
                                slotJestersIndependents = slotJestersIndependents + roleslot.weight
                            end
                        end
                    end

                    -- From the summed weights, add the percentage change that this slot will be filled by a role of each team to the totals
                    local totalSlotWeight = slotInnocents + slotTraitors + slotMonsters + slotJestersIndependents
                    rolePackInnocents = rolePackInnocents + (slotInnocents / totalSlotWeight)
                    rolePackTraitors = rolePackTraitors + (slotTraitors / totalSlotWeight)
                    rolePackMonsters = rolePackMonsters + (slotMonsters / totalSlotWeight)
                    rolePackJestersIndependents = rolePackJestersIndependents + (slotJestersIndependents / totalSlotWeight)
                end

                -- If we didn't fill enough slots for each player then we need to calculate what teams would fill the remaining slots using the same order used in regular role spawning (traitor>jester/independent>monster>innocent)
                if filledSlotCount < players then
                    local remainingSlots = players - filledSlotCount

                    -- If there should be more traitors then fill as many empty slots as required with traitors
                    if rolePackTraitors < traitors and remainingSlots > 0 then
                        local requiredExtraTraitors = math.min(traitors - rolePackTraitors, remainingSlots)
                        rolePackTraitors = rolePackTraitors + requiredExtraTraitors
                        remainingSlots = remainingSlots - requiredExtraTraitors
                    end

                    -- If there should be more jesters/independents then fill as many empty slots as required with jesters/independents
                    if rolePackJestersIndependents < jestersIndependents and remainingSlots > 0 then
                        local requiredExtraJestersIndependents = math.min(jestersIndependents - rolePackJestersIndependents, remainingSlots)
                        -- We don't actually need to know how many jesters/independents there are but we do need to know if any slots have been taken up
                        remainingSlots = remainingSlots - requiredExtraJestersIndependents
                    end

                    -- If there should be more monsters then fill as many empty slots as required with monsters
                    if rolePackMonsters < monsters and remainingSlots > 0 then
                        local requiredExtraMonsters = math.min(monsters - rolePackMonsters, remainingSlots)
                        -- We don't actually need to know how many monsters there are but we do need to know if any slots have been taken up
                        remainingSlots = remainingSlots - requiredExtraMonsters
                    end

                    -- Any remaining slots would be innocents
                    rolePackInnocents = rolePackInnocents + remainingSlots
                end

                -- Find the average percentage of players that are traitors in each round ignoring jesters, independents, and monsters
                traitorPct = rolePackTraitors / (rolePackInnocents + rolePackTraitors)
            else
                ErrorNoHalt("Table decoding failed!\n")
            end
        else
            ErrorNoHalt("No role pack named '" .. rolePack .. "' found!\n")
        end
    end

    -- Find whether the drunk joining the innocent, traitor, or another team will bring the ratio of traitor health to traitor and innocent health closest to the value calculated above
    local drunkHealth = self:Health()

    local innocentHealthRatio = traitorHealth / (innocentHealth + drunkHealth + traitorHealth)
    local traitorHealthRatio = (traitorHealth + drunkHealth) / (innocentHealth + traitorHealth + drunkHealth)
    local otherHealthRatio = traitorHealth / (innocentHealth + traitorHealth)

    local innocentDiff = math.abs(innocentHealthRatio - traitorPct)
    local traitorDiff = math.abs(traitorHealthRatio - traitorPct)
    local otherDiff = math.abs(otherHealthRatio - traitorPct)

    local losingTeam = ROLE_TEAM_TRAITOR
    if otherDiff <= innocentDiff and otherDiff <= traitorDiff then
        local rand = math.random()
        if #GetTeamRoles(MONSTER_ROLES) > 0 then
            if rand < 1/3 then
                losingTeam = ROLE_TEAM_JESTER
            elseif rand < 2/3 then
                losingTeam = ROLE_TEAM_INDEPENDENT
            else
                losingTeam = ROLE_TEAM_MONSTER
            end
        else
            if rand < 0.5 then
                losingTeam = ROLE_TEAM_JESTER
            else
                losingTeam = ROLE_TEAM_INDEPENDENT
            end
        end
    elseif innocentDiff <= traitorDiff then
        losingTeam = ROLE_TEAM_INNOCENT
    end

    self:SoberDrunk(losingTeam)
    return true
end

function plymeta:SoberDrunk(team)
    if not self:IsActiveDrunk() then return false end

    local role = nil
    -- If any role is allowed
    if drunk_any_role:GetBool() then
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
        -- Or build a list of the options based on what team is randomly chosen (innocent vs. traitor vs. everything else)
        else
            if math.random() <= drunk_innocent_chance:GetFloat() then
                role_options = GetTeamRoles(INNOCENT_ROLES, GetInnocentTeamDrunkExcludes())
            elseif math.random() <= drunk_traitor_chance:GetFloat() then
                role_options = GetTeamRoles(TRAITOR_ROLES, GetTraitorTeamDrunkExcludes())
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
            for _, p in PlayerIterator() do
                if p:IsCustom() then
                    table.RemoveByValue(role_options, p:GetRole())
                end
            end

            -- Keep track of which ones are explicitly allowed because removing from tables that you are iterating over causes the iteration to skip elements
            local allowed_options = {}

            -- Remove any roles that are not enabled or allowed
            for _, r in ipairs(role_options) do
                local rolestring = ROLE_STRINGS_RAW[r]
                if cvars.Bool("ttt_drunk_can_be_" .. rolestring, false) and (DEFAULT_ROLES[r] or drunk_any_role_include_disabled:GetBool() or util.CanRoleSpawnNaturally(r)) then
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
        elseif math.random() <= drunk_innocent_chance:GetFloat() then
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
    if not hidecenter then self:QueueMessage(MSG_PRINTCENTER, "You have remembered that you are " .. ROLE_STRINGS_EXT[role] .. ".") end
    self:SetDefaultCredits()

    local mode = drunk_notify_mode:GetInt()
    if mode > 0 then
        for _, v in PlayerIterator() do
            if self ~= v then
                if (v:IsTraitorTeam() and (mode == JESTER_NOTIFY_DETECTIVE_AND_TRAITOR or mode == JESTER_NOTIFY_TRAITOR)) or -- the enums here are the same as for the jester notifications so we can just use those
                        (v:IsDetectiveLike() and (mode == JESTER_NOTIFY_DETECTIVE_AND_TRAITOR or mode == JESTER_NOTIFY_DETECTIVE)) or
                        mode == JESTER_NOTIFY_EVERYONE then
                    v:PrintMessage(HUD_PRINTTALK, string.Capitalize(ROLE_STRINGS_EXT[ROLE_DRUNK]) .. " has remembered their role.")
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
    SetGlobalFloat("ttt_drunk_remember", CurTime() + drunk_sober_time:GetInt())
    timer.Create("drunkremember", drunk_sober_time:GetInt(), 1, function()
        for _, p in PlayerIterator() do
            if p:IsActiveDrunk() then
                if drunk_join_losing_team:GetBool() then
                    p:DrunkJoinLosingTeam()
                else
                    p:SoberDrunk()
                end
            elseif p:IsDrunk() and not p:Alive() and not timer.Exists("waitfordrunkrespawn") then
                timer.Create("waitfordrunkrespawn", 0.1, 0, function()
                    local dead_drunk = false
                    for _, p2 in PlayerIterator() do
                        if p2:IsActiveDrunk() then
                            if drunk_join_losing_team:GetBool() then
                                p2:DrunkJoinLosingTeam()
                            else
                                p2:SoberDrunk()
                            end
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

local function HandleDrunkWinBlock(win_type)
    if win_type == WIN_NONE then return win_type end

    local drunk = player.GetLivingRole(ROLE_DRUNK)
    if not IsPlayer(drunk) then return win_type end

    -- Make the drunk a clown
    if drunk_become_clown:GetBool() then
        StopDrunkTimers()
        drunk:DrunkRememberRole(ROLE_CLOWN, true)
        return WIN_NONE
    end

    -- Change the drunk to whichever team is about to lose
    local traitor_alive, innocent_alive, _, _, _ = player.AreTeamsLiving()
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
    for _, v in PlayerIterator() do
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