--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/15/2016
-- Time: 8:02 AM
-- To change this template use File | Settings | File Templates.
--

local STOP = -1
local success = 1
local working = 0
local failed = -1
local SIGHT = 5
local PATROLING = 0
local STALKING = 1
local ENFORCEMENT = 2

local patrol = require("app.logic.patrol")
local stalk = require("app.logic.stalk")
local check_surroundings = require("app.logic.check_surroundings")
local enter_level = require("app.logic.enter_level")
local leave_level = require("app.logic.leave_level")

local guardian_patrol = {
    task_name = -1,
    task_index = -1,
    guardian_status = 0,
    targets_list = {},
    stalk = nil,
    patrol = nil,
    enter_leave = nil,
    patrol_init = function(self, target_structs, new_targets_list)
        self.targets_list = new_targets_list
        self.patrol = patrol:new()
        self.patrol.target_structs = target_structs
        self.patrol.target_wait_time = 2.0
        self.patrol.waited_time = self.patrol.target_wait_time
    end,
    patroling = function(self, m_character, minions, structs, map, index, dt)
        if self.guardian_status == PATROLING then
            if self.guardian_status == PATROLING and math.random(20) <= 2 then
                local result = check_surroundings(self, m_character, minions, index, SIGHT, self.targets_list)
                if result ~= -1 then
                    self.patrol.path = nil
                    self.stalk = stalk:new()
                    self.stalk.stalking_target = result
                    self.guardian_status = STALKING
                    self.patrol.waited_time = self.patrol.target_wait_time
                end
            end
            if minions[index].height_level ~= 0 then
                if self.enter_leave == nil then
                    self.enter_leave = leave_level:new()
                    local i = minions[index].position.x / 50.0
                    local j = minions[index].position.y / 50.0
                    i = math.floor(i) + 1
                    j = math.floor(j) + 1
                    local struct_index = map[i][j]
                    self.enter_leave:init(struct_index)
                end
                local result = self.enter_leave:move(minions, structs, map, index, dt)
                if result == success then
                    self.enter_leave = nil
                elseif result == working then
                    return working
                else
                    return failed
                end
            end
            self.patrol:patroling(minions, structs, map, index, dt)
        end
        if self.guardian_status == STALKING then
            local result = self.stalk:stalking(m_character, minions, structs, map, index, dt)
            if result == failed then
                self.guardian_status = PATROLING
                self.stalk = nil
            elseif result == success then
                self.guardian_status = ENFORCEMENT
                self.stalk = nil
            end
        end
        if self.guardian_status == ENFORCEMENT then
            self.guardian_status = PATROLING
        end
        return working
    end
}

function guardian_patrol:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.task_name = -1
    o.task_index = -1
    o.guardian_status = 0
    o.targets_list = {}
    o.stalk = nil
    o.patrol = nil
    o.enter_leave = nil
    return o
end

return guardian_patrol
