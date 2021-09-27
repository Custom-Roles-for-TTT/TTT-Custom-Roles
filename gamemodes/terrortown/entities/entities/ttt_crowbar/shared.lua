AddCSLuaFile()
ENT.Type            = "anim"
ENT.Base            = "ttt_basegrenade_proj"

function ENT:Initialize()
    self:SetModel("models/weapons/w_crowbar.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:OnRemove()
end

function ENT:OnTakeDamage(dmgInfo)
end

function ENT:Think()
end

function ENT:Use(activator, caller)
    if activator:IsKiller() then
        activator:Give("weapon_kil_crowbar")
        self:Remove()
    end
end

function ENT:Break()
end
