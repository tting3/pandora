--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/6/2016
-- Time: 11:11 AM
-- To change this template use File | Settings | File Templates.
--
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
    map = cc.p(0, 0),
    tile = cc.p(0, 0),
    get_storage = function(self, height_level)
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
        local layer = level:layerNamed("storage")
        local ii, jj
        local out_flag = 0
        for i = 0, self.map.x - 1 do
            for j = 0, self.map.y - 1 do
                local gid = layer:tileGIDAt(cc.p(i, j))
                local property = level:propertiesForGID(gid)
                if property ~= 0 then
                    ii = i
                    jj = j
                    out_flag = 1
                    break
                end
            end
            if out_flag == 1 then
                break
            end
        end
        return cc.p(ii, jj)
    end,
    get_entrance = function(self, height_level)
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
        local out_flag = 0
        for i = 0, self.map.x - 1 do
            for j = 0, self.map.y - 1 do
                local gid = layer:tileGIDAt(cc.p(i, j))
                local property = level:propertiesForGID(gid)
                if property == 5 then
                    ii = i
                    jj = j
                    out_flag = 1
                    break
                end
            end
            if out_flag == 1 then
                break
            end
        end
        return cc.p(ii, jj)
    end,
    get_exit = function(self, height_level)
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
        local out_flag = 0
        for i = 0, self.map.x - 1 do
            for j = 0, self.map.y - 1 do
                local gid = layer:tileGIDAt(cc.p(i, j))
                local property = level:propertiesForGID(gid)
                if property == 4 then
                    ii = i
                    jj = j
                    out_flag = 1
                    break
                end
            end
            if out_flag == 1 then
                break
            end
        end
        return cc.p(ii, jj)
    end
}

function struct:enter(level)
    if level == 1 then
        self.roofs:setVisible(false)
        self.walls:setVisible(false)
        self.room1:setVisible(true)
    end
    if level == 2 then
        self.room1:setVisible(false)
        self.room2:setVisible(true)
    end
    if level == 3 then
        self.room2:setVisible(false)
        self.room3:setVisible(true)
    end
end

function struct:leave_and_enter(level)
    if level == 0 then
        self.roofs:setVisible(true)
        self.walls:setVisible(true)
        self.room1:setVisible(false)
    end
    if level == 1 then
        self.room1:setVisible(true)
        self.room2:setVisible(false)
    end
    if level == 2 then
        self.room2:setVisible(true)
        self.room3:setVisible(false)
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
    o.map = cc.p(0, 0)
    o.tile = cc.p(0, 0)
    return o
end

return struct