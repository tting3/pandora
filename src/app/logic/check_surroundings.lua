--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 3/15/2016
-- Time: 11:32 AM
-- To change this template use File | Settings | File Templates.
--

local check_condition = function(self, m_character, minions, c_index, index, targets_list)
    if c_index == 0 then
        if minions[index].height_level ~= m_character.height_level and m_character.height_level ~= 0 then
            return -1
        end
        for i, target in pairs(self.targets_list) do
            if m_character == target then
                return 0
            end
        end
        return -1
    end
    if (minions[index].height_level ~= minions[c_index].height_level and minions[c_index].height_level ~= 0) or c_index == index then
        return -1
    end
    for i, target in pairs(targets_list) do
        if minions[c_index] == target then
            return c_index
        end
    end
    return -1
end

local check_block = function(self, m_character, minions, index, check_i, check_j, targets_list)
    if minions[index].map_characters[check_i][check_j][1] <= 0 then
        return -1
    end
    for check_index = 2, minions[index].map_characters[check_i][check_j][1] + 1 do
        local result = check_condition(self, m_character, minions, minions[index].map_characters[check_i][check_j][check_index], index, targets_list)
        if result ~= -1 then
            return result
        end
    end
    return -1
end

local check_surroundings = function(self, m_character, minions, index, sight, targets_list)
    local i = minions[index].position.x / 50.0
    local j = minions[index].position.y / 50.0
    i = math.floor(i) + 1
    j = math.floor(j) + 1
    local result
    result = check_block(self, m_character, minions, index, i, j, targets_list)
    if result ~= -1 then
        return result
    end
    local dis
    for dis = 1, sight do
        local check_i
        local check_j
        local check_index
        check_j = j - dis
        local result
        for check_i = i - dis, i + dis do
            result = check_block(self, m_character, minions, index, check_i, check_j, targets_list)
            if result ~= -1 then
                return result
            end
        end
        check_j = j + dis
        for check_i = i - dis, i + dis do
            result = check_block(self, m_character, minions, index, check_i, check_j, targets_list)
            if result ~= -1 then
                return result
            end
        end
        check_i = i - dis
        for check_j = j - dis, j + dis do
            result = check_block(self, m_character, minions, index, check_i, check_j, targets_list)
            if result ~= -1 then
                return result
            end
        end
        check_i = i + dis
        for check_j = j - dis, j + dis do
            result = check_block(self, m_character, minions, index, check_i, check_j, targets_list)
            if result ~= -1 then
                return result
            end
        end
    end
    return -1
end

return check_surroundings
