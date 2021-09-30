------------------
-- HIGHLIGHTING --
------------------

local vampire_vision = false
local jesters_visible_to_traitors = false
local jesters_visible_to_monsters = false
local jesters_visible_to_independents = false
local vision_enabled = false
local client = nil

local function EnableVampireHighlights()
    -- Handle vampire targeting and non-traitor team logic
    -- Traitor logic is handled in cl_init and does not need to be duplicated here
    hook.Add("PreDrawHalos", "Vampire_Highlight_PreDrawHalos", function()
        local hasFangs = client.GetActiveWeapon and IsValid(client:GetActiveWeapon()) and client:GetActiveWeapon():GetClass() == "weapon_vam_fangs"
        local hideEnemies = not vampire_vision or not hasFangs

        -- Handle logic differently depending on which team they are on
        local allies = {}
        local showJesters = false
        local traitorAllies = false
        local onlyShowEnemies = false
        if MONSTER_ROLES[ROLE_VAMPIRE] then
            allies = GetTeamRoles(MONSTER_ROLES)
            showJesters = jesters_visible_to_monsters
        elseif INDEPENDENT_ROLES[ROLE_VAMPIRE] then
            allies = GetTeamRoles(INDEPENDENT_ROLES)
            showJesters = jesters_visible_to_independents
        else
            allies = GetTeamRoles(TRAITOR_ROLES)
            showJesters = jesters_visible_to_traitors
            traitorAllies = true
            onlyShowEnemies = true
        end

        OnPlayerHighlightEnabled(client, allies, showJesters, hideEnemies, traitorAllies, onlyShowEnemies)
    end)
end

hook.Add("TTTUpdateRoleState", "Vampire_Highlight_TTTUpdateRoleState", function()
    client = LocalPlayer()
    vampire_vision = GetGlobalBool("ttt_vampire_vision_enable", false)
    jesters_visible_to_traitors = GetGlobalBool("ttt_jesters_visible_to_traitors", false)
    jesters_visible_to_monsters = GetGlobalBool("ttt_jesters_visible_to_monsters", false)
    jesters_visible_to_independents = GetGlobalBool("ttt_jesters_visible_to_independents", false)

    -- Disable highlights on role change
    if vision_enabled then
        hook.Remove("PreDrawHalos", "Vampire_Highlight_PreDrawHalos")
        vision_enabled = false
    end
end)

-- Handle enabling and disabling of highlighting
hook.Add("Think", "Vampire_Highlight_Think", function()
    if not IsPlayer(client) or not client:Alive() or client:IsSpec() then return end

    if vampire_vision and client:IsVampire() then
        if not vision_enabled then
            EnableVampireHighlights()
            vision_enabled = true
        end
    else
        vision_enabled = false
    end

    if not vision_enabled then
        hook.Remove("PreDrawHalos", "Vampire_Highlight_PreDrawHalos")
    end
end)