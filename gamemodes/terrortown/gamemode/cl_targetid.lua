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

            local hideBeggar = v:GetNWBool("WasBeggar", false) and not GetGlobalBool("ttt_beggar_reveal_change", true)
            local showJester = (v:IsJesterTeam() and not v:GetNWBool("KillerClownActive", false)) or ((v:GetTraitor() or v:GetInnocent()) and hideBeggar)

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
                elseif v:GetDetectiveLike() and not (v:GetImpersonator() and client:IsTraitorTeam()) then
                    DrawRoleIcon(GetDetectiveIconRole(false), false, pos, dir)
                elseif v:GetClown() and v:GetNWBool("KillerClownActive", false) and not GetGlobalBool("ttt_clown_hide_when_active", false) then
                    DrawRoleIcon(ROLE_CLOWN, false, pos, dir)
                end
                if not hide_roles then
                    if client:IsTraitorTeam() then
                        if (v:GetTraitor() and not hideBeggar) or v:GetGlitch() then
                            DrawRoleIcon(ROLE_TRAITOR, true, pos, dir)
                        elseif v:GetImpersonator() then
                            -- If the impersonator is promoted, use the Detective's icon with the Impersonator's color
                            if v:GetNWBool("HasPromotion", false) then
                                DrawRoleIcon(GetDetectiveIconRole(true), true, pos, dir, ROLE_IMPERSONATOR)
                            else
                                DrawRoleIcon(ROLE_IMPERSONATOR, true, pos, dir)
                            end
                        -- If this is a vanilla traitor they should have been handled above and are therefore a converted beggar who should be hidden
                        elseif not v:GetTraitor() and v:IsTraitorTeam() then
                            DrawRoleIcon(v:GetRole(), true, pos, dir)
                        elseif showJester then
                            DrawRoleIcon(ROLE_JESTER, false, pos, dir)
                        end
                    elseif client:IsMonsterTeam() then
                        if v:IsMonsterTeam() then
                            DrawRoleIcon(v:GetRole(), true, pos, dir)
                        elseif showJester then
                            DrawRoleIcon(ROLE_JESTER, false, pos, dir)
                        end
                    elseif client:IsIndependentTeam() then
                        if v:IsIndependentTeam() then
                            DrawRoleIcon(v:GetRole(), true, pos, dir)
                        elseif showJester then
                            DrawRoleIcon(ROLE_JESTER, false, pos, dir)
                        end
                    elseif client:IsKiller() then
                        if showJester then
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
    local target_detective = false
    local target_jester = false
    local target_hypnotist = false
    local target_clown = false
    local target_impersonator = false
    local target_assassin = false
    local target_zombie = false
    local target_fellow_zombie = false
    local target_vampire = false
    local target_quack = false
    local target_parasite = false

    local target_revenger_lover = false
    local target_current_target = false
    local target_infected = false

    local target_corpse = false

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

        local hideBeggar = ent:GetNWBool("WasBeggar", false) and not GetGlobalBool("ttt_beggar_reveal_change", true)

        if not hide_roles and GetRoundState() == ROUND_ACTIVE then
            local showJester = (ent:IsJesterTeam() and not ent:GetNWBool("KillerClownActive", false)) or ((ent:GetTraitor() or ent:GetInnocent()) and hideBeggar)
            if client:IsTraitorTeam() then
                target_traitor = (ent:IsTraitor() and not hideBeggar) or ent:IsGlitch()
                target_hypnotist = ent:IsHypnotist()
                target_impersonator = ent:IsImpersonator()
                target_assassin = ent:IsAssassin()
                target_quack = ent:IsQuack()
                target_parasite = ent:IsParasite()
                target_vampire = ent:IsVampire() and ent:IsTraitorTeam()
                if client:IsZombie() then
                    target_fellow_zombie = ent:IsZombie()
                else
                    target_zombie = ent:IsZombie() and ent:IsTraitorTeam()
                end
                target_jester = showJester

                target_infected = ent:GetNWBool("Infected", false)
            elseif client:IsMonsterTeam() then
                if client:IsZombie() then
                    target_fellow_zombie = ent:IsZombie()
                else
                    target_zombie = ent:IsZombie() and ent:IsMonsterTeam()
                end
                target_vampire = ent:IsVampire() and ent:IsMonsterTeam()
                target_jester = showJester
            elseif client:IsIndependentTeam() then
                if client:IsZombie() then
                    target_fellow_zombie = ent:IsZombie()
                else
                    target_zombie = ent:IsZombie() and ent:IsIndependentTeam()
                end
                target_jester = showJester
            end
        end

        target_detective = GetRoundState() > ROUND_PREP and (ent:IsDetective() or ((ent:IsDeputy() or (ent:IsImpersonator() and not client:IsTraitorTeam())) and ent:GetNWBool("HasPromotion", false)))
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

    if target_traitor or target_detective or target_jester or target_hypnotist or target_clown or target_zombie or target_fellow_zombie or target_vampire or target_quack or target_parasite then
        surface.SetTexture(ring_tex)

        if target_traitor then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_TRAITOR])
        elseif target_detective then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_DETECTIVE])
        elseif target_hypnotist or target_impersonator or target_assassin or target_quack or target_parasite then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_HYPNOTIST])
        elseif target_vampire then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_VAMPIRE])
        elseif target_zombie or target_fellow_zombie then
            surface.SetDrawColor(ROLE_COLORS_RADAR[ROLE_ZOMBIE])
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
        if ent.search_result and client:IsDetective() then
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
        text = L.target_traitor
        clr = ROLE_COLORS_RADAR[ROLE_TRAITOR]
    elseif target_detective then
        text = L.target_detective
        clr = ROLE_COLORS_RADAR[ROLE_DETECTIVE]
    elseif target_jester then
        text = L.target_jester
        clr = ROLE_COLORS_RADAR[ROLE_JESTER]
    elseif target_hypnotist then
        text = L.target_hypnotist
        clr = ROLE_COLORS_RADAR[ROLE_HYPNOTIST]
    elseif target_clown then
        text = L.target_clown
        clr = ROLE_COLORS_RADAR[ROLE_CLOWN]
    elseif target_impersonator then
        text = L.target_impersonator
        clr = ROLE_COLORS_RADAR[ROLE_IMPERSONATOR]
    elseif target_assassin then
        text = L.target_assassin
        clr = ROLE_COLORS_RADAR[ROLE_ASSASSIN]
    elseif target_zombie then
        text = L.target_zombie
        clr = ROLE_COLORS_RADAR[ROLE_ZOMBIE]
	elseif target_fellow_zombie then
		text = L.target_fellow_zombie
        clr = ROLE_COLORS_RADAR[ROLE_ZOMBIE]
    elseif target_vampire then
        text = L.target_vampire
        clr = ROLE_COLORS_RADAR[ROLE_VAMPIRE]
    elseif target_quack then
        text = L.target_quack
        clr = ROLE_COLORS_RADAR[ROLE_QUACK]
    elseif target_parasite then
        text = L.target_parasite
        clr = ROLE_COLORS_RADAR[ROLE_PARASITE]
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
