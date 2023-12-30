WEPS = {}

local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local math = math
local pairs = pairs
local table = table
local util = util

local CallHook = hook.Call
local GetWeapons = weapons.GetList

function WEPS.TypeForWeapon(class)
    local tbl = util.WeaponForClass(class)
    return tbl and tbl.Kind or WEAPON_NONE
end

-- You'd expect this to go on the weapon entity, but we need to be able to call
-- it on a swep table as well.
function WEPS.IsEquipment(wep)
    return wep.Kind and wep.Kind >= WEAPON_EQUIP
end

function WEPS.GetClass(wep)
    if istable(wep) then
        return wep.ClassName or wep.Classname
    elseif IsValid(wep) then
        return wep:GetClass()
    end
end

function WEPS.DisguiseToggle(ply)
    if IsValid(ply) and ply:HasEquipmentItem(EQUIP_DISGUISE) then
        if not ply:GetNWBool("disguised", false) then
            RunConsoleCommand("ttt_set_disguise", "1")
        else
            RunConsoleCommand("ttt_set_disguise", "0")
        end
    end
end

WEPS.BuyableWeapons = { }
WEPS.ExcludeWeapons = { }
WEPS.BypassRandomWeapons = { }

function WEPS.ClearWeaponsLists()
    table.Empty(WEPS.BuyableWeapons)
    table.Empty(WEPS.ExcludeWeapons)
    table.Empty(WEPS.BypassRandomWeapons)
end
if CLIENT then net.Receive("TTT_ClearRoleWeapons", WEPS.ClearWeaponsLists) end

function WEPS.PrepWeaponsLists(role)
    -- Initialize the lists for this role
    if not WEPS.BuyableWeapons[role] then
        WEPS.BuyableWeapons[role] = {}
    end
    if not WEPS.ExcludeWeapons[role] then
        WEPS.ExcludeWeapons[role] = {}
    end
    if not WEPS.BypassRandomWeapons[role] then
        WEPS.BypassRandomWeapons[role] = {}
    end
    if not EquipmentItems[role] then
        EquipmentItems[role] = {}
    end
end

function WEPS.UpdateWeaponLists(role, weapon, includeSelected, excludeSelected, noRandomSelected)
    WEPS.PrepWeaponsLists(role)
    if includeSelected then
        if not table.HasValue(WEPS.BuyableWeapons[role], weapon) then
            table.insert(WEPS.BuyableWeapons[role], weapon)
        end
    else
        table.RemoveByValue(WEPS.BuyableWeapons[role], weapon)
    end
    if excludeSelected then
        if not table.HasValue(WEPS.ExcludeWeapons[role], weapon) then
            table.insert(WEPS.ExcludeWeapons[role], weapon)
        end
    else
        table.RemoveByValue(WEPS.ExcludeWeapons[role], weapon)
    end
    if noRandomSelected then
        if not table.HasValue(WEPS.BypassRandomWeapons[role], weapon) then
            table.insert(WEPS.BypassRandomWeapons[role], weapon)
        end
    else
        table.RemoveByValue(WEPS.BypassRandomWeapons[role], weapon)
    end
    CallHook("TTTRoleWeaponUpdated", nil, role, weapon, includeSelected, excludeSelected, noRandomSelected)
end

function WEPS.ResetWeaponsCache()
    -- Reset the CanBuy list or save the original for next time
    for _, v in pairs(GetWeapons()) do
        if v and v.CanBuy then
            if v.CanBuyOrig then
                v.CanBuy = table.Copy(v.CanBuyOrig)
            else
                v.CanBuyOrig = table.Copy(v.CanBuy)
            end
        end
    end
    WEPS.ResetRoleWeaponCache()
end

local DoesRoleHaveWeaponCache = { }
local RoleModes = { }

local function GetRoleMode(role)
    -- Cache these the first time
    if not RoleModes[role] then
        RoleModes[role] = cvars.Number("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_mode", SHOP_SYNC_MODE_NONE)
    end
    return RoleModes[role]
end

function WEPS.ResetRoleWeaponCache()
    for id, _ in pairs(ROLE_STRINGS_RAW) do
        DoesRoleHaveWeaponCache[id] = nil
    end
end

local function PlayerOwnsWepOrItem(ply, classOrId)
    if isstring(classOrId) then
        for _, wep in ipairs(ply:GetWeapons()) do
            if wep:GetClass() == classOrId then
                return true
            end
        end

        return false
    end

    return ply:HasEquipmentItem(classOrId)
