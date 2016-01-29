--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/17/2016
-- Time: 7:33 AM
-- To change this template use File | Settings | File Templates.
--

local STOP = -1
local success = 1
local working = 0
local failed = -1
local FINDING_TARGET = 0
local STALKING = 1
local STEALING = 2

local thief = {
    task_name = -1,
    task_index = -1,
    steal_status = 0,
    steal = function(self, minions, structs, map, index, dt)
        if self.steal_status == FINDING_TARGET then
            --for i = 0, 10
            --minions[index].map_characters[]
        end
    end
}

function thief:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.task_name = -1
    o.task_index = -1
    o.steal_status = 0
    return o
end

return thief
