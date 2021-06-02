-- shared extensions to player table

local plymeta = FindMetaTable("Player")
if not plymeta then return end

local math = math

function plymeta:IsTerror() return self:Team() == TEAM_TERROR end
function plymeta:IsSpec() return self:Team() == TEAM_SPEC end

AccessorFunc(plymeta, "role", "Role", FORCE_NUMBER)

-- Role access
function plymeta:GetTraitor() return self:GetRole() == ROLE_TRAITOR end
function plymeta:GetInnocent() return self:GetRole() == ROLE_INNOCENT end
function plymeta:GetDetective() return self:GetRole() == ROLE_DETECTIVE end
function plymeta:GetJester() return self:GetRole() == ROLE_JESTER end
function plymeta:GetSwapper() return self:GetRole() == ROLE_SWAPPER end
function plymeta:GetGlitch() return self:GetRole() == ROLE_GLITCH end
function plymeta:GetPhantom() return self:GetRole() == ROLE_PHANTOM end
function plymeta:GetHypnotist() return self:GetRole() == ROLE_HYPNOTIST end
function plymeta:GetRevenger() return self:GetRole() == ROLE_REVENGER end
function plymeta:GetDrunk() return self:GetRole() == ROLE_DRUNK end
function plymeta:GetClown() return self:GetRole() == ROLE_CLOWN end
function plymeta:GetDeputy() return self:GetRole() == ROLE_DEPUTY end
function plymeta:GetImpersonator() return self:GetRole() == ROLE_IMPERSONATOR end
function plymeta:GetBeggar() return self:GetRole() == ROLE_BEGGAR end
function plymeta:GetOldMan() return self:GetRole() == ROLE_OLDMAN end

function plymeta:GetDetectiveLike() return self:GetDetective() or ((self:GetDeputy() or self:GetImpersonator()) and self:GetNWBool("HasPromotion", false)) end

plymeta.IsTraitor = plymeta.GetTraitor
plymeta.IsInnocent = plymeta.GetInnocent
plymeta.IsDetective = plymeta.GetDetective
plymeta.IsJester = plymeta.GetJester
plymeta.IsSwapper = plymeta.GetSwapper
plymeta.IsGlitch = plymeta.GetGlitch
plymeta.IsPhantom = plymeta.GetPhantom
plymeta.IsHypnotist = plymeta.GetHypnotist
plymeta.IsRevenger = plymeta.GetRevenger
plymeta.IsDrunk = plymeta.GetDrunk
plymeta.IsClown = plymeta.GetClown
plymeta.IsDeputy = plymeta.GetDeputy
plymeta.IsImpersonator = plymeta.GetImpersonator
plymeta.IsBeggar = plymeta.GetBeggar
plymeta.IsOldMan = plymeta.GetOldMan

plymeta.IsDetectiveLike = plymeta.GetDetectiveLike

function plymeta:IsSpecial() return self:GetRole() ~= ROLE_INNOCENT end
function plymeta:IsCustom()
    local role = self:GetRole()
    return role ~= ROLE_INNOCENT and role ~= ROLE_TRAITOR and role ~= ROLE_DETECTIVE
end
function plymeta:IsShopRole()
    local role = self:GetRole()
    return role == ROLE_TRAITOR or role == ROLE_DETECTIVE or role == ROLE_HYPNOTIST or role == ROLE_DEPUTY or role == ROLE_IMPERSONATOR
end

-- Player is alive and in an active round
function plymeta:IsActive() return self:IsTerror() and GetRoundState() == ROUND_ACTIVE end

