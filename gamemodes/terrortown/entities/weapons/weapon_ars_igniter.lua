AddCSLuaFile()

local hook = hook
local player = player
local timer = timer
local util = util

local PlayerIterator = player.Iterator

if CLIENT then
    SWEP.PrintName          = "Igniter"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
else
    util.AddNetworkString("TTT_ArsonistIgnited")
end

SWEP.ViewModel              = "models/weapons/c_slam.mdl"
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

SWEP.Secondary.Delay        = 1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.ClipMax      = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Sound        = ""

SWEP.InLoadoutFor           = {ROLE_ARSONIST}
SWEP.InLoadoutForDefault    = {ROLE_ARSONIST}

local arsonist_early_ignite = GetConVar("ttt_arsonist_early_ignite")
local arsonist_ignite_on_death = CreateConVar("ttt_arsonist_ignite_on_death", "0", FCVAR_REPLICATED, "Whether to allow the arsonist to enable automatic triggering of their igniter on death", 0, 1)
local arsonist_ignite_on_death_timer = CreateConVar("ttt_arsonist_ignite_on_death_timer", "0", FCVAR_REPLICATED, "How long after the arsonist's death to trigger their igniter. Set to 0 to trigger instantly", 0, 180)
local arsonist_ignite_on_death_notify = CreateConVar("ttt_arsonist_ignite_on_death_notify", "1", FCVAR_REPLICATED, "Whether to notify other players that the arsonist's igniter is going to be triggered", 0, 1)
if SERVER then
    CreateConVar("ttt_arsonist_corpse_ignite_time", "10", FCVAR_NONE, "The amount of time (in seconds) to ignite doused dead player corpses for before destroying them", 1, 30)
end

local function NotifyEveryone(message)
    for _, v in PlayerIterator() do
        v:QueueMessage(MSG_PRINTBOTH, message)
    end
end

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    if CLIENT then
        local secondary_name = "arsonistigniter_help_sec"
        if arsonist_ignite_on_death:GetBool() then
            secondary_name = secondary_name .. "_ondeath"
        end
        self:AddHUDHelp("arsonistigniter_help_pri", secondary_name, true)
    elseif arsonist_ignite_on_death:GetBool() then
        hook.Add("PlayerDeath", "Arsonist_Trigger_PlayerDeath_" .. self:EntIndex(), function(ply, infl, att)
            if not IsValid(self) then return end
            -- Don't run this if it hasn't been activated
            if not self:GetOnDeath() then return end

            if not IsPlayer(ply) then return end
            -- We only care if an arsonist has been killed and this igniter has been dropped (no owner)
            if not ply:IsArsonist() or IsValid(self:GetOwner()) then return end
            if ply:IsRoleAbilityDisabled() then return end

            -- Don't ignite if all players aren't doused unless early ignition is enabled
            if not arsonist_early_ignite:GetBool() and not ply:GetNWBool("TTTArsonistDouseComplete", false) then
                ply:QueueMessage(MSG_PRINTBOTH, "Not all players have been doused in gasoline so your igniter does not trigger")
                return
            end

            local death_notify = arsonist_ignite_on_death_notify:GetBool()
            local death_timer = arsonist_ignite_on_death_timer:GetInt()
            if death_timer > 0 then
                if death_notify then
                    NotifyEveryone(string.Capitalize(ROLE_STRINGS_EXT[ROLE_ARSONIST]) .. "'s igniter activated on their death! You have " .. death_timer .. " seconds to find and de-activate it!")
                end
                timer.Create("TTTArsonistAutomaticTrigger_" .. self:EntIndex(), death_timer, 1, function()
                    if death_notify then
                        NotifyEveryone("The " .. ROLE_STRINGS[ROLE_ARSONIST] .. "'s igniter was not deactivated in time and has triggered!")
                    end
                    self:Trigger(self.OrigOwner or ply, not death_notify)
                end)
            else
                if death_notify then
                    NotifyEveryone(string.Capitalize(ROLE_STRINGS_EXT[ROLE_ARSONIST]) .. "'s igniter triggered on their death!")
                end
                self:Trigger(self.OrigOwner or ply, not death_notify)
            end
        end)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "OnDeath")
end

function SWEP:PreDrop()
    -- Save the original owner so we can use it in case someone else accidentally triggers the ignition
    self.OrigOwner = self:GetOwner()
    return self.BaseClass.PreDrop(self)
