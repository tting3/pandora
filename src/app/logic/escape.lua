--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 4/13/2016
-- Time: 4:30 PM
-- To change this template use File | Settings | File Templates.
--

local success = 1
local working = 0
local failed = -1
local DOWN = 0
local LEFT = 1
local RIGHT = 2
local UP = 3
local enter = 4
local leave = 5
local corner = 6
local dis = 50000

local cal_shortest_dis = require("app.logic.cal_shortest_dis")
local run_away_from = require("app.logic.run_away_from")
local enter_level = require("app.logic.enter_level")
local leave_level = require("app.logic.leave_level")

local escape = {
    escape_target = nil,
    path = nil,
    enter_leave_flag = 0,
    enter_leave = nil,
    init = function(self, escape_target)
        self.escape_target = escape_target
    end,
    run = function(self, minions, index, map, structs, dt)
        local function set_dest(direction, point)
            if direction == DOWN then
                self.path.dest = cc.p(minions[index].position.x, minions[index].position.y - minions[index].speed)
            elseif direction == LEFT then
                self.path.dest = cc.p(minions[index].position.x - minions[index].speed, minions[index].position.y)
            elseif direction == RIGHT then
                self.path.dest = cc.p(minions[index].position.x + minions[index].speed, minions[index].position.y)
            elseif direction == UP then
                self.path.dest = cc.p(minions[index].position.x, minions[index].position.y + minions[index].speed)
            elseif direction == leave then
                self.enter_leave_flag = 1
            elseif direction == corner then
                self.path.dest = point
            end
        end
        if self.enter_leave_flag == 0 then
            if self.path == nil then
                self.path = cal_shortest_dis:new()
                self.path.points[self.path.point_index] = minions[index].position
                local flag, result
                flag, result = run_away_from(minions[index].position, minions[index].height_level, self.escape_target.position, self.escape_target.height_level, map, structs)
                set_dest(flag, result)
            else
                local flag, result
                flag, result = run_away_from(minions[index].position, minions[index].height_level, self.escape_target.position, self.escape_target.height_level, map, structs)
                set_dest(flag, result)
                if self.path:cal(minions, structs, map, index, dt) == true then
                    self.path = nil
                end
            end
        elseif self.enter_leave_flag == 1 then
            if self.enter_leave == nil then
                self.enter_leave = leave_level:new()
                local i = minions[index].position.x / 50.0
                local j = minions[index].position.y / 50.0
                i = math.floor(i) + 1
                j = math.floor(j) + 1
                local struct_index = map[i][j]
                self.enter_leave:init(struct_index)
            else
                local result = self.enter_leave:move(minions, structs, map, index, dt)
                if result == success then
                    self.enter_leave = nil
                    self.enter_leave_flag = 0
                end
            end
        end
        if minions[index]:check_in_sight_dis(self.escape_target.position, self.escape_target.height_level, map, structs, dis) == false then
            return success
        end
        return working
    end
}

function escape:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.escape_target = nil
    o.path = nil
    o.enter_leave_flag = 0
    o.enter_leave = nil
    return o
end

return escape
