-- shared extensions to player table

local plymeta = FindMetaTable("Player")
if not plymeta then return end

local entmeta = FindMetaTable("Entity")
if not entmeta then return end

local ents = ents
local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local player = player
local string = string
local table = table
local timer = timer
local util = util

local CallHook = hook.Call
local AddHook = hook.Add
local RemoveHook = hook.Remove
local MathAbs = math.abs
local MathAcos = math.acos
local PlayerIterator = player.Iterator
local StartBleeding = util.StartBleeding
local TableHasValue = table.HasValue
local TraceEntity = util.TraceEntity

function plymeta:IsTerror() return self:Team() == TEAM_TERROR end
function plymeta:IsSpec() return self:Team() == TEAM_SPEC end

function plymeta:SetupDataTables()
    self:NetworkVar("Bool", 0, "Sprinting")
    self:NetworkVar("Float", 0, "SprintStamina")
    self:NetworkVar("Float", 1, "LastSprintTime")
end

AccessorFunc(plymeta, "role", "Role", FORCE_NUMBER)

local oldSetRole = plymeta.SetRole
function plymeta:SetRole(role)
    local oldRole = self:GetRole()
    oldSetRole(self, role)

    if SERVER and oldRole ~= role and ROLE_USES_SPECTATOR[oldRole] ~= ROLE_USES_SPECTATOR[role] then
        -- If we're changing FROM a role that used spectator spirits
        if ROLE_USES_SPECTATOR[oldRole] then
            local create_spirit = false
            local uses_spectator = GetTeamRoles(ROLE_USES_SPECTATOR)
            -- See if someone else still needs them
            for _, p in PlayerIterator() do
                if TableHasValue(uses_spectator, p:GetRole()) then
                    create_spirit = true
                    break
                end
            end

            -- If not, delete them
            if not create_spirit then
                for _, p in PlayerIterator() do
                    p:RemoveSpectatorSpirit()
                end
            end
        -- If we're changing TO a role that uses spectator spirits
        elseif ROLE_USES_SPECTATOR[role] then
            -- Create them for each dead player
            -- (The alive check is handled by the function already)
            for _, p in PlayerIterator() do
                p:CreateSpectatorSpirit()
            end
        end
    end

    CallHook("TTTPlayerRoleChanged", nil, self, oldRole, role)

    -- Role checks only run on the server
    if not SERVER then return end
    -- Only do this if they had an old role. This handles the case where they were assigned a role at the beginning of the round
    if not oldRole or oldRole <= ROLE_NONE or oldRole > ROLE_MAX then return end
    -- Only do this if the new role is valid. This is not strictly necessary since there wouldn't be a role check for an invalid role, but just for safety
    if not role or role <= ROLE_NONE or role > ROLE_MAX then return end
    -- Only do this if the player's role actually changed
    if oldRole == role then return end

    self:BeginRoleChecks()
end

local oldSetHealth = entmeta.SetHealth
function entmeta:SetHealth(health)
    local oldHealth = self:Health()
    oldSetHealth(self, health)

    -- Only call this if the health changed and the entity is a player
    if health ~= oldHealth and IsPlayer(self) then
        CallHook("TTTPlayerHealthChanged", nil, self, oldHealth, health)
    end
end

-- Player is alive and in an active round
function plymeta:IsActive() return self:Alive() and self:IsTerror() and GetRoundState() == ROUND_ACTIVE end

-- convenience functions for common patterns
function plymeta:IsRole(role) return self:GetRole() == role end
function plymeta:IsActiveRole(role) return self:IsRole(role) and self:IsActive() end

-- Role access
for role = 0, ROLE_MAX do
    local name = string.gsub(ROLE_STRINGS[role], "%s+", "")
    if not plymeta["Get" .. name] then
        plymeta["Get" .. name] = function(self) return self:IsRole(role) end
        if not plymeta["Is" .. name] then
            plymeta["Is" .. name] = plymeta["Get" .. name]
        end
    end
    if not plymeta["IsActive" .. name] then
        plymeta["IsActive" .. name] = function(self) return self:IsActiveRole(role) end
    end
end

-- functions to group individual roles into teams
function plymeta:IsTraitorTeam() return TRAITOR_ROLES[self:GetRole()] or false end
function plymeta:IsInnocentTeam() return INNOCENT_ROLES[self:GetRole()] or false end
function plymeta:IsJesterTeam() return JESTER_ROLES[self:GetRole()] or false end
function plymeta:IsIndependentTeam() return INDEPENDENT_ROLES[self:GetRole()] or false end
function plymeta:IsMonsterTeam() return MONSTER_ROLES[self:GetRole()] or false end
function plymeta:IsDetectiveTeam() return DETECTIVE_ROLES[self:GetRole()] or false end
function plymeta:IsActiveTraitorTeam() return self:IsTraitorTeam() and self:IsActive() end
function plymeta:IsActiveInnocentTeam() return self:IsInnocentTeam() and self:IsActive() end
function plymeta:IsActiveJesterTeam() return self:IsJesterTeam() and self:IsActive() end
function plymeta:IsActiveIndependentTeam() return self:IsIndependentTeam() and self:IsActive() end
function plymeta:IsActiveMonsterTeam() return self:IsMonsterTeam() and self:IsActive() end
function plymeta:IsActiveDetectiveTeam() return self:IsDetectiveTeam() and self:IsActive() end

