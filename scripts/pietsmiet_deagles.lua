if engine.ActiveGamemode() ~= "terrortown" then return end

local function ShootBullet(weap, dmg, onPlayerShot)
    weap:SendWeaponAnim(weap.PrimaryAnim)

    local owner = weap:GetOwner()
    if not IsPlayer(owner) then return end

    owner:MuzzleFlash()
    owner:SetAnimation(PLAYER_ATTACK1)

    if not IsFirstTimePredicted() then return end

    local bullet = {}
    bullet.Num    = 1
    bullet.Src    = owner:GetShootPos()
    bullet.Dir    = owner:GetAimVector()
    bullet.Spread = Vector( 0.02, 0.02, 0 )
    bullet.Force  = 0
    bullet.Damage = dmg
    if SERVER then
        bullet.Callback = function(atk, tr, d)
            local ent = tr.Entity
            if ent:IsPlayer() and ent:IsTerror() then
                onPlayerShot(ent, atk)
                SendFullStateUpdate()
            end
        end
    end

    owner:FireBullets(bullet)
end

hook.Add("PreRegisterSWEP", "PietSmietDeagles_PreRegisterSWEP", function(SWEP, class)
    if not CR_VERSION then return end

    if class == "weapon_ttt_copycatdeagle" then
        function SWEP:ShootBullet(dmg, recoil, numbul, cone)
            ShootBullet(self, dmg, function(ent, atk)
                atk:SetRoleAndBroadcast(ent:GetRole())
                SendFullStateUpdate()
            end)
        end
    elseif class == "weapon_ttt_masterdeagle" then
        function SWEP:ShootBullet(dmg, recoil, numbul, cone)
            ShootBullet(self, dmg, function(ent, atk)
                ent:SetRoleAndBroadcast(atk:GetRole())
                SendFullStateUpdate()
            end)
        end
    end
end)