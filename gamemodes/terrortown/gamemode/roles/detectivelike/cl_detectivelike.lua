------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "DetectiveLike_Translations_Initialize", function()
    -- Event
    LANG.AddToLanguage("english", "ev_promote", "{player} was promoted to {detective}")
end)

-------------
-- SCORING --
-------------

hook.Add("Initialize", "DetectiveLike_Scoring_Initialize", function()
    local promotion_icon = Material("icon16/award_star_add.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation
    Event(EVENT_PROMOTION, {
        text = function(e)
            return PT("ev_promote", {player = e.ply, detective = ROLE_STRINGS[ROLE_DETECTIVE]})
        end,
        icon = function(e)
            return promotion_icon, "Promotion"
        end})
end)

net.Receive("TTT_Promotion", function(len)
    local name = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_PROMOTION,
        ply = name
    })
end)