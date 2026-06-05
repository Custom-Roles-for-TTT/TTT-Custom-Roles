AddCSLuaFile()

local hook = hook

local AddHook = hook.Add

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_cupid_lover_vision_enabled", "1", FCVAR_REPLICATED, "Whether the lovers can see outlines of each other through walls", 0, 1)
CreateConVar("ttt_cupid_can_see_jesters", "0", FCVAR_REPLICATED)
CreateConVar("ttt_cupid_update_scoreboard", "0", FCVAR_REPLICATED)
local cupid_is_independent = CreateConVar("ttt_cupid_is_independent", "0", FCVAR_REPLICATED, "Whether cupids should be treated as members of the independent team", 0, 1)
CreateConVar("ttt_cupid_lovers_notify_mode", "1", FCVAR_REPLICATED, "Who is notified with cupid makes two players fall in love", 0, 3)
CreateConVar("ttt_cupid_can_damage_lovers", "0", FCVAR_REPLICATED, "Whether cupid should be able to damage the lovers", 0, 1)
CreateConVar("ttt_cupid_lovers_can_damage_lovers", "1", FCVAR_REPLICATED, "Whether the lovers should be able to damage each other", 0, 1)
CreateConVar("ttt_cupid_lovers_can_damage_cupid", "0", FCVAR_REPLICATED, "Whether the lovers should be able to damage cupid", 0, 1)

ROLE_CONVARS[ROLE_CUPID] = {
    {
        cvar = "ttt_cupid_arrow_speed_mult",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_cupid_arrow_hitscan",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cupid_notify_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"None", "Detective and Traitor", "Traitor", "Detective", "Everyone"},
        isNumeric = true
    },
    {
        cvar = "ttt_cupid_notify_killer",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cupid_notify_sound",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cupid_notify_confetti",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cupid_lovers_notify_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"No one", "Everyone", "Traitors", "Innocents"},
        isNumeric = true
    },
    {
        cvar = "ttt_cupid_is_independent",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cupid_can_damage_lovers",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cupid_lovers_can_damage_lovers",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cupid_lovers_can_damage_cupid",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cupid_lover_vision_enabled",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cupid_can_see_jesters",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_cupid_update_scoreboard",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

-------------------
-- ROLE FEATURES --
-------------------

AddHook("TTTUpdateRoleState", "Cupid_TeamChange_TTTUpdateRoleState", function()
    local is_independent = cupid_is_independent:GetBool()
    INDEPENDENT_ROLES[ROLE_CUPID] = is_independent
    JESTER_ROLES[ROLE_CUPID] = not is_independent
end)

AddHook("TTTPlayerCanSendCreditsTo", "Cupid_TTTPlayerCanSendCreditsTo", function(ply, target, canSend)
    -- Don't block a role that can send credits already
    if canSend then return end
    -- Only roles that have shops can transfer
    if not ply:CanUseShop() then return end
    -- and be transferred to
    if not target:CanUseShop() then return end

    local targetSid64 = target:SteamID64()

    -- If this is a cupid
    if ply:IsActiveCupid() then
        -- with both targets
        local target1 = ply:GetNWString("TTTCupidTarget1", "")
        if not target1 or #target1 == 0 then return end
        local target2 = ply:GetNWString("TTTCupidTarget2", "")
        if not target2 or #target2 == 0 then return end

        -- and we're being queried about one of their targets who has a shop, then they can be sent to
        if targetSid64 == target1 or targetSid64 == target2 then
            return true
        end
    end

    -- If this target is the player's lover then they can be sent to
    if targetSid64 == ply:GetNWString("TTTCupidLover", "") then
        return true
    end

    -- Or if they are the player's cupid then they can be sent to
    if targetSid64 == ply:GetNWString("TTTCupidShooter", "") then
        return true
    end
end)