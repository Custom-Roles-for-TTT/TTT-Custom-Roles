AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Initialize
function ENT:Initialize()
	util.PrecacheSound("weapons/ar2/npc_ar2_altfire.wav")
	util.PrecacheSound("weapons/ar2/ar2_altfire.wav")
	util.PrecacheSound("weapons/grenade/tick1.wav")

	self.Entity:SetModel("models/weapons/w_eq_flashbang_thrown.mdl")
	self.Entity:SetMaterial("smokenade/smokenade")
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	local phys = self.Entity:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()

		--This is how we make the smoke explosion
		local Smoke = function()
			--Safeguards
			if not self.Entity then return end
			if not self.Entity:IsValid() then return end

			if SERVER then
				self.Entity:EmitSound("weapons/ar2/npc_ar2_altfire.wav", 72, 100)
				self.Entity:EmitSound("weapons/ar2/ar2_altfire.wav", 72, 100)

				local shake = ents.Create("env_physexplosion")
				shake:SetKeyValue("radius", 256)
				shake:SetKeyValue("magnitude", 32)
				shake:SetKeyValue("spawnflags", "3")
				shake:SetOwner(self.Owner)
				shake:SetPos(self:GetPos())
				shake:Fire("Explode" , "", 0)
				shake:Fire("kill", "", 2)

				local fear = ents.Create("ai_sound")
				fear:SetKeyValue("soundtype", 8)
				fear:SetKeyValue("volume", 312)
				fear:SetKeyValue("duration", 5)
				fear:SetOwner(self.Owner)
				fear:SetPos(self:GetPos())
				fear:Fire("EmitAISound" , "", 0.82)
				fear:Fire("kill", "", 6)

				local sfx = EffectData()
				sfx:SetOrigin(self:GetPos())
				util.Effect("effect_smokenade_smoke", sfx)
				util.ScreenShake(self:GetPos(), 32, 210, 1, 1024)

				self.Entity:Remove()
			end
		end

		--This is the little tick before the explosion
		local Sfx = function()
			if SERVER and self:IsValid() then
				self.Entity:EmitSound("weapons/grenade/tick1.wav", 62, 100 )
			end
		end

		--Tick
		timer.Simple(1.42, Sfx)

		--Summon smoke
		timer.Simple(1.72, Smoke)
	end
end

-- Play physics sound on impact
function ENT:PhysicsCollide(data, physobj)
	-- If hit something too hard
	if data.Speed > 132 and data.DeltaTime > 0.21 then
		-- Slow this down
		local newVelocity = physobj:GetVelocity():GetNormal()
		local lastSpeed = math.max(newVelocity:Length(), math.max(data.OurOldVelocity:Length(), data.Speed))
		physobj:SetVelocity(newVelocity * lastSpeed * 0.62)

		-- Make collision sound
		self.Entity:EmitSound("physics/metal/weapon_impact_soft" .. math.random(1,2) .. ".wav", 52, 100)
	end
end