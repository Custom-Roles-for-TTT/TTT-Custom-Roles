AddCSLuaFile()

local hook = hook
local player = player
local table = table
local timer = timer

local AddHook = hook.Add
local PlayerIterator = player.Iterator
local SetMDL = FindMetaTable("Entity").SetModel

-------------
-- CONVARS --
-------------

local spy_steal_model_hands = CreateConVar("ttt_spy_steal_model_hands", "1", FCVAR_NONE, "Whether the spy should change to the victim's playermodel's 1st-person hands", 0, 1)
local spy_steal_model_alert = CreateConVar("ttt_spy_steal_model_alert", "1", FCVAR_NONE, "Whether the spy should see an alert message displaying who they are disguised as", 0, 1)
local spy_steal_from_respawning = CreateConVar("ttt_spy_steal_from_respawning", "1", FCVAR_NONE, "Whether the spy should steal the identity of their victim even if that player is respawning", 0, 1)

local spy_steal_mode = GetConVar("ttt_spy_steal_mode")
local spy_steal_model = GetConVar("ttt_spy_steal_model")
local spy_steal_name = GetConVar("ttt_spy_steal_name")

------------------
-- ROLE WEAPONS --
------------------

-- Only allow the spy to pick up spy-specific weapons
local function Spy_Weapons_PlayerCanPickupWeapon(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return end
    if wep:GetClass() == "weapon_spy_flaregun" then return ply:IsSpy() end
end

----------------
-- ROLE STATE --
----------------

local playerModels = {}

local function HandleStealIdentity(spy, target, mode)
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if not IsPlayer(spy) or not IsPlayer(target) then return end
    if spy == target then return end

    if spy_steal_mode:GetInt() ~= mode then return end
    -- Don't steal the identity of players who are respawning if we're told not to do that
    if not spy_steal_from_respawning:GetBool() and target:IsRespawning() then return end

    if not spy:IsSpy() or spy:IsRoleAbilityDisabled() then return end

    -- Stealing model
    local stealModel = spy_steal_model:GetBool()
    if stealModel then
        local spySid64 = spy:SteamID64()

        -- If the spy hasn't swapped models yet, we need to store their original model
        if not playerModels[spySid64] then
            playerModels[spySid64] = {
                model = spy:GetModel(),
                skin = spy:GetSkin(),
                bodygroups = {},
                color = spy:GetColor()
            }

            for _, value in pairs(spy:GetBodyGroups()) do
                playerModels[spySid64].bodygroups[value.id] = spy:GetBodygroup(value.id)
            end
        end

        SetMDL(spy, target:GetModel())
        spy:SetSkin(target:GetSkin())
        spy:SetColor(target:GetColor())
        for _, value in pairs(target:GetBodyGroups()) do
            spy:SetBodygroup(value.id, target:GetBodygroup(value.id))
        end

        -- Stealing 1st-person hands (There is no point in doing this if stealing model is not enabled)
        local stealHands = spy_steal_model_hands:GetBool()
        if stealHands then
            timer.Simple(0.1, function()
                if IsValid(spy) then
                    spy:SetupHands()
                end
            end)
        end
    end

    -- Stealing Name
    local stealName = spy_steal_name:GetBool()
    if stealName then
        spy:SetNWString("TTTSpyDisguiseName", target:GetName())
    end

    -- Displaying alert message on who the spy is now disguised as
    if spy_steal_model_alert:GetBool() and (stealModel or stealName) then
        spy:QueueMessage(MSG_PRINTBOTH, "Disguised as " .. target:Nick())
    end
end

-- The spy can steal the identity of the victim on killing a player
local function Spy_PlayerDeath(victim, inflictor, attacker)
    HandleStealIdentity(attacker, victim, SPY_STEAL_MODE_KILL)
end

local function Spy_TTTBodyFound(ply, deadply, rag)
    HandleStealIdentity(ply, deadply, SPY_STEAL_MODE_SEARCH)
end

local function ClearFullState()
    for _, ply in PlayerIterator() do
        local sid64 = ply:SteamID64()
        local playerModel = playerModels[sid64]
        if playerModel then
            SetMDL(ply, playerModel.model)
            ply:SetSkin(playerModel.skin)
            ply:SetColor(playerModel.color)
            for id, value in pairs(playerModel.bodygroups) do
                ply:SetBodygroup(id, value)
            end

            timer.Simple(0.1, function()
                ply:SetupHands()
            end)
        end

        ply:SetNWString("TTTSpyDisguiseName", "")
    end

    table.Empty(playerModels)
end

AddHook("TTTPrepareRound", "Spy_TTTPrepareRound", ClearFullState)

------------------
-- REGISTRATION --
------------------

ROLE_REGISTERED_HOOKS[ROLE_SPY] = {
    ["PlayerCanPickupWeapon"] = Spy_Weapons_PlayerCanPickupWeapon,
    ["PlayerDeath"] = Spy_PlayerDeath,
    ["TTTBodyFound"] = Spy_TTTBodyFound,
    ["TTTEndRound"] = ClearFullState
}