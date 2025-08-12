AddCSLuaFile()

ROLE_STARTING_CREDITS[ROLE_TASKMASTER] = 1
ROLE_HAS_PASSIVE_WIN[ROLE_TASKMASTER] = true
cvars.AddChangeCallback("ttt_taskmaster_is_passive", function(_, _, newValue)
    ROLE_HAS_PASSIVE_WIN[ROLE_TASKMASTER] = util.tobool(newValue)
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_taskmaster_kill_tasks", "1", FCVAR_REPLICATED, "The number of kill tasks assigned to the Taskmaster", 0, 10)
CreateConVar("ttt_taskmaster_misc_tasks", "2", FCVAR_REPLICATED, "The number of miscellaneous tasks assigned to the Taskmaster", 0, 10)
CreateConVar("ttt_taskmaster_completion_bonus", "1", FCVAR_REPLICATED, "How many credits the Taskmaster should get whenever they complete a task", 0, 10)
CreateConVar("ttt_taskmaster_blocks_team_wins", "1", FCVAR_REPLICATED, "Whether the Taskmaster should block teams (innocent, traitor, monster) from winning if they are alive and haven't finished their tasks.")
CreateConVar("ttt_taskmaster_win_block_length", "60", FCVAR_REPLICATED, "How long (in seconds) the Taskmaster should block teams (innocent, traitor, monster) from winning for (if 'ttt_taskmaster_blocks_team_wins' is enabled). Set to 0 to block until time runs out", 0, 300)
CreateConVar("ttt_taskmaster_wins_with_others", "1", FCVAR_REPLICATED, "If the Taskmaster should be allowed to win alongside other teams/players")
CreateConVar("ttt_taskmaster_is_passive", "1", FCVAR_REPLICATED, "Whether the Taskmaster should count as a 'passive' role for roles that need to kill other players, allowing them to win while the Taskmaster is still alive (if 'ttt_taskmaster_wins_with_others' is enabled)")

ROLE_CONVARS[ROLE_TASKMASTER] = {}

table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_kill_tasks",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
    cvar = "ttt_taskmaster_misc_tasks",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

-----------------------
-- TASK REGISTRATION --
-----------------------

TASKMASTER = {
    killTasks = {},
    miscTasks = {}
}

function TASKMASTER.RegisterTask(task)
    task.id = task.id or task.Id or task.ID

    if TASKMASTER.killTasks[task.id] or TASKMASTER.miscTasks[task.id] then
        ErrorNoHalt("ERROR: Attempted to register Taskmaster task '" .. task.id .. "' with duplicate task ID.\n")
        return
    end

    local cvarName = "ttt_taskmaster_" .. task.id .. "_enabled"
    local enabled = CreateConVar(cvarName, 1, FCVAR_REPLICATED)
    task.Enabled = function()
        return enabled:GetBool()
    end
    table.insert(ROLE_CONVARS[ROLE_TASKMASTER], {
        cvar = cvarName,
        type = ROLE_CONVAR_TYPE_BOOL
    })

    if task.isKillTask then
        TASKMASTER.killTasks[task.id] = task
    else
        TASKMASTER.miscTasks[task.id] = task
    end
end

local function AddTaskFiles(root)
    local taskFiles, _ = file.Find(root .. "*.lua", "LUA")
    for _, fil in ipairs(taskFiles) do
        include(root .. fil)
        if SERVER then AddCSLuaFile(root .. fil) end
    end
end

AddTaskFiles("terrortown/gamemode/roles/taskmaster/tasks/") -- Internal tasks
AddTaskFiles("taskmastertasks/") -- External tasks