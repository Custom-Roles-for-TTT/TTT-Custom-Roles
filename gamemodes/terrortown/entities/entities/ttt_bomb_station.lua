AddCSLuaFile()

if CLIENT then
    ENT.Icon = "vgui/ttt/icon_bombstation"
    ENT.PrintName = "bstation_name"

    local GetPTranslation = LANG.GetParamTranslation

    ENT.TargetIDHint = {
        name = "hstation_name",
        hint = "hstation_hint",
        fmt  = function(ent, txt)
            return GetPTranslation(txt,
                    { usekey = Key("+use", "USE"),
                      num    = ent:GetStoredHealth() or 0 } )
            end
    };
end

ENT.Type = "anim"
ENT.Model = Model("models/props/cs_office/microwave.mdl")

ENT.CanHavePrints = true
ENT.MaxHeal = 25
ENT.MaxStored = 200
ENT.RechargeRate = 1
ENT.RechargeFreq = 2

ENT.NextHeal = 0
ENT.HealRate = 1
ENT.HealFreq = 0.2

ENT.ExplosionDamage = 1000
ENT.ExplosionRange = 400
ENT.ExplosionTime = 1

ENT.Triggered = false

AccessorFuncDT(ENT, "StoredHealth", "StoredHealth")

AccessorFunc(ENT, "Placer", "Placer")

function ENT:SetupDataTables()
   self:DTVar("Int", 0, "StoredHealth")
end

local explodesound = Sound("c4.explode")

function ENT:Explode()
    if not IsValid(self) then return end

    local pos = self:GetPos()
    local radius = self.ExplosionRange
    local damage = self.ExplosionDamage

    util.BlastDamage( self, self:GetPlacer(), pos, radius, damage )
    local effect = EffectData()
        effect:SetStart(pos)
        effect:SetOrigin(pos)
        effect:SetScale(radius)
        effect:SetRadius(radius)
        effect:SetMagnitude(damage)
    util.Effect("Explosion", effect, true, true)

    sound.Play(explodesound, self:GetPos(), 60, 150)
    self:Remove()
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

    self.NextHeal = 0

    if CLIENT then
        local GetPTranslation = LANG.GetParamTranslation
        if LocalPlayer():IsTraitorTeam() then
            self.TargetIDHint = {
                name = "bstation_name",
                hint = "bstation_hint",
                fmt  = function(ent, txt)
                    return GetPTranslation(txt,
                            { usekey = Key("+use", "USE"),
                              num = self:GetStoredHealth() or 0 } )
                end
            };
        else
            self.TargetIDHint = {
                name = "hstation_name",
                hint = "hstation_hint",
                fmt  = function(ent, txt)
                    return GetPTranslation(txt,
                            { usekey = Key("+use", "USE"),
                              num = self:GetStoredHealth() or 0 } )
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

local beep = Sound("weapons/c4/c4_beep1.wav")

function ENT:Trigger(ply)
    if self.Triggered then return end

    self.Triggered = true

    for i=1,self.ExplosionTime do
        timer.Simple(i-1, function()
            sound.Play(beep, self:GetPos(), 75, 100)
        end)
    end

    timer.Simple(self.ExplosionTime, function()
        self:Explode()
    end)
end

local healsound = Sound("items/medshot4.wav")
local failsound = Sound("items/medshotno1.wav")

local last_sound_time = 0
function ENT:GiveHealth(ply, max_heal)
    if self:GetStoredHealth() > 0 then
        max_heal = max_heal or self.MaxHeal
        local dmg = ply:GetMaxHealth() - ply:Health()

        -- Reduce the number so it appears that it's been used
        self:TakeFromStorage(math.min(max_heal, dmg))

        if last_sound_time + 2 < CurTime() then
            self:EmitSound(healsound)
            last_sound_time = CurTime()
        end

        if ply:IsActiveTraitorTeam() then return end

        self:Trigger(ply)

        return true
    else
        self:EmitSound(failsound)
    end

    return false
end

function ENT:Use(ply)
    if IsPlayer(ply) and ply:IsActive() then
       local t = CurTime()
       if t > self.NextHeal then
            local healed = self:GiveHealth(ply, self.HealRate)
            self.NextHeal = t + (self.HealFreq * (healed and 1 or 2))
        end
    end
end

function ENT:OnTakeDamage(dmginfo)
    if dmginfo:GetAttacker() == self:GetPlacer() then return end

    self:TakePhysicsDamage(dmginfo)

    self:SetHealth(self:Health() - dmginfo:GetDamage())

    local att = dmginfo:GetAttacker()
    local placer = self:GetPlacer()
    if IsPlayer(att) then
        DamageLog(Format("DMG: \t %s [%s] damaged bomb station [%s] for %d dmg", att:Nick(), att:GetRoleString(), IsPlayer(placer) and placer:Nick() or "<disconnected>", dmginfo:GetDamage()))
    end

    if self:Health() < 0 then
        self:Remove()

        util.EquipmentDestroyed(self:GetPos())

        if IsValid(self:GetPlacer()) then
            LANG.Msg(self:GetPlacer(), "bstation_broken")
        end
    end
end