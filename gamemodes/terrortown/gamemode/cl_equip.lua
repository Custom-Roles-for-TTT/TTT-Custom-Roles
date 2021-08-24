include("shared.lua")

---- Traitor equipment menu

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

-- create ClientConVars
local numColsVar = CreateClientConVar("ttt_bem_cols", 4, true, false, "Sets the number of columns in the Traitor/Detective menu's item list.")
local numRowsVar = CreateClientConVar("ttt_bem_rows", 5, true, false, "Sets the number of rows in the Traitor/Detective menu's item list.")
local itemSizeVar = CreateClientConVar("ttt_bem_size", 64, true, false, "Sets the item size in the Traitor/Detective menu's item list.")
local showCustomVar = CreateClientConVar("ttt_bem_marker_custom", 1, true, false, "Should custom items get a marker?")
local showFavoriteVar = CreateClientConVar("ttt_bem_marker_fav", 1, true, false, "Should favorite items get a marker?")
local showSlotVar = CreateClientConVar("ttt_bem_marker_slot", 1, true, false, "Should items get a slot-marker?")

-- Buyable weapons are loaded automatically. Buyable items are defined in
-- equip_items_shd.lua

local Equipment = { }

local function UpdateWeaponList(role, list, weapon)
    if not table.HasValue(list[role], weapon) then
        table.insert(list[role], weapon)
    end
end

local function ResetWeaponsCache()
    -- Clear the weapon cache for each role
    for role, _ in pairs(ROLE_STRINGS_RAW) do
        Equipment[role] = nil
    end
    -- Clear the overall weapons cache
    Equipment = {}
    WEPS.ResetWeaponsCache()
end
concommand.Add("ttt_reset_weapons_cache", ResetWeaponsCache)

net.Receive("TTT_ResetBuyableWeaponsCache", function()
    ResetWeaponsCache()
    UpdateRoleWeaponState()
end)

net.Receive("TTT_BuyableWeapons", function()
    local role = net.ReadInt(16)
    WEPS.PrepWeaponsLists(role)
    ResetWeaponsCache()

    local roleweapons = net.ReadTable()
    for _, v in pairs(roleweapons) do
        UpdateWeaponList(role, WEPS.BuyableWeapons, v)
    end
    local excludeweapons = net.ReadTable()
    for _, v in pairs(excludeweapons) do
        UpdateWeaponList(role, WEPS.ExcludeWeapons, v)
    end
    local norandomweapons = net.ReadTable()
    for _, v in pairs(norandomweapons) do
        UpdateWeaponList(role, WEPS.BypassRandomWeapons, v)
    end
end)

local function ItemIsWeapon(item) return not tonumber(item.id) end

