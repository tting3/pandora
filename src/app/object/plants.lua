--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/11/2016
-- Time: 6:41 AM
-- To change this template use File | Settings | File Templates.
--

local plants_type = require("app.object.plants_type")

local success = 1
local working = 0
local failed = -1

local plants = {
    types = {},
    being_harvested = {},
    growth_status = {},
    plants_num = {},
    fruit_sprites = {},
    node = nil,
    width = 0,
    height = 0,
    init_plants = function(self, struct, structs_wall, width, height)
        local layer = struct.walls:layerNamed("plants")
        if layer == nil then
            return
        end
        self.node = structs_wall
        self.width = width
        self.height = height
        for i = 0, struct.map.x - 1 do
            self.types[i] = {}
            self.being_harvested[i] = {}
            self.growth_status[i] = {}
            self.fruit_sprites[i] = {}
            self.plants_num = {}
            for j = 1, 10 do
                self.plants_num[j] = 0
            end
            local x, y = self.node:getPosition()
            for j = 0, struct.map.y - 1 do
                local gid = layer:tileGIDAt(cc.p(i, j))
                local property = struct.walls:propertiesForGID(gid)
                if property ~= 0 then
                    self.types[i][j] = plants_type.CROP
                    self.being_harvested[i][j] = 0
                    self.growth_status[i][j] = plants_type.CROP.growth_time
                    self.plants_num[plants_type.CROP.id] = self.plants_num[plants_type.CROP.id] + 1
                    self.fruit_sprites[i][j] = display.newSprite(plants_type.CROP.fruit_name)
                        :move(x + struct.position.x - display.cx - self.width / 2 + struct.tile.x * i + 25, y - display.cy + struct.position.y - self.height / 2 + struct.tile.y * (struct.map.y - j - 1) + 25)
                        :addTo(self.node, 2)
                else
                    self.types[i][j] = nil
                    self.being_harvested[i][j] = -1
                    self.growth_status[i][j] = -1
                    self.fruit_sprites[i][j] = nil
                end
            end
        end
    end,
    add_plant = function(self, i, j, plant_type)
        if i >= 0 and j >= 0 and self.types[i][j] == nil then
            self.types[i][j] = plant_type
        end
    end,
    harvest_plant = function(self, i, j, dt)
        if i < 0 or j < 0 then
            return failed, nil
        end
        if self.types[i][j] == nil then
            return failed, nil
        end
        if self.growth_status[i][j] ~= self.types[i][j].growth_time then
            return failed, nil
        else
            if self.being_harvested[i][j] < self.types[i][j].harvest_time then
                self.being_harvested[i][j] = self.being_harvested[i][j] + dt
                return working, nil
            else
                self.fruit_sprites[i][j]:setVisible(false)
                self.being_harvested[i][j] = 0
                self.growth_status[i][j] = 0
                self.plants_num[self.types[i][j].id] = self.plants_num[self.types[i][j].id] - 1
                return success, {type = self.types[i][j].fruit.item_type, num = self.types[i][j].fruit.num}
            end
        end
    end,
    harvest_cancel = function(self, i, j)
        if self.types[i][j] == nil then
            return
        end
        self.being_harvested[i][j] = 0
    end,
    plants_grow = function(self, structs, index, dt)
        local x, y = self.node:getPosition()
        for i = 0, structs[index].map.x - 1 do
            for j = 0, structs[index].map.y - 1 do
                if self.types[i][j] ~= nil
                    and self.growth_status[i][j] < self.types[i][j].growth_time then
                    self.growth_status[i][j] = self.growth_status[i][j] + dt
                    if self.growth_status[i][j] >= self.types[i][j].growth_time then
                        self.growth_status[i][j] = self.types[i][j].growth_time
                        self.plants_num[self.types[i][j].id] = self.plants_num[self.types[i][j].id] + 1
                        self.fruit_sprites[i][j]:setVisible(true)
                    end
                end
            end
        end
    end,
    check_plant = function(self, i, j, plant)
        if i < 0 or j < 0 then
            return false
        end
        if self.types[i][j] == nil or self.being_harvested[i][j] ~= 0 or self.growth_status[i][j] ~= self.types[i][j].growth_time then
            return false
        end
        if plant ~= nil then
            if self.growth_status[i][j] ~= plant.growth_time then
                return false
            end
        end
        return true
    end,
    find_closest = function(self, struct, position, type)
        local ii = -1
        local jj = -1
        local x = struct.map.x - 1
        local y = struct.map.y - 1
        local closest = x * x + y * y
        local x = math.floor((position.x - struct.position.x) / struct.tile.x)
        local y = math.floor((struct.position.y + struct.map.y * struct.tile.y - position.y) / struct.tile.y)
        for i = 0, struct.map.x - 1 do
            for j = 0, struct.map.y - 1 do
                if self.types[i][j] == type
                    and self.being_harvested[i][j] == 0 then
                    if self.growth_status[i][j] == type.growth_time then
                        local new_dis = (i - x) * (i - x) + (j - y) * (j - y)
                        if new_dis <= closest then
                            closest = new_dis
                            ii = i
                            jj = j
                        end
                    end
                end
            end
        end
        return ii, jj
    end
}

function plants:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.type = {}
    o.being_harvested = {}
    o.growth_status = {}
    o.plants_num = {}
    o.fruit_sprites = {}
    o.node = nil
    o.width = 0
    o.height = 0
    return o
end

return plants
