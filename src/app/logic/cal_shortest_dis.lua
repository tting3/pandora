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
    last_pref = -1,
    cal = function(self, minions, structs, map, index, dt)
        local x = self.dest.x - minions[index].position.x
        local y = self.dest.y - minions[index].position.y
        local root = math.sqrt(x * x + y * y)
        if root == 0.0 then
            if minions[index].position.x ~= self.points[self.point_index].x or minions[index].position.y ~= self.points[self.point_index].y then
                self.points[self.point_index + 1] = minions[index].position
                self.points_valid[self.point_index] = true
                --minions[index]:set_name(table.getn(self.points).."", 0.0)
            end
            self.last_pref = -1
            return true
        end
        local real_speed = minions[index].speed * dt * fixedDeltaTimeScale
        local function dis(local_dest)
            local x = local_dest.x - minions[index].position.x
            local y = local_dest.y - minions[index].position.y
            --[[
            local new_x = speed * x / root
            local new_y = speed * y / root
            ]]
            local new_x = 0.0
            local new_y = 0.0
            if self.last_pref == -1 then
                if math.abs(x) >= math.abs(y) then
                    self.last_pref = 0
                else
                    self.last_pref = 1
                end
            end
            if self.last_pref == 0 then
                if math.abs(x) >= real_speed then
                    if x > 0.0 then
                        new_x = real_speed
                    else
                        new_x = 0.0 - real_speed
                    end
                    new_y = 0.0
                else
                    if math.abs(x) ~= 0.0 then
                        new_x = x
                        new_y = 0.0
                    else
                        new_x = 0.0
                        if math.abs(y) <= real_speed then
                            new_y = y
                        else
                            if y > 0.0 then
                                new_y = real_speed
                            else
                                new_y = 0.0 - real_speed
                            end
                        end
                        self.last_pref = 1
                    end
                end
            elseif self.last_pref == 1 then
                if math.abs(y) >= real_speed then
                    if y > 0.0 then
                        new_y = real_speed
                    else
                        new_y = 0.0 - real_speed
                    end
                    new_x = 0.0
                else
                    if math.abs(y) ~= 0.0 then
                        new_y = y
                        new_x = 0.0
                    else
                        new_y = 0.0
                        if math.abs(x) <= real_speed then
                            new_x = x
                        else
                            if x > 0.0 then
                                new_x = real_speed
                            else
                                new_x = 0.0 - real_speed
                            end
                        end
                        self.last_pref = 0
                    end
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
                minions[index].last_frame_index = 0
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
                if root == 0.0 then
                    self.point_index  = self.point_index + 1
                    self.last_pref = -1
                    --minions[index]:set_name(table.getn(self.points).."", 0.0)
                end
            else
                --minions[index]:set_name("here", 0.0)
                --minions[index]:set_name(self.pos_dir.."", 0.0)
                self.points_valid[self.point_index] = false
            end
        else
            local new_x, new_y = dis(self.dest)
            if minions[index]:check_move(new_x, new_y, structs, map) == true and (minions[index].height_level == 0 or (minions[index].height_level ~= 0 and self.point_index ~= 1)) then
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
                if minions[index].height_level == 0 and struct.walls ~= nil then
                    level = struct.walls
                end
                if minions[index].height_level == 1 and struct.room1 ~= nil then
                    level = struct.room1
                end
                if minions[index].height_level == 2 and struct.room2 ~= nil then
                    level = struct.room2
                end
                if minions[index].height_level == 3 and struct.room3 ~= nil then
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
                                if self.pos_dir == UP then
                                    if i < self.dest_i then
                                        self.direction = CLOCK
                                    else
                                        self.direction = C_CLOCK
                                    end
                                elseif self.pos_dir == DOWN then
                                    if i < self.dest_i then
                                        self.direction = C_CLOCK
                                    else
                                        self.direction = CLOCK
                                    end
                                elseif self.pos_dir == LEFT then
                                    if j < self.dest_j then
                                        self.direction = C_CLOCK
                                    else
                                        self.direction = CLOCK
                                    end
                                else
                                    if j < self.dest_j then
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
                                if self.pos_dir == UP then
                                    if i < self.dest_i then
                                        self.direction = CLOCK
                                    else
                                        self.direction = C_CLOCK
                                    end
                                elseif self.pos_dir == DOWN then
                                    if i < self.dest_i then
                                        self.direction = C_CLOCK
                                    else
                                        self.direction = CLOCK
                                    end
                                elseif self.pos_dir == LEFT then
                                    if j < self.dest_j then
                                        self.direction = C_CLOCK
                                    else
                                        self.direction = CLOCK
                                    end
                                else
                                    if j < self.dest_j then
                                        self.direction = CLOCK
                                    else
                                        self.direction = C_CLOCK
                                    end
                                end
                            end
                        elseif self.dest_i == -1 and self.dest_j == -1 then
                            self.dest_i = math.floor((self.dest.x - struct.position.x) / struct.tile.x)
                            self.dest_j = struct.map.y - 1 - math.floor((self.dest.y - struct.position.y) / struct.tile.y)
                        end
                    end
                    --minions[index]:set_name(self.direction.."", -10.0)
                    if minions[index].height_level ~= 0 then
                        self.dest_i = math.floor((self.dest.x - struct.position.x) / struct.tile.x)
                        self.dest_j = struct.map.y - 1 - math.floor((self.dest.y - struct.position.y) / struct.tile.y)
                        local visited = {}
                        for i = 0, struct.map.x - 1 do
                            visited[i] = {}
                            for j = 0, struct.map.y - 1 do
                                visited[i][j] = {}
                                visited[i][j].status = 0
                                visited[i][j].parent = nil
                            end
                        end
                        local i =  (minions[index].position.x - struct.position.x) / struct.tile.x
                        local j =  (struct.position.y + struct.map.y * struct.tile.y - minions[index].position.y) / struct.tile.y
                        i = math.floor(i)
                        j = math.floor(j)
                        visited[i][j].status = 1
                        if i == self.dest_i and j == self.dest_j then
                            self.points[1 + 1] = cc.p(struct.position.x + i * struct.tile.x + 25, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y + 25)
                            self.points_valid[1] = true
                            return false
                        end
                        local old_que = {cc.p(i, j)}
                        local new_que = {}
                        local function check(i, j)
                            if i >= 0 and j >= 0 and i < struct.map.x and j < struct.map.y then
                                if visited[i][j].status == 1 then
                                    return -1
                                end
                                local gid = layer:tileGIDAt(cc.p(i, j))
                                local property = level:propertiesForGID(gid)
                                return property
                            end
                            return -1
                        end
                        local temp_point_index = 1
                        while #old_que ~= 0 do
                            --release_print(#old_que.."startloop")
                            for index, point in pairs(old_que) do
                                --release_print("startloop2")
                                local function check_next(new_i, new_j, parent_i, parent_j)
                                    local result = check(new_i, new_j)
                                    if result == -1 then
                                        return -1
                                    end
                                    visited[new_i][new_j].status = 1
                                    visited[new_i][new_j].parent = cc.p(parent_i, parent_j)
                                    --release_print(new_i..":"..new_j)
                                    if new_i == self.dest_i and new_j == self.dest_j then
                                        self.point_index = 1
                                        local function add_points(i, j)
                                            if visited[i][j].parent ~= nil then
                                                --release_print("parent"..visited[i][j].parent.x..":"..visited[i][j].parent.y)
                                                add_points(visited[i][j].parent.x, visited[i][j].parent.y)
                                                self.points[temp_point_index + 1] = cc.p(struct.position.x + i * struct.tile.x + 25, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y + 25)
                                                self.points_valid[temp_point_index] = true
                                                temp_point_index = temp_point_index + 1
                                            end
                                        end
                                        if result ~= 0 and result ~= 4 and result ~= 5 and result ~= 6 and result ~= 7 then
                                            add_points(parent_i, parent_j)
                                        else
                                            add_points(new_i, new_j)
                                        end
                                        --release_print(table.getn(self.points)..":"..new_i..":"..new_j)
                                        return 1
                                    end
                                    if result ~= 0 and result ~= 4 and result ~= 5 and result ~= 6 and result ~= 7 then
                                        return -1
                                    end
                                    return 0
                                end
                                local new_i = point.x + 1
                                local new_j = point.y
                                local result = check_next(new_i, new_j, point.x, point.y)
                                if result == 0 then
                                    new_que[#new_que + 1] = cc.p(new_i, new_j)
                                elseif result == 1 then
                                    old_que = {}
                                    new_que = {}
                                    return false
                                end
                                local new_i = point.x - 1
                                local new_j = point.y
                                local result = check_next(new_i, new_j, point.x, point.y)
                                if result == 0 then
                                    new_que[#new_que + 1] = cc.p(new_i, new_j)
                                elseif result == 1 then
                                    old_que = {}
                                    new_que = {}
                                    return false
                                end
                                local new_i = point.x
                                local new_j = point.y - 1
                                local result = check_next(new_i, new_j, point.x, point.y)
                                if result == 0 then
                                    new_que[#new_que + 1] = cc.p(new_i, new_j)
                                elseif result == 1 then
                                    old_que = {}
                                    new_que = {}
                                    return false
                                end
                                local new_i = point.x
                                local new_j = point.y + 1
                                local result = check_next(new_i, new_j, point.x, point.y)
                                if result == 0 then
                                    new_que[#new_que + 1] = cc.p(new_i, new_j)
                                elseif result == 1 then
                                    old_que = {}
                                    new_que = {}
                                    return false
                                end
                            end
                            old_que = new_que
                            new_que = {}
                            --release_print(index.."endloop")
                        end
                        --release_print("end")
                        return false
                    end
                    local function find_points(i, j, point_index)
                        --minions[index]:set_name(table.getn(self.points).."", 0.0)
                        local function check(i, j)
                            if i >= 0 and j >= 0 and i < struct.map.x and j < struct.map.y then
                                local gid = layer:tileGIDAt(cc.p(i, j))
                                local property = level:propertiesForGID(gid)
                                if property ~= 0 and property ~= 4 and property ~= 6 then
                                    return false
                                end
                                return true
                            end
                            return false
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
                            --minions[index]:set_name(table.getn(self.points).."", -5.0)
                            if self.direction == CLOCK then
                                if self.pos_dir == DOWN then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x -  real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - real_speed)
                                end
                                if self.pos_dir == LEFT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x -  real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y +  real_speed)
                                end
                                if self.pos_dir == UP then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x +  real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y +  real_speed)
                                end
                                if self.pos_dir == RIGHT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x +  real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y -  real_speed)
                                end
                            elseif self.direction == C_CLOCK then
                                if self.pos_dir == DOWN then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x +  real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - real_speed)
                                end
                                if self.pos_dir == LEFT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x -  real_speed, struct.position.y + (struct.map.y - j - 1) * struct.tile.y -  real_speed)
                                end
                                if self.pos_dir == UP then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x -  real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y +  real_speed)
                                end
                                if self.pos_dir == RIGHT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x +  real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y +  real_speed)
                                end
                            end
                            self.points_valid[point_index] = true
                            if minions[index].height_level ~= 0 then
                                self.points[point_index + 2] = self.dest
                                self.points_valid[point_index + 1] = true
                            end
                            self.direction = -1
                            return false
                        end
                        if okay_to_go == true then
                            --minions[index]:set_name(table.getn(self.points).."", 0.0)
                            if self.direction == CLOCK then
                                if self.pos_dir == DOWN then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x -  real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - real_speed)
                                end
                                if self.pos_dir == LEFT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x -  real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y +  real_speed)
                                end
                                if self.pos_dir == UP then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x +  real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y +  real_speed)
                                end
                                if self.pos_dir == RIGHT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x +  real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y -  real_speed)
                                end
                            elseif self.direction == C_CLOCK then
                                if self.pos_dir == DOWN then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x +  real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - real_speed)
                                end
                                if self.pos_dir == LEFT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x -  real_speed, struct.position.y + (struct.map.y - j - 1) * struct.tile.y -  real_speed)
                                end
                                if self.pos_dir == UP then
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x -  real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y +  real_speed)
                                end
                                if self.pos_dir == RIGHT then
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x +  real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y +  real_speed)
                                end
                            end
                            self.points[point_index + 2] = self.dest
                            self.points_valid[point_index + 1] = true
                            self.direction = -1
                            return false
                        end
                        if self.direction == CLOCK then
                            --minions[index]:set_name(self.dest.x..""..self.dest.y, 0.0)
                            --minions[index]:set_name("CLOCK", 0.0)
                            --minions[index]:set_name(self.pos_dir.."", -3.0)
                            if self.pos_dir == DOWN then
                                --minions[index]:set_name("DOWN", 0.0)
                                if check(i - 1, j + 1) then
                                    if check(i - 1, j) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - real_speed)
                                        self.points_valid[point_index] = true
                                        self.pos_dir = LEFT
                                        --minions[index]:set_name(minions[index].position.x.."", 0.0)
                                        find_points(i, j, point_index + 1)
                                        return false
                                    else
                                        find_points(i - 1, j, point_index)
                                        return false
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x + real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - real_speed)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i - 1 + 1) * struct.tile.x + real_speed, struct.position.y + (struct.map.y - 1 - j - 1) * struct.tile.y)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = RIGHT
                                    find_points(i - 1, j + 1, point_index + 2)
                                    return false
                                end
                            end
                            if self.pos_dir == LEFT then
                                --minions[index]:set_name("LEFT", 0.0)
                                if check(i - 1, j - 1) then
                                    if check(i, j - 1) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y + real_speed)
                                        self.points_valid[point_index] = true
                                        --minions[index]:set_name(self.points[point_index + 1].x.." "..self.points[point_index + 1].y,  real_speed)
                                        self.pos_dir = UP
                                        find_points(i, j, point_index + 1)
                                        return false
                                    else
                                        find_points(i, j - 1, point_index)
                                        return false
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - real_speed, struct.position.y + (struct.map.y - 1 - j + 1) * struct.tile.y)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i - 1) * struct.tile.x, struct.position.y + (struct.map.y - 1 - j + 1) * struct.tile.y)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = DOWN
                                    find_points(i - 1, j - 1, point_index + 2)
                                    return false
                                end
                            end
                            if self.pos_dir == UP then
                                --minions[index]:set_name("UP", 0.0)
                                if check(i + 1, j - 1) then
                                    if check(i + 1, j) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y + real_speed)
                                        self.points_valid[point_index] = true
                                        --minions[index]:set_name("UP", -10.0)
                                        self.pos_dir = RIGHT
                                        find_points(i, j, point_index + 1)
                                        return false
                                    else
                                        find_points(i + 1, j, point_index)
                                        return false
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x - real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y + real_speed)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i + 1) * struct.tile.x - real_speed, struct.position.y + (struct.map.y - j + 1) * struct.tile.y)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = LEFT
                                    find_points(i + 1, j - 1, point_index + 2)
                                    return false
                                end
                            end
                            if self.pos_dir == RIGHT then
                                --minions[index]:set_name("RIGHT", 0.0)
                                if check(i + 1, j + 1) then
                                    if check(i, j + 1) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - real_speed)
                                        self.points_valid[point_index] = true
                                        self.pos_dir = DOWN
                                        find_points(i, j, point_index + 1)
                                        return false
                                    else
                                        find_points(i, j + 1, point_index)
                                        return false
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y + real_speed)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i + 2) * struct.tile.x, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y + real_speed)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = UP
                                    find_points(i + 1, j + 1, point_index + 2)
                                    return false
                                end
                            end
                        elseif self.direction == C_CLOCK then
                            --minions[index]:set_name("c"..self.dest.x..""..self.dest.y, 0.0)
                            --minions[index]:set_name("C_CLOCK", 0.0)
                            if self.pos_dir == DOWN then
                                --minions[index]:set_name("DOWN", 0.0)
                                if check(i + 1, j + 1) then
                                    if check(i + 1, j) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - real_speed)
                                        self.points_valid[point_index] = true
                                        self.pos_dir = RIGHT
                                        find_points(i, j, point_index + 1)
                                        return false
                                    else
                                        find_points(i + 1, j, point_index)
                                        return false
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x - real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y - real_speed)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i + 1) * struct.tile.x - real_speed, struct.position.y + (struct.map.y - 1 - j - 1) * struct.tile.y)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = LEFT
                                    find_points(i + 1, j + 1, point_index + 2)
                                    return false
                                end
                            end
                            if self.pos_dir == LEFT then
                                --minions[index]:set_name("LEFT", 0.0)
                                if check(i - 1, j + 1) then
                                    if check(i, j + 1) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - real_speed, struct.position.y + (struct.map.y - j - 1) * struct.tile.y - real_speed)
                                        self.points_valid[point_index] = true
                                        --minions[index]:set_name(self.points[point_index + 1].x.." "..self.points[point_index + 1].y,  real_speed)
                                        self.pos_dir = DOWN
                                        find_points(i, j, point_index + 1)
                                        return false
                                    else
                                        find_points(i, j + 1, point_index)
                                        return false
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - real_speed, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y + real_speed)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i - 1) * struct.tile.x, struct.position.y + (struct.map.y - 1 - j) * struct.tile.y +  real_speed)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = UP
                                    find_points(i - 1, j + 1, point_index + 2)
                                    return false
                                end
                            end
                            if self.pos_dir == UP then
                                if check(i - 1, j - 1) then
                                    if check(i - 1, j) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x - real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y + real_speed)
                                        self.points_valid[point_index] = true
                                        self.pos_dir = LEFT
                                        find_points(i, j, point_index + 1)
                                        return false
                                    else
                                        find_points(i - 1, j, point_index)
                                        return false
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + i * struct.tile.x + real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y + real_speed)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + i * struct.tile.x + real_speed, struct.position.y + (struct.map.y - j + 1) * struct.tile.y)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = RIGHT
                                    find_points(i - 1, j - 1, point_index + 2)
                                    return false
                                end
                            end
                            if self.pos_dir == RIGHT then
                                if check(i + 1, j - 1) then
                                    if check(i, j - 1) == true then
                                        self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y + real_speed)
                                        self.points_valid[point_index] = true
                                        self.pos_dir = UP
                                        find_points(i, j, point_index + 1)
                                        return false
                                    else
                                        find_points(i, j - 1 , point_index)
                                        return false
                                    end
                                else
                                    self.points[point_index + 1] = cc.p(struct.position.x + (i + 1) * struct.tile.x + real_speed, struct.position.y + (struct.map.y - j) * struct.tile.y - real_speed)
                                    self.points_valid[point_index] = true
                                    self.points[point_index + 2] = cc.p(struct.position.x + (i + 2) * struct.tile.x, struct.position.y + (struct.map.y - j) * struct.tile.y - real_speed)
                                    self.points_valid[point_index + 1] = true
                                    self.pos_dir = DOWN
                                    find_points(i + 1, j - 1, point_index + 2)
                                    return false
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
    o.last_pref = -1
    return o
end

return cal_shortest_dis_new
