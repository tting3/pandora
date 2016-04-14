--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 2/22/2016
-- Time: 4:32 PM
-- To change this template use File | Settings | File Templates.
--

local DROPPED_ITEM = 1

local dropped_item = {
    index = 0,
    index2 = 0,
    event_type = DROPPED_ITEM,
    indices_array = nil,
    back_node = nil,
    sprite = nil,
    shadow = nil,
    height_level = 0,
    position = cc.p(0.0, 0.0),
    counter = 0,
    counter_up_flag = true,
    item = nil,
    init = function(self, parent, main_position, item, position, height_level, index2)
        self:remove(parent)
        self.index2 = index2
        self.item = item
        self.position = position
        self.height_level = height_level
        self.back_node = display.newNode()
        :move(self.position.x - main_position.x + display.cx, self.position.y - main_position.y + display.cy)
        :addTo(parent, math.floor(display.top - (self.position.y - main_position.y + display.cy)))
        self.sprite = display.newSprite(self.item.type.icon)
        :move(0.5, 40.0)
        :addTo(self.back_node)
        self.shadow = display.newSprite("character/c_shadow.png")
        :move(0.5, 0.0)
        :addTo(self.back_node)
    end,
    update_position = function(self, parent, main_position, height_level)
        if self.back_node ~= nil then
            parent:reorderChild(self.back_node, math.floor(display.top - (self.position.y - main_position.y + display.cy)))
            self.back_node:move(self.position.x - main_position.x + display.cx, self.position.y - main_position.y + display.cy)
            if self.height_level ~= 0 and height_level ~= self.height_level then
                if self.back_node:isVisible() == true then
                    self.back_node:setVisible(false)
                end
            else
                if self.back_node:isVisible() == false then
                    self.back_node:setVisible(true)
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
                self.back_node = display.newNode()
                :move(self.position.x - main_position.x + display.cx, self.position.y - main_position.y + display.cy)
                :addTo(parent, math.floor(display.top - (self.position.y - main_position.y + display.cy)))
                self.sprite = display.newSprite(self.item.type.icon)
                :setAnchorPoint(0.5, 0.5)
                :move(0.0, 40.0)
                :addTo(self.back_node)
                self.shadow = display.newSprite("character/c_shadow.png")
                :setAnchorPoint(0.5, 0.5)
                :move(0.0, 0.0)
                :addTo(self.back_node)
            end
        end
    end,
    update_counter = function(self, dt)
        if self.counter >= 10 then
            self.counter_up_flag = false
        end
        if self.counter <= -5 then
            self.counter_up_flag = true
        end
        if self.sprite ~= nil then
            self.sprite:move(0.0, 40.0 + self.counter)
        end
        if self.counter_up_flag == true then
            self.counter = self.counter + dt * 20
        else
            self.counter = self.counter - dt * 20
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
        if self.shadow ~= nil then
            self.shadow:removeFromParentAndCleanup(true)
        end
        self.shadow = nil
        if self.back_ndoe ~= nil then
            self.back_node:removeFromParentAndCleanup(true)
        end
        self.back_node = nil
        if self.index2 ~= 0 then
            parent:remove_dropped_item(self)
        end
    end
}

function dropped_item:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.index = 0
    o.index2 = 0
    o.indices_array = nil
    o.back_node = nil
    o.sprite = nil
    o.shadow = nil
    o.height_level = 0
    o.position = cc.p(0.0, 0.0)
    o.counter = 0
    o.counter_up_flag = true
    o.item = nil
    return o
end

return dropped_item