function plymeta:IsSameTeam(target)
    if self:IsTraitorTeam() and target:IsTraitorTeam() then
        return true
    elseif self:IsMonsterTeam() and target:IsMonsterTeam() then
        return true
    elseif self:IsInnocentTeam() and target:IsInnocentTeam() then
        return true
    end
    return self:GetRole() == target:GetRole()
end
function plymeta:GetRoleTeam(detectivesAreInnocent)
    return player.GetRoleTeam(self:GetRole(), detectivesAreInnocent)
end

function plymeta:IsSpecial() return self:GetRole() ~= ROLE_INNOCENT end
function plymeta:IsCustom() return not DEFAULT_ROLES[self:GetRole()] end

function plymeta:IsShopRole()
    local role = self:GetRole()
    local hasShop = SHOP_ROLES[role] or false
    -- Don't perform the additional checks if "shop for all" is enabled
    if GetConVar("ttt_shop_for_all"):GetBool() then
        return hasShop
    end

    -- If this is a role with a potential shop, only give them access if there are actual things to buy
    if hasShop and (DELAYED_SHOP_ROLES[role] or self:IsJesterTeam()) then
        local hasWeapon = WEPS.DoesRoleHaveWeapon(role, self:IsDetectiveLike())
        -- Only allow roles with a delayed shop to use it if they have weapons or will be having weapons synced and are active or "active_only" is disabled
        if DELAYED_SHOP_ROLES[role] then
            local rolestring = ROLE_STRINGS_RAW[role]
            hasWeapon = (hasWeapon or cvars.Number("ttt_" .. rolestring .. "_shop_mode", SHOP_SYNC_MODE_NONE) > SHOP_SYNC_MODE_NONE) and
                (not cvars.Bool("ttt_" .. rolestring .. "_shop_active_only", false) or self:IsRoleActive())
        end
        return hasWeapon
    end
    return hasShop
end
function plymeta:CanUseShop()
    return self:IsShopRole() and WEPS.DoesRoleHaveWeapon(self:GetRole(), self:IsDetectiveLike())
end
function plymeta:ShouldDelayShopPurchase()
    local role = self:GetRole()
    if DELAYED_SHOP_ROLES[role] then
        return cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_delay", false) and not self:IsRoleActive()
    end
    return false
end
function plymeta:CanUseTraitorButton(active_only)
    if active_only and not self:IsActive() then return false end

    local can_use = TRAITOR_BUTTON_ROLES[self:GetRole()]
    -- If this is explicitly set, use it as-is
    -- This allows us to say a role is a traitor but cannot use traps by setting can_use to false
    if type(can_use) == "boolean" then
        return can_use
    end
    return self:IsTraitorTeam()
end
function plymeta:CanLootCredits(active_only)
    if active_only and not self:IsActive() then return false end
    if self:IsTraitorTeam() and self:IsRoleAbilityDisabled() then return false end

    local can_loot = CAN_LOOT_CREDITS_ROLES[self:GetRole()]
    -- If this is explicitly set, use it as-is
    -- This allows us to say a role has a shop but cannot loot credits by setting can_loot to false
    if type(can_loot) == "boolean" then
        return can_loot
    end
    return self:CanUseShop()
end

function plymeta:ShouldActLikeJester()
    -- Check if this role has an external definition for "ShouldActLikeJester" and use that
    local role = self:GetRole()
    if ROLE_SHOULD_ACT_LIKE_JESTER[role] then return ROLE_SHOULD_ACT_LIKE_JESTER[role](self) end

    return self:IsJesterTeam()
end
function plymeta:ShouldHideJesters()
    if self:IsTraitorTeam() then
        return not GetConVar("ttt_jesters_visible_to_traitors"):GetBool()
    elseif self:IsMonsterTeam() then
        return not GetConVar("ttt_jesters_visible_to_monsters"):GetBool()
    elseif self:IsIndependentTeam() then
        return not cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[self:GetRole()] .. "_can_see_jesters", false)
    end
    return true
end

function plymeta:ShouldNotDrown() return ROLE_SHOULD_NOT_DROWN[self:GetRole()] or false end
function plymeta:CanSeeC4()
    if self:IsActiveTraitorTeam() then
        return true
    end
    return ROLE_CAN_SEE_C4[self:GetRole()] or false
end

function plymeta:ShouldShowSpectatorHUD()
    -- Check if this role has an external definition for whether to show a spectator HUD and use that
    local role = self:GetRole()
    if ROLE_SHOULD_SHOW_SPECTATOR_HUD[role] then
        return ROLE_SHOULD_SHOW_SPECTATOR_HUD[role](self)
    end
    return false
end

function plymeta:ShouldRevealRoleWhenActive()
    -- Check if this role has an external definition for whether to show reveal their role when they are active
    local role = self:GetRole()
    if ROLE_SHOULD_REVEAL_ROLE_WHEN_ACTIVE[role] then
        return ROLE_SHOULD_REVEAL_ROLE_WHEN_ACTIVE[role](self)
    end
    return false
