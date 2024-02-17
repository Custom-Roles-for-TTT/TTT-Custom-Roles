include("weaponry_shd.lua") -- inits WEPS tbl

local concommand = concommand
local file = file
local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local player = player
local string = string
local table = table
local timer = timer
local util = util
local weapons = weapons

---- Weapon system, pickup limits, etc

local CallHook = hook.Call
local CreateEntity = ents.Create
local GetAllPlayers = player.GetAll
local IsEquipment = WEPS.IsEquipment
local StringLower = string.lower
local StringSub = string.sub

-- Prevent players from picking up multiple weapons of the same type etc
function GM:PlayerCanPickupWeapon(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return false end

    -- While resetting the map, players should not be allowed to pick up the newly-reset weapon
    -- entities, because they would be stripped again during the player spawning process and
    -- subsequently be missing.
    if GAMEMODE.RespawningWeapons then
        return false
    end

    -- Disallow picking up for ammo
    if ply:HasWeapon(wep:GetClass()) then
        return false
    elseif not ply:CanCarryWeapon(wep) then
        return false
    elseif IsEquipment(wep) and wep.IsDropped and (not ply:KeyDown(IN_USE)) then
        return false
    end

    local tr = util.TraceEntity({ start = wep:GetPos(), endpos = ply:GetShootPos(), mask = MASK_SOLID }, wep)
    if tr.Fraction == 1.0 or tr.Entity == ply then
        wep:SetPos(ply:GetShootPos())
    end

    return true
end

-- Cache role -> default-weapons table
local loadout_weapons = nil
local function GetLoadoutWeapons(r)
    if not loadout_weapons then
        local tbl = {}
        -- Initialize the table for every role
        for wrole = 0, ROLE_MAX do
            tbl[wrole] = {}
            if wrole >= ROLE_EXTERNAL_START and ROLE_LOADOUT_ITEMS[wrole] then
                for _, v in pairs(ROLE_LOADOUT_ITEMS[wrole]) do
                    if weapons.GetStored(v) then
                        table.insert(tbl[wrole], v)
                    end
                end
            end
        end

        for _, w in pairs(weapons.GetList()) do
            local weap_class = WEPS.GetClass(w)
            if weap_class == "weapon_ttt_unarmed" or weap_class == "weapon_zm_carry" or weap_class == "weapon_zm_improvised" then
                for wrole = 0, ROLE_MAX do
                    table.insert(tbl[wrole], weap_class)
                end
            elseif w and istable(w.InLoadoutFor) then
                for _, wrole in pairs(w.InLoadoutFor) do
                    table.insert(tbl[wrole], weap_class)
                end
            end
        end

        loadout_weapons = tbl
    end

    return loadout_weapons[r]
end

-- Give player loadout weapons they should have for their role that they do not have
-- yet
local function GiveLoadoutWeapons(ply)
    local r = GetRoundState() == ROUND_PREP and ROLE_INNOCENT or ply:GetRole()
    local weps = GetLoadoutWeapons(r)
    if not weps then return end

    for _, cls in pairs(weps) do
        if not ply:HasWeapon(cls) and ply:CanCarryType(WEPS.TypeForWeapon(cls)) then
            ply:Give(cls)
        end
    end
end

local function HasLoadoutWeapons(ply)
    if ply:IsSpec() then return true end

    local r = GetRoundState() == ROUND_PREP and ROLE_INNOCENT or ply:GetRole()
    local weps = GetLoadoutWeapons(r)
    if not weps then return true end

    for _, cls in pairs(weps) do
        if not ply:HasWeapon(cls) and ply:CanCarryType(WEPS.TypeForWeapon(cls)) then
            return false
        end
    end

    return true
end

-- Give loadout items.
local function GiveLoadoutItems(ply)
    local loadout_items = {}
    local role = ply:GetRole()

    local items = EquipmentItems[role]
    if items then
        for _, item in pairs(items) do
            if item.loadout and item.id then
                table.insert(loadout_items, item.id)
            end
        end
    end

    local ext_items = ROLE_LOADOUT_ITEMS[role]
    if ext_items then
        for _, item in pairs(ext_items) do
            if not weapons.GetStored(item) then
                local equip = GetEquipmentItemByName(item)
                if equip ~= nil then
                    table.insert(loadout_items, equip.id)
                end
            end
        end
    end

    for _, id in pairs(loadout_items) do
        ply:GiveEquipmentItem(id)

        hook.Call("TTTOrderedEquipment", GAMEMODE, ply, id, tonumber(id))
        ply:AddBought(id)

        net.Start("TTT_BoughtItem")
        net.WriteBit(true)
        net.WriteUInt(id, 32)
        net.Send(ply)
    end
end

-- Quick hack to limit hats to models that fit them well
local Hattables = { "phoenix.mdl", "arctic.mdl", "Group01", "monk.mdl" }
local function CanWearHat(ply)
    local path = string.Explode("/", ply:GetModel())
    if #path == 1 then path = string.Explode("\\", path) end

    return table.HasValue(Hattables, path[3])
end

CreateConVar("ttt_detective_hats", "1")
-- Just hats right now
local function GiveLoadoutSpecial(ply)
    if ply:IsActiveDetectiveTeam() and GetConVar("ttt_detective_hats"):GetBool() and CanWearHat(ply) then

        if not IsValid(ply.hat) then
            local hat = CreateEntity("ttt_hat_deerstalker")
            if not IsValid(hat) then return end

            hat:SetPos(ply:GetPos() + Vector(0, 0, 70))
            hat:SetAngles(ply:GetAngles())

            hat:SetParent(ply)

            ply.hat = hat

            hat:Spawn()
        end
    else
        SafeRemoveEntity(ply.hat)

        ply.hat = nil
    end
end

local retry_timers = {}
function WEPS.ClearRetryTimers()
    for timer_id, _ in pairs(retry_timers) do
        timer.Remove(timer_id)
    end
    table.Empty(retry_timers)
end

local function ClearLateLoadoutTimer(id)
    local timer_id = "lateloadout" .. id
    timer.Remove(timer_id)
    retry_timers[timer_id] = nil
end

-- Sometimes, in cramped map locations, giving players weapons fails. A timer
-- calling this function is used to get them the weapons anyway as soon as
-- possible.
local function LateLoadout(id)
    local ply = Entity(id)
    if not IsPlayer(ply) then
        ClearLateLoadoutTimer(id)
        return
    end

    if not HasLoadoutWeapons(ply) then
        GiveLoadoutWeapons(ply)

        if HasLoadoutWeapons(ply) then
            ClearLateLoadoutTimer(id)
        end
    end
end

-- Note that this is called both when a player spawns and when a round starts
function GM:PlayerLoadout(ply)
    if IsValid(ply) and (not ply:IsSpec()) then
        -- clear out equipment flags
        ply:ResetEquipment()

        -- Don't actually give out the loadout except for while the round is running
        if GetRoundState() == ROUND_ACTIVE then
            -- give default items
            GiveLoadoutItems(ply)

            -- hand out weaponry
            GiveLoadoutWeapons(ply)

            GiveLoadoutSpecial(ply)

            if not HasLoadoutWeapons(ply) then
                MsgN("Could not spawn all loadout weapons for " .. ply:Nick() .. ", will retry.")
                local timer_id = "lateloadout" .. ply:EntIndex()
                retry_timers[timer_id] = true
                timer.Create(timer_id, 1, 60, function() LateLoadout(ply:EntIndex()) end)
            end
        end
    end
end

function GM:UpdatePlayerLoadouts()
    for _, ply in ipairs(GetAllPlayers()) do
        hook.Call("PlayerLoadout", GAMEMODE, ply)
    end
end

---- Weapon dropping

function WEPS.DropNotifiedWeapon(ply, wep, death_drop)
    if IsValid(ply) and IsValid(wep) then
        -- Hack to tell the weapon it's about to be dropped and should do what it
        -- must right now
        if wep.PreDrop then
            wep:PreDrop(death_drop)
        end

        -- PreDrop might destroy weapon
        if not IsValid(wep) then return end

        -- Tag this weapon as dropped, so that if it's a special weapon we do not
        -- auto-pickup when nearby.
        wep.IsDropped = true

        -- After dropping a weapon, always switch to holstered, so that traitors
        -- will never accidentally pull out a traitor weapon.
        --
        -- Perform this *before* the drop in order to abuse the fact that this
        -- holsters the weapon, which in turn aborts any reload that's in
        -- progress. We don't want a dropped weapon to be in a reloading state
        -- because the relevant timer is reset when picking it up, making the
        -- reload happen instantly. This allows one to dodge the delay by dropping
        -- during reload. All of this is a workaround for not having access to
        -- CBaseWeapon::AbortReload() (and that not being handled in
        -- CBaseWeapon::Drop in the first place).
        ply:SelectWeapon("weapon_ttt_unarmed")

        ply:DropWeapon(wep)

        wep:PhysWake()
    end
end

local function DropActiveWeapon(ply)
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()

    if not IsValid(wep) then return end

    if wep.AllowDrop == false then
        return
    end

    local tr = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 32, ply)

    if tr.HitWorld then
        LANG.Msg(ply, "drop_no_room")
        return
    end

    ply:AnimPerformGesture(ACT_GMOD_GESTURE_ITEM_PLACE)

    WEPS.DropNotifiedWeapon(ply, wep)
