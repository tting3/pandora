--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 3/1/2016
-- Time: 12:56 AM
-- To change this template use File | Settings | File Templates.
--

local cloud_shadow = {
    position = cc.p(0.0, 0.0),
    sprite = nil,
    init = function(self, parent, position, name)
        self.position = position
        self.sprite = display.newSprite(name)
        :move(self.position.x - parent.m_character.position.x + display.cx, self.position.y - parent.m_character.position.y + display.cy + 25)
        :addTo(parent.c_node, math.floor(display.top - (self.position.y - parent.m_character.position.y + display.cy)))
    end,
    update = function(self, parent, dt)
        if self.sprite ~= nil then
            self.sprite:move(self.position.x - parent.m_character.position.x + display.cx, self.position.y - parent.m_character.position.y + display.cy + 25)
            self.sprite:setZOrder(math.floor(display.top - (self.position.y - parent.m_character.position.y + display.cy)))
        end
    end
}

function cloud_shadow:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.position = cc.p(0.0, 0.0)
    o.sprite = nil
    return o
end

return cloud_shadow