end

function plymeta:IsVictimChangingRole(victim)
    -- Check if this role has an external definition for whether players killed by them are changing their role
    local role = self:GetRole()
    if ROLE_VICTIM_CHANGING_ROLE[role] then
        return ROLE_VICTIM_CHANGING_ROLE[role](self, victim)
    end
    return false
end

function plymeta:IsRespawning()
    return CallHook("TTTIsPlayerRespawning", nil, self) == true
end
if SERVER then
    function plymeta:StopRespawning()
        return CallHook("TTTStopPlayerRespawning", nil, self) == true
    end
end

function plymeta:SetRoleAndBroadcast(role)
    self:SetRole(role)

    if SERVER then
        net.Start("TTT_RoleChanged")
        net.WriteString(self:SteamID64())
        net.WriteInt(role, util.RoleBits())
        net.Broadcast()
    end
end

function plymeta:IsActiveSpecial() return self:IsSpecial() and self:IsActive() end
function plymeta:IsActiveCustom() return self:IsCustom() and self:IsActive() end
function plymeta:IsActiveShopRole() return self:IsShopRole() and self:IsActive() end
function plymeta:IsRoleActive()
    -- Check if this role has an external definition for "IsActive" and use that
    local role = self:GetRole()
    if ROLE_IS_ACTIVE[role] then return ROLE_IS_ACTIVE[role](self) end

    return true
end

function plymeta:GetDisplayedRole()
    if self:IsDetectiveTeam() and not self:IsDetective() then
        local special_detective_mode = GetConVar("ttt_detectives_hide_special_mode"):GetInt()
        -- By default, show detective unless this is disabled
        local show_detective = special_detective_mode ~= SPECIAL_DETECTIVE_HIDE_NONE

        -- But if we're on the client
        if show_detective and CLIENT then
            local client = LocalPlayer()
            -- Check if the local player is the special detective
            -- If they are, don't hide their role if we're only hiding for others
            if client == self and special_detective_mode == SPECIAL_DETECTIVE_HIDE_FOR_OTHERS then
                show_detective = false
            end
        end

        if show_detective then
            return ROLE_DETECTIVE, true
        end
    end
    return self:GetRole(), false
end

-- Returns printable role
function plymeta:GetRoleString()
    return ROLE_STRINGS[self:GetDisplayedRole()]
end

-- Returns role language string id, caller must translate if desired
function plymeta:GetRoleStringRaw()
    return ROLE_STRINGS_RAW[self:GetDisplayedRole()]
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
    return self:IsSpec() and not self:Alive()
end

function plymeta:HasBought(id)
    return self.bought and table.HasValue(self.bought, id)
end

function plymeta:GetCredits() return self.equipment_credits or 0 end

function plymeta:GetEquipmentItems() return self.equipment_items end

-- Given an equipment id, returns if player owns this. Given nil, returns if
-- player has any equipment item.
function plymeta:HasEquipmentItem(id)
    if not id then
        return #self:GetEquipmentItems() > 0
    else
        return table.HasValue(self.equipment_items, id)
    end
end

function plymeta:HasEquipment()
    return self:HasEquipmentItem() or self:HasEquipmentWeapon()
end

function plymeta:StripRoleWeapons()
    -- Remove all old role weapons
    for _, w in ipairs(self:GetWeapons()) do
        if w.Category == WEAPON_CATEGORY_ROLE then
            local weap_class = WEPS.GetClass(w)
            self:StripWeapon(weap_class)
        end
    end
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

function plymeta:IsOnScreen(ent_or_pos, limit)
    local ent_pos = ent_or_pos
    if type(ent_pos) ~= "Vector" then
        ent_pos = ent_pos:GetPos()
    end
    if not limit then limit = 1 end

    local dir = ent_pos - self:GetPos()
    dir:Normalize()
    local eye = self:EyeAngles():Forward()
    return MathAcos(dir:Dot(eye)) <= limit
end

function plymeta:IsInvulnerable()
    return self:GetNWBool("CRTTT_Invulnerable", false)
end

local roleAbilityCache = {}
function plymeta:IsRoleAbilityDisabled(...)
    if roleAbilityCache[self:SteamID64()] then
        CallHook("TTTOnRoleAbilityBlocked", nil, self, ...)
        return true
    end

    local roleIsDisabled = CallHook("TTTIsRoleAbilityDisabled", nil, self, ...) == true
    if roleIsDisabled then
        self:DisableRoleAbility(...)
        CallHook("TTTOnRoleAbilityBlocked", nil, self, ...)
    end

    return roleIsDisabled
end

function plymeta:DisableRoleAbility(...)
    local sid64 = self:SteamID64()
    if roleAbilityCache[sid64] then return end

    roleAbilityCache[sid64] = true
    CallHook("TTTOnRoleAbilityDisabled", nil, self, ...)
end

function plymeta:EnableRoleAbility()
    local sid64 = self:SteamID64()
    if not roleAbilityCache[sid64] then return end

    roleAbilityCache[sid64] = nil
    CallHook("TTTOnRoleAbilityEnabled", nil, self)
end

