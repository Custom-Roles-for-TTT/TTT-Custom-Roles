
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ttt_basegrenade_proj"
ENT.Model = Model("models/weapons/w_eq_smokegrenade_thrown.mdl")

AccessorFunc( ENT, "radius", "Radius", FORCE_NUMBER )

function ENT:Initialize()
    if not self:GetRadius() then self:SetRadius(20) end

    return self.BaseClass.Initialize(self)
end

if SERVER then
    CreateConVar("ttt_smokegrenade_extinguish", "1", FCVAR_NONE, "Whether smoke grenades should extinguish fire")
end

if CLIENT then
    local smokeparticles = {
        Model("particle/particle_smokegrenade"),
        Model("particle/particle_noisesphere")
    };

   function ENT:CreateSmoke(center)
        local em = ParticleEmitter(center)

        local r = self:GetRadius()
        for i=1, 20 do
            local prpos = VectorRand() * r
            prpos.z = prpos.z + 32
            local p = em:Add(table.Random(smokeparticles), center + prpos)
            if p then
                local gray = math.random(75, 200)
                p:SetColor(gray, gray, gray)
                p:SetStartAlpha(255)
                p:SetEndAlpha(200)
                p:SetVelocity(VectorRand() * math.Rand(900, 1300))
                p:SetLifeTime(0)

                p:SetDieTime(math.Rand(50, 70))

                p:SetStartSize(math.random(140, 150))
                p:SetEndSize(math.random(1, 40))
                p:SetRoll(math.random(-180, 180))
                p:SetRollDelta(math.Rand(-0.1, 0.1))
                p:SetAirResistance(600)

                p:SetCollide(true)
                p:SetBounce(0.4)

                p:SetLighting(false)
            end
        end

        em:Finish()
    end
end

local extinguish = Sound("extinguish.wav")

function ENT:Explode(tr)
    if SERVER then
        self:SetNoDraw(true)
        self:SetSolid(SOLID_NONE)

        -- pull out of the surface
        if tr.Fraction != 1.0 then
            self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
        end

        -- Extinguish fire that is close enough to the grenade
        if GetConVar("ttt_smokegrenade_extinguish"):GetBool() then
            local target_ents = {"ttt_flame", "env_fire", "_firesmoke"}
            local pos = self:GetPos()
            local entities = ents.FindInSphere(pos, 100)
            local was_extinguished = false
            for _, e in ipairs(entities) do
                local ent_class = e:GetClass()
                if table.HasValue(target_ents, ent_class) then
                    SafeRemoveEntity(e)
                    was_extinguished = true
                    hook.Call("TTTSmokeGrenadeExtinguish", nil, ent_class, pos)
                end
            end

            -- Play a sound if something was extinguished
            if was_extinguished then
                self:EmitSound(extinguish)
            end
        end

        self:Remove()
    else
        local spos = self:GetPos()
        local trs = util.TraceLine({start=spos + Vector(0,0,64), endpos=spos + Vector(0,0,-128), filter=self})
        util.Decal("SmallScorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
        self:SetDetonateExact(0)

        if tr.Fraction != 1.0 then
            spos = tr.HitPos + tr.HitNormal * 0.6
        end

        -- Smoke particles can't get cleaned up when a round restarts, so prevent
        -- them from existing post-round.
        if GetRoundState() == ROUND_POST then return end

        self:CreateSmoke(spos)
    end
end
