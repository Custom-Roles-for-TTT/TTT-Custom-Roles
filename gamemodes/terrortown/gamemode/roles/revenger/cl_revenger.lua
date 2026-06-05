local hook = hook
local net = net
local pairs = pairs
local player = player
local surface = surface
local timer = timer

local AddHook = hook.Add
local RemoveHook = hook.Remove

local function IsLover(cli, ply)
    return ply:SteamID64() == cli:GetNWString("RevengerLover", "")
end

local function GetLover(cli)
    local sid = cli:GetNWString("RevengerLover", "")
    return player.GetBySteamID64(sid)
end

local function GetLoverKiller(cli)
    local sid = cli:GetNWString("RevengerKiller", "")
    return player.GetBySteamID64(sid)
end

-------------
-- CONVARS --
-------------

local revenger_radar_timer = GetConVar("ttt_revenger_radar_timer")
local revenger_damage_bonus = GetConVar("ttt_revenger_damage_bonus")

------------------
-- TRANSLATIONS --
------------------

AddHook("Initialize", "Revenger_Translations_Initialize", function()
    -- Target ID
    LANG.AddToLanguage("english", "target_revenger_lover", "YOUR SOULMATE")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_revenger", "Assigned a random player as soulmate to protect.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_revenger", [[You are {role}! You are helplessly in love with {lover}.
Do whatever you can to protect them. If they die you will
be able to track down their killer and get your revenge.]])
end)

----------------
-- ROLE POPUP --
----------------

local function Revenger_TTTRolePopupParams(cli)
    if cli:IsRevenger() then
        local lover = GetLover(cli)
        local name = "someone"
        if IsPlayer(lover) then name = lover:Nick() end
        return { lover = name }
    end
end

---------------
-- TARGET ID --
---------------

local function Revenger_TTTTargetIDPlayerTargetIcon(ply, cli, showJester)
    if cli:IsRevenger() and IsLover(cli, ply) then
        return "lover", false, ROLE_COLORS_RADAR[ROLE_REVENGER], "up"
    end
end

local function Revenger_TTTTargetIDPlayerText(ent, cli, text, col, secondary_text)
    if not IsPlayer(ent) then return end
    if cli:IsRevenger() and IsLover(cli, ent) then
        return LANG.GetTranslation("target_revenger_lover"), ROLE_COLORS_RADAR[ROLE_REVENGER], secondary_text
    end
end

ROLE_IS_TARGETID_OVERRIDDEN[ROLE_REVENGER] = function(ply, target)
    if not ply:IsRevenger() then return end
    if not IsPlayer(target) then return end

    ------ icon,  ring,  text
    return false, false, IsLover(ply, target)
end

-----------
-- RADAR --
-----------

local beacon_back = surface.GetTextureID("vgui/ttt/beacon_back")
local beacon_rev = surface.GetTextureID("vgui/ttt/beacon_rev")
local revenger_lover_killers = {}

local function Revenger_TTTRadarRender(cli)
    if cli:IsActiveRevenger() and #revenger_lover_killers then
        surface.SetTexture(beacon_back)
        surface.SetTextColor(0, 0, 0, 0)
        surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_REVENGER])

        for _, target in pairs(revenger_lover_killers) do
            RADAR:DrawTarget(target, 16, 0.5)
        end

        surface.SetTexture(beacon_rev)
        surface.SetTextColor(255, 255, 255, 255)
        surface.SetDrawColor(255, 255, 255, 255)

        for _, target in pairs(revenger_lover_killers) do
            RADAR:DrawTarget(target, 16, 0.5)
        end
    end
end

local beep_success = Sound("buttons/blip2.wav")
local function SetRevengerLoverKillerPosition()
    local cli = LocalPlayer()
    local attacker = GetLoverKiller(cli)
    if IsPlayer(attacker) and attacker:IsActive() and cli:IsRevenger() and not cli:IsRoleAbilityDisabled() then
        revenger_lover_killers = {
            { pos = attacker:LocalToWorld(attacker:OBBCenter()) }
        }
        if cli:IsActive() then surface.PlaySound(beep_success) end
    else
        revenger_lover_killers = {}
    end
end

local function UpdateRevengerLoverKiller()
    if timer.Exists("updaterevengerloverkiller") then timer.Remove("updaterevengerloverkiller") end
    local active = net.ReadBool()
    if active then
        SetRevengerLoverKillerPosition()
        timer.Create("updaterevengerloverkiller", revenger_radar_timer:GetInt(), 0, SetRevengerLoverKillerPosition)
    else
        revenger_lover_killers = {}
    end
