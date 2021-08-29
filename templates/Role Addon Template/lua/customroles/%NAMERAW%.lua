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
    resource.AddFile("materials/vgui/ttt/icon_ROLESHORT.vmt")
    resource.AddFile("materials/vgui/ttt/sprite_ROLESHORT.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_ROLESHORT_noz.vmt")
    resource.AddSingleFile("materials/vgui/ttt/score_ROLESHORT.png")
    resource.AddSingleFile("materials/vgui/ttt/tab_ROLESHORT.png")
end