end
concommand.Add("ttt_dropweapon", DropActiveWeapon)

local function DropActiveAmmo(ply)
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end

    if not wep.AmmoEnt then return end

    local amt = wep:Clip1()
    if amt < 1 or amt <= (wep.Primary.ClipSize * 0.25) then
        LANG.Msg(ply, "drop_no_ammo")
        return
    end

    local pos, ang = ply:GetShootPos(), ply:EyeAngles()
    local dir = (ang:Forward() * 32) + (ang:Right() * 6) + (ang:Up() * -5)

    local tr = util.QuickTrace(pos, dir, ply)
    if tr.HitWorld then return end

    wep:SetClip1(0)

    ply:AnimPerformGesture(ACT_GMOD_GESTURE_ITEM_GIVE)

    local box = CreateEntity(wep.AmmoEnt)
    if not IsValid(box) then return end

    box:SetPos(pos + dir)
    box:SetOwner(ply)
    box:Spawn()

    box:PhysWake()

    local phys = box:GetPhysicsObject()
    if IsValid(phys) then
        phys:ApplyForceCenter(ang:Forward() * 1000)
        phys:ApplyForceOffset(VectorRand(), vector_origin)
    end

    box.AmmoAmount = amt

    timer.Simple(2, function()
        if IsValid(box) then
            box:SetOwner(nil)
        end
    end)
