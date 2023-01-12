AddCSLuaFile()

ENT.Type      = "anim"
ENT.Spawnable = false

ENT.Model = "models/weapons/w_huntingbow_arrow.mdl"

if SERVER then
    resource.AddFile("models/weapons/w_huntingbow_arrow.mdl")
    resource.AddFile("materials/models/weapons/huntingbow/steelarrow.vmt")
end

local ARROW_MINS = Vector(-0.25, -0.25, 0.25)
local ARROW_MAXS = Vector(0.25, 0.25, 0.25)

if SERVER then
    util.AddNetworkString("TTT_CupidPaired")
end

function ENT:Initialize()
    if SERVER then
        self:SetModel(self.Model)

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_FLYGRAVITY)
        self:SetSolid(SOLID_BBOX)
        self:DrawShadow(true)

        self:SetCollisionBounds(ARROW_MINS, ARROW_MAXS)
        self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end
end

function ENT:Think()
    if SERVER then
        if self:GetMoveType() == MOVETYPE_FLYGRAVITY then
            self:SetAngles(self:GetVelocity():Angle())
        end
    end
end

local StickSound = {
    "cupid/impact_arrow_stick_1.wav",
    "cupid/impact_arrow_stick_2.wav",
    "cupid/impact_arrow_stick_3.wav"
}

local FleshSound = {
    "cupid/impact_arrow_flesh_1.wav",
    "cupid/impact_arrow_flesh_2.wav",
    "cupid/impact_arrow_flesh_3.wav",
    "cupid/impact_arrow_flesh_4.wav"
}

if SERVER then
    for _, s in ipairs(StickSound) do
        resource.AddSingleFile("sound/" .. s)
    end
    for _, s in ipairs(FleshSound) do
        resource.AddSingleFile("sound/" .. s)
    end
end

function ENT:Touch(ent)
    local owner = self:GetOwner()
    if not IsValid(owner) then
        return
    end

    local tr = self:GetTouchTrace()
    local tr2

    if tr.Hit then
        self:FireBullets({
            Damage = 0,
            Attacker = owner,
            Inflictor = self.Weapon,
            Callback = function(attacker, trace, damageinfo) tr2 = trace end,
            Force = 0,
            Tracer = 0,
            Src = tr.StartPos,
            Dir = tr.Normal,
            AmmoType = "huntingbow_arrows"
        })
    end

    if ent and ent:IsWorld() then
        sound.Play(table.Random(StickSound), tr.HitPos)

        self:SetMoveType(MOVETYPE_NONE)
        self:PhysicsInit(SOLID_NONE)

        SafeRemoveEntityDelayed(self, 10)
        return
    end

    if not IsValid(ent) then
        return
    end

    if ent:IsNPC() or ent:IsPlayer() then
        if tr2.Entity == ent then sound.Play(table.Random(FleshSound), tr.HitPos) end
        if ent:IsPlayer() and ent:IsActive() then
            if ent == owner then
                owner:PrintMessage(HUD_PRINTCENTER, "You cannot make yourself fall in love with someone.")
            else
                local target1 = owner:GetNWString("TTTCupidTarget1", "")
                if target1 == "" then
                    ent:SetNWString("TTTCupidShooter", owner:SteamID64())
                    owner:SetNWString("TTTCupidTarget1", ent:SteamID64())
                    owner:PrintMessage(HUD_PRINTCENTER, ent:Nick() .. " has been hit with your first arrow.")
                    owner:PrintMessage(HUD_PRINTTALK, ent:Nick() .. " has been hit with your first arrow.")
                    ent:PrintMessage(HUD_PRINTCENTER, "You have been hit by cupids arrow!")
                    ent:PrintMessage(HUD_PRINTTALK, "You have been hit by cupids arrow!")
                elseif owner:GetNWString("TTTCupidTarget2", "") == "" then
                    if ent:SteamID64() == target1 then
                        owner:PrintMessage(HUD_PRINTCENTER, "You cannot make someone fall in love with themselves.")
                    else
                        local ent2 = player.GetBySteamID64(target1)
                        ent:SetNWString("TTTCupidShooter", owner:SteamID64())
                        ent:SetNWString("TTTCupidLover", target1)
                        ent2:SetNWString("TTTCupidLover", ent:SteamID64())
                        owner:SetNWString("TTTCupidTarget2", ent:SteamID64())
                        owner:PrintMessage(HUD_PRINTCENTER, ent:Nick() .. " has fallen in love with " .. ent2:Nick() .. ".")
                        owner:PrintMessage(HUD_PRINTTALK, ent:Nick() .. " has fallen in love with " .. ent2:Nick() .. ".")
                        ent2:PrintMessage(HUD_PRINTCENTER, "You have fallen in love with " .. ent:Nick() .. "!")
                        ent2:PrintMessage(HUD_PRINTTALK, "You have fallen in love with " .. ent:Nick() .. "!")
                        ent:PrintMessage(HUD_PRINTCENTER, "You have fallen in love with " .. ent2:Nick() .. "!")
                        ent:PrintMessage(HUD_PRINTTALK, "You have fallen in love with " .. ent2:Nick() .. "!")
                        owner:StripWeapon("weapon_cup_bow")

                        net.Start("TTT_CupidPaired")
                        net.WriteString(owner:Nick())
                        net.WriteString(ent:Nick())
                        net.WriteString(ent2:Nick())
                        net.WriteString(owner:SteamID64())
                        net.Broadcast()

                        local mode = GetConVar("ttt_cupid_notify_mode"):GetInt()
                        if mode ~= ANNOUNCE_REVEAL_NONE then
                            for _, v in pairs(player.GetAll()) do
                                if v == ent or v == ent2 or v == owner then
                                    continue
                                end

                                if mode == ANNOUNCE_REVEAL_ALL or (v:IsTraitorTeam() and mode == ANNOUNCE_REVEAL_TRAITORS) or (v:IsInnocentTeam() and mode == ANNOUNCE_REVEAL_INNOCENTS) then
                                    v:PrintMessage(HUD_PRINTCENTER, ROLE_STRINGS_EXT[ROLE_CUPID] .. " has made two players fall in love!")
                                    v:PrintMessage(HUD_PRINTTALK, ROLE_STRINGS_EXT[ROLE_CUPID] .. " has made two players fall in love!")
                                end
                            end
                        end
                    end
                end
            end
        end

        self:Remove()
    else
        self:SetParent(ent)
        sound.Play(table.Random(StickSound), tr.HitPos)

        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)

        SafeRemoveEntityDelayed(self, 10)
    end
end