local cam = cam
local draw = draw
local ipairs = ipairs
local math = math
local pairs = pairs
local render = render
local surface = surface
local string = string
local table = table
local util = util

local CallHook = hook.Call
local RunHook = hook.Run
local GetAllPlayers = player.GetAll
local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation
local GetRaw = LANG.GetRawTranslation
local StringFormat = string.format
local StringUpper = string.upper

local key_params = { usekey = Key("+use", "USE"), walkkey = Key("+walk", "WALK"), adetective = ROLE_STRINGS_EXT[ROLE_DETECTIVE] }

local ClassHint = {
    prop_ragdoll = {
        name = "corpse",
        hint = "corpse_hint",

        fmt = function(ent, txt)
            if DetectiveMode() then
                -- Only show covert search label if the body can be searched
                if CORPSE.CanBeSearched(LocalPlayer(), ent) then
                    local ownerEnt = CORPSE.GetPlayer(ent)
                    -- and has not already
                    if IsValid(ownerEnt) and not ownerEnt:GetNWBool("body_searched", false) then
                        txt = txt .. "_covert"
                    end
                -- If the body can't be searched, change the label to say "call a Detective" instead
                else
                    txt = txt .. "_call"
                end
            end
            return GetPTranslation(txt, key_params)
        end
    }
};

-- Access for servers to display hints using their own HUD/UI.
function GM:GetClassHints()
    return ClassHint
end

-- Basic access for servers to add/modify hints. They override hints stored on
-- the entities themselves.
function GM:AddClassHint(cls, hint)
    ClassHint[cls] = table.Copy(hint)
end


---- "T" indicator above traitors

local indicator_mat_roleback = Material("vgui/ttt/sprite_roleback")
local indicator_mat_roleback_noz = Material("vgui/ttt/sprite_roleback_noz")
local indicator_mat_rolefront = Material("vgui/ttt/sprite_rolefront")
local indicator_mat_rolefront_noz = Material("vgui/ttt/sprite_rolefront_noz")

local indicator_mat_targetback = {down=Material("vgui/ttt/sprite_targetdownback"), up=Material("vgui/ttt/sprite_targetupback")}
local indicator_mat_targetback_noz = {down=Material("vgui/ttt/sprite_targetdownback_noz"), up=Material("vgui/ttt/sprite_targetupback_noz")}
local indicator_mat_targetfront = {down=Material("vgui/ttt/sprite_targetdownfront"), up=Material("vgui/ttt/sprite_targetupfront")}
local indicator_mat_targetfront_noz = {down=Material("vgui/ttt/sprite_targetdownfront_noz"), up=Material("vgui/ttt/sprite_targetupfront_noz")}

local client

local function DrawRoleIcon(role, noz, pos, dir, color_role, offset)
    local role_file_name = ROLE_STRINGS_SHORT[role]
    local cache_key = role_file_name
    if noz then
        cache_key = StringFormat("%s_noz", cache_key)
    end
    local indicator_mat = ROLE_SPRITE_ICON_MATERIALS[cache_key]

    if offset then
        pos = pos + (client:GetRight() * -5)
    end

    if noz then render.SetMaterial(indicator_mat_roleback_noz)
    else render.SetMaterial(indicator_mat_roleback) end
    render.DrawQuadEasy(pos, dir, 8, 8, ROLE_COLORS_SPRITE[color_role or role], 180)

    render.SetMaterial(indicator_mat)
    render.DrawQuadEasy(pos, dir, 8, 8, COLOR_WHITE, 180)

    if noz then render.SetMaterial(indicator_mat_rolefront_noz)
    else render.SetMaterial(indicator_mat_rolefront) end
    render.DrawQuadEasy(pos, dir, 8, 8, COLOR_WHITE, 180)
end

local targetIcons = {}

