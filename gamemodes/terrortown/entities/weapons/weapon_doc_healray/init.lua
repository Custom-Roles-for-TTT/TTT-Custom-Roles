
AddCSLuaFile("shared.lua")
AddCSLuaFile("config.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

--Assets
resource.AddFile("materials/stungun/lightningbolt.png")
resource.AddFile("materials/stungun/lightningbolt_glow.png")
resource.AddFile("materials/stungun/lightningbolt_outline.png")
resource.AddFile("materials/stungun/lightningbolt2.png")
resource.AddFile("sound/stungun/tazer.wav")
if HEALRAY.IsTTT then
	resource.AddFile("materials/stungun/icon_stungun.vmt")
end

local healInitial = 20
local healAmount = 5


--Stores the players weaponclasses and ammo in a table.
local function PlyStoreWeapons(ply)
	ply.storeweps = {}
	for k,v in pairs(ply:GetWeapons()) do
		table.insert(ply.storeweps, {cl = v:GetClass(), c1 = v:Clip1(), c2 = v:Clip2()})
	end
end

--Retrieves the stored weapons.
local function PlyRetrieveWeapons(ply)
	for k,v in pairs(ply.storeweps or {}) do
		ply:Give(v.cl)
		local wep = ply:GetWeapon(v.cl)
		if IsValid(wep) then
			wep:SetClip1(v.c1)
			wep:SetClip2(v.c2)
		end
	end
end

--Transforms a (1,1,1,1) color table to (255,255,255,255)
local function FromPlyColor(v)
	v:Mul(255)
	return Color(v.x,v.y,v.z,255)
end

function SWEP:Equip( ply )
	self.BaseClass.Equip(self,ply)
	self.lastowner = ply
end

util.AddNetworkString("tazerondrop")
function SWEP:OnDrop()
	self.BaseClass.OnDrop(self)
	if IsValid(self.lastowner) then
		net.Start("tazerondrop")
			net.WriteEntity(self)
		net.Send(self.lastowner)
	end
end



--Makes a hull trace the size of a player.

local data = {}
function HEALRAY.PlayerHullTrace(pos, ply, filter)
	data.start = pos
	data.endpos = pos
	data.filter = filter
	
	return util.TraceEntity( data, ply )
end


--Attemps to place the player at this position or as close as possible.

-- Directions to check
local directions = {
	Vector(0,0,0), Vector(0,0,1), --Center and up
	Vector(1,0,0), Vector(-1,0,0), Vector(0,1,0), Vector(0,-1,0) --All cardinals
	}
for deg=45,315,90 do --Diagonals
	local r = math.rad(deg)
	table.insert(directions, Vector(math.Round(math.cos(r)), math.Round(math.sin(r)), 0))
end

local magn = 15 -- How much increment for each iteration
local iterations = 2 -- How many iterations
function HEALRAY.PlayerSetPosNoBlock( ply, pos, filter )
	local tr
	
	local dirvec
	local m = magn
	local i = 1
	local its = 1
	repeat
		dirvec = directions[i] * m
		i = i + 1
		if i > #directions then
			its = its + 1
			i = 1
			m = m + magn
			if its > iterations then
				ply:SetPos(pos) -- We've done as many checks as we wanted, lets just force him to get stuck then.
				return false
			end
		end
		
		tr = HEALRAY.PlayerHullTrace(dirvec + pos, ply, filter)
	until tr.Hit == false
	
	ply:SetPos(pos + dirvec)
	return true
end


--Sets the player invisible/visible

function HEALRAY.PlayerInvis( ply, bool )
	ply:SetNoDraw(bool)
	ply:DrawShadow( not bool )
end



util.AddNetworkString("tazestartview")
util.AddNetworkString("tazeendview")
	
function HEALRAY:FireHeal( ply, pushdir )
	--Gag
	ply.tazeismuted = true
	self:Heal(ply, 1)
end

function HEALRAY:Heal(ply, t)
	local hpAdd = 0

	if ConVarExists("ttt_doctor_hot_initial") then
		healInitial = GetConVar("ttt_doctor_hot_initial"):GetInt()
	end
	
	if ConVarExists("ttt_doctor_hot_amount") then
		healAmount = GetConVar("ttt_doctor_hot_amount"):GetInt()
	end

	if ply:IsActive() and t <= 12 then
		if t == 1 then
			hpAdd = healInitial
		else
			hpAdd = healAmount
		end

		local newHealth = math.min(200, ply:Health() + hpAdd)
		ply:SetHealth(newHealth)
		t = t + 1
		timer.Simple(5, function()
			self:Heal(ply, t)
		end)
	end
end

hook.Add("PlayerSay", "Tazer", function(ply, str)
	if ply.tazeismuted then return "" end
end)

--TTT Specifics
function SWEP:WasBought(buyer)
	if not self.InfiniteAmmo then
		buyer:GiveAmmo(math.max(0, self.Ammo - 1), "ammo_stungun")
	end
end