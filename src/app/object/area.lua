--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 3/31/2016
-- Time: 5:40 PM
-- To change this template use File | Settings | File Templates.
--

local area = {
    allowed_ids = {}
}

function area:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.allowed_ids = {}
    return o
end

return area