local function ClearRoleAbilityCache()
    roleAbilityCache = {}
end
hook.Add("TTTPrepareRound", "RoleAbilityCache_TTTPrepareRound", ClearRoleAbilityCache)
hook.Add("TTTBeginRound", "RoleAbilityCache_TTTBeginRound", ClearRoleAbilityCache)
-- Don't clear on round end because we may need this for post-round summary stuff

if CLIENT then
    local function GetMaxBoneZ(ply, pred)
        local max_bone_z = 0
        for b = 0, ply:GetBoneCount() - 1 do
            local name = ply:GetBoneName(b)
            local bone = ply:LookupBone(name)
            if bone and (not pred or pred(b, name, bone)) then
                local matrix = ply:GetBoneMatrix(bone)
                if matrix then
                    local translation = matrix:GetTranslation()
                    -- Translate the bone position from being relative to the world to being relative to the player's position
                    local z = MathAbs(translation.z - ply:GetPos().z)
                    if z > max_bone_z then
                        max_bone_z = z
                    end
                end
            end
        end
        return max_bone_z
    end

    local height_cache = {}
    function plymeta:GetHeight()
        local id = self:UniqueID()
        if height_cache[id] then
            local data = height_cache[id]
            local height = data.height
            local time = data.time
            if (CurTime() - time) < RealFrameTime() then
                return height
            end
        end

        -- Find the bone with the highest z point
        local max_bone_z = GetMaxBoneZ(self)

        -- Check to see if the player's head is scaled
        local headId = self:LookupBone("ValveBiped.Bip01_Head1")
        if headId then
            local headScale = self:GetManipulateBoneScale(headId)
            if headScale.z > 1 then
                max_bone_z = max_bone_z + ((headScale.z - 1) * 25)
            end
        end

        if max_bone_z > 0 then
            height_cache[id] = {
                height = max_bone_z,
                time = CurTime()
            }
            return max_bone_z
        end

        -- Fallback to default player heights
        return self:Crouching() and 28 or 64
    end

    function plymeta:IsTargetIDOverridden(target, showJester)
        -- Check if this role has an external definition for "IsTargetIDOverridden" and use that
        local role = self:GetRole()
        if ROLE_IS_TARGETID_OVERRIDDEN[role] then return ROLE_IS_TARGETID_OVERRIDDEN[role](self, target, showJester) end

        local revealed = self:ShouldRevealRoleWhenActive() and self:IsRoleActive()
        ------ icon,     ring,     text
        return revealed, revealed, revealed
    end

    function plymeta:IsScoreboardInfoOverridden(target)
        -- Check if this role has an external definition for "IsScoreboardInfoOverridden" and use that
        local role = self:GetRole()
        if ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[role] then return ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[role](self, target) end

        ------ name,  role
        return false, self:ShouldRevealRoleWhenActive() and self:IsRoleActive()
    end

    function plymeta:IsTargetHighlighted(target)
        -- Check if this role or team has an external definition for "IsTargetHighlighted" and use that
        local role = self:GetRole()
        if ROLE_IS_TARGET_HIGHLIGHTED[role] then return ROLE_IS_TARGET_HIGHLIGHTED[role](self, target) end
        local roleteam = player.GetRoleTeam(role)
        if ROLETEAM_IS_TARGET_HIGHLIGHTED[roleteam] then return ROLETEAM_IS_TARGET_HIGHLIGHTED[roleteam](self, target) end

        return false
    end

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
        if not GetConVar("ttt_show_gestures"):GetBool() then return end

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
        local ply = net.ReadPlayer()
        local act = net.ReadUInt(16)
        if IsValid(ply) and act then
            ply:AnimPerformGesture(act)
        end
    end)

    -- Jester team confetti
    local confetti = Material("confetti.png")
    function plymeta:Celebrate(snd, show_confetti)
        if snd ~= nil then
            self:EmitSound(snd)
        end

        if not show_confetti then return end

        local pos = self:GetPos() + Vector(0, 0, self:OBBMaxs().z)
        if self.GetShootPos then
            pos = self:GetShootPos()
        end

        local velMax = 200
        local gravMax = 50
        local gravity = Vector(math.random(-gravMax, gravMax), math.random(-gravMax, gravMax), math.random(-gravMax, 0))

        --Handles particles
        local emitter = ParticleEmitter(pos, true)
        for _ = 1, 150 do
            local p = emitter:Add(confetti, pos)
            p:SetStartSize(math.random(6, 10))
            p:SetEndSize(0)
            p:SetAngles(Angle(math.random(0, 360), math.random(0, 360), math.random(0, 360)))
            p:SetAngleVelocity(Angle(math.random(5, 50), math.random(5, 50), math.random(5, 50)))
            p:SetVelocity(Vector(math.random(-velMax, velMax), math.random(-velMax, velMax), math.random(-velMax, velMax)))
            p:SetColor(255, 255, 255)
            p:SetDieTime(math.random(4, 7))
            p:SetGravity(gravity)
            p:SetAirResistance(125)
        end
        emitter:Finish()
    end

    function plymeta:QueueMessage(message_type, message, time, id)
        if LocalPlayer() ~= self then
            ErrorNoHalt("`plymeta:QueueMessage` cannot be used to send messages to other players when called clientside.\n")
            return
        end
        time = time or 5
        net.Start("TTT_QueueMessage")
        net.WriteUInt(message_type, 3)
        net.WriteString(message)
        net.WriteFloat(time)
        net.WriteString(id or "")
        net.SendToServer()
    end

    function plymeta:ClearQueuedMessage(id)
        if LocalPlayer() ~= self then
            ErrorNoHalt("`plymeta:QueueMessage` cannot be used to send messages to other players when called clientside.\n")
            return
        end
        net.Start("TTT_ClearQueuedMessage")
        net.WriteString(id)
        net.SendToServer()
    end
