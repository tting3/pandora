--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/6/2016
-- Time: 11:11 AM
-- To change this template use File | Settings | File Templates.
--

local chest = require("app.object.chest")
local oven = require("app.object.oven")

local struct = {
    position = cc.p(0.0, 0.0),
    name = "",
    functionality = -1,
    in_vision = false,
    roofs = nil,
    walls = nil,
    room1 = nil,
    room2 = nil,
    room3 = nil,
    plants = nil,
    chests = {},
    doors = {},
    beds = {},
    ovens = {},
    map = cc.p(0, 0),
    tile = cc.p(0, 0),
    get_target = function(self, height_level, target)
        local level = nil
        if height_level == 0 and self.walls ~= nil  then
            level = self.walls
        end
        if height_level == 1 and self.room1 ~= nil then
            level = self.room1
        end
        if height_level == 2 and self.room2 ~= nil  then
            level = self.room2
        end
        if height_level == 3 and self.room3 ~= nil  then
            level = self.room3
        end
        if level == nil then
            return {}
        end
        local layer = level:layerNamed(target)
        if layer == nil then
            return {}
        end
        local result = {}
        for i = 0, self.map.x - 1 do
            for j = 0, self.map.y - 1 do
                local gid = layer:tileGIDAt(cc.p(i, j))
                local property = level:propertiesForGID(gid)
                if property ~= 0 then
                    result[#result + 1] = cc.p(i, j)
                end
            end
        end
        return result
    end,
    get_beds = function(self, height_level)
        return self:get_target(height_level, "beds")
    end,
    get_storages = function(self, height_level)
        return self:get_target(height_level, "storage")
    end,
    get_ovens = function(self, height_level)
        return self:get_target(height_level, "oven")
    end,
    check_chest = function(self, height_level, i, j)
        if self.chests == nil then
            return false
        end
        if self.chests[height_level] == nil then
            return false
        end
        if self.chests[height_level][i] == nil then
            return false
        end
        if self.chests[height_level][i][j] == nil then
            return false
        end
        return true
    end,
    init_chests = function(self, sequence)
        for height_level = 0, 3 do
            local level = nil
            if height_level == 0 and self.walls ~= nil then
                level = self.walls
            end
            if height_level == 1 and self.room1 ~= nil then
                level = self.room1
            end
            if height_level == 2 and self.room2 ~= nil then
                level = self.room2
            end
            if height_level == 3 and self.room3 ~= nil then
                level = self.room3
            end
            if level ~= nil then
                local layer = level:layerNamed("storage")
                if layer ~= nil then
                    self.chests[height_level] = {}
                    for i = 0, self.map.x - 1 do
                        self.chests[height_level][i] = {}
                        for j = 0, self.map.y - 1 do
                            local gid = layer:tileGIDAt(cc.p(i, j))
                            local property = level:propertiesForGID(gid)
                            if property ~= 0 then
                                self.chests[height_level][i][j] = chest:new()
                                self.chests[height_level][i][j].key_sequence = sequence
                            end
                        end
                    end
                end
            end
        end
    end,
    init_beds = function(self)
        for height_level = 0, 3 do
            local level = nil
            if height_level == 0 and self.walls ~= nil then
                level = self.walls
            end
            if height_level == 1 and self.room1 ~= nil then
                level = self.room1
            end
            if height_level == 2 and self.room2 ~= nil then
                level = self.room2
            end
            if height_level == 3 and self.room3 ~= nil then
                level = self.room3
            end
            if level ~= nil then
                local layer = level:layerNamed("beds")
                if layer ~= nil then
                    self.beds[height_level] = {}
                    for i = 0, self.map.x - 1 do
                        self.beds[height_level][i] = {}
                        for j = 0, self.map.y - 1 do
                            local gid = layer:tileGIDAt(cc.p(i, j))
                            local property = level:propertiesForGID(gid)
                            if property ~= 0 then
                                self.beds[height_level][i][j] = {}
                                self.beds[height_level][i][j].in_use = false
                            end
                        end
                    end
                end
            end
        end
    end,
    init_ovens = function(self)
        for height_level = 0, 3 do
            local level = nil
            if height_level == 0 and self.walls ~= nil then
                level = self.walls
            end
            if height_level == 1 and self.room1 ~= nil then
                level = self.room1
            end
            if height_level == 2 and self.room2 ~= nil then
                level = self.room2
            end
            if height_level == 3 and self.room3 ~= nil then
                level = self.room3
            end
            if level ~= nil then
                local layer = level:layerNamed("oven")
                if layer ~= nil then
                    self.ovens[height_level] = {}
                    for i = 0, self.map.x - 1 do
                        self.ovens[height_level][i] = {}
                        for j = 0, self.map.y - 1 do
                            local gid = layer:tileGIDAt(cc.p(i, j))
                            local property = level:propertiesForGID(gid)
                            if property ~= 0 then
                                self.ovens[height_level][i][j] = oven:new()
                                self.ovens[height_level][i][j]:init_flame_sprite(level, i, j, self.tile, self.map)
                            end
                        end
                    end
                end
            end
        end
    end,
    init_doors = function(self, sequence, locked)
        for height_level = 0, 3 do
            local level = nil
            if height_level == 0 and self.walls ~= nil  then
                level = self.walls
            end
            if height_level == 1 and self.room1 ~= nil then
                level = self.room1
            end
            if height_level == 2 and self.room2 ~= nil  then
                level = self.room2
            end
            if height_level == 3 and self.room3 ~= nil  then
                level = self.room3
            end
            if level ~= nil then
                local layer = level:layerNamed("collision")
                if layer ~= nil then
                    self.doors[height_level] = {}
                    for i = 0, self.map.x - 1 do
                        self.doors[height_level][i] = {}
                        for j = 0, self.map.y - 1 do
                            local gid = layer:tileGIDAt(cc.p(i, j))
                            local property = level:propertiesForGID(gid)
                            if property == 7 then
                                self.doors[height_level][i][j] = {}
                                self.doors[height_level][i][j].locked = locked
                                self.doors[height_level][i][j].key_sequence = sequence
                            end
                            if property == 6 then
                                self.doors[height_level][i][j] = self.doors[height_level - 1][i][j - 1]
                            end
                        end
                    end
                end
            end
        end
    end,
    get_entrance = function(self, height_level, position)
        local level = nil
        if height_level == 0 and self.walls ~= nil  then
            level = self.walls
        end
        if height_level == 1 and self.room1 ~= nil then
            level = self.room1
        end
        if height_level == 2 and self.room2 ~= nil  then
            level = self.room2
        end
        if height_level == 3 and self.room3 ~= nil  then
            level = self.room3
        end
        if level == nil then
            return cc.p(-1.0, -1.0)
        end
        local layer = level:layerNamed("collision")
        local ii, jj
        local x = self.map.x - 1
        local y = self.map.y - 1
        local closest = x * x + y * y
        local x = math.floor((position.x - self.position.x) / self.tile.x)
        local y = math.floor((self.position.y + self.map.y * self.tile.y - position.y) / self.tile.y)
        if x < 0 then
            x = 0
        elseif x > self.map.x - 1 then
            x = self.map.x - 1
        end
        if y < 0 then
            y = 0
        elseif y > self.map.y - 1 then
            y = self.map.y - 1
        end
        for i = 0, self.map.x - 1 do
            for j = 0, self.map.y - 1 do
                local gid = layer:tileGIDAt(cc.p(i, j))
                local property = level:propertiesForGID(gid)
                if property == 5 or property == 7 then
                    local new_dis = (i - x) * (i - x) + (j - y) * (j - y)
                    if new_dis <= closest then
                        closest = new_dis
                        ii = i
                        jj = j
                    end
                end
            end
        end
        return cc.p(ii, jj)
    end,
    get_exit = function(self, height_level, position)
        local level = nil
        if height_level == 0 and self.walls ~= nil  then
            level = self.walls
        end
        if height_level == 1 and self.room1 ~= nil then
            level = self.room1
        end
        if height_level == 2 and self.room2 ~= nil  then
            level = self.room2
        end
        if height_level == 3 and self.room3 ~= nil  then
            level = self.room3
        end
        if level == nil then
            return cc.p(-1.0, -1.0)
        end
        local layer = level:layerNamed("collision")
        local ii, jj
        local x = self.map.x - 1
        local y = self.map.y - 1
        local closest = x * x + y * y
        local x = math.floor((position.x - self.position.x) / self.tile.x)
        local y = math.floor((self.position.y + self.map.y * self.tile.y - position.y) / self.tile.y)
        if x < 0 then
            x = 0
        elseif x > self.map.x - 1 then
            x = self.map.x - 1
        end
        if y < 0 then
            y = 0
        elseif y > self.map.y - 1 then
            y = self.map.y - 1
        end
        for i = 0, self.map.x - 1 do
            for j = 0, self.map.y - 1 do
                local gid = layer:tileGIDAt(cc.p(i, j))
                local property = level:propertiesForGID(gid)
                if property == 4 or property == 6 then
                    local new_dis = (i - x) * (i - x) + (j - y) * (j - y)
                    if new_dis <= closest then
                        closest = new_dis
                        ii = i
                        jj = j
                    end
                end
            end
        end
        return cc.p(ii, jj)
    end,
    update_ovens = function(self, parent, dt)
        for l = 0, 3 do
            if self.ovens[l] ~= nil then
                for i = 0, self.map.x - 1 do
                    if self.ovens[l][i] ~= nil then
                        for j = 0, self.map.y - 1 do
                            if self.ovens[l][i][j] ~= nil then
                                self.ovens[l][i][j]:update(parent, dt, self)
                            end
                        end
                    end
                end
            end
        end
    end
}

function struct:enter(level)
    if level == 1 then
        self.roofs:setVisible(false)
        self.walls:setVisible(false)
        self.room1:setVisible(true)
        if self.roofs_shadow ~= nil then
            self.roofs_shadow:setVisible(true)
        end
        if self.walls_shadow ~= nil then
            self.walls_shadow:setVisible(true)
        end
    end
    if level == 2 then
        self.room1:setVisible(false)
        self.room2:setVisible(true)
        if self.roofs_shadow ~= nil then
            self.roofs_shadow:setVisible(true)
        end
        if self.walls_shadow ~= nil then
            self.walls_shadow:setVisible(true)
        end
    end
    if level == 3 then
        self.room2:setVisible(false)
        self.room3:setVisible(true)
        if self.roofs_shadow ~= nil then
            self.roofs_shadow:setVisible(true)
        end
        if self.walls_shadow ~= nil then
            self.walls_shadow:setVisible(true)
        end
    end
end

function struct:leave_and_enter(level)
    if level == 0 then
        self.roofs:setVisible(true)
        self.walls:setVisible(true)
        self.room1:setVisible(false)
        if self.roofs_shadow ~= nil then
            self.roofs_shadow:setVisible(false)
        end
        if self.walls_shadow ~= nil then
            self.walls_shadow:setVisible(false)
        end
    end
    if level == 1 then
        self.room1:setVisible(true)
        self.room2:setVisible(false)
        if self.roofs_shadow ~= nil then
            self.roofs_shadow:setVisible(true)
        end
        if self.walls_shadow ~= nil then
            self.walls_shadow:setVisible(true)
        end
    end
    if level == 2 then
        self.room2:setVisible(true)
        self.room3:setVisible(false)
        if self.roofs_shadow ~= nil then
            self.roofs_shadow:setVisible(true)
        end
        if self.walls_shadow ~= nil then
            self.walls_shadow:setVisible(true)
        end
    end
end

function struct:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.position = cc.p(0.0, 0.0)
    o.name = ""
    o.functionality = -1
    o.in_vision = false
    o.roofs = nil
    o.walls = nil
    o.room1 = nil
    o.room2 = nil
    o.room3 = nil
    o.plants = nil
    o.allowed_id = {}
    o.allowed_minion_indices = {}
    o.chests = {}
    o.doors = {}
    o.beds = {}
    o.ovens = {}
    o.map = cc.p(0, 0)
    o.tile = cc.p(0, 0)
    return o
end

return struct