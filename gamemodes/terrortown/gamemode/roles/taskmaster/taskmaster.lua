AddCSLuaFile()

local CurTime = CurTime
local hook = hook
local ipairs = ipairs
local math = math
local net = net
local pairs = pairs
local player = player
local table = table
local util = util

local plymeta = FindMetaTable("Player")

util.AddNetworkString("TTT_TaskmasterRerollTask")
util.AddNetworkString("TTT_TaskmasterUpdateTaskList")
util.AddNetworkString("TTT_TaskmasterTaskComplete")

-------------
-- CONVARS --
-------------

local taskmaster_completion_bonus = CreateConVar("ttt_taskmaster_completion_bonus", "1", FCVAR_NONE, "How many credits the Taskmaster should get whenever they complete a task", 0, 10)

local taskmaster_kill_tasks = GetConVar("ttt_taskmaster_kill_tasks")
local taskmaster_misc_tasks = GetConVar("ttt_taskmaster_misc_tasks")
local taskmaster_repeat_rerolls = GetConVar("ttt_taskmaster_repeat_rerolls")
local taskmaster_blocks_team_wins = GetConVar("ttt_taskmaster_blocks_team_wins")
local taskmaster_win_block_length = GetConVar("ttt_taskmaster_win_block_length")
local taskmaster_wins_with_others = GetConVar("ttt_taskmaster_wins_with_others")

---------------------
-- TASK ASSIGNMENT --
---------------------

local function CheckTaskmasterWin(ply)
    local activeTasksList = ply:GetActiveTasks()
    if #activeTasksList == 0 then
        ply:SetProperty("TaskmasterShouldWin", true)
        local message = "All tasks complete!"
        if taskmaster_wins_with_others then
            message = message .. " You will win at the end of the round."
        end
        ply:QueueMessage(MSG_PRINTBOTH, message, nil, "tskTaskComplete")
        return true
    end
    return false
end

function plymeta:AssignTask(isKillTask, index)
    if not self:IsTaskmaster() then return end

    local taskList = isKillTask and TASKMASTER.KillTasks or TASKMASTER.MiscTasks
    local taskIds = table.GetKeys(taskList)
    local activeTasksName = isKillTask and "TaskmasterKillTasks" or "TaskmasterMiscTasks"

    for _, activeId in ipairs(self[activeTasksName]) do
        table.RemoveByValue(taskIds, activeId)
    end
    for _, rerolledId in ipairs(self.TaskmasterRerolledTasks) do
        table.RemoveByValue(taskIds, rerolledId)
    end
    table.Shuffle(taskIds)

    for _, id in ipairs(taskIds) do
        if taskList[id].CanAssignTask(self) then
            local blockedByFeature = false
            for _, feature in pairs(taskList[id].RequiredFeatures) do
                for _, killTaskId in pairs(self.TaskmasterKillTasks) do
                    if not table.HasValue(self.TaskmasterCompletedTasks, killTaskId) and not table.HasValue(self.TaskmasterRerolledTasks, killTaskId) then
                        if table.HasValue(TASKMASTER.KillTasks[killTaskId].RequiredFeatures, feature) then
                            blockedByFeature = true
                            break
                        end
                    end
                end
                if blockedByFeature then break end

                for _, miscTaskId in pairs(self.TaskmasterMiscTasks) do
                    if not table.HasValue(self.TaskmasterCompletedTasks, miscTaskId) and not table.HasValue(self.TaskmasterRerolledTasks, miscTaskId) then
                        if table.HasValue(TASKMASTER.MiscTasks[miscTaskId].RequiredFeatures, feature) then
                            blockedByFeature = true
                            break
                        end
                    end
                end
                if blockedByFeature then break end
            end

            if not blockedByFeature then
                taskList[id].OnTaskAssigned(self)

                if index then
                    table.insert(self[activeTasksName], index, id)
                else
                    table.insert(self[activeTasksName], id)
                end
                self:SetProperty(activeTasksName, self[activeTasksName], self)
                return taskList[id]
            end
        end
    end
    return false
end

function plymeta:RemoveTask(taskId)
    local isKillTask = TASKMASTER.KillTasks[taskId] and true or false
    local taskList = isKillTask and TASKMASTER.KillTasks or TASKMASTER.MiscTasks
    local activeTasksName = isKillTask and "TaskmasterKillTasks" or "TaskmasterMiscTasks"

    taskList[taskId].OnTaskRemoved(self)

    table.RemoveByValue(self[activeTasksName], taskId)
    self:SetProperty(activeTasksName, self[activeTasksName], self)
end