else
    -- SERVER

    -- On the server, we just send the client a message that the player is
    -- performing a gesture. This allows the client to decide whether it should
    -- play, depending on eg. a cvar.
    function plymeta:AnimPerformGesture(act)
        if not act then return end

        net.Start("TTT_PerformGesture")
            net.WritePlayer(self)
            net.WriteUInt(act, 16)
        net.Broadcast()
    end

    function plymeta:MoveRoleState(target, keep_on_source)
        -- Run role-specific logic
        if ROLE_MOVE_ROLE_STATE[self:GetRole()] then
            ROLE_MOVE_ROLE_STATE[self:GetRole()](self, target, keep_on_source)
        end

        -- If the dead player had role weapons stored, give them to the target and then clear the list
        -- Use a slight delay so their old role weapons (like the bodysnatching device) are removed first
        timer.Simple(0.25, function()
            if self.DeathRoleWeapons then
                if self.DeathRoleWeapons[self:GetRole()] then
                    for _, w in ipairs(self.DeathRoleWeapons[self:GetRole()]) do
                        target:Give(w)
                    end
                end

                table.Empty(self.DeathRoleWeapons)
            end
        end)
    end
end

--- Ragdoll

if SERVER then
    local function TransferRagdollDamage(rag, dmginfo)
        if not IsRagdoll(rag) then return end

        local ply = rag.ragdolled_ply
        if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end

        -- Keep track of how much health they have left
        local damage = dmginfo:GetDamage()
        -- Apply damage resistance, if it's provided
        if rag.damage_resist and rag.damage_resist > 0 then
            damage = damage - (damage * rag.damage_resist)
        end
        ply.ragdoll_info.health = ply.ragdoll_info.health - damage

        StartBleeding(rag, damage, 5)

        -- Kill the player if they run out of health
        if ply.ragdoll_info.health <= 0 then
            ply:UnRagdoll()

            local att = dmginfo:GetAttacker()
            local inflictor = dmginfo:GetInflictor()
            if not IsValid(inflictor) then
                inflictor = att
            end
            local dmg_type = dmginfo:GetDamageType()

            -- Use TakeDamage instead of Kill so it properly applies karma
            local dmg = DamageInfo()
            dmg:SetDamageType(dmg_type)
            dmg:SetAttacker(att)
            dmg:SetInflictor(inflictor)
            -- Use 10 so damage scaling doesn't mess with it. The worse damage factor (0.1) will still deal 1 damage after scaling a 10 down
            -- Karma ignores excess damage anyway
            dmg:SetDamage(10)
            dmg:SetDamageForce(Vector(0, 0, 1))

            ply:SetHealth(1)
            ply:TakeDamageInfo(dmg)
        else
            ply:SetHealth(ply.ragdoll_info.health)
        end
    end

    function plymeta:Ragdoll(len, transfer_damage, leave_role_weaps)
        if self:IsRagdolled() then return end

        -- Save a local reference to use in the hook below
        local ply = self
        ply:SetProperty("in_ragdoll", true)
        ply.last_ragdoll = CurTime()
        ply.ragdoll_info = {}

        if ply:InVehicle() then
            ply:ExitVehicle()
        end

        local weps = {}
        for _, wep in ipairs(ply:GetWeapons()) do
            if leave_role_weaps and wep.Category == WEAPON_CATEGORY_ROLE then continue end

            local wep_class = WEPS.GetClass(wep)
            weps[wep_class] = {}
            weps[wep_class].Clip = wep:Clip1()
            weps[wep_class].Reserve = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
            weps[wep_class].PAPUpgrade = wep.PAPUpgrade
        end

        local equipment = {}
        -- Keep track of what equipment the player had
        local idx = 1
        while idx <= EQUIP_MAX do
            equipment[idx] = ply:HasEquipmentItem(idx)
            idx = idx + 1
        end

        ply.ragdoll_info = {
            weps = weps,
            activeWeapon = WEPS.GetClass(ply:GetActiveWeapon()),
            health = ply:Health(),
            model = ply:GetModel(),
            credits = ply:GetCredits(),
            equipment = equipment,
            playerColor = ply:GetPlayerColor(),
            -- Save Dead Ringer state
            deadRinger = {
                status = ply:GetNWInt("DRStatus", 0),
                charge = ply:GetNWInt("DRCharge", 8)
            }
        }

        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll.ragdolled_ply = ply
        ragdoll.player_health = self:Health()
        -- Don't let the red matter bomb destroy this ragdoll
        ragdoll.WYOZIBHDontEat = true
        local velocity = ply:GetVelocity()
        ragdoll:SetPos(ply:GetPos())
        ragdoll:SetModel(ply.ragdoll_info.model)
        ragdoll:SetSkin(ply:GetSkin())
        for _, value in pairs(ply:GetBodyGroups()) do
            ragdoll:SetBodygroup(value.id, ply:GetBodygroup(value.id))
        end
        ragdoll:SetAngles(ply:GetAngles())
        ragdoll:SetColor(ply:GetColor())
        CORPSE.SetPlayerNick(ragdoll, ply)
        ragdoll:Spawn()
        ragdoll:Activate()

        local rag_collide = GetConVar("ttt_ragdoll_collide")
        ragdoll:SetCollisionGroup(rag_collide:GetBool() and COLLISION_GROUP_WEAPON or COLLISION_GROUP_DEBRIS_TRIGGER)

        ply:SetParent(ragdoll)
        -- Set velocity for each piece of the ragdoll
        for i = 1, ragdoll:GetPhysicsObjectCount() do
            local phys_obj = ragdoll:GetPhysicsObjectNum(i)
            if phys_obj then
                phys_obj:SetVelocity(velocity)
            end
        end

        ply:Spectate(OBS_MODE_CHASE)
        ply:SpectateEntity(ragdoll)
        -- Don't remove everything if we're leaving role weapons
        if leave_role_weaps then
            for _, wep in ipairs(ply:GetWeapons()) do
                if wep.Category == WEAPON_CATEGORY_ROLE then continue end

                local wep_class = WEPS.GetClass(wep)
                ply:StripWeapon(wep_class)
            end
        else
            ply:StripWeapons()
        end

        -- Just in case they have some undroppable/unremoveable weapon
        ply:DrawViewModel(false)
        ply:DrawWorldModel(false)

        -- Compatibility with something (which, honestly, I forget what it is...)
        if ragdoll.DisallowDeleting then
            ragdoll:DisallowDeleting(true, function(old, new)
                if IsValid(ply) then ply.ragdoll_ent = new end
            end)
        end

        -- If there is a barnacle holding this player, tell it to let go
        -- We do this so the player doesn't get stuck in a partial capture state
        -- where they are taking damage from the barnacle even though they have revived
        -- and moved away
        for _, b in ipairs(ents.FindByClass("npc_barnacle")) do
            if not IsValid(b) then continue end
            if b:GetEnemy() ~= ply then continue end
            b:Fire("LetGo", nil, 0, ply, ply)
        end

        ply.ragdoll_ent = ragdoll
        ply:SetProperty("ragdoll_ent_idx", ragdoll:EntIndex())

        if type(len) == "number" and len > 0 then
            local hookId = "PlayerRagdollTimer_" .. ply:SteamID64()
            AddHook("Think", hookId, function()
                if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end

                ply:DrawViewModel(false)
                ply:DrawWorldModel(false)

                local doll = ply.ragdoll_ent
                if not IsValid(doll) then return end

                local physObj = doll:GetPhysicsObjectNum(1)
                if not IsValid(physObj) then return end

                -- Turn a ragdoll back into a player if they have essentially stopped moving and have been a ragdoll "long enough"
                if physObj:GetVelocity():Length() <= 10 and (CurTime() - ply.last_ragdoll) > len then
                    RemoveHook("Think", hookId)
                    ply:UnRagdoll()
                end
            end)
        end

        if transfer_damage then
            AddHook("PostEntityTakeDamage", "PlayerRagdollDamageTransfer_" .. ply:SteamID64(), function(ent, dmginfo, taken)
                if not taken then return end
                if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end

                local att = dmginfo:GetAttacker()
                if not IsPlayer(att) then return end
                if att == ply then return end

                -- Don't transfer damage from jester-like players
                if att:ShouldActLikeJester() then return end

                local rag = ent
                if IsPlayer(ent) then
                    rag = ent.ragdoll_ent
                end

                if not IsRagdoll(rag) then return end

                -- Make sure the damaged ragdoll belongs to our target player
                if rag.ragdolled_ply ~= ply then return end

                -- Transfer damage from the ragdoll to the real player
                TransferRagdollDamage(rag, dmginfo)
            end)
        end

        CallHook("TTTPlayerRagdolled", nil, ply, ragdoll)
        return ragdoll
    end

    -- Thanks to SunRed on GitHub for the unstuck script
    local function PlayerNotStuck(ply)
        local pos = ply:GetPos()
        local t = {
            start = pos,
            endpos = pos,
            mask = MASK_PLAYERSOLID,
            filter = ply
        }
        return TraceEntity(t, ply).StartSolid == false
    end

    local function FindPassableSpace(ply, direction, step)
        local i = 0
        while (i < 100) do
            local origin = ply:GetPos()
            origin = origin + step * direction

            ply:SetPos(origin)
            if PlayerNotStuck(ply) then
                return true, ply:GetPos()
            end
            i = i + 1
        end
        return false, nil
    end

    --
    --    Purpose: Unstucks player
    --    Note: Very expensive to call, you have been warned!
    --
    local function UnstuckPlayer(ply)
        if not PlayerNotStuck(ply) then
            local oldPos = ply:GetPos()
            local angle = ply:GetAngles()
            local forward = angle:Forward()
            local right = angle:Right()
            local up = angle:Up()

            local searchScale = 1 -- Increase and it will unstuck you from even harder places but with lost accuracy. Please, don't try higher values than 12
            -- Forward
            local success, pos = FindPassableSpace(ply, forward, searchScale)
            if not success then success, pos = FindPassableSpace(ply, right, searchScale) end -- Right
            if not success then success, pos = FindPassableSpace(ply, right, -searchScale) end -- Left
            if not success then success, pos = FindPassableSpace(ply, up, searchScale) end -- Up
            if not success then success, pos = FindPassableSpace(ply, up, -searchScale) end -- Down
            if not success then success, pos = FindPassableSpace(ply, forward, -searchScale) end -- Back
            if not success then
                return false
            end

            -- Not stuck?
            if oldPos == pos then
                return true
            else
                ply:SetPos(pos)
                if IsValid(ply) and IsValid(ply:GetPhysicsObject()) then
                    if ply:IsPlayer() then
                        ply:SetVelocity(vector_origin)
                    end
                    ply:GetPhysicsObject():SetVelocity(vector_origin) -- prevents bugs :s
                end

                return true
            end
        end
    end

    local function HandleWeaponPAP(weap, upgrade)
        -- If PAP is installed, this weapon was given successfully, and the old one was PAP'd, then PAP the new one too
        if not TTTPAP then return end
        if not upgrade then return end
        if not IsValid(weap) then return end

        TTTPAP:ApplyUpgrade(weap, upgrade)
    end

    function plymeta:UnRagdoll()
        if not self:IsRagdolled() then return end

        -- Save a local reference to use in the timer below
        local ply = self
        ply:SetParent()

        -- These are reset in Spawn so save them first
        local ragdoll = ply.ragdoll_ent
        local ragdoll_info = ply.ragdoll_info

        -- Save these things in case something like a Randomat has changed them
        -- We'll restore them later since the `Spawn` call resets these flags to their default
        local jumpPower = ply:GetJumpPower()
        local walkSpeed = ply:GetWalkSpeed()
        local maxHealth = ply:GetMaxHealth()

        -- Set these so players don't get their role weapons given back if they've already used them
        ply.Resurrecting = true
        ply.DeathRoleWeapons = nil
        ply:Spawn()

        if IsValid(ragdoll) then
            local pos = ragdoll:GetPos()
            pos.z = pos.z + 10
            ply:SetPos(pos)
            ply:SetVelocity(ragdoll:GetVelocity())
            local yaw = ragdoll:GetAngles().yaw
            ply:SetAngles(Angle(0, yaw, 0))
            if ragdoll.DisallowDeleting then
                ragdoll:DisallowDeleting(false)
            end
            SafeRemoveEntity(ragdoll)
        end

        for i, _ in pairs(ragdoll_info.weps) do
            local wep = ply:Give(i)
            if not IsValid(wep) then continue end

            if ragdoll_info.weps[i].Clip then
                wep:SetClip1(ragdoll_info.weps[i].Clip)
            end
            ply:SetAmmo(ragdoll_info.weps[i].Reserve, wep:GetPrimaryAmmoType())
            HandleWeaponPAP(wep, ragdoll_info.weps[i].PAPUpgrade)
        end

        if ragdoll_info.activeWeapon then
            ply:SelectWeapon(ragdoll_info.activeWeapon)
        end

        ply:SetCredits(ragdoll_info.credits)
        ply:SetModel(ragdoll_info.model)
        ply:SetPlayerColor(ragdoll_info.playerColor)
        ply:DrawViewModel(true)
        ply:DrawWorldModel(true)

        -- Re-set Dead Ringer state
        ply:SetNWInt("DRStatus", ragdoll_info.deadRinger.status)
        ply:SetNWInt("DRCharge", ragdoll_info.deadRinger.charge)

        for i, j in pairs(ragdoll_info.equipment) do
            if j then
                ply:GiveEquipmentItem(i)
            end
        end

        -- Restore potentially-changed values
        ply:SetWalkSpeed(walkSpeed)
        ply:SetJumpPower(jumpPower)

        ply:SetMaxHealth(maxHealth)
        ply:SetHealth(math.max(0, ragdoll_info.health))
        if ply:Health() <= 0 then
            ply:Kill()
        else
            timer.Simple(0.1, function()
                if not IsPlayer(ply) then return end
                if not ply:Alive() or ply:IsSpec() then return end
                if ply:IsInWorld() then
                    UnstuckPlayer(ply)
                end
            end)
        end

        CallHook("TTTPlayerUnRagdolled", nil, ply, ragdoll)
    end

    local function ClearRagdolls()
        for _, ply in PlayerIterator() do
            if ply.in_ragdoll then
                ply:UnRagdoll()
            end
        end
    end
    AddHook("TTTEndRound", "Ragdoll_Clear_TTTEndRound", ClearRagdolls)
    AddHook("TTTPrepareRound", "Ragdoll_Clear_TTTPrepareRound", ClearRagdolls)
