-- Traitor radar functionality

-- should mirror client
local chargetime = 30

local concommand = concommand
local ipairs = ipairs
local IsValid = IsValid
local math = math
local net = net
local player = player
local table = table

local GetAllPlayers = player.GetAll
local FindEntsByClass = ents.FindByClass
local MathRound = math.Round

local function RadarScan(ply, cmd, args)
    if IsValid(ply) and ply:IsTerror() then
        if ply:HasEquipmentItem(EQUIP_RADAR) then

            if ply.radar_charge > CurTime() then
                LANG.Msg(ply, "radar_charging")
                return
            end

            ply.radar_charge = CurTime() + chargetime

            local scan_ents = GetAllPlayers()
            table.Add(scan_ents, FindEntsByClass("ttt_decoy"))

            local targets = {}
            for _, p in ipairs(scan_ents) do
                -- Only show radar blips for other entities that are valid
                if (ply ~= p and IsValid(p)) and
                    -- Only show non-players or players who are actually playing currently
                    (not p:IsPlayer() or (p:IsPlayer() and p:IsTerror())) then

                    -- If the target is disguised, only show the icon for the traitor team
                    if not p:GetNWBool("disguised", false) or ply:IsTraitorTeam() then
                        local pos = p:LocalToWorld(p:OBBCenter())

                        -- Round off, easier to send and inaccuracy does not matter
                        pos.x = MathRound(pos.x)
                        pos.y = MathRound(pos.y)
                        pos.z = MathRound(pos.z)

                        local role = p:IsPlayer() and p:GetDisplayedRole() or -1

                        table.insert(targets, {
                            role = role,
                            pos = pos,
                            was_beggar = p:GetNWBool("WasBeggar", false),
                            was_bodysnatcher = p:GetNWBool("WasBodysnatcher", false),
                            killer_clown_active = p:IsPlayer() and p:IsClown() and p:IsRoleActive(),
                            should_act_like_jester = p:IsPlayer() and p:ShouldActLikeJester(),
                            sid64 = p:IsPlayer() and p:SteamID64() or ""
                        })
                    end
                end
            end

            net.Start("TTT_Radar")
            net.WriteUInt(#targets, 8)
            for _, tgt in ipairs(targets) do
                net.WriteInt(tgt.role, 8)

                net.WriteInt(tgt.pos.x, 15)
                net.WriteInt(tgt.pos.y, 15)
                net.WriteInt(tgt.pos.z, 15)

                net.WriteBool(tgt.was_beggar)
                net.WriteBool(tgt.was_bodysnatcher)
                net.WriteBool(tgt.killer_clown_active)
                net.WriteBool(tgt.should_act_like_jester)
                net.WriteString(tgt.sid64)
            end
            net.Send(ply)

        -- Don't tell the role with a delayed shop that they don't have radar when they buy it
        -- Everyone else should get yelled at though
        elseif not ply:ShouldDelayShopPurchase() then
            LANG.Msg(ply, "radar_not_owned")
        end
    end
end
concommand.Add("ttt_radar_scan", RadarScan)
