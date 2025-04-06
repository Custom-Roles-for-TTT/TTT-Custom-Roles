---- Shared corpsey stuff

CreateConVar("ttt_spectator_corpse_search", "1", FCVAR_REPLICATED, "Whether spectators can search bodies (not shared with other players)", 0, 1)
CreateConVar("ttt_corpse_search_team_text_traitor", "0", FCVAR_REPLICATED, "Whether corpse searches of traitors should include flavor text hinting at the team of their killer", 0, 1)
CreateConVar("ttt_corpse_search_team_text_innocent", "0", FCVAR_REPLICATED, "Whether corpse searches of innocents should include flavor text hinting at the team of their killer", 0, 1)
CreateConVar("ttt_corpse_search_team_text_monster", "0", FCVAR_REPLICATED, "Whether corpse searches of monsters should include flavor text hinting at the team of their killer", 0, 1)
CreateConVar("ttt_corpse_search_team_text_independent", "0", FCVAR_REPLICATED, "Whether corpse searches of independents should include flavor text hinting at the team of their killer", 0, 1)
CreateConVar("ttt_corpse_search_team_text_jester", "0", FCVAR_REPLICATED, "Whether corpse searches of jesters should include flavor text hinting at the team of their killer", 0, 1)
CreateConVar("ttt_corpse_search_killer_team_text_traitor", "0", FCVAR_REPLICATED, "Whether corpse searches should include flavor text hinting at the team of their traitor team killer", 0, 1)
CreateConVar("ttt_corpse_search_killer_team_text_innocent", "0", FCVAR_REPLICATED, "Whether corpse searches should include flavor text hinting at the team of their innocent team killer", 0, 1)
CreateConVar("ttt_corpse_search_killer_team_text_monster", "0", FCVAR_REPLICATED, "Whether corpse searches should include flavor text hinting at the team of their monster team killer", 0, 1)
CreateConVar("ttt_corpse_search_killer_team_text_independent", "0", FCVAR_REPLICATED, "Whether corpse searches should include flavor text hinting at the team of their independent killer", 0, 1)
CreateConVar("ttt_corpse_search_killer_team_text_jester", "0", FCVAR_REPLICATED, "Whether corpse searches should include flavor text hinting at the team of their jester team killer", 0, 1)
CreateConVar("ttt_corpse_search_killer_team_text_plain", "0", FCVAR_REPLICATED, "Whether corpse searches should include plain text showing the team of their killer. Only used alongside the \"ttt_corpse_search_killer_team_text_*\" convars", 0, 1)

CORPSE = CORPSE or {}

-- Manual datatable indexing
CORPSE.dti = {
   BOOL_FOUND = 0,

   ENT_PLAYER = 0,

   INT_CREDITS = 0
};

local dti = CORPSE.dti
--- networked data abstraction
function CORPSE.GetFound(rag, default)
    return rag and rag:GetDTBool(dti.BOOL_FOUND) or default
end

function CORPSE.GetPlayerNick(rag, default)
    if not IsValid(rag) then return default end

    local ply = rag:GetDTEntity(dti.ENT_PLAYER)
    if IsValid(ply) then
        return ply:Nick()
    else
        return rag:GetNWString("nick", default)
    end
end

function CORPSE.GetCredits(rag, default)
    if not IsValid(rag) then return default end
    return rag:GetDTInt(dti.INT_CREDITS)
end

function CORPSE.GetPlayer(rag)
    if not IsValid(rag) then return NULL end
    return rag:GetDTEntity(dti.ENT_PLAYER)
end

local function IsAllDetectiveOnly()
    for _, dataType in ipairs(CORPSE_ICON_TYPES) do
        if not GetConVar("ttt_detectives_search_only_" .. dataType):GetBool() then
            return false
        end
    end
    return true
end

function CORPSE.CanBeSearched(ply, rag)
    if not IsPlayer(ply) then return false end

    local weap_class = WEPS.GetClass(ply.GetActiveWeapon and ply:GetActiveWeapon())
    local ownerEnt = CORPSE.GetPlayer(rag)
    local detectiveSearchOnly = (GetConVar("ttt_detectives_search_only"):GetBool() or IsAllDetectiveOnly()) and
                            not (GetConVar("ttt_all_search_postround"):GetBool() and GetRoundState() ~= ROUND_ACTIVE) and
                            not (GetConVar("ttt_all_search_binoc"):GetBool() and weap_class == "weapon_ttt_binoculars") and
                            not (GetConVar("ttt_all_search_dnascanner"):GetBool() and weap_class == "weapon_ttt_wtester")
    return ply:IsActiveDetectiveLike() or not detectiveSearchOnly or (IsValid(ownerEnt) and ownerEnt:GetNWBool("body_searched", false))
end