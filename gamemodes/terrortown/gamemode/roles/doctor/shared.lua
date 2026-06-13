AddCSLuaFile()

local hook = hook
local table = table
local weapons = weapons

local AddHook = hook.Add

-- Initialize role features
ROLE_STARTING_CREDITS[ROLE_DOCTOR] = 1
local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_DOCTOR] = {
            "weapon_ttt_health_station",
            "weapon_doc_cure"
        }
    end
end
InitializeEquipment()

AddHook("Initialize", "Doctor_Shared_Initialize", InitializeEquipment)
AddHook("TTTPrepareRound", "Doctor_Shared_TTTPrepareRound", InitializeEquipment)

------------------
-- ROLE CONVARS --
------------------

local doctor_cure_rebuyable = CreateConVar("ttt_doctor_cure_rebuyable", "0", FCVAR_REPLICATED, "Whether the cure can be bought multiple times", 0, 1)

ROLE_CONVARS[ROLE_DOCTOR] = {
    {
        cvar = "ttt_doctor_cure_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Kill nobody", "Kill owner", "Kill target"},
        isNumeric = true
    },
    {
        cvar = "ttt_doctor_cure_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_doctor_cure_rebuyable",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

------------------
-- ROLE WEAPONS --
------------------

AddHook("TTTUpdateRoleState", "Doctor_TTTUpdateRoleState", function()
    local cure = weapons.GetStored("weapon_doc_cure")
    if hook.Call("TTTCanCureableRoleSpawn") then
        cure.CanBuy = table.Copy(cure.CanBuyDefault)
    else
        table.Empty(cure.CanBuy)
    end

    cure.LimitedStock = not doctor_cure_rebuyable:GetBool()
end)