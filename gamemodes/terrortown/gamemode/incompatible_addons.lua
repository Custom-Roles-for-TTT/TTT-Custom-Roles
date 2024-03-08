local hook = hook
local pairs = pairs

local incompatible = {
    -- Outdated Custom Roles for TTT Versions
    ["1215502383"] = { reason = "Outdated version of Custom Roles for TTT." }, -- Custom Roles for TTT by Noxx
    ["1866859433"] = { reason = "Outdated version of Custom Roles for TTT." }, -- Custom Roles for TTT by Paradox R.
    ["1867285015"] = { reason = "Outdated version of Custom Roles for TTT." }, -- Custom Roles for TTT by MrDj
    ["2024774626"] = { reason = "Outdated version of Custom Roles for TTT." }, -- Custom Roles for TTT by Bud
    ["2039140325"] = { reason = "Outdated version of Custom Roles for TTT." }, -- Custom Roles for TTT by Greyull
    ["2045444087"] = { reason = "Outdated version of Custom Roles for TTT." }, -- Custom Roles for TTT by Malivil
    ["2110307090"] = { reason = "Outdated version of Custom Roles for TTT." }, -- TTT custom roles no jester or swapper by Beanie
    ["2125529065"] = { reason = "Outdated version of Custom Roles for TTT." }, -- Custom Roles for TTT by Squid Matty
    ["2137354235"] = { reason = "Outdated version of Custom Roles for TTT." }, -- TTT Custom Roles (T.Rich Version) by T.Rich
    ["2157141697"] = { reason = "Outdated version of Custom Roles for TTT." }, -- Custom Roles for TTT (Vampire Zombie Terrorists) by KillerChaos
    ["2171000363"] = { reason = "Outdated version of Custom Roles for TTT." }, -- Custom Roles for TTT by Zedasi
    ["2207320056"] = { reason = "Outdated version of Custom Roles for TTT." }, -- TTT Custom Roles - with MEDIC v1.1 by Shadyguy
    ["2350655792"] = { reason = "Outdated version of Custom Roles for TTT." }, -- TTT Custom Roles EMU [Chinese] by Smile
    ["2429143979"] = { reason = "Outdated version of Custom Roles for TTT." }, -- Custom Roles for TTT (Fixed) by DeusExp

    -- Outdated TTT or Custom Roles for TTT ULX Versions
    ["127865722"] = { reason = "Outdated version of Custom Roles for TTT ULX.", alt = "2421043753" }, -- Trouble in Terrorist Town ULX Commands
    ["1360293938"] = { reason = "Outdated version of Custom Roles for TTT ULX.", alt = "2421043753" }, -- TTT - (Addon) ULX Commands by Altamas
    ["1217368823"] = { reason = "Outdated version of Custom Roles for TTT ULX.", alt = "2421043753" }, -- ULX Module for Custom Roles for TTT by Noxx
    ["2091700901"] = { reason = "Outdated version of Custom Roles for TTT ULX.", alt = "2421043753" }, -- ULX Module for Custom Roles for TTT by Malivil
    ["2246286292"] = { reason = "Outdated version of Custom Roles for TTT ULX.", alt = "2421043753" }, -- ULX Module for Custom Roles for TTT by Squid Matty

    -- TTT2
    ["1357204556"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- TTT2 (Base)
    ["1362430347"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- [TTT2] ULX Commands for TTT2
    ["1687709497"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- [TTT2] Totem

    -- Town of Terror
    ["1092556189"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- Town Of Terror - More roles for TTT
    ["1827295539"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- [TTT] Town Of Terror + HUD - Custom Jester

    -- Other Roles
    ["828347015"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- TTT Vote + TTT Totem für Trouble Town by Hagen
    ["1219646499"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- More Roles. Strael's TTT by Strael
    ["1251093502"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- TTT Killer Info - Nutte, Zuhälter, Türsteher & Oberbitch Support by SnowSoulAngel
    ["1251103772"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- TTT - Oberbitch Role by SnowSoulAngel
    ["1330104618"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- Assasin role for ttt by Zlin
    ["1818951122"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- [GM] More Roles [TTT] by Selfridge

    -- Other Core File Overwrites
    ["107658972"] = { reason = "Overwrites core files required for Custom Roles for TTT.", alt = "686457995" }, -- TTT Round End Slowmotion by TheTrueLor
    ["254779132"] = { reason = "Overwrites core files required for Custom Roles for TTT.", alt = "810154456" }, -- TTT DeadRinger by Porter
    ["367945571"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- TTT: Advanced Body Search
    ["1848007854"] = { reason = "Overwrites the DNA scanner code which breaks Custom Roles for TTT features."}, -- TTT - DNA Scanner Model Version (BackStabber) by Kobra
    ["404599106"] = { reason = "Overwrites core functions required for Custom Roles for TTT" }, -- TTT Spectator Deathmatch by P4sca1
    ["2520210407"] = { reason = "Overwrites core files required for Custom Roles for TTT." }, -- TTT Weapon Balance by Emzatin.
    ["2553413816"] = { reason = "Overwrites core files required for Custom Roles for TTT" }, -- Emzatins TTT Weapon Balance Mod (Innocents Buffed)
    ["3022749770"] = { reason = "Overwrites core files required for Custom Roles for TTT" }, -- TTT Base Traitor Items Reworked by Emzatin
    ["693582992"] = { reason = "Overwrites core files required for Custom Roles for TTT", alt = "3025019026"}, -- TTT M9K Weapons Pack (With icon) by LittlEpande

    -- Damage Logs
    ["663328966"] = { reason = "Damage logs are not compatible with any non-default roles.", alt = "2306802961" }, -- TTT RDM Manager With Damage Logs by Schmatty

    -- Better Equipment Menu
    ["878772496"] = { reason = "Better Equipment Menu is included in Custom Roles for TTT." }, -- [TTT] Better Equipment Menu

    -- Sprint
    ["933056549"] = { reason = "Sprinting is included in Custom Roles for TTT." }, -- TTT Sprint by Fresh Garry
    ["1729301513"] = { reason = "Sprinting is included in Custom Roles for TTT." }, -- [TTT] Sprint by Lesh
    ["1822686406"] = { reason = "Sprinting is included in Custom Roles for TTT." }, -- [GM] Sprint [TTT] by Selfridge

    -- Glowing Traitors
    ["690007939"] = { reason = "Player outlines are included in Custom Roles for TTT." }, -- TTT Glowing Traitors by kuma7
    ["1821994127"] = { reason = "Player outlines are included in Custom Roles for TTT." }, -- [GM] Glowing Traitors [TTT]
    ["1137493106"] = { reason = "Player outlines are included in Custom Roles for TTT." }, -- [TTT/2] Glowing Teammates by LillyPoh

    -- Killer Notifier
    ["167547072"] = { reason = "Death messages are included in Custom Roles for TTT." }, -- TTT Killer Notifier by StarFox
    ["305575144"] = { reason = "Death messages are included in Custom Roles for TTT." }, -- TTT Kill reveal / Kill notifier with colors by Thomads

    -- Miscellaneous
    ["1721137539"] = { reason = "Breaks the tracker's footsteps by always returning a value to PlayerFootstep hook.", alt = "3052896263" }, -- Avengers RandoMat Event by Jenssons
    ["2209392671"] = { reason = "Breaks the weapon switch HUD (and possibly others)."}, -- TTT SimpleHUD by Suphax
    ["1256344426"] = { reason = "Breaks body searching and role-specific features" }, -- TTT Bots 2.0 by immortal man

    -- COD Zombie Perk Bottles
    ["842302491"] = { reason = "Incompatible with equipment item changes", alt = "2243578658"}, -- [TTT/2] Zombie Perk Bottles by Hagen
    ["653258161"] = { reason = "Incompatible with equipment item changes"}, -- [TTT/2] Blue Bull by Hagen
    ["2552701051"] = { reason = "Incompatible with equipment item changes", alt = "2243578658"} -- TTT Zombie Perk Bottles Rebalanced by Emzatin.

    -- Example convar config
    -- ["124567890"] = { convars = { { name = "ttt_broken_convar", value = "1", reason = "Breaks all the things", alt = "987654321" } } } -- An addon by a person
}

if CR_BETA then
    -- Update ULX incompatibilities to redirect to the beta version
    incompatible["127865722"].alt = "2414297330"
    incompatible["1360293938"].alt = "2414297330"
    incompatible["1217368823"].alt = "2414297330"
    incompatible["2091700901"].alt = "2414297330"
    incompatible["2246286292"].alt = "2414297330"

    -- Add the release versions of CR for TTT and CR for TTT ULX
    incompatible["2421039084"] = { reason = "Both release and beta versions of Custom Roles for TTT are installed." } -- Custom Roles for TTT
    incompatible["2421043753"] = { reason = "Incorrect version of ULX Module for Custom Roles for TTT is installed.", alt = "2414297330" } -- ULX Module for Custom Roles for TTT
else
    -- Add the beta versions of CR for TTT and CR for TTT ULX
    incompatible["2404251054"] = { reason = "Both release and beta versions of Custom Roles for TTT are installed." } -- Custom Roles for TTT (Beta)
    incompatible["2414297330"] = { reason = "Incorrect version of ULX Module for Custom Roles for TTT is installed.", alt = "2421043753"} -- ULX Module for Custom Roles for TTT (Beta)
end

hook.Add("InitPostEntity", "Incompatibility_InitPostEntity", function()
    local addons = engine.GetAddons()

    for _, v in pairs(addons) do
        local addon = incompatible[tostring(v.wsid)]
        if addon and v.mounted then
            if addon.convars then
                for _, convar in ipairs(addon.convars) do
                    local value = cvars.String(convar.name, nil)
                    if value == convar.value then
                        ErrorNoHalt("WARNING: ConVar '" .. convar.name .. "' from '" .. v.title .. "' is incompatible with Custom Roles for TTT!\n")
                        ErrorNoHalt("         Reason: " .. convar.reason .. "\n")
                        if convar.alt then
                            ErrorNoHalt("         An alternative addon is available at https://steamcommunity.com/sharedfiles/filedetails/?id=" .. convar.alt .. "\n")
                        end
                    end
                end
            else
                ErrorNoHalt("WARNING: Addon '" .. v.title .. "' is incompatible with Custom Roles for TTT!\n")
                ErrorNoHalt("         Reason: " .. addon.reason .. "\n")
                if addon.alt then
                    ErrorNoHalt("         An alternative addon is available at https://steamcommunity.com/sharedfiles/filedetails/?id=" .. addon.alt .. "\n")
                end
            end
        end
    end
end)