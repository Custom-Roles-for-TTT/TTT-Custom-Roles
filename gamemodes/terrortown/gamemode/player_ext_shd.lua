-- shared extensions to player table

local plymeta = FindMetaTable("Player")
if not plymeta then return end

local math = math

function plymeta:IsTerror() return self:Team() == TEAM_TERROR end
function plymeta:IsSpec() return self:Team() == TEAM_SPEC end

AccessorFunc(plymeta, "role", "Role", FORCE_NUMBER)

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

function plymeta:GetZombiePrime() return self:GetZombie() and self:GetNWBool("zombie_prime", false) end
function plymeta:GetVampirePrime() return self:GetVampire() and self:GetNWBool("vampire_prime", false) end
function plymeta:GetVampirePreviousRole() return self:GetNWInt("vampire_previous_role", ROLE_NONE) end
function plymeta:GetDetectiveLike() return self:IsDetectiveTeam() or ((self:GetDeputy() or self:GetImpersonator()) and self:GetNWBool("HasPromotion", false)) end
function plymeta:GetDetectiveLikePromotable() return (self:IsDeputy() or self:IsImpersonator()) and not self:GetNWBool("HasPromotion", false) end

function plymeta:GetZombieAlly()
    local role = self:GetRole()
    if MONSTER_ROLES[ROLE_ZOMBIE] then
        return MONSTER_ROLES[role]
    elseif TRAITOR_ROLES[ROLE_ZOMBIE] then
        return TRAITOR_ROLES[role]
    end
    return INDEPENDENT_ROLES[role]
end
function plymeta:GetVampireAlly()
    local role = self:GetRole()
    if MONSTER_ROLES[ROLE_VAMPIRE] then
        return MONSTER_ROLES[role]
    elseif TRAITOR_ROLES[ROLE_VAMPIRE] then
        return TRAITOR_ROLES[role]
    end
    return INDEPENDENT_ROLES[role]
end

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
    if self:IsTraitorTeam() then
        return ROLE_TEAM_TRAITOR
    elseif self:IsMonsterTeam() then
        return ROLE_TEAM_MONSTER
    elseif self:IsJesterteam() then
        return ROLE_TEAM_JESTER
    elseif self:IsIndependentTeam() then
        return ROLE_TEAM_INDEPENDENT
    elseif self:IsInnocentTeam() then
        if not detectivesAreInnocent and self:IsDetectiveTeam() then
            return ROLE_TEAM_DETECTIVE
        end
        return ROLE_TEAM_INNOCENT
    end
end

plymeta.IsDetectiveLike = plymeta.GetDetectiveLike
plymeta.IsDetectiveLikePromotable = plymeta.GetDetectiveLikePromotable
plymeta.IsZombiePrime = plymeta.GetZombiePrime
plymeta.IsVampirePrime = plymeta.GetVampirePrime

plymeta.IsZombieAlly = plymeta.GetZombieAlly
plymeta.IsVampireAlly = plymeta.GetVampireAlly

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
        local hasWeapon = WEPS.DoesRoleHaveWeapon(role)
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
        return isShopRole
    end

    return isShopRole and (not self:IsDeputy() or self:IsRoleActive())
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
    return self:IsShopRole()
end

function plymeta:ShouldActLikeJester()
    if self:IsClown() then return not self:GetNWBool("KillerClownActive", false) end

    -- Check if this role has an external definition for "ShouldActLikeJester" and use that
    local role = self:GetRole()
    if EXTERNAL_ROLE_SHOULD_ACT_LIKE_JESTER[role] then return EXTERNAL_ROLE_SHOULD_ACT_LIKE_JESTER[role](self) end

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
function plymeta:ShouldRevealBeggar(tgt)
    -- If we weren't given a target, use ourselves
    if not tgt then tgt = self end

    -- Determine whether which setting we should check based on what role they changed to
    local beggarMode = nil
    local sameTeam = false
    if tgt:IsTraitor() then
        beggarMode = GetGlobalInt("ttt_beggar_reveal_traitor", BEGGAR_REVEAL_ALL)
        sameTeam = self:IsTraitorTeam() and beggarMode == BEGGAR_REVEAL_TRAITORS
    elseif tgt:IsInnocent() then
        beggarMode = GetGlobalInt("ttt_beggar_reveal_innocent", BEGGAR_REVEAL_TRAITORS)
        sameTeam = self:IsInnocentTeam() and beggarMode == BEGGAR_REVEAL_INNOCENTS
    end

    -- Check the setting value and the player's team to see we if should reveal this beggar
    return beggarMode == BEGGAR_REVEAL_ALL or sameTeam
