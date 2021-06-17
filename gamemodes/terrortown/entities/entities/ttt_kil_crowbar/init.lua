AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self.Entity:SetModel("models/weapons/w_bugbait.mdl")
	self:PrecacheGibs()
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
end

function ENT:PhysicsCollide(data, physObj)
	if data.HitEntity:IsPlayer() then
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