end
net.Receive("TTT_RevengerLoverKillerRadar", UpdateRevengerLoverKiller)

local function Revenger_Radar_TTTEndRound()
    if timer.Exists("updaterevengerloverkiller") then timer.Remove("updaterevengerloverkiller") end
end

----------------
-- SCOREBOARD --
----------------

local function Revenger_TTTScoreboardPlayerRole(ply, cli, c, roleStr)
    if cli:IsRevenger() and IsLover(cli, ply) then
        return c, roleStr, ROLE_REVENGER
    end
end

local function Revenger_TTTScoreboardPlayerName(ply, cli, nickTxt)
    if cli:IsRevenger() and IsLover(cli, ply) then
        return ply:Nick() .. " (" .. LANG.GetTranslation("target_revenger_lover") .. ")"
    end
end

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_REVENGER] = function(ply, target)
    if not ply:IsRevenger() then return end
    if not IsPlayer(target) then return end
    if not IsLover(ply, target) then return end

    ------ name, role
    return true, true
end

--------------
-- TUTORIAL --
--------------

local function Revenger_TTTTutorialRoleText(role, titleLabel)
    if role == ROLE_REVENGER then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local html = "The " .. ROLE_STRINGS[ROLE_REVENGER] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to protect their soulmate."

        -- Revenge
        html = html .. "<span style='display: block; margin-top: 10px;'>If their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>soulmate is killed</span>, the " .. ROLE_STRINGS[ROLE_REVENGER] .. "'s goal becomes tracking down and <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>exacting revenge</span> against their soulmate's killer.</span>"

        -- Radar
        html = html .. "<span style='display: block; margin-top: 10px;'>To accomplish this, the " .. ROLE_STRINGS[ROLE_REVENGER] .. " is shown <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>the location of their soulmate's killer</span> via radar-like pings, every " .. revenger_radar_timer:GetInt() .. " seconds.</span>"

        -- Damage bonus
        if revenger_damage_bonus:GetFloat() > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>Once the " .. ROLE_STRINGS[ROLE_REVENGER] .. "'s soulmate is killed, they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>do more damage</span> to their soulmate's killer.</span>"
        end

        return html
    end
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_REVENGER] = function()
    AddHook("TTTEndRound", "Revenger_Radar_TTTEndRound", Revenger_Radar_TTTEndRound)
    AddHook("TTTRadarRender", "Revenger_TTTRadarRender", Revenger_TTTRadarRender)
    AddHook("TTTRolePopupParams", "Revenger_TTTRolePopupParams", Revenger_TTTRolePopupParams)
    AddHook("TTTScoreboardPlayerName", "Revenger_TTTScoreboardPlayerName", Revenger_TTTScoreboardPlayerName)
    AddHook("TTTScoreboardPlayerRole", "Revenger_TTTScoreboardPlayerRole", Revenger_TTTScoreboardPlayerRole)
    AddHook("TTTTargetIDPlayerTargetIcon", "Revenger_TTTTargetIDPlayerTargetIcon", Revenger_TTTTargetIDPlayerTargetIcon)
    AddHook("TTTTargetIDPlayerText", "Revenger_TTTTargetIDPlayerText", Revenger_TTTTargetIDPlayerText)
    AddHook("TTTTutorialRoleText", "Revenger_TTTTutorialRoleText", Revenger_TTTTutorialRoleText)
end

ROLE_UNREGISTER_HOOKS[ROLE_REVENGER] = function()
    RemoveHook("TTTEndRound", "Revenger_Radar_TTTEndRound")
    RemoveHook("TTTRadarRender", "Revenger_TTTRadarRender")
    RemoveHook("TTTRolePopupParams", "Revenger_TTTRolePopupParams")
    RemoveHook("TTTScoreboardPlayerName", "Revenger_TTTScoreboardPlayerName")
    RemoveHook("TTTScoreboardPlayerRole", "Revenger_TTTScoreboardPlayerRole")
    RemoveHook("TTTTargetIDPlayerTargetIcon", "Revenger_TTTTargetIDPlayerTargetIcon")
    RemoveHook("TTTTargetIDPlayerText", "Revenger_TTTTargetIDPlayerText")
    RemoveHook("TTTTutorialRoleText", "Revenger_TTTTutorialRoleText")
end