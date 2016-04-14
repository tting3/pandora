--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 2/24/2016
-- Time: 12:10 AM
-- To change this template use File | Settings | File Templates.
--


local oven_flame_motion = "OVEN_FLAME"

local oven_up_cols = 4
local oven_down_cols = 6

local cook_synthesis = require("app.logic.cook_synthesis")
local item_type = require("app.object.item_type")

local oven = {
    up = {},
    down = {},
    fire_on = false,
    sprite = nil,
    ignite = function(self)
        if self.fire_on == true then
            return true
        end
        local success = false
        for i = 1, oven_down_cols do
            if self.down[i] ~= nil then
                if self.down[i].type.burn_dur ~= nil and self.down[i].on_fire == nil then
                    self.down[i].heat_level = nil
                    self.down[i].on_fire = self.down[i].type.burn_dur
                    success = true
                end
            end
        end
        if success == true then
            self.fire_on = true
            self.sprite:setVisible(true)
        end
        return success
    end,
    put_out = function(self)
        if self.fire_on == false then
            return true
        end
        local success = false
        for i = 1, oven_down_cols do
            if self.down[i] ~= nil then
                if self.down[i].on_fire ~= nil then
                    self.down[i] = nil
                    success = true
                end
            end
        end
        if success == true then
            self.fire_on = false
            self.sprite:setVisible(false)
        end
        return success
    end,
    init_flame_sprite = function(self, parent_layer, i, j, tile, map)
        self.sprite = display.newSprite()
        self.sprite:setAnchorPoint(0.5, 0.0)
        self.sprite:move((i + 1) * tile.x, (map.y - j - 1) * tile.y + 5)
        self.sprite:addTo(parent_layer, 100)
        self.sprite:playAnimationForever(display.getAnimationCache(oven_flame_motion))
        if self.fire_on == false then
            self.sprite:setVisible(false)
        end
    end,
    update = function(self, parent, dt)
        for i = 1, oven_up_cols do
            if self.up[i] ~= nil then
                if self.up[i].fire_on ~= self.fire_on then
                    self.up[i].fire_on = self.fire_on
                end
                if self.fire_on == true and self.up[i].type.heat_dur ~= nil then
                    if self.up[i].heat_level == nil then
                        self.up[i].heat_level = 0
                        parent.cool_down:add_item(self.up[i])
                    end
                    if self.up[i].heat_level < 100 then
                        if self.up[i].heat_level + (100.0 / self.up[i].type.heat_dur) * dt <= 100 then
                            self.up[i].heat_level = self.up[i].heat_level + (100.0 / self.up[i].type.heat_dur) * dt
                        else
                            self.up[i].heat_level = 100
                        end
                    else
                        if self.up[i].type.char_dur ~= nil then
                            if self.up[i].heat_level + (100.0 / self.up[i].type.char_dur) * dt < 200 then
                                self.up[i].heat_level = self.up[i].heat_level + (100.0 / self.up[i].type.char_dur) * dt
                            else
                                self.up[i].num = self.up[i].type.burned.num
                                self.up[i].type = self.up[i].type.burned.type
                                if self.up[i].type.heat_dur == nil then
                                    self.up[i].heat_level = nil
                                end
                            end
                        else
                            self.up[i].heat_level = 100
                        end
                    end
                elseif self.up[i].type.heat_dur ~= nil and self.up[i].type.char_dur ~= nil then
                    if self.up[i].heat_level + (100.0 / self.up[i].type.char_dur) * dt >= 200 then
                        self.up[i].num = self.up[i].type.burned.num
                        self.up[i].type = self.up[i].type.burned.type
                        if self.up[i].type.heat_dur == nil then
                            self.up[i].heat_level = nil
                        end
                    end
                end
            end
        end
        local consuming_fuel = false
        for i = 1, oven_down_cols do
            if self.down[i] ~= nil then
                if self.down[i].fire_on ~= self.fire_on then
                    self.down[i].fire_on = self.fire_on
                end
                if self.fire_on == true then
                    if self.down[i].on_fire ~= nil then
                        if consuming_fuel == false then
                            consuming_fuel = true
                            if self.down[i].on_fire - dt > 0 then
                                self.down[i].on_fire = self.down[i].on_fire - dt
                            else
                                self.down[i].on_fire = self.down[i].type.burn_dur
                                self.down[i].num = self.down[i].num - 1
                                if self.down[i].num <= 0 then
                                    self.down[i] = nil
                                end
                            end
                        end
                    elseif self.down[i].type.burn_dur ~= nil then
                        self.down[i].on_fire = self.down[i].type.burn_dur
                        self.down[i].heat_level = nil
                    else
                        if self.down[i].heat_level == nil then
                            self.down[i].heat_level = 0
                            parent.cool_down:add_item(self.down[i])
                        end
                        if self.down[i].heat_level < 100 then
                            if self.down[i].heat_level + (100.0 / self.down[i].type.heat_dur) * dt <= 100 then
                                self.down[i].heat_level = self.down[i].heat_level + (100.0 / self.down[i].type.heat_dur) * dt
                            else
                                self.down[i].heat_level = 100
                            end
                        else
                            if self.down[i].type.melt_dur ~= nil then
                                if self.down[i].heat_level + (100.0 / self.down[i].type.melt_dur) * dt < 200 then
                                    self.down[i].heat_level = self.down[i].heat_level + (100.0 / self.down[i].type.melt_dur) * dt
                                else
                                end
                            else
                                self.down[i].heat_level = 100
                            end
                        end
                    end
                end
            end
        end
        for index, reaction in pairs(cook_synthesis) do
            local num_reactants = #(reaction.reactants)
            local reactants_matches = {}
            local matches_num = 0
            for j = 1, num_reactants do
                reactants_matches[j] = false
            end
            local real_reactants_index = {}
            for i = 1, oven_up_cols do
                if self.up[i] ~= nil and self.up[i].heat_level ~= nil and self.up[i].heat_level >= 100 then
                    for j = 1, num_reactants do
                        if reactants_matches[j] == false and self.up[i].type == reaction.reactants[j].type and self.up[i].num >= reaction.reactants[j].num then
                            reactants_matches[j] = true
                            matches_num = matches_num + 1
                            real_reactants_index[#real_reactants_index + 1] = i
                            break
                        end
                    end
                end
                if matches_num == num_reactants then
                    for ii = 1, #real_reactants_index do
                        self.up[real_reactants_index[ii]].heat_level = nil
                        self.up[real_reactants_index[ii]].on_fire = nil
                        self.up[real_reactants_index[ii]] = nil
                    end
                    for jj = 1, #(reaction.products) do
                        self.up[real_reactants_index[jj]] = {}
                        self.up[real_reactants_index[jj]].type = reaction.products[jj].type
                        self.up[real_reactants_index[jj]].num = reaction.products[jj].num
                        if self.up[real_reactants_index[jj]].type.heat_dur ~= nil then
                            self.up[real_reactants_index[jj]].heat_level = 100
                            parent.cool_down:add_item(self.up[real_reactants_index[jj]])
                        end
                    end
                    matches_num = 0
                    real_reactants_index = {}
                end
            end
        end
        if consuming_fuel == false then
            self.fire_on = false
            self.sprite:setVisible(false)
        end
    end,
    add_down = function(self, item)
        if item.type ~= item_type.CHAR then
            for i = 1, oven_down_cols do
                if self.down[i] == nil then
                    self.down[i] = item
                    return true
                end
            end
            return false
        else
            local nil_marker = 0
            for i = 1, oven_down_cols do
                if self.down[i] == nil and nil_marker == 0 then
                    nil_marker = i
                end
                if self.down[i] ~= nil and self.down[i].type == item.type then
                    local diff = self.down[i].type.stack_limit - self.down[i].num
                    if diff < item.num then
                        item.num = item.num - diff
                        self.down[i].num = self.down[i].num + diff
                    else
                        self.down[i].num = self.down[i].num + item.num
                        return true
                    end
                end
            end
            if nil_marker ~= 0 then
                self.down[nil_marker] = item
                return true
            end
            return false
        end
    end,
    add_up = function(self, item)
        if item.type ~= item_type.CHAR then
            for i = 1, oven_up_cols do
                if self.up[i] == nil then
                    self.up[i] = item
                    return true
                end
            end
            return false
        else
            local nil_marker = 0
            for i = 1, oven_up_cols do
                if self.up[i] == nil and nil_marker == 0 then
                    nil_marker = i
                end
                if self.up[i] ~= nil and self.up[i].type == item.type then
                    local diff = self.up[i].type.stack_limit - self.up[i].num
                    if diff < item.num then
                        item.num = item.num - diff
                        self.up[i].num = self.up[i].num + diff
                    else
                        self.up[i].num = self.up[i].num + item.num
                        return true
                    end
                end
            end
            if nil_marker ~= 0 then
                self.up[nil_marker] = item
                return true
            end
            return false
        end
    end
}

function oven:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.sprite = nil
    o.up = {}
    o.up.weight = 0
    o.down = {}
    o.down.weight = 0
    o.fire_on = false
    return o
end

return oven
