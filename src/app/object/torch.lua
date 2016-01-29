--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/22/2016
-- Time: 2:41 PM
-- To change this template use File | Settings | File Templates.
--

local torch = {
    position = cc.p(0, 0),
    sprite = nil,
}

function torch:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.position = cc.p(0, 0)
    o.sprite = nil
    return o
end

return torch
