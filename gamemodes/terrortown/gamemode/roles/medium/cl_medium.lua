local hook = hook
local math = math
local pairs = pairs

local GetAllEnts = ents.GetAll
local MathRand = math.Rand
local MathRandom = math.random

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Medium_Translations_Initialize", function()
    -- Popup
    LANG.AddToLanguage("english", "info_popup_medium", [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
You can see the spirits of the dead. Follow the spirits
to uncover secrets that were taken to the grave.

Press {menukey} to receive your equipment!]])
end)

------------------
-- ROLE FEATURE --
------------------

hook.Add("Think", "Medium_RoleFeature_Think", function()
    local client = LocalPlayer()
    if not client:IsActiveMedium() then return end

    for _, ent in pairs(GetAllEnts()) do
        if ent:GetNWBool("MediumSpirit", false) then
            ent:SetNoDraw(true)
            ent:SetRenderMode(RENDERMODE_NONE)
            ent:SetNotSolid(true)
            ent:DrawShadow(false)
            if not ent.WispEmitter then ent.WispEmitter = ParticleEmitter(ent:GetPos()) end
            if not ent.WispNextPart then ent.WispNextPart = CurTime() end
            local pos = ent:GetPos() + Vector(0, 0, 64)
            if ent.WispNextPart < CurTime() then
                if client:GetPos():Distance(pos) <= 3000 then
                    ent.WispEmitter:SetPos(pos)
                    ent.WispNextPart = CurTime() + MathRand(0.003, 0.01)
                    local particle = ent.WispEmitter:Add("particle/wisp.vmt", pos)
                    particle:SetVelocity(Vector(0, 0, 30))
                    particle:SetDieTime(1)
                    particle:SetStartAlpha(MathRandom(150, 220))
                    particle:SetEndAlpha(0)
                    local size = MathRandom(4, 7)
                    particle:SetStartSize(size)
                    particle:SetEndSize(1)
                    particle:SetRoll(MathRand(0, math.pi))
                    particle:SetRollDelta(0)
                    local col = ent:GetNWVector("SpiritColor", Vector(1, 1, 1))
                    particle:SetColor(col.x * 255, col.y * 255, col.z * 255)
                end
            end
        else
            if ent.WispEmitter then
                ent.WispEmitter:Finish()
                ent.WispEmitter = nil
            end
        end
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Medium_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_MEDIUM then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local detectiveColor = GetRoleTeamColor(ROLE_TEAM_DETECTIVE)
        local html = "The " .. ROLE_STRINGS[ROLE_MEDIUM] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have the ability to see the spirits of the dead as they move around the afterlife.</span>"

        -- Spirits
        if GetGlobalBool("ttt_medium_spirit_color", true) then
            html = html .. "<span style='display: block; margin-top: 10px;'>Each player will have a randomly assigned <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>spirit color</span> allowing the " .. ROLE_STRINGS[ROLE_MEDIUM] .. " to keep track of track specific spirits.</span>"
        end

        return html
    end
end)