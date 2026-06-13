AddCSLuaFile()

local cvars = cvars
local hook = hook
local ipairs = ipairs
local pairs = pairs
local table = table

local AddHook = hook.Add
local TableInsert = table.insert

-- Task Features
TASKMASTER_TF_TARGETID_PLAYERICON = 0
TASKMASTER_TF_TARGETID_PLAYERTEXT = 1
TASKMASTER_TF_PROGRESSBAR = 2
TASKMASTER_TF_PARTICLERADIUS = 3

-- Initialize role features
ROLE_CAN_SEE_JESTERS[ROLE_TASKMASTER] = true
ROLE_CAN_SEE_MIA[ROLE_TASKMASTER] = true
ROLE_STARTING_CREDITS[ROLE_TASKMASTER] = 1
ROLE_HAS_PASSIVE_WIN[ROLE_TASKMASTER] = false
cvars.AddChangeCallback("ttt_taskmaster_is_passive", function(_, _, newValue)
    ROLE_HAS_PASSIVE_WIN[ROLE_TASKMASTER] = tobool(newValue)
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_taskmaster_kill_tasks", "1", FCVAR_REPLICATED, "The number of kill tasks assigned to the Taskmaster", 0, 10)
CreateConVar("ttt_taskmaster_misc_tasks", "2", FCVAR_REPLICATED, "The number of miscellaneous tasks assigned to the Taskmaster", 0, 10)
CreateConVar("ttt_taskmaster_repeat_rerolls", "1", FCVAR_REPLICATED, "Whether the Taskmaster can be assigned tasks they previously rerolled away from", 0, 1)
CreateConVar("ttt_taskmaster_blocks_team_wins", "1", FCVAR_REPLICATED, "Whether the Taskmaster should block teams (innocent, traitor, monster) from winning if they are alive and haven't finished their tasks.", 0, 1)
CreateConVar("ttt_taskmaster_win_block_length", "60", FCVAR_REPLICATED, "How long (in seconds) the Taskmaster should block teams (innocent, traitor, monster) from winning for (if 'ttt_taskmaster_blocks_team_wins' is enabled). Set to 0 to block until time runs out", 0, 300)
CreateConVar("ttt_taskmaster_wins_with_others", "1", FCVAR_REPLICATED, "If the Taskmaster should be allowed to win alongside other teams/players", 0, 1)
CreateConVar("ttt_taskmaster_is_passive", "0", FCVAR_REPLICATED, "Whether the Taskmaster should count as a 'passive' role for roles that need to kill other players, allowing them to win while the Taskmaster is still alive (if 'ttt_taskmaster_wins_with_others' is enabled)", 0, 1)

ROLE_CONVARS[ROLE_TASKMASTER] = {
    {
        cvar = "ttt_taskmaster_kill_tasks",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_taskmaster_misc_tasks",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_taskmaster_completion_bonus",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_taskmaster_repeat_rerolls",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_taskmaster_blocks_team_wins",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_taskmaster_win_block_length",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_taskmaster_wins_with_others",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_taskmaster_is_passive",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

-----------------------
-- TASK REGISTRATION --
-----------------------

TASKMASTER = {
    KillTasks = {},
    MiscTasks = {}
}

function TASKMASTER.RegisterTask(task)
    task.id = task.id or task.Id or task.ID

    if TASKMASTER.KillTasks[task.id] or TASKMASTER.MiscTasks[task.id] then
        ErrorNoHalt("ERROR: Attempted to register Taskmaster task '" .. task.id .. "' with duplicate task ID.\n")
        return
    end

    local cvarName = "ttt_taskmaster_" .. task.id .. "_enabled"
    local enabled = CreateConVar(cvarName, 1, FCVAR_REPLICATED, "Whether the '" .. task.Name() .. "' task should be enabled", 0, 1)
    task.Enabled = function()
        return enabled:GetBool()
    end
    TableInsert(ROLE_CONVARS[ROLE_TASKMASTER], {
        cvar = cvarName,
        type = ROLE_CONVAR_TYPE_BOOL
    })

    if task.IsKillTask then
        TASKMASTER.KillTasks[task.id] = task
    else
        TASKMASTER.MiscTasks[task.id] = task
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

AddHook("Initialize", "Taskmaster_Task_Initialize", function()
    for _, t in pairs(TASKMASTER.KillTasks) do
        if t.Initialize then
            t.Initialize()
        end
    end
    for _, t in pairs(TASKMASTER.MiscTasks) do
        if t.Initialize then
            t.Initialize()
        end
    end
end)