hook.Add("TTTTutorialRoleEnabled", "Zombie_TTTTutorialRoleEnabled", function(role)
    if role == ROLE_ZOMBIE then
        -- Show the zombie screen if the Mad Scientist could spawn them
        return INDEPENDENT_ROLES[ROLE_ZOMBIE] and GetGlobalBool("ttt_madscientist_enabled", false)
    end
end)