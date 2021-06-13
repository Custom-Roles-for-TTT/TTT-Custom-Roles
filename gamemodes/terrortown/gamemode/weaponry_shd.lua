WEPS = {}

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
end

function WEPS.ResetWeaponsCache()
    -- Reset the CanBuy list or save the original for next time
    for _, v in pairs(weapons.GetList()) do
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

function WEPS.ResetRoleWeaponCache()
    for id, _ in pairs(ROLE_STRINGS) do
        DoesRoleHaveWeaponCache[id] = nil
    end
end

-- Useful for allowing roles to have a shop only if weapons are assigned to them
function WEPS.DoesRoleHaveWeapon(role)
    if type(DoesRoleHaveWeaponCache[role]) ~= "boolean" then
        DoesRoleHaveWeaponCache[role] = nil
    end

    if DoesRoleHaveWeaponCache[role] ~= nil then
        return DoesRoleHaveWeaponCache[role]
    end
    if WEPS.BuyableWeapons[role] ~= nil and table.Count(WEPS.BuyableWeapons[role]) > 0 then
        DoesRoleHaveWeaponCache[role] = true
        return true
    end

    for _, w in ipairs(weapons.GetList()) do
        if w and w.CanBuy and table.HasValue(w.CanBuy, role) then
            DoesRoleHaveWeaponCache[role] = true
            return true
        end
    end

    DoesRoleHaveWeaponCache[role] = false
    return false
end

MERC_SHOP_NONE = 0
MERC_SHOP_UNION = 1
MERC_SHOP_INTERSECT = 2
MERC_SHOP_DETECTIVE = 3
MERC_SHOP_TRAITOR = 4

local mercmode = nil
function WEPS.HandleCanBuyOverrides(wep, role, block_randomization, sync_traitor_weapons, sync_detective_weapons)
    if wep == nil then return end
    local id = WEPS.GetClass(wep)

    -- Cache this the first time
    if mercmode == nil then
        mercmode = GetGlobalInt("ttt_shop_mer_mode")
    end

    -- Handle the other overrides
    if wep.CanBuy then
        local roletable = WEPS.BuyableWeapons[role] or {}
        -- Make sure each of the buyable weapons is in the role's equipment list
        if not table.HasValue(wep.CanBuy, role) and table.HasValue(roletable, id) then
            table.insert(wep.CanBuy, role)
        end

        -- Handle Mercenary specifically
        if role == ROLE_MERCENARY then
            -- Traitor OR Detective or Detective only modes
            if mercmode == MERC_SHOP_UNION or mercmode == MERC_SHOP_DETECTIVE then
                -- and they can't already buy this weapon
                if not table.HasValue(wep.CanBuy, role) and
                    -- and detectives CAN buy this weapon, let the mercenary buy it too
                    table.HasValue(wep.CanBuy, ROLE_DETECTIVE) then
                    table.insert(wep.CanBuy, role)
                end
            end

            -- Traitor OR Detective or Traitor only modes
            if mercmode == MERC_SHOP_UNION or mercmode == MERC_SHOP_TRAITOR then
                -- and they can't already buy this weapon
                if not table.HasValue(wep.CanBuy, role) and
                    -- and traitors CAN buy this weapon, let the mercenary buy it too
                    table.HasValue(wep.CanBuy, ROLE_TRAITOR) then
                    table.insert(wep.CanBuy, role)
                end
            end

            -- Traitor AND Detective
            if mercmode == MERC_SHOP_INTERSECT then
                -- and they can't already buy this weapon
                if not table.HasValue(wep.CanBuy, role) and
                    -- and detectives AND traitors CAN buy this weapon, let the mercenary buy it too
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
        end

        -- If the player can still buy this weapon, check the various excludes
        if table.HasValue(wep.CanBuy, role) then
            -- Make sure each of the excluded weapons is NOT in the role's equipment list
            local excludetable = WEPS.ExcludeWeapons[role]
            if excludetable and table.HasValue(excludetable, id) then
                table.RemoveByValue(wep.CanBuy, role)
            -- Remove some weapons based on a random chance if it isn't blocked or bypassed
            -- Only run this on the client because there is no easy way to sync randomization between client and server
            elseif CLIENT then
                local norandomtable = WEPS.BypassRandomWeapons[role]
                if not block_randomization and (not norandomtable or not table.HasValue(norandomtable, id)) then
                    local random_cvar_enabled = GetGlobalBool("ttt_shop_random_" .. ROLE_STRINGS_SHORT[role] .. "_enabled", false)
                    if random_cvar_enabled then
                        local random_cvar_percent_global = GetGlobalInt("ttt_shop_random_percent", 0)
                        local random_cvar_percent = GetGlobalInt("ttt_shop_random_" .. ROLE_STRINGS_SHORT[role] .. "_percent", 0)
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
end