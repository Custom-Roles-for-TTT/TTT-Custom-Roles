
ENT.Type = "point"
ENT.Base = "base_point"

ENT.Message = ""
ENT.Color = COLOR_WHITE

local RECEIVE_ACTIVATOR = 0
local RECEIVE_ALL = 1
local RECEIVE_DETECTIVE = 2
local RECEIVE_TRAITOR = 3
local RECEIVE_INNOCENT = 4
local RECEIVE_JESTER = 5
local RECEIVE_INDEPENDENT = 6
local RECEIVE_MONSTER = 7

local RECEIVE_MAX = RECEIVE_MONSTER
ENT.Receiver = RECEIVE_ACTIVATOR

function ENT:KeyValue(key, value)
    if key == "message" then
        self.Message = tostring(value) or "ERROR: bad value"
    elseif key == "color" then
        local mr, mg, mb = string.match(value, "(%d*) (%d*) (%d*)")

        local c = Color(0,0,0)
        c.r = tonumber(mr) or 255
        c.g = tonumber(mg) or 255
        c.b = tonumber(mb) or 255

        self.Color = c
    elseif key == "receive" then
        self.Receiver = tonumber(value)
        if not (self.Receiver and self.Receiver >= RECEIVE_ACTIVATOR and self.Receiver <= RECEIVE_MAX) then
            ErrorNoHalt("ERROR: ttt_game_text has invalid receiver value\n")
            self.Receiver = RECEIVE_ACTIVATOR
        end
    end
end

function ENT:AcceptInput(name, activator)
    if name == "Display" then
        local recv = activator

        local r = self.Receiver
        if r == RECEIVE_ALL then
            recv = nil
        elseif r == RECEIVE_DETECTIVE then
            recv = GetDetectiveTeamFilter()
        elseif r == RECEIVE_TRAITOR then
            recv = GetTraitorTeamFilter()
        elseif r == RECEIVE_INNOCENT then
            recv = GetInnocentTeamFilter()
        elseif r == RECEIVE_JESTER then
            recv = GetJesterTeamFilter()
        elseif r == RECEIVE_INDEPENDENT then
            recv = GetIndependentTeamFilter()
        elseif r == RECEIVE_MONSTER then
            recv = GetMonsterTeamFilter()
        elseif r == RECEIVE_ACTIVATOR then
            if not (IsValid(activator) and activator:IsPlayer()) then
                ErrorNoHalt("ttt_game_text tried to show message to invalid !activator\n")
                return true
            end
        end

        CustomMsg(recv, self.Message, self.Color)

        return true
    end
end
