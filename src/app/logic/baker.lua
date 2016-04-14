--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/18/2016
-- Time: 9:33 AM
-- To change this template use File | Settings | File Templates.
--

local LOOKING_FOR_WHEAT = 0
local LOOKING_FOR_OVEN = 1
local STOP = -1
local success = 1
local working = 0
local failed = -1
local oven_up_cols = 4
local oven_down_cols = 6

local cal_shortest_dis = require("app.logic.cal_shortest_dis")
local item_type = require("app.object.item_type")

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

local baker = {
    task_name = -1,
    task_index = -1,
    status = LOOKING_FOR_WHEAT,
    oven_index = 0,
    oven_level = 0,
    storage_index = 0,
    storage_level = 0,
    ovens = {},
    curr_oven_index = 0,
    storages = {},
    curr_storage_index = 0,
    entrance_pos = cc.p(-1, -1),
    path = nil,
    reserved_bread = 1,
    do_baking = function(self, parent, minions, structs, map, index, dt)
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
                local new_point = cc.p(target_pos.x + structs[struct_index].tile.x / 2, target_pos.y + structs[struct_index].tile.y + 1.0)
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
        local reach_wheat_storage = function()
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
                            if minions[index].inventory[i] ~= nil and minions[index].inventory[i].type == item_type.BREAD then
                                minions[index].inventory[i].equipped = nil
                                local num = minions[index].inventory[i].num
                                if actual_reserved_bread - num < 0 then
                                    local reserved_item = nil
                                    if actual_reserved_bread > 0 then
                                        reserved_item = shallowcopy(minions[index].inventory[i])
                                        if reserved_item.heat_level ~= nil then
                                            parent.cool_down:add_item(reserved_item)
                                        end
                                        reserved_item.num = actual_reserved_bread
                                        minions[index].inventory[i].num = minions[index].inventory[i].num - actual_reserved_bread
                                        minions[index].inventory.weight = minions[index].inventory.weight - actual_reserved_bread * minions[index].inventory[i].type.weight
                                    end
                                    if minions[index].inventory[i].num > 0 then
                                        local num = minions[index].inventory[i].num
                                        if chest ~= nil and chest:add_item(parent, minions[index].inventory[i]) == true then
                                            minions[index].inventory.weight = minions[index].inventory.weight - num * minions[index].inventory[i].type.weight
                                            minions[index].inventory[i] = nil
                                        elseif self.curr_storage_index + 1 <= #self.storages then
                                            minions[index].inventory.weight = minions[index].inventory.weight - (num - minions[index].inventory[i].num) * minions[index].inventory[i].type.weight
                                            self.path = nil
                                            self.curr_storage_index = self.curr_storage_index + 1
                                            if reserved_item ~= nil then
                                                minions[index]:add_item(parent, reserved_item)
                                            end
                                            return working
                                        else
                                            minions[index].inventory.weight = minions[index].inventory.weight - (num - minions[index].inventory[i].num) * minions[index].inventory[i].type.weight
                                            parent:drop_new_item(minions[index].inventory[i], minions[index].position, minions[index].height_level)
                                            minions[index].inventory[i] = nil
                                            self.curr_storage_index = 1
                                            if reserved_item ~= nil then
                                                minions[index]:add_item(parent, reserved_item)
                                            end
                                            return working
                                        end
                                    else
                                        minions[index].inventory[i] = nil
                                    end
                                    if reserved_item ~= nil then
                                        minions[index]:add_item(parent, reserved_item)
                                    end
                                end
                                actual_reserved_bread = actual_reserved_bread - num
                            end
                        end
                        local desired_crop_num
                        desired_crop_num = 5
                        local num_ovens = #self.ovens
                        if num_ovens ~= 0 then
                            if num_ovens <= 4 then
                                desired_crop_num = 5 * num_ovens
                            else
                                desired_crop_num = 5 * 4
                            end
                            self.desired_crop_num = desired_crop_num
                        end
                        for i = 1, minions[index].inventory_size do
                            if minions[index].inventory[i] ~= nil and minions[index].inventory[i].type == item_type.CROP then
                                desired_crop_num = desired_crop_num - minions[index].inventory[i].num
                                if desired_crop_num <= 0 then
                                    break
                                end
                            end
                        end
                        if desired_crop_num > 0 then
                            local add_item = function(item)
                                while minions[index]:add_item(parent, item) == false do
                                    local trash
                                    local key_num = 0
                                    local key_sequence = chest.key_sequence
                                    for i = 1, minions[index].inventory_size do
                                        if minions[index].inventory[i] ~= nil and minions[index].inventory[i].type ~= item_type.CROP and minions[index].inventory[i].equipped == nil then
                                            if minions[index].inventory[i].type ~= item_type.KEY then
                                                trash = i
                                                break
                                            elseif minions[index].inventory[i].sequence ~= chest.key_sequence then
                                                trash = i
                                                break
                                            elseif minions[index].inventory[i].sequence == chest.key_sequence and key_num == 0 then
                                                key_num = key_num + 1
                                            elseif minions[index].inventory[i].sequence == chest.key_sequence and key_num ~= 0 then
                                                trash = i
                                                break
                                            end
                                        end
                                    end
                                    minions[index].inventory.weight = minions[index].inventory.weight - minions[index].inventory[trash].num * minions[index].inventory[trash].type.weight
                                    parent:drop_new_item(minions[index].inventory[trash], minions[index].position, minions[index].height_level)
                                    minions[index].inventory[trash] = nil
                                end
                            end
                            local actual_crop_num = 0
                            for i = 1, chest.inventory_size do
                                if chest.inventory[i] ~= nil and chest.inventory[i].type == item_type.CROP then
                                    if actual_crop_num + chest.inventory[i].num > desired_crop_num then
                                        local item = shallowcopy(chest.inventory[i])
                                        if item.heat_level ~= nil then
                                            parent.cool_down:add_item(item)
                                        end
                                        item.num = desired_crop_num - actual_crop_num
                                        chest.inventory[i].num = chest.inventory[i].num - (desired_crop_num - actual_crop_num)
                                        add_item(item)
                                        self.path = nil
                                        self.status = LOOKING_FOR_OVEN
                                        return working
                                    elseif actual_crop_num + chest.inventory[i].num == desired_crop_num then
                                        add_item(chest.inventory[i])
                                        chest.inventory[i] = nil
                                        self.path = nil
                                        self.status = LOOKING_FOR_OVEN
                                        return working
                                    end
                                    actual_crop_num = actual_crop_num + chest.inventory[i].num
                                    add_item(chest.inventory[i])
                                    chest.inventory[i] = nil
                                end
                            end
                            if self.curr_storage_index + 1 <= #self.storages then
                                self.path = nil
                                self.curr_storage_index = self.curr_storage_index + 1
                            else
                                self.curr_storage_index = 1
                                self.path = nil
                            end
                        else
                            self.path = nil
                            self.status = LOOKING_FOR_OVEN
                        end
                        return working
                    elseif result == -1 then
                        return working
                    else
                        return failed
                    end
                else
                    self.storages = {}
                    self.entrance_pos = cc.p(-1, -1)
                    self.path = nil
                    return failed
                end
            end
            return working
        end
        local reach_oven = function()
            if self.path == nil then
                self.path = cal_shortest_dis:new()
                self.path.points[self.path.point_index] = minions[index].position
                if #self.ovens == 0 then
                    self.ovens = structs[self.oven_index]:get_ovens(minions[index].height_level)
                    if #self.ovens == 0 then
                        self.entrance_pos = cc.p(-1, -1)
                        self.path = nil
                        return failed
                    end
                    self.curr_oven_index = 1
                end
                self.path.dest = cal_pos_blocked(self.oven_index, self.ovens[self.curr_oven_index])
            end
            if self.path:cal(minions, structs, map, index, dt) == true then
                local oven = structs[self.oven_index].ovens[minions[index].height_level][self.ovens[self.curr_oven_index].x][self.ovens[self.curr_oven_index].y]
                if oven == nil then
                    self.path = nil
                    self.ovens = {}
                    return failed
                end
                if (minions[index].right_hand ~= nil and minions[index].right_hand.item.type == item_type.TONGS) or (minions[index].left_hand ~= nil and minions[index].left_hand.item.type == item_type.TONGS) then
                    for i = 1, oven_up_cols do
                        if oven.up[i] ~= nil and oven.up[i].type == item_type.BREAD then
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
                            oven.up[i].fire_on = nil
                            add_item(oven.up[i])
                            oven.up[i] = nil
                        end
                    end
                end
                if oven.fire_on == false then
                    local fuel_dur = 0
                    for i = 1, oven_down_cols do
                        if oven.down[i] ~= nil and oven.down[i].type.burn_dur ~= nil then
                            fuel_dur = fuel_dur + oven.down[i].type.burn_dur * oven.down[i].num
                            break
                        end
                    end
                    if fuel_dur > 0 then
                        oven:ignite()
                    else
                        local fuel_dur = item_type.CROP.heat_dur
                        local remaining_slots = oven_down_cols
                        for i = 1, minions[index].inventory_size do
                            if minions[index].inventory[i] ~= nil and minions[index].inventory[i].type.burn_dur ~= nil and minions[index].inventory[i].type ~= item_type.BREAD then
                                minions[index].inventory[i].equipped = nil
                                local num = math.min(minions[index].inventory[i].num, remaining_slots)
                                if fuel_dur <= minions[index].inventory[i].type.burn_dur * num then
                                    fuel_dur = 0
                                    local num = math.min(num, math.floor(item_type.CROP.heat_dur / minions[index].inventory[i].type.burn_dur) + 1)
                                    for j = 1, num do
                                        local item = shallowcopy(minions[index].inventory[i])
                                        item.num = 1
                                        oven:add_down(item)
                                    end
                                    minions[index].inventory[i].num = minions[index].inventory[i].num - num
                                    minions[index].inventory.weight = minions[index].inventory.weight - num * minions[index].inventory[i].type.weight
                                    if minions[index].inventory[i].num <= 0 then
                                        minions[index].inventory[i] = nil
                                    end
                                else
                                    if num < remaining_slots then
                                        for j = 1, num do
                                            local item = shallowcopy(minions[index].inventory[i])
                                            item.num = 1
                                            oven:add_down(item)
                                        end
                                        fuel_dur = fuel_dur - minions[index].inventory[i].type.burn_dur * num
                                        remaining_slots = remaining_slots - num
                                        minions[index].inventory.weight = minions[index].inventory.weight - num * minions[index].inventory[i].type.weight
                                        minions[index].inventory[i] = nil
                                    end
                                end
                            end
                        end
                        if fuel_dur > 0 then
                            self.desired_crop_num = math.floor(item_type.CROP.heat_dur / item_type.CROP.burn_dur) + 1
                            self.path = nil
                            self.status = LOOKING_FOR_WHEAT
                        end
                        oven:ignite()
                    end
                end
                if oven.fire_on == true then
                    local blocked_slots = 0
                    local desired_crop_num = 3
                    if (minions[index].right_hand ~= nil and minions[index].right_hand.item.type == item_type.TONGS) or (minions[index].left_hand ~= nil and minions[index].left_hand.item.type == item_type.TONGS) then
                        for i = 1, oven_up_cols do
                            if oven.up[i] ~= nil and oven.up[i].type == item_type.CROP then
                                desired_crop_num = desired_crop_num - oven.up[i].num
                                if desired_crop_num <= 0 then
                                    break
                                end
                            elseif oven.up[i] ~= nil and oven.up[i].type ~= item_type.CROP then
                                oven.up[i].fire_on = nil
                                if minions[index]:add_item(parent, oven.up[i]) == false then
                                    parent:drop_new_item(oven.up[i], minions[index].position, minions[index].height_level)
                                end
                                oven.up[i] = nil
                            end
                        end
                    end
                    if desired_crop_num > 0 then
                        local temp_crop_num = desired_crop_num
                        for i = 1, minions[index].inventory_size do
                            if minions[index].inventory[i] ~= nil and minions[index].inventory[i].type == item_type.CROP then
                                desired_crop_num = desired_crop_num - minions[index].inventory[i].num
                                if desired_crop_num <= 0 then
                                    break
                                end
                            end
                        end
                        if desired_crop_num <= 0 then
                            local desired_crop_num = temp_crop_num
                            for i = 1, minions[index].inventory_size do
                                if minions[index].inventory[i] ~= nil and minions[index].inventory[i].type == item_type.CROP then
                                    minions[index].inventory[i].equipped = nil
                                    if desired_crop_num - minions[index].inventory[i].num <= 0 then
                                        local num = desired_crop_num
                                        for j = 1, num do
                                            local item = shallowcopy(minions[index].inventory[i])
                                            item.num = 1
                                            oven:add_up(item)
                                        end
                                        minions[index].inventory[i].num = minions[index].inventory[i].num - num
                                        minions[index].inventory.weight = minions[index].inventory.weight - num * minions[index].inventory[i].type.weight
                                        if minions[index].inventory[i].num <= 0 then
                                            minions[index].inventory[i] = nil
                                        end
                                        break
                                    else
                                        local num = minions[index].inventory[i].num
                                        for j = 1, num do
                                            local item = shallowcopy(minions[index].inventory[i])
                                            item.num = 1
                                            oven:add_up(item)
                                        end
                                        desired_crop_num = desired_crop_num - minions[index].inventory[i].num
                                        minions[index].inventory.weight = minions[index].inventory.weight - num * minions[index].inventory[i].type.weight
                                        minions[index].inventory[i] = nil
                                    end
                                end
                            end
                        else
                            --release_print(self.status..":"..self.curr_oven_index..":"..desired_crop_num)
                            self.desired_crop_num = desired_crop_num
                            self.path = nil
                            self.status = LOOKING_FOR_WHEAT
                            return working
                        end
                    end
                    if self.curr_oven_index + 1 <= #self.ovens then
                        self.path = nil
                        self.curr_oven_index = self.curr_oven_index + 1
                    else
                        self.path = nil
                        self.curr_oven_index = 1
                    end
                end
                return working
            end
            return working
        end
        local reach_function = nil
        local target_index = -1
        local target_level = -1
        if self.status == LOOKING_FOR_WHEAT then
            target_index = self.storage_index
            target_level = self.storage_level
            reach_function = reach_wheat_storage
        else
            target_index = self.oven_index
            target_level = self.oven_level
            reach_function = reach_oven
        end
        if target_index == -1 or target_level == -1 or reach_function == nil then
            self.entrance_pos = cc.p(-1, -1)
            self.path = nil
            return failed
        end
        local i = minions[index].position.x / 50.0
        local j = minions[index].position.y / 50.0
        i = math.floor(i) + 1
        j = math.floor(j) + 1
        local struct_index = map[i][j]
        if (struct_index ~= target_index and minions[index].height_level ~= 0) or minions[index].height_level > target_level then
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
                if check_door(target_index) == true then
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
        if (minions[index].height_level < target_level and struct_index == target_index) or minions[index].height_level == 0 then
            if self.path == nil then
                self.path = cal_shortest_dis:new()
                self.path.points[self.path.point_index] = minions[index].position
            end
            if self.entrance_pos.x == -1 or self.entrance_pos.y == -1 then
                self.entrance_pos = structs[target_index]:get_entrance(minions[index].height_level, minions[index].position)
            end
            local x = structs[target_index].position.x + self.entrance_pos.x * structs[target_index].tile.x + 2.0
            local y = structs[target_index].position.y + (structs[target_index].map.y - self.entrance_pos.y - 1) * structs[target_index].tile.y
            local tile = cc.p(structs[target_index].tile.x - 6.0, structs[target_index].tile.y - 2.0)
            self.path.dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), tile)
            if self.path:cal(minions, structs, map, index, dt) == true then
                if check_door(target_index) == true then
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
        if minions[index].height_level == target_level and struct_index == target_index then
            return reach_function()
        end
        return working
    end,
    reset = function(self)
        self.status = LOOKING_FOR_WHEAT
        self.entrance_pos = cc.p(-1, -1)
        self.path = nil
    end
}

function baker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.task_name = -1
    o.task_index = -1
    o.status = LOOKING_FOR_WHEAT
    o.desired_crop_num = -1
    o.oven_index = 0
    o.oven_level = 0
    o.storage_index = 0
    o.storage_level = 0
    o.ovens = {}
    o.curr_oven_index = 0
    o.storages = {}
    o.curr_storage_index = 0
    o.entrance_pos = cc.p(-1, -1)
    o.path = nil
    o.reserved_bread = 1
    return o
end

return baker
