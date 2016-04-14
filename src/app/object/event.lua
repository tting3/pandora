--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 3/14/2016
-- Time: 1:41 PM
-- To change this template use File | Settings | File Templates.
--

local hurting = 0
local murdering = 1
local dead_body = 2
local kidnap = 3

local event = {
    type = -1,
    initiator = nil,
    accepter = nil,
    time = 0,
    date = 0,
    location = cc.p(0.0, 0.0),
    height_level = 0,
    init = function(self, type, initiator, accepter, time, date, location, height_level)
        self.type = type
        self.initiator = initiator
        self.accepter = accepter
        self.time = time
        self.date = date
        self.location = location
        self.height_level = height_level
    end
}

function event:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.type = -1
    o.initiator = nil
    o.accepter = nil
    o.time = 0
    o.date = 0
    o.location = cc.p(0.0, 0.0)
    o.height_level = 0
    return o
end

return event
