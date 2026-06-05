local ents = ents

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

ROLE_REGISTERED_HOOKS[ROLE_TRICKSTER] = {
    ["TTTCanUseTraitorButton"] = Trickster_Disabled_TTTCanUseTraitorButton
}