else
    -- Don't show the target ID for our own ragdoll
    local function BlockTargetID(ent, client, text, color)
        if not IsValid(ent) then return end
        if ent:EntIndex() ~= client.ragdoll_ent_idx then return end

        return false
    end
    AddHook("TTTTargetIDRagdollName", "Ragdoll_BlockTargetID_TTTTargetIDRagdollName", BlockTargetID)
    AddHook("TTTTargetIDEntityHintLabel", "Ragdoll_BlockTargetID_TTTTargetIDEntityHintLabel", BlockTargetID)
    AddHook("TTTTargetIDPlayerHintText", "Ragdoll_BlockTargetID_TTTTargetIDPlayerHintText", BlockTargetID)
end

function plymeta:IsRagdolled()
    return self.in_ragdoll or false
end

--- Static methods

function player.GetRoleTeam(role, detectivesAreInnocent)
    if TRAITOR_ROLES[role] then
        return ROLE_TEAM_TRAITOR
    elseif MONSTER_ROLES[role] then
        return ROLE_TEAM_MONSTER
    elseif JESTER_ROLES[role] then
        return ROLE_TEAM_JESTER
    elseif INDEPENDENT_ROLES[role] then
        return ROLE_TEAM_INDEPENDENT
    elseif INNOCENT_ROLES[role] then
        if not detectivesAreInnocent and DETECTIVE_ROLES[role] then
            return ROLE_TEAM_DETECTIVE
        end
        return ROLE_TEAM_INNOCENT
    end