function GetEquipmentForRole(role, promoted, block_randomization)
    WEPS.PrepWeaponsLists(role)

    -- Determine which role sync variable to use, if any
    local rolemode = GetGlobalInt("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_mode", SHOP_SYNC_MODE_NONE)
    local traitorsync = GetGlobalBool("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_sync", false) and TRAITOR_ROLES[role]
    local sync_traitor_weapons = traitorsync or (rolemode > SHOP_SYNC_MODE_NONE)

    -- Pre-load the Traitor weapons so that any that have their CanBuy modified will also apply to the enabled allied role(s)
    if sync_traitor_weapons and not Equipment[ROLE_TRAITOR] then
        GetEquipmentForRole(ROLE_TRAITOR, false, true)
    end

    local sync_detective_like = promoted and (role == ROLE_DEPUTY or role == ROLE_IMPERSONATOR)
    local detectivesync = GetGlobalBool("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_sync", false) and DETECTIVE_ROLES[role]
    local sync_detective_weapons = detectivesync or sync_detective_like or (rolemode > SHOP_SYNC_MODE_NONE)

    -- Pre-load the Detective weapons so that any that have their CanBuy modified will also apply to the enabled allied role(s)
    if sync_detective_weapons and not Equipment[ROLE_DETECTIVE] then
        GetEquipmentForRole(ROLE_DETECTIVE, false, true)
    end

    -- Cache the equipment unless the role's shop can change mid round
    if not Equipment[role] then
        -- start with all the non-weapon goodies
        local tbl = table.Copy(EquipmentItems)

        -- find buyable weapons to load info from
        for _, v in pairs(weapons.GetList()) do
            WEPS.HandleCanBuyOverrides(v, role, block_randomization, sync_traitor_weapons, sync_detective_weapons)
            if v and v.CanBuy then
                local data = v.EquipMenuData or {}
                local base = {
                    id = WEPS.GetClass(v),
                    name = v.PrintName or "Unnamed",
                    limited = v.LimitedStock,
                    kind = v.Kind or WEAPON_NONE,
                    slot = (v.Slot or 0) + 1,
                    material = v.Icon or "vgui/ttt/icon_id",
                    -- the below should be specified in EquipMenuData, in which case
                    -- these values are overwritten
                    type = "Type not specified",
                    model = "models/weapons/w_bugbait.mdl",
                    desc = "No description specified."
                };

                -- Force material to nil so that model key is used when we are
                -- explicitly told to do so (ie. material is false rather than nil).
                if data.modelicon then
                    base.material = nil
                end

                table.Merge(base, data)

                -- add this buyable weapon to all relevant equipment tables
                for _, r in pairs(v.CanBuy) do
                    table.insert(tbl[r], base)
                end
            end
        end

        local traitor_equipment = {}
        local traitor_equipment_ids = {}
        local detective_equipment = {}
        local detective_equipment_ids = {}
        local available = {}
        for r, is in pairs(tbl) do
            for _, i in pairs(is) do
                if i then
                    -- Mark custom items
                    i.custom = not table.HasValue(DefaultEquipment[r], i.id)

                    -- Run through this again to make sure non-custom equipment is saved to be synced below
                    if not ItemIsWeapon(i) and i.custom then
                        -- Track the items already available to this role to avoid duplicates
                        if r == role then
                            available[i.id] = true
                        end

                        if r == ROLE_TRAITOR then
                            table.insert(traitor_equipment, i)
                            table.insert(traitor_equipment_ids, i.id)
                        elseif r == ROLE_DETECTIVE then
                            table.insert(detective_equipment, i)
                            table.insert(detective_equipment_ids, i.id)
                        end
                    end
                end
            end
        end

        -- Sync the equipment from above
        if rolemode == SHOP_SYNC_MODE_INTERSECT then
            for idx, i in pairs(traitor_equipment_ids) do
                -- Traitor AND Detective mode, (Detective && Traitor) -> Sync Role
                if not available[i] and table.HasValue(detective_equipment_ids, i) then
                    table.insert(tbl[role], traitor_equipment[idx])
                    available[i] = true
                end
            end
        else
            for _, i in pairs(traitor_equipment) do
                -- Avoid duplicates
                if not available[i.id] and
                    -- Traitor -> Special Traitor
                    (sync_traitor_weapons or
                    -- Traitor OR Detective or Traitor-only modes, Traitor -> Sync Role
                    (rolemode == SHOP_SYNC_MODE_UNION or rolemode == SHOP_SYNC_MODE_TRAITOR)) then
                    table.insert(tbl[role], i)
                    available[i.id] = true
                end
            end
            for _, i in pairs(detective_equipment) do
                -- Avoid duplicates
                if not available[i.id] and
                    -- Detective -> Detective-like
                    (sync_detective_like or
                    -- Traitor OR Detective or Detective-only modes, Detective -> Mercenary/Killer Clown
                    (rolemode == SHOP_SYNC_MODE_UNION or rolemode == SHOP_SYNC_MODE_DETECTIVE)) then
                    table.insert(tbl[role], i)
                    available[i.id] = true
                end
            end
        end

        -- Also check the extra buyable equipment
        for _, v in ipairs(WEPS.BuyableWeapons[role]) do
            -- If this isn't a weapon, get its information from one of the roles and compare that to the ID we have
            if not weapons.GetStored(v) then
                local equip = GetEquipmentItemByName(v)
                -- If this exists and isn't already in the list, add it to the role's list
                if equip ~= nil and not available[equip.id] then
                    table.insert(tbl[role], equip)
                    available[equip.id] = true
                end
            end
        end

        -- Lastly, go through the excludes to make sure things are removed that should be
        for _, v in ipairs(WEPS.ExcludeWeapons[role]) do
            -- If this isn't a weapon, get its information from one of the roles and compare that to the ID we have
            if not weapons.GetStored(v) then
                local equip = GetEquipmentItemByName(v)
                -- If this exists and is in the available list, remove it from the role's list
                if equip ~= nil then
                    for idx, i in ipairs(tbl[role]) do
                        if not ItemIsWeapon(i) and i.id == equip.id then
                            table.remove(tbl[role], idx)
                            break
                        end
                    end

                    available[equip.id] = false
                end
            end
        end

        Equipment[role] = tbl[role]
    end

    return Equipment and Equipment[role] or {}
