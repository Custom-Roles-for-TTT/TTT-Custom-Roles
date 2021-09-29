include("shared.lua")

-- Define GM12 fonts for compatibility
surface.CreateFont("DefaultBold", {
    font = "Tahoma",
    size = 13,
    weight = 1000 })
surface.CreateFont("TabLarge", {
    font = "Tahoma",
    size = 13,
    weight = 700,
    shadow = true, antialias = false })
surface.CreateFont("Trebuchet22", {
    font = "Trebuchet MS",
    size = 22,
    weight = 900 })

include("corpse_shd.lua")
include("player_ext_shd.lua")
include("weaponry_shd.lua")

include("vgui/ColoredBox.lua")
include("vgui/SimpleIcon.lua")
include("vgui/ProgressBar.lua")
include("vgui/ScrollLabel.lua")

include("cl_radio.lua")
include("cl_disguise.lua")
include("cl_transfer.lua")
include("cl_targetid.lua")
include("cl_search.lua")
include("cl_radar.lua")
include("cl_tbuttons.lua")
include("cl_scoreboard.lua")
include("cl_tips.lua")
include("cl_help.lua")
include("cl_hud.lua")
include("cl_msgstack.lua")
include("cl_hudpickup.lua")
include("cl_keys.lua")
include("cl_wepswitch.lua")
include("cl_scoring.lua")
include("cl_scoring_events.lua")
include("cl_popups.lua")
include("cl_equip.lua")
include("cl_voice.lua")
include("cl_roleweapons.lua")

local traitor_vision = false
local zombie_vision = false
local vampire_vision = false
local jesters_visible_to_traitors = false
local jesters_visible_to_monsters = false
local jesters_visible_to_independents = false
local vision_enabled = false

local function AddRoleTranslations()
    for role, lang_table in pairs(ROLE_TRANSLATIONS) do
        for lang, string_table in pairs(lang_table) do
            for name, value in pairs(string_table) do
                LANG.AddToLanguage(lang, name, value)
            end
        end
    end
end

function GM:Initialize()
    MsgN("TTT Client initializing...")

    GAMEMODE.round_state = ROUND_WAIT

    LANG.Init()

    AddRoleTranslations()

    self.BaseClass:Initialize()
end

function GM:InitPostEntity()
    MsgN("TTT Client post-init...")

    net.Start("TTT_Spectate")
    net.WriteBool(GetConVar("ttt_spectator_mode"):GetBool())
    net.SendToServer()

    if not game.SinglePlayer() then
        timer.Create("idlecheck", 5, 0, CheckIdle)
    end

    -- make sure player class extensions are loaded up, and then do some
    -- initialization on them
    local client = LocalPlayer()
    if IsValid(client) and client.GetTraitor then
        GAMEMODE:ClearClientState()
    end

    timer.Create("cache_ents", 1, 0, GAMEMODE.DoCacheEnts)

    RunConsoleCommand("_ttt_request_serverlang")
    RunConsoleCommand("_ttt_request_rolelist")

    UpdateRoleStrings()
end

function GM:DoCacheEnts()
    RADAR:CacheEnts()
    TBHUD:CacheEnts()
end

function GM:HUDClear()
    RADAR:Clear()
    TBHUD:Clear()
end

KARMA = {}
function KARMA.IsEnabled() return GetGlobalBool("ttt_karma", false) end

function GetRoundState() return GAMEMODE.round_state end

local function RoundStateChange(o, n)
    if n == ROUND_PREP then
        -- prep starts
        GAMEMODE:ClearClientState()
        GAMEMODE:CleanUpMap()

        -- show warning to spec mode players
        if GetConVar("ttt_spectator_mode"):GetBool() and IsValid(LocalPlayer()) then
            LANG.Msg("spec_mode_warning")
        end

        -- reset cached server language in case it has changed
        RunConsoleCommand("_ttt_request_serverlang")
    elseif n == ROUND_ACTIVE then
        -- round starts
        VOICE.CycleMuteState(MUTE_NONE)

        CLSCORE:ClearPanel()

        -- people may have died and been searched during prep
        for _, p in ipairs(player.GetAll()) do
            p.search_result = nil
        end

        -- clear blood decals produced during prep
        RunConsoleCommand("r_cleardecals")

        GAMEMODE.StartingPlayers = #util.GetAlivePlayers()
    elseif n == ROUND_POST then
        RunConsoleCommand("ttt_cl_traitorpopup_close")
    end

    -- stricter checks when we're talking about hooks, because this function may
    -- be called with for example o = WAIT and n = POST, for newly connecting
    -- players, which hooking code may not expect
    if n == ROUND_PREP then
        -- can enter PREP from any phase due to ttt_roundrestart
        hook.Call("TTTPrepareRound", GAMEMODE)
    elseif (o == ROUND_PREP) and (n == ROUND_ACTIVE) then
        hook.Call("TTTBeginRound", GAMEMODE)
    elseif (o == ROUND_ACTIVE) and (n == ROUND_POST) then
        hook.Call("TTTEndRound", GAMEMODE)
    end

    -- whatever round state we get, clear out the voice flags
    for _, v in ipairs(player.GetAll()) do
        v.traitor_gvoice = false
    end