end
concommand.Add("ttt_dropammo", DropActiveAmmo)


-- Give a weapon to a player. If the initial attempt fails due to heisenbugs in
-- the map, keep trying until the player has moved to a better spot where it
-- does work.
local function GiveEquipmentWeapon(sid64, cls)
    -- Referring to players by SteamID because a player may disconnect while his
    -- unique timer still runs, in which case we want to be able to stop it. For
    -- that we need its name, and hence their SteamID64.
    local ply = player.GetBySteamID64(sid64)
    local tmr = "give_equipment" .. sid64

    if (not IsValid(ply)) or (not ply:IsShopRole(true)) then
        timer.Remove(tmr)
        return
    end

    -- giving attempt, will fail if we're in a crazy spot in the map or perhaps
    -- other glitchy cases
    local w = ply:Give(cls)

    if (not IsValid(w)) or (not ply:HasWeapon(cls)) then
        if not timer.Exists(tmr) then
            retry_timers[tmr] = true
            timer.Create(tmr, 1, 60, function() GiveEquipmentWeapon(sid64, cls) end)
        end

        -- we will be retrying
    else
        -- can stop retrying, if we were
        timer.Remove(tmr)
        retry_timers[tmr] = nil

        if w.WasBought then
            -- some weapons give extra ammo after being bought, etc
            w:WasBought(ply)
        end
    end
