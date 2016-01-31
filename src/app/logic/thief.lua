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

local identity = require("app.logic.identity")

local thief = {
    task_name = -1,
    task_index = -1,
    steal_status = 0,
    targets_list = {},
    check_condition = function(self, minions, c_index)
        if c_index == 0 then
            return 0
        end
        for i, target in pairs(self.targets_list) do
            if minions[c_index].id == target then
                return c_index
            end
        end
        return -1
    end,
    check_block = function(self, minions, index, check_i, check_j)
        if minions[index].map_characters[check_i][check_j][1] <= 0 then
            return -1
        end
        for check_index = 2, minions[index].map_characters[check_i][check_j][1] + 1 do
            local result = self:check_condition(minions, minions[index].map_characters[check_i][check_j][check_index])
            if result ~= -1 then
                return result
            end
        end
        return -1
    end,
    check_surroundings = function(self, minions, index, sight)
        local i = minions[index].position.x / 50.0
        local j = minions[index].position.y / 50.0
        i = math.floor(i) + 1
        j = math.floor(j) + 1
        local dis
        for dis = 1, sight do
            local check_i
            local check_j
            local check_index
            check_j = j - dis
            local result
            for check_i = i - dis, i + dis do
                result = self:check_block(minions, index, check_i, check_j)
                if result ~= -1 then
                    return result
                end
            end
            check_j = j + dis
            for check_i = i - dis, i + dis do
                result = self:check_block(minions, index, check_i, check_j)
                if result ~= -1 then
                    return result
                end
            end
            check_i = i - dis
            for check_j = j - dis, j + dis do
                result = self:check_block(minions, index, check_i, check_j)
                if result ~= -1 then
                    return result
                end
            end
            check_i = i + dis
            for check_j = j - dis, j + dis do
                result = self:check_block(minions, index, check_i, check_j)
                if result ~= -1 then
                    return result
                end
            end
        end
        return -1
    end,
    steal = function(self, minions, structs, map, index, dt)
        if self.steal_status == FINDING_TARGET and math.random(20) <= 2 then
            self.targets_list = {identity.slave_farm}
            local result = self:check_surroundings(minions, index, SIGHT)
            minions[index]:set_name(tostring(result), 0.0)
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
    o.targets_list = {}
    return o
end

return thief
