include("shared.lua")

local concommand = concommand
local hook = hook
local ipairs = ipairs
local math = math
local net = net
local pairs = pairs
local surface = surface
local table = table
local vgui = vgui
local weapons = weapons

---- Traitor equipment menu

local CallHook = hook.Call
local RunHook = hook.Run
local GetWeapon = weapons.GetStored
local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation
local StringFind = string.find
local StringLower = string.lower
local TableHasValue = table.HasValue
local TableInsert = table.insert
local TableSort = table.sort
local TableCopy = table.Copy

-- BEM client convars and config menu
local numColsVar = CreateClientConVar("ttt_bem_cols", 4, true, false, "Sets the number of columns in the Traitor/Detective menu's item list.")
local numRowsVar = CreateClientConVar("ttt_bem_rows", 5, true, false, "Sets the number of rows in the Traitor/Detective menu's item list.")
local itemSizeVar = CreateClientConVar("ttt_bem_size", 64, true, false, "Sets the item size in the Traitor/Detective menu's item list.")
local showCustomVar = CreateClientConVar("ttt_bem_marker_custom", 1, true, false, "Should custom items get a marker?")
local showFavoriteVar = CreateClientConVar("ttt_bem_marker_fav", 1, true, false, "Should favorite items get a marker?")
local showSlotVar = CreateClientConVar("ttt_bem_marker_slot", 1, true, false, "Should items get a slot-marker?")
local showLoadoutEquipment = CreateClientConVar("ttt_show_loadout_equipment", 0, true, false, "Should loadout equipment show in shops?")
local sortAlphabetically = CreateClientConVar("ttt_sort_alphabetically", 1, true, false, "Should the shop sort alphabetically?")
local sortBySlotFirst = CreateClientConVar("ttt_sort_by_slot_first", 0, true, false, "Should the shop sort by slot first?")

hook.Add("Initialize", "EquipmentMenu_Initialize", function()
    LANG.AddToLanguage("english", "set_title_equipment", "Equipment/Shop settings")
    LANG.AddToLanguage("english", "set_label_equipment", "All changes made here are clientside and will only apply to your own menu!")
    LANG.AddToLanguage("english", "set_equipment_convar_slot", "Show slot marker")
    LANG.AddToLanguage("english", "set_equipment_convar_custom", "Show custom item marker")
    LANG.AddToLanguage("english", "set_equipment_convar_fav", "Show favourite item marker")
    LANG.AddToLanguage("english", "set_equipment_convar_loadout", "Show loadout items")
    LANG.AddToLanguage("english", "set_equipment_convar_alpha", "Sort alphabetically")
    LANG.AddToLanguage("english", "set_equipment_convar_sort_by_slot", "Sort by slot first")
end)

hook.Add("TTTSettingsConfigTabSections", "EquipmentMenu_TTTSettingsConfigTabSections", function(dsettings)
    local dbemsettings = vgui.Create("DForm", dsettings)
    dbemsettings:Dock(TOP)
    dbemsettings:DockMargin(0, 0, 5, 10)
    dbemsettings:DoExpansion(false)
    dbemsettings:SetName(GetTranslation("set_title_equipment"))

    local dlabel = vgui.Create("DLabel", dbemsettings)
    dlabel:SetText(GetTranslation("set_label_equipment"))
    dlabel:SetTextColor(Color(0, 0, 0, 255))
    dbemsettings:AddItem(dlabel)

    dbemsettings:NumSlider("Number of columns (def. 4)", "ttt_bem_cols", 1, 20, 0)
    dbemsettings:NumSlider("Number of rows (def. 5)", "ttt_bem_rows", 1, 20, 0)
    dbemsettings:NumSlider("Icon size (def. 64)", "ttt_bem_size", 32, 128, 0)

    dbemsettings:CheckBox(GetTranslation("set_equipment_convar_slot"), "ttt_bem_marker_slot")
    dbemsettings:CheckBox(GetTranslation("set_equipment_convar_custom"), "ttt_bem_marker_custom")
    dbemsettings:CheckBox(GetTranslation("set_equipment_convar_fav"), "ttt_bem_marker_fav")
    dbemsettings:CheckBox(GetTranslation("set_equipment_convar_loadout"), "ttt_show_loadout_equipment")
    dbemsettings:CheckBox(GetTranslation("set_equipment_convar_alpha"), "ttt_sort_alphabetically")
    dbemsettings:CheckBox(GetTranslation("set_equipment_convar_sort_by_slot"), "ttt_sort_by_slot_first")

    CallHook("TTTSettingsConfigTabFields", nil, "BEM", dbemsettings)

    dsettings:AddItem(dbemsettings)
end)

