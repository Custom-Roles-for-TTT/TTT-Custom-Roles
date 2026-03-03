local function PrintRoleCvars(ply, cmd, args)
    if #args == 0 then
        ErrorNoHalt("Missing role name argument. Usage: cr4ttt_role_cvars role_name [format] [min_name_length_for_md_fmt] [min_default_length_for_md_fmt]\n")
        return
    end

    local roleName = args[1]
    local roleId
    if table.HasValue(ROLE_STRINGS_RAW, roleName) then
        roleId = table.KeyFromValue(ROLE_STRINGS_RAW, roleName)
    elseif table.HasValue(ROLE_STRINGS_SHORT, roleName) then
        roleId = table.KeyFromValue(ROLE_STRINGS_SHORT, roleName)
    else
        ErrorNoHalt("Unknown role: " .. roleName .. "\n")
        return
    end

    if roleId <= ROLE_NONE or roleId > ROLE_MAX then
        ErrorNoHalt("Invalid role: " .. roleName .. "\n")
        return
    end

    if not ROLE_CONVARS[roleId] then
        ErrorNoHalt("Role has no ConVars: " .. roleName .. "\n")
        return
    end

    local fmt
    if #args > 1 then
        fmt = args[2]
    end

    local nameLengthMin = 46
    if #args > 2 then
        nameLengthMin = tonumber(args[3]) or nameLengthMin
    end

    local defaultLengthMin = 8
    if #args > 3 then
        defaultLengthMin = tonumber(args[4]) or defaultLengthMin
    end

    local formatFn
    if fmt == "md" or fmt == "markdown" then
        formatFn = function(cvar)
            local convar = GetConVar(cvar.cvar)

            local namePadded = convar:GetName()
            while #namePadded < nameLengthMin do
                namePadded = namePadded .. " "
            end

            local defaultPadded = convar:GetDefault()
            while #defaultPadded < defaultLengthMin do
                defaultPadded = defaultPadded .. " "
            end

            print(namePadded .. " " .. defaultPadded .. "// " .. convar:GetHelpText())
        end
    elseif fmt == "html" or fmt == "web" then
        local function GetCvarType(convar, cvar)
            if cvar.type == ROLE_CONVAR_TYPE_NUM then
                local typeName
                if not cvar.decimal or cvar.decimal == 0 then
                    typeName = "Integer"
                else
                    typeName = "Float"
                end

                if convar:GetMin() and convar:GetMax() then
                    return typeName .. " (" .. convar:GetMin() .. "-" .. convar:GetMax() .. ")"
                end
                return typeName
            elseif cvar.type == ROLE_CONVAR_TYPE_BOOL then
                return "Boolean"
            elseif cvar.type == ROLE_CONVAR_TYPE_TEXT then
                return "String"
            elseif cvar.type == ROLE_CONVAR_TYPE_DROPDOWN then
                if cvar.isNumeric then
                    if convar:GetMin() and convar:GetMax() then
                        return "Integer (" .. convar:GetMin() .. "-" .. convar:GetMax() .. ")"
                    end
                    return "Integer"
                end
                return "String"
            end
        end

        local function GetCvarDesc(convar, cvar)
            local desc = convar:GetHelpText()
            if cvar.type == ROLE_CONVAR_TYPE_DROPDOWN then
                desc = desc .. ":"
                if cvar.isNumeric then
                    desc = desc .. "\r\n        <ol start=\"" .. (convar:GetMin() or 0) .. "\">"
                    for _, choice in ipairs(cvar.choices) do
                        desc = desc .. "\r\n            <li>" .. choice .. ".</li>"
                    end
                    desc = desc .. "\r\n        </ol>\r\n    "
                else
                    desc = desc .. "\r\n        <ul>"
                    for _, choice in ipairs(cvar.choices) do
                        desc = desc .. "\r\n            <li>" .. choice .. ".</li>"
                    end
                    desc = desc .. "\r\n        </ul>\r\n    "
                end
            end

            return desc
        end

        formatFn = function(cvar)
            local convar = GetConVar(cvar.cvar)
            print("<tr>")
            print("    <td>" .. cvar.cvar .. "</td>")
            print("    <td>" .. convar:GetDefault() .. "</td>")
            print("    <td>" .. GetCvarType(convar, cvar) .. "</td>")
            print("    <td>" .. GetCvarDesc(convar, cvar) .. "</td>")
            print("</tr>")
        end
    else
        formatFn = function(cvar)
            local convar = GetConVar(cvar.cvar)
            print(convar:GetName() .. " (def. " .. convar:GetDefault() .. ") - " .. convar:GetHelpText())
        end
    end

    local roleCvars = table.Copy(ROLE_CONVARS[roleId])
    table.SortByMember(roleCvars, "cvar", true)

    for _, cvar in ipairs(roleCvars) do
        formatFn(cvar)
    end
end

local function PrintRoleCvarsComplete(cmd, argStr, args)
    if #args == 1 then
        local filtered = {}
        for _, r in ipairs(ROLE_STRINGS_RAW) do
            if string.StartsWith(r, args[1]) then
                table.insert(filtered, cmd .. " \"" .. r .. "\" ")
            end
        end
        return filtered
    elseif #args == 2 then
        local options = {"html", "markdown", "ulx"}
        local filtered = {}
        for _, f in ipairs(options) do
            if string.StartsWith(f, args[2]) then
                table.insert(filtered, cmd .. " \"" .. args[1] .. "\" \"" .. f .. "\"")
            end
        end
        return filtered
    end
end

concommand.Add("cr4ttt_role_cvars", PrintRoleCvars, PrintRoleCvarsComplete, "Prints all role custom convars in the desired format. Usage: cr4ttt_role_cvars role_name [format] [min_name_length_for_md_fmt] [min_default_length_for_md_fmt]")