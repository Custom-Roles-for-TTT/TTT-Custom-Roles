local hook

local AddHook = hook.Add

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Cannibal_Translations_Initialize", function()
    -- Events
    LANG.AddToLanguage("english", "ev_cannibaleat", "{victim} was eaten by {source}")

    -- Win conditions
    LANG.AddToLanguage("english", "win_cannibal", "The {role} is finally satiated!")
    LANG.AddToLanguage("english", "ev_win_cannibal", "The gluttonous {role} has won the round!")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_cannibal", "Wins by eating all other living players. If they die everyone they ate is revived.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_cannibal", [[You are {role}! Eat all living players to win.

Everyone you ate will be respawned if you die.]])
end)

----------------
-- WIN CHECKS --
----------------

AddHook("TTTScoringWinTitle", "Cannibal_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_CANNIBAL then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[WIN_CANNIBAL]) }, c = ROLE_COLORS[WIN_CANNIBAL] }
    end
end)

------------
-- EVENTS --
------------

AddHook("TTTEventFinishText", "Cannibal_TTTEventFinishText", function(e)
    if e.win == WIN_CANNIBAL then
        return LANG.GetParamTranslation("ev_win_cannibal", { role = string.lower(ROLE_STRINGS[WIN_CANNIBAL]) })
    end
end)

AddHook("TTTEventFinishIconText", "Cannibal_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_CANNIBAL then
        return win_string, ROLE_STRINGS[WIN_CANNIBAL]
    end
end)

AddHook("Initialize", "Cannibal_Events_Initialize", function()
    local eat_icon = Material("icon16/emoticon_tongue.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation

    Event(EVENT_CANNIBALEAT, {
        text = function(e)
            return PT("ev_cannibaleat", {victim = e.vic, source = e.src})
        end,
        icon = function(e)
            return eat_icon, "Eaten"
        end})
end)

net.Receive("TTT_CannibalEaten", function(len)
    local victim = net.ReadString()
    local source = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_CANNIBALEAT,
        vic = victim,
        src = source
    })
end)

----------------
-- SCOREBOARD --
----------------

local client

AddHook("TTTScoreGroup", "Cannibal_TTTScoreGroup", function(ply)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not IsPlayer(ply) then return end
    if not ply.TTTCannibalEaten then return end

    if not IsPlayer(client) then
        client = LocalPlayer()
    end

    if client:IsSpec() or client:IsTraitorTeam() or client:IsMonsterTeam() or (client:IsIndependentTeam() and cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[client:GetRole()] .. "_update_scoreboard", false)) then
        return GROUP_NOTFOUND
    end
end)