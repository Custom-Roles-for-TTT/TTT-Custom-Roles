---- Shared corpsey stuff

CreateConVar("ttt_spectator_corpse_search", "1", FCVAR_REPLICATED, "Whether spectators can search bodies (not shared with other players)", 0, 1)
CreateConVar("ttt_corpse_search_not_shared", "0", FCVAR_REPLICATED, "Whether corpse searches are not shared with other players (only affects non-detective-like searchers)", 0, 1)

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

    local ownerEnt = CORPSE.GetPlayer(rag)
    local detectiveSearchOnly = (GetConVar("ttt_detectives_search_only"):GetBool() or IsAllDetectiveOnly()) and
                            not (GetConVar("ttt_all_search_postround"):GetBool() and GetRoundState() ~= ROUND_ACTIVE) and
                            not (GetConVar("ttt_all_search_binoc"):GetBool() and ply:GetActiveWeapon() and WEPS.GetClass(ply:GetActiveWeapon()) == "weapon_ttt_binoculars")
    return ply:IsActiveDetectiveLike() or not detectiveSearchOnly or (IsValid(ownerEnt) and ownerEnt:GetNWBool("body_searched", false))
end