end

-- ply should be a valid player ent, wep should be either a valid ent class name or valid item ID
function WEPS.PlayerOwnsWepReqs(ply, wep)
    local tab

    if isnumber(wep) then
        tab = GetEquipmentItem(ply:GetRole(), wep)
    elseif istable(wep) then
        tab = wep
    else
        tab = weapons.GetStored(wep)
    end

    if tab and tab.req then
        local requisiteItems = tab.req

        if istable(requisiteItems) then
            for _, classOrId in ipairs(requisiteItems) do
                if not PlayerOwnsWepOrItem(ply, classOrId) then
                    return false
                end
            end

            return true
        end

        return PlayerOwnsWepOrItem(ply, requisiteItems)
    end

    -- If no requisite items provided, return true
    return true
end

-- Useful for allowing roles to have a shop only if weapons are assigned to them
function WEPS.DoesRoleHaveWeapon(role, promoted)
    WEPS.PrepWeaponsLists(role)
    if type(DoesRoleHaveWeaponCache[role]) ~= "boolean" then
        DoesRoleHaveWeaponCache[role] = nil
    end

    if DoesRoleHaveWeaponCache[role] ~= nil then
        return DoesRoleHaveWeaponCache[role]
    end

    local excludes = WEPS.ExcludeWeapons[role]
    for _, w in ipairs(GetWeapons()) do
        -- If there is a weapon that this role can buy that isn't excluded then we can stop looking
        if w and w.CanBuy and table.HasValue(w.CanBuy, role) and not table.HasValue(excludes, WEPS.GetClass(w)) then
            DoesRoleHaveWeaponCache[role] = true
            return true
        end
    end

    -- If there are any additional weapons for the role then we can stop looking
    if WEPS.BuyableWeapons[role] ~= nil and table.Count(WEPS.BuyableWeapons[role]) > 0 then
        DoesRoleHaveWeaponCache[role] = true
        return true
    end

    -- Detective-like roles get detective weapons so if detectives have weapons then so do they
    if promoted and WEPS.DoesRoleHaveWeapon(ROLE_DETECTIVE, false) then
        DoesRoleHaveWeaponCache[role] = true
        return true
    end

    -- Equipment counts as well
    if EquipmentItems[role] then
        for _, e in ipairs(EquipmentItems[role]) do
            if not table.HasValue(excludes, e.name) then
                DoesRoleHaveWeaponCache[role] = true
                return true
            end
        end
    end

    local rolemode = GetRoleMode(role)
    -- If this role is set to sync with traitor or detective then they have weapons as traitor and detective always have weapons
    if rolemode > SHOP_SYNC_MODE_NONE then
        DoesRoleHaveWeaponCache[role] = true
        return true
    end

    -- If this role doesn't have its own weapons, check if any of the roles it syncs with do
    local syncroles = ROLE_SHOP_SYNC_ROLES[role]
    if syncroles and table.Count(syncroles) > 0 then
        for _, r in pairs(syncroles) do
            if WEPS.DoesRoleHaveWeapon(r, false) then
                DoesRoleHaveWeaponCache[role] = true
                return true
            end
        end
    end

    DoesRoleHaveWeaponCache[role] = false
    return false
end

SHOP_SYNC_MODE_NONE = 0
SHOP_SYNC_MODE_UNION = 1
SHOP_SYNC_MODE_INTERSECT = 2
SHOP_SYNC_MODE_DETECTIVE = 3
SHOP_SYNC_MODE_TRAITOR = 4

