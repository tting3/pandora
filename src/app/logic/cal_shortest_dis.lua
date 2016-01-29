--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/8/2016
-- Time: 1:17 PM
-- To change this template use File | Settings | File Templates.
--

local DOWN = 0
local LEFT = 1
local RIGHT = 2
local UP = 3
local CLOCK = 0
local C_CLOCK = 1
local speed = 2.0
local fixedDeltaTimeScale = 60.0

local cal_shortest_dis_new = {
    points = {},
    points_valid = {},
    point_index = 1,
    direction = -1,
    pos_dir = -1,
    dest_i = -1,
    dest_j = -1,
    dest = cc.p(0.0, 0.0),
    cal = function(self, minions, structs, map, index, dt)
        local x = self.dest.x - minions[index].position.x
        local y = self.dest.y - minions[index].position.y
        local root = math.sqrt(x * x + y * y)
        if root < 2.0 then
            if minions[index].position.x ~= self.points[self.point_index].x or minions[index].position.y ~= self.points[self.point_index].y then
                self.points[self.point_index + 1] = minions[index].position
                self.points_valid[self.point_index] = true
                --minions[index]:set_name(table.getn(self.points).."", 0.0)
            end
            return true
        end
        local function dis(local_dest)
            local x = local_dest.x - minions[index].position.x
            local y = local_dest.y - minions[index].position.y
            --[[
            local new_x = speed * x / root
            local new_y = speed * y / root
            ]]
            local new_x = 0.0
            local new_y = 0.0
            if (math.abs(x) < math.abs(y) and math.abs(x) > 2.0) or math.abs(y) < 2.0 then
                if x > 0.0 then
                    new_x = speed
                else
                    new_x = 0.0 - speed
                end
                new_y = 0.0
            else
                if y > 0.0 then
                    new_y = speed
                else
                    new_y = 0.0 - speed
                end
            end
            if new_x > 0 then
                minions[index].dir = RIGHT
            end
            if new_x < 0 then
                minions[index].dir = LEFT
            end
            if new_y > 0 then
                minions[index].dir = UP
            end
            if new_y < 0 then
                minions[index].dir = DOWN
            end
            if minions[index].dir ~= minions[index].last_act then
                minions[index].animated = false
            end
            minions[index].last_act = minions[index].dir
            return new_x, new_y
        end
        if self.points_valid[self.point_index] == true then
            --minions[index]:set_name(table.getn(self.points).."", 0.0)
            local new_x, new_y = dis(self.points[self.point_index + 1])
            --minions[index]:set_name(self.points[self.point_index + 1].x.." "..self.points[self.point_index + 1].y, 1.0)
            --minions[index]:set_name(minions[index].position.x.." "..minions[index].position.y, 1.0)
            --minions[index]:set_name(new_x.." "..new_y, 0.0)
            if minions[index]:check_move(new_x, new_y, structs, map) == true then
                minions[index]:update_position(new_x, new_y)
                local x = self.points[self.point_index + 1].x - minions[index].position.x
                local y = self.points[self.point_index + 1].y - minions[index].position.y
                local root = math.sqrt(x * x + y * y)
                if root < 2.0 then
                    self.point_index  = self.point_index + 1
                    --minions[index]:set_name(table.getn(self.points).."", 0.0)
                end
            else
                --minions[index]:set_name("here", 0.0)
                --minions[index]:set_name(self.pos_dir.."", 0.0)
                self.points_valid[self.point_index] = false
            end
        else
            local new_x, new_y = dis(self.dest)
            if minions[index]:check_move(new_x, new_y, structs, map) == true then
                minions[index]:update_position(new_x, new_y)
            else
                if minions[index].position.x ~= self.points[self.point_index].x or minions[index].position.y ~= self.points[self.point_index].y then
                    self.points[self.point_index + 1] = minions[index].position
                    self.points_valid[self.point_index] = false
                    self.point_index  = self.point_index + 1
                end
                local i = (minions[index].position.x + new_x) / 50.0
                local j = (minions[index].position.y + new_y) / 50.0
                i = math.floor(i) + 1
                j = math.floor(j) + 1
                local ii = map[i][j]
                local struct = structs[ii]
                local level = nil
                if minions[index].height_level == 0 and struct.walls ~= nil  then
                    level = struct.walls
                end
                if minions[index].height_level == 1 and struct.room1 ~= nil then
                    level = struct.room1
                    --minions[index]:set_name("room1")
                end
                if minions[index].height_level == 2 and struct.room2 ~= nil  then
                    level = struct.room2
                end
                if minions[index].height_level == 3 and struct.room3 ~= nil  then
                    level = struct.room3
                end
                if level ~= nil then
                    local layer = level:layerNamed("collision")
                    local i =  (minions[index].position.x + new_x - struct.position.x) / struct.tile.x
                    local j =  (struct.position.y + struct.map.y * struct.tile.y - minions[index].position.y - new_y) / struct.tile.y
                    i = math.floor(i)
                    j = math.floor(j)
                    minions[index].last_act = minions[index].dir
                    if self.direction == -1 then
                        self.pos_dir = -1
                        if new_x > 0 then
                            self.pos_dir = LEFT
                        end
                        if new_x < 0 then
                            self.pos_dir = RIGHT
                        end
                        if new_y > 0 then
                            self.pos_dir = DOWN
                        end
                        if new_y < 0 then
                            self.pos_dir = UP
                        end
                        if minions[index].height_level == 0 then
                            if self.dest.x < struct.position.x + struct.map.x * struct.tile.x and self.dest.x >= struct.position.x and
                                    self.dest.y < struct.position.y + struct.map.y * struct.tile.y and self.dest.y >= struct.position.y then
                                self.dest_i = math.floor((self.dest.x - struct.position.x) / struct.tile.x)
                                self.dest_j = struct.map.y - 1 - math.floor((self.dest.y - struct.position.y) / struct.tile.y)
                                if self.dest_i < i and self.dest_j < j then
                                    if struct.position.x + struct.map.x * struct.tile.x - minions[index].position.x >= minions[index].position.y - struct.position.y then
                                        self.direction = CLOCK
                                    else
                                        self.direction = C_CLOCK
                                    end
                                end
                                if self.dest_i >= i and self.dest_j < j then
                                    if minions[index].position.x - struct.position.x >= minions[index].position.y - struct.position.y then
                                        self.direction = C_CLOCK
                                    else
                                        self.direction = CLOCK
                                    end
                                end
                                if self.dest_i < i and self.dest_j >= j then
                                    if struct.position.x + struct.map.x * struct.tile.x - minions[index].position.x >= struct.position.y + struct.map.y * struct.tile.y - minions[index].position.y then
                                        self.direction = C_CLOCK
                                    else
                                        self.direction = CLOCK
                                    end
                                end
                                if self.dest_i >= i and self.dest_j >= j then
                                    if minions[index].position.x - struct.position.x >= struct.position.y + struct.map.y * struct.tile.y - minions[index].position.y then
                                        self.direction = CLOCK
                                    else
                                        self.direction = C_CLOCK
                                    end
                                end
                                --minions[index]:set_name(self.dest_i..""..self.dest_j, 0.0)
                            else
                                self.dest_i = 0
                                self.dest_j = struct.map.y - 1
                                if self.dest.x < struct.position.x + struct.map.x * struct.tile.x and self.dest.x >= struct.position.x then
                                    if minions[index].position.x > struct.position.x + struct.map.x * struct.tile.x / 2 then
                                        self.dest_i = struct.map.x - 1
                                    end
                                else
                                    if self.dest.x > struct.position.x + struct.map.x then
                                        self.dest_i = struct.map.x - 1
                                    end
                                end
                                if self.dest.y < struct.position.y + struct.map.y * struct.tile.y and self.dest.y >= struct.position.y then
                                    if minions[index].position.y > struct.position.y + struct.map.y * struct.tile.x / 2 then
                                        self.dest_j = 0
                                    end
                                else
                                    if self.dest.y > struct.position.y + struct.map.y then
                                        self.dest_j = 0
                                    end
                                end
                                if self.dest_i == 0 and self.dest_j == 0 then
                                    if struct.position.x + struct.map.x * struct.tile.x - minions[index].position.x >= minions[index].position.y - struct.position.y then
                                        self.direction = CLOCK
                                    else
                                        self.direction = C_CLOCK
                                    end
                                end
                                if self.dest_i ~= 0 and self.dest_j == 0 then
                                    if minions[index].position.x - struct.position.x >= minions[index].position.y - struct.position.y then
                                        self.direction = C_CLOCK
                                    else
                                        self.direction = CLOCK
                                    end
                                end
                                if self.dest_i == 0 and self.dest_j ~= 0 then
                                    if struct.position.x + struct.map.x * struct.tile.x - minions[index].position.x >= struct.position.y + struct.map.y * struct.tile.y - minions[index].position.y then
                                        self.direction = C_CLOCK
                                    else
                                        self.direction = CLOCK
                                    end
                                end
                                if self.dest_i ~= 0 and self.dest_j ~= 0 then
                                    if minions[index].position.x - struct.position.x >= struct.position.y + struct.map.y * struct.tile.y - minions[index].position.y then
                                        self.direction = CLOCK
                                    else
                                        self.direction = C_CLOCK
                                    end
                                end
                            end
                        else
                            self.dest_i = math.floor((self.dest.x - struct.position.x) / struct.tile.x)
                            self.dest_j = struct.map.y - 1 - math.floor((self.dest.y - struct.position.y) / struct.tile.y)
                            if self.pos_dir == LEFT then
                                if j <= self.dest_j then
                                    self.direction = C_CLOCK
                                else
                                    self.direction = CLOCK
                                end
                            elseif self.pos_dir == RIGHT then
                                if j <= self.dest_j then
                                    self.direction = CLOCK
                                else
                                    self.direction = C_CLOCK
                                end
                            elseif self.pos_dir == DOWN then
                                if i <= self.dest_i then
                                    self.direction = C_CLOCK
                                else
                                    self.direction = CLOCK
                                end
                            elseif self.pos_dir == UP then
                                if i <= self.dest_i then
                                    self.direction = CLOCK
                                else
                                    self.direction = C_CLOCK
                                end
                            end
                        end
                    end
                    --minions[index]:set_name(self.direction.."", -10.0)
                    local function find_points(i, j, point_index)
                        --minions[index]:set_name(table.getn(self.points).."", 0.0)
                        local function check(i, j)
                            if i >= 0 and j >= 0 and i < struct.map.x and j < struct.map.y then
                                local gid = layer:tileGIDAt(cc.p(i, j))
                                local property = level:propertiesForGID(gid)
                                if property ~= 0 and property ~= 4 then
                                    return false
                                end
                            end
                            return true
                        end
                        local start_check = true
                        local next_i = i
                        local next_j = j
                        if i > self.dest_i then
                            next_i = i - 1
                        end
                        if i < self.dest_i then
                            next_i = i + 1
                        end
                        if j > self.dest_j then
                            next_j = j - 1
                        end
                        if j < self.dest_j then
                            next_j = j + 1
                        end
                        if next_i == i then
                            start_check = check(i, next_j)
                        elseif next_j == j then
                            start_check = check(next_i, j)
                        else
                            start_check = check(next_i, j) and check(i, next_j) and check(next_i, next_j)
                        end
                        local okay_to_go = false
                        if self.pos_dir == DOWN then
                            if j == self.dest_j and (i == self.dest_i - 1 or i == self.dest_i + 1) then
                                okay_to_go = check(self.dest_i, j + 1)
                            end
                        elseif self.pos_dir == LEFT then
                            if i == self.dest_i and (j == self.dest_j - 1 or j == self.dest_j + 1) then
                                okay_to_go = check(i - 1, self.dest_j)
                            end
                        elseif self.pos_dir == UP then
                            if j == self.dest_j and (i == self.dest_i - 1 or i == self.dest_i + 1) then
                                okay_to_go = check(self.dest_i, j - 1)
                            end
                        elseif self.pos_dir == RIGHT then
                            if i == self.dest_i and (j == self.dest_j - 1 or j == self.dest_j + 1) then
                                okay_to_go = check(i + 1, self.dest_j)
                            end
                        end
                        if start_check == true then
                            --minions[index]:set_name(i..""..j, 0.0)
                            --minions[index]:set_name(table.getn(self.points).."", 0.0)
                            if self.direction == CLOCK then
                                if self.pos_dir == DOWN then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y)
                                end
                                if self.pos_dir == LEFT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                end
                                if self.pos_dir == UP then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                end
                                if self.pos_dir == RIGHT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - 2.0)
                                end
                            elseif self.direction == C_CLOCK then
                                if self.pos_dir == DOWN then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y)
                                end
                                if self.pos_dir == LEFT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - j - 1) * struct.tile.y - 2.0)
                                end
                                if self.pos_dir == UP then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                end
                                if self.pos_dir == RIGHT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                end
                            end
                            self.points_valid[point_index] = true
                            if minions[index].height_level ~= 0 then
                                self.points[point_index + 2] = self.dest
                                self.points_valid[point_index + 1] = true
                            end
                            self.direction = -1
                            return
                        end
                        if okay_to_go == true then
                            --minions[index]:set_name(table.getn(self.points).."", 0.0)
                            if self.direction == CLOCK then
                                if self.pos_dir == DOWN then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y)
                                end
                                if self.pos_dir == LEFT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                end
                                if self.pos_dir == UP then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                end
                                if self.pos_dir == RIGHT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - 2.0)
                                end
                            elseif self.direction == C_CLOCK then
                                if self.pos_dir == DOWN then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y)
                                end
                                if self.pos_dir == LEFT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - j - 1) * struct.tile.y - 2.0)
                                end
                                if self.pos_dir == UP then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                end
                                if self.pos_dir == RIGHT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                end
                            end
                            self.points[point_index + 2] = self.dest
                            self.points_valid[point_index + 1] = true
                            self.direction = -1
                            return
                        end
                        if self.direction == CLOCK then
                            --minions[index]:set_name("CLOCK", 0.0)
                            --minions[index]:set_name(self.pos_dir.."", -3.0)
                            if self.pos_dir == DOWN then
                                --minions[index]:set_name("DOWN", 0.0)
                                if check(i - 1, j + 1) then
                                    if check(i - 1, j) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y)
                                        self.points_valid[point_index] = true
                                        self.pos_dir = LEFT
                                        --minions[index]:set_name(minions[index].position.x.."", 0.0)
                                        find_points(i, j, point_index + 1)
                                        return
                                    else
                                        find_points(i - 1, j, point_index)
                                        return
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x + 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i - 1 + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - 1 - j - 1) * struct.tile.y)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = RIGHT
                                    find_points(i - 1, j + 1, point_index + 2)
                                    return
                                end
                            end
                            if self.pos_dir == LEFT then
                                --minions[index]:set_name("LEFT", 0.0)
                                if check(i - 1, j - 1) then
                                    if check(i, j - 1) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                        self.points_valid[point_index] = true
                                        --minions[index]:set_name(self.points[point_index + 1].x.." "..self.points[point_index + 1].y, 2.0)
                                        self.pos_dir = UP
                                        find_points(i, j, point_index + 1)
                                        return
                                    else
                                        find_points(i, j - 1, point_index)
                                        return
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - 1 - j + 1) * struct.tile.y)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i - 1) * struct.tile.x, struct.position.y + (struct.map.y - 1 - j + 1) * struct.tile.y)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = DOWN
                                    find_points(i - 1, j - 1, point_index + 2)
                                    return
                                end
                            end
                            if self.pos_dir == UP then
                                --minions[index]:set_name("UP", 0.0)
                                if check(i + 1, j - 1) then
                                    if check(i + 1, j) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                        self.points_valid[point_index] = true
                                        --minions[index]:set_name("UP", -10.0)
                                        self.pos_dir = RIGHT
                                        find_points(i, j, point_index + 1)
                                        return
                                    else
                                        find_points(i + 1, j, point_index)
                                        return
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x - 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i + 1) * struct.tile.x - 2.0, struct.position.y + (struct.map.y - j + 1) * struct.tile.y)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = LEFT
                                    find_points(i + 1, j - 1, point_index + 2)
                                    return
                                end
                            end
                            if self.pos_dir == RIGHT then
                                --minions[index]:set_name("RIGHT", 0.0)
                                if check(i + 1, j + 1) then
                                    if check(i, j + 1) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - 2.0)
                                        self.points_valid[point_index] = true
                                        self.pos_dir = DOWN
                                        find_points(i, j, point_index + 1)
                                        return
                                    else
                                        find_points(i, j + 1, point_index)
                                        return
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y + 2.0)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i + 2) * struct.tile.x, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y + 2.0)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = UP
                                    find_points(i + 1, j + 1, point_index + 2)
                                    return
                                end
                            end
                        elseif self.direction == C_CLOCK then
                            --minions[index]:set_name("C_CLOCK", 0.0)
                            if self.pos_dir == DOWN then
                                --minions[index]:set_name("DOWN", 0.0)
                                if check(i + 1, j + 1) then
                                    if check(i + 1, j) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y)
                                        self.points_valid[point_index] = true
                                        self.pos_dir = RIGHT
                                        find_points(i, j, point_index + 1)
                                        return
                                    else
                                        find_points(i + 1, j, point_index)
                                        return
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x - 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i + 1) * struct.tile.x - 2.0, struct.position.y + (struct.map.y - 1 - j - 1) * struct.tile.y)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = LEFT
                                    find_points(i + 1, j + 1, point_index + 2)
                                    return
                                end
                            end
                            if self.pos_dir == LEFT then
                                --minions[index]:set_name("LEFT", 0.0)
                                if check(i - 1, j + 1) then
                                    if check(i, j + 1) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - j - 1) * struct.tile.y - 2.0)
                                        self.points_valid[point_index] = true
                                        --minions[index]:set_name(self.points[point_index + 1].x.." "..self.points[point_index + 1].y, 2.0)
                                        self.pos_dir = DOWN
                                        find_points(i, j, point_index + 1)
                                        return
                                    else
                                        find_points(i, j + 1, point_index)
                                        return
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y + 2.0)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i - 1) * struct.tile.x, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y + 2.0)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = UP
                                    find_points(i - 1, j + 1, point_index + 2)
                                    return
                                end
                            end
                            if self.pos_dir == UP then
                                --minions[index]:set_name("UP", 0.0)
                                if check(i - 1, j - 1) then
                                    if check(i - 1, j) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                        self.points_valid[point_index] = true
                                        self.pos_dir = LEFT
                                        find_points(i, j, point_index + 1)
                                        return
                                    else
                                        find_points(i - 1, j, point_index)
                                        return
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x + 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + i * struct.tile.x + 2.0, struct.position.y + (struct.map.y - j + 1) * struct.tile.y)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = RIGHT
                                    find_points(i - 1, j - 1, point_index + 2)
                                    return
                                end
                            end
                            if self.pos_dir == RIGHT then
                                if check(i + 1, j - 1) then
                                    if check(i, j - 1) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                        self.points_valid[point_index] = true
                                        self.pos_dir = UP
                                        find_points(i, j, point_index + 1)
                                        return
                                    else
                                        find_points(i, j - 1 , point_index)
                                        return
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + 2.0, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i + 2) * struct.tile.x, struct.position.y + (struct.map.y - j) * struct.tile.y + 2.0)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = DOWN
                                    find_points(i + 1, j - 1, point_index + 2)
                                    return
                                end
                            end
                        end
                    end
                    find_points(i, j, self.point_index)
                end
            end
        end
        return false
    end
}

function cal_shortest_dis_new:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.points = {}
    o.points_valid = {}
    o.point_index = 1
    o.direction = -1
    o.pos_dir = -1
    o.dest_i = -1
    o.dest_j = -1
    o.dest = cc.p(0.0, 0.0)
    return o
end

return cal_shortest_dis_new