end
function plymeta:ShouldRevealBodysnatcher(tgt)
    -- If we weren't given a target, use ourselves
    if not tgt then tgt = self end

    -- Determine whether which setting we should check based on what role they changed to
    local bodysnatcherMode = nil
    if tgt:IsTraitorTeam() then
        bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_traitor", BODYSNATCHER_REVEAL_ALL)
    elseif tgt:IsInnocentTeam() then
        bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_innocent", BODYSNATCHER_REVEAL_ALL)
    elseif tgt:IsMonsterTeam() then
        bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_monster", BODYSNATCHER_REVEAL_ALL)
    elseif tgt:IsIndependentTeam() then
        bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_independent", BODYSNATCHER_REVEAL_ALL)
    end

    -- Check the setting value and whether the player and the target are the same team
    return bodysnatcherMode == BODYSNATCHER_REVEAL_ALL or (self:IsSameTeam(tgt) and bodysnatcherMode == BODYSNATCHER_REVEAL_TEAM)
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
function plymeta:IsActiveDetectiveLike() return self:IsActive() and self:IsDetectiveLike() end
function plymeta:IsRoleActive()
    if self:IsClown() then return self:GetNWBool("KillerClownActive", false) end
    if self:IsVeteran() then return self:GetNWBool("VeteranActive", false) end
    if self:IsDeputy() or self:IsImpersonator() then return self:GetNWBool("HasPromotion", false) end
    if self:IsOldMan() then return self:GetNWBool("AdrenalineRush", false) end

    -- Check if this role has an external definition for "IsActive" and use that
    local role = self:GetRole()
    if EXTERNAL_ROLE_IS_ACTIVE[role] then return EXTERNAL_ROLE_IS_ACTIVE[role](self) end

    return true
end

-- Returns printable role
function plymeta:GetRoleString()
    return ROLE_STRINGS[self:GetRole()]
end

-- Returns role language string id, caller must translate if desired
function plymeta:GetRoleStringRaw()
    return ROLE_STRINGS_RAW[self:GetRole()]
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
        local max_bone_z = 0
        for b = 0, self:GetBoneCount() - 1 do
            local name = self:GetBoneName(b)
            local bone = self:LookupBone(name)
            if bone then
                local matrix = self:GetBoneMatrix(bone)
                if matrix then
                    local translation = matrix:GetTranslation()
                    -- Translate the bone position from being relative to the world to being relative to the player's position
                    local z = translation.z - self:GetPos().z
                    if z > max_bone_z then
                        max_bone_z = z
                    end
                end
            end
        end

        -- Check to see if the player's head is scaled
        local headId = self:LookupBone("ValveBiped.Bip01_Head1")
        if headId then
            local headScale = self:GetManipulateBoneScale(headId)
            if headScale.z ~= 1 then
                -- If it has, get the difference between the previous largest Z position and the head position
                local matrix = self:GetBoneMatrix(headId)
                if matrix then
                    local translation = matrix:GetTranslation()
                    local diff = math.abs(max_bone_z - translation.z)
                    -- Scale the difference by the head scale
                    max_bone_z = max_bone_z + (diff * headScale.z)
                end
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

    function plymeta:HandleDetectiveLikePromotion()
        self:SetNWBool("HasPromotion", true)

        net.Start("TTT_Promotion")
        net.WriteString(self:Nick())
        net.Broadcast()

        -- The player has been promoted so we need to update their shop
        net.Start("TTT_ResetBuyableWeaponsCache")
        net.Send(self)
    end

    function plymeta:MoveRoleState(target, keep_on_source)
        if self:IsZombiePrime() then
            if not keep_on_source then self:SetZombiePrime(false) end
            target:SetZombiePrime(true)
        end

        if self:IsVampirePrime() then
            if not keep_on_source then self:SetVampirePrime(false) end
            target:SetVampirePrime(true)
        end

        if self:GetNWBool("HasPromotion", false) then
            if not keep_on_source then self:SetNWBool("HasPromotion", false) end
            target:HandleDetectiveLikePromotion()
        end

        local killer = self:GetNWString("RevengerKiller", "")
        if #killer > 0 then
            if not keep_on_source then self:SetNWString("RevengerKiller", "") end
            target:SetNWString("RevengerKiller", killer)
        end

        local lover = self:GetNWString("RevengerLover", "")
        if #lover > 0 then
            if not keep_on_source then self:SetNWString("RevengerLover", "") end
            target:SetNWString("RevengerLover", lover)

            local revenger_lover = player.GetBySteamID64(lover)
            if IsValid(revenger_lover) then
                target:PrintMessage(HUD_PRINTTALK, "You are now in love with " .. revenger_lover:Nick() .. ".")
                target:PrintMessage(HUD_PRINTCENTER, "You are now in love with " .. revenger_lover:Nick() .. ".")

                if not revenger_lover:Alive() or revenger_lover:IsSpec() then
                    local message
                    if killer == target:SteamID64() then
                        message = "Your love has died by your hand."
                    elseif killer then
                        message = "Your love has died. Track down their killer."

                        timer.Simple(1, function() -- Slight delay needed for NW variables to be sent
                            net.Start("TTT_RevengerLoverKillerRadar")
                            net.WriteBool(true)
                            net.Send(target)
                        end)
                    else
                        message = "Your love has died, but you cannot determine the cause."
                    end

                    timer.Simple(1, function()
                        target:PrintMessage(HUD_PRINTTALK, message)
                        target:PrintMessage(HUD_PRINTCENTER, message)
                    end)
                end
            end
        end

        local assassinTarget = self:GetNWString("AssassinTarget", "")
        if #assassinTarget > 0 then
            if not keep_on_source then self:SetNWString("AssassinTarget", "") end
            target:SetNWString("AssassinTarget", assassinTarget)
            target:PrintMessage(HUD_PRINTCENTER, "You have learned that your predecessor's target was " .. assassinTarget)
            target:PrintMessage(HUD_PRINTTALK, "You have learned that your predecessor's target was " .. assassinTarget)
        elseif self:IsAssassin() then
            -- If the player we're taking the role state from was an assassin but they didn't have a target, try to assign a target to this player
            -- Use a slight delay to let the role change go through first just in case
            timer.Simple(0.25, function()
                AssignAssassinTarget(target, true)
            end)
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
