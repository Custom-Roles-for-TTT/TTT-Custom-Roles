local halo = halo
local hook = hook
local IsValid = IsValid
local pairs = pairs

local RemoveHook = hook.Remove
local GetAllPlayers = player.GetAll

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Vindicator_Translations_Initialize", function()
    -- Win conditions
    LANG.AddToLanguage("english", "win_vindicator", "The {role} got their revenge!")
    LANG.AddToLanguage("english", "ev_win_vindicator", "The {role} has won the round!")

    -- EVENTS
    LANG.AddToLanguage("english", "ev_vindicator_active", "{vindicator} is tracking down their killer, {target}")
    LANG.AddToLanguage("english", "ev_vindicator_success", "{vindicator} got their revenge on {target}")
    LANG.AddToLanguage("english", "ev_vindicator_fail", "{vindicator} didn't get revenge on {target}")
end)

---------------
-- TARGET ID --
---------------

hook.Add("TTTTargetIDPlayerTargetIcon", "Vindicator_TTTTargetIDPlayerTargetIcon", function(ply, cli, showJester)
    if cli:IsVindicator() and  cli:GetNWString("VindicatorTarget") == ply:SteamID64() then
        return "kill", true, ROLE_COLORS_SPRITE[ROLE_VINDICATOR], "down"
    end
end)

hook.Add("TTTTargetIDPlayerText", "Vindicator_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
    if cli:IsVindicator() and IsPlayer(ent) and ent:SteamID64() == cli:GetNWString("VindicatorTarget", "") then
        return LANG.GetTranslation("target_current_target"), ROLE_COLORS_RADAR[ROLE_VINDICATOR]
    end
end)

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_VINDICATOR] = function(ply, target, showJester)
    if not ply:IsVindicator() then return end
    if not IsPlayer(target) then return end

    local show = (target:SteamID64() == ply:GetNWString("VindicatorTarget", ""))

    ------ icon,  ring, text
    return false, false, show
end

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Vindicator_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if cli:IsVindicator() and ply:SteamID64() == cli:GetNWString("VindicatorTarget", "") then
        return c, roleStr, ROLE_VINDICATOR
    end
end)

hook.Add("TTTScoreboardPlayerName", "Vindicator_TTTScoreboardPlayerName", function(ply, cli, text)
    if cli:IsVindicator() and ply:SteamID64() == cli:GetNWString("VindicatorTarget", "") then
        return ply:Nick() .. " (" .. LANG.GetTranslation("target_assassin_target") .. ")" -- We can reuse the assassin translations here
    end
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_VINDICATOR] = function(ply, target)
    if not ply:IsVindicator() then return end
    if not IsPlayer(target) then return end

    local show = target:SteamID64() == ply:GetNWString("VindicatorTarget", "")

    ------ name, role
    return show, show
end

------------------
-- HIGHLIGHTING --
------------------

local vision_enabled = false
local client = nil

local function EnableVindicatorTargetHighlights()
    hook.Add("PreDrawHalos", "Vindicator_Highlight_PreDrawHalos", function()
        local target_sid64 = client:GetNWString("VindicatorTarget", "")
        if not target_sid64 or #target_sid64 == 0 then return end

        local target = nil
        for _, v in pairs(GetAllPlayers()) do
            if IsValid(v) and v:IsActive() and v ~= client and v:SteamID64() == target_sid64 then
                target = v
                break
            end
        end

        if not target then return end

        halo.Add({target}, ROLE_COLORS[ROLE_VINDICATOR], 1, 1, 1, true, true)
    end)
end

