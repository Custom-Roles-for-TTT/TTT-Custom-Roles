AddCSLuaFile()

local hook = hook

-------------
-- CONVARS --
-------------

local marshal_monster_deputy_chance = CreateConVar("ttt_marshal_monster_deputy_chance", "0.5", FCVAR_NONE, "The chance that a monster will become a deputy. -1 to disable", -1, 1)
local marshal_jester_deputy_chance = CreateConVar("ttt_marshal_jester_deputy_chance", "0.5", FCVAR_NONE, "The chance that a jester will become a deputy. -1 to disable", -1, 1)
local marshal_independent_deputy_chance = CreateConVar("ttt_marshal_independent_deputy_chance", "0.5", FCVAR_NONE, "The chance that an independent will become a deputy. -1 to disable", -1, 1)
local marshal_announce_deputy = CreateConVar("ttt_marshal_announce_deputy", "1")

hook.Add("TTTSyncGlobals", "Marshal_TTTSyncGlobals", function()
    SetGlobalFloat("ttt_marshal_monster_deputy_chance", marshal_monster_deputy_chance:GetFloat())
    SetGlobalFloat("ttt_marshal_jester_deputy_chance", marshal_jester_deputy_chance:GetFloat())
    SetGlobalFloat("ttt_marshal_independent_deputy_chance", marshal_independent_deputy_chance:GetFloat())
    SetGlobalBool("ttt_marshal_announce_deputy", marshal_announce_deputy:GetBool())
end)
