-- Traitor radar functionality

-- should mirror client
local chargetime = 30

local math = math

local function RadarScan(ply, cmd, args)
    if IsValid(ply) and ply:IsTerror() then
        if ply:HasEquipmentItem(EQUIP_RADAR) then

            if ply.radar_charge > CurTime() then
                LANG.Msg(ply, "radar_charging")
                return
            end

            ply.radar_charge = CurTime() + chargetime

            local scan_ents = player.GetAll()
            table.Add(scan_ents, ents.FindByClass("ttt_decoy"))

            local targets = {}
            for k, p in ipairs(scan_ents) do
                if ply ~= p and IsValid(p) then
                    if (p:IsPlayer() and p:IsTerror()) or not p:IsPlayer() then
                        local pos = p:LocalToWorld(p:OBBCenter())

                        -- Round off, easier to send and inaccuracy does not matter
                        pos.x = math.Round(pos.x)
                        pos.y = math.Round(pos.y)
                        pos.z = math.Round(pos.z)

                        local role = p:IsPlayer() and p:GetRole() or -1

                        table.insert(targets, { role = role, pos = pos })
                    end
                end
            end

            net.Start("TTT_Radar")
            net.WriteUInt(#targets, 8)
            for k, tgt in ipairs(targets) do
                net.WriteUInt(tgt.role, 8)

                net.WriteInt(tgt.pos.x, 32)
                net.WriteInt(tgt.pos.y, 32)
                net.WriteInt(tgt.pos.z, 32)
            end
            net.Send(ply)

        else
            LANG.Msg(ply, "radar_not_owned")
        end
    end
end
concommand.Add("ttt_radar_scan", RadarScan)
