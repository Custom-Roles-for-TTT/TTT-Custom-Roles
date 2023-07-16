local startChance = .2
local startDelay = 10
local minSpectators = 3
local events = {
    ["apparition"] = 2,
    ["bets"] = 1,
    ["boo"] = 2,
    ["deadchat"] = 1,
    ["explosivespectate"] = 2,
    ["ghosting"] = 1,
    ["gifts"] = 1,
    ["poltergeists"] = 1,
    ["revenge"] = 2,
    ["smoke"] = 2,
    ["specbees"] = 2,
    ["specbuff"] = 1
}

local function GetRandomWeightedEvent()
    local weighted_events = {}
    for id, weight in pairs(events) do
        if not Randomat:CanEventRun(id) then continue end

        for _ = 1, weight do
            table.insert(weighted_events, id)
        end
    end
    
    if #weighted_events == 0 then return nil end

    -- Randomize the weighted list
    table.Shuffle(weighted_events)

    -- Then get a random index from the random list for more randomness
    local count = table.Count(weighted_events)
    local idx = math.random(count)
    return weighted_events[idx]
end

hook.Add("TTTBeginRound", "SpectatorRandomats_TTTBeginRound", function()
    if math.random() > startChance then return end

    local specCount = 0
    for _, p in ipairs(player.GetAll()) do
        if p:IsSpec() or not p:Alive() then
            specCount = specCount + 1
        end
    end

    if specCount < minSpectators then return end

    print("[SpectatorRandomats] There are " .. specCount .. " spectators. Starting event after " .. startDelay .. " seconds.")
    timer.Create("SpectatorRandomatsDelay", startDelay, 1, function()
        -- If one of these is running already, don't start a new one
        for id, _ in pairs(events) do
            if Randomat:IsEventActive(id) then
                print("[SpectatorRandomats] Another spectator-based Randomat is already running, no new event will be started")
                return
            end
        end

        local event = GetRandomWeightedEvent()
        if not event then
            print("[SpectatorRandomats] No valid event was found to start")
            return
        end

        print("[SpectatorRandomats] Starting " .. event)
        Randomat:TriggerEvent(event)
    end)
end)

hook.Add("TTTEndRound", "SpectatorRandomats_TTTEndRound", function()
    timer.Remove("SpectatorRandomatsDelay")
end)
