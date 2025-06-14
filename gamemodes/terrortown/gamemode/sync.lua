util.AddNetworkString("TTT_ClearEntityProperty")
util.AddNetworkString("TTT_ClearPlayerProperty")
util.AddNetworkString("TTT_SetEntityProperty")
util.AddNetworkString("TTT_SetPlayerProperty")

SYNC = {}

function SYNC:SetPlayerProperty(ply, propertyName, propertyValue, targets)
    ply[propertyName] = propertyValue

    net.Start("TTT_SetPlayerProperty")
    net.WritePlayer(ply)
    net.WriteString(propertyName)
    net.WriteType(propertyValue)
    if targets then
        net.Send(targets)
    else
        net.Broadcast()
    end
end

function SYNC:ClearPlayerProperty(ply, propertyName, targets)
    ply[propertyName] = nil

    net.Start("TTT_ClearPlayerProperty")
    net.WritePlayer(ply)
    net.WriteString(propertyName)
    if targets then
        net.Send(targets)
    else
        net.Broadcast()
    end
end

function SYNC:SetEntityProperty(ent, propertyName, propertyValue, targets)
    ent[propertyName] = propertyValue

    net.Start("TTT_SetEntityProperty")
    net.WriteEntity(ent)
    net.WriteString(propertyName)
    net.WriteType(propertyValue)
    if targets then
        net.Send(targets)
    else
        net.Broadcast()
    end
end

function SYNC:ClearEntityProperty(ent, propertyName, targets)
    ent[propertyName] = nil

    net.Start("TTT_ClearEntityProperty")
    net.WriteEntity(ent)
    net.WriteString(propertyName)
    if targets then
        net.Send(targets)
    else
        net.Broadcast()
    end
end