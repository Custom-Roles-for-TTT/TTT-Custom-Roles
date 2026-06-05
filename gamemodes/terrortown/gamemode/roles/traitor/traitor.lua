AddCSLuaFile()

local hook = hook
local player = player
local timer = timer

local AddHook = hook.Add
local PlayerIterator = player.Iterator

-------------
-- CONVARS --
-------------

local traitor_credits_timer = CreateConVar("ttt_traitors_credits_timer", "0")

-----------------------
-- PLAYER VISIBILITY --
-----------------------

-- Add all traitors to the PVS for all players they can see via Target ID with NoZ (Traitors, Glitch)
local function Traitors_SetupPlayerVisibility(ply)
    if not ply:ShouldBypassCulling() then return end
    if not ply:IsActiveTraitorTeam() then return end

    for _, v in PlayerIterator() do
        if not v:IsActiveTraitorTeam() and not v:IsActiveGlitch() then continue end
        if ply:TestPVS(v) then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end

------------------
-- AUTO CREDITS --
------------------

local function Traitors_TTTBeginRound()
    local credit_timer = traitor_credits_timer:GetInt()
    if credit_timer <= 0 then return end

    timer.Create("TraitorCreditTimer", credit_timer, 0, function()
        for _, v in PlayerIterator() do
            if v:IsActiveTraitorTeam() then
                v:AddCredits(1)
                LANG.Msg(v, "credit_all", { role = ROLE_STRINGS[v:GetRole()], num = 1 })
            end
        end
    end)
end

local function Traitors_TTTEndRound()
    timer.Remove("TraitorCreditTimer")
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_TRAITOR] = function()
    AddHook("SetupPlayerVisibility", "Traitors_SetupPlayerVisibility", Traitors_SetupPlayerVisibility)
    AddHook("TTTBeginRound", "Traitors_TTTBeginRound", Traitors_TTTBeginRound)
    AddHook("TTTEndRound", "Traitors_TTTEndRound", Traitors_TTTEndRound)
end

ROLE_UNREGISTER_HOOKS[ROLE_TRAITOR] = function()
    RemoveHook("SetupPlayerVisibility", "Traitors_SetupPlayerVisibility")
    RemoveHook("TTTBeginRound", "Traitors_TTTBeginRound")
    RemoveHook("TTTEndRound", "Traitors_TTTEndRound")
end