end

function player.GetLivingRole(role)
    for _, v in PlayerIterator() do
        if v:Alive() and v:IsTerror() and v:IsRole(role) then
            return v
        end
    end
    return nil
end
function player.IsRoleLiving(role) return IsPlayer(player.GetLivingRole(role)) end

function player.GetLivingInRadius(pos, radius)
    local living_players = {}
    for _, p in PlayerIterator() do
        if not p:Alive() or p:IsSpec() then continue end
        if p:GetPos():Distance(pos) > radius then continue end
        table.insert(living_players, p)
    end
    return living_players
end

function player.TeamLivingCount(ignorePassiveWinners)
    local innocent_alive = 0
    local traitor_alive = 0
    local indep_alive = 0
    local monster_alive = 0
    local jester_alive = 0
    for _, v in PlayerIterator() do
        -- If the player is alive
        if v:Alive() and v:IsTerror() then
            -- If we're either not ignoring passive winners or this isn't a passive winning role
            if not ignorePassiveWinners or not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                if v:IsInnocentTeam() then
                    innocent_alive = innocent_alive + 1
                elseif v:IsTraitorTeam() then
                    traitor_alive = traitor_alive + 1
                elseif v:IsIndependentTeam() then
                    indep_alive = indep_alive + 1
                elseif v:IsMonsterTeam() then
                    monster_alive = monster_alive + 1
                elseif v:IsJesterTeam() then
                    jester_alive = jester_alive + 1
                end
            end
        -- Handle zombification differently because the player's original role should have no impact on this
        elseif v:IsZombifying() then
            if TRAITOR_ROLES[ROLE_ZOMBIE] then
                traitor_alive = traitor_alive + 1
            elseif INDEPENDENT_ROLES[ROLE_ZOMBIE] then
                indep_alive = indep_alive + 1
            elseif MONSTER_ROLES[ROLE_ZOMBIE] then
                monster_alive = monster_alive + 1
            end
        end
    end
    return traitor_alive, innocent_alive, indep_alive, monster_alive, jester_alive
