local halo = halo
local hook = hook
local ipairs = ipairs
local net = net
local surface = surface
local table = table

local GetAllPlayers = player.GetAll
local HaloAdd = halo.Add
local AddHook = hook.Add
local RemoveHook = hook.Remove
local TableInsert = table.insert

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "DetectiveLike_Translations_Initialize", function()
    -- Event
    LANG.AddToLanguage("english", "ev_promote", "{player} was promoted to {detective}")

    -- HUD
    LANG.AddToLanguage("english", "detective_promotion_hud", "You have been promoted to {detective}")
    LANG.AddToLanguage("english", "detective_special_hidden_hud", "Your {detective} type is hidden from others")
end)

-------------
-- SCORING --
-------------

AddHook("Initialize", "DetectiveLike_Scoring_Initialize", function()
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

---------
-- HUD --
---------

AddHook("TTTHUDInfoPaint", "DetectiveLike_TTTHUDInfoPaint", function(client, label_left, label_top, active_labels)
    local hide_role = false
    if ConVarExists("ttt_hide_role") then
        hide_role = GetConVar("ttt_hide_role"):GetBool()
    end

    if hide_role then return end

    if client:IsDetectiveTeam() then
        if GetGlobalInt("ttt_detective_hide_special_mode", SPECIAL_DETECTIVE_HIDE_NONE) == SPECIAL_DETECTIVE_HIDE_FOR_OTHERS then
            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 230)

            local text = LANG.GetParamTranslation("detective_special_hidden_hud", { detective = ROLE_STRINGS[ROLE_DETECTIVE] })
            local _, h = surface.GetTextSize(text)

            -- Move this up based on how many other labels here are
            label_top = label_top + (20 * #active_labels)

            surface.SetTextPos(label_left, ScrH() - label_top - h)
            surface.DrawText(text)

            -- Track that the label was added so others can position accurately
            table.insert(active_labels, "detective_team")
        end
    elseif client:IsDetectiveLike() then
        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local text = LANG.GetParamTranslation("detective_promotion_hud", { detective = ROLE_STRINGS[ROLE_DETECTIVE] })
        local _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels here are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        table.insert(active_labels, "detective_like")
    end
end)

------------------
-- HIGHLIGHTING --
------------------

local detective_glow = false
local vision_enabled = false
local client = nil

local function EnableDetectiveLikeHighlights()
    AddHook("PreDrawHalos", "DetectiveLike_Highlight_PreDrawHalos", function()
        local detectives = {}
        for _, v in ipairs(GetAllPlayers()) do
            if not v:IsActiveDetectiveLike() then continue end
            -- Don't highlight players who are already highlighted by things like traitor vision
            if client:IsTargetHighlighted(v) then continue end
            TableInsert(detectives, v)
        end

        if #detectives == 0 then return end

        HaloAdd(detectives, ROLE_COLORS[ROLE_DETECTIVE], 1, 1, 1, true, true)
    end)
end

AddHook("TTTUpdateRoleState", "DetectiveLike_Highlight_TTTUpdateRoleState", function()
    client = LocalPlayer()
    detective_glow = GetGlobalBool("ttt_detective_glow_enable", false)

    -- Disable highlights on role change
    if vision_enabled then
        RemoveHook("PreDrawHalos", "DetectiveLike_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end)

-- Handle enabling and disabling of highlighting
AddHook("Think", "DetectiveLike_Highlight_Think", function()
    if not IsPlayer(client) or not client:Alive() or client:IsSpec() then return end

    if detective_glow then
        if not vision_enabled then
            EnableDetectiveLikeHighlights()
            vision_enabled = true
        end
    else
        vision_enabled = false
    end

    if detective_glow and not vision_enabled then
        RemoveHook("PreDrawHalos", "DetectiveLike_Highlight_PreDrawHalos")
    end
end)