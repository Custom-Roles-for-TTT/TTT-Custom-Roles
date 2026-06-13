AddCSLuaFile()

local hook = hook
local player = player

local AddHook = hook.Add
local PlayerIterator = player.Iterator

-------------------
-- ROLE FEATURES --
-------------------

ROLE_ON_ROLE_ASSIGNED[ROLE_GLITCH] = function(ply)
    SetGlobalBool("ttt_glitch_round", true)
end

AddHook("Initialize", "Glitch_RoleFeatures_Initialize", function()
    SetGlobalBool("ttt_glitch_round", false)
end)

AddHook("TTTPrepareRound", "Glitch_RoleFeatures_PrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWInt("GlitchBluff", ROLE_TRAITOR)
    end
end)

AddHook("TTTBeginRound", "Glitch_RoleFeatures_TTTBeginRound", function()
    local alive = player.IsRoleLiving(ROLE_GLITCH)
    SetGlobalBool("ttt_glitch_round", alive)
end)

AddHook("TTTEndRound", "Glitch_RoleFeatures_TTTEndRound", function()
    SetGlobalBool("ttt_glitch_round", false)
end)