-- convenience functions for common patterns
function plymeta:IsRole(role) return self:GetRole() == role end
function plymeta:IsActiveRole(role) return self:IsRole(role) and self:IsActive() end
function plymeta:IsActiveTraitor() return self:IsActiveRole(ROLE_TRAITOR) end
function plymeta:IsActiveInnocent() return self:IsActiveRole(ROLE_INNOCENT) end
function plymeta:IsActiveDetective() return self:IsActiveRole(ROLE_DETECTIVE) end
function plymeta:IsActiveJester() return self:IsActiveRole(ROLE_JESTER) end
function plymeta:IsActiveSwapper() return self:IsActiveRole(ROLE_SWAPPER) end
function plymeta:IsActiveGlitch() return self:IsActiveRole(ROLE_GLITCH) end
function plymeta:IsActivePhantom() return self:IsActiveRole(ROLE_PHANTOM) end
function plymeta:IsActiveHypnotist() return self:IsActiveRole(ROLE_HYPNOTIST) end
function plymeta:IsActiveRevenger() return self:IsActiveRole(ROLE_REVENGER) end
function plymeta:IsActiveDrunk() return self:IsActiveRole(ROLE_DRUNK) end
function plymeta:IsActiveClown() return self:IsActiveRole(ROLE_CLOWN) end
function plymeta:IsActiveDeputy() return self:IsActiveRole(ROLE_DEPUTY) end
function plymeta:IsActiveImpersonator() return self:IsActiveRole(ROLE_IMPERSONATOR) end
function plymeta:IsActiveBeggar() return self:IsActiveRole(ROLE_BEGGAR) end
function plymeta:IsActiveOldMan() return self:IsActiveRole(ROLE_OLDMAN) end

function plymeta:IsActiveSpecial() return self:IsSpecial() and self:IsActive() end
function plymeta:IsActiveCustom() return self:IsCustom() and self:IsActive() end
function plymeta:IsActiveShopRole() return self:IsShopRole() and self:IsActive() end

function plymeta:IsActiveDetectiveLike() return self:IsActive() and self:IsDetectiveLike() end

-- functions to group individual roles into teams
function plymeta:IsTraitorTeam()
    local role = self:GetRole()
    return role == ROLE_TRAITOR or role == ROLE_HYPNOTIST or role == ROLE_IMPERSONATOR
end
function plymeta:IsInnocentTeam()
    local role = self:GetRole()
    return role == ROLE_INNOCENT or role == ROLE_DETECTIVE or role == ROLE_GLITCH or role == ROLE_PHANTOM or role == ROLE_REVENGER or role == ROLE_DEPUTY
end
function plymeta:IsJesterTeam()
    local role = self:GetRole()
    return role == ROLE_JESTER or role == ROLE_SWAPPER or role == ROLE_CLOWN or role == ROLE_BEGGAR
end
function plymeta:IsIndependentTeam()
    local role = self:GetRole()
    return role == ROLE_DRUNK or role == ROLE_OLDMAN
end
function plymeta:IsActiveTraitorTeam() return self:IsTraitorTeam() and self:IsActive() end
function plymeta:IsActiveInnocentTeam() return self:IsInnocentTeam() and self:IsActive() end
function plymeta:IsActiveJesterTeam() return self:IsJesterTeam() and self:IsActive() end
function plymeta:IsActiveIndependentTeam() return self:IsIndependentTeam() and self:IsActive() end

local GetRTranslation = CLIENT and LANG.GetRawTranslation or util.passthrough

-- Returns printable role
function plymeta:GetRoleString()
    return GetRTranslation(ROLE_STRINGS[self:GetRole()]) or "???"
end

-- Returns role language string id, caller must translate if desired
function plymeta:GetRoleStringRaw()
    return ROLE_STRINGS[self:GetRole()]
end

function plymeta:GetBaseKarma() return self:GetNWFloat("karma", 1000) end

function plymeta:HasEquipmentWeapon()
    for _, wep in ipairs(self:GetWeapons()) do
        if IsValid(wep) and wep:IsEquipment() then
            return true
        end
    end

    return false
end

function plymeta:CanCarryWeapon(wep)
    if (not wep) or (not wep.Kind) then return false end

    return self:CanCarryType(wep.Kind)
end

function plymeta:CanCarryType(t)
    if not t then return false end

    for _, w in ipairs(self:GetWeapons()) do
        if w.Kind and w.Kind == t then
            return false
        end
    end
    return true
end

function plymeta:IsDeadTerror()
    return (self:IsSpec() and not self:Alive())
end

function plymeta:HasBought(id)
    return self.bought and table.HasValue(self.bought, id)
end

function plymeta:GetCredits() return self.equipment_credits or 0 end

function plymeta:GetEquipmentItems() return self.equipment_items or EQUIP_NONE end

-- Given an equipment id, returns if player owns this. Given nil, returns if
-- player has any equipment item.
function plymeta:HasEquipmentItem(id)
    if not id then
        return self:GetEquipmentItems() ~= EQUIP_NONE
    else
        return util.BitSet(self:GetEquipmentItems(), id)
    end
end