end

concommand.Add("ttt_print_playercount", function() print(GAMEMODE.StartingPlayers) end)

--- optional sound cues on round start and end
CreateConVar("ttt_cl_soundcues", "0", FCVAR_ARCHIVE)

local cues = {
    Sound("ttt/thump01e.mp3"),
    Sound("ttt/thump02e.mp3")
};
local function PlaySoundCue()
    if GetConVar("ttt_cl_soundcues"):GetBool() then
        surface.PlaySound(table.Random(cues))
    end
end

GM.TTTBeginRound = PlaySoundCue
GM.TTTEndRound = PlaySoundCue

--- usermessages

local function ReceiveRole()
    -- Wait until now to update the teams so we know the globals have been synced
    UpdateRoleState()

    local role = net.ReadInt(8)

    -- after a mapswitch, server might have sent us this before we are even done
    -- loading our code
    local client = LocalPlayer()
    if not IsValid(client) or not client.SetRole then return end

    client:SetRole(role)

    -- Update the local state
    traitor_vision = GetGlobalBool("ttt_traitor_vision_enable", false)
    zombie_vision = GetGlobalBool("ttt_zombie_vision_enable", false)
    vampire_vision = GetGlobalBool("ttt_vampire_vision_enable", false)
    jesters_visible_to_traitors = GetGlobalBool("ttt_jesters_visible_to_traitors", false)
    jesters_visible_to_monsters = GetGlobalBool("ttt_jesters_visible_to_monsters", false)
    jesters_visible_to_independents = GetGlobalBool("ttt_jesters_visible_to_independents", false)

    -- Disable highlights on role change
    if vision_enabled then
        hook.Remove("PreDrawHalos", "AddPlayerHighlights")
        vision_enabled = false
    end

    if role > ROLE_NONE then
        Msg("You are: ")
        MsgN(string.upper(client:GetRoleString()))
    end
end
net.Receive("TTT_Role", ReceiveRole)

local function ReceiveRoleList()
    local role = net.ReadInt(8)
    local num_ids = net.ReadUInt(8)

    for _ = 1, num_ids do
        local eidx = net.ReadUInt(7) + 1 -- we - 1 worldspawn=0

        local ply = player.GetByID(eidx)
        if IsValid(ply) and ply.SetRole then
            ply:SetRole(role)

            if ply:IsTraitorTeam() then
                ply.traitor_gvoice = false -- assume traitorchat by default
            end
        end
    end
end
net.Receive("TTT_RoleList", ReceiveRoleList)

-- Round state comm
local function ReceiveRoundState()
    local o = GetRoundState()
    GAMEMODE.round_state = net.ReadUInt(3)

    if o ~= GAMEMODE.round_state then
        RoundStateChange(o, GAMEMODE.round_state)
    end

    MsgN("Round state: " .. GAMEMODE.round_state)
end
net.Receive("TTT_RoundState", ReceiveRoundState)

-- Cleanup at start of new round
function GM:ClearClientState()
    GAMEMODE:HUDClear()

    local client = LocalPlayer()
    if not IsValid(client) or not client.SetRole then return end -- code not loaded yet

    client:SetRole(ROLE_INNOCENT)

    client.equipment_items = EQUIP_NONE
    client.equipment_credits = 0
    client.bought = {}
    client.last_id = nil
    client.radio = nil
    client.called_corpses = {}
    client.revenger_lover_killers = {}

    VOICE.InitBattery()

    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then
            p.sb_tag = nil
            p:SetRole(ROLE_INNOCENT)
            p.search_result = nil
        end
    end

    VOICE.CycleMuteState(MUTE_NONE)
    RunConsoleCommand("ttt_mute_team_check", "0")

    if GAMEMODE.ForcedMouse then
        gui.EnableScreenClicker(false)
    end
end
net.Receive("TTT_ClearClientState", GM.ClearClientState)

function GM:CleanUpMap()
    -- Ragdolls sometimes stay around on clients. Deleting them can create issues
    -- so all we can do is try to hide them.
    for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
        if IsValid(ent) and CORPSE.GetPlayerNick(ent, "") ~= "" then
            ent:SetNoDraw(true)
            ent:SetSolid(SOLID_NONE)
            ent:SetColor(Color(0, 0, 0, 0))

            -- Horrible hack to make targetid ignore this ent, because we can't
            -- modify the collision group clientside.
            ent.NoTarget = true
        end
    end

    -- This cleans up decals since GMod v100
    game.CleanUpMap()
end

-- server tells us to call this when our LocalPlayer has spawned
local function PlayerSpawn()
    local as_spec = net.ReadBit() == 1
    if as_spec then
        TIPS.Show()
    else
        TIPS.Hide()
    end
end
net.Receive("TTT_PlayerSpawned", PlayerSpawn)

local function PlayerDeath()
    TIPS.Show()
end
net.Receive("TTT_PlayerDied", PlayerDeath)

function GM:ShouldDrawLocalPlayer(ply) return false end