end

local function ShouldDelayPurchase(client)
    return client:IsClown() and GetGlobalBool("ttt_clown_shop_delay", false) and not client:GetNWBool("KillerClownActive", false)
end

local function CanCarryWeapon(item)
    local client = LocalPlayer()
    -- Don't allow the clown to buy any weapon that has a kind matching one of the weapons they've already bought
    if item.kind and client.bought and ShouldDelayPurchase(client) then
        for _, id in ipairs(client.bought) do
            local wep = weapons.GetStored(id)
            if wep and wep.Kind == item.kind then
                return false
            end
        end
    end

    return client:CanCarryType(item.kind)
end

local function HasEquipmentItem(item)
    local client = LocalPlayer()
    -- Don't allow the clown to buy the same equipment item twice if delayed acceptance is enabled
    if client.bought and ShouldDelayPurchase(client) then
        return table.HasValue(client.bought, tostring(item.id))
    end

    return client:HasEquipmentItem(item.id)
end

local color_bad = Color(220, 60, 60, 255)
local color_good = Color(255, 255, 255, 255)

-- Creates tabel of labels showing the status of ordering prerequisites
local function PreqLabels(parent, x, y)
    local tbl = {}

    -- coins icon
    tbl.credits = vgui.Create("DLabel", parent)
    tbl.credits:SetPos(x, y)

    tbl.credits.img = vgui.Create("DImage", parent)
    tbl.credits.img:SetSize(32, 32)
    tbl.credits.img:CopyPos(tbl.credits)
    tbl.credits.img:MoveLeftOf(tbl.credits)
    tbl.credits.img:SetImage("vgui/ttt/equip/coin.png")

    tbl.credits.Check = function(s, sel)
        local credits = LocalPlayer():GetCredits()
        return credits > 0, " " .. credits, GetPTranslation("equip_cost", { num = credits })
    end

    -- carry icon
    tbl.owned = vgui.Create("DLabel", parent)
    tbl.owned:CopyPos(tbl.credits)
    tbl.owned:MoveRightOf(tbl.credits, y * 3)

    tbl.owned.img = vgui.Create("DImage", parent)
    tbl.owned.img:SetSize(32, 32)
    tbl.owned.img:CopyPos(tbl.owned)
    tbl.owned.img:MoveLeftOf(tbl.owned)
    tbl.owned.img:SetImage("vgui/ttt/equip/briefcase.png")

    tbl.owned.Check = function(s, sel)
        if ItemIsWeapon(sel) and (not CanCarryWeapon(sel)) then
            return false, "X", GetPTranslation("equip_carry_slot", { slot = sel.slot })
        elseif (not ItemIsWeapon(sel)) and HasEquipmentItem(sel) then
            return false, "X", GetTranslation("equip_carry_own")
        else
            return true, "✔", GetTranslation("equip_carry")
        end
    end

    -- stock icon
    tbl.bought = vgui.Create("DLabel", parent)
    tbl.bought:CopyPos(tbl.owned)
    tbl.bought:MoveRightOf(tbl.owned, y * 3)

    tbl.bought.img = vgui.Create("DImage", parent)
    tbl.bought.img:SetSize(32, 32)
    tbl.bought.img:CopyPos(tbl.bought)
    tbl.bought.img:MoveLeftOf(tbl.bought)
    tbl.bought.img:SetImage("vgui/ttt/equip/package.png")

    tbl.bought.Check = function(s, sel)
        if sel.limited and LocalPlayer():HasBought(tostring(sel.id)) then
            return false, "X", GetTranslation("equip_stock_deny")
        else
            return true, "✔", GetTranslation("equip_stock_ok")
        end
    end

    for k, pnl in pairs(tbl) do
        pnl:SetFont("DermaLarge")
    end

    return function(selected)
        local allow = true
        for _, pnl in pairs(tbl) do
            local result, text, tooltip = pnl:Check(selected)
            pnl:SetTextColor(result and color_good or color_bad)
            pnl:SetText(text)
            pnl:SizeToContents()
            pnl:SetTooltip(tooltip)
            pnl.img:SetImageColor(result and color_good or color_bad)
            pnl.img:SetTooltip(tooltip)
            allow = allow and result
        end
        return allow
    end
