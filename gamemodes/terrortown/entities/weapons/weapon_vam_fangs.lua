AddCSLuaFile()

local ents = ents
local hook = hook
local IsValid = IsValid
local math = math
local net = net
local player = player
local timer = timer
local util = util

local CreateEntity = ents.Create

if CLIENT then
    SWEP.PrintName = "Fangs"
    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Left-click to suck blood. Right-click to fade."
    };

    SWEP.Slot = 8 -- add 1 to get the slot number key
    SWEP.ViewModelFOV = 54
    SWEP.ViewModelFlip = false
    SWEP.UseHands = true
else
    util.AddNetworkString("TTT_Vampified")
    util.AddNetworkString("TTT_Vampire_Fade")
end

SWEP.InLoadoutFor = { ROLE_VAMPIRE }

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.HoldType = "knife"

SWEP.ViewModel = Model("models/weapons/cstrike/c_knife_t.mdl")
SWEP.WorldModel = Model("models/weapons/w_knife_t.mdl")

SWEP.Primary.Ammo = "fade"
SWEP.Primary.ClipSize = 100
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = false

SWEP.Secondary.Automatic = false

SWEP.Kind = WEAPON_ROLE
SWEP.LimitedStock = false
SWEP.AllowDrop = false

SWEP.TargetEntity = nil
SWEP.TargetEntityChatWarned = false
SWEP.TargetEntityVoiceWarned = false

local STATE_ERROR = -1
local STATE_NONE = 0
local STATE_EAT = 1
local STATE_DRAIN = 2
local STATE_CONVERT = 3
local STATE_KILL = 4

local beep = Sound("npc/fast_zombie/fz_alert_close1.wav")

local vampire_convert_enabled = CreateConVar("ttt_vampire_convert_enabled", "0", FCVAR_REPLICATED, "Whether vampires have the ability to convert living targets to a vampire thrall using their fangs", 0, 1)
local vampire_drain_enabled = CreateConVar("ttt_vampire_drain_enabled", "1", FCVAR_REPLICATED, "Whether vampires have the ability to drain a living target's blood using their fangs", 0, 1)
local vampire_drain_first = CreateConVar("ttt_vampire_drain_first", "0", FCVAR_REPLICATED, "Whether vampires should drain a living target's blood first rather than converting first", 0, 1)
local vampire_prime_only_convert = CreateConVar("ttt_vampire_prime_only_convert", "1", FCVAR_REPLICATED, "Whether only prime vampires (e.g. players who spawn as vampire originally) are allowed to convert other players", 0, 1)
local vampire_drop_bones = CreateConVar("ttt_vampire_drop_bones", "1", FCVAR_REPLICATED, "Whether vampires should drop bones when draining a player or a corpse", 0, 1)

if SERVER then
    CreateConVar("ttt_vampire_drain_credits", "0", FCVAR_NONE, "How many credits a vampire should get for draining a living target", 0, 10)
    CreateConVar("ttt_vampire_drain_mute_target", "0", FCVAR_NONE, "Whether players being drained by a vampire should be muted", 0, 1)
    CreateConVar("ttt_vampire_fang_dead_timer", "0", FCVAR_NONE, "The amount of time fangs must be used to fully drain a dead target's blood. Set to 0 to use the same time as \"ttt_vampire_fang_timer\"", 0, 30)
    CreateConVar("ttt_vampire_fang_timer", "5", FCVAR_NONE, "The amount of time fangs must be used to fully drain a target's blood", 0, 30)
    CreateConVar("ttt_vampire_fang_heal", "50", FCVAR_NONE, "The amount of health a vampire will heal by when they fully drain a target's blood", 0, 100)
    CreateConVar("ttt_vampire_fang_overheal", "25", FCVAR_NONE, "The amount over the vampire's normal maximum health (e.g. 100 + this ConVar) that the vampire can heal to by drinking blood", 0, 100)
    CreateConVar("ttt_vampire_fang_overheal_living", "-1", FCVAR_NONE, "The amount of overheal (see \"ttt_vampire_fang_overheal\") to give if the vampire's target is living. Set to -1 to use the same amount as \"ttt_vampire_fang_overheal\" instead", -1, 100)
    CreateConVar("ttt_vampire_fang_unfreeze_delay", "2", FCVAR_NONE, "The number of seconds before players who were frozen in place by the fangs should be released if the vampire stops using the fangs on them", 0, 15)
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "FangTime")
    self:NetworkVar("Int", 2, "DeadFangTime")
    self:NetworkVar("Float", 0, "StartTime")
    self:NetworkVar("String", 0, "Message")
    self:NetworkVar("Bool", 0, "TargetIsBody")
    if SERVER then
        self:SetFangTime(GetConVar("ttt_vampire_fang_timer"):GetInt())
        self:SetDeadFangTime(GetConVar("ttt_vampire_fang_dead_timer"):GetInt())
        self:Reset()
    end
