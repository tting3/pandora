--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 2/19/2016
-- Time: 10:47 PM
-- To change this template use File | Settings | File Templates.
--

local inventory_cols_chest = 8
local inventory_rows_chest = 7

local chest = {
    inventory = {},
    inventory_size = inventory_cols_chest * inventory_rows_chest,
    key_sequence = nil,
    add_item = function(self, parent, item)
        local nil_marker = 0
        for i = 1, self.inventory_size do
            if self.inventory[i] == nil and nil_marker == 0 then
                nil_marker = i
            end
            if self.inventory[i] ~= nil and self.inventory[i].type == item.type then
                local diff = self.inventory[i].type.stack_limit - self.inventory[i].num
                if diff < item.num then
                    local heat = 0
                    if item.heat_level ~= nil then
                        heat = heat + item.heat_level * diff
                    end
                    if self.inventory[i].heat_level ~= nil then
                        heat = heat + self.inventory[i].heat_level * self.inventory[i].num
                    end
                    item.num = item.num - diff
                    self.inventory[i].num = self.inventory[i].num + diff
                    if heat ~= 0 then
                        if self.inventory[i].heat_level == nil then
                            parent.cool_down:add_item(self.inventory[i])
                        end
                        self.inventory[i].heat_level = heat / self.inventory[i].num
                    end
                else
                    local heat = 0
                    if item.heat_level ~= nil then
                        heat = heat + item.heat_level * item.num
                    end
                    if self.inventory[i].heat_level ~= nil then
                        heat = heat + self.inventory[i].heat_level * self.inventory[i].num
                    end
                    self.inventory[i].num = self.inventory[i].num + item.num
                    item.num = 0
                    if heat ~= 0 then
                        if self.inventory[i].heat_level == nil then
                            parent.cool_down:add_item(self.inventory[i])
                        end
                        self.inventory[i].heat_level = heat / self.inventory[i].num
                    end
                    return true
                end
            end
        end
        if nil_marker ~= 0 then
            self.inventory[nil_marker] = item
            return true
        end
        return false
    end
}

function chest:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.inventory = {}
    o.inventory.weight = 0
    o.inventory.weight_limit = math.huge
    o.inventory_size = inventory_cols_chest * inventory_rows_chest
    o.key_sequence = nil
    return o
end

return chest
