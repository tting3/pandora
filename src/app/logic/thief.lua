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
local SIGHT = 5

local patrol = require("app.logic.patrol")
local stalk = require("app.logic.stalk")
local check_surroundings_id = require("app.logic.check_surroundings_id")

local thief = {
    task_name = -1,
    task_index = -1,
    steal_status = 0,
    ids_list = {},
    patrol = nil,
    patrol_init = function(self, target_structs, new_ids_list)
        self.ids_list = new_ids_list
        self.patrol = patrol:new()
        self.patrol.target_structs = target_structs
        self.patrol.target_wait_time = 0.0
    end,
    steal = function(self, m_character, minions, structs, map, index, dt)
        if self.steal_status == FINDING_TARGET then
            self.patrol:patroling(minions, structs, map, index, dt)
        end
        if self.steal_status == FINDING_TARGET and math.random(20) <= 2 then
            local result = check_surroundings_id(self, m_character, minions, index, SIGHT)
            if result ~= -1 then
                self.patrol.path = nil
                self.stalk = stalk:new()
                self.stalk.stalking_target = result
                self.steal_status = STALKING
            end
        end
        if self.steal_status == STALKING then
            local result = self.stalk:stalking(m_character, minions, structs, map, index, dt)
            if result == failed then
                self.steal_status = FINDING_TARGET
                self.stalk = nil
            elseif result == success then
                self.steal_status = STEALING
                self.stalk = nil
            end
        end
        if self.steal_status == STEALING then
            self.steal_status = FINDING_TARGET
        end
        return working
    end
}

function thief:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.task_name = -1
    o.task_index = -1
    o.steal_status = 0
    o.ids_list = {}
    o.patrol = nil
    o.stalk = nil
    return o
end

return thief
