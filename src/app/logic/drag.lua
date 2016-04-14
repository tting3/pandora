--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 3/17/2016
-- Time: 7:38 AM
-- To change this template use File | Settings | File Templates.
--

local counter = 0
local font = require("app.views.font")

local check_chain_block = function(dragged_one, target, height_level, structs, map, speed)
    local point
    local point_height_level
    if #(dragged_one.chain_points) == 0 then
        point = dragged_one.position
        point_height_level = dragged_one.height_level
    else
        point = dragged_one.chain_points[#(dragged_one.chain_points)]
        point_height_level = dragged_one.chain_points_height[#(dragged_one.chain_points)]
    end
    if point_height_level ~= height_level then
        local function cal_pos_with_index(target_pos, tile, size)
            local x, y
            if point.x >= target_pos.x and point.x < target_pos.x + size.x * tile.x then
                x = point.x
            end
            if point.x < target_pos.x then
                x = target_pos.x
            end
            if point.x >= target_pos.x + size.x * tile.x then
                x = target_pos.x + size.x * tile.x
            end
            if point.y >= target_pos.y and point.y < target_pos.y + size.y * tile.y then
                y = point.y
            end
            if point.y < target_pos.y then
                y = target_pos.y
            end
            if point.y >= target_pos.y + size.y * tile.y then
                y = target_pos.y + size.y * tile.y
            end
            return cc.p(x, y)
        end
        local i = target.x / 50.0
        local j = target.y / 50.0
        i = math.floor(i) + 1
        j = math.floor(j) + 1
        local ii = map[i][j]
        if ii == 0 then
            i = point.x / 50.0
            j = point.y / 50.0
            i = math.floor(i) + 1
            j = math.floor(j) + 1
            ii = map[i][j]
        end
        local entrance_pos
        if point_height_level < height_level then
            entrance_pos = structs[ii]:get_entrance(point_height_level, target)
        else
            entrance_pos = structs[ii]:get_exit(point_height_level, target)
        end
        local x = structs[ii].position.x + entrance_pos.x * structs[ii].tile.x + 2.0
        local y = structs[ii].position.y + (structs[ii].map.y - entrance_pos.y - 1) * structs[ii].tile.y
        local tile = cc.p(structs[ii].tile.x - 6.0, structs[ii].tile.y - 2.0)
        local dest = cal_pos_with_index(cc.p(x, y), cc.p(1, 1), tile)
        dragged_one.chain_points[#(dragged_one.chain_points) + 1] = dest
        dragged_one.chain_points_height[#(dragged_one.chain_points_height) + 1] = height_level
        return false
    end
    local k,b
    if target.x ~= point.x and target.y ~= point.y then
        k = (target.y - point.y)/(target.x - point.x)
    elseif target.y ~= point.y then
        k = (target.y - point.y)/(0.001)
    else
        k = 0.001
    end
    b = target.y - k * target.x
    local target_i = target.x / 50.0
    local target_j = target.y / 50.0
    target_i = math.floor(target_i) + 1
    target_j = math.floor(target_j) + 1
    local i = point.x / 50.0
    local j = point.y / 50.0
    i = math.floor(i) + 1
    j = math.floor(j) + 1
    local x_dir = 0
    local y_dir = 0
    if target_i > i then
        x_dir = 1
    elseif target_i < i then
        x_dir = -1
    end
    if target_j > j then
        y_dir = 1
    elseif target_j < j then
        y_dir = -1
    end
    while target_i ~= i or target_j ~= j do
        local temp_flag = 0
        local temp_i, temp_i_x, temp_i_y, temp_j, temp_j_y, temp_j_x
        if (x_dir > 0 and i + x_dir <= target_i) or (x_dir < 0 and i + x_dir >= target_i) then
            temp_i = i + x_dir
            if x_dir > 0 then
                temp_i_x = (temp_i - 1) * 50
            else
                temp_i_x = (temp_i) * 50
            end
            temp_i_y = k * temp_i_x + b
        else
            temp_i = target_i
            j = target_j
            temp_i_x = target.x
            temp_i_y = target.y
        end
        if (y_dir > 0 and j + y_dir <= target_j) or (y_dir < 0 and j + y_dir >= target_j) then
            temp_j = j + y_dir
            if y_dir > 0 then
                temp_j_y = (temp_j - 1) * 50
            else
                temp_j_y = (temp_j) * 50
            end
            temp_j_x = (temp_j_y - b) / k
        else
            i = target_i
            temp_j = target_j
            temp_j_x = target.x
            temp_j_y = target.y
        end
        if counter < 10 then
            if counter == 0 then
                --release_print(x_dir.." "..y_dir)
            end
            --release_print(counter)
            --release_print("target_i "..target_i.."target_j "..target_j.."i "..i.."j "..j)
            counter  = counter + 1
        end
        local dis_i = (temp_i_x - point.x) * (temp_i_x - point.x) + (temp_i_y - point.y) * (temp_i_y - point.y)
        local dis_j = (temp_j_x - point.x) * (temp_j_x - point.x) + (temp_j_y - point.y) * (temp_j_y - point.y)
        local x, y
        if dis_i < dis_j then
            temp_flag = 0
            i = temp_i
            x = temp_i_x
            y = temp_i_y
        elseif dis_i > dis_j then
            temp_flag = 1
            j = temp_j
            x = temp_j_x
            y = temp_j_y
        else
            i = temp_i
            j = temp_j
            x = temp_i_x
            y = temp_i_y
        end
        local ii = map[i][j]
        if ii > 0 then
            local struct = structs[ii]
            local level = nil
            if height_level == 0 and struct.walls ~= nil then
                level = struct.walls
            end
            if height_level == 1 and struct.room1 ~= nil then
                level = struct.room1
            end
            if height_level == 2 and struct.room2 ~= nil then
                level = struct.room2
            end
            if height_level == 3 and struct.room3 ~= nil then
                level = struct.room3
            end
            if level ~= nil then
                local layer = level:layerNamed("collision")
                local function check(check_i, check_j)
                    local i =  ((check_i - 1) * 50 - struct.position.x) / struct.tile.x
                    local j =  (struct.position.y + struct.map.y * struct.tile.y - (check_j) * 50) / struct.tile.y
                    i = math.floor(i)
                    j = math.floor(j)
                    if i >= 0 and i < struct.map.x and j >= 0 and j < struct.map.y then
                        local gid = layer:tileGIDAt(cc.p(i, j))
                        local property = level:propertiesForGID(gid)
                        if property ~= 0 and property ~= 4 and property ~= 6 and property ~= 5 and property ~= 7 then
                            return false
                        end
                        return true
                    end
                    return true
                end
                if check(i, j) == false then
                    local temp_i2 = i
                    local temp_j2 = j
                    if x % 50 == 0 then
                        if y_dir >= 0 then
                            while check(temp_i2, temp_j2) == false do
                                temp_j2 = temp_j2 + 1
                            end
                            j = temp_j2 - 1
                        else
                            while check(temp_i2, temp_j2) == false do
                                temp_j2 = temp_j2 - 1
                            end
                            j = temp_j2 + 1
                        end
                    else
                        if x_dir >= 0 then
                            while check(temp_i2, temp_j2) == false do
                                temp_i2 = temp_i2 + 1
                            end
                            i = temp_i2 - 1
                        else
                            while check(temp_i2, temp_j2) == false do
                                temp_i2 = temp_i2 - 1
                            end
                            i = temp_i2 + 1
                        end
                    end
                    if x_dir >= 0 and y_dir >= 0 then
                        if x % 50 == 0 then
                            dragged_one.chain_points[#(dragged_one.chain_points) + 1] = cc.p((i - 1) * 50 - speed, (j) * 50 + speed)
                        else
                            dragged_one.chain_points[#(dragged_one.chain_points) + 1] = cc.p((i) * 50 + speed, (j - 1) * 50 - speed)
                        end
                    elseif x_dir >= 0 and y_dir < 0 then
                        if x % 50 == 0 then
                            dragged_one.chain_points[#(dragged_one.chain_points) + 1] = cc.p((i - 1) * 50 - speed, (j - 1) * 50 - speed)
                        else
                            dragged_one.chain_points[#(dragged_one.chain_points) + 1] = cc.p((i) * 50 + speed, (j) * 50)
                        end
                    elseif x_dir < 0 and y_dir >= 0 then
                        if x % 50 == 0 then
                            dragged_one.chain_points[#(dragged_one.chain_points) + 1] = cc.p((i) * 50 + speed, (j) * 50 + speed)
                        else
                            dragged_one.chain_points[#(dragged_one.chain_points) + 1] = cc.p((i - 1) * 50 - speed, (j - 1) * 50 - speed)
                        end
                    elseif x_dir < 0 and y_dir < 0 then
                        if x % 50 == 0 then
                            dragged_one.chain_points[#(dragged_one.chain_points) + 1] = cc.p((i) * 50 + speed, (j - 1) * 50 - speed)
                        else
                            dragged_one.chain_points[#(dragged_one.chain_points) + 1] = cc.p((i - 1) * 50 - speed, (j) * 50 + speed)
                        end
                    end
                    dragged_one.chain_points_height[#(dragged_one.chain_points_height) + 1] = height_level
                    return false
                end
            end
        end
    end
    return true
end

local draw_rope = function(m_character_p, dragged_one, dragging_one)
    dragged_one.rope_node:clear()
    dragged_one.rope_body_node:clear()
    if #(dragged_one.chain_points) > 0 then
        for i, point in pairs(dragged_one.chain_points) do
            local point1
            local height
            if i == 1 then
                point1 = dragged_one.position
                height = dragged_one.height_level
            else
                point1 = dragged_one.chain_points[i - 1]
                height = dragged_one.chain_points_height[i - 1]
            end
            if height == dragging_one.height_level or height == 0 then
                dragged_one.rope_node:drawLine(cc.p(point1.x - m_character_p.x - 1 + display.cx, point1.y - m_character_p.y + display.cy), cc.p(point.x - m_character_p.x - 1 + display.cx, point.y - m_character_p.y + display.cy), font.ROPE)
                dragged_one.rope_node:drawLine(cc.p(point1.x - m_character_p.x + display.cx, point1.y - m_character_p.y + display.cy), cc.p(point.x - m_character_p.x + display.cx, point.y - m_character_p.y + display.cy), font.ROPE)
                dragged_one.rope_node:drawLine(cc.p(point1.x - m_character_p.x + display.cx, point1.y - m_character_p.y - 1 + display.cy), cc.p(point.x - m_character_p.x + display.cx, point.y - m_character_p.y - 1 + display.cy), font.ROPE)
            end
        end
        local point = dragged_one.chain_points[#dragged_one.chain_points]
        dragged_one.rope_node:drawLine(cc.p(point.x - m_character_p.x - 1 + display.cx, point.y - m_character_p.y + display.cy), cc.p(dragging_one.position.x - m_character_p.x - 1 + display.cx, dragging_one.position.y - m_character_p.y + display.cy), font.ROPE)
        dragged_one.rope_node:drawLine(cc.p(point.x - m_character_p.x + display.cx, point.y - m_character_p.y + display.cy), cc.p(dragging_one.position.x - m_character_p.x + display.cx, dragging_one.position.y - m_character_p.y + display.cy), font.ROPE)
        dragged_one.rope_node:drawLine(cc.p(point.x - m_character_p.x + display.cx, point.y - m_character_p.y - 1 + display.cy), cc.p(dragging_one.position.x - m_character_p.x + display.cx, dragging_one.position.y - m_character_p.y - 1 + display.cy), font.ROPE)
    else
        dragged_one.rope_node:drawLine(cc.p(dragged_one.position.x - m_character_p.x - 1 + display.cx, dragged_one.position.y - m_character_p.y + display.cy), cc.p(dragging_one.position.x - m_character_p.x - 1 + display.cx, dragging_one.position.y - m_character_p.y + display.cy), font.ROPE)
        dragged_one.rope_node:drawLine(cc.p(dragged_one.position.x - m_character_p.x + display.cx, dragged_one.position.y - m_character_p.y + display.cy), cc.p(dragging_one.position.x - m_character_p.x + display.cx, dragging_one.position.y - m_character_p.y + display.cy), font.ROPE)
        dragged_one.rope_node:drawLine(cc.p(dragged_one.position.x - m_character_p.x + display.cx, dragged_one.position.y - m_character_p.y - 1 + display.cy), cc.p(dragging_one.position.x - m_character_p.x + display.cx, dragging_one.position.y - m_character_p.y - 1 + display.cy), font.ROPE)
    end
    if dragged_one.height_level == dragging_one.height_level or dragged_one.height_level == 0 then
        dragged_one.rope_body_node:drawLine(cc.p(dragged_one.position.x - m_character_p.x - 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 9.0 + display.cy), cc.p(dragged_one.position.x- m_character_p.x + 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 9.0 + display.cy), font.ROPE)
        dragged_one.rope_body_node:drawLine(cc.p(dragged_one.position.x - m_character_p.x - 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 8.0 + display.cy), cc.p(dragged_one.position.x- m_character_p.x + 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 8.0 + display.cy), font.ROPE)
        dragged_one.rope_body_node:drawLine(cc.p(dragged_one.position.x - m_character_p.x - 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 12.0 + display.cy), cc.p(dragged_one.position.x- m_character_p.x + 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 12.0 + display.cy), font.ROPE)
        dragged_one.rope_body_node:drawLine(cc.p(dragged_one.position.x - m_character_p.x - 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 13.0 + display.cy), cc.p(dragged_one.position.x- m_character_p.x + 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 13.0 + display.cy), font.ROPE)
        dragged_one.rope_body_node:drawLine(cc.p(dragged_one.position.x - m_character_p.x - 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 16.0 + display.cy), cc.p(dragged_one.position.x- m_character_p.x + 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 16.0 + display.cy), font.ROPE)
        dragged_one.rope_body_node:drawLine(cc.p(dragged_one.position.x - m_character_p.x - 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 17.0 + display.cy), cc.p(dragged_one.position.x- m_character_p.x + 13.0 + display.cx, dragged_one.position.y - m_character_p.y + 17.0 + display.cy), font.ROPE)
        if dragged_one.position.y - m_character_p.y ~= 0 then
            dragged_one.rope_body_node:setZOrder(math.floor(display.top - (dragged_one.position.y - m_character_p.y + display.cy - 1.0)))
        else
            dragged_one.rope_body_node:setZOrder(display.cy + 1)
        end
    end
end

local drag = function(m_character_p, dragged_one, dragging_one, structs, map, drag_dis, speed)
    counter = 0
    if #(dragged_one.chain_points) > 0 then
        local check_dragged_one = {}
        if #(dragged_one.chain_points) > 1 then
            check_dragged_one.position = dragged_one.chain_points[#(dragged_one.chain_points) - 1]
            check_dragged_one.height_level = dragged_one.chain_points_height[#(dragged_one.chain_points) - 1]
        else
            check_dragged_one.position = dragged_one.position
            check_dragged_one.height_level = dragged_one.height_level
        end
        check_dragged_one.chain_points_height = {}
        check_dragged_one.chain_points = {}
        if check_dragged_one.height_level == dragging_one.height_level and check_chain_block(check_dragged_one, dragging_one.position, dragging_one.height_level, structs, map, speed) == true then
            dragged_one.chain_points[#(dragged_one.chain_points)] = nil
            dragged_one.chain_points_height[#(dragged_one.chain_points_height)] = nil
        end
    end
    while check_chain_block(dragged_one, dragging_one.position, dragging_one.height_level, structs, map, speed) == false do
    end
    local dis = 0
    if #(dragged_one.chain_points) > 0 then
        for i, point in pairs(dragged_one.chain_points) do
            local point1
            if i == 1 then
                point1 = dragged_one.position
            else
                point1 = dragged_one.chain_points[i - 1]
            end
            local temp_dis = (point1.x - point.x) * (point1.x - point.x) + (point1.y - point.y) * (point1.y - point.y)
            dis = dis + math.sqrt(temp_dis)
        end
        local point = dragged_one.chain_points[#dragged_one.chain_points]
        local temp_dis = (point.x - dragging_one.position.x) * (point.x - dragging_one.position.x) + (point.y - dragging_one.position.y) * (point.y - dragging_one.position.y)
        dis = dis + math.sqrt(temp_dis)
    else
        dis = (dragged_one.position.x - dragging_one.position.x) * (dragged_one.position.x - dragging_one.position.x) + (dragged_one.position.y - dragging_one.position.y) * (dragged_one.position.y - dragging_one.position.y)
        dis = math.sqrt(dis)
    end
    dragged_one.chain_blocked = false
    if dis > drag_dis then
        local target
        if #(dragged_one.chain_points) > 0 then
            target = dragged_one.chain_points[1]
        else
            target = dragging_one.position
        end
        local temp_dis = (target.x - dragged_one.position.x) * (target.x - dragged_one.position.x) + (target.y - dragged_one.position.y) * (target.y - dragged_one.position.y)
        temp_dis = math.sqrt(temp_dis)
        if temp_dis <= speed then
            dragged_one:update_position(target.x - dragged_one.position.x, target.y - dragged_one.position.y)
            dragged_one.height_level = dragged_one.chain_points_height[#(dragged_one.chain_points_height)]
            local num = #(dragged_one.chain_points)
            for i, point in pairs(dragged_one.chain_points) do
                if i < num then
                    dragged_one.chain_points[i] = dragged_one.chain_points[i + 1]
                    dragged_one.chain_points_height[i] = dragged_one.chain_points_height[i + 1]
                else
                    dragged_one.chain_points[i] = nil
                    dragged_one.chain_points_height[i] = nil
                end
            end
        else
            local new_x = speed * (target.x - dragged_one.position.x) / temp_dis
            local new_y = speed * (target.y - dragged_one.position.y) / temp_dis
            dragged_one:update_position(new_x, new_y)
        end
    end
    if dragged_one.sprite ~= nil and dragging_one.sprite ~= nil then
        draw_rope(m_character_p, dragged_one, dragging_one)
    end
end

return drag