-- Buyable weapons are loaded automatically. Buyable items are defined in
-- equip_items_shd.lua

local Equipment = { }

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
    WEPS.BuyableWeapons[role] = net.ReadTable(true)
    WEPS.ExcludeWeapons[role] = net.ReadTable(true)
    WEPS.BypassRandomWeapons[role] = net.ReadTable(true)
    WEPS.LoadoutWeapons[role] = net.ReadTable(true)
    ResetWeaponsCache()
end)

net.Receive("TTT_RolePackBuyableWeapons", function()
    local role = net.ReadInt(16)
    WEPS.RolePackBuyableWeapons[role] = net.ReadTable(true)
    WEPS.RolePackExcludeWeapons[role] = net.ReadTable(true)
    WEPS.RolePackBypassRandomWeapons[role] = net.ReadTable(true)
    WEPS.RolePackLoadoutWeapons[role] = net.ReadTable(true)
    ResetWeaponsCache()
end)

net.Receive("TTT_RoleWeaponsLoaded", function()
    CallHook("TTTRoleWeaponsLoaded")
end)

net.Receive("TTT_UpdateBuyableWeapons", function()
    local id = net.ReadString()
    local role = net.ReadInt(8)
    local includeSelected = net.ReadBool()
    local excludeSelected = net.ReadBool()
    local noRandomSelected = net.ReadBool()
    local loadoutSelected = net.ReadBool()

    -- Update tables and reset cache
    WEPS.UpdateWeaponLists(role, id, includeSelected, excludeSelected, noRandomSelected, loadoutSelected)
    ResetWeaponsCache()
    UpdateRoleWeaponState()
end)

local function ItemIsWeapon(item) return not tonumber(item.id) end