local view = { origin = vector_origin, angles = angle_zero, fov = 0 }
function GM:CalcView(ply, origin, angles, fov)
    view.origin = origin
    view.angles = angles
    view.fov = fov

    -- first person ragdolling
    if ply:Team() == TEAM_SPEC and ply:GetObserverMode() == OBS_MODE_IN_EYE then
        local tgt = ply:GetObserverTarget()
        if IsValid(tgt) and (not tgt:IsPlayer()) then
            -- assume if we are in_eye and not speccing a player, we spec a ragdoll
            local eyes = tgt:LookupAttachment("eyes") or 0
            eyes = tgt:GetAttachment(eyes)
            if eyes then
                view.origin = eyes.Pos
                view.angles = eyes.Ang
            end
        end
    end

    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        local func = wep.CalcView
        if func then
            view.origin, view.angles, view.fov = func(wep, ply, origin * 1, angles * 1, fov)
        end
    end

    return view
end

function GM:AddDeathNotice() end
function GM:DrawDeathNotice() end

function GM:Think()
    local client = LocalPlayer()
    for _, v in pairs(player.GetAll()) do
        if v:Alive() and not v:IsSpec() then
            local shouldSmoke = v:GetNWBool("Haunted", false) and GetGlobalBool("ttt_phantom_killer_smoke")
            local smokeColor = COLOR_BLACK
            local smokeParticle = "particle/snow.vmt"
            local smokeOffset = Vector(0, 0, 30)

            -- Allow other addons to manipulate whether and how players smoke
            local newShouldSmoke, newSmokeColor, newSmokeParticle, newSmokeOffset = hook.Run("TTTShouldPlayerSmoke", v, client, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
            if type(newShouldSmoke) == "boolean" then shouldSmoke = newShouldSmoke end
            if newSmokeColor then smokeColor = newSmokeColor end
            if newSmokeParticle then smokeParticle = newSmokeParticle end
            if newSmokeOffset then smokeOffset = newSmokeOffset end

            if shouldSmoke then
                if not v.SmokeEmitter then v.SmokeEmitter = ParticleEmitter(v:GetPos()) end
                if not v.SmokeNextPart then v.SmokeNextPart = CurTime() end
                local pos = v:GetPos() + smokeOffset
                if v.SmokeNextPart < CurTime() then
                    if client:GetPos():Distance(pos) <= 3000 then
                        v.SmokeEmitter:SetPos(pos)
                        v.SmokeNextPart = CurTime() + math.Rand(0.003, 0.01)
                        local vec = Vector(math.Rand(-8, 8), math.Rand(-8, 8), math.Rand(10, 55))
                        local particle = v.SmokeEmitter:Add(smokeParticle, v:LocalToWorld(vec))
                        particle:SetVelocity(Vector(0, 0, 4) + VectorRand() * 3)
                        particle:SetDieTime(math.Rand(0.5, 2))
                        particle:SetStartAlpha(math.random(150, 220))
                        particle:SetEndAlpha(0)
                        local size = math.random(4, 7)
                        particle:SetStartSize(size)
                        particle:SetEndSize(size + 1)
                        particle:SetRoll(0)
                        particle:SetRollDelta(0)
                        particle:SetColor(smokeColor.r, smokeColor.g, smokeColor.b)
                    end
                end
            else
                if v.SmokeEmitter then
                    v.SmokeEmitter:Finish()
                    v.SmokeEmitter = nil
                end
            end
            if v:IsPaladin() then
                if not v.AuraEmitter then v.AuraEmitter = ParticleEmitter(v:GetPos()) end
                if not v.AuraNextPart then v.AuraNextPart = CurTime() end
                if not v.AuraDir then v.AuraDir = 0 end
                local pos = v:GetPos() + Vector(0, 0, 30)
                if v.AuraNextPart < CurTime() then
                    if client:GetPos():Distance(pos) <= 3000 then
                        v.AuraEmitter:SetPos(pos)
                        v.AuraNextPart = CurTime() + 0.02
                        v.AuraDir = v.AuraDir + 0.05
                        local radius = GetGlobalFloat("ttt_paladin_aura_radius", 262.45)
                        local vec = Vector(math.sin(v.AuraDir) * radius, math.cos(v.AuraDir) * radius, 10)
                        local particle = v.AuraEmitter:Add("particle/shield.vmt", v:GetPos() + vec)
                        particle:SetVelocity(Vector(0, 0, 20))
                        particle:SetDieTime(1)
                        particle:SetStartAlpha(200)
                        particle:SetEndAlpha(0)
                        particle:SetStartSize(3)
                        particle:SetEndSize(2)
                        particle:SetRoll(0)
                        particle:SetRollDelta(0)
                        particle:SetColor(ROLE_COLORS[ROLE_PALADIN].r, ROLE_COLORS[ROLE_PALADIN].g, ROLE_COLORS[ROLE_PALADIN].b)
                    end
                end
            else
                if v.AuraEmitter then
                    v.AuraEmitter:Finish()
                    v.AuraEmitter = nil
                end
            end
        end
    end
    if client:IsActiveMedium() then
        for _, ent in pairs(ents.GetAll()) do
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
                        ent.WispNextPart = CurTime() + math.Rand(0.003, 0.01)
                        local particle = ent.WispEmitter:Add("particle/wisp.vmt", pos)
                        particle:SetVelocity(Vector(0, 0, 30))
                        particle:SetDieTime(1)
                        particle:SetStartAlpha(math.random(150, 220))
                        particle:SetEndAlpha(0)
                        local size = math.random(4, 7)
                        particle:SetStartSize(size)
                        particle:SetEndSize(1)
                        particle:SetRoll(math.Rand(0, math.pi))
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
    end
end

function GM:Tick()
    local client = LocalPlayer()
    if IsValid(client) then
        if client:Alive() and client:Team() ~= TEAM_SPEC then
            WSWITCH:Think()
            RADIO:StoreTarget()
            if traitor_vision or zombie_vision or vampire_vision then
                HandleRoleHighlights(client)
            end
        end

        VOICE.Tick()
    end
end

-- Simple client-based idle checking
local idle = { ang = nil, pos = nil, mx = 0, my = 0, t = 0 }
function CheckIdle()
    local client = LocalPlayer()
    if not IsValid(client) then return end

    if not idle.ang or not idle.pos then
        -- init things
        idle.ang = client:GetAngles()
        idle.pos = client:GetPos()
        idle.mx = gui.MouseX()
        idle.my = gui.MouseY()
        idle.t = CurTime()

        return
    end

    if GetRoundState() == ROUND_ACTIVE and client:IsTerror() and client:Alive() then
        local idle_limit = GetGlobalInt("ttt_idle_limit", 300) or 300
        if idle_limit <= 0 then idle_limit = 300 end -- networking sucks sometimes


        if client:GetAngles() ~= idle.ang then
            -- Normal players will move their viewing angles all the time
            idle.ang = client:GetAngles()
            idle.t = CurTime()
        elseif gui.MouseX() ~= idle.mx or gui.MouseY() ~= idle.my then
            -- Players in eg. the Help will move their mouse occasionally
            idle.mx = gui.MouseX()
            idle.my = gui.MouseY()
            idle.t = CurTime()
        elseif client:GetPos():Distance(idle.pos) > 10 then
            -- Even if players don't move their mouse, they might still walk
            idle.pos = client:GetPos()
            idle.t = CurTime()
        elseif CurTime() > (idle.t + idle_limit) then
            RunConsoleCommand("say", "(AUTOMATED MESSAGE) I have been moved to the Spectator team because I was idle/AFK.")

            timer.Simple(0.3, function()
                RunConsoleCommand("ttt_spectator_mode", 1)
                net.Start("TTT_Spectate")
                net.WriteBool(true)
                net.SendToServer()
                RunConsoleCommand("ttt_cl_idlepopup")
            end)
        elseif CurTime() > (idle.t + (idle_limit / 2)) then
            -- will repeat
            LANG.Msg("idle_warning")
        end
    end
end

function GM:OnEntityCreated(ent)
    -- Make ragdolls look like the player that has died
    if ent:IsRagdoll() then
        local ply = CORPSE.GetPlayer(ent)

        if IsValid(ply) then
            -- Only copy any decals if this ragdoll was recently created
            if ent:GetCreationTime() > CurTime() - 1 then
                ent:SnatchModelInstance(ply)
            end

            -- Copy the color for the PlayerColor matproxy
            local playerColor = ply:GetPlayerColor()
            ent.GetPlayerColor = function()
                return playerColor
            end
        end
    end

    return self.BaseClass.OnEntityCreated(self, ent)
end

-- Clown and Jester confetti
local confetti = Material("confetti.png")
local function Celebrate(ply, sound, show_confetti)
    if not IsValid(ply) then return end
    if sound ~= nil then
        ply:EmitSound(sound)
    end

    if not show_confetti then return end

    local pos = ply:GetPos() + Vector(0, 0, ply:OBBMaxs().z)
    if ply.GetShootPos then
        pos = ply:GetShootPos()
    end

    local velMax = 200
    local gravMax = 50
    local gravity = Vector(math.random(-gravMax, gravMax), math.random(-gravMax, gravMax), math.random(-gravMax, 0))

    --Handles particles
    local emitter = ParticleEmitter(pos, true)
    for _ = 1, 150 do
        local p = emitter:Add(confetti, pos)
        p:SetStartSize(math.random(6, 10))
        p:SetEndSize(0)
        p:SetAngles(Angle(math.random(0, 360), math.random(0, 360), math.random(0, 360)))
        p:SetAngleVelocity(Angle(math.random(5, 50), math.random(5, 50), math.random(5, 50)))
        p:SetVelocity(Vector(math.random(-velMax, velMax), math.random(-velMax, velMax), math.random(-velMax, velMax)))
        p:SetColor(255, 255, 255)
        p:SetDieTime(math.random(4, 7))
        p:SetGravity(gravity)
        p:SetAirResistance(125)
    end
    emitter:Finish()
end

net.Receive("TTT_JesterDeathCelebration", function()
    local ent = net.ReadEntity()
    local play_sound = net.ReadBool()
    local show_confetti = net.ReadBool()

    local sound = nil
    if play_sound then
        sound = "birthday.wav"
    end

    Celebrate(ent, sound, show_confetti)
end)

net.Receive("TTT_ClownActivate", function()
    local ent = net.ReadEntity()
    Celebrate(ent, "clown.wav", true)

    local name = ent:Nick()
    CLSCORE:AddEvent({
        id = EVENT_CLOWNACTIVE,
        ply = name
    })
end)

-- Hit Markers
-- Creator: Exho
local hm_toggle = CreateClientConVar("hm_enabled", "1", true, true)
local hm_type = CreateClientConVar("hm_hitmarkertype", "lines", true, true)
local hm_color = CreateClientConVar("hm_hitmarkercolor", "255, 255, 255", true, true)
local hm_crit = CreateClientConVar("hm_showcrits", "1", true, true)
local hm_critcolor = CreateClientConVar("hm_hitmarkercritcolor", "255, 0, 0", true, true)
local hm_sound = CreateClientConVar("hm_hitsound", "0", true, true)
local hm_DrawHitM = false
local hm_LastHitCrit = false
local hm_CanPlayS = true
local hm_Alpha = 0

local function GrabColor() -- Used for retrieving the console color
    local coltable = string.Explode(",", hm_color:GetString())
    local newcol = {}

    for k, v in pairs(coltable) do
        v = tonumber(v)
        if v == nil then -- Fixes missing values
            coltable[k] = 0
        end
    end
    newcol[1], newcol[2], newcol[3] = coltable[1] or 0, coltable[2] or 0, coltable[3] or 0 -- Fixes missing keys
    return Color(newcol[1], newcol[2], newcol[3]) -- Returns the finished color
end

local function GrabCritColor() -- Used for retrieving the console color
    local coltable = string.Explode(",", hm_critcolor:GetString())
    local newcol = {}

    for k, v in pairs(coltable) do
        v = tonumber(v)
        if v == nil then -- Fixes missing values
            coltable[k] = 0
        end
    end
    newcol[1], newcol[2], newcol[3] = coltable[1] or 0, coltable[2] or 0, coltable[3] or 0 -- Fixes missing keys
    return Color(newcol[1], newcol[2], newcol[3]) -- Returns the finished color
end

net.Receive("TTT_OpenMixer", function(len, ply) -- Receive the server message
    local crit = net.ReadBool()

    -- Creating the color mixer panel
    local frame = vgui.Create("DFrame")
    if crit then
        frame:SetTitle("Hitmarker Critical Color Config")
    else
        frame:SetTitle("Hitmarker Color Config")
    end
    frame:SetSize(300, 400)
    frame:Center()
    frame:MakePopup()

    local colMix = vgui.Create("DColorMixer", frame)
    colMix:Dock(TOP)
    colMix:SetPalette(true)
    colMix:SetAlphaBar(false)
    colMix:SetWangs(false)
    -- Sets the default color to your current one
    if crit then
        colMix:SetColor(GrabCritColor())
    else
        colMix:SetColor(GrabColor())
    end

    local button = vgui.Create("DButton", frame)
    button:SetText("Set Color")
    button:SetSize(150, 70)
    button:SetPos(70, 290)
    button.DoClick = function(b) -- Concatenate your choices together and set the color
        local colors = colMix:GetColor()
        local colstring = tostring(colors.r .. ", " .. colors.g .. ", " .. colors.b)
        if crit then
            RunConsoleCommand("hm_hitmarkercritcolor", colstring)
        else
            RunConsoleCommand("hm_hitmarkercolor", colstring)
        end
    end
end)

net.Receive("TTT_DrawHitMarker", function(len, ply)
    hm_DrawHitM = true
    hm_CanPlayS = true
    if net.ReadBool() then
        hm_LastHitCrit = true
    else
        hm_LastHitCrit = false
    end
    hm_Alpha = 255
end)

net.Receive("TTT_CreateBlood", function()
    local pos = net.ReadVector()
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(1)
    util.Effect("bloodimpact", effect)
end)

hook.Add("HUDPaint", "HitmarkerDrawer", function()
    if hm_toggle:GetBool() == false then return end -- Enables/Disables the hitmarkers
    if hm_Alpha == 0 then hm_DrawHitM = false hm_CanPlayS = true end -- Removes them after they decay

    if hm_DrawHitM == true then
        if hm_CanPlayS and hm_sound:GetBool() == true then
            surface.PlaySound("hitmarkers/mlghit.wav")
            hm_CanPlayS = false
        end

        local x = ScrW() / 2
        local y = ScrH() / 2

        hm_Alpha = math.Approach(hm_Alpha, 0, 5)
        local col = GrabColor()
        if hm_LastHitCrit and hm_crit:GetBool() then
            col = GrabCritColor()
        end
        col.a = hm_Alpha
        surface.SetDrawColor(col)

        local sel = string.lower(hm_type:GetString())
        -- The drawing part of the hitmarkers and the various types you can choose
        if sel == "lines" then
            surface.DrawLine(x - 6, y - 5, x - 11, y - 10)
            surface.DrawLine(x + 5, y - 5, x + 10, y - 10)
            surface.DrawLine(x - 6, y + 5, x - 11, y + 10)
            surface.DrawLine(x + 5, y + 5, x + 10, y + 10)
        elseif sel == "sidesqr_lines" then
            surface.DrawLine(x - 15, y, x, y + 15)
            surface.DrawLine(x + 15, y, x, y - 15)
            surface.DrawLine(x, y + 15, x + 15, y)
            surface.DrawLine(x, y - 15, x - 15, y)
            surface.DrawLine(x - 5, y - 5, x - 10, y - 10)
            surface.DrawLine(x + 5, y - 5, x + 10, y - 10)
            surface.DrawLine(x - 5, y + 5, x - 10, y + 10)
            surface.DrawLine(x + 5, y + 5, x + 10, y + 10)
        elseif sel == "sqr_rot" then
            surface.DrawLine(x - 15, y, x, y + 15)
            surface.DrawLine(x + 15, y, x, y - 15)
            surface.DrawLine(x, y + 15, x + 15, y)
            surface.DrawLine(x, y - 15, x - 15, y)
        else -- Defaults to 'lines' in case of an incorrect type
            surface.DrawLine(x - 6, y - 5, x - 11, y - 10)
            surface.DrawLine(x + 5, y - 5, x + 10, y - 10)
            surface.DrawLine(x - 6, y + 5, x - 11, y + 10)
            surface.DrawLine(x + 5, y + 5, x + 10, y + 10)
        end
    end
end)

-- Sprint
local function ConVars()
    net.Start("TTT_SprintGetConVars")
    net.SendToServer()
end

-- Set default Values
local speedMultiplier = 0.4
local recovery = 0.08
local traitorRecovery = 0.12
local consumption = 0.3
local stamina = 100
local sprinting = false
local crosshairSize = 1
local sprintTimer = CurTime()
local recoveryTimer = CurTime()

-- Receive ConVars (SERVER)
net.Receive("TTT_SprintGetConVars", function()
    local convars = net.ReadTable()
    speedMultiplier = convars[1]
    recovery = convars[2]
    traitorRecovery = convars[3]
    consumption = convars[4]
end)

-- Requesting ConVars first time
ConVars()

-- Change the Speed
local function SpeedChange(bool)
    local client = LocalPlayer()
    net.Start("TTT_SprintSpeedSet")
    if bool then
        local mul = math.min(math.max(speedMultiplier, 0.1), 2)
        net.WriteFloat(mul)
        client.mult = 1 + mul

        local tmp = GetConVar("ttt_crosshair_size")
        crosshairSize = tmp and tmp:GetString() or 1
        RunConsoleCommand("ttt_crosshair_size", "2")
    else
        net.WriteFloat(0)
        client.mult = nil

        RunConsoleCommand("ttt_crosshair_size", crosshairSize)
    end

    net.SendToServer()
end

-- Sprint activated (sprint if there is stamina)
local function SprintFunction()
    if stamina > 0 then
        if not sprinting then
            SpeedChange(true)
            sprinting = true
            sprintTimer = CurTime()
        end
        stamina = stamina - (CurTime() - sprintTimer) * (math.min(math.max(consumption, 0.1), 5) * 250)
        local result = hook.Call("TTTSprintStaminaPost", GAMEMODE, LocalPlayer(), stamina, sprintTimer, consumption)
        -- Use the overwritten stamina if one is provided
        if result then
            stamina = result
        end
        sprintTimer = CurTime()
    else
        if sprinting then
            SpeedChange(false)
            sprinting = false
        end
    end
end

hook.Add("TTTPrepareRound", "TTTSprintPrepareRound", function()
    -- reset every round
    stamina = 100
    ConVars()

    -- listen for activation
    hook.Add("Think", "TTTSprintThink", function()
        local client = LocalPlayer()
        local forward_key = hook.Call("TTTSprintKey", GAMEMODE, client) or IN_FORWARD
        if client:KeyDown(forward_key) and client:KeyDown(IN_SPEED) then
            -- forward + selected key
            SprintFunction()
            recoveryTimer = CurTime()
        else
            if sprinting then
                -- not sprinting
                SpeedChange(false)
                sprinting = false
                recoveryTimer = CurTime()
            end

            if GetRoundState() ~= ROUND_WAIT then
                if IsPlayer(client) and (client:IsTraitorTeam() or client:IsMonsterTeam() or client:IsIndependentTeam()) then
                    stamina = stamina + (CurTime() - recoveryTimer) * traitorRecovery * 250
                else
                    stamina = stamina + (CurTime() - recoveryTimer) * recovery * 250
                end
            end

            recoveryTimer = CurTime()
        end

        if stamina < 0 then
            -- prevent bugs
            stamina = 0
            SpeedChange(false)
            sprinting = false
            recoveryTimer = CurTime()
        elseif stamina > 100 then
            stamina = 100
        end
        if IsPlayer(client) then
            client:SetNWFloat("sprintMeter", stamina)
        end
    end)
end)

-- Set Sprint Speed
hook.Add("TTTPlayerSpeedModifier", "TTTSprintPlayerSpeed", function(sply, _, _)
    if sply ~= LocalPlayer() then return end
    return GetSprintMultiplier(sply, sprinting)
end)

-- Death messages
net.Receive("TTT_ClientDeathNotify", function()
    -- Read the variables from the message
    local name = net.ReadString()
    local role = net.ReadInt(8)
    local reason = net.ReadString()

    -- Format the number role into a human readable role and identifying color
    local roleString = ROLE_STRINGS_EXT[role]
    local col = ROLE_COLORS_HIGHLIGHT[role]

    -- Format the reason for their death
    if reason == "suicide" then
        chat.AddText(COLOR_WHITE, "You killed yourself!")
    elseif reason == "burned" then
        chat.AddText(COLOR_WHITE, "You burned to death!")
    elseif reason == "prop" then
        chat.AddText(COLOR_WHITE, "You were killed by a prop!")
    elseif reason == "ply" then
        chat.AddText(COLOR_WHITE, "You were killed by ", col, name, COLOR_WHITE, ", they were ", col, roleString .. "!")
    elseif reason == "fell" then
        chat.AddText(COLOR_WHITE, "You fell to your death!")
    elseif reason == "water" then
        chat.AddText(COLOR_WHITE, "You drowned!")
    else
        chat.AddText(COLOR_WHITE, "You died!")
    end
end)

-- Player highlights

function OnPlayerHighlightEnabled(client, alliedRoles, showJesters, hideEnemies, traitorAllies)
    if GetRoundState() ~= ROUND_ACTIVE then return end
    local enemies = {}
    local friends = {}
    local jesters = {}
    for _, v in pairs(player.GetAll()) do
        if IsValid(v) and v:Alive() and not v:IsSpec() and v ~= client then
            if showJesters and v:ShouldActLikeJester() then
                table.insert(jesters, v)
            elseif table.HasValue(alliedRoles, v:GetRole()) then
                table.insert(friends, v)
            -- Don't even track enemies if this role can't see them
            elseif not hideEnemies then
                table.insert(enemies, v)
            end
        end
    end

    -- If the allies of this role are Traitors, show them in red to be thematic
    if traitorAllies then
        halo.Add(friends, ROLE_COLORS[ROLE_TRAITOR], 1, 1, 1, true, true)
    -- Otherwise green is good
    else
        halo.Add(friends, ROLE_COLORS[ROLE_INNOCENT], 1, 1, 1, true, true)
    end

    -- Don't show enemies if we're hiding them
    if not hideEnemies then
        -- If the allies of this role are Traitors, show enemies as green to be difference
        if traitorAllies then
            halo.Add(enemies, ROLE_COLORS[ROLE_INNOCENT], 1, 1, 1, true, true)
        else
            halo.Add(enemies, ROLE_COLORS[ROLE_TRAITOR], 1, 1, 1, true, true)
        end
    end

    halo.Add(jesters, ROLE_COLORS[ROLE_JESTER], 1, 1, 1, true, true)
end

local function EnableTraitorHighlights(client)
    hook.Add("PreDrawHalos", "AddPlayerHighlights", function()
        -- Start with the list of traitors
        local allies = GetTeamRoles(TRAITOR_ROLES)
        -- And add the glitch
        table.insert(allies, ROLE_GLITCH)

        OnPlayerHighlightEnabled(client, allies, jesters_visible_to_traitors, true, true)
    end)
end
local function EnableZombieHighlights(client)
    hook.Add("PreDrawHalos", "AddPlayerHighlights", function()
        local hasClaws = client.GetActiveWeapon and IsValid(client:GetActiveWeapon()) and client:GetActiveWeapon():GetClass() == "weapon_zom_claws"
        local hideEnemies = not zombie_vision or not hasClaws
        local allies = {}
        local traitorAllies = TRAITOR_ROLES[ROLE_ZOMBIE]
        local showJesters = false
        -- If zombies are traitors and traitor vision or zombie vision is enabled then add all the traitor roles as allies
        if (traitor_vision or zombie_vision) and traitorAllies then
            allies = GetTeamRoles(TRAITOR_ROLES)
            showJesters = jesters_visible_to_traitors
        -- If zombie vision is enabled, add the allied roles
        elseif zombie_vision then
            -- If they are monsters, ally with Zombies and monster-Vampires
            if MONSTER_ROLES[ROLE_ZOMBIE] then
                allies = {ROLE_ZOMBIE}
                if MONSTER_ROLES[ROLE_VAMPIRE] then
                    table.insert(allies, ROLE_VAMPIRE)
                end
                showJesters = jesters_visible_to_monsters
            else
                allies = GetTeamRoles(INDEPENDENT_ROLES)
                showJesters = jesters_visible_to_independents
            end
        end

        OnPlayerHighlightEnabled(client, allies, showJesters, hideEnemies, traitorAllies)
    end)
end
local function EnableVampireHighlights(client)
    hook.Add("PreDrawHalos", "AddPlayerHighlights", function()
        local hasFangs = client.GetActiveWeapon and IsValid(client:GetActiveWeapon()) and client:GetActiveWeapon():GetClass() == "weapon_vam_fangs"
        local hideEnemies = not vampire_vision or not hasFangs
        local allies = {}
        local traitorAllies = TRAITOR_ROLES[ROLE_VAMPIRE]
        local showJesters = false
        -- If vampires are traitors and traitor vision or vampire vision is enabled then add all the traitor roles as allies
        if (traitor_vision or vampire_vision) and traitorAllies then
            allies = GetTeamRoles(TRAITOR_ROLES)
            showJesters = jesters_visible_to_traitors
        -- If vampire vision is enabled, add the allied roles
        elseif vampire_vision then
            -- If they are monsters, ally with Vampires and monster-Zombies
            if MONSTER_ROLES[ROLE_VAMPIRE] then
                allies = {ROLE_VAMPIRE}
                if MONSTER_ROLES[ROLE_ZOMBIE] then
                    table.insert(allies, ROLE_ZOMBIE)
                end
                showJesters = jesters_visible_to_monsters
            else
                allies = GetTeamRoles(INDEPENDENT_ROLES)
                showJesters = jesters_visible_to_independents
            end
        end

        OnPlayerHighlightEnabled(client, allies, showJesters, hideEnemies, traitorAllies)
    end)
end

function HandleRoleHighlights(client)
    if not IsValid(client) then return end

    if client:IsZombie() and (zombie_vision or (traitor_vision and TRAITOR_ROLES[ROLE_ZOMBIE])) then
        if not vision_enabled then
            EnableZombieHighlights(client)
            vision_enabled = true
        end
    elseif client:IsVampire() and (vampire_vision or (traitor_vision and TRAITOR_ROLES[ROLE_VAMPIRE])) then
        if not vision_enabled then
            EnableVampireHighlights(client)
            vision_enabled = true
        end
    elseif client:IsTraitorTeam() and traitor_vision then
        if not vision_enabled then
            EnableTraitorHighlights(client)
            vision_enabled = true
        end
    else
        vision_enabled = false
    end

    if not vision_enabled then
        hook.Remove("PreDrawHalos", "AddPlayerHighlights")
    end
end

-- Monster-as-traitors equipment

net.Receive("TTT_LoadMonsterEquipment", function()
    local zombies_are_traitors = net.ReadBool()
    local vampires_are_traitors = net.ReadBool()
    LoadMonsterEquipment(zombies_are_traitors, vampires_are_traitors)
end)

-- Footsteps

local footSteps = {}
local footMat = Material("thieves/footprint")
local function DrawFootprints()
    local client = LocalPlayer()
    if not IsValid(client) then return end

    cam.Start3D(client:EyePos(), client:EyeAngles())
    render.SetMaterial(footMat)
    local pos = client:EyePos()
    for k, footstep in pairs(footSteps) do
        local timediff = (footstep.curtime + footstep.fadetime) - CurTime()
        if timediff > 0 then
            if (footstep.pos - pos):LengthSqr() < 600 ^ 2 then
                -- Fade the footprints into invisibility based on how long they've been around
                local faderatio = timediff / footstep.fadetime
                local col = Color(footstep.col.r, footstep.col.g, footstep.col.b, faderatio * 255)

                local hitpos = footstep.pos
                -- If this player is spectating through the target's eyes, move the prints down so they don't appear to float
                if client:IsSpec() and client:GetObserverMode() == OBS_MODE_IN_EYE then
                    hitpos = hitpos + Vector(0, 0, -50)
                end
                render.DrawQuadEasy(hitpos + footstep.normal * 0.01, footstep.normal, 10, 20, col, footstep.angle)
            end
        else
            footSteps[k] = nil
        end
    end
    cam.End3D()
end

function AddFootstep(ply, pos, ang, foot, col, fade_time)
    ang.p = 0
    ang.r = 0
    local fpos = pos
    if foot == 1 then
        fpos = fpos + ang:Right() * 5
    else
        fpos = fpos + ang:Right() * -5
    end

    local trace = {
        start = fpos,
        endpos = fpos + Vector(0, 0, -10),
        filter = ply
    }
    local tr = util.TraceLine(trace)
    if tr.Hit then
        local tbl = {
            pos = tr.HitPos,
            curtime = CurTime(),
            fadetime = fade_time,
            angle = ang.y,
            normal = tr.HitNormal,
            col = col
        }
        table.insert(footSteps, tbl)
    end
end

net.Receive("TTT_PlayerFootstep", function()
    local ply = net.ReadEntity()
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    local foot = net.ReadBit()
    local color = net.ReadTable()
    local fade_time = net.ReadUInt(8)

    AddFootstep(ply, pos, ang, foot, color, fade_time)
end)

net.Receive("TTT_ClearPlayerFootsteps", function()
    table.Empty(footSteps)
end)

hook.Add("PostDrawTranslucentRenderables", "FootstepRender", function(depth, skybox)
    DrawFootprints()
end)