end

function SWEP:Initialize()
    self.lastTickSecond = 0
    self.fading = false

    if CLIENT then
        self:AddHUDHelp("vam_fangs_help_pri", "vam_fangs_help_sec", true)
    end

    if SERVER then
        if GetConVar("ttt_vampire_drain_mute_target"):GetBool() then
            hook.Add("PlayerCanSeePlayersChat", "Vampire_PlayerCanSeePlayersChat_" .. self:EntIndex(), function(text, team_only, listener, speaker)
                if not IsPlayer(listener) or not IsPlayer(speaker) then return end

                if speaker == self.TargetEntity then
                    if not self.TargetEntityChatWarned then
                        self.TargetEntityChatWarned = true
                        speaker:PrintMessage(HUD_PRINTTALK, "You cannot speak while " .. ROLE_STRINGS_EXT[ROLE_VAMPIRE]  .. " is draining your blood.")
                    end
                    return false
                end
            end)

            hook.Add("PlayerCanHearPlayersVoice", "Vampire_PlayerCanHearPlayersVoice_" .. self:EntIndex(), function(listener, speaker)
                if not IsPlayer(listener) or not IsPlayer(speaker) then return end

                if speaker == self.TargetEntity then
                    if not self.TargetEntityVoiceWarned then
                        self.TargetEntityVoiceWarned = true
                        speaker:PrintMessage(HUD_PRINTTALK, "You cannot speak while " .. ROLE_STRINGS_EXT[ROLE_VAMPIRE]  .. " is draining your blood.")
                    end
                    return false, false
                end
            end)
        end
    end

    return self.BaseClass.Initialize(self)
end

function SWEP:Holster()
    self:FireError()
    return not self.fading
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:OnRemove()
    if IsPlayer(self.TargetEntity) then
        self:CancelUnfreeze(self.TargetEntity)
        self:DoUnfreeze()
    end
    if SERVER then
        self:Reset()
        hook.Remove("PlayerCanSeePlayersChat", "Vampire_PlayerCanSeePlayersChat_" .. self:EntIndex())
        hook.Remove("PlayerCanHearPlayersVoice", "Vampire_PlayerCanHearPlayersVoice_" .. self:EntIndex())
    end
end

function SWEP:CanConvert()
    return vampire_convert_enabled:GetBool() and (not vampire_prime_only_convert:GetBool() or self:GetOwner():IsVampirePrime())
end

local function GetPlayerFromBody(body)
    local ply

    if body.sid64 then
        ply = player.GetBySteamID64(body.sid64)
    elseif body.sid == "BOT" then
        ply = player.GetByUniqueID(body.uqid)
    else
        ply = player.GetBySteamID(body.sid)
    end

    if not IsValid(ply) then return false end

    return ply
end

function SWEP:PrimaryAttack()
    if CLIENT then return end

    local tr = self:GetTraceEntity()
    if IsValid(tr.Entity) then
        local ent = tr.Entity
        if ent:GetClass() == "prop_ragdoll" then
            self:SetTargetIsBody(true)
            local ply = GetPlayerFromBody(ent)
            if not IsValid(ply) or ply:Alive() then
                self:Error("INVALID TARGET")
                return
            end

            self:Eat(tr.Entity)
        elseif ent:IsPlayer() and vampire_drain_enabled:GetBool() then
            self:SetTargetIsBody(false)
            if ent:ShouldActLikeJester() then
                self:Error("TARGET IS A JESTER")
            -- Don't allow draining allies or glitches when the vampire is a traitor
            elseif ent:IsVampireAlly() or (TRAITOR_ROLES[ROLE_VAMPIRE] and ent:IsGlitch()) then
                self:Error("TARGET IS AN ALLY")
            else
                self:Drain(ent)
            end
        end
    end
