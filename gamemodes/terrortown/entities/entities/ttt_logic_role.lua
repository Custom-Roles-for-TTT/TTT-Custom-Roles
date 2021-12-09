ENT.Type = "point"
ENT.Base = "base_point"

local ROLE_ANY = 3

ENT.Role = ROLE_ANY

function ENT:KeyValue(key, value)
    if key == "OnPass" or key == "OnFail" then
        -- this is our output, so handle it as such
        self:StoreOutput(key, value)
    elseif key == "Role" then
        self.Role = tonumber(value)

        if not self.Role then
            ErrorNoHalt("ttt_logic_role: bad value for Role key, not a number\n")
            self.Role = ROLE_ANY
        end
    end
end

function ENT:AcceptInput(name, activator)
    if name == "TestActivator" then
        if IsPlayer(activator) then
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

            if traitorTest or innocentTest or jesterTest or independentTest or specificTest or detectiveTest or anyTest then
                Dev(2, activator, "passed logic_role test of", self:GetName())
                self:TriggerOutput("OnPass", activator)
            else
                Dev(2, activator, "failed logic_role test of", self:GetName())
                self:TriggerOutput("OnFail", activator)
            end
        end

        return true
    end
end