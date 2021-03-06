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
    beds = {},
    curr_bed_index = 0,
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
        local function check_door()
            local can_go = true
            if structs[self.sleep_index].doors ~= nil and structs[self.sleep_index].doors[minions[index].height_level] ~= nil then
                if structs[self.sleep_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y] ~= nil then
                    if structs[self.sleep_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y].locked == true then
                        if minions[index]:find_key(structs[self.sleep_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y].key_sequence) == 1 then
                            structs[self.sleep_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y].locked = false
                        else
                            can_go = false
                        end
                    end
                end
            end
            return can_go
        end
        local i = minions[index].position.x / 50.0
        local j = minions[index].position.y / 50.0
        i = math.floor(i) + 1
        j = math.floor(j) + 1
        local struct_index = map[i][j]
        if (struct_index ~= self.sleep_index and minions[index].height_level ~= 0) or minions[index].height_level > self.bed_level then
            if self.path == nil then
                self.path = cal_shortest_dis:new()
                self.path.points[self.path.point_index] = minions[index].position
            end
            if self.entrance_pos.x == -1 or self.entrance_pos.y == -1 then
                self.entrance_pos = structs[struct_index]:get_exit(minions[index].height_level, minions[index].position)
            end
            local x = structs[struct_index].position.x + self.entrance_pos.x * structs[struct_index].tile.x + 2.0
            local y = structs[struct_index].position.y + (structs[struct_index].map.y - self.entrance_pos.y - 1) * structs[struct_index].tile.y
            local tile = cc.p(structs[struct_index].tile.x - 6.0, structs[struct_index].tile.y - 2.0)
            self.path.dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), tile)
            if self.path:cal(minions, structs, map, index, dt) == true then
                if check_door() == true then
                    minions[index]:enter_prev_level()
                    self.entrance_pos = cc.p(-1, -1)
                    self.path = nil
                end
            end
        end
        if (minions[index].height_level < self.bed_level and struct_index == self.sleep_index) or minions[index].height_level == 0 then
            if self.path == nil then
                self.path = cal_shortest_dis:new()
                self.path.points[self.path.point_index] = minions[index].position
            end
            if self.entrance_pos.x == -1 or self.entrance_pos.y == -1 then
                self.entrance_pos = structs[self.sleep_index]:get_entrance(minions[index].height_level, minions[index].position)
            end
            local x = structs[self.sleep_index].position.x + self.entrance_pos.x * structs[self.sleep_index].tile.x + 2.0
            local y = structs[self.sleep_index].position.y + (structs[self.sleep_index].map.y - self.entrance_pos.y - 1) * structs[self.sleep_index].tile.y
            local tile = cc.p(structs[self.sleep_index].tile.x - 6.0, structs[self.sleep_index].tile.y - 2.0)
            self.path.dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), tile)
            if self.path:cal(minions, structs, map, index, dt) == true then
                if check_door() == true then
                    minions[index]:enter_next_level()
                    self.entrance_pos = cc.p(-1, -1)
                    self.path = nil
                end
            end
        end
        if minions[index].height_level == self.bed_level and struct_index == self.sleep_index then
            if self.path == nil then
                self.path = cal_shortest_dis:new()
                self.path.points[self.path.point_index] = minions[index].position
                if #self.beds == 0 then
                    self.beds = structs[self.sleep_index]:get_beds(minions[index].height_level)
                    if #self.beds == 0 then
                        return failed, nil
                    end
                    self.curr_bed_index = 1
                end
            end
            local bed_coor = {}
            bed_coor.x = self.beds[self.curr_bed_index].x
            bed_coor.y = self.beds[self.curr_bed_index].y
            self.path.dest = cc.p(structs[self.sleep_index].position.x + bed_coor.x * structs[self.sleep_index].tile.x + 20.0, structs[self.sleep_index].position.y + (structs[self.sleep_index].map.y - bed_coor.y - 1) * structs[self.sleep_index].tile.y + 45.0)
            if self.path:cal(minions, structs, map, index, dt) == true then
                local bed = structs[self.sleep_index].beds[minions[index].height_level][self.beds[self.curr_bed_index].x][self.beds[self.curr_bed_index].y]
                if bed ~= nil and bed.in_use == false then
                    self.path = nil
                    self.entrance_pos = cc.p(-1, -1)
                    return success, bed
                elseif self.curr_bed_index + 1 <= #self.beds then
                    self.curr_bed_index = self.curr_bed_index + 1
                    self.path = nil
                    return working, nil
                else
                    self.path = nil
                    self.curr_bed_index = 1
                end
                if bed == nil then
                    self.path = nil
                    self.beds = {}
                end
            end
        end
        return working, nil
    end,
    reset = function(self)
        self.entrance_pos = cc.p(-1, -1)
        self.path = nil
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
    o.beds = {}
    o.curr_bed_index = 0
    o.entrance_pos = cc.p(-1, -1)
    o.path = nil
    return o
end

return sleep
