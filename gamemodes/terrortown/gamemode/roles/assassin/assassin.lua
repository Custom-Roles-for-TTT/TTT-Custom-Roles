AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local math = math
local pairs = pairs
local table = table
local timer = timer

local GetAllPlayers = player.GetAll

-------------
-- CONVARS --
-------------

local assassin_show_target_icon = CreateConVar("ttt_assassin_show_target_icon", "0")
local assassin_target_vision_enable = CreateConVar("ttt_assassin_target_vision_enable", "0")
local assassin_next_target_delay = CreateConVar("ttt_assassin_next_target_delay", "5", FCVAR_NONE, "The delay (in seconds) before an assassin is assigned their next target", 0, 30)
local assassin_target_damage_bonus = CreateConVar("ttt_assassin_target_damage_bonus", "1", FCVAR_NONE, "Damage bonus that the assassin has against their target (e.g. 0.5 = 50% extra damage)", 0, 1)
local assassin_target_bonus_bought = CreateConVar("ttt_assassin_target_bonus_bought", "1")
local assassin_wrong_damage_penalty = CreateConVar("ttt_assassin_wrong_damage_penalty", "0.5", FCVAR_NONE, "Damage penalty that the assassin has when attacking someone who is not their target (e.g. 0.5 = 50% less damage)", 0, 1)
local assassin_failed_damage_penalty = CreateConVar("ttt_assassin_failed_damage_penalty", "0.5", FCVAR_NONE, "Damage penalty that the assassin has after they have failed their contract by killing the wrong person (e.g. 0.5 = 50% less damage)", 0, 1)
local assassin_shop_roles_last = CreateConVar("ttt_assassin_shop_roles_last", "0")

hook.Add("TTTSyncGlobals", "Assassin_TTTSyncGlobals", function()
    SetGlobalBool("ttt_assassin_show_target_icon", assassin_show_target_icon:GetBool())
    SetGlobalBool("ttt_assassin_target_vision_enable", assassin_target_vision_enable:GetBool())
    SetGlobalFloat("ttt_assassin_next_target_delay", assassin_next_target_delay:GetFloat())
end)

-----------------------
-- TARGET ASSIGNMENT --
-----------------------

local function UpdateAssassinTargets(ply)
    for _, v in pairs(GetAllPlayers()) do
        local assassintarget = v:GetNWString("AssassinTarget", "")
        if v:IsAssassin() and ply:Nick() == assassintarget then
            -- Reset the target to clear the target overlay from the scoreboard
            v:SetNWString("AssassinTarget", "")

            -- Don't select a new target if this was the final target
            if not v:GetNWBool("AssassinComplete", false) then
                local delay = assassin_next_target_delay:GetFloat()
                -- Delay giving the next target if we're configured to do so
                if delay > 0 then
                    if v:Alive() and not v:IsSpec() then
                        v:PrintMessage(HUD_PRINTCENTER, "Target eliminated. You will receive your next assignment in " .. tostring(delay) .. " seconds.")
                        v:PrintMessage(HUD_PRINTTALK, "Target eliminated. You will receive your next assignment in " .. tostring(delay) .. " seconds.")
                    end
                    timer.Create(v:Nick() .. "AssassinTarget", delay, 1, function()
                        AssignAssassinTarget(v, false, true)
                    end)
                else
                    AssignAssassinTarget(v, false, false)
                end
            else
                v:PrintMessage(HUD_PRINTCENTER, "Final target eliminated.")
                v:PrintMessage(HUD_PRINTTALK, "Final target eliminated.")
            end
        end
    end
end