hook.Add("TTTUpdateRoleState", "Vindicator_Highlight_TTTUpdateRoleState", function()
    client = LocalPlayer()

    -- Disable highlights on role change
    if vision_enabled then
        RemoveHook("PreDrawHalos", "Vindicator_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end)

-- Handle enabling and disabling of highlighting
hook.Add("Think", "Vindicator_Highlight_Think", function()
    if not IsPlayer(client) or not client:Alive() or client:IsSpec() then return end

    if client:IsVindicator() then
        if not vision_enabled then
            EnableVindicatorTargetHighlights()
            vision_enabled = true
        end
    else
        vision_enabled = false
    end

    if not vision_enabled then
        RemoveHook("PreDrawHalos", "Vindicator_Highlight_PreDrawHalos")
    end
end)

ROLE_IS_TARGET_HIGHLIGHTED[ROLE_VINDICATOR] = function(ply, target)
    if not ply:IsVindicator() then return end
    if not IsPlayer(target) then return end

    local target_sid64 = ply:GetNWString("VindicatorTarget", "")
    if not target_sid64 or #target_sid64 == 0 then return end

    local isTarget = target_sid64 == target:SteamID64()
    return isTarget
end

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Vindicator_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_VINDICATOR then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_VINDICATOR]) }, c = ROLE_COLORS[ROLE_VINDICATOR] }
    end
end)

hook.Add("TTTScoringSecondaryWins", "Vindicator_TTTScoringSecondaryWins", function(wintype, secondary_wins)
    for _, ply in pairs(GetAllPlayers()) do
        if ply:IsVindicator() and ply:GetNWBool("VindicatorSuccess", false) then
            TableInsert(secondary_wins, ROLE_VINDICATOR)
        end
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Vindicator_TTTEventFinishText", function(e)
    if e.win == WIN_VINDICATOR then
        return LANG.GetTranslation("ev_win_vindicator")
    end
end)

hook.Add("TTTEventFinishIconText", "Vindicator_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_VINDICATOR then
        return win_string, ROLE_STRINGS[ROLE_VINDICATOR]
    end
end)

hook.Add("TTTEndRound", "Vindicator_SecondaryWinEvent_TTTEndRound", function()
    for _, ply in pairs(GetAllPlayers()) do
        if ply:IsVindicator() and ply:GetNWBool("VindicatorSuccess", false) then
            CLSCORE:AddEvent({ -- Log the win event with an offset to force it to the end
                id = EVENT_FINISH,
                win = WIN_VINDICATOR
            }, 1)
            return
        end
    end
end)

-- Register the scoring events for the vindicator
hook.Add("Initialize", "Vindicator_Scoring_Initialize", function()
    local user_delete_icon = Material("icon16/user_delete.png")
    local star_icon = Material("icon16/star.png")
    local stop_icon = Material("icon16/stop.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation
    Event(EVENT_VINDICATORACTIVE, {
        text = function(e)
            return PT("ev_vindicator_active", {vindicator = e.vindicator, target = e.target})
        end,
        icon = function(e)
            return user_delete_icon, "Vindicator Active"
        end})
    Event(EVENT_VINDICATORSUCCESS, {
        text = function(e)
            return PT("ev_vindicator_success", {vindicator = e.vindicator, target = e.target})
        end,
        icon = function(e)
            return star_icon, "Vindicator Success"
        end})
    Event(EVENT_VINDICATORFAIL, {
        text = function(e)
            return PT("ev_vindicator_fail", {vindicator = e.vindicator, target = e.target})
        end,
        icon = function(e)
            return stop_icon, "Vindicator Fail"
        end})
end)

net.Receive("TTT_VindicatorActive", function(len)
    local vindicator = net.ReadString()
    local target = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_VINDICATORACTIVE,
        vindicator = vindicator,
        target = target
    })
end)

net.Receive("TTT_VindicatorSuccess", function(len)
    local vindicator = net.ReadString()
    local target = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_VINDICATORSUCCESS,
        vindicator = vindicator,
        target = target
    })
end)

net.Receive("TTT_VindicatorFail", function(len)
    local vindicator = net.ReadString()
    local target = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_VINDICATORFAIL,
        vindicator = vindicator,
        target = target
    })
end)