end

local function HasPendingOrder(ply)
    return timer.Exists("give_equipment" .. tostring(ply:SteamID64()))
end

function GM:TTTCanOrderEquipment(ply, id, is_item)
    --- return true to allow buying of an equipment item, false to disallow
    return true
end

-- Equipment buying
local function OrderEquipment(ply, cmd, args)
    if not IsValid(ply) or #args ~= 1 then return end

    if not ply:IsActiveShopRole() then return end

    -- no credits, can't happen when buying through menu as button will be off
    if ply:GetCredits() < 1 then return end

    -- it's an item if the arg is an id instead of an ent name
    local id = args[1]
    local is_item = tonumber(id)

    if not hook.Run("TTTCanOrderEquipment", ply, id, is_item) then return end

    -- we use weapons.GetStored to save time on an unnecessary copy, we will not
    -- be modifying it
    local swep_table = (not is_item) and weapons.GetStored(id) or nil

    local role = ply:GetRole()

    local rolemode = cvars.Number("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_mode", SHOP_SYNC_MODE_NONE)
    local traitorsync = cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_sync", false) and TRAITOR_ROLES[role]
    local sync_traitor_weapons = traitorsync or (rolemode > SHOP_SYNC_MODE_NONE)

    local promoted = ply:IsDetectiveLike() and not DETECTIVE_ROLES[role]
    local detectivesync = cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_sync", false) and DETECTIVE_ROLES[role]
    local sync_detective_weapons = detectivesync or promoted or (rolemode > SHOP_SYNC_MODE_NONE)

    local sync_roles = ROLE_SHOP_SYNC_ROLES[role]
    if type(sync_roles) ~= "table" then
        sync_roles = {}
    end

    -- If traitor weapons are to be synced, add them to the list
    if sync_traitor_weapons and not table.HasValue(sync_roles, ROLE_TRAITOR) then
        table.insert(sync_roles, ROLE_TRAITOR)
    end
    -- If detective weapons are to be synced, add them to the list
    if sync_detective_weapons and not table.HasValue(sync_roles, ROLE_DETECTIVE) then
        table.insert(sync_roles, ROLE_DETECTIVE)
    end

    -- If this role has a table of additional weapons and that table includes this weapon
    -- and this weapon is not currently buyable by the role then mark this weapon as buyable
    if swep_table then
        -- some weapons can only be bought once per player per round, this used to be
        -- defined in a table here, but is now in the SWEP's table
        if swep_table.LimitedStock and ply:HasBought(id) then
            LANG.Msg(ply, "buy_no_stock")
            return
        end

        -- Pre-load the weapons for each synced role so that any that have their CanBuy modified will also apply to the enabled allied role(s)
        if #sync_roles > 0 then
            for _, r in pairs(sync_roles) do
                WEPS.HandleCanBuyOverrides(swep_table, r, true, sync_traitor_weapons, sync_detective_weapons)
            end
        end

        -- Add the loaded weapons for this role
        WEPS.HandleCanBuyOverrides(swep_table, role, false, sync_traitor_weapons, sync_detective_weapons, false, sync_roles)
    end

    -- Don't give roles their items if delayed shop is enabled
    local should_give = not ply:ShouldDelayShopPurchase()
    local received = false
    if is_item then
        id = tonumber(id)

        -- item whitelist check
        local allowed = GetEquipmentItem(role, id)
        -- Check for the syncing options
        if not allowed then
            if rolemode > SHOP_SYNC_MODE_NONE then
                -- Traitor OR Detective
                if rolemode == SHOP_SYNC_MODE_UNION then
                    allowed = GetEquipmentItem(ROLE_TRAITOR, id) or GetEquipmentItem(ROLE_DETECTIVE, id)
                -- Traitor AND Detective
                elseif rolemode == SHOP_SYNC_MODE_INTERSECT then
                    allowed = GetEquipmentItem(ROLE_TRAITOR, id) and GetEquipmentItem(ROLE_DETECTIVE, id)
                -- Detective only
                elseif rolemode == SHOP_SYNC_MODE_DETECTIVE then
                    allowed = GetEquipmentItem(ROLE_DETECTIVE, id)
                -- Traitor only
                elseif rolemode == SHOP_SYNC_MODE_TRAITOR then
                    allowed = GetEquipmentItem(ROLE_TRAITOR, id)
                end
            end
        end

        -- Check each sync role for their equipment as well
        if not allowed and #sync_roles > 0 then
            for _, r in pairs(sync_roles) do
                allowed = GetEquipmentItem(r, id)
                if allowed then
                    break
                end
            end
        end

        -- If it's not allowed, check the extra buyable equipment
        if not allowed then
            for _, v in ipairs(WEPS.BuyableWeapons[role]) do
                -- If this isn't a weapon, get its information from one of the roles and compare that to the ID we have
                if not weapons.GetStored(v) then
                    local equip = GetEquipmentItemByName(v)
                    if equip ~= nil and equip.id == id then
                        allowed = true
                        break
                    end
                end
            end
        end

        -- Lastly, if it is allowed check the exclude equipment list
        if allowed then
            for _, v in ipairs(WEPS.ExcludeWeapons[role]) do
                -- If this isn't a weapon, get its information from one of the roles and compare that to the ID we have
                if not weapons.GetStored(v) then
                    local equip = GetEquipmentItemByName(v)
                    if equip ~= nil and equip.id == id then
                        allowed = false
                        break
                    end
                end
            end
        end

        -- Check if the item needs another purchased before it can be
        if allowed then
            if not WEPS.PlayerOwnsWepReqs(ply, allowed) then
                print(ply, "tried to buy item requiring another item they don't own", id)
                return
            end
        end

        if not allowed then
            print(ply, "tried to buy item not buyable for their role:", id)
            return
        end

        -- ownership check and finalise
        if id and EQUIP_NONE < id then
            if not ply:HasEquipmentItem(id) then
                if should_give then
                    ply:GiveEquipmentItem(id)
                end

                received = true
            end
        end
    elseif swep_table then
        -- weapon whitelist check
        if not table.HasValue(swep_table.CanBuy, role) then
            print(ply, "tried to buy weapon their role is not permitted to buy")
            return
        end

        -- if we have a pending order because we are in a confined space, don't
        -- start a new one
        if HasPendingOrder(ply) then
            LANG.Msg(ply, "buy_pending")
            return
        end

        -- no longer restricted to only WEAPON_EQUIP weapons, just anything that
        -- is whitelisted and carryable
        if ply:CanCarryWeapon(swep_table) then
            if should_give then
                GiveEquipmentWeapon(ply:SteamID64(), id)
            end

            received = true
        end
    end

    if received then
        ply:SubtractCredits(1)
        if should_give then
            LANG.Msg(ply, "buy_received")
        else
            LANG.Msg(ply, "buy_received_delay")
        end

        ply:AddBought(id)

        timer.Simple(0.5,
                function()
                    if not IsValid(ply) then return end
                    net.Start("TTT_BoughtItem")
                    net.WriteBit(is_item)
                    if is_item then
                        net.WriteUInt(id, 32)
                    else
                        net.WriteString(id)
                    end
                    net.Send(ply)
                end)

        hook.Call("TTTOrderedEquipment", GAMEMODE, ply, id, is_item)
    end
