net.Receive("TTT_SetPlayerProperty", function()
    local ply = net.ReadPlayer()
    if not IsPlayer(ply) then return end

    local propertyName = net.ReadString()
    local propertyValue = net.ReadType()

    ply[propertyName] = propertyValue
end)

net.Receive("TTT_ClearPlayerProperty", function()
    local ply = net.ReadPlayer()
    if not IsPlayer(ply) then return end

    local propertyName = net.ReadString()
    ply[propertyName] = nil
end)

net.Receive("TTT_SetEntityProperty", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    local propertyName = net.ReadString()
    local propertyValue = net.ReadType()

    ent[propertyName] = propertyValue
end)

net.Receive("TTT_ClearEntityProperty", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    local propertyName = net.ReadString()
    ent[propertyName] = nil
end)