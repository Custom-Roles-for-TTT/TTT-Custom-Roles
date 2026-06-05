local ents = ents
local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove
local FindEntsByClass = ents.FindByClass

ROLE_SELECTION_PREDICATE[ROLE_TRICKSTER] = function() return #FindEntsByClass("ttt_traitor_button") > 0 end

local function Trickster_Disabled_TTTCanUseTraitorButton(ent, ply)
    if ply:IsActiveTrickster() and ply:IsRoleAbilityDisabled() then
        return false
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_TRICKSTER] = function()
    AddHook("TTTCanUseTraitorButton", "Trickster_Disabled_TTTCanUseTraitorButton", Trickster_Disabled_TTTCanUseTraitorButton)
end

ROLE_UNREGISTER_HOOKS[ROLE_TRICKSTER] = function()
    RemoveHook("TTTCanUseTraitorButton", "Trickster_Disabled_TTTCanUseTraitorButton")
end