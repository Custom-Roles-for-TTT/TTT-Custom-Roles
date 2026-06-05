local surface = surface
local math = math
local table = table

local AddHook = hook.Add
local RemoveHook = hook.Remove
local MathMax = math.max

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Twins_Translations_Initialize", function()
    -- HUD
    LANG.AddToLanguage("english", "twins_hud", "Invulnerability ends in: {time}")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_goodtwin", "Has an Evil Twin on the traitor team that knows who the Good Twin is.")
    LANG.AddToLanguage("english", "cheatsheet_desc_eviltwin", "Has a Good Twin on the traitor team that knows who the Evil Twin is.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_goodtwin", [[You are {role}!
You have a twin on the traitor team that knows who you are.
However, you and your twin are unable to damage each other.
If you are the last twin left alive you get temporary invulnerability.
Try to convince everyone that you are the good twin!]])

    LANG.AddToLanguage("english", "info_popup_eviltwin", [[You are {role}! {comrades}

You have a twin on the innocent team that knows who you are.
However, you and your twin are unable to damage each other.
If you are the last twin left alive you get temporary invulnerability.
Try to trick everyone into thinking you are the good twin!

Press {menukey} to receive your special equipment!]])
end)

---------------
-- TARGET ID --
---------------

local function Twins_TTTTargetIDPlayerRoleIcon(ply, cli, role, noz, colorRole, hideBeggar, showJester, hideBodysnatcher)
    if not cli:IsActiveTwin() then return end
    if ply == cli then return end

    if ply:IsActiveGoodTwin() then
        return ROLE_GOODTWIN, false
    elseif ply:IsActiveEvilTwin() then
        return ROLE_EVILTWIN, cli:IsActiveEvilTwin()
    end
end

local function Twins_TTTTargetIDPlayerRing(ent, cli, ringVisible)
    if not IsPlayer(ent) then return end
    if not cli:IsActiveTwin() then return end
    if ent == cli then return end

    if ent:IsActiveTwin() then
        return true, ROLE_COLORS_RADAR[ent:GetRole()]
    end
end

local function Twins_TTTTargetIDPlayerText(ent, cli, text, col)
    if not IsPlayer(ent) then return end
    if not cli:IsActiveTwin() then return end
    if ent == cli then return end

    if ent:IsActiveTwin() then
        local role = ent:GetRole()
        return utf8.upper(ROLE_STRINGS[role]), ROLE_COLORS_RADAR[role]
    end
end

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_GOODTWIN] = function(ply, target, showJester)
    if not IsPlayer(target) then return end

    if ply:IsActiveGoodTwin() and target:IsActiveTwin() then
        return true, true, true
    end
end

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_EVILTWIN] = function(ply, target, showJester)
    if not IsPlayer(target) then return end

    if ply:IsActiveEvilTwin() and target:IsActiveTwin() then
        return true, true, true
    end
end

----------------
-- SCOREBOARD --
----------------

local function Twins_TTTScoreboardPlayerRole(ply, cli, color, roleFileName)
    if not cli:IsActiveTwin() then return end
    if ply == cli then return end

    if ply:IsTwin() then
        local role = ply:GetRole()
        return ROLE_COLORS_SCOREBOARD[role], ROLE_STRINGS_SHORT[role]
    end
end

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_GOODTWIN] = function(ply, target)
    return false, ply:IsActiveGoodTwin() and target:IsActiveTwin()
end

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_EVILTWIN] = function(ply, target)
    return false, ply:IsActiveEvilTwin() and target:IsActiveTwin()
end

---------
-- HUD --
---------

local hide_role = GetConVar("ttt_hide_role")