local function DrawTargetIcon(icon, noz, pos, dir, iconColor, iconType, offset)
    local iconFile = icon
    if noz then
        iconFile = StringFormat("%s_noz", iconFile)
    end
    local cache_key = StringFormat("%s_%s", iconType, iconFile)
    if not targetIcons[cache_key] then
        targetIcons[cache_key] = Material(StringFormat("vgui/ttt/targeticons/%s/sprite_target_%s.vmt", iconType, iconFile))
    end
    local indicator_mat = targetIcons[cache_key]

    if offset then
        pos = pos + (client:GetRight() * 5)
    end

    if noz then render.SetMaterial(indicator_mat_targetback_noz[iconType])
    else render.SetMaterial(indicator_mat_targetback[iconType]) end
    render.DrawQuadEasy(pos, dir, 8, 8, iconColor, 180)

    render.SetMaterial(indicator_mat)
    render.DrawQuadEasy(pos, dir, 8, 8, COLOR_WHITE, 180)

    if noz then render.SetMaterial(indicator_mat_targetfront_noz[iconType])
    else render.SetMaterial(indicator_mat_targetfront[iconType]) end
    render.DrawQuadEasy(pos, dir, 8, 8, COLOR_WHITE, 180)
end

local plys, ply, pos, dir, tgt

local propspec_outline = Material("models/props_combine/portalball001_sheet")

local function GetDetectiveIconRole(is_traitor)
    if is_traitor then
        if GetConVar("ttt_impersonator_use_detective_icon"):GetBool() then
            return ROLE_DETECTIVE
        end
        return ROLE_IMPERSONATOR
    elseif GetConVar("ttt_deputy_use_detective_icon"):GetBool() then
        return ROLE_DETECTIVE
    end
    return ROLE_DEPUTY
end

local function GetGlitchedRole(p, glitchMode)
    -- Use the player's role if they are a traitor, otherwise this is a glitch and we should use their fake role
    local role = p:IsTraitorTeam() and p:GetRole() or p:GetNWInt("GlitchBluff", ROLE_TRAITOR)
    -- Only hide vanilla traitors
    if glitchMode == GLITCH_SHOW_AS_TRAITOR then
        if role == ROLE_TRAITOR then
            return ROLE_NONE, ROLE_TRAITOR
        end
        return role, nil
    -- Hide all traitors, but show whether they are special or not based on the color
    elseif glitchMode == GLITCH_SHOW_AS_SPECIAL_TRAITOR then
        return ROLE_NONE, role
    end

    -- Hide all traitors, period
    return ROLE_NONE, ROLE_TRAITOR
end