end

function SWEP:OnDrop()
    -- If ignite-on-death is enabled with a delay and it has been activated on this weapon, let the weapon drop
    -- so another player can pick it up and try to stop it
    if arsonist_ignite_on_death:GetBool() and arsonist_ignite_on_death_timer:GetInt() > 0 and self:GetOnDeath() then
        return
    end

    self:Remove()
end

function SWEP:OnRemove()
    timer.Remove("TTTArsonistAutomaticTrigger_" .. self:EntIndex())
    self.OrigOwner = nil
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

function SWEP:Trigger(owner, notify)
    if CLIENT then return end

    local corpseIgniteTime = GetConVar("ttt_arsonist_corpse_ignite_time"):GetInt()
    local igniteCount = 0
    for _, p in PlayerIterator() do
        if p == owner then continue end
        if p:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED) ~= ARSONIST_DOUSED then continue end

        igniteCount = igniteCount + 1

        -- If the player is dead, try to ignite their ragdoll instead
        if not p:Alive() or p:IsSpec() then
            local rag = p.server_ragdoll or p:GetRagdollEntity()
            if IsValid(rag) then
                util.BurnRagdoll(rag, corpseIgniteTime)
            end
            continue
        end

        -- Arbitrarily high number so they burn to death
        p:Ignite(1000)
        -- Normally we would set the inflictor to be the igniter, but since we're destroying it below it won't be valid anymore
        p.ignite_info = {att=owner, infl=owner}

        if notify then
            p:QueueMessage(MSG_PRINTBOTH, "You have been ignited by the " .. ROLE_STRINGS[ROLE_ARSONIST] .. "!")
        end

        -- Remove the notification delay timer since the message above already tells them the same thing
        timer.Remove("TTTArsonistNotifyDelay_" .. p:SteamID64())
    end

    -- Log the event
    net.Start("TTT_ArsonistIgnited")
    net.Broadcast()

    -- Make sure this player still exists in case this was called after a delay
    if IsPlayer(owner) then
        local message = "You have set " .. igniteCount .. " player(s) on fire!"
        if igniteCount == 0 then
            message = "No players were doused so your igniter just fizzles out"
        end
        owner:QueueMessage(MSG_PRINTBOTH, message)

        -- Set the owner as "complete" so we stop dousing players
        owner:SetNWBool("TTTArsonistDouseComplete", true)
        owner:SetNWString("TTTArsonistDouseTarget", "")
        owner:SetNWFloat("TTTArsonistDouseStartTime", -1)
    end

    self:Remove()
end

function SWEP:PrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if GetRoundState() ~= ROUND_ACTIVE then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    if owner:IsRoleAbilityDisabled() then return end

    -- Don't ignite if all players aren't doused unless early ignition is enabled
    if not arsonist_early_ignite:GetBool() and not owner:GetNWBool("TTTArsonistDouseComplete", false) then
        if not owner:IsArsonist() then
            self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)
            self:Remove()
        elseif SERVER then
            owner:QueueMessage(MSG_PRINTBOTH, "Not all players have been doused in gasoline yet")
        end
        return
    end

    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)
    -- Use the original owner if there is one because that can only be the arsonist this weapon was given to
    -- at the start of the round and can only be set if the weapon was dropped which can only happen
    -- when that arsonist was killed
    self:Trigger(self.OrigOwner or owner, true)
end

function SWEP:SecondaryAttack()
    if CLIENT then return end
    if not arsonist_ignite_on_death:GetBool() then return end

    if self:GetNextSecondaryFire() > CurTime() then return end
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

    if GetRoundState() ~= ROUND_ACTIVE then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    if owner:IsRoleAbilityDisabled() then return end

    if timer.Exists("TTTArsonistAutomaticTrigger_" .. self:EntIndex()) then
        self:SetOnDeath(false)
        if arsonist_ignite_on_death_notify:GetBool() then
            NotifyEveryone(owner:Nick() .. " has de-activated the " .. ROLE_STRINGS[ROLE_ARSONIST] .. "'s igniter!")
        end
        self:Remove()
    elseif owner:IsArsonist() then
        self:SetOnDeath(not self:GetOnDeath())
    end
end

function SWEP:DryFire() return false end