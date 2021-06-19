--[[ /*****************
BASIC SECTION
******************/ ]]

--Should it display in thirdperson view for the tazed player? (if false, firstperson)
HEALRAY.Thirdperson = true

--If above is true, should users be able to press crouch button (default ctrl) to switch between third and firstperson?
HEALRAY.AllowSwitchFromToThirdperson = true

--Should people be able to pick a tazed player using physgun?
HEALRAY.AllowPhysgun = false

--Should people be able to use toolgun on tazed players?
HEALRAY.AllowToolgun = false

--Should tazed players take falldamage? (Warning: experimental, not recommended to have if players can pick them up using physgun.)
HEALRAY.Falldamage = true

--Should it display name and HP on tazed players?
HEALRAY.ShowPlayerInfo = true

--Can the player be damaged while he's tazed?
HEALRAY.AllowDamage = true

--Can the player suicide while he's paralyzed?
HEALRAY.ParalyzeAllowSuicide = false

--Can the player suicide while he's mute?
HEALRAY.MuteAllowSuicide = false

--Amount of seconds the player is immune to stuns after he just got up from being paralyzed. -1 to disable.
HEALRAY.Immunity = 3

--Can people of same team stungun each other? Check further below (in the advanced section) for the check-function.
--The check function is by default set to ignore police trying to taze police.
HEALRAY.AllowFriendlyFire = false

--Thirdperson holdtype. Put "revolver" to make him carry the gun in 2 hands, put "pistol" to make him one-hand the gun.
SWEP.HoldType = "revolver"

--Default charge for the weapon, when the guy picks the gun up, should it be filled already or wait to be filled? 100 is max charge, 0 is uncharged.
SWEP.Charge = 100

--Should we have infinite ammo (true) or finite ammo (false)?
--Finite ammo makes it spawn with 1 charge, unless you're running TTT in which you can specify how much ammo it should start with down below.
SWEP.InfiniteAmmo = false

--Recharge rate. How many seconds it takes to fill the gun back up.
SWEP.RechargeTime = 1

--How long range the weapon has. Players beyond this range won't get hit.
--To put in perspective, in darkrp, the above-head-playerinfo has a default range of 400.
SWEP.Range = 800

--[[ /*
There's two seperate times for this. This is so the person has a chance to escape but the robbers still have a chance to re-taze him.
Put the paralyzetime and mutetime at same to make the person able to talk exactly when he's able to get up.
Put the mutetime slightly higher than paralyze time to make him wait a few seconds before he's able to talk after he got up.
*/ ]]

--How many seconds the person is paralyzed = Unable to move.
HEALRAY.ParalyzedTime = 10

--How many seconds the person is mute/gagged = Unable to speak/chat.
HEALRAY.MuteTime = 0

--What teams are immune to the stungun? (if any).
local immuneteams = {
	TEAM_MAYOR, 
	TEAM_CHIEF
}

--[[ /*****************
ADVANCED SECTION
Contact me if you need help with any function.
******************/ ]]


--Hurt sounds

local combinemodels = {["models/player/police.mdl"] = true, ["models/player/police_fem.mdl"] = true}
local females = {
	["models/player/alyx.mdl"] = true,["models/player/p2_chell.mdl"] = true,
	["models/player/mossman.mdl"] = true,["models/player/mossman_arctic.mdl"] = true}
function HEALRAY.PlayHurtSound( ply )
	local mdl = ply:GetModel()
	
	--Combine
	if combinemodels[mdl] or string.find(mdl, "combine") then
		return "npc/combine_soldier/pain"..math.random(1,3)..".wav"
	end
	
	--Female
	if females[mdl] or string.find(mdl, "female") then
		return "vo/npc/female01/pain0"..math.random(1,9)..".wav"
	end
	
	--Male
	return "vo/npc/male01/pain0"..math.random(1,9)..".wav"
end


--Custom same-team function.

function HEALRAY.SameTeam(ply1, ply2)
	if HEALRAY.IsDarkRP then
		--Casesensitivity is a bitch. Backwards compatibility
		if ply1.isCP then
			if ply1:isCP() and ply2:isCP() then return true end
		elseif ply1.IsCP then
			if ply1:IsCP() and ply2:IsCP() then return true end
		end
	end
	
	--return (ply1:Team() == ply2:Team()) -- Probably dont want this in DarkRP, nor TTT, but maybe your custom TDM gamemode.
end


--Custom Immunity function.

function HEALRAY.IsPlayerImmune(ply)
	if type(immuneteams) == "table" and table.HasValue(immuneteams, ply:Team()) then return true end
	return false
end


--[[ /*****************
DarkRP Specific stuff
Only care about these if you're running it on a DarkRP server.
******************/ ]]

--Should the stungun charges be buyable in the f4 store?
--If yes, put in a number above 0 as price, if no, put -1 to disable.
HEALRAY.AddAmmoItem = 50

--[[ /*****************
TTT Specific stuff
Only care about these if you're running it on a TTT server.
******************/ ]]

--Can stunned players be picked up by magnetostick?
SWEP.CanPickup = false

--Default ammo.
local charges = 3

if ConVarExists("ttt_doctor_hot_charges") then
	charges = GetConVar("ttt_doctor_hot_charges"):GetInt()
end
print(">>> HoT Charges: " .. charges)
SWEP.Ammo = charges

--Kind specifies the category this weapon is in. Players can only carry one of
--each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
--Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_EQUIP1

--If AutoSpawnable is true and SWEP.Kind is not WEAPON_EQUIP1/2, then this gun can
--be spawned as a random weapon.
SWEP.AutoSpawnable = false

--CanBuy is a table of ROLE_* entries like ROLE_TRAITOR and ROLE_DETECTIVE. If
--a role is in this table, those players can buy this.
SWEP.CanBuy = { }

--InLoadoutFor is a table of ROLE_* entries that specifies which roles should
--receive this weapon as soon as the round starts. In this case, none.
SWEP.InLoadoutFor = {  }

--If LimitedStock is true, you can only buy one per round.
SWEP.LimitedStock = false

--If AllowDrop is false, players can't manually drop the gun with Q
SWEP.AllowDrop = true
