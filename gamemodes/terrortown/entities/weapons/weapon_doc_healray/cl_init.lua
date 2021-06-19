--Based off Stungun SWEP Created by Donkie (http://steamcommunity.com/id/Donkie/)

include("shared.lua")

SWEP.PrintName = "Heal Ray"
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = (not SWEP.InfiniteAmmo)
SWEP.DrawCrosshair = false

language.Add("ammo_stungun_ammo", "Stungun Ammo")

if HEALRAY.IsTTT then
	--TTT stuff
	-- Path to the icon material
	SWEP.Icon = "stungun/icon_stungun"

	local ammotext = ""
	if SWEP.Ammo > 0 then
		ammotext = "\nIt has "..SWEP.Ammo.." charges."
	end

	-- Text shown in the equip menu
	SWEP.EquipMenuData = {
		type = "Weapon",
		desc = string.format("Heal ray used to heal terrorists over time",ammotext)
	}
end


SWEP.VElements = {
	["Yellowbox+"] = { type = "Model", model = "models/props_c17/FurnitureFridge001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "Yellowbox", pos = Vector(-3.182, 0, 0), angle = Angle(0, 0, 0), size = Vector(0.05, 0.1, 0.029), color = Color(255, 255, 0, 255), surpresslightning = false, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["Yellowbox"] = { type = "Model", model = "models/props_c17/FurnitureFridge001a.mdl", bone = "ValveBiped.square", rel = "", pos = Vector(0.259, 0.455, 2.273), angle = Angle(90, 0, 180), size = Vector(0.05, 0.1, 0.029), color = Color(255, 255, 0, 255), surpresslightning = false, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["Yellowbox+++"] = { type = "Model", model = "models/props_c17/FurnitureFridge001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.171, 1.784, -0.456), angle = Angle(0, 90, -101.25), size = Vector(0.054, 0.293, 0.05), color = Color(0, 0, 24, 255), surpresslightning = false, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["Yellowbox++"] = { type = "Model", model = "models/props_c17/FurnitureFridge001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "Yellowbox", pos = Vector(-1.8, -0.201, -0.75), angle = Angle(90, -90, 0), size = Vector(0.054, 0.4, 0.05), color = Color(0, 0, 0, 255), surpresslightning = false, material = "phoenix_storms/stripes", skin = 0, bodygroup = {} },
	["Blackreceiver"] = { type = "Model", model = "models/props_c17/FurnitureWashingmachine001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "Yellowbox", pos = Vector(-3.5, 0, -0.201), angle = Angle(0, -90, 90), size = Vector(0.119, 0.054, 0.3), color = Color(0, 0, 0, 0), surpresslightning = false, material = "phoenix_storms/stripes", skin = 0, bodygroup = {} },
	["counter"] = { type = "Quad", bone = "ValveBiped.Bip01_R_Hand", rel = "Blackreceiver", pos = Vector(0, 0, 4.099), angle = Angle(0, -90, 0), size = 0.02, draw_func = nil}
}
SWEP.WElements = {
	["Yellowbox"] = { type = "Model", model = "models/props_c17/FurnitureFridge001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(8.635, 2.273, -3.5), angle = Angle(-5, -2, 90), size = Vector(0.05, 0.1, 0.029), color = Color(255, 255, 0, 255), surpresslightning = false, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["Yellowbox+"] = { type = "Model", model = "models/props_c17/FurnitureFridge001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "Yellowbox", pos = Vector(-3.182, 0, 0), angle = Angle(0, 0, 0), size = Vector(0.05, 0.1, 0.029), color = Color(255, 255, 0, 255), surpresslightning = false, material = "models/debug/debugwhite", skin = 0, bodygroup = {} },
	["Blackreceiver"] = { type = "Model", model = "models/props_c17/FurnitureWashingmachine001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "Yellowbox", pos = Vector(-3, 0, -0.201), angle = Angle(0, -90, 90), size = Vector(0.119, 0.057, 0.3), color = Color(0, 0, 0, 255), surpresslightning = false, material = "phoenix_storms/stripes", skin = 0, bodygroup = {} }
}


--IN-HEAD VIEW

net.Receive("tazestartview", function()
	local rag = net.ReadEntity()
	LocalPlayer().viewrag = rag
end)
net.Receive("tazeendview", function()
	LocalPlayer().viewrag = nil
end)

hook.Add("PlayerBindPress", "Tazer", function(ply,bind,pressed)
	if IsValid(ply:GetNWEntity("tazerviewrag")) and HEALRAY.Thirdperson and HEALRAY.AllowSwitchFromToThirdperson then
		if bind == "+duck" then
			if ply.thirdpersonview == nil then
				ply.thirdpersonview = false
			end
			
			ply.thirdpersonview = not ply.thirdpersonview
			print(ply.thirdpersonview)
		end
	end
end)

local dist = 200
local view = {}
hook.Add("CalcView", "Tazer", function(ply, origin, angles, fov)
	local rag = ply:GetNWEntity("tazerviewrag")
	if IsValid(rag) then
		local bid = rag:LookupBone("ValveBiped.Bip01_Head1")
		if bid then
			local dothirdperson = false
			if HEALRAY.Thirdperson then
				if HEALRAY.AllowSwitchFromToThirdperson then
					dothirdperson = ply.thirdpersonview
				else
					dothirdperson = true
				end
			end
			
			if dothirdperson then
				local ragpos = rag:GetBonePosition(bid)
				
				local pos = ragpos - (ply:GetAimVector()*dist)
				local ang = (ragpos - pos):Angle()
				
				--Do a traceline so he can't see through walls
				local trdata = {}
				trdata.start = ragpos
				trdata.endpos = pos
				trdata.filter = rag
				local trres = util.TraceLine(trdata)
				if trres.Hit then
					pos = trres.HitPos + (trres.HitWorld and trres.HitNormal * 3 or vector_origin)
				end
				
				view.origin = pos
				view.angles = ang
			else
				local pos,ang = rag:GetBonePosition(bid)
				pos = pos + ang:Forward() * 7
				ang:RotateAroundAxis(ang:Up(), -90)
				ang:RotateAroundAxis(ang:Forward(), -90)
				pos = pos + ang:Forward() * 1
				
				view.origin = pos
				view.angles = ang
			end
			
			return view
		end
	end
end)


--CROSSHAIR


local col1 = Color(0,150,0,255)
local col2 = Color(150,0,0,255)
local w,h = ScrW(), ScrH()
local w2,h2 = w/2,h/2
function SWEP:DrawHUD()
	if LocalPlayer() ~= self.Owner then return end -- Not sure why this would happen but you never know.
	if HEALRAY.IsTTT and GetConVar("ttt_disable_crosshair"):GetBool() then return end -- If a TTT player wants it disabled, so be it.
	
	--Small delay so we don't spam the shit out of the player.
	if not self.trres or self.nexttr < CurTime() then
		self.trres = util.TraceLine(util.GetPlayerTrace(LocalPlayer()))
		self.nexttr = CurTime() + .05
	end
	
	local hit = self.trres.HitPos:Distance(LocalPlayer():GetShootPos()) <= self.Range and (IsValid(self.trres.Entity) and self.trres.Entity:IsPlayer())

	surface.SetDrawColor(hit and col1 or col2)
	
	local gap = (hit and 0 or 10) + 5
	local length = 10
	 
	surface.DrawLine( w2 - length, h2, w2 - gap, h2 )
	surface.DrawLine( w2 + length, h2, w2 + gap, h2 )
	surface.DrawLine( w2, h2 - length, w2, h2 - gap )
	surface.DrawLine( w2, h2 + length, w2, h2 + gap )
end


--TARGET ID

--Stops targetids from drawing in darkrp. TTT sadly has no hook like this.
hook.Add("HUDShouldDraw", "Tazer", function(hud)
	if hud == "DarkRP_EntityDisplay" then
		local p = {}
		local edited = false
		for k,v in pairs(player.GetAll()) do
			if not IsValid(v:GetNWEntity("tazerviewrag")) then
				table.insert(p, v)
			else
				edited = true
			end
		end
		
		if edited then -- Only override if we actually done something. So others have a chance.
			return true, p
		end
	end
end)

local function IsOnScreen(pos)
	return pos.x > 0 and pos.x < w and pos.y > 0 and pos.y < h
end

local function GrabPlyInfo(ply)
	if HEALRAY.IsTTT then
		local text, color
		if ply:GetNWBool("disguised", false) then
			 if LocalPlayer():IsTraitor() or LocalPlayer():IsSpec() then
					text = ply:Nick() .. LANG.GetUnsafeLanguageTable().target_disg
			 else
					-- Do not show anything
					return
			 end

			 color = COLOR_RED
		else
			 text = ply:Nick()
		end
		
		return text, (color or COLOR_WHITE), "TargetID"
	--[[ elseif HEALRAY.IsDarkRP then
		return ply:Nick(), (team.GetColor(ply:Team()) or Color(255,255,255)), "DarkRPHUD2" ]]
	else
		return ply:Nick(), (team.GetColor(ply:Team()) or Color(255,255,255)), "TargetID"
	end
end

hook.Add("HUDPaint", "Tazer", function()
	--Draws info about crouch able to switch between third and firstperson
	if HEALRAY.Thirdperson and HEALRAY.AllowSwitchFromToThirdperson and IsValid(LocalPlayer():GetNWEntity("tazerviewrag")) then
		local txt = string.format("Press %s to switch between third and firstperson view.", input.LookupBinding("+duck"))
		draw.SimpleText(txt, "TargetID", ScrW()/2 + 1, 10 + 1, Color(0,0,0,255), 1)
		draw.SimpleText(txt, "TargetID", ScrW()/2, 10, Color(200,200,200,255), 1)
	end
	
	--Draws custom targetids on rags
	if not HEALRAY.ShowPlayerInfo then return end
	
	local targ = LocalPlayer():GetEyeTrace().Entity
	if IsValid(targ) and IsValid(targ:GetNWEntity("plyowner")) and LocalPlayer():GetPos():Distance(targ:GetPos()) < 400 then
		local pos = targ:GetPos():ToScreen()
		if IsOnScreen(pos) then
			local ply = targ:GetNWEntity("plyowner")
			local nick,nickclr,font = GrabPlyInfo(ply)
			if not nick then return end -- Someone doesn't want us to draw his info.
			
			draw.DrawText(nick, font, pos.x-1, pos.y - 51, Color(0,0,0), 1)
			draw.DrawText(nick, font, pos.x, pos.y - 50, nickclr, 1)
			
			local hp = (ply.newhp and ply.newhp or ply:Health())
			if HEALRAY.IsTTT then
				local txt,clr = util.HealthToString(hp) -- Grab TTT Data
				txt = LANG.GetUnsafeLanguageTable()[txt] -- Convert to whatever language
				draw.DrawText(txt, "TargetIDSmall2", pos.x-1, pos.y - 31, Color(0,0,0), 1)
				draw.DrawText(txt, "TargetIDSmall2", pos.x, pos.y - 30, clr, 1)
			
			else
				local txt = hp.."%"
				
				draw.DrawText(txt, "TargetID", pos.x-1, pos.y - 31, Color(0,0,0), 1)
				draw.DrawText(txt, "TargetID", pos.x, pos.y - 30, Color(255,255,255,200), 1)
			end
		end
	end
end)

--For some reason, when they're ragdolled their hp isn't sent properly to the clients.
net.Receive("tazersendhealth", function()
	local ent = net.ReadEntity()
	local newhp = net.ReadInt(32)
	ent.newhp = newhp
end)

--[[ /********************************************************
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378
********************************************************/ ]]

local boltpositions
local boltcount
local poly
local glowtimer = 0

local bolt1 = Material("stungun/lightningbolt.png")
local bolt1_o = Material("stungun/lightningbolt_outline.png")
local bolt1_g = Material("stungun/lightningbolt_glow.png")
local bolt2 = Material("stungun/lightningbolt2.png")
function SWEP:DrawScreen(x, y, w, h)
	local frac = (self.Charge or 0) / 100
	local fracinv = 1 - frac
	
	if frac >= 1 then glowtimer = glowtimer + 1 else glowtimer = 0 end
	
	local bx, by = x + w/2 - 16, y + h/2 - 32 + 10
	if not poly then
		--[[ /*
		Setup boltpositions
		*/ ]]
		boltpositions = {}
		local v
		local a
		for i=-30,30,14 do
			v = Vector(0,by - 25,0)
			a = Angle(0,i,0)
			v:Rotate(a)
			
			table.insert(boltpositions, {pos = v, ang = a})
		end
		boltcount = #boltpositions
		
		--[[ /*
		Setup polygon
		*/ ]]
		poly = {{
			x = bx,
			y = by + (fracinv * 64),
			u = 0,
			v = fracinv
		},{
			x = bx + 32,
			y = by + (fracinv * 64),
			u = 1,
			v = fracinv
		},{
			x = bx + 32,
			y = by + 64,
			u = 1,
			v = 1
		},{
			x = bx,
			y = by + 64,
			u = 0,
			v = 1
		}}
	end
	
	
	--[[ /*
	Bolt fill
	*/ ]]
	surface.SetDrawColor(Color(255,255,255,255))
	surface.SetMaterial(bolt1)
	
	poly[1].y = by + (fracinv * 64)
	poly[1].v = fracinv
	poly[2].y = poly[1].y
	poly[2].v = poly[1].v
	
	surface.DrawPoly(poly)
	
	--[[ /*
	Bolt outline
	*/ ]]
	surface.SetMaterial(bolt1_o)
	surface.DrawTexturedRect(bx, by, 32, 64)
	
	--[[ /*
	Small bolts
	*/ ]]
	surface.SetMaterial(bolt2)
	
	local a
	for k,v in pairs(boltpositions) do
		a = math.Clamp((frac * (254 * boltcount)) - (254*(k-1)), 0, 254)
		
		surface.SetDrawColor(Color(0,0,255,a + 1))
		surface.DrawTexturedRectRotated(v.pos.x + (x + w/2), v.pos.y, 16, 32, -(v.ang.y))
	end
	
	--[[ /*
	Bolt glow
	*/ ]]
	surface.SetDrawColor(Color(255,255,255,math.cos(glowtimer/40 + math.pi) * 50 + 50))
	surface.SetMaterial(bolt1_g)
	surface.DrawTexturedRect(bx-16, by-32, 64, 128)
end

function SWEP:Initialize()
	-- Create a new table for every weapon instance
	self.VElements = table.FullCopy( self.VElements )
	self.WElements = table.FullCopy( self.WElements )
	self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

	self:CreateModels(self.VElements) -- create viewmodels
	self:CreateModels(self.WElements) -- create worldmodels
	
	-- init view model bone build function
	--[[ /*if IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
			vm:DrawShadow( false )
			vm:SetMaterial( "models/effects/vol_light001" )
			vm:SetRenderMode( RENDERMODE_TRANSALPHA )
		end
	end*/ ]]
	
	self.VElements["counter"].draw_func = function()
		self:DrawScreen(-27,-65,65,123)
	end
end

function SWEP:Holster()
	return true
end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)

	return true
end

function SWEP:OnRemove()
	self:Holster()
end

function SWEP:OnDrop()
	self:Holster()
end

net.Receive("tazerondrop",function()
	local swep = net.ReadEntity()
	swep:OnDrop()
end)

SWEP.vRenderOrder = nil
function SWEP:ViewModelDrawn()
	
	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then return end
	
	if (not self.VElements) then return end
	
	self:UpdateBonePositions(vm)

	if (not self.vRenderOrder) then
		
		-- we build a render order because sprites need to be drawn after models
		self.vRenderOrder = {}

		for k, v in pairs( self.VElements ) do
			if (v.type == "Model") then
				table.insert(self.vRenderOrder, 1, k)
			elseif (v.type == "Sprite" or v.type == "Quad") then
				table.insert(self.vRenderOrder, k)
			end
		end
		
	end

	for k, name in ipairs( self.vRenderOrder ) do
	
		local v = self.VElements[name]
		if (not v) then self.vRenderOrder = nil break end
		if (v.hide) then continue end
		
		local model = v.modelEnt
		local sprite = v.spriteMaterial
		
		if (!v.bone) then continue end
		
		local pos, ang = self:GetBoneOrientation( self.VElements, v, vm )
		
		if (!pos) then continue end
		
		if (v.type == "Model" and IsValid(model)) then

			model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)

			model:SetAngles(ang)
			--model:SetModelScale(v.size)
			local matrix = Matrix()
			matrix:Scale(v.size)
			model:EnableMatrix( "RenderMultiply", matrix )
			
			if (v.material == "") then
				model:SetMaterial("")
			elseif (model:GetMaterial() ~= v.material) then
				model:SetMaterial( v.material )
			end
			
			if (v.skin and v.skin ~= model:GetSkin()) then
				model:SetSkin(v.skin)
			end
			
			if (v.bodygroup) then
				for k, v in pairs( v.bodygroup ) do
					if (model:GetBodygroup(k) ~= v) then
						model:SetBodygroup(k, v)
					end
				end
			end
			
			if (v.surpresslightning) then
				render.SuppressEngineLighting(true)
			end
			
			render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
			render.SetBlend(v.color.a/255)
			model:DrawModel()
			render.SetBlend(1)
			render.SetColorModulation(1, 1, 1)
			
			if (v.surpresslightning) then
				render.SuppressEngineLighting(false)
			end
			
		elseif (v.type == "Sprite" and sprite) then
			
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			render.SetMaterial(sprite)
			render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			
		elseif (v.type == "Quad" and v.draw_func) then
			
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
			
			cam.Start3D2D(drawpos, ang, v.size)
				v.draw_func( self )
			cam.End3D2D()

		end
		
	end
	
end

SWEP.wRenderOrder = nil
function SWEP:DrawWorldModel()
	--Fixes worldmodel being seen in firstperson spectating
	local viewent = LocalPlayer():GetObserverTarget()
	if IsValid(viewent) and viewent ~= LocalPlayer() and viewent == self.Owner then
		return
	end
	
	if (self.ShowWorldModel == nil or self.ShowWorldModel) then
		self:DrawModel()
	end
	
	if (!self.WElements) then return end
	
	if (!self.wRenderOrder) then

		self.wRenderOrder = {}

		for k, v in pairs( self.WElements ) do
			if (v.type == "Model") then
				table.insert(self.wRenderOrder, 1, k)
			elseif (v.type == "Sprite" or v.type == "Quad") then
				table.insert(self.wRenderOrder, k)
			end
		end

	end
	
	if (IsValid(self.Owner)) then
		bone_ent = self.Owner
	else
		-- when the weapon is dropped
		bone_ent = self
	end
	
	for k, name in pairs( self.wRenderOrder ) do
	
		local v = self.WElements[name]
		if (!v) then self.wRenderOrder = nil break end
		if (v.hide) then continue end
		
		local pos, ang
		
		if (v.bone) then
			pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
		else
			pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
		end
		
		if (!pos) then continue end
		
		local model = v.modelEnt
		local sprite = v.spriteMaterial
		
		if (v.type == "Model" and IsValid(model)) then

			model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)

			model:SetAngles(ang)
			--model:SetModelScale(v.size)
			local matrix = Matrix()
			matrix:Scale(v.size)
			model:EnableMatrix( "RenderMultiply", matrix )
			
			if (v.material == "") then
				model:SetMaterial("")
			elseif (model:GetMaterial() != v.material) then
				model:SetMaterial( v.material )
			end
			
			if (v.skin and v.skin != model:GetSkin()) then
				model:SetSkin(v.skin)
			end
			
			if (v.bodygroup) then
				for k, v in pairs( v.bodygroup ) do
					if (model:GetBodygroup(k) != v) then
						model:SetBodygroup(k, v)
					end
				end
			end
			
			if (v.surpresslightning) then
				render.SuppressEngineLighting(true)
			end
			
			render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
			render.SetBlend(v.color.a/255)
			model:DrawModel()
			render.SetBlend(1)
			render.SetColorModulation(1, 1, 1)
			
			if (v.surpresslightning) then
				render.SuppressEngineLighting(false)
			end
			
		elseif (v.type == "Sprite" and sprite) then
			
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			render.SetMaterial(sprite)
			render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			
		elseif (v.type == "Quad" and v.draw_func) then
			
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
			
			cam.Start3D2D(drawpos, ang, v.size)
				v.draw_func( self )
			cam.End3D2D()

		end
		
	end
	
end

function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
	
	local bone, pos, ang
	if (tab.rel and tab.rel != "") then
		
		local v = basetab[tab.rel]
		
		if (!v) then return end
		
		-- Technically, if there exists an element with the same name as a bone
		-- you can get in an infinite loop. Let's just hope nobody's that stupid.
		pos, ang = self:GetBoneOrientation( basetab, v, ent )
		
		if (!pos) then return end
		
		pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
		ang:RotateAroundAxis(ang:Up(), v.angle.y)
		ang:RotateAroundAxis(ang:Right(), v.angle.p)
		ang:RotateAroundAxis(ang:Forward(), v.angle.r)
			
	else
	
		bone = ent:LookupBone(bone_override or tab.bone)

		if (!bone) then return end
		
		pos, ang = Vector(0,0,0), Angle(0,0,0)
		local m = ent:GetBoneMatrix(bone)
		if (m) then
			pos, ang = m:GetTranslation(), m:GetAngles()
		end
		
		if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
			ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
			ang.r = -ang.r -- Fixes mirrored models
		end
	
	end
	
	return pos, ang
end

function SWEP:CreateModels( tab )

	if (!tab) then return end

	-- Create the clientside models here because Garry says we can't do it in the render hook
	for k, v in pairs( tab ) do
		if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and 
				string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
			
			v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
			if (IsValid(v.modelEnt)) then
				v.modelEnt:SetPos(self:GetPos())
				v.modelEnt:SetAngles(self:GetAngles())
				v.modelEnt:SetParent(self)
				v.modelEnt:SetNoDraw(true)
				v.createdModel = v.model
			else
				v.modelEnt = nil
			end
			
		elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite) 
			and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
			
			local name = v.sprite.."-"
			local params = { ["$basetexture"] = v.sprite }
			-- make sure we create a unique name based on the selected options
			local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
			for i, j in pairs( tocheck ) do
				if (v[j]) then
					params["$"..j] = 1
					name = name.."1"
				else
					name = name.."0"
				end
			end

			v.createdSprite = v.sprite
			v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
			
		end
	end
	
