--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 3/6/2016
-- Time: 6:31 PM
-- To change this template use File | Settings | File Templates.
--

local DEAD_BODY = 0

local NORMAL = 0
local BLOODY = 1
local BURNED = 2

local identity = require("app.logic.identity")

local dead_body = {
    position = cc.p(0.0, 0.0),
    height_level = 0,
    id = -1,
    indices_array = nil,
    event_type = DEAD_BODY,
    index2 = 0,
    corpse_status = NORMAL,
    sprite_name = nil,
    sprite = nil,
    init = function(self, parent, main_position, id, corpse_status, position, height_level, index2, event_spread_dis)
        self.indices_array = {}
        for i = 1, event_spread_dis * 2 + 1 do
            self.indices_array[i] = {}
            for j = 1, event_spread_dis * 2 + 1 do
                self.indices_array[i][j] = {}
                self.indices_array[i][j].value = 0
                self.indices_array[i][j].dis = event_spread_dis
            end
        end
        self:remove(parent)
        self.id = id
        self.index2 = index2
        self.corpse_status = corpse_status
        self.position = position
        self.height_level = height_level
        if self.id == identity.slave then
            if self.corpse_status == NORMAL then
                self.sprite_name = "character/dead_free_folk_normal.png"
            elseif self.corpse_status == BLOODY then
                self.sprite_name = "character/dead_free_folk_bloody.png"
            elseif self.corpse_status == BURNED then
                self.sprite_name = "character/dead_free_folk_burned.png"
            end
        end
        if self.id == identity.free_folk then
            if self.corpse_status == NORMAL then
                self.sprite_name = "character/dead_free_folk_normal.png"
            elseif self.corpse_status == BLOODY then
                self.sprite_name = "character/dead_free_folk_bloody.png"
            elseif self.corpse_status == BURNED then
                self.sprite_name = "character/dead_free_folk_burned.png"
            end
        end
        self.sprite = display.newSprite(self.sprite_name)
        :move(self.position.x - main_position.x + display.cx, self.position.y - main_position.y + display.cy + 10.0)
        :addTo(parent, math.floor(display.top - (self.position.y - main_position.y + display.cy + 10.0)))
    end,
    update_position = function(self, parent, main_position, height_level)
        if self.sprite ~= nil then
            parent:reorderChild(self.sprite, math.floor(display.top - (self.position.y - main_position.y + display.cy + 10.0)))
            self.sprite:move(self.position.x - main_position.x + display.cx, self.position.y - main_position.y + display.cy + 10.0)
            if self.height_level ~= 0 and height_level ~= self.height_level then
                if self.sprite:isVisible() == true then
                    self.sprite:setVisible(false)
                end
            else
                if self.sprite:isVisible() == false then
                    self.sprite:setVisible(true)
                end
            end
            if self.position.x - main_position.x < 0.0 - display.cx - 2 * 50 or
                    self.position.x - main_position.x > display.cx + 2 * 50 or
                    self.position.y - main_position.y < 0.0 - display.cy - 2 * 50 or
                    self.position.y - main_position.y > display.cy + 2 * 50 then
                self:remove(parent)
            end
        else
            if self.position.x - main_position.x <= display.cx + 2 * 50 and
                    self.position.x - main_position.x >= 0.0 - display.cx - 50 and
                    self.position.y - main_position.y <= display.cy + 2 * 50 and
                    self.position.y - main_position.y >= 0.0 - display.cy - 2 * 50 then
                self.sprite = display.newSprite(self.sprite_name)
                :move(self.position.x - main_position.x + display.cx, self.position.y - main_position.y + display.cy + 10.0)
                :addTo(parent, math.floor(display.top - (self.position.y - main_position.y + display.cy + 10.0)))
            end
        end
    end,
    change_night_level_shader = function(self)
        if self.sprite == nil or self.sprite:isVisible() == false then
            return
        end
        if self.height_level ~= 0 then
            local night_char = cc.GLProgramCache:getInstance():getGLProgram("night_char"..self.height_level)
            if self.sprite:getGLProgram() ~= night_char then
                self.sprite:setGLProgram(night_char)
            end
        else
            local night_char = cc.GLProgramCache:getInstance():getGLProgram("night_char")
            if self.sprite:getGLProgram() ~= night_char then
                self.sprite:setGLProgram(night_char)
            end
        end
    end,
    remove = function(self, parent)
        if self.sprite ~= nil then
            self.sprite:removeFromParentAndCleanup(true)
        end
        self.sprite = nil
        if self.index2 ~= 0 then
            parent:remove_dead_body(self)
        end
    end
}

function dead_body:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.position = cc.p(0.0, 0.0)
    o.id = -1
    o.event_type = DEAD_BODY
    o.height_level = 0
    o.indices_array = nil
    o.index2 = 0
    o.corpse_status = NORMAL
    o.sprite_name = nil
    o.sprite = nil
    return o
end

return dead_body
