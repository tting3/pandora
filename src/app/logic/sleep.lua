--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/21/2016
-- Time: 1:55 PM
-- To change this template use File | Settings | File Templates.
--

local success = 1
local working = 0
local failed = -1

local cal_shortest_dis = require("app.logic.cal_shortest_dis")

local sleep = {
    task_name = -1,
    task_index = -1,
    sleep_index = -1,
    bed_level = -1,
    bed_pos = cc.p(-1, -1),
    entrance_pos = cc.p(-1, -1),
    path = nil,
    go_to_bed = function(self, minions, structs, map, index, dt)
        local function cal_pos_with_index(target_pos, tile, size)
            local x, y
            if minions[index].position.x >= target_pos.x and minions[index].position.x < target_pos.x + size.x * tile.x then
                x = minions[index].position.x
            end
            if minions[index].position.x < target_pos.x then
                x = target_pos.x
            end
            if minions[index].position.x >= target_pos.x + size.x * tile.x then
                x = target_pos.x + size.x * tile.x
            end
            if minions[index].position.y >= target_pos.y and minions[index].position.y < target_pos.y + size.y * tile.y then
                y = minions[index].position.y
            end
            if minions[index].position.y < target_pos.y then
                y = target_pos.y
            end
            if minions[index].position.y >= target_pos.y + size.y * tile.y then
                y = target_pos.y + size.y * tile.y
            end
            return cc.p(x, y)
        end
        if minions[index].height_level < self.bed_level then
            if self.path == nil then
                self.path = cal_shortest_dis:new()
                self.path.points[self.path.point_index] = minions[index].position
            end
            if self.entrance_pos.x == -1 or self.entrance_pos.y == -1 then
                self.entrance_pos = structs[self.sleep_index]:get_entrance(minions[index].height_level)
            end
            local x = structs[self.sleep_index].position.x + self.entrance_pos.x * structs[self.sleep_index].tile.x + 2.0
            local y = structs[self.sleep_index].position.y + (structs[self.sleep_index].map.y - self.entrance_pos.y - 1) * structs[self.sleep_index].tile.y
            local tile = cc.p(structs[self.sleep_index].tile.x - 4.0, structs[self.sleep_index].tile.y - 2.0)
            self.path.dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), tile)
            if self.path:cal(minions, structs, map, index, dt) == true then
                minions[index]:enter_next_level()
                self.entrance_pos = cc.p(-1, -1)
                self.path = nil
            end
        end
        if minions[index].height_level == self.bed_level then
            if self.path == nil then
                self.path = cal_shortest_dis:new()
                self.path.points[self.path.point_index] = minions[index].position
            end
            self.path.dest = cc.p(structs[self.sleep_index].position.x + self.bed_pos.x * structs[self.sleep_index].tile.x + 20.0, structs[self.sleep_index].position.y + (structs[self.sleep_index].map.y - self.bed_pos.y - 1) * structs[self.sleep_index].tile.y + 45.0)
            if self.path:cal(minions, structs, map, index, dt) == true then
                self.path = nil
                self.entrance_pos = cc.p(-1, -1)
                return success
            end
        end
        if minions[index].height_level > self.bed_level then
            if self.path == nil then
                self.path = cal_shortest_dis:new()
                self.path.points[self.path.point_index] = minions[index].position
            end
            local i = minions[index].position.x / 50.0
            local j = minions[index].position.y / 50.0
            i = math.floor(i) + 1
            j = math.floor(j) + 1
            local struct_index = map[i][j]
            if self.entrance_pos.x == -1 or self.entrance_pos.y == -1 then
                self.entrance_pos = structs[struct_index]:get_exit(minions[index].height_level)
            end
            local x = structs[struct_index].position.x + self.entrance_pos.x * structs[struct_index].tile.x + 2.0
            local y = structs[struct_index].position.y + (structs[struct_index].map.y - self.entrance_pos.y - 1) * structs[struct_index].tile.y
            local tile = cc.p(structs[struct_index].tile.x - 4.0, structs[struct_index].tile.y - 2.0)
            self.path.dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), tile)
            if self.path:cal(minions, structs, map, index, dt) == true then
                minions[index]:enter_prev_level()
                self.entrance_pos = cc.p(-1, -1)
                self.path = nil
            end
        end
        return working
    end
}

function sleep:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.task_name = -1
    o.task_index = -1
    o.sleep_index = -1
    o.bed_level = -1
    o.bed_pos = cc.p(-1, -1)
    o.entrance_pos = cc.p(-1, -1)
    o.path = nil
    return o
end

return sleep
