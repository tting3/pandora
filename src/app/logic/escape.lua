--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 4/13/2016
-- Time: 4:30 PM
-- To change this template use File | Settings | File Templates.
--

local escape = {
    escape_target = nil
}

function escape:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.escape_target = nil
    return o
end

return escape