end

-- quick, very basic override of DPanelSelect
local PANEL = {}
local function DrawSelectedEquipment(pnl)
    surface.SetDrawColor(255, 200, 0, 255)
    surface.DrawOutlinedRect(0, 0, pnl:GetWide(), pnl:GetTall())
end

function PANEL:SelectPanel(pnl)
    if pnl then
        self.BaseClass.SelectPanel(self, pnl)
        pnl.PaintOver = DrawSelectedEquipment
    else
        self:OnActivePanelChanged(self.SelectedPanel, pnl)
        self.SelectedPanel = nil
    end
end
vgui.Register("EquipSelect", PANEL, "DPanelSelect")

local SafeTranslate = LANG.TryTranslation

local color_darkened = Color(255, 255, 255, 80)

-- BEM helper functions

function CreateFavTable()
    if not sql.TableExists("ttt_bem_fav") then
        local query = "CREATE TABLE ttt_bem_fav (guid TEXT, role TEXT, weapon_id TEXT)"
        sql.Query(query)
    end
end

function AddFavorite(guid, role, weapon_id)
    local query = "INSERT INTO ttt_bem_fav VALUES('" .. guid .. "','" .. role .. "','" .. weapon_id .. "')"
    sql.Query(query)
end

function RemoveFavorite(guid, role, weapon_id)
    local query = "DELETE FROM ttt_bem_fav WHERE guid = '" .. guid .. "' AND role = '" .. role .. "' AND weapon_id = '" .. weapon_id .. "'"
    sql.Query(query)
end

function GetFavorites(guid, role)
    local query = "SELECT weapon_id FROM ttt_bem_fav WHERE guid = '" .. guid .. "' AND role = '" .. role .. "'"
    local result = sql.Query(query)
    return result
end

function IsFavorite(favorites, weapon_id)
    for _, value in pairs(favorites) do
        local dbid = value["weapon_id"]
        if (dbid == tostring(weapon_id)) then
            return true
        end
    end
    return false
end

-- Create the buy menu

local eqframe = nil

local function ForceCloseTraitorMenu(ply, cmd, args)
    if IsValid(eqframe) then
        eqframe:Close()
    end
end
concommand.Add("ttt_cl_traitorpopup_close", ForceCloseTraitorMenu)

