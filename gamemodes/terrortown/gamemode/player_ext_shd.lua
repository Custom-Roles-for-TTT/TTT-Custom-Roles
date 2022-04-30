-- shared extensions to player table

local plymeta = FindMetaTable("Player")
if not plymeta then return end

local ipairs = ipairs
local IsValid = IsValid
local math = math
local net = net
local string = string
local table = table
local timer = timer
local util = util

local CallHook = hook.Call
local GetAllPlayers = player.GetAll
local MathAbs = math.abs

function plymeta:IsTerror() return self:Team() == TEAM_TERROR end
function plymeta:IsSpec() return self:Team() == TEAM_SPEC end

AccessorFunc(plymeta, "role", "Role", FORCE_NUMBER)

local oldSetRole = plymeta.SetRole
function plymeta:SetRole(role)
    local oldRole = self:GetRole()
    oldSetRole(self, role)
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

-- Player is alive and in an active round
function plymeta:IsActive() return self:IsTerror() and GetRoundState() == ROUND_ACTIVE end

-- convenience functions for common patterns
function plymeta:IsRole(role) return self:GetRole() == role end
function plymeta:IsActiveRole(role) return self:IsRole(role) and self:IsActive() end

-- Role access
for role = 0, ROLE_MAX do
    local name = string.gsub(ROLE_STRINGS[role], "%s+", "")
    plymeta["Get" .. name] = function(self) return self:IsRole(role) end
    plymeta["Is" .. name] = plymeta["Get" .. name]
    plymeta["IsActive" .. name] = function(self) return self:IsActiveRole(role) end
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
    if GetGlobalBool("ttt_shop_for_all", false) then
        return hasShop
    end

    -- If this is a role with a potential shop, only give them access if there are actual things to buy
    if hasShop and (DELAYED_SHOP_ROLES[role] or self:IsJesterTeam()) then
        local hasWeapon = WEPS.DoesRoleHaveWeapon(role, self:IsDetectiveLike())
        -- Only allow roles with a delayed shop to use it if they have weapons or will be having weapons synced and are active or "active_only" is disabled
        if DELAYED_SHOP_ROLES[role] then
            local rolestring = ROLE_STRINGS_RAW[role]
            hasWeapon = (hasWeapon or GetGlobalInt("ttt_" .. rolestring .. "_shop_mode", SHOP_SYNC_MODE_NONE) > SHOP_SYNC_MODE_NONE) and
                (not GetGlobalBool("ttt_" .. rolestring .. "_shop_active_only", false) or self:IsRoleActive())
        end
        return hasWeapon
    end
    return hasShop
end
function plymeta:CanUseShop()
    local isShopRole = self:IsShopRole()
    -- Don't perform the additional checks if "shop for all" is enabled
    if GetGlobalBool("ttt_shop_for_all", false) then
        return isShopRole and WEPS.DoesRoleHaveWeapon(self:GetRole(), self:IsDetectiveLike())
    end

    return isShopRole
end
function plymeta:ShouldDelayShopPurchase()
    local role = self:GetRole()
    if DELAYED_SHOP_ROLES[role] then
        return GetGlobalBool("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_delay", false) and not self:IsRoleActive()
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
        return not GetGlobalBool("ttt_jesters_visible_to_traitors", false)
    elseif self:IsMonsterTeam() then
        return not GetGlobalBool("ttt_jesters_visible_to_monsters", false)
    elseif self:IsIndependentTeam() then
        return not GetGlobalBool("ttt_jesters_visible_to_independents", false)
    end
    return true
end

function plymeta:ShouldDelayAnnouncements() return ROLE_SHOULD_DELAY_ANNOUNCEMENTS[self:GetRole()] or false end
function plymeta:ShouldNotDrown() return ROLE_SHOULD_NOT_DROWN[self:GetRole()] or false end

function plymeta:ShouldShowSpectatorHUD()
    -- Check if this role has an external definition for whether to show a spectator HUD and use that
    local role = self:GetRole()
    if ROLE_SHOULD_SHOW_SPECTATOR_HUD[role] then
        return ROLE_SHOULD_SHOW_SPECTATOR_HUD[role](self)
    end
    return false
end

function plymeta:SetRoleAndBroadcast(role)
    self:SetRole(role)

    if SERVER then
        net.Start("TTT_RoleChanged")
        net.WriteString(self:SteamID64())
        net.WriteInt(role, 8)
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
        local special_detective_mode = GetGlobalInt("ttt_detective_hide_special_mode", SPECIAL_DETECTIVE_HIDE_NONE)
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
            return ROLE_DETECTIVE
        end
    end
    return self:GetRole()
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

function plymeta:StripRoleWeapons()
    -- Remove all old role weapons
    for _, w in ipairs(self:GetWeapons()) do
        if w.Category == WEAPON_CATEGORY_ROLE then
            local weap_class = WEPS.GetClass(w)
            self:StripWeapon(weap_class)
        end
    end

    -- Remove the DNA scanner explcitly since it's a role weapon but not a CR role weapon so it's not tagged with the category
    self:StripWeapon("weapon_ttt_wtester")
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
        local ply = net.ReadEntity()
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
    for _, v in ipairs(GetAllPlayers()) do
        if v:Alive() and v:IsTerror() and v:IsRole(role) then
            return v
        end
    end
    return nil
end
function player.IsRoleLiving(role) return IsPlayer(player.GetLivingRole(role)) end

function player.TeamLivingCount(ignorePassiveWinners)
    local innocent_alive = 0
    local traitor_alive = 0
    local indep_alive = 0
    local monster_alive = 0
    local jester_alive = 0
    for _, v in ipairs(GetAllPlayers()) do
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
    for _, v in ipairs(GetAllPlayers()) do
        if not aliveOnly or (v:Alive() and v:IsTerror()) then
            local playerTeam = player.GetRoleTeam(v:GetRole(), detectivesAreInnocent)
            if playerTeam == roleTeam then
                callback(v)
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
    for _, v in ipairs(GetAllPlayers()) do
        -- If the player is alive and we're either not ignoring passive winners or this isn't a passive winning role
        if (v:Alive() and v:IsTerror() and (not ignorePassiveWinners or not ROLE_HAS_PASSIVE_WIN[v:GetRole()])) or
            -- Handle zombification differently because the player's original role should have no impact on this
            v:IsZombifying() then
            players_alive = players_alive + 1
        end
    end
    return players_alive
end