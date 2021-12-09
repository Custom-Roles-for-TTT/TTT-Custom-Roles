local FindEntsByClass = ents.FindByClass

ROLE_SELECTION_PREDICATE[ROLE_TRICKSTER] = function() return #FindEntsByClass("ttt_traitor_button") > 0 end