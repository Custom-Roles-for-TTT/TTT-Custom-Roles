---- Health dispenser

AddCSLuaFile()

if CLIENT then
   -- this entity can be DNA-sampled so we need some display info
   ENT.Icon = "vgui/ttt/icon_health"
   ENT.PrintName = "hstation_name"
end

ENT.Type = "anim"
ENT.Model = Model("models/props/cs_office/microwave.mdl")

--ENT.CanUseKey = true
ENT.CanHavePrints = true
ENT.MaxHeal = 25
ENT.MaxStored = 200
ENT.RechargeRate = 1
ENT.RechargeFreq = 2 -- in seconds

ENT.NextHeal = 0
ENT.HealRate = 1
ENT.HealFreq = 0.2

AccessorFuncDT(ENT, "StoredHealth", "StoredHealth")

AccessorFunc(ENT, "Placer", "Placer")

local function ShouldReduceHealth(ply)
    if not ply:Alive() or ply:IsSpec() then return false end

    local role = ply:GetRole()
    if role <= ROLE_NONE or role > ROLE_MAX then return false end

    local rolestring = ROLE_STRINGS_RAW[role]
    local convar = "ttt_" .. rolestring .. "_healthstation_reduce_max"
    return cvars.Bool(convar, false)
end

function ENT:SetupDataTables()
   self:DTVar("Int", 0, "StoredHealth")
end

function ENT:Initialize()
    self:SetModel(self.Model)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_BBOX)

    local b = 32
    self:SetCollisionBounds(Vector(-b, -b, -b), Vector(b,b,b))

    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    if SERVER then
        self:SetMaxHealth(200)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(200)
        end

        self:SetUseType(CONTINUOUS_USE)
    end
    self:SetHealth(200)

    self:SetColor(Color(180, 180, 250, 255))

    self:SetStoredHealth(200)

    self:SetPlacer(nil)

    self.NextHeal = 0

    self.fingerprints = {}

    if CLIENT then
        local GetPTranslation = LANG.GetParamTranslation
        self.TargetIDHint = function()
            local hint = "hstation_hint"
            if ShouldReduceHealth(LocalPlayer()) then
                hint = hint .. "_reduce"
            end

            return {
                name = "hstation_name",
                hint = hint,
                fmt  = function(ent, txt)
                    return GetPTranslation(txt,
                            { usekey = Key("+use", "USE"),
                            num = ent:GetStoredHealth() or 0 } )
                end
            };
        end
    end
end

function ENT:AddToStorage(amount)
    self:SetStoredHealth(math.min(self.MaxStored, self:GetStoredHealth() + amount))
end

function ENT:TakeFromStorage(amount)
    -- if we only have 5 healthpts in store, that is the amount we heal
    amount = math.min(amount, self:GetStoredHealth())
    self:SetStoredHealth(math.max(0, self:GetStoredHealth() - amount))
    return amount
end

local healsound = Sound("items/medshot4.wav")
local failsound = Sound("items/medshotno1.wav")

local last_sound_time = 0
function ENT:GiveHealth(ply, max_heal)
    if self:GetStoredHealth() > 0 then
        max_heal = max_heal or self.MaxHeal
        local dmg = ply:GetMaxHealth() - ply:Health()
        if dmg > 0 then
            -- constant clamping, no risks
            local healed = self:TakeFromStorage(math.min(max_heal, dmg))
            local should_reduce = ShouldReduceHealth(ply)
            if should_reduce then
                local new = math.max(ply:Health(), ply:GetMaxHealth() - healed)
                ply:SetMaxHealth(new)
            else
                local new = math.min(ply:GetMaxHealth(), ply:Health() + healed)
                ply:SetHealth(new)
            end

            hook.Run("TTTPlayerUsedHealthStation", ply, self, healed, should_reduce)

            if last_sound_time + 2 < CurTime() then
                self:EmitSound(healsound)
                last_sound_time = CurTime()
            end

            if not table.HasValue(self.fingerprints, ply) then
                table.insert(self.fingerprints, ply)
            end

            return true
        else
            self:EmitSound(failsound)
        end
    else
        self:EmitSound(failsound)
    end

    return false
end

function ENT:Use(ply)
    if IsValid(ply) and ply:IsPlayer() and ply:IsActive() then
        local t = CurTime()
        if t > self.NextHeal then
            local healed = self:GiveHealth(ply, self.HealRate)

            self.NextHeal = t + (self.HealFreq * (healed and 1 or 2))
        end
    end
end

if SERVER then
    -- recharge
    local nextcharge = 0
    function ENT:Think()
        if nextcharge < CurTime() then
            self:AddToStorage(self.RechargeRate)

            nextcharge = CurTime() + self.RechargeFreq
        end
    end

    local ttt_damage_own_healthstation = CreateConVar("ttt_damage_own_healthstation", "0") -- 0 as detective cannot damage their own health station

    -- traditional equipment destruction effects
    function ENT:OnTakeDamage(dmginfo)
        if dmginfo:GetAttacker() == self:GetPlacer() and not ttt_damage_own_healthstation:GetBool() then return end

        self:TakePhysicsDamage(dmginfo)

        self:SetHealth(self:Health() - dmginfo:GetDamage())

        local att = dmginfo:GetAttacker()
        local placer = self:GetPlacer()
        if IsPlayer(att) then
            DamageLog(Format("DMG: \t %s [%s] damaged bomb station [%s] for %d dmg", att:Nick(), ROLE_STRINGS[att:GetRole()], IsPlayer(placer) and placer:Nick() or "<disconnected>", dmginfo:GetDamage()))
        end

        if self:Health() < 0 then
            self:Remove()

            util.EquipmentDestroyed(self:GetPos())

            if IsValid(self:GetPlacer()) then
                LANG.Msg(self:GetPlacer(), "hstation_broken")
            end
        end
    end
end