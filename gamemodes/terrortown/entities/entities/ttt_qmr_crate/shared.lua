AddCSLuaFile()
ENT.Type = "anim"

function ENT:Initialize()
    self:SetModel("models/items/item_item_crate.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetModelScale(1)
    self:SetHealth(250)
    if SERVER then
        self:PrecacheGibs()
    end
    self.nextUse = CurTime()

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    if CLIENT then
        local GetPTranslation = LANG.GetParamTranslation
        LANG.AddToLanguage("english", "qmr_crate_name", "Weapons Crate")
        LANG.AddToLanguage("english", "qmr_crate_hint", "Press '{usekey}' to receive item")
        self.TargetIDHint = function()
            return {
                name = "qmr_crate_name",
                hint = "qmr_crate_hint",
                fmt  = function(ent, txt)
                    return GetPTranslation(txt, { usekey = Key("+use", "USE") } )
                end
            };
        end
    end
end

function ENT:OnRemove()
end

function ENT:Think()
end

function ENT:Break()
end

function ENT:OnTakeDamage(dmgInfo)
    self:SetHealth(self:Health() - dmgInfo:GetDamage())
    if self:Health() <= 0 then
        self:GibBreakServer(Vector(1, 1, 1))
        self:Remove()
    end
    return true
end

if SERVER then
    util.AddNetworkString("TTT_QuartermasterCrateNotify")

    local function CallShopHooks(isequip, id, ply)
        hook.Call("TTTOrderedEquipment", GAMEMODE, ply, id, isequip, true)
        ply:AddBought(id)

        net.Start("TTT_BoughtItem")
        -- Not a boolean so we can't write it directly
        if isequip then
            net.WriteBit(true)
        else
            net.WriteBit(false)
        end
        if isequip then
            local bits = 16
            -- Only use 32 bits if the number of equipment items we have requires it
            if EQUIP_MAX >= 2^bits then
                bits = 32
            end

            net.WriteUInt(id, bits)
        else
            net.WriteString(id)
        end
        net.Send(ply)
    end

    local function NotifyPlayer(ply, item, has, can_carry)
        net.Start("TTT_QuartermasterCrateNotify")
        net.WriteString(tostring(item))
        net.WriteBool(has)
        net.WriteBool(can_carry)
        net.Send(ply)
    end

    function ENT:Use(activator)
        if CurTime() > self.nextUse then
            if not IsValid(activator) or not activator:Alive() or activator:IsSpec() then return end
            self.nextUse = CurTime() + 0.5

            if activator:IsQuartermaster() then
                activator:QueueMessage(MSG_PRINTBOTH, ROLE_STRINGS_PLURAL[ROLE_QUARTERMASTER] .. " cannot loot weapons crates!")
                return
            end

            -- Only let them use one crate, if that's enabled
            if GetConVar("ttt_quartermaster_limited_loot"):GetBool() and activator:GetNWBool("TTTQuartermasterLooted", false) then
                activator:QueueMessage(MSG_PRINTBOTH, "You've already looted a weapons crate from " .. ROLE_STRINGS_EXT[ROLE_QUARTERMASTER] .. " this round!")
                return
            end

            local item_id = self.item_id

            local equip_id = tonumber(item_id)
            if equip_id then
                local has = activator:HasEquipmentItem(equip_id)
                NotifyPlayer(activator, equip_id, has, true)
                if has then
                    return
                else
                    activator:SetNWBool("TTTQuartermasterLooted", true)
                    activator:GiveEquipmentItem(equip_id)
                    CallShopHooks(equip_id, equip_id, activator)
                end
            else
                local has = activator:HasWeapon(item_id)
                local can_carry = activator:CanCarryWeapon(weapons.GetStored(item_id))
                NotifyPlayer(activator, item_id, has, can_carry)
                if has or not can_carry then
                    return
                else
                    activator:SetNWBool("TTTQuartermasterLooted", true)
                    activator:Give(item_id)
                    CallShopHooks(nil, item_id, activator)
                end
            end

            hook.Call("TTTQuartermasterCrateOpened", nil, self.source_ply, activator, item_id)
            self:Remove()
        end
    end
end

if CLIENT then
    local function GetItemName(item)
        local id = tonumber(item)
        local info = GetEquipmentItemById(id)
        return info and LANG.TryTranslation(info.name) or item
    end

    local function GetWeaponName(item)
        for _, v in ipairs(weapons.GetList()) do
            if item == WEPS.GetClass(v) then
                return LANG.TryTranslation(v.PrintName)
            end
        end

        return item
    end

    net.Receive("TTT_QuartermasterCrateNotify", function()
        local client = LocalPlayer()
        if not IsPlayer(client) then return end

        local item = net.ReadString()
        local has = net.ReadBool()
        local can_carry = net.ReadBool()
        local name
        if tonumber(item) then
            name = GetItemName(item)
        else
            name = GetWeaponName(item)
        end

        if has then
            client:PrintMessage(HUD_PRINTTALK, "You already have '" .. name .. "'!")
        elseif not can_carry then
            client:PrintMessage(HUD_PRINTTALK, "You are already holding an item that shares a slot with '" .. name .. "'!")
        else
            client:PrintMessage(HUD_PRINTTALK, "You got '" .. name .. "' from " .. ROLE_STRINGS_EXT[ROLE_QUARTERMASTER] .. "!")
        end
    end)
end