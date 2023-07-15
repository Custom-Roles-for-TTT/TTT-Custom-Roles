local gmod = gmod
local hook = hook
local net = net
local string = string
local util = util

local CallHook = hook.Call
local StringStartsWith = string.StartsWith

util.AddNetworkString("TTT_ClientDeathNotify")

local death_notifier_enable = CreateConVar("ttt_death_notifier_enable", "1")

hook.Add("PlayerDeath", "TTT_ClientDeathNotify", function(victim, inflictor, attacker)
    if gmod.GetGamemode().Name ~= "Trouble in Terrorist Town" then return end
    if not death_notifier_enable:GetBool() then return end

    local reason = "nil"
    local killerName = "nil"
    local role = ROLE_NONE

    if victim.DiedByWater then
        reason = "water"
    elseif attacker == victim then
        reason = "suicide"
    elseif inflictor ~= NULL then
        if IsPlayer(victim) and (StringStartsWith(inflictor:GetClass(), "prop_physics") or inflictor:GetClass() == "prop_dynamic") then
            -- If the killer is also a prop
            reason = "prop"
        elseif attacker then
            if (inflictor:GetClass() == "entityflame" and attacker:GetClass() == "entityflame") or
                (inflictor:GetClass() == "env_fire" and attacker:GetClass() == "env_fire") then
                reason = "burned"
            elseif inflictor:GetClass() == "worldspawn" and attacker:GetClass() == "worldspawn" then
                reason = "fell"
            elseif IsPlayer(attacker) and victim ~= attacker then
                reason = "ply"
                killerName = attacker:Nick()
                role = attacker:GetRole()
            end
        end
    end

    local new_reason, new_killer, new_role = CallHook("TTTDeathNotifyOverride", nil, victim, inflictor, attacker, reason, killerName, role)
    if type(new_reason) == "string" then reason = new_reason end
    if type(new_killer) == "string" then killerName = new_killer end
    if type(new_role) == "number" and new_role >= ROLE_NONE and new_role <= ROLE_MAX then role = new_role end

    -- Send the buffer message with the death information to the victim
    net.Start("TTT_ClientDeathNotify")
    net.WriteString(killerName)
    net.WriteInt(role, 8)
    net.WriteString(reason)
    net.Send(victim)
end)