function WEPS.HandleCanBuyOverrides(wep, role, block_randomization, sync_traitor_weapons, sync_detective_weapons, block_exclusion, sync_roles)
    if wep == nil then return end
    if not wep.CanBuy then return end

    local id = WEPS.GetClass(wep)
    local rolemode = GetRoleMode(role)

    -- If the last key in the table does not match how many keys there are, this is a non-sequential table
    -- table.RemoveByValue does not work with non-sequential tables and there is not an easy way
    -- of removing items from a non-sequential table by key or value
    if #wep.CanBuy ~= table.Count(wep.CanBuy) then
        wep.CanBuy = table.ClearKeys(wep.CanBuy)
    end

    local roletable = WEPS.BuyableWeapons[role] or {}
    -- Make sure each of the buyable weapons is in the role's equipment list
    if not table.HasValue(wep.CanBuy, role) and table.HasValue(roletable, id) then
        table.insert(wep.CanBuy, role)
    end

    -- Handle roles with shop syncing specifically
    if rolemode > SHOP_SYNC_MODE_NONE then
        -- Traitor OR Detective or Detective only modes
        if rolemode == SHOP_SYNC_MODE_UNION or rolemode == SHOP_SYNC_MODE_DETECTIVE then
            -- and they can't already buy this weapon
            if not table.HasValue(wep.CanBuy, role) and
                -- and detectives CAN buy this weapon, let the role buy it too
                table.HasValue(wep.CanBuy, ROLE_DETECTIVE) then
                table.insert(wep.CanBuy, role)
            end
        end

        -- Traitor OR Detective or Traitor only modes
        if rolemode == SHOP_SYNC_MODE_UNION or rolemode == SHOP_SYNC_MODE_TRAITOR then
            -- and they can't already buy this weapon
            if not table.HasValue(wep.CanBuy, role) and
                -- and traitors CAN buy this weapon, let the role buy it too
                table.HasValue(wep.CanBuy, ROLE_TRAITOR) then
                table.insert(wep.CanBuy, role)
            end
        end

        -- Traitor AND Detective
        if rolemode == SHOP_SYNC_MODE_INTERSECT then
            -- and they can't already buy this weapon
            if not table.HasValue(wep.CanBuy, role) and
                -- and detectives AND traitors CAN buy this weapon, let the role buy it too
                table.HasValue(wep.CanBuy, ROLE_DETECTIVE) and table.HasValue(wep.CanBuy, ROLE_TRAITOR) then
                table.insert(wep.CanBuy, role)
            end
        end
    else
        -- If the player is a role that should have all weapons that vanilla traitors have
        if sync_traitor_weapons and
                -- and they can't already buy this weapon
                not table.HasValue(wep.CanBuy, role) and
                -- and vanilla traitors CAN buy this weapon, let this player buy it too
                table.HasValue(wep.CanBuy, ROLE_TRAITOR) then
            table.insert(wep.CanBuy, role)
        end

        -- If the player is a role that should have all weapons that vanilla detectives have
        if sync_detective_weapons and
                -- and they can't already buy this weapon
                not table.HasValue(wep.CanBuy, role) and
                -- and vanilla detectives CAN buy this weapon, let this player buy it too
                table.HasValue(wep.CanBuy, ROLE_DETECTIVE) then
            table.insert(wep.CanBuy, role)
        end

        -- If this player's role has a list of other roles they should sync from
        if sync_roles and #sync_roles > 0 and
                -- and they can't already buy this weapon
                not table.HasValue(wep.CanBuy, role) then
            -- Check whether any of the sync roles can can it
            for _, r in pairs(sync_roles) do
                if table.HasValue(wep.CanBuy, r) then
                    table.insert(wep.CanBuy, role)
                    break
                end
            end
        end
    end

    -- If the player can still buy this weapon, check the various excludes
    if table.HasValue(wep.CanBuy, role) then
        -- Make sure each of the excluded weapons is NOT in the role's equipment list
        local excludetable = WEPS.ExcludeWeapons[role]
        if not block_exclusion and excludetable and table.HasValue(excludetable, id) then
            table.RemoveByValue(wep.CanBuy, role)
        -- Remove some weapons based on a random chance if it isn't blocked or bypassed
        -- Only run this on the client because there is no easy way to sync randomization between client and server
        elseif CLIENT and not wep.BlockShopRandomization then
            local norandomtable = WEPS.BypassRandomWeapons[role]
            if not block_randomization and (not norandomtable or not table.HasValue(norandomtable, id)) then
                local random_cvar_enabled = cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_random_enabled", false)
                if random_cvar_enabled then
                    local random_cvar_percent_global = GetConVar("ttt_shop_random_percent"):GetInt()
                    local random_cvar_percent = GetConVar("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_random_percent"):GetInt()
                    -- Use the global value if the per-role override isn't set
                    if random_cvar_percent == 0 then
                        random_cvar_percent = random_cvar_percent_global
                    end

                    if math.random() < (random_cvar_percent / 100.0) then
                        table.RemoveByValue(wep.CanBuy, role)
                    end
                end
            end
        end
    end
end