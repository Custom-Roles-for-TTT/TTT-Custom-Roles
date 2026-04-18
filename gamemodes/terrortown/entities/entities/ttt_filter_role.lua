ENT.Type = "filter"
ENT.Base = "base_filter"

local ROLE_ANY = 3

ENT.Role = ROLE_ANY

function ENT:KeyValue(key, value)
    if key == "Role" then
        if isstring(value) then
            -- HACK: Let map makers specify they want the check to only work for jesters, but keep compatibility with base TTT where "ROLE_ANY" is 3 in this entity
            if value == "ROLE_JESTER" then
                value = -ROLE_JESTER
            else
                value = _G[value] or value
            end
        end

        self.Role = tonumber(value)

        if not self.Role then
            ErrorNoHalt("ttt_filter_role: bad value for Role key, not a number\n")
            self.Role = ROLE_ANY
        end
    end
end

function ENT:PassesFilter(caller, activator)
    if not IsPlayer(activator) then return false end

    local traitorTest = false
    local innocentTest =  false
    local jesterTest = false
    local independentTest = false
    local detectiveTest = false
    local specificTest = false
    local anyTest = self.Role == ROLE_ANY

    -- Everyone is innocent during the prep phase
    if GetRoundState() == ROUND_PREP then
        innocentTest = self.Role == ROLE_INNOCENT
    else
        if self.Role == ROLE_TRAITOR then
            traitorTest = activator:IsTraitorTeam()
            jesterTest = activator:IsJesterTeam() and GetConVar("ttt_jesters_trigger_traitor_testers"):GetBool()
            independentTest = activator:IsIndependentTeam() and GetConVar("ttt_independents_trigger_traitor_testers"):GetBool()
        elseif self.Role == ROLE_INNOCENT then
            traitorTest = activator:IsTraitorTeam()
            innocentTest = activator:IsInnocentTeam()
            jesterTest = activator:IsJesterTeam() and not GetConVar("ttt_jesters_trigger_traitor_testers"):GetBool()
            independentTest = activator:IsIndependentTeam() and not GetConVar("ttt_independents_trigger_traitor_testers"):GetBool()
        elseif self.Role == ROLE_DETECTIVE then
            detectiveTest = activator:IsDetectiveLike()
        end

        specificTest = self.Role == activator:GetRole()

        -- HACK: Let map makers specify they want the check to only work for jesters, but keep compatibility with base TTT where "ROLE_ANY" is 3 in this entity
        if activator:GetRole() == ROLE_JESTER and self.Role == -ROLE_JESTER then
            specificTest = true
        end
    end

    local hookTest = hook.Call("TTTPlayerPassesTraitorCheck", nil, activator, self) == true
    if traitorTest or innocentTest or jesterTest or independentTest or specificTest or detectiveTest or anyTest or hookTest then
        Dev(2, activator, "passed filter_role test of", self:GetName())
        return true
    end

    Dev(2, activator, "failed filter_role test of", self:GetName())
    return false
end