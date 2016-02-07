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
local patrol = require("app.logic.patrol")
local cal_shortest_dis = require("app.logic.cal_shortest_dis")

local thief = {
    task_name = -1,
    task_index = -1,
    steal_status = 0,
    targets_list = {},
    stalking_target = nil,
    path = nil,
    patrol = nil,
    patrol_init = function(self, target_structs)
        self.targets_list = {identity.slave_farm}
        self.patrol = patrol:new()
        self.patrol.target_structs = target_structs
        self.patrol.target_wait_time = 0.0
    end,
    check_condition = function(self, m_character, minions, c_index, index)
        if c_index == 0 then
            if minions[index].height_level < m_character.height_level then
                return -1
            end
            for i, target in pairs(self.targets_list) do
                if m_character.id == target then
                    return 0
                end
            end
            return -1
        end
        if minions[index].height_level < minions[c_index].height_level or c_index == index then
            return -1
        end
        for i, target in pairs(self.targets_list) do
            if minions[c_index].id == target then
                return c_index
            end
        end
        return -1
    end,
    check_block = function(self, m_character, minions, index, check_i, check_j)
        if minions[index].map_characters[check_i][check_j][1] <= 0 then
            return -1
        end
        for check_index = 2, minions[index].map_characters[check_i][check_j][1] + 1 do
            local result = self:check_condition(m_character, minions, minions[index].map_characters[check_i][check_j][check_index], index)
            if result ~= -1 then
                return result
            end
        end
        return -1
    end,
    check_surroundings = function(self, m_character, minions, index, sight)
        local i = minions[index].position.x / 50.0
        local j = minions[index].position.y / 50.0
        i = math.floor(i) + 1
        j = math.floor(j) + 1
        local result
        result = self:check_block(m_character, minions, index, i, j)
        if result ~= -1 then
            return result
        end
        local dis
        for dis = 1, sight do
            local check_i
            local check_j
            local check_index
            check_j = j - dis
            local result
            for check_i = i - dis, i + dis do
                result = self:check_block(m_character, minions, index, check_i, check_j)
                if result ~= -1 then
                    return result
                end
            end
            check_j = j + dis
            for check_i = i - dis, i + dis do
                result = self:check_block(m_character, minions, index, check_i, check_j)
                if result ~= -1 then
                    return result
                end
            end
            check_i = i - dis
            for check_j = j - dis, j + dis do
                result = self:check_block(m_character, minions, index, check_i, check_j)
                if result ~= -1 then
                    return result
                end
            end
            check_i = i + dis
            for check_j = j - dis, j + dis do
                result = self:check_block(m_character, minions, index, check_i, check_j)
                if result ~= -1 then
                    return result
                end
            end
        end
        return -1
    end,
    steal = function(self, m_character, minions, structs, map, index, dt)
        if self.steal_status == FINDING_TARGET then
            self.patrol:patroling(minions, structs, map, index, dt)
        end
        if self.steal_status == FINDING_TARGET and math.random(20) <= 2 then
            local result = self:check_surroundings(m_character, minions, index, SIGHT)
            if result ~= -1 then
                self.patrol.path = nil
                self.stalking_target = result
                self.steal_status = STALKING
            end
        end
        if self.steal_status == STALKING then
            if self.path == nil then
                self.path = cal_shortest_dis:new()
                self.path.points[self.path.point_index] = minions[index].position
                if self.stalking_target ~= 0 then
                    self.path.dest = minions[self.stalking_target].position
                else
                    self.path.dest = m_character.position
                end
            end
            if self.stalking_target ~= 0 then
                local dis = (minions[self.stalking_target].position.x - minions[index].position.x) * (minions[self.stalking_target].position.x - minions[index].position.x) + (minions[self.stalking_target].position.y - minions[index].position.y) * (minions[self.stalking_target].position.y - minions[index].position.y)
                if minions[self.stalking_target].height_level > minions[index].height_level or dis > 50*5*50*5 then
                    self.path = nil
                    self.steal_status = FINDING_TARGET
                    return working
                end
            else
                local dis = (m_character.position.x - m_character.position.x) * (m_character.position.x - m_character.position.x) + (m_character.position.y - m_character.position.y) * (m_character.position.y - m_character.position.y)
                if m_character.height_level > m_character.height_level or dis > 50*5*50*5 then
                    self.path = nil
                    self.steal_status = FINDING_TARGET
                    return working
                end
            end
            if self.path:cal(minions, structs, map, index, dt) == true then
                self.path = nil
            end
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
    o.stalking_target = nil
    o.path = nil
    o.patrol = nil
    return o
end

return thief
