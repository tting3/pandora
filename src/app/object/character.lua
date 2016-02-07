--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 12/30/2015
-- Time: 8:34 PM
-- To change this template use File | Settings | File Templates.
--

local STOP = -1
local DOWN = 0
local LEFT = 1
local RIGHT = 2
local UP = 3

local font = require("app.views.font")
local identity = require("app.logic.identity")
local minion_logic = require("app.logic.minion_logic")

local character = {
    position = cc.p(0.0, 0.0),
    name = "",
    name_txt = nil,
    asleep = false,
    sprite = nil,
    animated = false,
    last_act = DOWN,
    logic = nil,
    dir = STOP,
    last_act = STOP,
    height_level = 0,
    map_characters = nil,
    minions = nil,
    m_character = nil,
    last_map_index = -1,
    index = 0,
    id = identity.free_folk,
    hp = 100,
    hunger = 0,
    inventory = {},
    left_hand = nil,
    right_hand = nil,
    armor = nil,
    set_position = function(self, x, y)
        self.position = cc.p(x, y)
    end,
    enter_next_level = function(self)
        self.height_level = self.height_level + 1
    end,
    enter_prev_level = function(self)
        self.height_level = self.height_level - 1
    end,
    check_move = function(self, x, y, structs, map)
        local can_move = true
        local i = (self.position.x + x) / 50.0
        local j = (self.position.y + y) / 50.0
        i = math.floor(i) + 1
        j = math.floor(j) + 1
        local ii = map[i][j]
        if ii > 0 then
            local struct = structs[ii]
            local level = nil
            if self.height_level == 0 and struct.walls ~= nil  then
                level = struct.walls
            end
            if self.height_level == 1 and struct.room1 ~= nil then
                level = struct.room1
            end
            if self.height_level == 2 and struct.room2 ~= nil  then
                level = struct.room2
            end
            if self.height_level == 3 and struct.room3 ~= nil  then
                level = struct.room3
            end
            if level ~= nil then
                local layer = level:layerNamed("collision")
                local function check(self, newx, newy)
                    local i =  (newx - struct.position.x) / struct.tile.x
                    local j =  (struct.position.y + struct.map.y * struct.tile.y - newy) / struct.tile.y
                    i = math.floor(i)
                    j = math.floor(j)
                    if i >= 0 and i < struct.map.x and j >= 0 and j < struct.map.y then
                        local gid = layer:tileGIDAt(cc.p(i, j))
                        local property = level:propertiesForGID(gid)
                        if property ~= 0 and property ~= 4 then
                            --self:set_name(self.position.x..""..self.position.y, 5.0)
                            --self:set_name(newx, 5.0)
                            can_move = false
                        end
                    end
                end
                local newx = self.position.x + x
                local newy = self.position.y + y
                check(self, newx, newy)
            end
        end
        return can_move
    end,
    change_position_m = function(self, x, y, structs, map)
        local leave_enter = -1
        local struct_index = 0
        local i = (self.position.x + x) / 50.0
        local j = (self.position.y + y) / 50.0
        i = math.floor(i) + 1
        j = math.floor(j) + 1
        local ii = map[i][j]
        if ii > 0 then
            local struct = structs[ii]
            local level = nil
            if self.height_level == 0 and struct.walls ~= nil  then
                level = struct.walls
            end
            if self.height_level == 1 and struct.room1 ~= nil then
                level = struct.room1
            end
            if self.height_level == 2 and struct.room2 ~= nil  then
                level = struct.room2
            end
            if self.height_level == 3 and struct.room3 ~= nil  then
                level = struct.room3
            end
            if struct.in_vision == true and level ~= nil then
                local layer = level:layerNamed("collision")
                local function check(self, newx, newy, offset)
                    local i =  (newx - struct.position.x) / struct.tile.x
                    local j =  (struct.position.y + struct.map.y * struct.tile.y - newy) / struct.tile.y
                    i = math.floor(i)
                    j = math.floor(j)
                    if i >= 0 and i < struct.map.x and j >= 0 and j < struct.map.y then
                        local gid = layer:tileGIDAt(cc.p(i, j))
                        local property = level:propertiesForGID(gid)
                        if property == 1 or property == 2 or property == 3 then
                            return 0
                        end
                        local old_property = -1
                        local i =  (self.position.x - struct.position.x) / struct.tile.x
                        local j =  (struct.position.y + struct.map.y * struct.tile.y - self.position.y) / struct.tile.y
                        i = math.floor(i)
                        j = math.floor(j)
                        if i >= 0 and i < struct.map.x and j >= 0 and j < struct.map.y then
                            local old_gid = layer:tileGIDAt(cc.p(i, j))
                            old_property = level:propertiesForGID(old_gid)
                        end
                        if property == 4 then
                            if old_property ~= 4 then
                                self.height_level = self.height_level - 1
                                leave_enter = 0
                                struct_index = ii
                            end
                        end
                        if property == 5 then
                            if old_property ~= 5 then
                                self.height_level = self.height_level + 1
                                leave_enter = 1
                                struct_index = ii
                            end
                        end
                    end
                    return offset
                end
                local newx = self.position.x + x
                local newy = self.position.y
                x = check(self, newx, newy, x)
                local newx = self.position.x
                local newy = self.position.y + y
                y = check(self, newx, newy, y)
            end
        end
        self:update_position(x, y)
        return leave_enter, struct_index
    end,
    update_position = function(self, x, y)
        self:update_map_characters(x, y)
        self.position = cc.p(self.position.x + x, self.position.y + y)
    end,
    change_position = function(self, x, y, sx, sy)
        self:update_position(x, y)
        if self.sprite ~= nil then
            self.sprite:move(self.position.x - sx + display.cx, self.position.y - sy + display.cy + 25)
        end
    end,
    set_name = function(self, name, anchor_x)
        self.name = name
        if self.sprite ~= nil and name ~= "" then
            if self.name_txt ~= nil then
                self.name_txt:removeFromParentAndCleanup(true)
                self.name_txt = nil
            end
            self.name_txt = cc.Label:createWithSystemFont(self.name, font.GREEK_FONT, 20)
                :setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
                :setAnchorPoint(anchor_x, -1.5)
                :setTextColor(font.BLACK)
                :addTo(self.sprite)
        end
    end,
    set_id = function(self, new_id)
        self.id = new_id
        self.logic = minion_logic:new()
    end,
    add_shadow = function(self)
        local c_shadow = display.loadImage("character/c_shadow.png")
        display.newSprite(c_shadow)
            :setAnchorPoint(0.0, 0.5)
            :addTo(self.sprite)
    end,
    set_map_characters = function(self, new_map_characters, index, minions, m_character)
        self.index = index
        self.map_characters = new_map_characters
        self.minions = minions
        self.m_character = m_character
    end,
    update_map_characters = function(self, x, y)
        local new_i = math.floor((self.position.x + x) / 50.0) + 1
        local new_j = math.floor((self.position.y + y) / 50.0) + 1
        if self.last_map_index ~= -1 then
            local old_i = math.floor(self.position.x / 50.0) + 1
            local old_j = math.floor(self.position.y / 50.0) + 1
            if old_i == new_i and old_j == new_j then
                return
            end
            local old_num = self.map_characters[old_i][old_j][1]
            for i = self.last_map_index, old_num + 1 do
                if i ~= old_num + 1 then
                    self.map_characters[old_i][old_j][i] = self.map_characters[old_i][old_j][i + 1]
                    if self.map_characters[old_i][old_j][i] ~= 0 and self.map_characters[old_i][old_j][i] ~= nil then
                        self.minions[self.map_characters[old_i][old_j][i]].last_map_index = self.minions[self.map_characters[old_i][old_j][i]].last_map_index - 1
                    end
                    if self.map_characters[old_i][old_j][i] == 0 then
                        self.m_character.last_map_index = self.m_character.last_map_index - 1
                    end
                else
                    self.map_characters[old_i][old_j][i] = nil
                end
            end
            self.map_characters[old_i][old_j][1] = old_num - 1
        end
        local num = self.map_characters[new_i][new_j][1]
        num = num + 1
        self.map_characters[new_i][new_j][1] = num
        self.last_map_index = num + 1
        self.map_characters[new_i][new_j][num + 1] = self.index
    end
}

function character:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.position = cc.p(0.0, 0.0)
    o.name = ""
    o.name_txt = nil
    o.asleep = false
    o.sprite = nil
    o.animated = false
    o.last_act = DOWN
    o.logic = nil
    o.dir = STOP
    o.height_level = 0
    o.map_characters = nil
    o.minions = nil
    o.m_character = nil
    o.last_map_index = -1
    o.id = identity.free_folk
    o.index = 0
    o.hp = 100
    o.hunger = 0
    o.inventory = {}
    return o
end

return character
