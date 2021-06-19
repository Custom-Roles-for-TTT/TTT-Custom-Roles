HEALRAY = {} -- General stungun stuff table
include("config.lua")

HEALRAY.IsTTT = true -- For a gamemode to be TTT only
if HEALRAY.IsTTT then
	SWEP.Base = "weapon_tttbase"
	SWEP.AmmoEnt = ""
	SWEP.IsSilent = false
	SWEP.NoSights = true
end

--SWEP.Author = "Donkie"
SWEP.Instructions = "Left click to heal a person."
SWEP.Contact = ""
SWEP.Purpose = ""

SWEP.ViewModelFOV = 50
SWEP.ViewModelFlip = false
SWEP.ViewModel = Model("models/weapons/c_pistol.mdl")
SWEP.WorldModel = Model("models/weapons/w_pistol.mdl")

SWEP.UseHands = true

SWEP.Spawnable = true
SWEP.AdminOnly = true

if SWEP.InfiniteAmmo then
	SWEP.Primary.ClipSize = -1
	SWEP.Primary.DefaultClip = 0
	SWEP.Primary.Ammo = "none"
else
	SWEP.Primary.ClipSize = 1
	SWEP.Primary.DefaultClip = 1
	
	if HEALRAY.IsTTT then
		SWEP.Primary.DefaultClip = SWEP.Ammo
		SWEP.Primary.ClipMax = SWEP.Ammo
	end
	
	SWEP.Primary.Ammo = "ammo_stungun"
end
SWEP.Primary.Automatic = false

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

--print(SERVER and "SERVER INIT" or "CLIENT INIT")

SWEP.Uncharging = false

game.AddAmmoType({
	name = "ammo_stungun",
	dmgtype = DMG_GENERIC,
	tracer = TRACER_NONE,
	plydmg = 0,
	npcdmg = 0,
	force = 0,
	minsplash = 0,
	maxsplash = 0
})

if HEALRAY.AddAmmoItem >= 0 then
	if GAMEMODE.AddAmmoType then
		GAMEMODE:AddAmmoType("ammo_stungun", "Stungun Charges", "models/Items/battery.mdl", math.ceil(HEALRAY.AddAmmoItem), 1)
	end
end

function SWEP:PrimaryAttack()
	if self.Charge < 100 then return end
	
	if not self.InfiniteAmmo then
		if self:Clip1() <= 0 then return end
		self:TakePrimaryAmmo(1)
	end
	
	self.Uncharging = true
	
	--Shoot trace
	self.Owner:LagCompensation(true)
	local tr = util.TraceLine(util.GetPlayerTrace( self.Owner ))
	self.Owner:LagCompensation(false)
	
	--Animations
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	
	--Electric bolt, taken from toolgun
	local effectdata = EffectData()
		effectdata:SetOrigin( tr.HitPos )
		effectdata:SetStart( self.Owner:GetShootPos() )
		effectdata:SetAttachment( 1 )
		effectdata:SetEntity( self.Weapon )
	util.Effect( "ToolTracer", effectdata )
	
	if SERVER then
		self.Owner:EmitSound("npc/turret_floor/shoot1.wav",100,100)
	end
	
	local ent = tr.Entity
	
	if CLIENT then return end
	
	--Don't proceed if we don't hit any player
	if not IsValid(ent) or not ent:IsPlayer() then return end
	if ent == self.Owner then return end
	if self.Owner:GetShootPos():Distance(tr.HitPos) > self.Range then return end
	
	net.Start("DrawHitMarker")
	net.WriteBool(false)
	net.Send(self.Owner) -- Send the message to the attacker

	HEALRAY:FireHeal( ent, (ent:GetPos() - self.Owner:GetPos()):GetNormal() )
end

local chargeinc
function SWEP:Think()
	--In charge of charging the swep
	--Since we got the same in-sensitive code both client and serverside we don't need to network anything.
	if SERVER or (CLIENT and IsFirstTimePredicted()) then
		if not chargeinc then
			--Calculate how much we should increase charge every tick based on how long we want it to take.
			chargeinc = ((100 / self.RechargeTime) * engine.TickInterval())
		end
		
		local inc = self.Uncharging and (-5) or chargeinc
		
		if self:Clip1() <= 0 and not self.InfiniteAmmo then inc = math.min(inc, 0) end -- If we're out of clip, we shouldn't be allowed to recharge.
		
		self.Charge = math.min(self.Charge + inc, 100)
		if self.Charge < 0 then self:Reload() self.Uncharging = false self.Charge = 0 end
	end
end

function SWEP:SecondaryAttack()
	return false
end

function SWEP:Reload()
	self.Weapon:DefaultReload( ACT_VM_RELOAD )
	return true
end

local shoulddisable = {} -- Disables muzzleflashes and ejections
shoulddisable[21] = true
shoulddisable[5003] = true
shoulddisable[6001] = true
function SWEP:FireAnimationEvent( pos, ang, event, options )
	if shoulddisable[event] then return true end
end

hook.Add("PhysgunPickup", "Tazer", function(_,ent)
	if not HEALRAY.AllowPhysgun and IsValid(ent:GetNWEntity("plyowner")) then return false end
end)
hook.Add("CanTool", "Tazer", function(_,tr,_)
	if not HEALRAY.AllowToolgun and IsValid(tr.Entity) and IsValid(tr.Entity:GetNWEntity("plyowner")) then return false end
end)

