local ROLE = {}

ROLE.nameraw = ""
ROLE.name = ""
ROLE.nameplural = ""
ROLE.nameext = ""
ROLE.nameshort = ""

ROLE.desc = [[]]

ROLE.team = ROLE_TEAM_

ROLE.shop = {}

ROLE.loadout = {}

ROLE.convars = {}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()
end