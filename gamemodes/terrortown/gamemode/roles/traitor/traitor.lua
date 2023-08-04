AddCSLuaFile()

local hook = hook

local GetAllPlayers = player.GetAll

-------------
-- CONVARS --
-------------

local traitor_credits_timer = CreateConVar("ttt_traitor_credits_timer", "0")

-----------------------
-- PLAYER VISIBILITY --
-----------------------

-- Add all traitors to the PVS for all players they can see via Target ID with NoZ (Traitors, Glitch)
hook.Add("SetupPlayerVisibility", "Traitors_SetupPlayerVisibility", function(ply)
    if not ply:ShouldBypassCulling() then return end
    if not ply:IsActiveTraitorTeam() then return end

    for _, v in ipairs(GetAllPlayers()) do
        if not v:IsActiveTraitorTeam() and not v:IsActiveGlitch() then continue end
        if ply:TestPVS(v) then continue end

        local pos = v:GetPos()
        if ply:IsOnScreen(pos) then
            AddOriginToPVS(pos)
        end
    end
end)

------------------
-- AUTO CREDITS --
------------------

hook.Add("TTTBeginRound", "Traitors_TTTBeginRound", function()
    local credit_timer = traitor_credits_timer:GetInt()
    if credit_timer <= 0 then return end

    timer.Create("TraitorCreditTimer", credit_timer, 0, function()
        for _, v in pairs(GetAllPlayers()) do
            if v:IsActiveTraitorTeam() then
                v:AddCredits(1)
                LANG.Msg(v, "credit_all", { role = ROLE_STRINGS[v:GetRole()], num = 1 })
            end
        end
    end)
end)

hook.Add("TTTEndRound", "Traitors_TTTEndRound", function()
    timer.Remove("TraitorCreditTimer")
end)