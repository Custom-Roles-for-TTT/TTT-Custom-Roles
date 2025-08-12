AddCSLuaFile()

local plymeta = FindMetaTable("Player")

util.AddNetworkString("TTT_TaskmasterRerollTask")
util.AddNetworkString("TTT_TaskmasterUpdateTaskList")

-------------
-- CONVARS --
-------------

local taskmaster_kill_tasks = GetConVar("ttt_taskmaster_kill_tasks")
local taskmaster_misc_tasks = GetConVar("ttt_taskmaster_misc_tasks")
local taskmaster_completion_bonus = GetConVar("ttt_taskmaster_completion_bonus")
local taskmaster_blocks_team_wins = GetConVar("ttt_taskmaster_blocks_team_wins")
local taskmaster_win_block_length = GetConVar("ttt_taskmaster_win_block_length")
local taskmaster_wins_with_others = GetConVar("ttt_taskmaster_wins_with_others")

---------------------
-- TASK ASSIGNMENT --
---------------------

function plymeta:AssignTask(isKillTask, index)
    if not self:IsTaskmaster() then return end

    local taskList = isKillTask and TASKMASTER.killTasks or TASKMASTER.miscTasks
    local taskIds = table.GetKeys(taskList)
    local activeTasksName = isKillTask and "taskmasterKillTasks" or "taskmasterMiscTasks"

    for _, activeId in ipairs(self[activeTasksName]) do
        table.RemoveByValue(taskIds, activeId)
    end
    for _, rerolledId in ipairs(self.taskmasterRerolledTasks) do
        table.RemoveByValue(taskIds, rerolledId)
    end
    table.Shuffle(taskIds)

    for _, id in ipairs(taskIds) do
        if taskList[id].CanAssignTask(self) then
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
    -- TODO: Handle edge case where there are no valid tasks. Maybe we need to change their role? Or just have a free fallback task?
    return false
end

function plymeta:RemoveTask(taskId)
    if not self:IsTaskmaster() then return end

    local isKillTask = TASKMASTER.killTasks[taskId] and true or false
    local taskList = isKillTask and TASKMASTER.killTasks or TASKMASTER.miscTasks
    local activeTasksName = isKillTask and "taskmasterKillTasks" or "taskmasterMiscTasks"

    taskList[taskId].OnTaskRemoved(self)

    table.RemoveByValue(self[activeTasksName], taskId)
    self:SetProperty(activeTasksName, self[activeTasksName], self)
end

function plymeta:RerollTask(taskId, free)
    if not self:IsTaskmaster() then return end
    if not free and self:GetCredits() == 0 then return end

    local isKillTask = TASKMASTER.killTasks[taskId] and true or false
    local activeTasksName = isKillTask and "taskmasterKillTasks" or "taskmasterMiscTasks"
    local index = table.KeyFromValue(self[activeTasksName], taskId)
    if not index then return end

    table.insert(self.taskmasterRerolledTasks, taskId)
    self:SetProperty("taskmasterRerolledTasks", self.taskmasterRerolledTasks, self)

    self:AssignTask(isKillTask, index)
    self:RemoveTask(taskId)

    if not free then
        self:SubtractCredits(1)
    end

    net.Start("TTT_TaskmasterUpdateTaskList")
    net.Send(self)
end

net.Receive("TTT_TaskmasterRerollTask", function(len, ply)
    ply:RerollTask(net.ReadString())
end)

function plymeta:CompleteTask(taskId)
    if not self:IsActiveTaskmaster() then return end

    local isKillTask = TASKMASTER.killTasks[taskId] and true or false
    local taskList = isKillTask and TASKMASTER.killTasks or TASKMASTER.miscTasks
    local activeTasksName = isKillTask and "taskmasterKillTasks" or "taskmasterMiscTasks"
    if table.HasValue(self[activeTasksName], taskId) then
        taskList[taskId].OnTaskComplete(self)
        table.insert(self.taskmasterCompletedTasks, taskId)
        self:SetProperty("taskmasterCompletedTasks", self.taskmasterCompletedTasks, self)

        local activeTasksList = table.Copy(self.taskmasterKillTasks)
        table.Add(activeTasksList, self.taskmasterMiscTasks)
        for _, id in ipairs(self.taskmasterCompletedTasks) do
            if table.HasValue(activeTasksList, id) then
                table.RemoveByValue(activeTasksList, id)
            else
                break
            end
        end
        if #activeTasksList == 0 then
            self:SetProperty("taskmasterShouldWin", true)
            -- TODO: Alert the player that they have finished all their tasks
        end

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

ROLE_ON_ROLE_ASSIGNED[ROLE_TASKMASTER] = function(ply)
    ply:SetProperty("taskmasterKillTasks", {}, ply)
    ply:SetProperty("taskmasterMiscTasks", {}, ply)
    ply:SetProperty("taskmasterCompletedTasks", {}, ply)
    ply:SetProperty("taskmasterRerolledTasks", {}, ply)
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

        if taskmaster.taskmasterShouldWin then return win_type end

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
            if v:IsTaskmaster() and v.taskmasterShouldWin then
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
    ply:ClearProperty("taskmasterKillTasks", ply)
    ply:ClearProperty("taskmasterMiscTasks", ply)
    ply:ClearProperty("taskmasterCompletedTasks", ply)
    ply:ClearProperty("taskmasterRerolledTasks", ply)
    ply:ClearProperty("taskmasterShouldWin")
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