local function Twins_TTTHUDInfoPaint(client, label_left, label_top, active_labels)
    if hide_role:GetBool() then return end

    if not client:IsActiveTwin() or not client:IsInvulnerable() then return end

    local invulnerabilityEnd = client:GetNWFloat("TTTTwinsInvulnerabilityEnd", 0)
    if invulnerabilityEnd <= 0 then return end

    surface.SetFont("TabLarge")
    surface.SetTextColor(255, 255, 255, 230)

    local remaining = MathMax(0, invulnerabilityEnd - CurTime())
    local text = LANG.GetParamTranslation("twins_hud", { time = util.SimpleTime(remaining, "%02i:%02i") })
    local _, h = surface.GetTextSize(text)

    -- Move this up based on how many other labels there are
    label_top = label_top + (20 * #active_labels)

    surface.SetTextPos(label_left, ScrH() - label_top - h)
    surface.DrawText(text)

    -- Track that the label was added so others can position accurately
    table.insert(active_labels, "twins")
end

--------------
-- TUTORIAL --
--------------

local function Twins_TTTTutorialRoleText(role, titleLabel)
    if role == ROLE_GOODTWIN then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local traitorColor = ROLE_COLORS[ROLE_TRAITOR]

        local html = "The " .. ROLE_STRINGS[ROLE_GOODTWIN] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> who has an evil counterpart on the <span style='color: rgb(" .. traitorColor.r .. ", " .. traitorColor.g .. ", " .. traitorColor.b .. ")'>traitor team</span>."

        html = html .. "<span style='display: block; margin-top: 10px;'>The twins <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cannot damage each other</span> unless they are the last non-jester players alive."

        local invulnerability_timer = GetConVar("ttt_twins_invulnerability_timer"):GetInt()
        if invulnerability_timer > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>If one twin dies, the other is given " .. invulnerability_timer .. " second(s) of invulnerability."
        end

        return html
    elseif role == ROLE_EVILTWIN then
        local roleColor = ROLE_COLORS[ROLE_TRAITOR]
        local innocentColor = ROLE_COLORS[ROLE_INNOCENT]

        local html = "The " .. ROLE_STRINGS[ROLE_EVILTWIN] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>traitor team</span> who has a good counterpart on the <span style='color: rgb(" .. innocentColor.r .. ", " .. innocentColor.g .. ", " .. innocentColor.b .. ")'>innocent team</span>."

        html = html .. "<span style='display: block; margin-top: 10px;'>The twins <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>cannot damage each other</span> unless they are the last non-jester players alive."

        local invulnerability_timer = GetConVar("ttt_twins_invulnerability_timer"):GetInt()
        if invulnerability_timer > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>If one twin dies, the other is given " .. invulnerability_timer .. " second(s) of invulnerability."
        end

        return html
    end
end

------------------
-- REGISTRATION --
------------------

-- TOOD: How do we handle th is for the GOODTWIN and EVILTWIN as two roles with shared hooks?

ROLE_REGISTER_HOOKS[ROLE_TWINS] = function()
    AddHook("TTTHUDInfoPaint", "Twins_TTTHUDInfoPaint", Twins_TTTHUDInfoPaint)
    AddHook("TTTScoreboardPlayerRole", "Twins_TTTScoreboardPlayerRole", Twins_TTTScoreboardPlayerRole)
    AddHook("TTTTargetIDPlayerRing", "Twins_TTTTargetIDPlayerRing", Twins_TTTTargetIDPlayerRing)
    AddHook("TTTTargetIDPlayerRoleIcon", "Twins_TTTTargetIDPlayerRoleIcon", Twins_TTTTargetIDPlayerRoleIcon)
    AddHook("TTTTargetIDPlayerText", "Twins_TTTTargetIDPlayerText", Twins_TTTTargetIDPlayerText)
    AddHook("TTTTutorialRoleText", "Twins_TTTTutorialRoleText", Twins_TTTTutorialRoleText)
end

ROLE_UNREGISTER_HOOKS[ROLE_TWINS] = function()
    RemoveHook("TTTHUDInfoPaint", "Twins_TTTHUDInfoPaint")
    RemoveHook("TTTScoreboardPlayerRole", "Twins_TTTScoreboardPlayerRole")
    RemoveHook("TTTTargetIDPlayerRing", "Twins_TTTTargetIDPlayerRing")
    RemoveHook("TTTTargetIDPlayerRoleIcon", "Twins_TTTTargetIDPlayerRoleIcon")
    RemoveHook("TTTTargetIDPlayerText", "Twins_TTTTargetIDPlayerText")
    RemoveHook("TTTTutorialRoleText", "Twins_TTTTutorialRoleText")
end