end
concommand.Add("ttt_order_equipment", OrderEquipment)

concommand.Add("ttt_order_for_someone", function(ply, cmd, args)
    local target_name = args[1]
    local target = nil
    for _, v in pairs(GetAllPlayers()) do
        if target_name == v:Nick() then
            target = v
            break
        end
    end

    if not IsValid(target) then return end
    local new_args = {}
    new_args[1] = args[2]

    OrderEquipment(target, cmd, new_args)
end, nil, nil, FCVAR_CHEAT)

function GM:TTTToggleDisguiser(ply, state)
    -- Can be used to prevent players from using this button.
    -- return true to prevent it.
end

local function SetDisguise(ply, cmd, args)
    if not IsValid(ply) then return end

    if ply:HasEquipmentItem(EQUIP_DISGUISE) then
        local state = #args == 1 and tobool(args[1])
        if hook.Run("TTTToggleDisguiser", ply, state) then return end

        ply:SetNWBool("disguised", state)
        local SetMDL = FindMetaTable("Entity").SetModel
        -- Change the player's model to a random one when they disguise and back to their previous when they undisguise
        if state then
            ply.oldmodel = ply:GetModel()
            local randommodel = GetRandomPlayerModel()
            SetMDL(ply, randommodel)
        elseif ply.oldmodel then
            SetMDL(ply, ply.oldmodel)
            ply.oldmodel = nil
        end

        LANG.Msg(ply, state and "disg_turned_on" or "disg_turned_off")
    end
