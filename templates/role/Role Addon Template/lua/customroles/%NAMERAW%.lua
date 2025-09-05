local ROLE = {}

ROLE.nameraw = ""
ROLE.name = ""
ROLE.nameplural = ""
ROLE.nameext = ""
ROLE.nameshort = ""

ROLE.desc = [[]]

ROLE.team = ROLE_TEAM_

ROLE.shop = nil
ROLE.loadout = {}

ROLE.startingcredits = nil

ROLE.startinghealth = nil
ROLE.maxhealth = nil

ROLE.isactive = nil
ROLE.selectionpredicate = nil
ROLE.shouldactlikejester = nil

ROLE.translations = {}

ROLE.convars = {}

RegisterRole(ROLE)

if SERVER then
    AddCSLuaFile()
end