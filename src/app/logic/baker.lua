--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/18/2016
-- Time: 9:33 AM
-- To change this template use File | Settings | File Templates.
--

local baker = {

}

function baker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

return baker