end
concommand.Add("ttt_set_disguise", SetDisguise)

local function CheatCredits(ply)
    if IsValid(ply) then
        ply:AddCredits(10)
    end
end
concommand.Add("ttt_cheat_credits", CheatCredits, nil, nil, FCVAR_CHEAT)

local function TransferCredits(ply, cmd, args)
    if (not IsValid(ply)) or (not ply:IsActiveSpecial()) then return end
    if #args ~= 2 then return end

    local sid64 = tostring(args[1])
    local credits = tonumber(args[2])
    if sid64 and credits then
        local target = player.GetBySteamID64(sid64)
        if (not IsValid(target)) or (not target:IsActiveSpecial()) or not ply:IsSameTeam(target) or (target == ply) then
            LANG.Msg(ply, "xfer_no_recip")
            return
        end

        if ply:GetCredits() < credits then
            LANG.Msg(ply, "xfer_no_credits")
            return
        end

        credits = math.Clamp(credits, 0, ply:GetCredits())
        if credits == 0 then return end

        ply:SubtractCredits(credits)
        target:AddCredits(credits)

        LANG.Msg(ply, "xfer_success", { player = target:Nick() })
        LANG.Msg(target, "xfer_received", { player = ply:Nick(), num = credits })
    end
end
concommand.Add("ttt_transfer_credits", TransferCredits)

local function FakeTransferCredits(ply, cmd, args)
    if (not IsValid(ply)) or (not ply:IsActiveSpecial()) then return end
    if #args ~= 1 then return end

    local sid = tostring(args[1])
    local credits = tonumber(args[2])
    if credits then
        local target = player.GetBySteamID64(sid)
        if (not IsValid(target)) or (target == ply) then
            LANG.Msg(ply, "xfer_no_recip")
            return
        end

        if ply:GetCredits() < credits then
            LANG.Msg(ply, "xfer_no_credits")
            return
        end

        credits = math.Clamp(credits, 0, ply:GetCredits())
        if credits == 0 then return end

        ply:SubtractCredits(credits)

        LANG.Msg(ply, "xfer_success", { player = target:Nick() })
    end
end
concommand.Add("ttt_fake_transfer_credits", FakeTransferCredits)

-- Protect against non-TTT weapons that may break the HUD
function GM:WeaponEquip(wep, ply)
    if not IsValid(wep) then return end

    -- only remove if they lack critical stuff
    if not wep.Kind then
        wep:Remove()
        ErrorNoHalt("Equipped weapon " .. wep:GetClass() .. " is not compatible with TTT\n")
    end
end

