AddCSLuaFile()

local ipairs = ipairs
local player = player

local GetAllPlayers = player.GetAll

if CLIENT then
    SWEP.PrintName          = "Igniter"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
else
    util.AddNetworkString("TTT_ArsonistIgnited")
end

SWEP.ViewModel              = "models/weapons/v_slam.mdl"
SWEP.WorldModel             = "models/weapons/w_slam.mdl"
SWEP.Weight                 = 2

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "slam"
SWEP.Kind                   = WEAPON_ROLE

SWEP.DeploySpeed            = 4
SWEP.AllowDrop              = false
SWEP.NoSights               = true
SWEP.UseHands               = true
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.Primary.Delay          = 1
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.ClipSize       = -1
SWEP.Primary.ClipMax        = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Sound          = ""

SWEP.Secondary.Delay        = 1.25
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.ClipMax      = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Sound        = ""

SWEP.InLoadoutFor           = {ROLE_ARSONIST}
SWEP.InLoadoutForDefault    = {ROLE_ARSONIST}

if SERVER then
    CreateConVar("ttt_arsonist_early_ignite", "0", FCVAR_NONE, "Whether to allow the arsonist to use their igniter without dousing everyone first", 0, 1)
    CreateConVar("ttt_arsonist_corpse_ignite_time", "10", FCVAR_NONE, "The amount of time (in seconds) to ignite doused dead player corpses for before destroying them", 0, 30)
end

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    if SERVER then
        SetGlobalBool("ttt_arsonist_early_ignite", GetConVar("ttt_arsonist_early_ignite"):GetBool())
    end
    if CLIENT then
        self:AddHUDHelp("arsonistigniter_help_pri", "arsonistigniter_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

function SWEP:PrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if GetRoundState() ~= ROUND_ACTIVE then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    -- Don't ignite if all players aren't doused unless early ignition is enabled
    if not GetGlobalBool("ttt_arsonist_early_ignite", false) and not owner:GetNWBool("TTTArsonistDouseComplete", false) then
        if SERVER then
            local message = "Not all players have been doused in gasoline yet"
            owner:PrintMessage(HUD_PRINTCENTER, message)
            owner:PrintMessage(HUD_PRINTTALK, message)
        end
        return
    end

    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)

    if CLIENT then return end

    local corpseIgniteTime = GetConVar("ttt_arsonist_corpse_ignite_time"):GetInt()
    local igniteCount = 0
    for _, p in ipairs(GetAllPlayers()) do
        if p == owner then continue end
        if p:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED) ~= ARSONIST_DOUSED then continue end

        igniteCount = igniteCount + 1

        -- If the player is dead, try to ignite their ragdoll instead
        if not p:Alive() or p:IsSpec() then
            if corpseIgniteTime > 0 then
                local rag = p.server_ragdoll or p:GetRagdollEntity()
                if IsValid(rag) then
                    rag:Ignite(corpseIgniteTime)
                    timer.Simple(corpseIgniteTime, function()
                        SafeRemoveEntity(rag)
                    end)
                end
            end
            continue
        end

        -- Arbitrarily high number so they burn to death
        p:Ignite(1000)
        -- Normally we would set the inflictor to be the igniter, but since we're destroying it below it won't be valid anymore
        p.ignite_info = {att=owner, infl=owner}

        local message = "You have been ignited by the " .. ROLE_STRINGS[ROLE_ARSONIST] .. "!"
        p:PrintMessage(HUD_PRINTCENTER, message)
        p:PrintMessage(HUD_PRINTTALK, message)

        -- Remove the notification delay timer since the message above already tells them the same thing
        timer.Remove("TTTArsonistNotifyDelay_" .. p:SteamID64())
    end

    local message = "You have set " .. igniteCount .. " player(s) on fire!"
    if igniteCount == 0 then
        message = "No players were doused so your igniter just fizzles out"
    end
    owner:PrintMessage(HUD_PRINTCENTER, message)
    owner:PrintMessage(HUD_PRINTTALK, message)

    -- Log the event
    net.Start("TTT_ArsonistIgnited")
    net.Broadcast()

    -- Set the owner as "complete" so we stop dousing players
    owner:SetNWBool("TTTArsonistDouseComplete", true)
    owner:SetNWString("TTTArsonistDouseTarget", "")
    owner:SetNWFloat("TTTArsonistDouseStartTime", -1)
    self:Remove()
end

function SWEP:DryFire() return false end