-- using this hook instead of pre/postplayerdraw because playerdraw seems to
-- happen before certain entities are drawn, which then clip over the sprite
function GM:PostDrawTranslucentRenderables()
    client = LocalPlayer()
    plys = GetAllPlayers()

    dir = client:GetForward() * -1

    local glitchMode = GetConVar("ttt_glitch_mode"):GetInt()
    local glitchRound = GetGlobalBool("ttt_glitch_round", false)
    local hide_roles = false
    if ConVarExists("ttt_hide_role") then
        hide_roles = GetConVar("ttt_hide_role"):GetBool()
    end

    for _, v in pairs(plys) do
        -- Compatibility with the disguises, Dead Ringer (810154456), and Prop Disguiser (310403737 and 2127939503)
        local hidden = v:GetNWBool("disguised", false) or (v.IsFakeDead and v:IsFakeDead()) or v:GetNWBool("PD_Disguised", false)
        if v:IsActive() and v ~= client and not hidden and not CallHook("TTTTargetIDPlayerBlockIcon", nil, v, client) then
            pos = v:GetPos()
            pos.z = pos.z + v:GetHeight() + 15

            local hideBeggar = v:GetNWBool("WasBeggar", false) and not client:ShouldRevealBeggar(v)
            local hideBodysnatcher = v:GetNWBool("WasBodysnatcher", false) and not client:ShouldRevealBodysnatcher(v)
            local showJester = (v:ShouldActLikeJester() or ((v:GetTraitor() or v:GetInnocent()) and hideBeggar) or hideBodysnatcher) and not client:ShouldHideJesters()

            local role = nil
            local color_role = nil
            local noz = false
            if v:IsDetectiveTeam() then
                local disp_role, changed = v:GetDisplayedRole()
                -- If the displayed role was changed, use it for the color but use the question mark for the icon
                if changed then
                    color_role = disp_role
                    role = ROLE_NONE
                else
                    role = disp_role
                end
            elseif v:IsDetectiveLike() and not (v:IsImpersonator() and client:IsTraitorTeam()) then
                role = GetDetectiveIconRole(false)
            end
            if not hide_roles then
                if client:IsTraitorTeam() then
                    noz = true
                    if showJester then
                        role = ROLE_NONE
                        color_role = ROLE_JESTER
                        noz = false
                    elseif v:IsTraitorTeam() then
                        if glitchRound then
                            role, color_role = GetGlitchedRole(v, glitchMode)
                        -- If the impersonator is promoted, use the Detective's icon with the Impersonator's color
                        elseif v:IsImpersonator() and v:IsRoleActive() then
                            role = GetDetectiveIconRole(true)
                            color_role = ROLE_IMPERSONATOR
                        else
                            role = v:GetRole()
                        end
                    elseif v:IsGlitch() then
                        if client:IsZombie() then
                            role = ROLE_ZOMBIE
                        else
                            role, color_role = GetGlitchedRole(v, glitchMode)
                        end
                    -- Disable "No Z" for other icons like the Detective-like roles
                    else
                        noz = false
                    end
                elseif client:IsMonsterTeam() then
                    if showJester then
                        role = ROLE_NONE
                        color_role = ROLE_JESTER
                    elseif v:IsMonsterTeam() then
                        role = v:GetRole()
                        noz = true
                    end
                elseif client:IsIndependentTeam() then
                    if showJester and GetConVar("ttt_" .. ROLE_STRINGS_RAW[client:GetRole()] .. "_can_see_jesters"):GetBool() then
                        role = ROLE_NONE
                        color_role = ROLE_JESTER
                    end
                end
            end

            local newRole, newNoZ, newColorRole = CallHook("TTTTargetIDPlayerRoleIcon", nil, v, client, role, noz, color_role, hideBeggar, showJester, hideBodysnatcher)
            if newRole or (type(newRole) == "boolean" and not newRole) then role = newRole end
            if type(newNoZ) == "boolean" then noz = newNoZ end
            if newColorRole then color_role = newColorRole end

            local icon, iconNoZ, iconColor, iconType = CallHook("TTTTargetIDPlayerTargetIcon", nil, v, client, showJester)

            if not icon then  -- TODO: Remove after 2.0.0
                local showKillIcon = CallHook("TTTTargetIDPlayerKillIcon", nil, v, client, false, showJester)
                if showKillIcon then
                    icon = "kill"
                    iconNoZ = true
                    iconColor = ROLE_COLORS_SPRITE[client:GetRole()]
                    iconType = "down"
                end
            end

            local offset = role and icon

            if role then
                DrawRoleIcon(role, noz, pos, dir, color_role, offset)
            end
            if icon then
                DrawTargetIcon(icon, iconNoZ, pos, dir, iconColor, iconType, offset)
            end
        end
    end

    if client:Team() == TEAM_SPEC then
        cam.Start3D(EyePos(), EyeAngles())

        for i = 1, #plys do
            ply = plys[i]
            tgt = ply:GetObserverTarget()
            if IsValid(tgt) and tgt:GetNWEntity("spec_owner", nil) == ply then
                render.MaterialOverride(propspec_outline)
                render.SuppressEngineLighting(true)
                render.SetColorModulation(1, 0.5, 0)

                tgt:SetModelScale(1.05, 0)
                tgt:DrawModel()

                render.SetColorModulation(1, 1, 1)
                render.SuppressEngineLighting(false)
                render.MaterialOverride(nil)
            end
        end

        cam.End3D()
    end
end

---- Spectator labels

local function DrawPropSpecLabels(cli)
    if (not cli:IsSpec()) and (GetRoundState() ~= ROUND_POST) then return end

    surface.SetFont("TabLarge")

    local scrpos
    local text
    local w
    tgt = nil
    for _, p in ipairs(GetAllPlayers()) do
        if p:IsSpec() then
            surface.SetTextColor(220, 200, 0, 120)

            tgt = p:GetObserverTarget()

            if IsValid(tgt) and tgt:GetNWEntity("spec_owner", nil) == p then

                scrpos = tgt:GetPos():ToScreen()
            else
                scrpos = nil
            end
        else
            local _, healthcolor = util.HealthToString(p:Health(), p:GetMaxHealth())
            surface.SetTextColor(clr(healthcolor))

            scrpos = p:EyePos()
            scrpos.z = scrpos.z + 20

            scrpos = scrpos:ToScreen()
        end

        if scrpos and (not IsOffScreen(scrpos)) then
            text = p:Nick()
            w, _ = surface.GetTextSize(text)

            surface.SetTextPos(scrpos.x - w / 2, scrpos.y)
            surface.DrawText(text)
        end
    end
