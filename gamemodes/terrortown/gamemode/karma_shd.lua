KARMA = {}

KARMA.cv = {}
KARMA.cv.enabled = CreateConVar("ttt_karma", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED)
KARMA.cv.max = CreateConVar("ttt_karma_max", "1000", FCVAR_REPLICATED)

local config = KARMA.cv
function KARMA.IsEnabled()
    return config.enabled:GetBool()
end