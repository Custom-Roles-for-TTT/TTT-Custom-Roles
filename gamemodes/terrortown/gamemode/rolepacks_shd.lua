local table = table

ROLEPACKS = ROLEPACKS or {}

function ROLEPACKS.GetCurrentRolePackName()
    if ROLE_PACK_DETAILS and not table.IsEmpty(ROLE_PACK_DETAILS) then
        return ROLE_PACK_DETAILS.name or ""
    end
    return ""
end