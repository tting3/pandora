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

local item_type = require("app.object.item_type")
local plants_type = require("app.object.plants_type")
local cal_shortest_dis = require("app.logic.cal_shortest_dis")

local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
    copy = orig
    end
    return copy
end

local farmer = {
    task_name = -1,
    task_index = -1,
    status = LOOKING_FOR_FARM,
    farm_index = 0,
    storage_index = 0,
    storage_level = 0,
    storages = {},
    curr_storage_index = 0,
    entrance_pos = cc.p(-1, -1),
    crop_pos = cc.p(-1, -1),
    path = nil,
    reserved_bread = 1,
    last_crop_num = 0,
    do_farming = function(self, parent, minions, structs, map, index, dt)
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
        local function cal_pos_blocked(struct_index, target_coor)
            local level = nil
            if minions[index].height_level == 0 and structs[struct_index].walls ~= nil  then
                level = structs[struct_index].walls
            end
            if minions[index].height_level == 1 and structs[struct_index].room1 ~= nil then
                level = structs[struct_index].room1
            end
            if minions[index].height_level == 2 and structs[struct_index].room2 ~= nil  then
                level = structs[struct_index].room2
            end
            if minions[index].height_level == 3 and structs[struct_index].room3 ~= nil  then
                level = structs[struct_index].room3
            end
            if level == nil then
                return cc.p(-1.0, -1.0)
            end
            local layer = level:layerNamed("collision")
            local function check(i, j)
                if i >= 0 and j >= 0 and i < structs[struct_index].map.x and j < structs[struct_index].map.y then
                    local gid = layer:tileGIDAt(cc.p(i, j))
                    local property = level:propertiesForGID(gid)
                    if property ~= 0 and property ~= 4 and property ~= 6 and property ~= 5 and property ~= 7 then
                        return false
                    end
                    return true
                end
                return false
            end
            local function cal_dis(a, b)
                return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)
            end
            local target_pos = {}
            target_pos.x = structs[struct_index].position.x + target_coor.x * structs[struct_index].tile.x
            target_pos.y = structs[struct_index].position.y + (structs[struct_index].map.y - target_coor.y - 1) * structs[struct_index].tile.y
            local x = -1.0
            local y = -1.0
            local dis = math.huge
            local closest = cc.p(-1.0, -1.0)
            if check(target_coor.x - 1, target_coor.y) == true then
                local new_point = cc.p(target_pos.x - 1.0, target_pos.y + structs[struct_index].tile.y / 2)
                local new_dis = cal_dis(new_point, minions[index].position)
                if dis > new_dis then
                    dis = new_dis
                    closest = new_point
                end
            end
            if check(target_coor.x + 1, target_coor.y) == true then
                local new_point = cc.p(target_pos.x + structs[struct_index].tile.x, target_pos.y + structs[struct_index].tile.y / 2)
                local new_dis = cal_dis(new_point, minions[index].position)
                if dis > new_dis then
                    dis = new_dis
                    closest = new_point
                end
            end
            if check(target_coor.x, target_coor.y - 1) == true then
                local new_point = cc.p(target_pos.x + structs[struct_index].tile.x / 2, target_pos.y + structs[struct_index].tile.y)
                local new_dis = cal_dis(new_point, minions[index].position)
                if dis > new_dis then
                    dis = new_dis
                    closest = new_point
                end
            end
            if check(target_coor.x, target_coor.y + 1) == true then
                local new_point = cc.p(target_pos.x  + structs[struct_index].tile.x / 2, target_pos.y - 1.0)
                local new_dis = cal_dis(new_point, minions[index].position)
                if dis > new_dis then
                    dis = new_dis
                    closest = new_point
                end
            end
            return closest
        end
        local function check_door(target_index)
            local can_go = true
            if structs[target_index].doors ~= nil and structs[target_index].doors[minions[index].height_level] ~= nil then
                if structs[target_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y] ~= nil then
                    if structs[target_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y].locked == true then
                        if minions[index]:find_key(structs[target_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y].key_sequence) == 1 then
                            structs[target_index].doors[minions[index].height_level][self.entrance_pos.x][self.entrance_pos.y].locked = false
                        else
                            can_go = false
                        end
                    end
                end
            end
            return can_go
        end
        if self.status == LOOKING_FOR_FARM then
            if minions[index].height_level == 0 then
                if self.path == nil then
                    if self.farm_index == 0 then
                        self.entrance_pos = cc.p(-1, -1)
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
                    self.entrance_pos = structs[struct_index]:get_exit(minions[index].height_level, minions[index].position)
                end
                local x = structs[struct_index].position.x + self.entrance_pos.x * structs[struct_index].tile.x + 2.0
                local y = structs[struct_index].position.y + (structs[struct_index].map.y - self.entrance_pos.y - 1) * structs[struct_index].tile.y
                local tile = cc.p(structs[struct_index].tile.x - 6.0, structs[struct_index].tile.y - 2.0)
                self.path.dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), tile)
                if self.path:cal(minions, structs, map, index, dt) == true then
                    if check_door(self.storage_index) == true then
                        minions[index]:enter_prev_level()
                        self.entrance_pos = cc.p(-1, -1)
                        self.path = nil
                    else
                        self.entrance_pos = cc.p(-1, -1)
                        self.path = nil
                        return failed
                    end
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
                        if minions[index]:add_item(parent, fruit) == false then
                            parent:drop_new_item(fruit, minions[index].position, minions[index].height_level)
                        end
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
                if minions[index]:add_item(parent, fruit) == false then
                    parent:drop_new_item(fruit, minions[index].position, minions[index].height_level)
                end
                self.status = DELIEVERING
            elseif result == failed then
                self.status = LOOKING_FOR_HARVEST
            end
        elseif self.status == DELIEVERING then
            local i = minions[index].position.x / 50.0
            local j = minions[index].position.y / 50.0
            i = math.floor(i) + 1
            j = math.floor(j) + 1
            local struct_index = map[i][j]
            if (struct_index ~= self.storage_index and minions[index].height_level ~= 0) or minions[index].height_level > self.storage_level then
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
                    if check_door(self.storage_index) == true then
                        minions[index]:enter_prev_level()
                        self.entrance_pos = cc.p(-1, -1)
                        self.path = nil
                    else
                        self.entrance_pos = cc.p(-1, -1)
                        self.path = nil
                        return failed
                    end
                end
            end
            if (minions[index].height_level < self.storage_level and struct_index == self.storage_index) or minions[index].height_level == 0 then
                if self.path == nil then
                    self.path = cal_shortest_dis:new()
                    self.path.points[self.path.point_index] = minions[index].position
                end
                if self.entrance_pos.x == -1 or self.entrance_pos.y == -1 then
                    self.entrance_pos = structs[self.storage_index]:get_entrance(minions[index].height_level, minions[index].position)
                end
                local x = structs[self.storage_index].position.x + self.entrance_pos.x * structs[self.storage_index].tile.x + 2.0
                local y = structs[self.storage_index].position.y + (structs[self.storage_index].map.y - self.entrance_pos.y - 1) * structs[self.storage_index].tile.y
                local tile = cc.p(structs[self.storage_index].tile.x - 6.0, structs[self.storage_index].tile.y - 2.0)
                self.path.dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), tile)
                if self.path:cal(minions, structs, map, index, dt) == true then
                    if check_door(self.storage_index) == true then
                        minions[index]:enter_next_level()
                        self.entrance_pos = cc.p(-1, -1)
                        self.path = nil
                    else
                        self.entrance_pos = cc.p(-1, -1)
                        self.path = nil
                        return failed
                    end
                end
            end
            if minions[index].height_level == self.storage_level and struct_index == self.storage_index then
                if self.path == nil then
                    self.path = cal_shortest_dis:new()
                    self.path.points[self.path.point_index] = minions[index].position
                    if #self.storages == 0 then
                        self.storages = structs[self.storage_index]:get_storages(minions[index].height_level)
                        if #self.storages == 0 then
                            self.entrance_pos = cc.p(-1, -1)
                            self.path = nil
                            return failed
                        end
                        self.curr_storage_index = 1
                    end
                    self.path.dest = cal_pos_blocked(self.storage_index, self.storages[self.curr_storage_index])
                end
                if self.path:cal(minions, structs, map, index, dt) == true then
                    if structs[self.storage_index]:check_chest(minions[index].height_level, self.storages[self.curr_storage_index].x, self.storages[self.curr_storage_index].y) == true then
                        local chest = structs[self.storage_index].chests[minions[index].height_level][self.storages[self.curr_storage_index].x][self.storages[self.curr_storage_index].y]
                        local result = minions[index]:find_key(chest.key_sequence)
                        if result == 1 then
                            local actual_reserved_bread = self.reserved_bread
                            for i = 1, minions[index].inventory_size do
                                if minions[index].inventory[i] ~= nil and minions[index].inventory[i].type == item_type.CROP then
                                    minions[index].inventory[i].equipped = nil
                                    local num = minions[index].inventory[i].num
                                    if chest ~= nil and chest:add_item(parent, minions[index].inventory[i]) == true then
                                        minions[index].inventory.weight = minions[index].inventory.weight - num * minions[index].inventory[i].type.weight
                                        minions[index].inventory[i] = nil
                                    elseif self.curr_storage_index + 1 <= #self.storages then
                                        minions[index].inventory.weight = minions[index].inventory.weight - (num - minions[index].inventory[i].num) * minions[index].inventory[i].type.weight
                                        self.path = nil
                                        self.curr_storage_index = self.curr_storage_index + 1
                                        return working
                                    else
                                        minions[index].inventory.weight = minions[index].inventory.weight - (num - minions[index].inventory[i].num) * minions[index].inventory[i].type.weight
                                        parent:drop_new_item(minions[index].inventory[i], minions[index].position, minions[index].height_level)
                                        minions[index].inventory[i] = nil
                                        self.curr_storage_index = 1
                                    end
                                elseif minions[index].inventory[i] ~= nil and minions[index].inventory[i].type == item_type.BREAD then
                                    actual_reserved_bread = actual_reserved_bread - minions[index].inventory[i].num
                                end
                            end
                            if actual_reserved_bread > 0 then
                                for i = 1, chest.inventory_size do
                                    if chest.inventory[i] ~= nil and chest.inventory[i].type == item_type.BREAD then
                                        local add_item = function(item)
                                            while item ~= nil and minions[index]:add_item(parent, item) == false do
                                                local trash = -1
                                                local over_flow_bread = -1
                                                local key_num = 0
                                                local door_pos = structs[self.storage_index]:get_entrance(0, minions[index].position)
                                                local door = structs[self.storage_index].doors[0][door_pos.x][door_pos.y]
                                                local key_sequence = door.key_sequence
                                                for i = 1, minions[index].inventory_size do
                                                    if minions[index].inventory[i] ~= nil and minions[index].inventory[i].type ~= item_type.BREAD and minions[index].inventory[i].equipped == nil then
                                                        if minions[index].inventory[i].type ~= item_type.KEY then
                                                            trash = i
                                                            break
                                                        elseif minions[index].inventory[i].sequence ~= door.key_sequence then
                                                            trash = i
                                                            break
                                                        elseif minions[index].inventory[i].sequence == door.key_sequence and key_num == 0 then
                                                            key_num = key_num + 1
                                                        elseif minions[index].inventory[i].sequence == door.key_sequence and key_num ~= 0 then
                                                            trash = i
                                                            break
                                                        end
                                                    elseif minions[index].inventory[i].type == item_type.BREAD then
                                                        over_flow_bread = i
                                                    end
                                                end
                                                if trash ~= -1 then
                                                    minions[index].inventory.weight = minions[index].inventory.weight - minions[index].inventory[trash].num * minions[index].inventory[trash].type.weight
                                                    parent:drop_new_item(minions[index].inventory[trash], minions[index].position, minions[index].height_level)
                                                    minions[index].inventory[trash] = nil
                                                elseif over_flow_bread ~= -1 then
                                                    minions[index].inventory.weight = minions[index].inventory.weight - minions[index].inventory[over_flow_bread].num * minions[index].inventory[over_flow_bread].type.weight
                                                    parent:drop_new_item(minions[index].inventory[over_flow_bread], minions[index].position, minions[index].height_level)
                                                    minions[index].inventory[over_flow_bread] = nil
                                                else
                                                    parent:drop_new_item(item, minions[index].position, minions[index].height_level)
                                                    item = nil
                                                end
                                            end
                                        end
                                        if actual_reserved_bread < chest.inventory[i].num then
                                            local item = shallowcopy(chest.inventory[i])
                                            if item.heat_level ~= nil then
                                                parent.cool_down:add_item(item)
                                            end
                                            item.num = actual_reserved_bread
                                            chest.inventory[i].num = chest.inventory[i].num - actual_reserved_bread
                                            add_item(item)
                                            break
                                        else
                                            actual_reserved_bread = actual_reserved_bread - chest.inventory[i].num
                                            add_item(chest.inventory[i])
                                            chest.inventory[i] = nil
                                            if actual_reserved_bread == 0 then
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        elseif result == -1 then
                            return working
                        else
                            for i = 1, minions[index].inventory_size do
                                if minions[index].inventory[i] ~= nil and minions[index].inventory[i].type == item_type.CROP then
                                    minions[index].inventory.weight = minions[index].inventory.weight - minions[index].inventory[i].num * minions[index].inventory[i].type.weight
                                    parent:drop_new_item(minions[index].inventory[i], minions[index].position, minions[index].height_level)
                                    minions[index].inventory[i] = nil
                                end
                            end
                            self.entrance_pos = cc.p(-1, -1)
                            self.path = nil
                            return failed
                        end
                    else
                        self.path = nil
                        self.storages = {}
                        self.path = nil
                    end
                    self.status = LOOKING_FOR_FARM
                    self.path = nil
                    self.entrance_pos = cc.p(-1, -1)
                end
            end
        end
        return working
    end,
    reset = function(self)
        self.status = LOOKING_FOR_FARM
        self.entrance_pos = cc.p(-1, -1)
        self.crop_pos = cc.p(-1, -1)
        self.path = nil
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
    o.storages = {}
    o.curr_storage_index = 0
    o.entrance_pos = cc.p(-1, -1)
    o.crop_pos = cc.p(-1, -1)
    o.last_crop_num = 0
    o.path = nil
    o.reserved_bread = 1
    return o
end

return farmer