function plymeta:RerollTask(taskId, free)
    if not self:IsTaskmaster() then return end
    if not free and self:GetCredits() == 0 then return end

    local isKillTask = TASKMASTER.KillTasks[taskId] and true or false
    local activeTasksName = isKillTask and "TaskmasterKillTasks" or "TaskmasterMiscTasks"
    local index = table.KeyFromValue(self[activeTasksName], taskId)
    if not index then return end

    -- Don't track what we rerolled if we allow the player to reroll back to the same tasks
    if not taskmaster_repeat_rerolls:GetBool() then
        table.insert(self.TaskmasterRerolledTasks, taskId)
        self:SetProperty("TaskmasterRerolledTasks", self.TaskmasterRerolledTasks, self)
    end

    local rerolled = self:AssignTask(isKillTask, index)
    self:RemoveTask(taskId)

    if not free then
        self:SubtractCredits(1)
    end

    net.Start("TTT_TaskmasterUpdateTaskList")
    net.Send(self)

    if not rerolled then
        self:QueueMessage(MSG_PRINTTALK, "Ran out of valid tasks to assign! You can have this one for free.", nil, "tskTaskRerollFailed")
        CheckTaskmasterWin(self)
    end
end

net.Receive("TTT_TaskmasterRerollTask", function(len, ply)
    ply:RerollTask(net.ReadString())
end)

function plymeta:GetActiveTasks(roundEnd)
    local activeTasksList = table.Copy(self.TaskmasterKillTasks)
    table.Add(activeTasksList, self.TaskmasterMiscTasks)
    for _, id in ipairs(self.TaskmasterCompletedTasks) do
        if table.HasValue(activeTasksList, id) then
            table.RemoveByValue(activeTasksList, id)
        end
    end

    if roundEnd then
        -- Loop backwards so removing something from this list doesn't mess us up
        for i = #activeTasksList, 1, -1 do
            local id = activeTasksList[i]
            local task = TASKMASTER.KillTasks[id]
            if not task then
                task = TASKMASTER.MiscTasks[id]
            end

            if task and task.CompleteOnRoundEnd then
                table.RemoveByValue(activeTasksList, id)
            end
        end
    end

    return activeTasksList
end

function plymeta:CompleteTask(taskId)
    if not self:IsActiveTaskmaster() then return end

    local isKillTask = TASKMASTER.KillTasks[taskId] and true or false
    local taskList = isKillTask and TASKMASTER.KillTasks or TASKMASTER.MiscTasks
    local activeTasksName = isKillTask and "TaskmasterKillTasks" or "TaskmasterMiscTasks"
    if table.HasValue(self[activeTasksName], taskId) then
        -- If our role ability was disabled, keep track of which tasks were completed
        -- so we can instantly complete them if/when we become un-disabled
        if self:IsRoleAbilityDisabled() then
            if not self.TaskmasterCompletedButBlocked then
                self.TaskmasterCompletedButBlocked = {}
            end
            if not table.HasValue(self.TaskmasterCompletedButBlocked, taskId) then
                table.insert(self.TaskmasterCompletedButBlocked, taskId)
            end
            return false
        end

        local task = taskList[taskId]
        task.OnTaskComplete(self)
        table.insert(self.TaskmasterCompletedTasks, taskId)
        self:SetProperty("TaskmasterCompletedTasks", self.TaskmasterCompletedTasks, self)

        net.Start("TTT_TaskmasterTaskComplete")
        net.Send(self)
        self:QueueMessage(MSG_PRINTTALK, "'" .. task.Name(self) .. "' complete!", nil, "tskTaskComplete")

        CheckTaskmasterWin(self)

        net.Start("TTT_TaskmasterUpdateTaskList")
        net.Send(self)

        local bonus = taskmaster_completion_bonus:GetInt()
        if bonus > 0 then
            self:AddCredits(bonus)
            LANG.Msg(self, "taskmaster_credit_bonus", {
                role = ROLE_STRINGS[ROLE_TASKMASTER],
                num = bonus
            })
        end

        return true
    end
    return false
end

hook.Add("TTTOnRoleAbilityEnabled", "Taskmaster_TTTOnRoleAbilityEnabled", function(ply)
    if not ply:IsTaskmaster() then return end
    if not ply.TaskmasterCompletedButBlocked then return end

    for _, taskId in ipairs(ply.TaskmasterCompletedButBlocked) do
        ply:CompleteTask(taskId)
    end
    ply.TaskmasterCompletedButBlocked = nil
end)

ROLE_ON_ROLE_ASSIGNED[ROLE_TASKMASTER] = function(ply)
    ply:SetProperty("TaskmasterKillTasks", {}, ply)
    ply:SetProperty("TaskmasterMiscTasks", {}, ply)
    ply:SetProperty("TaskmasterCompletedTasks", {}, ply)
    ply:SetProperty("TaskmasterRerolledTasks", {}, ply)
    for _ = 1, taskmaster_kill_tasks:GetInt() do
        ply:AssignTask(true)
    end
    for _ = 1, taskmaster_misc_tasks:GetInt() do
        ply:AssignTask(false)
    end
