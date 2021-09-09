AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.DidCollide = false

function ENT:Initialize()
    self:SetModel("models/weapons/w_bugbait.mdl")
    self:PrecacheGibs()
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:PhysicsCollide(data, physObj)
    if not self.DidCollide then
        if IsPlayer(data.HitEntity) then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(50)
            dmginfo:SetAttacker(self:GetOwner())
            dmginfo:SetInflictor(self)
            dmginfo:SetDamageType(DMG_SLASH)
            dmginfo:SetDamagePosition(self:GetPos())

            data.HitEntity:TakeDamageInfo(dmginfo)
        end

        local ent = ents.Create("ttt_crowbar")
        ent:SetPos(self:GetPos())
        ent:SetAngles(self:GetAngles())
        ent:Spawn()
        ent:SetModel("models/weapons/w_crowbar.mdl")
        self.DidCollide = true
    end

    self:Remove()
end

function ENT:OnRemove()
end

function ENT:OnTakeDamage(dmgInfo)
end

function ENT:Think()
end

function ENT:Break()
end
