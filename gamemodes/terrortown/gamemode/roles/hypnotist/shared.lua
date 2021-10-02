-----------------
-- ROLE WEAPON --
-----------------

hook.Add("TTTUpdateRoleState", "Hypnotist_TTTUpdateRoleState", function()
    local hypnotist_defib = weapons.GetStored("weapon_hyp_brainwash")
    if GetGlobalBool("ttt_hypnotist_device_loadout", false) then
        hypnotist_defib.InLoadoutFor = table.Copy(hypnotist_defib.InLoadoutForDefault)
    else
        table.Empty(hypnotist_defib.InLoadoutFor)
    end
    if GetGlobalBool("ttt_hypnotist_device_shop", false) then
        hypnotist_defib.CanBuy = {ROLE_HYPNOTIST}
    else
        hypnotist_defib.CanBuy = nil
    end
end)