end

local allbones
local hasGarryFixedBoneScalingYet = false

function SWEP:UpdateBonePositions(vm)
	
	if self.ViewModelBoneMods then
		
		if (!vm:GetBoneCount()) then return end
		
		-- !! WORKAROUND !! --
		-- We need to check all model names :/
		local loopthrough = self.ViewModelBoneMods
		if (!hasGarryFixedBoneScalingYet) then
			allbones = {}
			for i=0, vm:GetBoneCount() do
				local bonename = vm:GetBoneName(i)
				if (self.ViewModelBoneMods[bonename]) then 
					allbones[bonename] = self.ViewModelBoneMods[bonename]
				else
					allbones[bonename] = { 
						scale = Vector(1,1,1),
						pos = Vector(0,0,0),
						angle = Angle(0,0,0)
					}
				end
			end
			
			loopthrough = allbones
		end
		-- !! ----------- !! --
		
		for k, v in pairs( loopthrough ) do
			local bone = vm:LookupBone(k)
			if (!bone) then continue end
			
			-- !! WORKAROUND !! --
			local s = Vector(v.scale.x,v.scale.y,v.scale.z)
			local p = Vector(v.pos.x,v.pos.y,v.pos.z)
			local ms = Vector(1,1,1)
			if (!hasGarryFixedBoneScalingYet) then
				local cur = vm:GetBoneParent(bone)
				while(cur >= 0) do
					local pscale = loopthrough[vm:GetBoneName(cur)].scale
					ms = ms * pscale
					cur = vm:GetBoneParent(cur)
				end
			end
			
			s = s * ms
			-- !! ----------- !! --
			
			if vm:GetManipulateBoneScale(bone) != s then
				vm:ManipulateBoneScale( bone, s )
			end
			if vm:GetManipulateBoneAngles(bone) != v.angle then
				vm:ManipulateBoneAngles( bone, v.angle )
			end
			if vm:GetManipulateBonePosition(bone) != p then
				vm:ManipulateBonePosition( bone, p )
			end
		end
	else
		self:ResetBonePositions(vm)
	end
		 
end
 
function SWEP:ResetBonePositions(vm)
	
	if (!vm:GetBoneCount()) then return end
	for i=0, vm:GetBoneCount() do
		vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
		vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
		vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
	end
	
end

/**************************
	Global utility code
**************************/

-- Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
-- Does not copy entities of course, only copies their reference.
-- WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
function table.FullCopy( tab )

	if (!tab) then return nil end
	
	local res = {}
	for k, v in pairs( tab ) do
		if (type(v) == "table") then
			res[k] = table.FullCopy(v) -- recursion ho!
		elseif (type(v) == "Vector") then
			res[k] = Vector(v.x, v.y, v.z)
		elseif (type(v) == "Angle") then
			res[k] = Angle(v.p, v.y, v.r)
		else
			res[k] = v
		end
	end
	
	return res
	
end