end

function SWEP:SecondaryAttack()
    if self:Clip1() == 100 then
        self:SetClip1(0)

        if SERVER then
            net.Start("TTT_Vampire_Fade")
                net.WritePlayer(self:GetOwner())
            net.Broadcast()
        end
    end
end

function SWEP:GetFangDuration()
    local fang_time = self:GetDeadFangTime()
    if fang_time <= 0 or self:GetState() ~= STATE_EAT then
        fang_time = self:GetFangTime()
    end
    return fang_time
end

function SWEP:Eat(entity)
    self:GetOwner():EmitSound("weapons/ttt/vampireeat.wav")
    self:SetState(STATE_EAT)
    self:SetStartTime(CurTime())
    self:SetMessage("DRAINING BODY")

    self.TargetEntity = entity

    self:SetNextPrimaryFire(CurTime() + self:GetFangDuration())
end

function SWEP:Drain(entity)
    self:GetOwner():EmitSound("weapons/ttt/vampireeat.wav")
    self:SetState(STATE_DRAIN)
    self:SetStartTime(CurTime())
    self:SetMessage("DRAINING")
    self:CancelUnfreeze(entity)

    entity:QueueMessage(MSG_PRINTCENTER, "Someone is draining your blood!")
    self.TargetEntity = entity
    self:DoFreeze()

    self:SetNextPrimaryFire(CurTime() + self:GetFangDuration())
end

function SWEP:CancelUnfreeze(entity)
    if CLIENT then return end
    if not IsPlayer(entity) then return end
    if not IsValid(self:GetOwner()) then return end
    local timerid = "VampUnfreezeDelay_" .. self:GetOwner():Nick() .. "_" .. entity:Nick()
    if timer.Exists(timerid) then
        self:AdjustFreezeCount(entity, -1, 1)
        timer.Remove(timerid)
    end
end

function SWEP:AdjustFreezeCount(ent, adj, def)
    if CLIENT then return end
    local freeze_count =  math.max(0, ent:GetNWInt("VampireFreezeCount", def) + adj)
    ent:SetNWInt("VampireFreezeCount", freeze_count)
    return freeze_count
end

function SWEP:DoFreeze()
    if CLIENT then return end
    self:AdjustFreezeCount(self.TargetEntity, 1, 0)
    self.TargetEntity:Freeze(true)
end

function SWEP:ResetFreeze()
    if CLIENT then return end
    self.TargetEntity:SetNWInt("VampireFreezeCount", 0)
    self.TargetEntity:Freeze(false)
    self.TargetEntity = nil
end

function SWEP:DoUnfreeze()
    if CLIENT then return end
    local freeze_count = self:AdjustFreezeCount(self.TargetEntity, -1, 1)
    -- Only unfreeze the target if nobody else is draining them
    if freeze_count <= 0 then
        self.TargetEntity:Freeze(false)
    end
    self.TargetEntity:RemoveEFlags(EFL_NO_DAMAGE_FORCES)
    self.TargetEntity = nil
    self.TargetEntityChatWarned = false
    self.TargetEntityVoiceWarned = false
end

function SWEP:DoConvert()
    local ply = self.TargetEntity
    ply:StripRoleWeapons()
    if not ply:HasWeapon("weapon_zm_improvised") then
        ply:Give("weapon_zm_improvised")
    end
    ply:SetVampirePreviousRole(ply:GetRole())
    ply:SetRole(ROLE_VAMPIRE)
    ply:SetVampirePrime(false)
    ply:QueueMessage(MSG_PRINTCENTER, "You have become " .. ROLE_STRINGS_EXT[ROLE_VAMPIRE] .. "! Use your fangs to suck blood or fade from view")

    local owner = self:GetOwner()
    hook.Call("TTTPlayerRoleChangedByItem", nil, owner, ply, self)

    net.Start("TTT_Vampified")
    net.WriteString(ply:Nick())
    net.Broadcast()

    -- Not actually an error, but it resets the things we want
    self:FireError()
    self:ResetFreeze()

    SendFullStateUpdate()
    -- Reset the victim's max health
    SetRoleMaxHealth(ply)
