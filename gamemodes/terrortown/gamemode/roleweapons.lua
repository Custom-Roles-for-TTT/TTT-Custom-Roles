include("shared.lua")

local concommand = concommand
local net = net
local pairs = pairs
local table = table
local string = string

local StringStripExtension = string.StripExtension
local TableHasValue = table.HasValue
local TableInsert = table.insert

if SERVER then
    util.AddNetworkString("TTT_RoleWeaponsList")
    util.AddNetworkString("TTT_RoleWeaponsClean")
    util.AddNetworkString("TTT_RoleWeaponsReload")
end

local function FindAndRemoveInvalidWeapons(tbl, invalidWeapons, printRemoval)
    local cleanTbl = {}
    for _, weaponName in ipairs(tbl) do
        if weapons.GetStored(weaponName) == nil and GetEquipmentItemByName(weaponName) == nil then
            TableInsert(invalidWeapons, weaponName)
            if printRemoval then
                print("[ROLEWEAPONS] Removing entry representing invalid weapon/equipment: " .. weaponName)
            end
        else
            TableInsert(cleanTbl, weaponName)
        end
    end
    return cleanTbl
end

local function ShowList()
    local roleFiles, _ = file.Find("roleweapons/*.json", "DATA")
    local invalidRoles = {}
    for _, fileName in pairs(roleFiles) do
        local name = StringStripExtension(fileName)
        if not TableHasValue(ROLE_STRINGS_RAW, name) then
            TableInsert(invalidRoles, name)
            continue
        end

        local roleBuyables = {}
        local roleExcludes = {}
        local roleNoRandoms = {}
        local invalidWeapons = {}
        -- Load the lists from the JSON file for this role
        if file.Exists("roleweapons/" .. name .. ".json", "DATA") then
            local roleJson = file.Read("roleweapons/" .. name .. ".json", "DATA")
            if roleJson then
                local roleData = util.JSONToTable(roleJson)
                if roleData then
                    roleBuyables = roleData.Buyables or {}
                    roleExcludes = roleData.Excludes or {}
                    roleNoRandoms = roleData.NoRandoms or {}
                end
            end
        end

        roleBuyables = FindAndRemoveInvalidWeapons(roleBuyables, invalidWeapons)
        roleExcludes = FindAndRemoveInvalidWeapons(roleExcludes, invalidWeapons)
        roleNoRandoms = FindAndRemoveInvalidWeapons(roleNoRandoms, invalidWeapons)

        -- Print this role's information
        print("[ROLEWEAPONS] Configuration information for '" .. name .. "'")
        print("\tInclude:")
        for _, weaponName in ipairs(roleBuyables) do
            print("\t\t" .. weaponName)
        end

        print("\n\tExclude:")
        for _, weaponName in ipairs(roleExcludes) do
            print("\t\t" .. weaponName)
        end

        print("\n\tNo-Random:")
        for _, weaponName in ipairs(roleNoRandoms) do
            print("\t\t" .. weaponName)
        end

        print("\n\tInvalid Weapons (files that don't match any installed weapon or equipment):")
        for _, weaponName in ipairs(invalidWeapons) do
            print("\t\t" .. weaponName)
        end
    end

    if #invalidRoles > 0 then
        print("\n[ROLEWEAPONS] Found " .. #invalidRoles .. " role folders that don't match any known role:")
        for _, role in ipairs(invalidRoles) do
            print("\t" .. role)
        end
    end
end
net.Receive("TTT_RoleWeaponsList", ShowList)

local function Clean()
    local roleFiles, _ = file.Find("roleweapons/*.json", "DATA")
    for _, fileName in pairs(roleFiles) do
        local name = StringStripExtension(fileName)
        if not TableHasValue(ROLE_STRINGS_RAW, name) then
            print("[ROLEWEAPONS] Removing file representing invalid role: " .. fileName)
            file.Delete("roleweapons/" .. fileName, "DATA")
            continue
        end

        -- Load the lists from the JSON file for this role
        if file.Exists("roleweapons/" .. name .. ".json", "DATA") then
            local roleJson = file.Read("roleweapons/" .. name .. ".json", "DATA")
            local valid = true
            if roleJson then
                local roleData = util.JSONToTable(roleJson)
                if roleData then
                    roleData.Buyables = FindAndRemoveInvalidWeapons(roleData.Buyables or {}, {}, true)
                    roleData.Excludes = FindAndRemoveInvalidWeapons(roleData.Excludes or {}, {}, true)
                    roleData.NoRandoms = FindAndRemoveInvalidWeapons(roleData.NoRandoms or {}, {}, true)

                    -- Update the file with the cleaned tables
                    if #roleData.Buyables > 0 or #roleData.Excludes > 0 or #roleData.NoRandoms > 0 then
                        roleJson = util.TableToJSON(roleData)
                        file.Write("roleweapons/" .. name .. ".json", roleJson)
                    else
                        valid = false
                    end
                else
                    valid = false
                end
            else
                valid = false
            end

            if not valid then
                print("[ROLEWEAPONS] Removing empty file: " .. fileName)
                file.Delete("roleweapons/" .. fileName, "DATA")
            end
        end
    end
end
net.Receive("TTT_RoleWeaponsClean", Clean)

local function Reload()
    print("[ROLEWEAPONS] Reloading configuration...")

    -- Clear the weapon lists on all clients
    net.Start("TTT_ClearRoleWeapons")
    net.Broadcast()

    -- Use the common logic to clear the weapon lists and load it all again on the server
    WEPS.ClearWeaponsLists()
    WEPS.HandleRoleEquipment()
end
if SERVER then net.Receive("TTT_RoleWeaponsReload", Reload) end

local function PrintHelp()
    print("ttt_roleweapons [OPTION]")
    print("If no options provided, default of 'open' will be used")
    print("\tclean\t-\tRemoves any invalid configurations. WARNING: This CANNOT be undone!")
    print("\thelp\t-\tPrints this message")
    print("\topen\t-\tOpen the configuration dialog [CLIENT ONLY]")
    print("\tshow\t")
    print("\tlist\t-\tPrints the current configuration in the server console, highlighting anything invalid")
    print("\tprint\t")
    print("\treload\t-\tReloads the configurations from the server's filesystem")
end

concommand.Add("sv_ttt_roleweapons", function(ply, cmd, args)
    local method = #args > 0 and args[1] or "help"
    if method == "open" or method == "show" then
        ErrorNoHalt("ERROR: Command must be run inside client console\n")
    elseif method == "print" or method == "list" then
        ShowList()
    elseif method == "clean" then
        Clean()
    elseif method == "reload" then
        Reload()
    elseif method == "help" then
        PrintHelp()
    else
        ErrorNoHalt("ERROR: Unknown command '" .. method .. "'\n")
    end
end)