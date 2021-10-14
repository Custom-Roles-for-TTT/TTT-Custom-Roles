AddCSLuaFile()

-------------
-- CONVARS --
-------------

CreateConVar("ttt_veteran_damage_bonus", "0.5")
CreateConVar("ttt_veteran_full_heal", "1")
CreateConVar("ttt_veteran_heal_bonus", "0")
CreateConVar("ttt_veteran_announce", "0")
CreateConVar("ttt_veteran_activation_credits", "0")

hook.Add("TTTSyncGlobals", "Veteran_TTTSyncGlobals", function()
    SetGlobalBool("ttt_veteran_full_heal", GetConVar("ttt_veteran_full_heal"):GetBool())
end)

-----------------
-- ROLE STATUS --
-----------------

hook.Add("PlayerDeath", "Veteran_RoleFeatures_PlayerDeath", function(victim, infl, attacker)
    local innocents_alive = 0
    local veterans = {}
    for _, v in pairs(player.GetAll()) do
        if v:IsActiveInnocentTeam() then innocents_alive = innocents_alive + 1 end
        if v:IsActiveVeteran() then table.insert(veterans, v) end
    end
    if #veterans > 0 and innocents_alive == #veterans then
        for _, v in pairs(veterans) do
            if not v:IsRoleActive() then
                v:SetNWBool("VeteranActive", true)
                v:AddCredits(GetConVar("ttt_veteran_activation_credits"):GetInt())

                v:PrintMessage(HUD_PRINTTALK, "You are the last " .. ROLE_STRINGS[ROLE_INNOCENT] .. " alive!")
                v:PrintMessage(HUD_PRINTCENTER, "You are the last " .. ROLE_STRINGS[ROLE_INNOCENT] .. " alive!")
                if GetConVar("ttt_veteran_announce"):GetBool() then
                    for _, p in ipairs(player.GetAll()) do
                        if p ~= v and p:Alive() and not p:IsSpec() then
                            p:PrintMessage(HUD_PRINTTALK, "The last " .. ROLE_STRINGS[ROLE_INNOCENT] .. " alive is " .. ROLE_STRINGS_EXT[ROLE_VETERAN] .. "!")
                            p:PrintMessage(HUD_PRINTCENTER, "The last " .. ROLE_STRINGS[ROLE_INNOCENT] .. " alive is " .. ROLE_STRINGS_EXT[ROLE_VETERAN] .. "!")
                        end
                    end
                end

                if GetConVar("ttt_veteran_full_heal"):GetBool() then
                    local heal_bonus = GetConVar("ttt_veteran_heal_bonus"):GetInt()
                    local health = math.min(v:GetMaxHealth(), 100) + heal_bonus

                    v:SetHealth(health)
                    if heal_bonus > 0 then
                        v:PrintMessage(HUD_PRINTTALK, "You have been fully healed (with a bonus)!")
                    else
                        v:PrintMessage(HUD_PRINTTALK, "You have been fully healed!")
                    end
                end

                -- Give the veteran their shop items if purchase was delayed
                if v.bought and GetConVar("ttt_veteran_shop_delay"):GetBool() then
                    v:GiveDelayedShopItems()
                end
            end
        end
    end
end)

hook.Add("ScalePlayerDamage", "Veteran_ScalePlayerDamage", function(ply, hitgroup, dmginfo)
    local att = dmginfo:GetAttacker()
    if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
        -- Veterans deal extra damage if they are the last innocent alive
        if att:IsVeteran() and att:IsRoleActive() then
            local bonus = GetConVar("ttt_veteran_damage_bonus"):GetFloat()
            dmginfo:ScaleDamage(1 + bonus)
        end
    end
end)

hook.Add("TTTPrepareRound", "Veteran_RoleFeatures_PrepareRound", function()
    for _, v in pairs(player.GetAll()) do
        v:SetNWBool("VeteranActive", false)
    end
end)