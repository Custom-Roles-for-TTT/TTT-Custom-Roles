local util = util
local surface = surface
local draw = draw

local GetPTranslation = LANG.GetParamTranslation
local GetRaw = LANG.GetRawTranslation

local key_params = { usekey = Key("+use", "USE"), walkkey = Key("+walk", "WALK") }

local ClassHint = {
    prop_ragdoll = {
        name = "corpse",
        hint = "corpse_hint",

        fmt = function(ent, txt) return GetPTranslation(txt, key_params) end
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

local indicator_mat_target_noz = Material("vgui/ttt/sprite_target_noz")

local function DrawRoleIcon(role, noz, pos, dir, color_role)
    local path = "vgui/ttt/sprite_" .. ROLE_STRINGS_SHORT[role]
    if noz then path = path .. "_noz" end
    local indicator_mat = Material(path)

    if noz then render.SetMaterial(indicator_mat_roleback_noz)
    else render.SetMaterial(indicator_mat_roleback) end
    render.DrawQuadEasy(pos, dir, 8, 8, ROLE_COLORS_SPRITE[color_role or role], 180)

    render.SetMaterial(indicator_mat)
    render.DrawQuadEasy(pos, dir, 8, 8, COLOR_WHITE, 180)

    if noz then render.SetMaterial(indicator_mat_rolefront_noz)
    else render.SetMaterial(indicator_mat_rolefront) end
    render.DrawQuadEasy(pos, dir, 8, 8, COLOR_WHITE, 180)
end

local client, plys, ply, pos, dir, tgt
local GetPlayers = player.GetAll

local propspec_outline = Material("models/props_combine/portalball001_sheet")

local function GetDetectiveIconRole(is_traitor)
    if is_traitor then
        if GetGlobalBool("ttt_impersonator_use_detective_icon", false) then
            return ROLE_DETECTIVE
        end
        return ROLE_IMPERSONATOR
    elseif GetGlobalBool("ttt_deputy_use_detective_icon", false) then
        return ROLE_DETECTIVE
    end
    return ROLE_DEPUTY
end

local function ShouldHideJesters(p)
    return (p:IsTraitorTeam() and not GetGlobalBool("ttt_jesters_visible_to_traitors", false)) or
            (p:IsMonsterTeam() and not GetGlobalBool("ttt_jesters_visible_to_monsters", false)) or
            (p:IsIndependentTeam() and not GetGlobalBool("ttt_jesters_visible_to_independents", false))
end

-- using this hook instead of pre/postplayerdraw because playerdraw seems to
-- happen before certain entities are drawn, which then clip over the sprite
function GM:PostDrawTranslucentRenderables()
    client = LocalPlayer()
    plys = GetPlayers()

    dir = client:GetForward() * -1

    local hide_roles = false
    if ConVarExists("ttt_hide_role") then
        hide_roles = GetConVar("ttt_hide_role"):GetBool()
    end

    for _, v in pairs(player.GetAll()) do
        -- Compatibility with the disguises, Dead Ringer (810154456), and Prop Disguiser (310403737 and 2127939503)
        local hidden = v:GetNWBool("disguised", false) or (v.IsFakeDead and v:IsFakeDead()) or v:GetNWBool("PD_Disguised", false)
        if v:IsActive() and v ~= client and not hidden then
            pos = v:GetPos()
            pos.z = pos.z + v:GetHeight() + 15

            local beggarMode = GetGlobalInt("ttt_beggar_reveal_traitor", 1)
            local hideBeggar = v:GetNWBool("WasBeggar", false) and (beggarMode == BEGGAR_REVEAL_NONE or beggarMode == BEGGAR_REVEAL_INNOCENTS)
            local showJester = ((v:IsJesterTeam() and not v:GetNWBool("KillerClownActive", false)) or ((v:GetTraitor() or v:GetInnocent()) and hideBeggar)) and not ShouldHideJesters(client)
            local glitchMode = GetGlobalInt("ttt_glitch_mode", 0)

            -- Only show the "KILL" target if the setting is enabled
            local showkillicon = ((client:IsAssassin() and GetGlobalBool("ttt_assassin_show_target_icon", false) and client:GetNWString("AssassinTarget") == v:Nick()) or
                                    (client:IsKiller() and GetGlobalBool("ttt_killer_show_target_icon", false)) or
                                    (client:IsZombie() and GetGlobalBool("ttt_zombie_show_target_icon", false) and client.GetActiveWeapon and IsValid(client:GetActiveWeapon()) and client:GetActiveWeapon():GetClass() == "weapon_zom_claws") or
                                    (client:IsVampire() and GetGlobalBool("ttt_vampire_show_target_icon", false)) or
                                    (client:IsClown() and client:GetNWBool("KillerClownActive", false) and GetGlobalBool("ttt_clown_show_target_icon", false)))
                                    and not showJester

            if showkillicon and not client:IsSameTeam(v) then -- If we are showing the "KILL" icon this should take priority over role icons
                render.SetMaterial(indicator_mat_roleback_noz)
                render.DrawQuadEasy(pos, dir, 8, 8, ROLE_COLORS_SPRITE[client:GetRole()], 180) -- Use the colour of whatever role the player currently is for the "KILL" icon

                render.SetMaterial(indicator_mat_target_noz)
                render.DrawQuadEasy(pos, dir, 8, 8, COLOR_WHITE, 180)

                render.SetMaterial(indicator_mat_rolefront_noz)
                render.DrawQuadEasy(pos, dir, 8, 8, COLOR_WHITE, 180)
            else
                if v:GetDetective() then
                    DrawRoleIcon(ROLE_DETECTIVE, false, pos, dir)
                elseif v:IsDetectiveTeam() then
                    DrawRoleIcon(v:GetRole(), false, pos, dir)
                elseif v:GetDetectiveLike() and not (v:GetImpersonator() and client:IsTraitorTeam()) then
                    DrawRoleIcon(GetDetectiveIconRole(false), false, pos, dir)
                elseif v:GetClown() and v:GetNWBool("KillerClownActive", false) and not GetGlobalBool("ttt_clown_hide_when_active", false) then
                    DrawRoleIcon(ROLE_CLOWN, false, pos, dir)
                end
                if not hide_roles then
                    if client:IsTraitorTeam() then
                        if (v:GetTraitor() and not hideBeggar) then
                            DrawRoleIcon(ROLE_TRAITOR, true, pos, dir)
                        elseif v:GetImpersonator() then
                            -- If the impersonator is promoted, use the Detective's icon with the Impersonator's color
                            if v:GetNWBool("HasPromotion", false) then
                                DrawRoleIcon(GetDetectiveIconRole(true), true, pos, dir, ROLE_IMPERSONATOR)
                            elseif glitchMode == GLITCH_HIDE_SPECIAL_TRAITOR_ROLES and GetGlobalBool("ttt_glitch_round", false) then
                                DrawRoleIcon(ROLE_TRAITOR, true, pos, dir)
                            else
                                DrawRoleIcon(ROLE_IMPERSONATOR, true, pos, dir)
                            end
                        -- If this is a vanilla traitor they should have been handled above and are therefore a converted beggar who should be hidden
                        elseif not v:GetTraitor() and v:IsTraitorTeam() then
                            if v:GetZombie() then
                                DrawRoleIcon(ROLE_ZOMBIE, true, pos, dir)
                            elseif glitchMode == GLITCH_HIDE_SPECIAL_TRAITOR_ROLES and GetGlobalBool("ttt_glitch_round", false) then
                                DrawRoleIcon(ROLE_TRAITOR, true, pos, dir)
                            else
                                DrawRoleIcon(v:GetRole(), true, pos, dir)
                            end
                        elseif showJester then
                            DrawRoleIcon(ROLE_JESTER, false, pos, dir)
                        elseif v:GetGlitch() then
                            if client:IsZombie() then
                                DrawRoleIcon(ROLE_ZOMBIE, true, pos, dir)
                            else
                                DrawRoleIcon(v:GetNWInt("GlitchBluff", ROLE_TRAITOR), true, pos, dir)
                            end
                        end
                    elseif client:IsMonsterTeam() then
                        if v:IsMonsterTeam() then
                            DrawRoleIcon(v:GetRole(), true, pos, dir)
                        elseif showJester then
                            DrawRoleIcon(ROLE_JESTER, false, pos, dir)
                        end
                    elseif client:IsKiller() then
                        if showJester then
                            DrawRoleIcon(ROLE_JESTER, false, pos, dir)
                        end
                    elseif client:IsIndependentTeam() then
                        if v:IsIndependentTeam() then
                            DrawRoleIcon(v:GetRole(), true, pos, dir)
                        elseif showJester then
                            DrawRoleIcon(ROLE_JESTER, false, pos, dir)
                        end
                    end
                end
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

local function DrawPropSpecLabels(client)
    if (not client:IsSpec()) and (GetRoundState() ~= ROUND_POST) then return end

    surface.SetFont("TabLarge")

    local tgt = nil
    local scrpos = nil
    local text = nil
    local w = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsSpec() then
            surface.SetTextColor(220, 200, 0, 120)

            tgt = ply:GetObserverTarget()

            if IsValid(tgt) and tgt:GetNWEntity("spec_owner", nil) == ply then

                scrpos = tgt:GetPos():ToScreen()
            else
                scrpos = nil
            end
        else
            local _, healthcolor = util.HealthToString(ply:Health(), ply:GetMaxHealth())
            surface.SetTextColor(clr(healthcolor))

            scrpos = ply:EyePos()
            scrpos.z = scrpos.z + 20

            scrpos = scrpos:ToScreen()
        end

        if scrpos and (not IsOffScreen(scrpos)) then
            text = ply:Nick()
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

    if hook.Call("HUDShouldDraw", GAMEMODE, "TTTPropSpec") then
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

    -- some bools for caching what kind of ent we are looking at
    local target_traitor = false
    local target_special_traitor = false
    local target_detective = false
    local target_special_detective = false

    local target_glitch = false

    local target_jester = false
    local target_clown = false

    local target_madscientist = false

    local target_zombie = false
    local target_vampire = false

    local target_revenger_lover = false
    local target_current_target = false
    local target_infected = false

    local target_corpse = false

    local glitchMode = GetGlobalInt("ttt_glitch_mode", 0)

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

        local beggarMode = GetGlobalInt("ttt_beggar_reveal_traitor", 1)
        local hideBeggar = ent:GetNWBool("WasBeggar", false) and (beggarMode == BEGGAR_REVEAL_NONE or beggarMode == BEGGAR_REVEAL_INNOCENTS)

        if not hide_roles and GetRoundState() == ROUND_ACTIVE then
            local showJester = ((ent:IsJesterTeam() and not ent:GetNWBool("KillerClownActive", false)) or ((ent:GetTraitor() or ent:GetInnocent()) and hideBeggar)) and not ShouldHideJesters(client)
            if client:IsTraitorTeam() then
                target_traitor = (ent:IsTraitor() and not hideBeggar)
                target_special_traitor = ent:IsTraitorTeam() and not ent:IsTraitor()
                target_glitch = ent:IsGlitch()

                if glitchMode == GLITCH_HIDE_SPECIAL_TRAITOR_ROLES and GetGlobalBool("ttt_glitch_round", false) then
                    if target_traitor or target_special_traitor or target_glitch then
                        target_traitor = false
                        target_special_traitor = false
                        target_glitch = true
                    end
                end

                target_jester = showJester

                target_infected = ent:GetNWBool("Infected", false)
            elseif client:IsMonsterTeam() then
                target_zombie = ent:IsZombie() and ent:IsMonsterTeam()
                target_vampire = ent:IsVampire() and ent:IsMonsterTeam()

                target_jester = showJester
            elseif client:IsIndependentTeam() then
                target_zombie = ent:IsZombie() and ent:IsIndependentTeam()
                target_madscientist = ent:IsMadScientist()

                target_jester = showJester
            end
        end

        target_detective = GetRoundState() > ROUND_PREP and (ent:IsDetective() or ((ent:IsDeputy() or (ent:IsImpersonator() and not client:IsTraitorTeam())) and ent:GetNWBool("HasPromotion", false)))
        target_special_detective = GetRoundState() > ROUND_PREP and ent:IsDetectiveTeam() and not target_detective
        if not GetGlobalBool("ttt_clown_hide_when_active", false) then
            target_clown = GetRoundState() > ROUND_PREP and ent:IsClown() and ent:GetNWBool("KillerClownActive", false)
        end

        if client:IsRevenger() then
            target_revenger_lover = (ent:SteamID64() == client:GetNWString("RevengerLover", ""))
        end

        if client:IsAssassin() then
            target_current_target = (ent:Nick() == client:GetNWString("AssassinTarget", ""))
        end

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
    elseif not hint then
        -- Not something to ID and not something to hint about
        return
    end

    local x_orig = ScrW() / 2.0
    local x = x_orig
    local y = ScrH() / 2.0

    local w, h = 0, 0 -- text width/height, reused several times

    if target_traitor or target_special_traitor or target_detective or target_special_detective or target_glitch or target_jester or target_clown or target_zombie or target_vampire then
        surface.SetTexture(ring_tex)

        if target_traitor then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_TRAITOR])
        elseif target_special_traitor then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_HYPNOTIST])
        elseif target_detective then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_DETECTIVE])
        elseif target_special_detective then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_PALADIN])
        elseif target_glitch then
            if client:IsZombie() and client:IsTraitorTeam() then
                surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_ZOMBIE])
            else
                local bluff = ent:GetNWInt("GlitchBluff", ROLE_TRAITOR)
                surface.SetDrawColor(ROLE_COLORS_RADAR[bluff])
            end
        elseif target_vampire then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_VAMPIRE])
        elseif target_zombie then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_ZOMBIE])
        elseif target_madscientist then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_MADSCIENTIST])
        elseif target_jester then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_JESTER])
        elseif target_clown then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_CLOWN])
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
    local clr = rag_color
    if ent:IsPlayer() then
        text, clr = util.HealthToString(ent:Health(), ent:GetMaxHealth())

        -- HealthToString returns a string id, need to look it up
        text = L[text]
    elseif hint then
        text = GetRaw(hint.name) or hint.name
    else
        return
    end
    font = "TargetIDSmall2"

    surface.SetFont(font)
    w, h = surface.GetTextSize(text)
    x = x_orig - w / 2

    draw.SimpleText(text, font, x + 1, y + 1, COLOR_BLACK)
    draw.SimpleText(text, font, x, y, clr)

    font = "TargetIDSmall"
    surface.SetFont(font)

    -- Draw second subtitle: karma
    if ent:IsPlayer() and KARMA.IsEnabled() then
        text, clr = util.KarmaToString(ent:GetBaseKarma())

        text = L[text]

        w, h = surface.GetTextSize(text)
        y = y + h + 5
        x = x_orig - w / 2

        draw.SimpleText(text, font, x + 1, y + 1, COLOR_BLACK)
        draw.SimpleText(text, font, x, y, clr)
    end

    -- Draw key hint
    if hint and hint.hint then
        if not hint.fmt then
            text = GetRaw(hint.hint) or hint.hint
        else
            text = hint.fmt(ent, hint.hint)
        end

        w, h = surface.GetTextSize(text)
        x = x_orig - w / 2
        y = y + h + 5
        draw.SimpleText(text, font, x + 1, y + 1, COLOR_BLACK)
        draw.SimpleText(text, font, x, y, COLOR_LGRAY)
    end

    text = nil

    if target_current_target then -- Prioritise target/soulmate message over roles
        text = L.target_current_target
        clr = ROLE_COLORS_RADAR[ROLE_ASSASSIN]
    elseif target_revenger_lover then
        text = L.target_revenger_lover
        clr = ROLE_COLORS_RADAR[ROLE_REVENGER]
    elseif target_infected then
        text = L.target_infected
        clr = ROLE_COLORS_RADAR[ROLE_PARASITE]
    elseif target_traitor then
        text = string.upper(ROLE_STRINGS[ROLE_TRAITOR])
        clr = ROLE_COLORS_RADAR[ROLE_TRAITOR]
    elseif target_special_traitor then
        local role = ent:GetRole()
        text = string.upper(ROLE_STRINGS[role])
        clr = ROLE_COLORS_RADAR[role]
    elseif target_glitch then
        local bluff = ent:GetNWInt("GlitchBluff", ROLE_TRAITOR)
        if client:IsZombie() and client:IsTraitorTeam() then
            bluff = ROLE_ZOMBIE
        end
        text = string.upper(ROLE_STRINGS[bluff])
        clr = ROLE_COLORS_RADAR[bluff]
    elseif target_detective then
        text = string.upper(ROLE_STRINGS[ROLE_DETECTIVE])
        clr = ROLE_COLORS_RADAR[ROLE_DETECTIVE]
    elseif target_special_detective then
        local role = ent:GetRole()
        text = string.upper(ROLE_STRINGS[role])
        clr = ROLE_COLORS_RADAR[role]
    elseif target_jester then
        text = string.upper(ROLE_STRINGS[ROLE_JESTER])
        clr = ROLE_COLORS_RADAR[ROLE_JESTER]
    elseif target_clown then
        text = string.upper(ROLE_STRINGS[ROLE_CLOWN])
        clr = ROLE_COLORS_RADAR[ROLE_CLOWN]
    elseif target_zombie then
        text = string.upper(ROLE_STRINGS[ROLE_ZOMBIE])
        clr = ROLE_COLORS_RADAR[ROLE_ZOMBIE]
    elseif target_madscientist then
        text = string.upper(ROLE_STRINGS[ROLE_MADSCIENTIST])
        clr = ROLE_COLORS_RADAR[ROLE_MADSCIENTIST]
    elseif target_vampire then
        text = string.upper(ROLE_STRINGS[ROLE_VAMPIRE])
        clr = ROLE_COLORS_RADAR[ROLE_VAMPIRE]
    elseif ent.sb_tag and ent.sb_tag.txt ~= nil then
        text = L[ent.sb_tag.txt]
        clr = ent.sb_tag.color
    elseif target_corpse and client:CanLootCredits(true) and CORPSE.GetCredits(ent, 0) > 0 then
        text = L.target_credits
        clr = COLOR_YELLOW
    end

    if text then
        w, h = surface.GetTextSize(text)
        x = x_orig - w / 2
        y = y + h + 5

        draw.SimpleText(text, font, x + 1, y + 1, COLOR_BLACK)
        draw.SimpleText(text, font, x, y, clr)
    end
end
