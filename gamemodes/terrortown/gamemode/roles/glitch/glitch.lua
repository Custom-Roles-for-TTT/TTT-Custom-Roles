AddCSLuaFile()

local hook = hook
local pairs = pairs
local player = player

local GetAllPlayers = player.GetAll

-------------------
-- ROLE FEATURES --
-------------------

ROLE_ON_ROLE_ASSIGNED[ROLE_GLITCH] = function(ply)
    SetGlobalBool("ttt_glitch_round", true)
end

hook.Add("Initialize", "Glitch_RoleFeatures_Initialize", function()
    SetGlobalBool("ttt_glitch_round", false)
end)

hook.Add("TTTPrepareRound", "Glitch_RoleFeatures_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWInt("GlitchBluff", ROLE_TRAITOR)
    end
end)

hook.Add("TTTBeginRound", "Glitch_RoleFeatures_TTTBeginRound", function()
    local alive = player.IsRoleLiving(ROLE_GLITCH)
    SetGlobalBool("ttt_glitch_round", alive)
end)

hook.Add("TTTEndRound", "Glitch_RoleFeatures_TTTEndRound", function()
    SetGlobalBool("ttt_glitch_round", false)
end)