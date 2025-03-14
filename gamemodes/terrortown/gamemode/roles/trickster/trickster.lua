local FindEntsByClass = ents.FindByClass

ROLE_SELECTION_PREDICATE[ROLE_TRICKSTER] = function() return #FindEntsByClass("ttt_traitor_button") > 0 end

hook.Add("TTTCanUseTraitorButton", "TTT_DisableTricksterUsingButtons", function(ply)
    if ply:IsActiveTrickster() and ply:IsRoleAbilityDisabled() then
        return false
    end
end)