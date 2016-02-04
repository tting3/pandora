--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/28/2016
-- Time: 6:28 AM
-- To change this template use File | Settings | File Templates.
--

local cal_shortest_dis = require("app.logic.cal_shortest_dis")

local patrol = {
    target_structs = {},
    struct_index = -1,
    path = nil,
    patroling = function(self, minions, structs, map, index, dt)
        local function cal_pos_with_index(target_pos, tile, size)
            local x, y
            if minions[index].position.x >= target_pos.x and minions[index].position.x < target_pos.x + size.x * tile.x then
                x = minions[index].position.x
            end
            if minions[index].position.x < target_pos.x then
                x = target_pos.x
            end
            if minions[index].position.x >= target_pos.x + size.x * tile.x then
                x = target_pos.x + size.x * tile.x
            end
            if minions[index].position.y >= target_pos.y and minions[index].position.y < target_pos.y + size.y * tile.y then
                y = minions[index].position.y
            end
            if minions[index].position.y < target_pos.y then
                y = target_pos.y
            end
            if minions[index].position.y >= target_pos.y + size.y * tile.y then
                y = target_pos.y + size.y * tile.y
            end
            return cc.p(x, y)
        end
        if self.path == nil then
            self.path = cal_shortest_dis:new()
            self.path.points[self.path.point_index] = minions[index].position
            math.randomseed(os.time() + index)
            local struct_index = self.target_structs[math.random(table.getn(self.target_structs))]
            self.struct_index = struct_index
        end
        self.path.dest = cal_pos_with_index(structs[self.struct_index].position, structs[self.struct_index].map, structs[self.struct_index].tile)
        if self.path:cal(minions, structs, map, index, dt) == true then
            self.path = nil
        end
    end
}

function patrol:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.target_structs = {}
    o.struct_index = -1
    o.path = nil
    return o
end

return patrol