-- Centralize this so it can be handled on round start and on player death
function AssignAssassinTarget(ply, start, delay)
    -- Don't let dead players, spectators, non-assassins, failed assassins, or assassins who already received their "final target" get another target
    -- And don't assign targets if the round isn't currently running
    if not IsValid(ply) or GetRoundState() > ROUND_ACTIVE or
        not ply:IsAssassin() or ply:GetNWBool("AssassinFailed", false) or ply:GetNWBool("AssassinComplete", false)
    then
        return
    end

    -- Reset the target to empty in case there are no valid targets
    ply:SetNWString("AssassinTarget", "")

    local enemies = {}
    local shops = {}
    local detectives = {}
    local independents = {}
    local beggarMode = GetConVar("ttt_beggar_reveal_innocent"):GetInt()
    local shopRolesLast = assassin_shop_roles_last:GetBool()
    local bodysnatcherModeInno = GetConVar("ttt_bodysnatcher_reveal_innocent"):GetInt()
    local bodysnatcherModeMon = GetConVar("ttt_bodysnatcher_reveal_monster"):GetInt()
    local bodysnatcherModeIndep = GetConVar("ttt_bodysnatcher_reveal_independent"):GetInt()

    local function AddEnemy(p, bodysnatcherMode)
        -- Don't add the former beggar to the list of enemies unless the "reveal" setting is enabled
        if p:IsInnocent() and p:GetNWBool("WasBeggar", false) and beggarMode ~= BEGGAR_REVEAL_ALL and beggarMode ~= BEGGAR_REVEAL_TRAITORS then return end
        if p:GetNWBool("WasBodysnatcher", false) and bodysnatcherMode ~= BODYSNATCHER_REVEAL_ALL then return end

        -- Put shop roles into a list if they should be targeted last
        if shopRolesLast and p:IsShopRole() then
            table.insert(shops, p:Nick())
        else
            table.insert(enemies, p:Nick())
        end
    end

    for _, p in pairs(GetAllPlayers()) do
        if p:Alive() and not p:IsSpec() then
            -- Include all non-traitor detective-like players
            if p:IsDetectiveLike() and not p:IsTraitorTeam() then
                table.insert(detectives, p:Nick())
            -- Exclude Glitch from this list so they don't get discovered immediately
            elseif p:IsInnocentTeam() and not p:IsGlitch() then
                AddEnemy(p, bodysnatcherModeInno)
            elseif p:IsMonsterTeam() then
                AddEnemy(p, bodysnatcherModeMon)
            -- Exclude roles that have a passive win because they just want to survive
            elseif p:IsIndependentTeam() and not ROLE_HAS_PASSIVE_WIN[p:GetRole()] then
                -- Also exclude bodysnatchers turned into an independent if their role hasn't been revealed
                if not p:GetNWBool("WasBodysnatcher", false) or bodysnatcherModeIndep == BODYSNATCHER_REVEAL_ALL then
                    table.insert(independents, p:Nick())
                end
            end
        end
    end

    local target = nil
    if #enemies > 0 then
        target = enemies[math.random(#enemies)]
    elseif #shops > 0 then
        target = shops[math.random(#shops)]
    elseif #detectives > 0 then
        target = detectives[math.random(#detectives)]
    elseif #independents > 0 then
        target = independents[math.random(#independents)]
    end

    local targetMessage = ""
    if target ~= nil then
        ply:SetNWString("AssassinTarget", target)

        local targets = #enemies + #shops + #detectives + #independents
        local targetCount
        if targets > 1 then
            targetCount = start and "first" or "next"
        elseif targets == 1 then
            targetCount = "final"
            ply:SetNWBool("AssassinComplete", true)
        end
        targetMessage = "Your " .. targetCount .. " target is " .. target .. "."
    else
        targetMessage = "No further targets available."
    end

    if ply:Alive() and not ply:IsSpec() then
        if not delay and not start then targetMessage = "Target eliminated. " .. targetMessage end
        ply:PrintMessage(HUD_PRINTCENTER, targetMessage)
        ply:PrintMessage(HUD_PRINTTALK, targetMessage)
    end
end

ROLE_MOVE_ROLE_STATE[ROLE_ASSASSIN] = function(ply, target, keep_on_source)
    local assassinComplete = ply:GetNWBool("AssassinComplete", false)
    if assassinComplete then
        if not keep_on_source then ply:SetNWBool("AssassinComplete", false) end
        target:SetNWBool("AssassinComplete", true)
    end

    local assassinTarget = ply:GetNWString("AssassinTarget", "")
    if #assassinTarget > 0 then
        if not keep_on_source then ply:SetNWString("AssassinTarget", "") end
        target:SetNWString("AssassinTarget", assassinTarget)
        target:PrintMessage(HUD_PRINTCENTER, "You have learned that your predecessor's target was " .. assassinTarget)
        target:PrintMessage(HUD_PRINTTALK, "You have learned that your predecessor's target was " .. assassinTarget)
    elseif ply:IsAssassin() then
        -- If the player we're taking the role state from was an assassin but they didn't have a target, try to assign a target to this player
        -- Use a slight delay to let the role change go through first just in case
        timer.Simple(0.25, function()
            AssignAssassinTarget(target, true)
        end)
    end
end
ROLE_ON_ROLE_ASSIGNED[ROLE_ASSASSIN] = function(ply)
    AssignAssassinTarget(ply, true, false)
end

local function ValidTarget(role)
    if TRAITOR_ROLES[role] then return false end
    if JESTER_ROLES[role] then return false end
    if ROLE_HAS_PASSIVE_WIN[role] then return false end
    if role == ROLE_GLITCH then return false end
    return true
end

hook.Add("TTTPlayerRoleChanged", "Assassin_Target_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if not ply:Alive() or ply:IsSpec() then return end

    -- If this player is not longer an assassin, clear out thier target
    if oldRole == ROLE_ASSASSIN and oldRole ~= newRole then
        ply:SetNWString("AssassinTarget", "")
        ply:SetNWBool("AssassinFailed", false)
        ply:SetNWBool("AssassinComplete", false)
        timer.Remove(ply:Nick() .. "AssassinTarget")
    end

    -- If this player's role could have been a valid target and definitely isn't anymore, update any assassin that has them as a target
    if ValidTarget(oldRole) and not ValidTarget(newRole) then
        UpdateAssassinTargets(ply)
    end
end)

hook.Add("DoPlayerDeath", "Assassin_DoPlayerDeath", function(ply, attacker, dmginfo)
    -- Let Assassins kill Loot Goblins without penalty
    if not IsValid(ply) or (ply:IsLootGoblin() and ply:IsRoleActive()) then return end

    local attackertarget = attacker:GetNWString("AssassinTarget", "")
    if IsPlayer(attacker) and attacker:IsAssassin() and ply ~= attacker and ply:Nick() ~= attackertarget and (attackertarget ~= "" or timer.Exists(attacker:Nick() .. "AssassinTarget")) then
        timer.Remove(attacker:Nick() .. "AssassinTarget")
        attacker:PrintMessage(HUD_PRINTCENTER, "Contract failed. You killed the wrong player.")
        attacker:PrintMessage(HUD_PRINTTALK, "Contract failed. You killed the wrong player.")
        attacker:SetNWString("AssassinTarget", "")
        attacker:SetNWBool("AssassinFailed", true)
    end

    UpdateAssassinTargets(ply)
end)

-- Clear the assassin target information when the next round starts
hook.Add("TTTPrepareRound", "Assassin_Smoke_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWString("AssassinTarget", "")
        v:SetNWBool("AssassinFailed", false)
        v:SetNWBool("AssassinComplete", false)
        timer.Remove(v:Nick() .. "AssassinTarget")
    end
end)

------------
-- DAMAGE --
------------

hook.Add("ScalePlayerDamage", "Assassin_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    -- Only apply damage scaling after the round starts
    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        -- Assassins deal extra damage to their target, less damage to other players, and less damage if they fail their contract
        -- Don't apply the scaling to the Jester team to specifically allow doing 100% damage to the active killer clown
        if att:IsAssassin() and ply ~= att and not ply:IsJesterTeam() then
            local scale = 0
            if att:GetNWBool("AssassinFailed", false) then
                scale = -assassin_failed_damage_penalty:GetFloat()
            elseif ply:Nick() == att:GetNWString("AssassinTarget", "") then
                -- Get the active weapon, whather it's in the inflictor or it's from the attacker
                local active_weapon = dmginfo:GetInflictor()
                if not IsValid(active_weapon) or IsPlayer(active_weapon) then
                    active_weapon = att:GetActiveWeapon()
                end

                -- Only scale bought weapons if that is enabled
                if (active_weapon.Spawnable or (not active_weapon.CanBuy or assassin_target_bonus_bought:GetBool())) then
                    scale = assassin_target_damage_bonus:GetFloat()
                end
            else
                scale = -assassin_wrong_damage_penalty:GetFloat()
            end
            dmginfo:ScaleDamage(1 + scale)
        end
    end
end)