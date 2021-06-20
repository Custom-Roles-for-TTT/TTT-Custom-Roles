include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
end

function ENT:Draw()
    self.BaseClass.Draw(self)
end

function ENT:DrawTranslucent()
    self.BaseClass.DrawTranslucent(self)
end

function ENT:Think()
end