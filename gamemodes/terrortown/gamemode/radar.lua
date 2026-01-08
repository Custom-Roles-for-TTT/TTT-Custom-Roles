-- Traitor radar functionality

-- should mirror client
local chargetime = 30

local concommand = concommand
local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local math = math
local net = net
local player = player
local table = table

local RunHook = hook.Run
local MathRound = math.Round
local PlayerIterator = player.Iterator
local TableInsert = table.insert

local function RadarScan(ply, cmd, args)
    if not IsValid(ply) or ply:IsSpec() then return end

    if not ply:HasEquipmentItem(EQUIP_RADAR) then
        -- Don't tell the role with a delayed shop that they don't have radar when they buy it
        -- Everyone else should get yelled at though
        if not ply:ShouldDelayShopPurchase() then
            LANG.Msg(ply, "radar_not_owned")
        end
        return
    end

    if ply.radar_charge > CurTime() then
        LANG.Msg(ply, "radar_charging")
        return
    end

    ply.radar_charge = CurTime() + chargetime

    local targets = {}
    for _, p in PlayerIterator() do
        if ply == p or not IsValid(p) or not p:IsTerror() then continue end
        if p:GetNWBool("disguised", false) and not ply:IsTraitorTeam() then continue end

        local pos = p:LocalToWorld(p:OBBCenter())
        local role = p:GetDisplayedRole()
        TableInsert(targets, {
            role = role,
            pos = pos,
            ent = p,
            was_beggar = p:GetNWBool("WasBeggar", false),
            was_bodysnatcher = p:GetNWBool("WasBodysnatcher", false),
            killer_clown_active = p:IsClown() and p:IsRoleActive(),
            should_act_like_jester = p:ShouldActLikeJester(),
            sid64 = p:SteamID64()
        })
    end

    RunHook("TTTRadarScan", ply, targets)

    local roleBits = util.RoleBits()
    net.Start("TTT_Radar")
        net.WriteUInt(#targets, 8)
        for _, tgt in ipairs(targets) do
            net.WriteInt(tgt.role, roleBits)

            -- Round off, easier to send and inaccuracy does not matter
            net.WriteInt(MathRound(tgt.pos.x), 15)
            net.WriteInt(MathRound(tgt.pos.y), 15)
            net.WriteInt(MathRound(tgt.pos.z), 15)

            net.WriteBool(tgt.was_beggar)
            net.WriteBool(tgt.was_bodysnatcher)
            net.WriteBool(tgt.killer_clown_active)
            net.WriteBool(tgt.should_act_like_jester)
            net.WriteString(tgt.sid64 or "")
        end
    net.Send(ply)
end
concommand.Add("ttt_radar_scan", RadarScan)