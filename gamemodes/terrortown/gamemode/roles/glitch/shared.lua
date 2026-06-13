AddCSLuaFile()

local hook = hook
local player = player
local table = table

local AddHook = hook.Add
local PlayerIterator = player.Iterator
local TableInsert = table.insert

-- Initialize role features
GLITCH_SHOW_AS_TRAITOR = 0
GLITCH_SHOW_AS_SPECIAL_TRAITOR = 1
GLITCH_HIDE_SPECIAL_TRAITOR_ROLES = 2

GLITCH_CHAT_NONE = 0
GLITCH_CHAT_BLOCK_ALWAYS = 1
GLITCH_CHAT_BLOCK_WHILE_ALIVE = 2
GLITCH_CHAT_BLOCK_WHILE_UNCONFIRMED = 3

AddHook("TTTUpdateRoleState", "Glitch_TTTUpdateRoleState", function()
    local glitch_use_traps = GetConVar("ttt_glitch_use_traps"):GetBool()
    CAN_LOOT_CREDITS_ROLES[ROLE_GLITCH] = glitch_use_traps
    TRAITOR_BUTTON_ROLES[ROLE_GLITCH] = glitch_use_traps
end)

AddHook("TTTPlayerCanSendCreditsTo", "Glitch_TTTPlayerCanSendCreditsTo", function(sender, target, canSend)
    if sender:IsTraitorTeam() and target:IsGlitch() then
        return true
    end
end)

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_glitch_mode", "0", FCVAR_REPLICATED, "The way in which the glitch appears to traitors. 0 - Appears as a regular traitor. 1 - Can appear as a special traitor. 2 - Causes all traitors, regular or special, to appear as regular traitors and appears as a regular traitor themselves.", GLITCH_SHOW_AS_TRAITOR, GLITCH_HIDE_SPECIAL_TRAITOR_ROLES)
local glitch_chat_block_mode = CreateConVar("ttt_glitch_chat_block_mode", "1", FCVAR_REPLICATED, "How to handle glitch chat blocking. 0 - Don't block. 1 - Always block when there's a glitch. 2 - Block while a glitch is alive. 3 - Block until all glitches are confirmed by inspecting their body.", GLITCH_CHAT_NONE, GLITCH_CHAT_BLOCK_WHILE_UNCONFIRMED)
CreateConVar("ttt_glitch_use_traps", "0", FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_GLITCH] = {
    {
        cvar = "ttt_glitch_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Traitor", "Random Special Traitor", "Mask all traitors"},
        isNumeric = true
    },
    {
        cvar = "ttt_glitch_chat_block_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Don't block", "Always block", "Block while alive", "Block while body unconfirmed"},
        isNumeric = true
    },
    {
        cvar = "ttt_glitch_use_traps",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

--------------------
-- PLAYER METHODS --
--------------------

function ShouldGlitchBlockCommunications()
    local chat_block_mode = glitch_chat_block_mode:GetInt()
    if chat_block_mode <= GLITCH_CHAT_NONE then return false end

    local glitches = {}
    for _, v in PlayerIterator() do
        if v:IsGlitch() and not v:IsRoleAbilityDisabled() then
            TableInsert(glitches, v)
        end
    end

    if #glitches == 0 then return false end
    if chat_block_mode == GLITCH_CHAT_BLOCK_ALWAYS then return true end

    for _, v in ipairs(glitches) do
        -- If any of the glitches are alive, block communications
        if chat_block_mode == GLITCH_CHAT_BLOCK_WHILE_ALIVE then
            if v:Alive() then return true end
        -- If any of the glitches are alive or their corpses are unconfirmed, block communications
        elseif chat_block_mode == GLITCH_CHAT_BLOCK_WHILE_UNCONFIRMED then
            if v:Alive() or not v:GetNWBool("body_searched", false) then return true end
        end
    end

    -- If got to this point all glitches match the chat block mode rule
    return false
end