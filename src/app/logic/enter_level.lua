--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 3/15/2016
-- Time: 7:52 PM
-- To change this template use File | Settings | File Templates.
--

local success = 1
local working = 0
local failed = -1

local cal_shortest_dis = require("app.logic.cal_shortest_dis")

local enter_level = {
    struct_index = 0,
    entrance_pos = cc.p(-1, -1),
    path = nil,
    init = function(self, struct_index)
        self.struct_index = struct_index
    end,
    move = function(self, minions, structs, map, index, dt)
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
            if structs[self.struct_index].doors ~= nil and structs[self.struct_index].doors[minions[index].height_level] ~= nil then
                if structs[self.struct_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y] ~= nil then
                    if structs[self.struct_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y].locked == true then
                        if minions[index]:find_key(structs[self.struct_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y].key_sequence) == 1 then
                            structs[self.struct_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y].locked = false
                        else
                            can_go = false
                        end
                    end
                end
            end
            return can_go
        end
        if self.path == nil then
            self.path = cal_shortest_dis:new()
            self.path.points[self.path.point_index] = minions[index].position
        end
        if self.entrance_pos.x == -1 or self.entrance_pos.y == -1 then
            self.entrance_pos = structs[self.struct_index]:get_entrance(minions[index].height_level, minions[index].position)
        end
        local x = structs[self.struct_index].position.x + self.entrance_pos.x * structs[self.struct_index].tile.x + 2.0
        local y = structs[self.struct_index].position.y + (structs[self.struct_index].map.y - self.entrance_pos.y - 1) * structs[self.struct_index].tile.y
        local tile = cc.p(structs[self.struct_index].tile.x - 6.0, structs[self.struct_index].tile.y - 2.0)
        self.path.dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), tile)
        if self.path:cal(minions, structs, map, index, dt) == true then
            if check_door() == true then
                minions[index]:enter_next_level()
                self.entrance_pos = cc.p(-1, -1)
                self.path = nil
                return success
            else
                return failed
            end
        end
        return working
    end
}

function enter_level:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.struct_index = 0
    o.entrance_pos = cc.p(-1, -1)
    o.path = nil
    return o
end

return enter_level
