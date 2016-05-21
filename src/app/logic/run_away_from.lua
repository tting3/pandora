--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 4/19/2016
-- Time: 1:41 AM
-- To change this template use File | Settings | File Templates.
--

local DOWN = 0
local LEFT = 1
local RIGHT = 2
local UP = 3
local enter = 4
local leave = 5
local corner = 6

local run_away_from = function(ori_pos, ori_height_level, target_pos, target_height_level, map, structs)
    if ori_height_level == target_height_level then
        if ori_height_level == 0 then
            local i = ori_pos.x / 50.0
            local j = ori_pos.y / 50.0
            i = math.floor(i) + 1
            j = math.floor(j) + 1
            local struct_index = map[i][j]
            if struct_index == 0 then
                if math.abs(target_pos.x - ori_pos.x) >= math.abs(target_pos.y - ori_pos.y) then
                    if target_pos.x - ori_pos.x >= 0 then
                        return LEFT, nil
                    else
                        return RIGHT, nil
                    end
                else
                    if target_pos.y - ori_pos.y >= 0 then
                        return DOWN, nil
                    else
                        return UP, nil
                    end
                end
            else
                local point = cc.p(structs[struct_index].position.x, structs[struct_index].position.y)
                if target_pos.x - ori_pos.x < 0 then
                    point.x = point.x + (structs[struct_index].map.x + 1) * structs[struct_index].tile.x
                end
                if target_pos.y - ori_pos.y < 0 then
                    point.y = point.y + (structs[struct_index].map.y + 1) * structs[struct_index].tile.y
                end
                if ori_pos.x == point.x and ori_pos.y == point.y then
                    if math.abs(target_pos.x - ori_pos.x) >= math.abs(target_pos.y - ori_pos.y) then
                        if target_pos.x - ori_pos.x >= 0 then
                            return LEFT, nil
                        else
                            return RIGHT, nil
                        end
                    else
                        if target_pos.y - ori_pos.y >= 0 then
                            return DOWN, nil
                        else
                            return UP, nil
                        end
                    end
                end
                return corner, point
            end
        else
            return leave, nil
        end
    end
    return 0, nil
end

return run_away_from
