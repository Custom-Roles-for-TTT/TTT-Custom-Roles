local hook = hook
local math = math
local player = player
local table = table
local string = string
local ents = ents

local StringUpper = string.upper
local PlayerIterator = player.Iterator
local MathRand = math.Rand
local MathRandom = math.random
local TableInsert = table.insert
local FindEntsByClass = ents.FindByClass

-------------
-- CONVARS --
-------------

local medium_spirit_color = GetConVar("ttt_medium_spirit_color")
local medium_spirit_vision = GetConVar("ttt_medium_spirit_vision")
local medium_seance_time = GetConVar("ttt_medium_seance_time")
local medium_seance_max_info = GetConVar("ttt_medium_seance_max_info")
local medium_hide_killer_role = GetConVar("ttt_medium_hide_killer_role")

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Medium_Translations_Initialize", function()
    -- Seance
    LANG.AddToLanguage("english", "mdmseance_name", "NAME")
    LANG.AddToLanguage("english", "mdmseance_team", "TEAM")
    LANG.AddToLanguage("english", "mdmseance_role", "ROLE")

    -- Notifications
    LANG.AddToLanguage("english", "medium_reveal_name", "{medium} has performed a seance and discovered the spirit of {spirit}.")
    LANG.AddToLanguage("english", "medium_reveal_role", "{medium} has performed a seance and discovered that {spirit} was {role}.")

    -- Cheat Sheet
    LANG.AddToLanguage("english", "cheatsheet_desc_medium", "Can communicate with the souls of dead players.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_medium", [[You are {role}! As {adetective}, HQ has given you special resources to find the {traitors}.
You can see the spirits of the dead. Follow the spirits
to uncover secrets that were taken to the grave.

Press {menukey} to receive your equipment!]])
end)

------------------
-- ROLE FEATURE --
------------------

local spirit_vision = true
hook.Add("TTTUpdateRoleState", "Medium_RoleFeature_TTTUpdateRoleState", function()
    spirit_vision = medium_spirit_vision:GetBool()
end)

local cacheTime = CurTime()
local cacheLength = 5
local lastResult = nil
local function ShouldSeeSpirits(ply)
    -- Mediums can always see spirits
    if ply:IsActiveMedium() then return true end
    -- If spirit vision is disabled, non-Mediums can never see spirits
    if not spirit_vision then return false end
    -- If the player is alive, they can never see spirits
    if ply:Alive() or not ply:IsSpec() then return false end

    -- If the last result is too old, clear it
    if (CurTime() - cacheTime) > cacheLength then
        lastResult = nil
    end

    -- If we have a valid last result, use it again
    if type(lastResult) == "boolean" then return lastResult end

    -- Otherwise, calculate the result and cache it
    cacheTime = CurTime()

    -- Only allow dead people to see spirits if there is a medium
    for _, v in PlayerIterator() do
        if v:IsMedium() then
            lastResult = true
            return true
        end
    end

    lastResult = false
    return false
end

local client
hook.Add("Think", "Medium_RoleFeature_Think", function()
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if not client then
        client = LocalPlayer()
    end
    if not ShouldSeeSpirits(client) then return end

    for _, ent in ipairs(FindEntsByClass("npc_kleiner")) do
        if ent:GetNWBool("MediumSpirit", false) then
            ent:SetNoDraw(true)
            ent:SetRenderMode(RENDERMODE_NONE)
            ent:SetNotSolid(true)
            ent:DrawShadow(false)
            if not ent.WispEmitter then ent.WispEmitter = ParticleEmitter(ent:GetPos()) end
            if not ent.WispNextPart then ent.WispNextPart = CurTime() end
            local pos = ent:GetPos() + Vector(0, 0, 64)
            if ent.WispNextPart < CurTime() and client:GetPos():Distance(pos) <= 3000 then
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
        elseif ent.WispEmitter then
            ent.WispEmitter:Finish()
            ent.WispEmitter = nil
        end
    end
end)

---------------
-- SPIRIT ID --
---------------

local roleback = surface.GetTextureID("vgui/ttt/sprite_roleback")
local rolefront = surface.GetTextureID("vgui/ttt/sprite_rolefront")