end


---- Crosshair affairs

surface.CreateFont("TargetIDSmall2", { font = "TargetID",
                                       size = 16,
                                       weight = 1000 })

local minimalist = CreateConVar("ttt_minimal_targetid", "0", FCVAR_ARCHIVE)

local magnifier_mat = Material("icon16/magnifier.png")
local ring_tex = surface.GetTextureID("effects/select_ring")

local rag_color = Color(200, 200, 200, 255)

local GetLang = LANG.GetUnsafeLanguageTable

local MAX_TRACE_LENGTH = math.sqrt(3) * 2 * 16384

function GM:HUDDrawTargetID()
    client = LocalPlayer()

    local L = GetLang()

    if RunHook("HUDShouldDraw", "TTTPropSpec") then
        DrawPropSpecLabels(client)
    end

    local startpos = client:EyePos()
    local endpos = client:GetAimVector()
    endpos:Mul(MAX_TRACE_LENGTH)
    endpos:Add(startpos)

    local trace = util.TraceLine({
        start = startpos,
        endpos = endpos,
        mask = MASK_SHOT,
        filter = client:GetObserverMode() == OBS_MODE_IN_EYE and { client, client:GetObserverTarget() } or client
    })
    local ent = trace.Entity
    if (not IsValid(ent)) or ent.NoTarget then return end

    if IsPlayer(ent) and CallHook("TTTTargetIDPlayerBlockInfo", nil, ent, client) then return end

    -- some bools for caching what kind of ent we are looking at
    local target_traitor = false
    local target_unknown_traitor = false
    local target_special_traitor = false
    local target_unknown_special_traitor = false

    local target_detective = false
    local target_unknown_detective = false
    local target_special_detective = false

    local target_glitch = false

    local target_jester = false

    local target_monster = false

    local target_corpse = false

    local glitchMode = GetConVar("ttt_glitch_mode"):GetInt()
    local glitchRound = GetGlobalBool("ttt_glitch_round", false)

    local text = nil
    local color = COLOR_WHITE

    -- if a vehicle, we identify the driver instead
    if IsValid(ent:GetNWEntity("ttt_driver", nil)) then
        ent = ent:GetNWEntity("ttt_driver", nil)

        if ent == client then return end
    end

    local cls = ent:GetClass()
    local minimal = minimalist:GetBool()
    local hint = (not minimal) and (ent.TargetIDHint or ClassHint[cls])
    if type(hint) == "function" then
        hint = hint()
    end

    local hide_roles = false
    if ConVarExists("ttt_hide_role") then
        hide_roles = GetConVar("ttt_hide_role"):GetBool()
    end

    if ent:IsPlayer() and ent:Alive() then
        -- Compatibility with the disguises, Dead Ringer (810154456), and Prop Disguiser (310403737 and 2127939503)
        local hidden = ent:GetNWBool("disguised", false) or (ent.IsFakeDead and ent:IsFakeDead()) or ent:GetNWBool("PD_Disguised", false)
        if hidden then
            client.last_id = nil

            if client:IsTraitor() or client:IsSpec() then
                text = ent:Nick() .. L.target_disg
            else
                -- Do not show anything
                return
            end

            color = COLOR_RED
        else
            text = ent:Nick()
            client.last_id = ent
        end

        local _ -- Stop global clutter
        -- in minimalist targetID, colour nick with health level
        if minimal then
            _, color = util.HealthToString(ent:Health(), ent:GetMaxHealth())
        end

        if not hide_roles and GetRoundState() == ROUND_ACTIVE then
            local hideBeggar = ent:GetNWBool("WasBeggar", false) and not client:ShouldRevealBeggar(ent)
            local hideBodysnatcher = ent:GetNWBool("WasBodysnatcher", false) and not client:ShouldRevealBodysnatcher(ent)
            local showJester = (ent:ShouldActLikeJester() or ((ent:GetTraitor() or ent:GetInnocent()) and hideBeggar) or hideBodysnatcher) and not client:ShouldHideJesters()
            if client:IsTraitorTeam() then
                if showJester then
                    target_jester = showJester
                else
                    target_traitor = ent:IsTraitor()
                    target_special_traitor = ent:IsTraitorTeam() and not ent:IsTraitor()
                    target_glitch = ent:IsGlitch()

                    if glitchRound and (target_traitor or target_special_traitor or (target_glitch and not GetGlobalBool("ttt_zombie_round", false))) then
                        local role, color_role = GetGlitchedRole(ent, glitchMode)
                        target_traitor = role == ROLE_TRAITOR
                        target_unknown_traitor = role == ROLE_NONE and color_role == ROLE_TRAITOR
                        target_special_traitor = role ~= ROLE_NONE and role ~= ROLE_TRAITOR
                        target_unknown_special_traitor = role == ROLE_NONE and color_role ~= ROLE_TRAITOR
                    end
                end
            elseif client:IsMonsterTeam() then
                if showJester then
                    target_jester = showJester
                elseif ent:IsMonsterTeam() then
                    target_monster = ent:GetRole()
                end
            elseif client:IsIndependentTeam() then
                if showJester and GetConVar("ttt_" .. ROLE_STRINGS_RAW[client:GetRole()] .. "_can_see_jesters"):GetBool() then
                    target_jester = showJester
                end
            end
        end

        if GetRoundState() > ROUND_PREP then
            local _, changed = ent:GetDisplayedRole()
            if (ent:IsDetective() and not changed) or ((ent:IsDeputy() or (ent:IsImpersonator() and not client:IsTraitorTeam())) and ent:IsRoleActive()) then
                target_detective = true
            elseif changed then
                target_unknown_detective = true
            elseif ent:IsDetectiveTeam() then
                target_special_detective = true
            end
        end

        -- Allow external roles to override or block showing player name
        local new_text, new_col = CallHook("TTTTargetIDPlayerName", nil, ent, client, text, color)
        -- If the first return value is a boolean and it's "false" then save that so we know to skip rendering the text
        if new_text or (type(new_text) == "boolean" and not new_text) then text = new_text end
        if new_col then color = new_col end
    elseif cls == "prop_ragdoll" then
        -- only show this if the ragdoll has a nick, else it could be a mattress
        if CORPSE.GetPlayerNick(ent, false) == false then return end

        target_corpse = true

        if CORPSE.GetFound(ent, false) or not DetectiveMode() then
            text = CORPSE.GetPlayerNick(ent, "A Terrorist")
        else
            text = L.target_unid
            color = COLOR_YELLOW
        end

        -- Allow external roles to override or block showing a ragdoll's name
        local new_text, new_col = CallHook("TTTTargetIDRagdollName", nil, ent, client, text, color)
        -- If the first return value is a boolean and it's "false" then save that so we know to skip rendering the text
        if new_text or (type(new_text) == "boolean" and not new_text) then text = new_text end
        if new_col then color = new_col end
    elseif not hint then
        -- Not something to ID and not something to hint about
        return
    end

    local x_orig = ScrW() / 2.0
    local x = x_orig
    local y = ScrH() / 2.0

    local w, h -- text width/height, reused several times

    local ring_visible = target_traitor or target_unknown_traitor or target_special_traitor or target_unknown_special_traitor or target_detective or target_unknown_detective or target_special_detective or target_glitch or target_jester or target_monster

    local new_visible, color_override = CallHook("TTTTargetIDPlayerRing", nil, ent, client, ring_visible)
    if type(new_visible) == "boolean" then ring_visible = new_visible end

    if ring_visible then
        surface.SetTexture(ring_tex)

        if color_override then
            surface.SetDrawColor(color_override)
        elseif target_traitor or target_unknown_traitor then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_TRAITOR])
        elseif target_special_traitor or target_unknown_special_traitor then
            surface.SetDrawColor(GetRoleTeamColor(ROLE_TEAM_TRAITOR, "radar"))
        elseif target_detective then
            local detective_role = ROLE_DETECTIVE
            -- Only override the info for non-detective detective-likes
            if not ent:IsDetectiveTeam() then
                detective_role = GetDetectiveIconRole(false)
            end
            surface.SetDrawColor(ROLE_COLORS_RADAR[detective_role])
        elseif target_unknown_detective then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_DETECTIVE])
        elseif target_special_detective then
            surface.SetDrawColor(GetRoleTeamColor(ROLE_TEAM_DETECTIVE, "radar"))
        elseif target_glitch then
            if client:IsZombie() and client:IsTraitorTeam() then
                surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_ZOMBIE])
            else
                local bluff = ent:GetNWInt("GlitchBluff", ROLE_TRAITOR)
                surface.SetDrawColor(ROLE_COLORS_RADAR[bluff])
            end
        elseif target_monster then
            surface.SetDrawColor(GetRoleTeamColor(ROLE_TEAM_MONSTER, "radar"))
        elseif target_jester then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_JESTER])
        end
        surface.DrawTexturedRect(x - 32, y - 32, 64, 64)
    end

    y = y + 30
    local font = "TargetID"
    surface.SetFont(font)

    -- Draw main title, ie. nickname
    if text then
        w, h = surface.GetTextSize(text)

        x = x - w / 2

        draw.SimpleText(text, font, x + 1, y + 1, COLOR_BLACK)
        draw.SimpleText(text, font, x, y, color)

        -- for ragdolls searched by detectives, add icon
        if ent.search_result and client:IsDetectiveLike() then
            -- if I am detective and I know a search result for this corpse, then I
            -- have searched it or another detective has
            surface.SetMaterial(magnifier_mat)
            surface.SetDrawColor(200, 200, 255, 255)
            surface.DrawTexturedRect(x + w + 5, y, 16, 16)
        end

        y = y + h + 4
    end

    -- Minimalist target ID only draws a health-coloured nickname, no hints, no
    -- karma, no tag
    if minimal then return end

    -- Draw subtitle: health or type
    local col = rag_color
    if ent:IsPlayer() then
        text, col = util.HealthToString(ent:Health(), ent:GetMaxHealth())

        -- HealthToString returns a string id, need to look it up
        text = L[text]

        -- Allow external roles to override or block showing health
        local new_text, new_col = CallHook("TTTTargetIDPlayerHealth", nil, ent, client, text, col)
        -- If the first return value is a boolean and it's "false" then save that so we know to skip rendering the text
        if new_text or (type(new_text) == "boolean" and not new_text) then text = new_text end
        if new_col then col = new_col end
    elseif hint then
        text = GetRaw(hint.name) or hint.name

        -- Allow external roles to override or block showing the hint label
        local new_text, new_col = CallHook("TTTTargetIDEntityHintLabel", nil, ent, client, text, col)
        -- If the first return value is a boolean and it's "false" then save that so we know to skip rendering the text
        if new_text or (type(new_text) == "boolean" and not new_text) then text = new_text end
        if new_col then col = new_col end
    else
        return
    end
    font = "TargetIDSmall2"

    if text and col then
        surface.SetFont(font)
        w, _ = surface.GetTextSize(text)
        x = x_orig - w / 2

        draw.SimpleText(text, font, x + 1, y + 1, COLOR_BLACK)
        draw.SimpleText(text, font, x, y, col)
    end

    font = "TargetIDSmall"
    surface.SetFont(font)

    -- Draw second subtitle: karma
    if ent:IsPlayer() and KARMA.IsEnabled() then
        text, col = util.KarmaToString(ent:GetBaseKarma())

        text = L[text]

        -- Allow external roles to override or block showing karma
        local new_text, new_col = CallHook("TTTTargetIDPlayerKarma", nil, ent, client, text, col)
        -- If the first return value is a boolean and it's "false" then save that so we know to skip rendering the text
        if new_text or (type(new_text) == "boolean" and not new_text) then text = new_text end
        if new_col then col = new_col end

        if text and col then
            w, h = surface.GetTextSize(text)
            y = y + h + 5
            x = x_orig - w / 2

            draw.SimpleText(text, font, x + 1, y + 1, COLOR_BLACK)
            draw.SimpleText(text, font, x, y, col)
        end
    end

    -- Draw key hint
    if hint and hint.hint then
        col = COLOR_LGRAY
        if not hint.fmt then
            text = GetRaw(hint.hint) or hint.hint
        else
            text = hint.fmt(ent, hint.hint)
        end

        -- Allow external roles to override or block showing karma
        local new_text, new_col = CallHook("TTTTargetIDPlayerHintText", nil, ent, client, text, col)
        -- If the first return value is a boolean and it's "false" then save that so we know to skip rendering the text
        if new_text or (type(new_text) == "boolean" and not new_text) then text = new_text end
        if new_col then col = new_col end

        if text and col then
            w, h = surface.GetTextSize(text)
            x = x_orig - w / 2
            y = y + h + 5
            draw.SimpleText(text, font, x + 1, y + 1, COLOR_BLACK)
            draw.SimpleText(text, font, x, y, col)
        end
    end

    text = nil
    if target_traitor then
        text = StringUpper(ROLE_STRINGS[ROLE_TRAITOR])
        col = ROLE_COLORS_RADAR[ROLE_TRAITOR]
    elseif target_unknown_traitor then
        text = GetPTranslation("target_unknown_team", { targettype = StringUpper(GetTranslation("traitor")) })
        col = ROLE_COLORS_RADAR[ROLE_TRAITOR]
    elseif target_special_traitor then
        local role = ent:GetRole()
        text = StringUpper(ROLE_STRINGS[role])
        col = ROLE_COLORS_RADAR[role]
    elseif target_unknown_special_traitor then
        text = GetPTranslation("target_unknown_team", { targettype = StringUpper(GetTranslation("traitor")) })
        col = ROLE_COLORS_RADAR[ROLE_ASSASSIN]
    elseif target_glitch then
        local bluff = ent:GetNWInt("GlitchBluff", ROLE_TRAITOR)
        if client:IsZombie() and client:IsTraitorTeam() then
            bluff = ROLE_ZOMBIE
        end
        text = StringUpper(ROLE_STRINGS[bluff])
        col = ROLE_COLORS_RADAR[bluff]
    elseif target_detective then
        local detective_role = ROLE_DETECTIVE
        -- Only override the info for non-detective detective-likes
        if not ent:IsDetectiveTeam() then
            detective_role = GetDetectiveIconRole(false)
        end
        text = StringUpper(ROLE_STRINGS[detective_role])
        col = ROLE_COLORS_RADAR[detective_role]
    elseif target_special_detective then
        local role = ent:GetRole()
        text = StringUpper(ROLE_STRINGS[role])
        col = ROLE_COLORS_RADAR[role]
    elseif target_unknown_detective then
        text = GetPTranslation("target_unknown_team", { targettype = StringUpper(ROLE_STRINGS[ROLE_DETECTIVE]) })
        col = ROLE_COLORS_RADAR[ROLE_DETECTIVE]
    elseif target_jester then
        text = GetPTranslation("target_unknown_team", { targettype = StringUpper(GetTranslation("jester")) })
        col = ROLE_COLORS_RADAR[ROLE_JESTER]
    elseif target_monster then
        text = StringUpper(ROLE_STRINGS[target_monster])
        col = GetRoleTeamColor(ROLE_TEAM_MONSTER, "radar")
    elseif ent.sb_tag and ent.sb_tag.txt ~= nil then
        text = L[ent.sb_tag.txt]
        col = ent.sb_tag.color
    elseif target_corpse and client:CanLootCredits(true) and CORPSE.GetCredits(ent, 0) > 0 then
        text = L.target_credits
        col = COLOR_YELLOW
    end

    local new_text, new_color, secondary_text, secondary_col = CallHook("TTTTargetIDPlayerText", nil, ent, client, text, col)
    -- If either text return value is a boolean and it's "false" then save that so we know to skip rendering the text
    if new_text or (type(new_text) == "boolean" and not new_text) then text = new_text end
    if new_color then col = new_color end

    if text then
        w, h = surface.GetTextSize(text)
        x = x_orig - w / 2
        y = y + h + 5

        draw.SimpleText(text, font, x + 1, y + 1, COLOR_BLACK)
        draw.SimpleText(text, font, x, y, col)
    end
    if secondary_text then
        w, h = surface.GetTextSize(secondary_text)
        x = x_orig - w / 2
        y = y + h + 5

        draw.SimpleText(secondary_text, font, x + 1, y + 1, COLOR_BLACK)
        draw.SimpleText(secondary_text, font, x, y, secondary_col or col)
    end
end