function GetEquipmentForRole(role, promoted, block_randomization, block_exclusion, ignore_cache, rolepack_weps)
    local packName = GetConVar("ttt_role_pack"):GetString()
    if rolepack_weps == nil and #packName > 0 then
        rolepack_weps = {Buyables = WEPS.RolePackBuyableWeapons[role], Excludes = WEPS.RolePackExcludeWeapons[role], NoRandoms = WEPS.RolePackBypassRandomWeapons[role]}
    elseif rolepack_weps == false or #packName == 0 then
        rolepack_weps = {Buyables = {}, Excludes = {}, NoRandoms = {}}
    end

    WEPS.PrepWeaponsLists(role)

    -- Determine which role sync variable to use, if any
    local rolemode = cvars.Number("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_mode", SHOP_SYNC_MODE_NONE)
    local traitorsync = TRAITOR_ROLES[role] and cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_sync", false)
    local sync_traitor_weapons = traitorsync or (rolemode > SHOP_SYNC_MODE_NONE)

    -- Pre-load the Traitor weapons so that any that have their CanBuy modified will also apply to the enabled allied role(s)
    if sync_traitor_weapons and not Equipment[ROLE_TRAITOR] then
        GetEquipmentForRole(ROLE_TRAITOR, false, true, block_exclusion, ignore_cache)
    end

    local detectivesync = DETECTIVE_ROLES[role] and cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[role] .. "_shop_sync", false)
    local sync_detective_weapons = detectivesync or promoted or (rolemode > SHOP_SYNC_MODE_NONE)

    -- Pre-load the Detective weapons so that any that have their CanBuy modified will also apply to the enabled allied role(s)
    if sync_detective_weapons and not Equipment[ROLE_DETECTIVE] then
        GetEquipmentForRole(ROLE_DETECTIVE, false, true, block_exclusion, ignore_cache)
    end

    -- Pre-load all role weapons for all the sync roles (if there are any)
    local sync_roles = ROLE_SHOP_SYNC_ROLES[role]
    if sync_roles and #sync_roles > 0 then
        for _, r in pairs(sync_roles) do
            if not Equipment[r] then
                GetEquipmentForRole(r, false, true, block_exclusion, ignore_cache, rolepack_weps)
            end
        end
    end

    -- Cache the equipment unless the role's shop can change mid round
    if ignore_cache or not Equipment[role] then
        -- start with all the non-weapon goodies
        local tbl = table.Copy(EquipmentItems)

        -- find buyable weapons to load info from
        for _, v in pairs(weapons.GetList()) do
            WEPS.HandleCanBuyOverrides(v, role, block_randomization, sync_traitor_weapons, sync_detective_weapons, block_exclusion, sync_roles, rolepack_weps)
            if v and v.CanBuy then
                local data = v.EquipMenuData or {}
                local base = {
                    id = WEPS.GetClass(v),
                    name = v.ShopName or v.PrintName or "Unnamed",
                    limited = v.LimitedStock,
                    kind = v.Kind or WEAPON_NONE,
                    slot = (v.Slot or 0) + 1,
                    material = v.Icon or "vgui/ttt/icon_id",
                    req = v.RequiredItems or {},
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
                    -- Skip invalid entries
                    if type(r) ~= "number" then continue end
                    if not tbl[r] then continue end

                    TableInsert(tbl[r], base)
                end
            end
        end

        local traitor_equipment = {}
        local traitor_equipment_ids = {}
        local detective_equipment = {}
        local detective_equipment_ids = {}
        local sync_equipment = {}
        local available = {}
        for r, is in pairs(tbl) do
            for _, i in pairs(is) do
                if i then
                    -- Mark custom items
                    i.custom = not TableHasValue(DefaultEquipment[r], i.id)

                    -- Save the equipment to be synced below
                    if not ItemIsWeapon(i) then
                        -- Track the items already available to this role to avoid duplicates
                        if r == role then
                            available[i.id] = true
                        end

                        if r == ROLE_TRAITOR then
                            TableInsert(traitor_equipment, i)
                            TableInsert(traitor_equipment_ids, i.id)
                        elseif r == ROLE_DETECTIVE then
                            TableInsert(detective_equipment, i)
                            TableInsert(detective_equipment_ids, i.id)
                        end

                        -- If we have sync roles and this role is one of them, save the item info for later
                        if sync_roles and table.HasValue(sync_roles, r) then
                            TableInsert(sync_equipment, i)
                        end
                    end
                end
            end
        end

        -- Sync the equipment from above
        if rolemode == SHOP_SYNC_MODE_INTERSECT then
            for idx, i in pairs(traitor_equipment_ids) do
                -- Traitor AND Detective mode, (Detective && Traitor) -> Sync Role
                if not available[i] and TableHasValue(detective_equipment_ids, i) then
                    TableInsert(tbl[role], traitor_equipment[idx])
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
                    TableInsert(tbl[role], i)
                    available[i.id] = true
                end
            end
            for _, i in pairs(detective_equipment) do
                -- Avoid duplicates
                if not available[i.id] and
                    -- Detective -> Detective-like, Detective -> Special Detective
                    (promoted or sync_detective_weapons or
                    -- Traitor OR Detective or Detective-only modes, Detective -> Sync Role
                    (rolemode == SHOP_SYNC_MODE_UNION or rolemode == SHOP_SYNC_MODE_DETECTIVE)) then
                    TableInsert(tbl[role], i)
                    available[i.id] = true
                end
            end
        end

        -- Add all the equipment from the sync roles
        for _, i in pairs(sync_equipment) do
            -- Avoid duplicates
            if not available[i.id] then
                TableInsert(tbl[role], i)
                available[i.id] = true
            end
        end

        -- Also check the extra buyable equipment
        local mergedBuyableWeapons = TableCopy(WEPS.BuyableWeapons[role])
        for _, v in pairs(rolepack_weps.Buyables) do
            if not TableHasValue(mergedBuyableWeapons, v) then
                TableInsert(mergedBuyableWeapons, v)
            end
        end
        for _, v in ipairs(mergedBuyableWeapons) do
            -- If this isn't a weapon, get its information from one of the roles and compare that to the ID we have
            if not weapons.GetStored(v) then
                local equip = GetEquipmentItemByName(v)
                -- If this exists and isn't already in the list, add it to the role's list
                if equip ~= nil and not available[equip.id] then
                    TableInsert(tbl[role], equip)
                    available[equip.id] = true
                end
            end
        end

        -- Lastly, go through the excludes to make sure things are removed that should be, if it's not blocked
        if not block_exclusion then
            local mergedExcludeWeapons = TableCopy(WEPS.ExcludeWeapons[role])
            for _, v in pairs(rolepack_weps.Excludes) do
                if not TableHasValue(mergedExcludeWeapons, v) then
                    TableInsert(mergedExcludeWeapons, v)
                end
            end
            for _, v in ipairs(mergedExcludeWeapons) do
                -- If this is enabled via role pack but but disabled via role weapons, the role pack should take priority
                if TableHasValue(rolepack_weps.Buyables, v) then continue end

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
        end

        -- If we're ignoring the cache, don't even save the results to the cache
        if ignore_cache then
            return tbl[role]
        else
            Equipment[role] = tbl[role]
        end
    end

    return Equipment and Equipment[role] or {}
end

local function CanCarryWeapon(item)
    local client = LocalPlayer()
    -- Don't allow delayed shop roles to buy any weapon that has a kind matching one of the weapons they've already bought
    if item.kind and client.bought and client:ShouldDelayShopPurchase() then
        for _, id in ipairs(client.bought) do
            local wep = GetWeapon(id)
            if wep and wep.Kind == item.kind then
                return false
            end
        end
    end

    return client:CanCarryType(item.kind)
end

local function HasEquipmentItem(item)
    local client = LocalPlayer()
    -- Don't allow the delayed shop roles to buy the same equipment item twice if delayed acceptance is enabled
    if client.bought and client:ShouldDelayShopPurchase() then
        return TableHasValue(client.bought, tostring(item.id))
    end

    return client:HasEquipmentItem(item.id)
end

local color_bad = Color(220, 60, 60, 255)
local color_good = Color(255, 255, 255, 255)

-- Creates tabel of labels showing the status of ordering prerequisites
local function PreqLabels(parent, x, y)
    local tbl = {}

    -- coins icon
    tbl.credits = vgui.Create("DPanel", parent)
    tbl.credits:SetPaintBackground(false)
    tbl.credits:SetHeight(32)
    tbl.credits:SetPos(x - 32 - 2, y)

    tbl.credits.img = vgui.Create("DImage", parent)
    tbl.credits.img:SetSize(32, 32)
    tbl.credits.img:CopyPos(tbl.credits)
    tbl.credits.img:SetImage("vgui/ttt/equip/coin.png")

    tbl.credits.lbl = vgui.Create("DLabel", parent)
    tbl.credits.lbl:CopyPos(tbl.credits)
    tbl.credits.lbl:MoveRightOf(tbl.credits.img)

    tbl.credits.Check = function(s, sel)
        local credits = LocalPlayer():GetCredits()
        return credits > 0, " " .. credits, GetPTranslation("equip_cost", { num = credits })
    end

    -- carry icon
    tbl.owned = vgui.Create("DPanel", parent)
    tbl.owned:SetPaintBackground(false)
    tbl.owned:SetHeight(32)
    tbl.owned:CopyPos(tbl.credits)
    tbl.owned:MoveRightOf(tbl.credits, y * 3)

    tbl.owned.img = vgui.Create("DImage", parent)
    tbl.owned.img:SetSize(32, 32)
    tbl.owned.img:CopyPos(tbl.owned)
    tbl.owned.img:SetImage("vgui/ttt/equip/briefcase.png")

    tbl.owned.lbl = vgui.Create("DLabel", parent)
    tbl.owned.lbl:CopyPos(tbl.owned)
    tbl.owned.lbl:MoveRightOf(tbl.owned.img)

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
    tbl.bought = vgui.Create("DPanel", parent)
    tbl.bought:SetPaintBackground(false)
    tbl.bought:SetHeight(32)
    tbl.bought:CopyPos(tbl.owned)
    tbl.bought:MoveRightOf(tbl.owned, y * 3)

    tbl.bought.img = vgui.Create("DImage", parent)
    tbl.bought.img:SetSize(32, 32)
    tbl.bought.img:CopyPos(tbl.bought)
    tbl.bought.img:SetImage("vgui/ttt/equip/package.png")

    tbl.bought.lbl = vgui.Create("DLabel", parent)
    tbl.bought.lbl:CopyPos(tbl.bought)
    tbl.bought.lbl:MoveRightOf(tbl.bought.img)

    tbl.bought.Check = function(s, sel)
        if sel.limited and LocalPlayer():HasBought(tostring(sel.id)) then
            return false, "X", GetTranslation("equip_stock_deny")
        elseif sel.req and not WEPS.PlayerOwnsWepReqs(LocalPlayer(), sel) then
            return false, "X", GetTranslation("equip_stock_req_deny")
        else
            return true, "✔", GetTranslation("equip_stock_ok")
        end
    end

    for k, pnl in pairs(tbl) do
        pnl.lbl:SetFont("DermaLarge")
    end

    return function(selected)
        local allow = true
        for _, pnl in pairs(tbl) do
            local result, text, tooltip = pnl:Check(selected)
            pnl.lbl:SetTextColor(result and color_good or color_bad)
            pnl.lbl:SetText(text)
            pnl.lbl:SizeToContents()

            pnl.img:SetImageColor(result and color_good or color_bad)

            pnl:SetTooltip(tooltip)

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
local function ForceCloseTraitorMenu()
    if IsValid(eqframe) then
        eqframe:Close()
        eqframe = nil
        return true
    end
    return false
end
concommand.Add("ttt_cl_traitorpopup_close", ForceCloseTraitorMenu)

hook.Add("OnPauseMenuShow", "EquipMenu_OnPauseMenuShow", function()
    -- If we needed to close the traitor menu, don't open the pause menu too
    if ForceCloseTraitorMenu() then
        return false
    end
end)

local function DoesValueMatch(item, data, value)
    if not item[data] then return false end

    local itemdata = item[data]
    if isfunction(itemdata) then
        itemdata = itemdata()
    end
    return itemdata and StringFind(StringLower(SafeTranslate(itemdata)), StringLower(value), 1, true)
end

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
    local dlisth = ((itemSize + 2) * numRows) - 2 + 45
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
    if IsValid(eqframe) then
        eqframe:Close()
        eqframe = nil
    end

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
                TableInsert(owned_ids, wep:GetClass())
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
        dlist:EnableVerticalScrollbar()
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
            return (not orderable) or
                    -- already owned
                    TableHasValue(owned_ids, item.id) or
                    (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
                    -- already carrying a weapon for this slot
                    (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
                    -- already bought the item before
                    (item.limited and ply:HasBought(tostring(item.id))) or
                    -- doesn't have the required items
                    not WEPS.PlayerOwnsWepReqs(ply, item)
        end

        local function FillEquipmentList(itemlist)
            dlist:Clear()

            -- temp table for sorting
            local paneltablefav = {}
            local paneltable = {}
            for i = 0, 9 do
                paneltablefav[i] = {}
                paneltable[i] = {}
            end

            for _, item in pairs(itemlist) do
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
                    ic.slot = 0
                    if ItemIsWeapon(item) then
                        if showSlotVar:GetBool() then
                            local slot = vgui.Create("SimpleIconLabelled")
                            slot:SetIcon("vgui/ttt/slot_cap")
                            slot:SetIconColor(ROLE_COLORS[ply:GetDisplayedRole()] or COLOR_GREY)
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
                        else
                            ic.slot = 1 -- Separate equipment items from weapons
                        end
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
                local externalLoadout = ROLE_LOADOUT_ITEMS[ply:GetRole()] and TableHasValue(ROLE_LOADOUT_ITEMS[ply:GetRole()], item.name)
                if not ItemIsWeapon(item) and ply:HasEquipmentItem(item.id) and (item.loadout or externalLoadout) and not showLoadoutEquipment:GetBool() then
                    ic:Remove()
                else
                    if ic.favorite then
                        TableInsert(paneltablefav[ic.slot or 1], ic)
                    else
                        TableInsert(paneltable[ic.slot or 1], ic)
                    end
                end
            end

            local AddNameSortedItems = function(panels)
                if sortAlphabetically:GetBool() then
                    TableSort(panels, function(a, b) return StringLower(a.item.name) < StringLower(b.item.name) end)
                end
                for _, panel in pairs(panels) do
                    dlist:AddPanel(panel)
                end
            end

            -- add favorites first
            -- Add equipment items separately
            AddNameSortedItems(paneltablefav[0])

            if sortBySlotFirst:GetBool() then
                for i = 1, 9 do
                    AddNameSortedItems(paneltablefav[i])
                end
            else
                -- Gather all the panels into one list
                local panels = {}
                for i = 1, 9 do
                    for _, p in pairs(paneltablefav[i]) do
                        TableInsert(panels, p)
                    end
                end

                AddNameSortedItems(panels)
            end

            -- non favorites second
            -- Randomize positions if this is enabled
            if GetConVar("ttt_shop_random_position"):GetBool() then
                -- Gather all the panels into one list
                local panels = {}
                for i = 0, 9 do
                    for _, p in pairs(paneltable[i]) do
                        TableInsert(panels, p)
                    end
                end

                -- Randomize it
                panels = table.Shuffle(panels)

                -- Add them all to the list
                for _, p in ipairs(panels) do
                    dlist:AddPanel(p)
                end
            else
                -- Add equipment items separately
                AddNameSortedItems(paneltable[0])

                if sortBySlotFirst:GetBool() then
                    for i = 1, 9 do
                        AddNameSortedItems(paneltable[i])
                    end
                else
                    -- Gather all the panels into one list
                    local panels = {}
                    for i = 1, 9 do
                        for _, p in pairs(paneltable[i]) do
                            TableInsert(panels, p)
                        end
                    end

                    AddNameSortedItems(panels)
                end
            end

            -- select first
            dlist:SelectPanel(dlist:GetItems()[1])
        end
        dsearch.OnValueChange = function(box, value)
            local roleitems = GetEquipmentForRole(ply:GetRole(), ply:IsDetectiveLike() and not ply:IsDetectiveTeam(), false)
            local filtered = {}
            for _, v in pairs(roleitems) do
                if v and (DoesValueMatch(v, "name", value) or DoesValueMatch(v, "desc", value)) then
                    TableInsert(filtered, v)
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

            local pnl = dlist.SelectedPanel
            if not pnl or not pnl.item then return end

            if new:GetPanel() == dequip then
                can_order = update_preqs(pnl.item)
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

            dsearch:OnTextChanged()
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
                    TableInsert(buyable_items, item_panel)
                end
            end

            if #buyable_items == 0 then return end

            local random_panel = buyable_items[math.random(1, #buyable_items)]
            dlist:SelectPanel(random_panel)
            dconfirm.DoClick()
            CallHook("TTTShopRandomBought", nil, LocalPlayer(), random_panel.item)
        end

        FillEquipmentList(GetEquipmentForRole(ply:GetRole(), ply:IsDetectiveLike() and not ply:IsDetectiveTeam(), false))
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
    local canSend = credits > 0 and hasShop and (ply:IsTraitorTeam() or ply:IsMonsterTeam())
    local newCanSend = CallHook("TTTPlayerCanSendCredits", nil, ply, credits, hasShop, canSend)
    if type(newCanSend) == "boolean" then canSend = newCanSend end
    if canSend then
        local dtransfer = CreateTransferMenu(dsheet)
        dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false, false, GetTranslation("equip_tooltip_xfer"))
        show = true
    end

    local new_show = RunHook("TTTEquipmentTabs", dsheet, dframe)
    if new_show then show = new_show end

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
    if IsValid(eqframe) then
        ForceCloseTraitorMenu()
    else
        TraitorMenuPopup()
    end
end

local function ReceiveEquipment()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    ply.equipment_items = {}
    local count = net.ReadUInt(8)
    for i=1,count do
        TableInsert(ply.equipment_items, net.ReadUInt(8))
    end
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
        if #s > 0 then
            TableInsert(ply.bought, s)
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

-- Player received the item they have just bought, so run clientside init
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
    RunHook("TTTBoughtItem", is_item, id)
end
net.Receive("TTT_BoughtItem", ReceiveBoughtItem)
