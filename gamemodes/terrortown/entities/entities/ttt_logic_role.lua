ENT.Type = "point"
ENT.Base = "base_point"

local ROLE_ANY = -1

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
        if IsValid(activator) and activator:IsPlayer() then
            local activator_role = (GetRoundState() == ROUND_PREP) and ROLE_INNOCENT or activator:GetRole()

            if (GetRoundState() ~= ROUND_PREP and self.Role == ROLE_TRAITOR and activator:IsTraitorTeam()) or -- Traitor team
                    (self.Role == ROLE_INNOCENT and activator:IsInnocentTeam()) or  -- Innocent team
                    (GetRoundState() ~= ROUND_PREP and self.Role == ROLE_TRAITOR and activator:IsJesterTeam() and GetConVar("ttt_jesters_trigger_traitor_testers"):GetBool()) -- Jester team
                    (GetRoundState() ~= ROUND_PREP and self.Role == ROLE_TRAITOR and activator:IsIndependentTeam() and GetConVar("ttt_independents_trigger_traitor_testers"):GetBool()) -- Independent team
                    (self.Role == activator_role) or -- Specific role check
                    (self.Role == ROLE_ANY) then
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