end

function SWEP:DoKill()
    local attacker = self:GetOwner()

    -- Negate the knockback from using a huge damage value
    self.TargetEntity:AddEFlags(EFL_NO_DAMAGE_FORCES)

    local dmginfo = DamageInfo()
    dmginfo:SetDamage(10000)
    dmginfo:SetAttacker(attacker)
    dmginfo:SetInflictor(game.GetWorld())
    dmginfo:SetDamageType(DMG_SLASH)
    dmginfo:SetDamageForce(vector_origin)
    dmginfo:SetDamagePosition(attacker:GetPos())
    self.TargetEntity:TakeDamageInfo(dmginfo)

    -- Cleanup
    timer.Simple(0.25, function()
        if not IsValid(self) then return end
        if not IsPlayer(self.TargetEntity) then return end
        self.TargetEntity:RemoveEFlags(EFL_NO_DAMAGE_FORCES)
    end)

    self:DoHeal(true)
    self:DropBones()

    -- Remove the body
    local rag = self.TargetEntity.server_ragdoll or self.TargetEntity:GetRagdollEntity()
    SafeRemoveEntity(rag)

    local amt = GetConVar("ttt_vampire_drain_credits"):GetInt()
    if amt > 0 then
        LANG.Msg(attacker, "credit_all", { role = ROLE_STRINGS[ROLE_VAMPIRE], num = amt })
        attacker:AddCredits(amt)
    end

    -- Not actually an error, but it resets the things we want
    self:FireError()
end

function SWEP:DoHeal(living)
    local vamoverheal = GetConVar("ttt_vampire_fang_overheal_living"):GetInt()
    if not living or vamoverheal < 0 then
        vamoverheal = GetConVar("ttt_vampire_fang_overheal"):GetInt()
    end

    local vamheal = GetConVar("ttt_vampire_fang_heal"):GetInt()
    local owner = self:GetOwner()
    local health = math.min(owner:Health() + vamheal, owner:GetMaxHealth() + vamoverheal)
    hook.Call("TTTVampireBodyEaten", nil, owner, self.TargetEntity, living, health - owner:Health())
    owner:SetHealth(health)
end

function SWEP:UnfreezeTarget()
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsPlayer(self.TargetEntity) then return end

    self:CancelUnfreeze(self.TargetEntity)

    -- Unfreeze the target immediately if there is no delay or no owner
    local delay = GetConVar("ttt_vampire_fang_unfreeze_delay"):GetFloat()
    if delay <= 0 or not IsPlayer(owner) then
        self:DoUnfreeze()
    else
        timer.Create("VampUnfreezeDelay_" .. owner:Nick() .. "_" .. self.TargetEntity:Nick(), delay, 1, function()
            if not IsPlayer(self.TargetEntity) then return end
            self:DoUnfreeze()
        end)
    end
end

function SWEP:FireError()
    self:SetState(STATE_NONE)
    self:UnfreezeTarget()
    self:SetNextPrimaryFire(CurTime() + 0.1)
end

