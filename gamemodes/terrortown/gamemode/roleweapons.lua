include("shared.lua")

local concommand = concommand
local net = net
local pairs = pairs
local table = table
local string = string

local StringLower = string.lower
local StringSub = string.sub

if SERVER then
    util.AddNetworkString("TTT_RoleWeaponsList")
    util.AddNetworkString("TTT_RoleWeaponsClean")
    util.AddNetworkString("TTT_RoleWeaponsReload")
end

local function ShowList()
    local _, roledirs = file.Find("roleweapons/*", "DATA")
    local invalidroles = {}
    for _, name in pairs(roledirs) do
        if not table.HasValue(ROLE_STRINGS_RAW, name) then
            table.insert(invalidroles, name)
            continue
        end

        local rolefiles, _ = file.Find("roleweapons/" .. name .. "/*.txt", "DATA")
        local roleexcludes = {}
        local roleenorandoms = {}
        local roleweapons = {}
        local invalidweapons = {}
        for _, v in pairs(rolefiles) do
            -- Extract the weapon name from the file name
            local lastdotpos = v:find("%.")
            local weaponname = StringSub(v, 0, lastdotpos - 1)
            if weapons.GetStored(weaponname) == nil and GetEquipmentItemByName(weaponname) == nil then
                table.insert(invalidweapons, v)
                continue
            end

            -- Check that there isn't a two-part extension (e.g. "something.exclude.txt")
            local extension = StringSub(v, lastdotpos + 1, #v)
            lastdotpos = extension:find("%.")

            -- If there is, check if it equals one of our expected types
            if lastdotpos ~= nil then
                extension = StringLower(StringSub(extension, 0, lastdotpos - 1))
                if extension == "exclude" then
                    table.insert(roleexcludes, weaponname)
                elseif extension == "norandom" then
                    table.insert(roleenorandoms, weaponname)
                end
            else
                table.insert(roleweapons, weaponname)
            end
        end

        -- Print this role's information
        print("[ROLEWEAPONS] Configuration information for '" .. name .. "'")
        print("\tInclude:")
        for _, weaponname in ipairs(roleweapons) do
            print("\t\t" .. weaponname)
        end

        print("\n\tExclude:")
        for _, weaponname in ipairs(roleexcludes) do
            print("\t\t" .. weaponname)
        end

        print("\n\tNo-Random:")
        for _, weaponname in ipairs(roleenorandoms) do
            print("\t\t" .. weaponname)
        end

        print("\n\tInvalid Weapons (files that don't match any installed weapon or equipment):")
        for _, weaponname in ipairs(invalidweapons) do
            print("\t\t" .. weaponname)
        end
    end

    if #invalidroles > 0 then
        print("\n[ROLEWEAPONS] Found " .. #invalidroles .. " role folders that don't match any known role:")
        for _, role in ipairs(invalidroles) do
            print("\t" .. role)
        end
    end
end
net.Receive("TTT_RoleWeaponsList", ShowList)

local function Clean()
    local _, roledirs = file.Find("roleweapons/*", "DATA")
    for _, name in pairs(roledirs) do
        if not table.HasValue(ROLE_STRINGS_RAW, name) then
            print("[ROLEWEAPONS] Removing folder representing invalid role: " .. name)
            file.Delete("roleweapons/" .. name, "DATA")
            continue
        end

        local rolefiles, _ = file.Find("roleweapons/" .. name .. "/*.txt", "DATA")
        local validfiles = 0
        for _, v in pairs(rolefiles) do
            -- Extract the weapon name from the file name
            local lastdotpos = v:find("%.")
            local weaponname = StringSub(v, 0, lastdotpos - 1)
            if weapons.GetStored(weaponname) == nil and GetEquipmentItemByName(weaponname) == nil then
                print("[ROLEWEAPONS] Removing file representing invalid weapon/equipment: " .. v)
                file.Delete("roleweapons/" .. name .. "/" .. v, "DATA")
                continue
            end

            validfiles = validfiles + 1
        end

        if validfiles == 0 then
            print("[ROLEWEAPONS] Removing empty folder: " .. name)
            file.Delete("roleweapons/" .. name, "DATA")
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