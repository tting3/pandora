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
    path = nil,
    patroling = function(self, minions, structs, map, index, dt)
        if self.path == nil then
            self.path = cal_shortest_dis:new()
            self.path.points[self.path.point_index] = minions[index].position
            math.randomseed(os.time() + index)
            local struct_index = self.target_structs[math.random(table.getn(self.target_structs))]
            local corner = math.random(4)
            if corner == 1 then
                self.path.dest = cc.p(structs[struct_index].position.x, structs[struct_index].position.y)
            end
            if corner == 2 then
                self.path.dest = cc.p(structs[struct_index].position.x + (structs[struct_index].map.x) * structs[struct_index].tile.x, structs[struct_index].position.y)
            end
            if corner == 3 then
                self.path.dest = cc.p(structs[struct_index].position.x + (structs[struct_index].map.x) * structs[struct_index].tile.x, structs[struct_index].position.y + (structs[struct_index].map.y) * structs[struct_index].tile.y)
            end
            if corner == 4 then
                self.path.dest = cc.p(structs[struct_index].position.x, structs[struct_index].position.y + (structs[struct_index].map.y) * structs[struct_index].tile.y)
            end
        end
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
    o.path = nil
    return o
end

return patrol