function plymeta:HasEquipment()
    return self:HasEquipmentItem() or self:HasEquipmentWeapon()
end

-- Override GetEyeTrace for an optional trace mask param. Technically traces
-- like GetEyeTraceNoCursor but who wants to type that all the time, and we
-- never use cursor tracing anyway.
function plymeta:GetEyeTrace(mask)
    mask = mask or MASK_SOLID

    if CLIENT then
        local framenum = FrameNumber()

        if self.LastPlayerTrace == framenum and self.LastPlayerTraceMask == mask then
            return self.PlayerTrace
        end

        self.LastPlayerTrace = framenum
        self.LastPlayerTraceMask = mask
    end

    local tr = util.GetPlayerTrace(self)
    tr.mask = mask

    tr = util.TraceLine(tr)
    self.PlayerTrace = tr

    return tr
end

if CLIENT then

    function plymeta:AnimApplyGesture(act, weight)
        self:AnimRestartGesture(GESTURE_SLOT_CUSTOM, act, true) -- true = autokill
        self:AnimSetGestureWeight(GESTURE_SLOT_CUSTOM, weight)
    end

    local simple_runners = {
        ACT_GMOD_GESTURE_DISAGREE,
        ACT_GMOD_GESTURE_BECON,
        ACT_GMOD_GESTURE_AGREE,
        ACT_GMOD_GESTURE_WAVE,
        ACT_GMOD_GESTURE_BOW,
        ACT_SIGNAL_FORWARD,
        ACT_SIGNAL_GROUP,
        ACT_SIGNAL_HALT,
        ACT_GMOD_TAUNT_CHEER,
        ACT_GMOD_GESTURE_ITEM_PLACE,
        ACT_GMOD_GESTURE_ITEM_DROP,
        ACT_GMOD_GESTURE_ITEM_GIVE
    }
    local function MakeSimpleRunner(act)
        return function(ply, w)
            -- just let this gesture play itself and get out of its way
            if w == 0 then
                ply:AnimApplyGesture(act, 1)
                return 1
            else
                return 0
            end
        end
    end

    -- act -> gesture runner fn
    local act_runner = {
        -- ear grab needs weight control
        -- sadly it's currently the only one
        [ACT_GMOD_IN_CHAT] = function(ply, w)
            local dest = ply:IsSpeaking() and 1 or 0
            w = math.Approach(w, dest, FrameTime() * 10)
            if w > 0 then
                ply:AnimApplyGesture(ACT_GMOD_IN_CHAT, w)
            end
            return w
        end
    };

    -- Insert all the "simple" gestures that do not need weight control
    for _, a in ipairs(simple_runners) do
        act_runner[a] = MakeSimpleRunner(a)
    end

    CreateConVar("ttt_show_gestures", "1", FCVAR_ARCHIVE)

    -- Perform the gesture using the GestureRunner system. If custom_runner is
    -- non-nil, it will be used instead of the default runner for the act.
    function plymeta:AnimPerformGesture(act, custom_runner)
        if GetConVarNumber("ttt_show_gestures") == 0 then return end

        local runner = custom_runner or act_runner[act]
        if not runner then return false end

        self.GestureWeight = 0
        self.GestureRunner = runner

        return true
    end

    -- Perform a gesture update
    function plymeta:AnimUpdateGesture()
        if self.GestureRunner then
            self.GestureWeight = self:GestureRunner(self.GestureWeight)

            if self.GestureWeight <= 0 then
                self.GestureRunner = nil
            end
        end
    end

    function GM:UpdateAnimation(ply, vel, maxseqgroundspeed)
        ply:AnimUpdateGesture()

        return self.BaseClass.UpdateAnimation(self, ply, vel, maxseqgroundspeed)
    end

    function GM:GrabEarAnimation(ply) end

    net.Receive("TTT_PerformGesture", function()
        local ply = net.ReadEntity()
        local act = net.ReadUInt(16)
        if IsValid(ply) and act then
            ply:AnimPerformGesture(act)
        end
    end)

else
    -- SERVER

    -- On the server, we just send the client a message that the player is
    -- performing a gesture. This allows the client to decide whether it should
    -- play, depending on eg. a cvar.
    function plymeta:AnimPerformGesture(act)

        if not act then return end

        net.Start("TTT_PerformGesture")
        net.WriteEntity(self)
        net.WriteUInt(act, 16)
        net.Broadcast()
    end
end