end

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTWinCheckBlocks", "Taskmaster_TTTWinCheckBlocks", function(win_blocks)
    table.insert(win_blocks, function(win_type)
        if win_type == WIN_NONE or win_type == WIN_TASKMASTER then return win_type end

        local taskmaster = player.GetLivingRole(ROLE_TASKMASTER)
        if not IsPlayer(taskmaster) then return win_type end

        if taskmaster.TaskmasterShouldWin then return win_type end
        -- If we only have tasks remaining that complete on round end, let the round end as normal
        if #taskmaster:GetActiveTasks(true) == 0 then return win_type end

        if not taskmaster_blocks_team_wins:GetBool() then return win_type end

        if win_type == WIN_TRAITOR or win_type == WIN_INNOCENT or win_type == WIN_MONSTER then
            local win_block_length = taskmaster_win_block_length:GetInt()
            if win_block_length > 0 then
                local winBlockEnd = GetGlobalFloat("taskmaster_block_end", 0)
                if winBlockEnd == 0 then
                    local roundEnd = GetGlobalFloat("ttt_round_end", 0)
                    local blockEnd = CurTime() + win_block_length
                    if blockEnd > roundEnd then
                        win_block_length = roundEnd - CurTime()
                    end
                    SetGlobalFloat("taskmaster_block_end", CurTime() + win_block_length)
                    local teamName
                    if win_type == WIN_TRAITOR then teamName = "traitor"
                    elseif win_type == WIN_INNOCENT then teamName = "innocent"
                    elseif win_type == WIN_MONSTER then teamName = "monster" end

                    for _, ply in player.Iterator() do
                        if ply:IsActiveTaskmaster() then
                            ply:QueueMessage(MSG_PRINTBOTH, "The " .. teamName .. " team have won! You have " .. math.Round(win_block_length) .. " seconds left to finish your tasks before the round ends!")
                        end
                    end
                elseif CurTime() > winBlockEnd then
                    return win_type
                end
            end

            return WIN_NONE
        end
    end)
end)

hook.Add("TTTCheckForWin", "Taskmaster_TTTCheckForWin", function()
    local winning_taskmaster_alive = false
    local other_alive = false
    for _, v in player.Iterator() do
        if v:IsActive() then
            -- If they have won or the only active tasks they have remaining complete on round end, they win
            if v:IsTaskmaster() and (v.TaskmasterShouldWin or #v:GetActiveTasks(true) == 0) then
                winning_taskmaster_alive = true
            elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                other_alive = true
            end
        end
    end

    if winning_taskmaster_alive and (not taskmaster_wins_with_others:GetBool() or not other_alive) then
        return WIN_TASKMASTER
    end
end)

hook.Add("TTTPrintResultMessage", "Taskmaster_TTTPrintResultMessage", function(type)
    if type == WIN_TASKMASTER then
        LANG.Msg("win_taskmaster", { role = ROLE_STRINGS[ROLE_TASKMASTER] })
        ServerLog("Result: " .. ROLE_STRINGS[ROLE_TASKMASTER] .. " wins.\n")
        return true
    end
end)

-------------
-- CLEANUP --
-------------

local function CleanupTasks(ply)
    if ply.TaskmasterKillTasks then
        for _, id in pairs(ply.TaskmasterKillTasks) do
            ply:RemoveTask(id)
        end
    end

    if ply.TaskmasterMiscTasks then
        for _, id in pairs(ply.TaskmasterMiscTasks) do
            ply:RemoveTask(id)
        end
    end

    ply:ClearProperty("TaskmasterKillTasks", ply)
    ply:ClearProperty("TaskmasterMiscTasks", ply)
    ply:ClearProperty("TaskmasterCompletedTasks", ply)
    ply:ClearProperty("TaskmasterRerolledTasks", ply)
    ply:ClearProperty("TaskmasterShouldWin")
    ply.TaskmasterCompletedButBlocked = nil
end

hook.Add("TTTPrepareRound", "Taskmaster_TTTPrepareRound", function()
    SetGlobalFloat("taskmaster_block_end", 0)
    for _, ply in player.Iterator() do
        CleanupTasks(ply)
    end
end)

hook.Add("TTTPlayerRoleChanged", "Taskmaster_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if not ply:Alive() or ply:IsSpec() then return end

    if oldRole == ROLE_TASKMASTER and oldRole ~= newRole then
        CleanupTasks(ply)
    end
end)