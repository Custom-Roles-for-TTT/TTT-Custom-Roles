include("shared.lua")

local net = net
local util = util
local file = file
local table = table
local string = string

local StringSub = string.sub
local TableInsert = table.insert
local TableHasValue = table.HasValue

if SERVER then
    util.AddNetworkString("TTT_WriteRolePackTable")
    util.AddNetworkString("TTT_WriteRolePackTable_Part")
    util.AddNetworkString("TTT_RequestRolePackTable")
    util.AddNetworkString("TTT_ReadRolePackTable")
    util.AddNetworkString("TTT_ReadRolePackTable_Part")
    util.AddNetworkString("TTT_RequestRolePackList")
    util.AddNetworkString("TTT_SendRolePackList")
    util.AddNetworkString("TTT_CreateRolePack")
    util.AddNetworkString("TTT_RenameRolePack")
    util.AddNetworkString("TTT_DeleteRolePack")
    util.AddNetworkString("TTT_ApplyRolePack")
    util.AddNetworkString("TTT_SendRolePackRoleList")

    -- 2^16 bytes - 4 (header) - 2 (UInt length) - 1 (terminanting byte)
    local maxStreamLength = 65529

    local function SendStreamToClient(ply, json, networkString)
        if not json or json == "" then return end
        local jsonTable = util.Compress(json)
        if jsonTable == "" then
            ErrorNoHalt("Table compression failed!\n")
            return
        end

        local len = #jsonTable

        if len <= maxStreamLength then
            net.Start(networkString)
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
            net.WriteUInt(len, 16)
            net.WriteData(StringSub(jsonTable, curpos + 1, len), len - curpos)
            net.Send(ply)
        end
    end

    local function ReceiveStreamFromClient(networkString, callback)
        local buff = ""
        net.Receive(networkString .. "_Part", function()
            buff = buff .. net.ReadData(maxStreamLength)
        end)

        net.Receive(networkString, function()
            local jsonTable = util.Decompress(buff .. net.ReadData(net.ReadUInt(16)))
            buff = ""

            if jsonTable == "" then
                ErrorNoHalt("Table decompression failed!\n")
            end

            callback(jsonTable)
        end)
    end

    local function WriteRolePackTable(json)
        local jsonTable = util.JSONToTable(json)
        local name = jsonTable.name
        file.Write("rolepacks/" .. name .. ".json", json)
    end
    ReceiveStreamFromClient("TTT_WriteRolePackTable", WriteRolePackTable)

    net.Receive("TTT_RequestRolePackTable", function(len, ply)
        local name = net.ReadString()
        local json = file.Read("rolepacks/" .. name .. ".json", "DATA")
        if not json then return end
        SendStreamToClient(ply, json, "TTT_ReadRolePackTable")
    end)

    net.Receive("TTT_RequestRolePackList", function(len, ply)
        net.Start("TTT_SendRolePackList")
        local packNames = {}
        for _, v in pairs(file.Find("rolepacks/*.json", "DATA")) do
            TableInsert(packNames, StringSub(v,1, -6))
        end
        net.WriteUInt(#packNames, 8)
        for _, name in pairs(packNames) do
            net.WriteString(name)
        end
        net.Send(ply)
    end)

    net.Receive("TTT_CreateRolePack", function()
        local name = net.ReadString()
        if not file.IsDir("rolepacks", "DATA") then
            if file.Exists("rolepacks", "DATA") then
                ErrorNoHalt("Item named 'rolepacks' already exists in garrysmod/data but it is not a directory\n")
                return
            end

            file.CreateDir("rolepacks")
        end
        file.Write("rolepacks/" .. name .. ".json", "")
    end)

    net.Receive("TTT_RenameRolePack", function()
        local oldName = net.ReadString()
        local newName = net.ReadString()
        local oldPath = "rolepacks/" .. oldName .. ".json"
        if file.Exists(oldPath, "DATA") then
            file.Rename(oldPath, "rolepacks/" .. newName .. ".json")
        end
    end)

    net.Receive("TTT_DeleteRolePack", function()
        local name = net.ReadString()
        local path = "rolepacks/" .. name .. ".json"
        if file.Exists(path, "DATA") then
            file.Delete(path)
        end
    end)

    net.Receive("TTT_ApplyRolePack", function()
        local name = net.ReadString()
        GetConVar("ttt_role_pack"):SetString(name)
    end)

    function SendRolePackRoleList()
        ROLE_PACK_ROLES = {}

        net.Start("TTT_SendRolePackRoleList")
        local name = GetConVar("ttt_role_pack"):GetString()
        local json = file.Read("rolepacks/" .. name .. ".json", "DATA")
        if not json then
            net.WriteUInt(0, 8)
            net.Broadcast()
            return
        end

        local jsonTable = util.JSONToTable(json)
        if jsonTable == nil then
            ErrorNoHalt("Table decoding failed!\n")
            net.WriteUInt(0, 8)
            net.Broadcast()
            return
        end

        local roles = {}
        for _, slot in pairs(jsonTable.slots) do
            for _, roleslot in pairs(slot) do
                local role = ROLE_NONE
                for r = ROLE_INNOCENT, ROLE_MAX do
                    if ROLE_STRINGS_RAW[r] == roleslot.role then
                        role = r
                        break
                    end
                end
                if role ~= ROLE_NONE and not TableHasValue(roles, role) then
                    TableInsert(roles, role)
                end
            end
        end

        net.WriteUInt(#roles, 8)
        for _, role in pairs(roles) do
            net.WriteUInt(role, 8)
            ROLE_PACK_ROLES[role] = true
        end
        net.Broadcast()
    end
end