-- non-cheat developer commands can reveal precaching the first time equipment
-- is bought, so trigger it at the start of a round instead
function WEPS.ForcePrecache()
    for _, w in ipairs(weapons.GetList()) do
        if w.WorldModel then
            util.PrecacheModel(w.WorldModel)
        end
        if w.ViewModel then
            util.PrecacheModel(w.ViewModel)
        end
    end
end

-- Roleweapons

-- If this logic or the list of roles who can buy is changed, it must also be updated in OrderEquipment above and cl_equip.lua
-- This also sends a cache reset request to every client so that things like shop randomization happen every round
function WEPS.HandleRoleEquipment(ply)
    local handled = false
    for id, name in pairs(ROLE_STRINGS_RAW) do
        WEPS.PrepWeaponsLists(id)

        local roleBuyables = {}
        local roleExcludes = {}
        local roleNoRandoms = {}
        -- Check for the JSON file first and use that if it exists
        if file.Exists("roleweapons/" .. name .. ".json", "DATA") then
            local roleJson = file.Read("roleweapons/" .. name .. ".json", "DATA")
            if roleJson then
                local roleData = util.JSONToTable(roleJson)
                if roleData then
                    roleBuyables = roleData.Buyables or {}
                    roleExcludes = roleData.Excludes or {}
                    roleNoRandoms = roleData.NoRandoms or {}
                end
            end
        -- Otherwise use the old text files and also convert them to a JSON file
        else
            local roleTextFiles, _ = file.Find("roleweapons/" .. name .. "/*.txt", "DATA")
            for _, v in pairs(roleTextFiles) do
                local exclude = false
                local norandom = false
                -- Extract the weapon name from the file name
                local lastdotpos = v:find("%.")
                local weaponname = StringSub(v, 0, lastdotpos - 1)

                -- Check that there isn't a two-part extension (e.g. "something.exclude.txt")
                local extension = StringSub(v, lastdotpos + 1, #v)
                lastdotpos = extension:find("%.")

                -- If there is, check if it equals one of our expected types
                if lastdotpos ~= nil then
                    extension = StringLower(StringSub(extension, 0, lastdotpos - 1))
                    if extension == "exclude" then
                        exclude = true
                    elseif extension == "norandom" then
                        norandom = true
                    end
                end

                if exclude then
                    table.insert(roleExcludes, weaponname)
                elseif norandom then
                    table.insert(roleNoRandoms, weaponname)
                else
                    table.insert(roleBuyables, weaponname)
                end
            end

            -- Create JSON file if we have anything in the tables
            if #roleBuyables > 0 or #roleExcludes > 0 or #roleNoRandoms > 0 then
                local roleData = {
                    Buyables = roleBuyables,
                    Excludes = roleExcludes,
                    NoRandoms = roleNoRandoms
                }
                local roleJson = util.TableToJSON(roleData)
                file.Write("roleweapons/" .. name .. ".json", roleJson)
                print("[ROLEWEAPONS] Converting legacy text files to new JSON format for " .. name)
            end

            -- If this role has a directory, get rid of it now that we've converted to JSON
            if file.IsDir("roleweapons/" .. name, "DATA") then
                print("[ROLEWEAPONS] Removing legacy text file structure for " .. name)
                for _, v in pairs(roleTextFiles) do
                    file.Delete("roleweapons/" .. name .. "/" .. v, "DATA")
                end
                file.Delete("roleweapons/" .. name, "DATA")
            end
        end

        -- Copy the loaded table into the global table for this role
        WEPS.BuyableWeapons[id] = roleBuyables
        WEPS.ExcludeWeapons[id] = roleExcludes
        WEPS.BypassRandomWeapons[id] = roleNoRandoms

        if id >= ROLE_EXTERNAL_START and ROLE_SHOP_ITEMS[id] then
            for _, v in pairs(ROLE_SHOP_ITEMS[id]) do
                table.insert(WEPS.BuyableWeapons[id], v)
                table.insert(roleBuyables, v)
            end
        end

        if #roleBuyables > 0 or #roleExcludes > 0 or #roleNoRandoms > 0 then
            net.Start("TTT_BuyableWeapons")
            net.WriteInt(id, 16)
            net.WriteTable(roleBuyables)
            net.WriteTable(roleExcludes)
            net.WriteTable(roleNoRandoms)
            if ply then
                net.Send(ply)
            else
                net.Broadcast()
            end
            handled = true
        end
    end

    -- Send this once if the roleweapons feature wasn't used (which resets the cache on its own)
    if not handled then
        net.Start("TTT_ResetBuyableWeaponsCache")
        if ply then
            net.Send(ply)
        else
            net.Broadcast()
        end
    end

    net.Start("TTT_RoleWeaponsLoaded")
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
    CallHook("TTTRoleWeaponsLoaded")
end

net.Receive("TTT_ConfigureRoleWeapons", function(len, ply)
    if not IsPlayer(ply) then return end

    if not ply:IsAdmin() and not ply:IsSuperAdmin() then
        ErrorNoHalt("Player without admin access attempted to configure role weapons: " .. ply:Nick() .. " (" .. ply:SteamID() .. ")\n")
        return
    end

    local id = StringLower(net.ReadString())
    local role = net.ReadInt(8)
    local includeSelected = net.ReadBool()
    local excludeSelected = net.ReadBool()
    local noRandomSelected = net.ReadBool()
    local roleName = StringLower(ROLE_STRINGS_RAW[role])

    -- Ensure directories exist
    if not file.IsDir("roleweapons", "DATA") then
        if file.Exists("roleweapons", "DATA") then
            ErrorNoHalt("Item named 'roleweapons' already exists in garrysmod/data but it is not a directory\n")
            return
        end

        file.CreateDir("roleweapons")
    end

    local roleData = nil
    local rolePath = "roleweapons/" .. roleName .. ".json"
    if file.Exists(rolePath, "DATA") then
        local roleJson = file.Read(rolePath, "DATA")
        if roleJson then
            local loadedData = util.JSONToTable(roleJson)
            if loadedData then
                roleData = loadedData
            end
        end
    end

    -- If we didn't load any role data, set up the default tables
    if not roleData then
        roleData = {
            Buyables = {},
            Excludes = {},
            NoRandoms = {}
        }
    end

    -- Update tables
    local included = table.HasValue(roleData.Buyables, id)
    if not includeSelected then
        if included then
            -- Remove the entry from the table
            table.RemoveByValue(roleData.Buyables, id)
            -- Make the table have sequential keys again
            roleData.Buyables = table.ClearKeys(roleData.Buyables)
        end
    elseif not included then
        table.insert(roleData.Buyables, id)
    end

    local excluded = table.HasValue(roleData.Excludes, id)
    if not excludeSelected then
        if excluded then
            -- Remove the entry from the table
            table.RemoveByValue(roleData.Excludes, id)
            -- Make the table have sequential keys again
            roleData.Excludes = table.ClearKeys(roleData.Excludes)
        end
    elseif not excluded then
        table.insert(roleData.Excludes, id)
    end

    local noRandom = table.HasValue(roleData.NoRandoms, id)
    if not noRandomSelected then
        if noRandom then
            -- Remove the entry from the table
            table.RemoveByValue(roleData.NoRandoms, id)
            -- Make the table have sequential keys again
            roleData.NoRandoms = table.ClearKeys(roleData.NoRandoms)
        end
    elseif not noRandom then
        table.insert(roleData.NoRandoms, id)
    end

    -- Save the updated file to the disk
    local roleJson = util.TableToJSON(roleData)
    file.Write(rolePath, roleJson)

    -- Update tables
    WEPS.UpdateWeaponLists(role, id, includeSelected, excludeSelected, noRandomSelected)

    -- Send list update to client
    net.Start("TTT_UpdateBuyableWeapons")
    net.WriteString(id)
    net.WriteInt(role, 8)
    net.WriteBool(includeSelected)
    net.WriteBool(excludeSelected)
    net.WriteBool(noRandomSelected)
    net.Broadcast()
end)
