include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Initialize()
end

function ENT:Draw(flags)
    self.BaseClass.Draw(self, flags)
end

function ENT:DrawTranslucent(flags)
    self.BaseClass.DrawTranslucent(self, flags)
end

function ENT:Think()
end