AddCSLuaFile()

local ents = ents
local hook = hook

if SERVER then
    local player = player
    local timer = timer

    local CreateEntity = ents.Create
    local PlayerIterator = player.Iterator

    local defaultColor = Vector(1, 1, 1)
    local function CreateSpectatorSpirit(ply)
        if IsValid(ply.SpiritEnt) then return end
        if IsValid(ply.SpecSpiritEnt) then return end
        if ply:Alive() or not ply:IsSpec() then return end
        if ply:GetRole() == ROLE_NONE then return end

        local spirit = CreateEntity("npc_kleiner")
        spirit:SetPos(ply:GetPos())
        spirit:SetRenderMode(RENDERMODE_NONE)
        spirit:SetNotSolid(true)
        spirit:DrawShadow(false)
        spirit:AddFlags(FL_NOTARGET)
        spirit:SetNWString("SpecSpiritOwner", ply:SteamID64())
        spirit:SetNWVector("SpecSpiritColor", ply:GetNWVector("PlayerColor", defaultColor))
        spirit:Spawn()

        ply.SpecSpiritEnt = spirit
    end

    hook.Add("PlayerDeath", "SpecSpirits_PlayerDeath", function(victim, infl, attacker)
        -- Wait so the Medium logic has a chance to run first
        timer.Simple(0, function()
            if not IsPlayer(victim) then return end
            print("[SpecSpirits] Creating spirit for " .. victim:Nick())
            CreateSpectatorSpirit(victim)
        end)
    end)

    hook.Add("FinishMove", "SpecSpirits_FinishMove", function(ply, mv)
        if not IsValid(ply) or not ply:IsSpec() then return end
        if not IsValid(ply.SpecSpiritEnt) then return end

        ply.SpecSpiritEnt:SetPos(ply:GetPos())

        local show = ply:GetObserverMode() == OBS_MODE_ROAMING
        ply.SpecSpiritEnt:SetProperty("SpecSpiritVisible", show)
    end)

    hook.Add("TTTPrepareRound", "SpecSpirits_TTTPrepareRound", function()
        for _, p in PlayerIterator() do
            SafeRemoveEntity(p.SpecSpiritEnt)
            p.SpecSpiritEnt = nil
        end
    end)
end

if CLIENT then
    local math = math

    local EntsFindByClass = ents.FindByClass
    local MathRand = math.Rand
    local MathRandom = math.random

    local client
    local wispOffset = Vector(0, 0, 64)
    local wispVelocity = Vector(0, 0, 30)
    local wispColor = Vector(1, 1, 1)
    hook.Add("Think", "SpecSpirits_Think", function()
        if GetRoundState() ~= ROUND_ACTIVE then return end

        if not client then
            client = LocalPlayer()
        end
        if client:Alive() or not client:IsSpec() then return end

        for _, ent in ipairs(EntsFindByClass("npc_kleiner")) do
            if ent.SpecSpiritVisible then
                local curTime = CurTime()

                ent:SetNoDraw(true)
                ent:SetRenderMode(RENDERMODE_NONE)
                ent:SetNotSolid(true)
                ent:DrawShadow(false)
                if not ent.SpecSpiritEmitter then ent.SpecSpiritEmitter = ParticleEmitter(ent:GetPos()) end
                if not ent.SpecSpiritNextPart then ent.SpecSpiritNextPart = curTime end
                local pos = ent:GetPos() + wispOffset
                -- Use DistToSqr as it's more efficient and this is called very frequently
                -- 9000000 = 3000^2
                if ent.SpecSpiritNextPart < curTime and client:GetPos():DistToSqr(pos) <= 9000000 then
                    ent.SpecSpiritEmitter:SetPos(pos)
                    ent.SpecSpiritNextPart = curTime + MathRand(0.003, 0.01)
                    local particle = ent.SpecSpiritEmitter:Add("particle/wisp.vmt", pos)
                    particle:SetVelocity(wispVelocity)
                    particle:SetDieTime(1)
                    particle:SetStartAlpha(MathRandom(150, 220))
                    particle:SetEndAlpha(0)
                    local size = MathRandom(4, 7)
                    particle:SetStartSize(size)
                    particle:SetEndSize(1)
                    particle:SetRoll(MathRand(0, math.pi))
                    particle:SetRollDelta(0)
                    local col = ent:GetNWVector("SpecSpiritColor", wispColor)
                    particle:SetColor(col.x * 255, col.y * 255, col.z * 255)
                end
            elseif ent.SpecSpiritEmitter then
                ent.SpecSpiritEmitter:Finish()
                ent.SpecSpiritEmitter = nil
            end
        end
    end)
end