end
function player.AreTeamsLiving(ignorePassiveWinners)
    local traitor_alive, innocent_alive, indep_alive, monster_alive, jester_alive = player.TeamLivingCount(ignorePassiveWinners)
    return traitor_alive > 0, innocent_alive > 0, indep_alive > 0, monster_alive > 0, jester_alive > 0
end

function player.ExecuteAgainstTeamPlayers(roleTeam, detectivesAreInnocent, aliveOnly, callback)
    for _, v in PlayerIterator() do
        if not aliveOnly or (v:Alive() and v:IsTerror()) then
            local playerTeam = player.GetRoleTeam(v:GetRole(), detectivesAreInnocent)
            if playerTeam == roleTeam and callback(v) then
                return
            end
        end
    end
end

function player.GetTeamPlayers(roleTeam, detectivesAreInnocent, aliveOnly)
    local team_players = {}
    player.ExecuteAgainstTeamPlayers(roleTeam, detectivesAreInnocent, aliveOnly, function(ply)
        table.insert(team_players, ply)
    end)
    return team_players
end

function player.LivingCount(ignorePassiveWinners)
    local players_alive = 0
    for _, v in PlayerIterator() do
        -- If the player is alive and we're either not ignoring passive winners or this isn't a passive winning role
        if (v:Alive() and v:IsTerror() and (not ignorePassiveWinners or not ROLE_HAS_PASSIVE_WIN[v:GetRole()])) or
            -- Handle zombification differently because the player's original role should have no impact on this
            v:IsZombifying() then
            players_alive = players_alive + 1
        end
    end
    return players_alive
end