local function TraitorMenuPopup()
    local numCols = GetGlobalInt("ttt_bem_sv_cols", 4)
    local numRows = GetGlobalInt("ttt_bem_sv_rows", 5)
    local itemSize = GetGlobalInt("ttt_bem_sv_size", 64)

    if GetGlobalBool("ttt_bem_allow_change", true) then
        numCols = numColsVar:GetInt()
        numRows = numRowsVar:GetInt()
        itemSize = itemSizeVar:GetInt()
    end

    -- margin
    local m = 5
    -- item list width
    local dlistw = ((itemSize + 2) * numCols) - 2 + 15
    local dlisth = ((itemSize + 2) * numRows) - 2 + 15
    -- right column width
    local diw = 270
    -- frame size
    local w = dlistw + diw + (m * 4)
    local h = dlisth + 75

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then
        return
    end

    -- Close any existing traitor menu
    if eqframe and IsValid(eqframe) then eqframe:Close() end

    local dframe = vgui.Create("DFrame")
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetTitle(GetTranslation("equip_title"))
    dframe:SetVisible(true)
    dframe:ShowCloseButton(true)
    dframe:SetMouseInputEnabled(true)
    dframe:SetDeleteOnClose(true)

    local dsheet = vgui.Create("DPropertySheet", dframe)

    -- Add a callback when switching tabs
    local oldfunc = dsheet.SetActiveTab
    dsheet.SetActiveTab = function(self, new)
        if self.m_pActiveTab ~= new and self.OnTabChanged then
            self:OnTabChanged(self.m_pActiveTab, new)
        end
        oldfunc(self, new)
    end

    dsheet:SetPos(0, 0)
    dsheet:StretchToParent(m, m + 25, m, m)

    local credits = ply:GetCredits()
    local show = false
    -- Only show the shop for roles that have it (or have been promoted/activated to have it)
    local hasShop = ply:CanUseShop()
    if hasShop then
        local can_order = credits > 0
        local padding = dsheet:GetPadding()

        local dequip = vgui.Create("DPanel", dsheet)
        dequip:SetPaintBackground(false)
        dequip:StretchToParent(padding, padding, padding, padding)

        -- Determine if we already have equipment
        local owned_ids = {}
        for _, wep in ipairs(ply:GetWeapons()) do
            if IsValid(wep) and wep.IsEquipment and wep:IsEquipment() then
                table.insert(owned_ids, wep:GetClass())
            end
        end

        -- Stick to one value for no equipment
        if #owned_ids == 0 then
            owned_ids = nil
        end

        local dsearchheight = 25
        local dsearchpadding = 5
        local dsearch = vgui.Create("DTextEntry", dequip)
        dsearch:SetPos(0, 0)
        dsearch:SetSize(dlistw, dsearchheight)
        dsearch:SetPlaceholderText("Search...")
        dsearch:SetUpdateOnType(true)
        dsearch.OnGetFocus = function() dframe:SetKeyboardInputEnabled(true) end
        dsearch.OnLoseFocus = function() dframe:SetKeyboardInputEnabled(false) end

        --- Construct icon listing
        --- icon size = 64 x 64
        local dlist = vgui.Create("EquipSelect", dequip)
        -- local dlistw = 288
        dlist:SetPos(0, dsearchheight + dsearchpadding)
        dlist:SetSize(dlistw, dlisth - dsearchheight - dsearchpadding)
        dlist:EnableVerticalScrollbar(true)
        dlist:EnableHorizontal(true)

        local bw, bh = 102, 25

        -- Whole right column
        local dih = h - bh - m * 5
        -- local diw = w - dlistw - m*6 - 2
        local dinfobg = vgui.Create("DPanel", dequip)
        dinfobg:SetPaintBackground(false)
        dinfobg:SetSize(diw - m, dih)
        dinfobg:SetPos(dlistw + m, 0)

        -- item info pane
        local dinfo = vgui.Create("ColoredBox", dinfobg)
        dinfo:SetColor(Color(90, 90, 95))
        dinfo:SetPos(0, 0)
        dinfo:StretchToParent(0, 0, m * 2, 105)

        local dfields = {}
        for _, k in pairs({ "name", "type", "desc" }) do
            dfields[k] = vgui.Create("DLabel", dinfo)
            dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
            dfields[k]:SetPos(m * 3, m * 2)
            dfields[k]:SetWidth(diw - m * 6)
        end

        dfields.name:SetFont("TabLarge")

        dfields.type:SetFont("DermaDefault")
        dfields.type:MoveBelow(dfields.name)

        dfields.desc:SetFont("DermaDefaultBold")
        dfields.desc:SetContentAlignment(7)
        dfields.desc:MoveBelow(dfields.type, 1)

        local dhelp = vgui.Create("DPanel", dinfobg)
        dhelp:SetPaintBackground(false)
        dhelp:SetSize(diw, 64)
        dhelp:MoveBelow(dinfo, m)

        local update_preqs = PreqLabels(dhelp, m * 7, m * 2)

        local function CannotBuyItem(item)
            local orderable = update_preqs(item)
            return ((not orderable) or
                    -- already owned
                    table.HasValue(owned_ids, item.id) or
                    (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
                    -- already carrying a weapon for this slot
                    (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
                    -- already bought the item before
                    (item.limited and ply:HasBought(tostring(item.id))))
        end

        local function FillEquipmentList(itemlist)
            dlist:Clear()

            -- temp table for sorting
            local paneltablefav = {}
            local paneltable = {}
            for i = 1, 9 do
                paneltablefav[i] = {}
                paneltable[i] = {}
            end

            for k, item in pairs(itemlist) do
                local ic = nil

                -- Create icon panel
                if item.material then
                    ic = vgui.Create("LayeredIcon", dlist)

                    if item.custom and showCustomVar:GetBool() then
                        -- Custom marker icon
                        local marker = vgui.Create("DImage")
                        marker:SetImage("vgui/ttt/custom_marker")
                        marker.PerformLayout = function(s)
                            s:AlignBottom(2)
                            s:AlignRight(2)
                            s:SetSize(16, 16)
                        end
                        marker:SetTooltip(GetTranslation("equip_custom"))

                        ic:AddLayer(marker)

                        ic:EnableMousePassthrough(marker)
                    end

                    -- Favorites marker icon
                    ic.favorite = false
                    local favorites = GetFavorites(ply:SteamID(), ply:GetRole())
                    if favorites then
                        if IsFavorite(favorites, item.id) then
                            ic.favorite = true
                            if showFavoriteVar:GetBool() then
                                local star = vgui.Create("DImage")
                                star:SetImage("icon16/star.png")
                                star.PerformLayout = function(s)
                                    s:AlignTop(2)
                                    s:AlignRight(2)
                                    s:SetSize(12, 12)
                                end
                                star:SetTooltip("Favorite")
                                ic:AddLayer(star)
                                ic:EnableMousePassthrough(star)
                            end
                        end
                    end

                    -- Slot marker icon
                    ic.slot = 1
                    if ItemIsWeapon(item) and showSlotVar:GetBool() then
                        local slot = vgui.Create("SimpleIconLabelled")
                        slot:SetIcon("vgui/ttt/slot_cap")
                        slot:SetIconColor(ROLE_COLORS[ply:GetRole()] or COLOR_GREY)
                        slot:SetIconSize(16)

                        slot:SetIconText(item.slot)
                        ic.slot = item.slot

                        -- Credit to @Angela and @Technofrood on the Lonely Yogs Discord for the fix!
                        -- Clamp the item slot within the correct limits
                        if ic.slot ~= nil then
                            ic.slot = math.Clamp(ic.slot, 1, #paneltable)
                        end

                        slot:SetIconProperties(COLOR_WHITE,
                            "DefaultBold",
                            { opacity = 220, offset = 1 },
                            { 9, 8 })

                        ic:AddLayer(slot)
                        ic:EnableMousePassthrough(slot)
                    end

                    ic:SetIconSize(itemSize)
                    ic:SetIcon(item.material)
                elseif item.model then
                    ic = vgui.Create("SpawnIcon", dlist)
                    ic:SetModel(item.model)
                else
                    ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
                end

                ic.item = item

                local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
                ic:SetTooltip(tip)

                -- If we cannot order this item, darken it
                if CannotBuyItem(item) then
                    ic:SetIconColor(color_darkened)
                end

                -- Don't show equipment items that you already own that are listed as "loadout" because you were given it for free
                if not ItemIsWeapon(item) and ply:HasEquipmentItem(item.id) and item.loadout then
                    ic:Remove()
                else
                    if ic.favorite then
                        paneltablefav[ic.slot or 1][k] = ic
                    else
                        paneltable[ic.slot or 1][k] = ic
                    end
                end
            end

            -- add favorites first
            for i = 1, 9 do
                for _, panel in pairs(paneltablefav[i]) do
                    dlist:AddPanel(panel)
                end
            end

            -- non favorites second
            -- Randomize positions if this is enabled
            if GetGlobalBool("ttt_shop_random_position", false) then
                -- Gather all the panels into one list
                local panels = {}
                for i = 1, 9 do
                    for _, p in pairs(paneltable[i]) do
                        table.insert(panels, p)
                    end
                end

                -- Randomize it
                panels = table.Shuffle(panels)

                -- Add them all to the list
                for _, p in ipairs(panels) do
                    dlist:AddPanel(p)
                end
            else
                for i = 1, 9 do
                    for _, panel in pairs(paneltable[i]) do
                        dlist:AddPanel(panel)
                    end
                end
            end

            -- select first
            dlist:SelectPanel(dlist:GetItems()[1])
        end
        dsearch.OnValueChange = function(box, value)
            local roleitems = GetEquipmentForRole(ply:GetRole(), ply:GetNWBool("HasPromotion", false), false)
            local filtered = {}
            for _, v in pairs(roleitems) do
                if v and v["name"] and string.find(SafeTranslate(v["name"]):lower(), value:lower()) then
                    table.insert(filtered, v)
                end
            end
            FillEquipmentList(filtered)
        end

        dhelp:SizeToContents()

        local dconfirm = vgui.Create("DButton", dinfobg)
        dconfirm:SetPos(0, dih - bh * 2)
        dconfirm:SetSize(bw, bh)
        dconfirm:SetDisabled(true)
        dconfirm:SetText(GetTranslation("equip_confirm"))

        dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, GetTranslation("equip_tooltip_main"))

        -- couple panelselect with info
        dlist.OnActivePanelChanged = function(self, _, new)
            can_order = false
            if new and new.item then
                for k, v in pairs(new.item) do
                    if dfields[k] then
                        local value = v
                        if type(v) == "function" then
                            value = v()
                        end
                        dfields[k]:SetText(SafeTranslate(value))
                        dfields[k]:SetAutoStretchVertical(true)
                        dfields[k]:SetWrap(true)
                    end
                end

                -- Trying to force everything to update to
                -- the right size is a giant pain, so just
                -- force a good size.
                dfields.desc:SetTall(70)

                can_order = update_preqs(new.item)
            else
                for _, v in pairs(dfields) do
                    if v then
                        v:SetText("---")
                        v:SetAutoStretchVertical(true)
                        v:SetWrap(true)
                    end
                end
            end

            dconfirm:SetDisabled(not can_order)
        end

        -- prep confirm action
        dconfirm.DoClick = function()
            local pnl = dlist.SelectedPanel
            if not pnl or not pnl.item then return end
            local choice = pnl.item
            RunConsoleCommand("ttt_order_equipment", choice.id)
            dframe:Close()
        end

        -- update some basic info, may have changed in another tab
        -- specifically the number of credits in the preq list
        dsheet.OnTabChanged = function(s, old, new)
            if not IsValid(new) then return end

            if new:GetPanel() == dequip then
                can_order = update_preqs(dlist.SelectedPanel.item)
                dconfirm:SetDisabled(not can_order)
            end
        end

        local dcancel = vgui.Create("DButton", dframe)
        dcancel:SetPos(w - 17 - bw, h - bh - 17)
        dcancel:SetSize(bw, bh)
        dcancel:SetDisabled(false)
        dcancel:SetText(GetTranslation("close"))
        dcancel.DoClick = function() dframe:Close() end

        --add as favorite button
        local dfav = vgui.Create("DButton", dinfobg)
        dfav:SetPos(0, dih - bh * 2)
        dfav:MoveRightOf(dconfirm)
        dfav:SetSize(bh, bh)
        dfav:SetDisabled(false)
        dfav:SetText("")
        dfav:SetImage("icon16/star.png")
        dfav:SetTooltip(GetTranslation("buy_favorite_toggle"))
        dfav.DoClick = function()
            local local_ply = LocalPlayer()
            local role = local_ply:GetRole()
            local guid = local_ply:SteamID()
            local pnl = dlist.SelectedPanel
            if not pnl or not pnl.item then return end
            local choice = pnl.item
            local weapon = choice.id
            CreateFavTable()
            if pnl.favorite then
                RemoveFavorite(guid, role, weapon)
            else
                AddFavorite(guid, role, weapon)
            end
        end

        local drdm = vgui.Create("DButton", dinfobg)
        drdm:MoveRightOf(dfav)
        local bx, _ = drdm:GetPos()
        drdm:SetPos(bx + 1, dih - bh * 2)
        drdm:SetSize(bh, bh)
        drdm:SetDisabled(false)
        drdm:SetText("")
        drdm:SetImage("icon16/basket_go.png")
        drdm:SetTooltip(GetTranslation("buy_random"))
        drdm.DoClick = function()
            local item_panels = dlist:GetItems()
            local buyable_items = {}
            for _, item_panel in pairs(item_panels) do
                if item_panel.item and not CannotBuyItem(item_panel.item) then
                    table.insert(buyable_items, item_panel)
                end
            end

            if #buyable_items == 0 then return end

            dlist:SelectPanel(buyable_items[math.random(1, #buyable_items)])
            dconfirm.DoClick()
        end

        FillEquipmentList(GetEquipmentForRole(ply:GetRole(), ply:GetNWBool("HasPromotion", false), false))
        show = true
    end

    -- Item control
    if ply:HasEquipmentItem(EQUIP_RADAR) then
        local dradar = RADAR.CreateMenu(dsheet, dframe)
        dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false, false, GetTranslation("equip_tooltip_radar"))
        show = true
    end

    if ply:HasEquipmentItem(EQUIP_DISGUISE) then
        local ddisguise = DISGUISE.CreateMenu(dsheet)
        dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false, false, GetTranslation("equip_tooltip_disguise"))
        show = true
    end

    -- Weapon/item control
    if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
        local dradio = TRADIO.CreateMenu(dsheet)
        dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false, false, GetTranslation("equip_tooltip_radio"))
        show = true
    end

    -- Credit transferring, but only for roles that have a shop and are allowed to transfer
    if credits > 0 and hasShop and not (ply:IsMercenary() or ply:IsKiller() or ply:IsJesterTeam()) then
        local dtransfer = CreateTransferMenu(dsheet)
        dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false, false, GetTranslation("equip_tooltip_xfer"))
        show = true
    end

    hook.Run("TTTEquipmentTabs", dsheet)

    dframe:MakePopup()
    dframe:SetKeyboardInputEnabled(false)

    eqframe = dframe

    if not show then
        ForceCloseTraitorMenu()
    end
end
concommand.Add("ttt_cl_traitorpopup", TraitorMenuPopup)

function GM:OnContextMenuOpen()
    if GetRoundState() ~= ROUND_ACTIVE then
        CLSCORE:Toggle()
        return
    end
    if eqframe and IsValid(eqframe) then
        ForceCloseTraitorMenu()
    else
        TraitorMenuPopup()
    end
end

local function ReceiveEquipment()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    ply.equipment_items = net.ReadUInt(32)
end
net.Receive("TTT_Equipment", ReceiveEquipment)

local function ReceiveCredits()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    ply.equipment_credits = net.ReadUInt(8)
end
net.Receive("TTT_Credits", ReceiveCredits)

local r = 0
local function ReceiveBought()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    ply.bought = {}
    local num = net.ReadUInt(8)
    for _ = 1, num do
        local s = net.ReadString()
        if s ~= "" then
            table.insert(ply.bought, s)
        end
    end

    -- This usermessage sometimes fails to contain the last weapon that was
    -- bought, even though resending then works perfectly. Possibly a bug in
    -- bf_read. Anyway, this hack is a workaround: we just request a new umsg.
    if num ~= #ply.bought and r < 10 then
        -- r is an infinite loop guard
        RunConsoleCommand("ttt_resend_bought")
        r = r + 1
    else
        r = 0
    end
end
net.Receive("TTT_Bought", ReceiveBought)

-- Player received the item he has just bought, so run clientside init
local function ReceiveBoughtItem()
    local is_item = net.ReadBit() == 1
    local id
    if is_item then
        local _, bits_left = net.BytesLeft()

        -- If we don't have enough bits for the full amount, only read 16
        local bits = 32
        if bits_left < bits then
            bits = 16
        end

        id = net.ReadUInt(bits)
    else
        id = net.ReadString()
    end

    -- I can imagine custom equipment wanting this, so making a hook
    hook.Run("TTTBoughtItem", is_item, id)
end
net.Receive("TTT_BoughtItem", ReceiveBoughtItem)