hook.Add("PostDrawTranslucentRenderables", "Medium_PostDrawTranslucentRenderables", function()
    if medium_seance_max_info:GetInt() == MEDIUM_SCANNED_NONE then return end

    if not client then
        client = LocalPlayer()
    end
    if not IsPlayer(client) or not client:IsActiveMedium() then return end

    for _, ent in ipairs(FindEntsByClass("npc_kleiner")) do
        if ent:GetNWBool("MediumSpirit", false) then
            local sid64 = ent:GetNWString("SpiritOwner", "")
            local ply = player.GetBySteamID64(sid64)
            if IsPlayer(ply) then
                local stage = ply:GetNWInt("TTTMediumSeanceStage")
                if stage >= MEDIUM_SCANNED_NAME then
                    local pos = ent:GetPos() + Vector(0, 0, 64)
                    local ang = EyeAngles()
                    local col = ent:GetNWVector("SpiritColor", Vector(1, 1, 1))
                    cam.Start3D2D(pos, Angle(0, ang.y - 90, 90 - ang.x), .25)
                    draw.SimpleText(ply:Nick(), "TargetID", 0, 30, Color(col.x * 255, col.y * 255, col.z * 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    if stage >= MEDIUM_SCANNED_TEAM then
                        local role = ply:GetRole()
                        local roleFileName = ROLE_STRINGS_SHORT[role]
                        local roleText = StringUpper(ROLE_STRINGS[ply:GetRole()])
                        if stage == MEDIUM_SCANNED_TEAM then
                            role = ROLE_NONE
                            if ply:IsTraitorTeam() then role = ROLE_TRAITOR
                            elseif ply:IsDetectiveTeam() then role = ROLE_DETECTIVE
                            elseif ply:IsInnocentTeam() then role = ROLE_INNOCENT
                            elseif ply:IsIndependentTeam() then role = ROLE_DRUNK
                            elseif ply:IsJesterTeam() then role = ROLE_JESTER
                            elseif ply:IsMonsterTeam() then role = ply:GetRole() end

                            roleFileName = "nil"

                            local T = LANG.GetTranslation
                            local PT = LANG.GetParamTranslation
                            local labelParam

                            if TRAITOR_ROLES[role] then labelParam = T("traitor")
                            elseif DETECTIVE_ROLES[role] then labelParam = T("detective")
                            elseif INNOCENT_ROLES[role] then labelParam = T("innocent")
                            elseif INDEPENDENT_ROLES[role] then labelParam = T("independent")
                            elseif JESTER_ROLES[role] then labelParam = T("jester")
                            elseif MONSTER_ROLES[role] then labelParam = T("monster") end

                            roleText = PT("target_unknown_team", {targettype = StringUpper(labelParam)})
                        end
                        local roleCol = ROLE_COLORS_RADAR[role]
                        draw.SimpleText(roleText, "TargetIDSmall", 0, 50, roleCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                        local filePath = util.GetRoleIconPath(roleFileName, "sprite", "vtf")

                        draw.TexturedQuad({texture = roleback, color = ROLE_COLORS_SPRITE[role], x = -24, y = -80, w = 48, h = 48})
                        draw.TexturedQuad({texture = surface.GetTextureID(filePath), color = COLOR_WHITE, x = -24, y = -80, w = 48, h = 48})
                        draw.TexturedQuad({texture = rolefront, color = COLOR_WHITE, x = -24, y = -80, w = 48, h = 48})
                    end
                    cam.End3D2D()
                end
            end
        end
    end
end)

----------------
-- SCOREBOARD --
----------------

hook.Add("TTTScoreboardPlayerRole", "Medium_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not IsPlayer(ply) then return end
    if ply:IsActive() then return end
    if cli:IsScoreboardInfoOverridden(ply) then return end

    local state = ply:GetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_NONE)
    if state <= MEDIUM_SCANNED_NAME then return end

    local newColor = c
    local newRoleStr = roleStr

    if state == MEDIUM_SCANNED_TEAM then
        local role = ROLE_NONE
        if ply:IsTraitorTeam() then role = ROLE_TRAITOR
        elseif ply:IsDetectiveTeam() then role = ROLE_DETECTIVE
        elseif ply:IsInnocentTeam() then role = ROLE_INNOCENT
        elseif ply:IsIndependentTeam() then role = ROLE_DRUNK
        elseif ply:IsJesterTeam() then role = ROLE_JESTER
        elseif ply:IsMonsterTeam() then role = ply:GetRole() end

        newColor = ROLE_COLORS_SCOREBOARD[role]
        newRoleStr = "nil"
    elseif state == MEDIUM_SCANNED_ROLE then
        newColor = ROLE_COLORS_SCOREBOARD[ply:GetRole()]
        newRoleStr = ROLE_STRINGS_SHORT[ply:GetRole()]
    end

    return newColor, newRoleStr
end)

hook.Add("TTTScoreGroup", "Medium_TTTScoreGroup", function(ply)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not IsPlayer(ply) then return end
    if ply:IsActive() then return end

    local state = ply:GetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_NONE)
    if state <= MEDIUM_SCANNED_NONE then return end

    if not ply.search_result and not ply:GetNWBool("body_searched", false) and not ply:GetNWBool("body_found", false) then
        return GROUP_NOTFOUND
    end
end)

----------------
-- SEANCE HUD --
----------------

hook.Add("HUDPaint", "Medium_HUDPaint", function()
    if not client then
        client = LocalPlayer()
    end

    if not client:IsActiveMedium() then return end

    local seance_max_info = medium_seance_max_info:GetInt()
    if seance_max_info == MEDIUM_SCANNED_NONE then return end

    local state = client:GetNWInt("TTTMediumSeanceState", MEDIUM_SEANCE_IDLE)

    if state == MEDIUM_SEANCE_IDLE then return end

    local scan = medium_seance_time:GetInt()
    local time = client:GetNWFloat("TTTMediumSeanceStartTime", -1) + scan

    local x = ScrW() / 2.0
    local y = ScrH() / 2.0

    y = y + (y / 3)

    local w = 300

    local T = LANG.GetTranslation
    local titles = {T("mdmseance_name")}
    if seance_max_info >= MEDIUM_SCANNED_TEAM then
        TableInsert(titles, T("mdmseance_team"))
        if seance_max_info == MEDIUM_SCANNED_ROLE then
            TableInsert(titles, T("mdmseance_role"))
        end
    end

    if state == MEDIUM_SEANCE_LOCKED or state == MEDIUM_SEANCE_SEARCHING then
        if time < 0 then return end

        local color = Color(255, 255, 0, 155)
        if state == MEDIUM_SEANCE_LOCKED then
            color = Color(0, 255, 0, 155)
        end

        local target = player.GetBySteamID64(client:GetNWString("TTTMediumSeanceTarget", ""))
        local targetState = target:GetNWInt("TTTMediumSeanceStage", MEDIUM_SCANNED_NONE)

        local cc = math.min(1, 1 - ((time - CurTime()) / scan))
        local progress = (cc + targetState) / #titles

        CRHUD:PaintProgressBar(x, y, w, color, client:GetNWString("TTTMediumSeanceMessage", ""), progress, #titles, titles)
    elseif state == MEDIUM_SEANCE_LOST then
        local color = Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)
        CRHUD:PaintProgressBar(x, y, w, color, client:GetNWString("TTTMediumSeanceMessage", ""), 1, #titles, titles)
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Medium_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_MEDIUM then
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]
        local detectiveColor = ROLE_COLORS[ROLE_DETECTIVE]
        local html = "The " .. ROLE_STRINGS[ROLE_MEDIUM] .. " is a " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " and a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose job is to find and eliminate their enemies."

        html = html .. "<span style='display: block; margin-top: 10px;'>Instead of getting a DNA Scanner like a vanilla <span style='color: rgb(" .. detectiveColor.r .. ", " .. detectiveColor.g .. ", " .. detectiveColor.b .. ")'>" .. ROLE_STRINGS[ROLE_DETECTIVE] .. "</span>, they have the ability to see the spirits of the dead as they move around the afterlife.</span>"

        -- Spirits
        if medium_spirit_color:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>Each player will have a randomly assigned <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>spirit color</span> allowing the " .. ROLE_STRINGS[ROLE_MEDIUM] .. " to keep track of track specific spirits.</span>"
        end

        -- Seances
        local seance_max_info = medium_seance_max_info:GetInt()
        if seance_max_info >= MEDIUM_SCANNED_NAME then
            html = html .. "<span style='display: block; margin-top: 10px;'>The ".. ROLE_STRINGS[ROLE_MEDIUM] .. " can <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>perform a seance</span> by staying close to a spirit. Performing a seance will reveal a spirit's name"
            if seance_max_info == MEDIUM_SCANNED_TEAM then
                html = html .. " and then their team"
            elseif seance_max_info == MEDIUM_SCANNED_ROLE then
                html = html .. ", then their team, and finally their role"
            end
            html = html .. ".</span>"
        end

        -- Spirit vision
        if spirit_vision then
            html = html .. "<span style='display: block; margin-top: 10px;'>The spirits of the dead can also <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>see eachother</span>!</span>"
        end

        -- Hide special detectives mode
        html = html .. "<span style='display: block; margin-top: 10px;'>Other players will know you are " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. " just by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>looking at you</span>"
        local special_detective_mode = GetConVar("ttt_detectives_hide_special_mode"):GetInt()
        if special_detective_mode > SPECIAL_DETECTIVE_HIDE_NONE then
            html = html .. ", but not what specific type of " .. ROLE_STRINGS[ROLE_DETECTIVE]
            if special_detective_mode == SPECIAL_DETECTIVE_HIDE_FOR_ALL then
                html = html .. ". <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Not even you know what type of " .. ROLE_STRINGS[ROLE_DETECTIVE] .. " you are</span>"
            end
        end
        html = html .. ".</span>"

        -- Killer role hiding
        if medium_hide_killer_role:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>When there is " .. ROLE_STRINGS_EXT[ROLE_MEDIUM] .. " in the round, players who kill others <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will have their role hidden</span> in death notifications.</span>"
        end

        return html
    end
end)