AddCSLuaFile()

local hook = hook
local player = player
local util = util

local AddHook = hook.Add
local RemoveHook = hook.Remove
local PlayerIterator = player.Iterator

local plymeta = FindMetaTable("Player")

util.AddNetworkString("TTT_TurncoatTeamChange")

-------------
-- CONVARS --
-------------

local turncoat_change_max_health = CreateConVar("ttt_turncoat_change_max_health", "1", FCVAR_NONE, "Whether to change the turncoat's max health when they change teams", 0, 1)

local turncoat_change_health = GetConVar("ttt_turncoat_change_health")
local turncoat_change_innocent_kill = GetConVar("ttt_turncoat_change_innocent_kill")

-------------------
-- ROLE FEATURES --
-------------------

function plymeta:ChangeTurncoatTeam(extra)
    if not self:IsTurncoat() then return end
    if self:IsTraitorTeam() then return end

    -- Change team and broadcast to everyone, unless their role ability is disabled
    if not self:IsRoleAbilityDisabled() then
        SetTurncoatTeam(self, true)
    end

    -- Announce the role change
    local message = self:Nick() .. " is " .. ROLE_STRINGS_EXT[ROLE_TURNCOAT] .. " and has joined the " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR]
    if extra then
        message = message .. extra
    end
    message = message .. "!"
    for _, ply in PlayerIterator() do
        ply:QueueMessage(MSG_PRINTBOTH, message)
    end

    -- Change health
    local health = turncoat_change_health:GetInt()
    -- Don't heal the owner if they already have less health that the convar
    self:SetHealth(math.Min(self:Health(), health))
    if turncoat_change_max_health:GetBool() then
        self:SetMaxHealth(health)
    end
end

-- Reset the role back to the innocent team
AddHook("TTTPrepareRound", "Turncoat_PrepareRound", function()
    SetTurncoatTeam(nil, false)
end)

-- Change the turncoat's team automatically if they kill an innocent and that setting is enabled
local function Turncoat_DoPlayerDeath(ply, attacker, dmginfo)
    if not turncoat_change_innocent_kill:GetBool() then return end
    if not IsPlayer(attacker) then return end
    if not ply:IsInnocentTeam() then return end
    if not attacker:IsTurncoat() then return end
    if ply == attacker then return end
    if attacker:IsTraitorTeam() then return end

    attacker:ChangeTurncoatTeam(" by killing " .. ROLE_STRINGS_EXT[ROLE_INNOCENT])
    attacker:StripWeapon("weapon_tur_changer")
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_TURNCOAT] = function()
    AddHook("DoPlayerDeath", "Turncoat_DoPlayerDeath", Turncoat_DoPlayerDeath)
end

ROLE_UNREGISTER_HOOKS[ROLE_TURNCOAT] = function()
    RemoveHook("DoPlayerDeath", "Turncoat_DoPlayerDeath")
end