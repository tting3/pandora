--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 3/15/2016
-- Time: 2:55 PM
-- To change this template use File | Settings | File Templates.
--

local success = 1
local working = 0
local failed = -1

local cal_shortest_dis = require("app.logic.cal_shortest_dis")
local enter_level = require("app.logic.enter_level")
local leave_level = require("app.logic.leave_level")

local stalk = {
    path = nil,
    stalking_target = nil,
    last_seen = nil,
    enter_leave = nil,
    stalking = function(self, m_character, minions, structs, map, index, dt)
        local stalking_character
        if self.stalking_target ~= 0 then
            stalking_character = minions[self.stalking_target]
        else
            stalking_character = m_character
        end
        if self.last_seen == nil then
            local dis = (stalking_character.position.x - minions[index].position.x) * (stalking_character.position.x - minions[index].position.x) + (stalking_character.position.y - minions[index].position.y) * (stalking_character.position.y - minions[index].position.y)
            if (stalking_character.height_level ~= minions[index].height_level and stalking_character.height_level ~= 0) or dis > 50*5*50*5 then
                self.last_seen = stalking_character.position
                local i
                local j
                if minions[index].height_level < stalking_character.height_level then
                    self.enter_leave = enter_level:new()
                    i = stalking_character.position.x / 50.0
                    j = stalking_character.position.y / 50.0
                else
                    self.enter_leave = leave_level:new()
                    i = minions[index].position.x / 50.0
                    j = minions[index].position.y / 50.0
                end
                i = math.floor(i) + 1
                j = math.floor(j) + 1
                local struct_index = map[i][j]
                self.enter_leave:init(struct_index)
                self.path = nil
            elseif minions[index].height_level > 0 and stalking_character.height_level == 0 and self.enter_leave == nil then
                self.enter_leave = leave_level:new()
                local i = minions[index].position.x / 50.0
                local j = minions[index].position.y / 50.0
                i = math.floor(i) + 1
                j = math.floor(j) + 1
                local struct_index = map[i][j]
                self.enter_leave:init(struct_index)
            end
        else
            local dis = (stalking_character.position.x - minions[index].position.x) * (stalking_character.position.x - minions[index].position.x) + (stalking_character.position.y - minions[index].position.y) * (stalking_character.position.y - minions[index].position.y)
            if (stalking_character.height_level == minions[index].height_level or stalking_character.height_level == 0) and dis <= 50*5*50*5 then
                self.last_seen = nil
                self.enter_leave = nil
            end
        end
        if self.enter_leave ~= nil then
            local result = self.enter_leave:move(minions, structs, map, index, dt)
            if result == success then
                self.enter_leave = nil
            elseif result == working then
                return working
            else
                return failed
            end
        end
        if self.path == nil then
            self.path = cal_shortest_dis:new()
            self.path.points[self.path.point_index] = minions[index].position
        end
        if self.last_seen == nil then
            self.path.dest = stalking_character.position
        else
            self.path.dest = self.last_seen
        end
        if self.path:cal(minions, structs, map, index, dt) == true then
            if self.last_seen ~= nil then
                self.last_seen = nil
                self.path = nil
                return failed
            else
                self.last_seen = nil
                self.path = nil
                return success
            end
        end
        return working
    end
}

function stalk:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.path = nil
    o.stalking_target = nil
    o.last_seen = nil
    o.enter_leave = nil
    return o
end

return stalk
