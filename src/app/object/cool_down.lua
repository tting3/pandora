--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 2/26/2016
-- Time: 6:58 PM
-- To change this template use File | Settings | File Templates.
--

local cool_down = {
    items = {},
    max = 0,
    update = function(self, dt)
        for i = 1, self.max do
            if self.items[i] ~= nil and self.items[i].heat_level ~= nil then
                if self.items[i].fire_on == nil then
                    self.items[i].heat_level = self.items[i].heat_level - (100.0 / self.items[i].type.cool_down) * dt
                    if self.items[i].heat_level <= 0 then
                        self.items[i].heat_level = nil
                        self.items[i] = nil
                    end
                elseif self.items[i].fire_on == false then
                    self.items[i].heat_level = self.items[i].heat_level - (100.0 / self.items[i].type.cool_down) * dt / 2
                    if self.items[i].heat_level <= 0 then
                        self.items[i].heat_level = 0
                    end
                end
            else
                self.items[i] = nil
            end
        end
    end,
    add_item = function(self, item)
        local empty_index = 0
        for i = 1, self.max do
            if self.items[i] == nil then
                empty_index = i
            elseif self.items[i] == item then
                return
            end
        end
        if empty_index ~= 0 then
            self.items[empty_index] = item
        else
            self.max = self.max + 1
            self.items[self.max] = item
        end
    end
}

return cool_down