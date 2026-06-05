local hook = hook

local AddHook = hook.Add

-------------
-- CONVARS --
-------------

CreateConVar("ttt_twins_enabled", "0", FCVAR_REPLICATED)
CreateConVar("ttt_twins_invulnerability_timer", "20", FCVAR_REPLICATED, "How long (in seconds) the twins should be made invulnerable for if only one type of twin is alive. (Set to 0 to disable.)", 0, 60)

ROLE_CONVARS[ROLE_GOODTWIN] = {
    {
        cvar = "ttt_twins_invulnerability_timer",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

ROLE_CONVARS[ROLE_EVILTWIN] = {
    {
        cvar = "ttt_twins_invulnerability_timer",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

--------------------
-- PLAYER METHODS --
--------------------

local plymeta = FindMetaTable("Player")

function plymeta:GetTwin() return self:GetGoodTwin() or self:GetEvilTwin() end
plymeta.IsTwin = plymeta.GetTwin
function plymeta:IsActiveTwin() return self:IsActive() and self:IsTwin() end

-------------------
-- ROLE SPAWNING --
-------------------

ROLE_BLOCK_SPAWN_CONVARS[ROLE_GOODTWIN] = true
ROLE_BLOCK_SPAWN_CONVARS[ROLE_EVILTWIN] = true

AddHook("TTTRoleSpawnsArtificially", "Twins_TTTRoleSpawnsArtificially", function(role)
    if role == ROLE_GOODTWIN or role == ROLE_EVILTWIN then
        if GetConVar("ttt_twins_enabled"):GetBool() then
            return true
        end
    end
end)