function SWEP:DropBones()
    if not vampire_drop_bones:GetBool() then return end

    local pos = self.TargetEntity:GetPos()
    local fingerprints = { self:GetOwner() }

    local skull = CreateEntity("prop_physics")
    if not IsValid(skull) then return end
    skull:SetModel("models/Gibs/HGIBS.mdl")
    skull:SetPos(pos)
    skull:Spawn()
    skull:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    skull.fingerprints = fingerprints

    local ribs = CreateEntity("prop_physics")
    if not IsValid(ribs) then return end
    ribs:SetModel("models/Gibs/HGIBS_rib.mdl")
    ribs:SetPos(pos + Vector(0, 0, 15))
    ribs:Spawn()
    ribs:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    ribs.fingerprints = fingerprints

    local spine = CreateEntity("prop_physics")
    if not IsValid(ribs) then return end
    spine:SetModel("models/Gibs/HGIBS_spine.mdl")
    spine:SetPos(pos + Vector(0, 0, 30))
    spine:Spawn()
    spine:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    spine.fingerprints = fingerprints

    local scapula = CreateEntity("prop_physics")
    if not IsValid(scapula) then return end
    scapula:SetModel("models/Gibs/HGIBS_scapula.mdl")
    scapula:SetPos(pos + Vector(0, 0, 45))
    scapula:Spawn()
    scapula:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    scapula.fingerprints = fingerprints
end

function SWEP:Think()
    if CLIENT then return end

    if (CurTime() - self.lastTickSecond > 0.08) and (self:Clip1() <= 100) then
        self:SetClip1(self:Clip1() + math.min(1, 100 - self:Clip1()))
        self.lastTickSecond = CurTime()
    end

    local owner = self:GetOwner()
    if self:Clip1() < 15 and not self.fading then
        self.fading = true
        owner:SetColor(Color(255, 255, 255, 0))
        owner:SetMaterial("sprites/heatwave")
        owner:EmitSound("weapons/ttt/fade.wav")
        hook.Call("TTTVampireInvisibilityChange", nil, owner, true)
    elseif self:Clip1() >= 40 and self.fading then
        self.fading = false
        owner:SetColor(COLOR_WHITE)
        owner:SetMaterial("")
        owner:EmitSound("weapons/ttt/unfade.wav")
        hook.Call("TTTVampireInvisibilityChange", nil, owner, false)
    end

    if self:GetState() >= STATE_EAT then
        if not IsValid(owner) then
            self:FireError()
            return
        end

        local tr = self:GetTraceEntity()
        if not owner:KeyDown(IN_ATTACK) or tr.Entity ~= self.TargetEntity then
            -- Only allow doing the 1/2 progress actions if there are 2 actions enabled (e.g. drain and convert)
            if self:CanConvert() and IsPlayer(self.TargetEntity) and not self.TargetEntity:IsVampire() then
                if self:GetState() == STATE_KILL then
                    self:DoKill()
                    return
                elseif self:GetState() == STATE_CONVERT then
                    self:DoConvert()
                    return
                end
            end

            self:Error("DRAINING ABORTED")
            return
        end

        -- If there is a target and they have been turned to a vampire by someone else, stop trying to drain them
        if self:GetState() ~= STATE_EAT and (not IsPlayer(self.TargetEntity) or self.TargetEntity:IsVampire()) then
            self:Error("DRAINING ABORTED")
            return
        end

        if self:GetState() ~= STATE_DRAIN then
            if CurTime() >= self:GetStartTime() + self:GetFangDuration() then
                -- These seem backwards, but it's due to how the state tracking works.
                -- The "in-progress" state of killing a player is STATE_CONVERT because
                -- when "ttt_vampire_drain_first" is not enabled, the player will be "converting" until the very end.
                -- Therefore, the state will be STATE_CONVERT even though the end intent is to kill.
                -- When "ttt_vampire_drain_first" is enabled, the player will be "killing" until the very end.
                -- Therefore, the state will be STATE_KILL even though the end intent is to convert.
                -- Of course we also have to check that this vampire can actually convert and kill the target if they can't.
                if self:GetState() == STATE_CONVERT then
                    self:DoKill()
                elseif self:GetState() == STATE_KILL then
                    if self:CanConvert() then
                        self:DoConvert()
                    else
                        self:DoKill()
                    end
                else
                    self:DropBones()
                    self:DoHeal()
                    SafeRemoveEntity(self.TargetEntity)

                    -- Not actually an error, but it resets the things we want
                    self:FireError()
                end
            end
        else
            if CurTime() >= self:GetStartTime() + (self:GetFangDuration() / 2) then
                local verb = "CONVERT"
                if vampire_drain_first:GetBool() then
                    self:SetState(STATE_KILL)
                    verb = "KILL"
                else
                    self:SetState(STATE_CONVERT)
                end

                -- Only update the message if this player can convert
                if self:CanConvert() then
                    self:SetMessage("DRAINING - RELEASE TO " .. verb)
                end
            end
        end
    end
