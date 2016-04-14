--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 4/11/2016
-- Time: 1:58 PM
-- To change this template use File | Settings | File Templates.
--

local HELP = 2
local TRADE = 3

local shouting = {
    position = cc.p(0.0, 0.0),
    height_level = 0,
    event_type = -1,
    indices_array = nil,
    type = nil,
    init = function(self, position, height_level, type, event_spread_dis)
        self.indices_array = {}
        for i = 1, event_spread_dis * 2 + 1 do
            self.indices_array[i] = {}
            for j = 1, event_spread_dis * 2 + 1 do
                self.indices_array[i][j] = {}
                self.indices_array[i][j].value = 0
            end
        end
        self.event_type = type
        self.position = position
        self.height_level = height_level
    end
}

function shouting:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.position = cc.p(0.0, 0.0)
    o.height_level = 0
    o.event_type = -1
    o.indices_array = nil
    o.type = nil
    return o
end

return shouting
