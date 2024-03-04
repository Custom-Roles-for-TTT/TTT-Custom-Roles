include("shared.lua")

local net = net
local util = util
local file = file
local table = table
local string = string

local StringSub = string.sub
local TableInsert = table.insert

ROLEBLOCKS = {}

util.AddNetworkString("TTT_WriteRoleBlocks")
util.AddNetworkString("TTT_WriteRoleBlocks_Part")
util.AddNetworkString("TTT_RequestRoleBlocks")
util.AddNetworkString("TTT_ReadRoleBlocks")
util.AddNetworkString("TTT_ReadRoleBlocks_Part")

-- 2^16 bytes - 4 (header) - 2 (UInt length) - 1 (Extra optional byte) - 1 (terminanting byte)
local maxStreamLength = 65528

local function SendStreamToClient(ply, json, networkString, byte)
    if not json or #json == 0 then return end
    local jsonTable = util.Compress(json)
    if #jsonTable == 0 then
        ErrorNoHalt("Table compression failed!\n")
        return
    end

    local len = #jsonTable

    if len <= maxStreamLength then
        net.Start(networkString)
        net.WriteUInt(byte or 0, 8)
        net.WriteUInt(len, 16)
        net.WriteData(jsonTable, len)
        net.Send(ply)
    else
        local curpos = 0

        repeat
            net.Start(networkString .. "_Part")
            net.WriteData(StringSub(jsonTable, curpos + 1, curpos + maxStreamLength + 1), maxStreamLength)
            net.Send(ply)

            curpos = curpos + maxStreamLength + 1
        until (len - curpos <= maxStreamLength)

        net.Start(networkString)
        net.WriteUInt(byte or 0, 8)
        net.WriteUInt(len, 16)
        net.WriteData(StringSub(jsonTable, curpos + 1, len), len - curpos)
        net.Send(ply)
    end
end

local function ReceiveStreamFromClient(networkString, callback)
    local buff = ""
    net.Receive(networkString .. "_Part", function(len, ply)
        if not ply:IsAdmin() and not ply:IsSuperAdmin() then
            ErrorNoHalt("ERROR: You must be an administrator to configure Role Blocks\n")
            return
        end

        buff = buff .. net.ReadData(maxStreamLength)
    end)

    net.Receive(networkString, function(len, ply)
        if not ply:IsAdmin() and not ply:IsSuperAdmin() then
            ErrorNoHalt("ERROR: You must be an administrator to configure Role Blocks\n")
            return
        end

        local jsonTable = util.Decompress(buff .. net.ReadData(net.ReadUInt(16)))
        buff = ""

        if #jsonTable == 0 then
            ErrorNoHalt("Table decompression failed!\n")
            return
        end

        callback(jsonTable)
    end)
end

local function WriteRoleBlocks(json)
    file.Write("roleblocks.json", json)
end
ReceiveStreamFromClient("TTT_WriteRoleBlocks", WriteRoleBlocks)

net.Receive("TTT_RequestRoleBlocks", function(len, ply)
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("ERROR: You must be an administrator to configure Role Blocks\n")
        return
    end

    local json = file.Read("roleblocks.json", "DATA")
    if not json then return end
    SendStreamToClient(ply, json, "TTT_ReadRoleBlocks")
end)

function ROLEBLOCKS.GetBlockedRoles(excludeRolePack)
    local roleblocks = {}
    local json = file.Read("roleblocks.json", "DATA")
    if json then
        roleblocks = util.JSONToTable(json)
        if roleblocks == nil then
            ErrorNoHalt("Table decoding failed!\n")
            roleblocks = {}
        end
    end

    local blocks = {}
    excludeRolePack = excludeRolePack or false
    local rolepack = GetConVar("ttt_role_pack"):GetString()
    if rolepack and #rolepack > 0 and not excludeRolePack then
        local rolepackblocks = ROLEPACKS.GetRolePackBlockedRoles()
        if rolepackblocks and rolepackblocks.groups then
            blocks = table.Copy(rolepackblocks.groups)
        end

        if rolepackblocks and rolepackblocks.config and rolepackblocks.config.usedefault then
            for _, group in ipairs(roleblocks) do
                table.insert(blocks, group)
            end
        end
    else
        blocks = roleblocks
    end

    return blocks
end

----------------------------
-- OLD ROLE BLOCK CONVARS --
----------------------------

-- TODO: Deprecated - Remove after next major update

local paired_role_blocks = {
    {"deputy", "impersonator"},
    {"doctor", "quack"},
    {"paramedic", "hypnotist"},
    {"phantom", "parasite"},
    {"drunk", "clown"},
    {"jester", "swapper"}
}

local function FloatToFraction(x)
    local error = 0.001
    local lowerN = 0
    local lowerD = 1
    local upperN = 1
    local upperD = 1
    for _ = 1, 100 do -- If we somehow haven't found a close enough answer after 100 iterations just use what we have
        local middleN = lowerN + upperN
        local middleD = lowerD + upperD
        local middleF = middleN / middleD
        if error < x - middleF then
            lowerN = middleN
            lowerD = middleD
        elseif error < middleF - x then
            upperN = middleN
            upperD = middleD
        else
            return middleN, middleD
        end
    end
    return lowerN + upperN, lowerD + upperD
end

local function GreatestCommonDivisor(a, b)
    if b == 0 then
        return a
    else
        return GreatestCommonDivisor(b, a % b)
    end
end

hook.Add("TTTPrepareRound", "OldRoleBlocks_TTTPrepareRound", function()
    local roleblocks = ROLEBLOCKS.GetBlockedRoles(true)
    local changes = false
    for _, v in ipairs(paired_role_blocks) do
        local cvar_name = "ttt_single_" .. v[1] .. "_" .. v[2]
        if cvars.Bool(cvar_name, false) then
            local exists = false
            for _, group in ipairs(roleblocks) do
                if #group ~= 2 then continue end
                if (group[1].role == v[1] and group[2].role == v[2]) or (group[1].role == v[2] and group[2].role == v[1]) then
                    exists = true
                    break
                end
            end

            if not exists then
                local weight = cvars.Number(cvar_name .. "_chance", 0.5)
                local n, d = FloatToFraction(weight)
                local gcd = GreatestCommonDivisor(n, d)
                local weight1 = n / gcd
                local weight2 = (d / gcd) - weight1
                TableInsert(roleblocks, {{role = v[1], weight = weight1}, {role = v[2], weight = weight2}})
                ErrorNoHalt("WARNING: ConVar \'" .. cvar_name .. "\' deprecated. Your configuration has been imported into the new role blocks configuration. Use \'ttt_roleblocks\' on an admin client to configure!\n")
                changes = true
            end
        end
    end

    if changes then
        local json = util.TableToJSON(roleblocks)
        if json == nil then
            ErrorNoHalt("Table encoding failed!\n")
            return
        end
        file.Write("roleblocks.json", json)
    end
end)