--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/8/2016
-- Time: 8:15 AM
-- To change this template use File | Settings | File Templates.
--

local LOOKING_FOR_FARM = 0
local LOOKING_FOR_HARVEST = 1
local HARVESTING = 2
local DELIEVERING = 3
local STOP = -1
local success = 1
local working = 0
local failed = -1

local plants_type = require("app.object.plants_type")
local cal_shortest_dis = require("app.logic.cal_shortest_dis")

local farmer = {
    task_name = -1,
    task_index = -1,
    status = LOOKING_FOR_FARM,
    farm_index = 0,
    storage_index = 0,
    storage_level = 0,
    storage_pos = cc.p(-1, -1),
    entrance_pos = cc.p(-1, -1),
    crop_pos = cc.p(-1, -1),
    path = nil,
    last_crop_num = 0,
    do_farming = function(self, minions, structs, map, index, dt)
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
        if self.status == LOOKING_FOR_FARM then
            if minions[index].height_level == 0 then
                if self.path == nil then
                    if self.farm_index == 0 then
                        return failed
                    end
                    self.path = cal_shortest_dis:new()
                    self.path.points[self.path.point_index] = minions[index].position
                end
                self.path.dest = cal_pos_with_index(structs[self.farm_index].position, structs[self.farm_index].map, structs[self.farm_index].tile)
                if self.path:cal(minions, structs, map, index, dt) == true then
                    self.entrance_pos = cc.p(-1, -1)
                    self.crop_pos = cc.p(-1, -1)
                    self.status = LOOKING_FOR_HARVEST
                    self.path = nil
                end
            elseif minions[index].height_level > 0 then
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
        elseif self.status == LOOKING_FOR_HARVEST then
            if structs[self.farm_index].plants:check_plant(self.crop_pos.x, self.crop_pos.y, plants_type.CROP) == false then
                local ii = -1
                local jj = -1
                ii, jj = structs[self.farm_index].plants:find_closest(structs[self.farm_index], minions[index].position, plants_type.CROP)
                self.crop_pos = cc.p(ii, jj)
                self.last_crop_num = structs[self.farm_index].plants.plants_num[plants_type.CROP.type]
            end
            if self.crop_pos.x ~= -1 and self.crop_pos.y ~= -1 then
                if self.path == nil then
                    self.path = cal_shortest_dis:new()
                    self.path.points[self.path.point_index] = minions[index].position
                end
                local x = structs[self.farm_index].position.x + self.crop_pos.x * structs[self.farm_index].tile.x
                local y = structs[self.farm_index].position.y + (structs[self.farm_index].map.y - self.crop_pos.y - 1) * structs[self.farm_index].tile.y
                self.path.dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), structs[self.farm_index].tile)
                if self.path:cal(minions, structs, map, index, dt) == true then
                    local result, fruit = structs[self.farm_index].plants:harvest_plant(self.crop_pos.x, self.crop_pos.y, dt)
                    self.path = nil
                    if result == success then
                        minions[index]:add_item(fruit)
                        self.status = DELIEVERING
                    elseif result == failed then
                        self.crop_pos = cc.p(-1, -1)
                    elseif result == working then
                        self.status = HARVESTING
                    end
                end
            else
                minions[index].dir = STOP
            end
        elseif self.status == HARVESTING then
            minions[index].dir = STOP
            local result, fruit = structs[self.farm_index].plants:harvest_plant(self.crop_pos.x, self.crop_pos.y, dt)
            if result == success then
                minions[index]:add_item(fruit)
                self.status = DELIEVERING
            elseif result == failed then
                self.status = LOOKING_FOR_HARVEST
            end
        elseif self.status == DELIEVERING then
            if minions[index].height_level < self.storage_level then
                if self.path == nil then
                    self.path = cal_shortest_dis:new()
                    self.path.points[self.path.point_index] = minions[index].position
                end
                if self.entrance_pos.x == -1 or self.entrance_pos.y == -1 then
                    self.entrance_pos = structs[self.storage_index]:get_entrance(minions[index].height_level)
                end
                local x = structs[self.storage_index].position.x + self.entrance_pos.x * structs[self.storage_index].tile.x + 2.0
                local y = structs[self.storage_index].position.y + (structs[self.storage_index].map.y - self.entrance_pos.y - 1) * structs[self.storage_index].tile.y
                local tile = cc.p(structs[self.storage_index].tile.x - 4.0, structs[self.storage_index].tile.y - 2.0)
                self.path.dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), tile)
                if self.path:cal(minions, structs, map, index, dt) == true then
                    minions[index]:enter_next_level()
                    self.entrance_pos = cc.p(-1, -1)
                    self.path = nil
                end
            end
            if minions[index].height_level == self.storage_level then
                if self.path == nil then
                    self.path = cal_shortest_dis:new()
                    self.path.points[self.path.point_index] = minions[index].position
                end
                if self.storage_pos.x == -1 or self.storage_pos.y == -1 then
                    self.storage_pos = structs[self.storage_index]:get_storage(minions[index].height_level)
                end
                local x = structs[self.storage_index].position.x + self.storage_pos.x * structs[self.storage_index].tile.x + 2.0
                local y = structs[self.storage_index].position.y + (structs[self.storage_index].map.y - self.storage_pos.y - 1) * structs[self.storage_index].tile.y
                local tile = cc.p(structs[self.storage_index].tile.x - 4.0, structs[self.storage_index].tile.y - 2.0)
                self.path.dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), tile)
                if self.path:cal(minions, structs, map, index, dt) == true then
                    self.status = LOOKING_FOR_FARM
                    self.path = nil
                    self.entrance_pos = cc.p(-1, -1)
                end
            end
            if minions[index].height_level > self.storage_level then
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
        end
        return working
    end
}

function farmer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.task_name = -1
    o.task_index = -1
    o.status = LOOKING_FOR_FARM
    o.farm_index = 0
    o.storage_index = 0
    o.storage_level = 0
    o.storage_pos = cc.p(-1, -1)
    o.entrance_pos = cc.p(-1, -1)
    o.crop_pos = cc.p(-1, -1)
    o.last_crop_num = 0
    o.path = nil
    return o
end

return farmer