end

if CLIENT then
    function SWEP:DrawHUD()
        self.BaseClass.DrawHUD(self)

        local firstVerb
        local secondVerb
        if vampire_drain_first:GetBool() then
            firstVerb = "vam_fangs_kill"
            secondVerb = "vam_fangs_convert"
        else
            firstVerb = "vam_fangs_convert"
            secondVerb = "vam_fangs_kill"
        end

        local progress
        local color
        if self:GetState() == STATE_ERROR then
            progress = 1
            color = Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)
        elseif self:GetState() >= STATE_EAT then
            progress = math.TimeFraction(self:GetStartTime(), self:GetStartTime() + self:GetFangDuration(), CurTime())
            color = Color(0, 255, 0, 155)

            if progress < 0.5 then
                firstVerb = firstVerb .. "ing"
                secondVerb = ""
            else
                secondVerb = secondVerb .. "ing"
            end
        else
            return
        end

        if progress < 0 then return end

        progress = math.Clamp(progress, 0, 1)

        local T = LANG.GetTranslation
        local split = self:CanConvert() and not self:GetTargetIsBody()
        local x = ScrW() / 2.0
        local y = ScrH() / 2.0
        y = y + (y / 3)
        CRHUD:PaintProgressBar(x, y, 255, color, self:GetMessage(), progress, split and 2 or 1, {T(firstVerb), T(secondVerb)})
    end
else
    function SWEP:Reset()
        self:SetState(STATE_NONE)
        self:SetStartTime(-1)
        self:SetMessage('')
        self:SetNextPrimaryFire(CurTime() + 0.1)
    end

    function SWEP:Error(msg)
        self:SetState(STATE_ERROR)
        self:SetStartTime(CurTime())
        self:SetMessage(msg)

        self:GetOwner():EmitSound(beep, 60, 50, 1)
        self:UnfreezeTarget()

        timer.Simple(0.75, function()
            if IsValid(self) then self:Reset() end
        end)
    end

    function SWEP:GetTraceEntity()
        local spos = self:GetOwner():GetShootPos()
        local sdest = spos + (self:GetOwner():GetAimVector() * 70)
        local kmins = Vector(1,1,1) * -10
        local kmaxs = Vector(1,1,1) * 10

        return util.TraceHull({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})
    end
end

if CLIENT then
    net.Receive("TTT_Vampire_Fade", function()
        local ply = net.ReadPlayer()
        if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return end

        local pos = ply:GetPos() + Vector(0, 0, 10)
        local client = LocalPlayer()
        if client:GetPos():Distance(pos) > 1000 then return end

        local emitter = ParticleEmitter(pos)
        for _ = 0, math.random(150, 250) do
            local max_height = ply:GetViewOffset().z + 10
            local height = math.random(0, max_height)

            -- Set width limits based on what the random height is so it vaguely resembles a person-shape (or just their head)
            local width_min = -20
            local width_max = 20

            local location = (height / max_height)
            -- Head
            if location > 0.75 then
                width_min = -5
                width_max = 5
            end

            local partpos = ply:GetPos() + Vector(math.random(width_min, width_max), math.random(width_min, width_max), height)
            local part = emitter:Add("particle/particle_smokegrenade", partpos)
            if part then
                part:SetDieTime(math.random(0.7, 1.2))
                part:SetStartAlpha(math.random(200, 240))
                part:SetEndAlpha(0)
                part:SetColor(math.random(200, 220), math.random(200, 220), math.random(200, 220))

                part:SetStartSize(math.random(6, 8))
                part:SetEndSize(0)

                part:SetRoll(0)
                part:SetRollDelta(0)

                local velocity = VectorRand() * math.random(10, 15);
                velocity.z = 5;
                part:SetVelocity(velocity)
            end
        end

        emitter:Finish()
    end)
end