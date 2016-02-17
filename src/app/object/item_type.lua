--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/17/2016
-- Time: 6:55 AM
-- To change this template use File | Settings | File Templates.
--

local item_type = {
    COIN = {
        weight = 0,
        stack_limit = math.huge,
        icon = "object/coin.png"
    },
    CROP = {
        weight = 2,
        stack_limit = 12,
        icon = "object/crop.png"
    },
    SWORD = {
        weight = 10,
        stack_limit = 1,
        icon = "object/sword.png"
    },
    MASK = {
        weight = 1,
        stack_limit = 5,
        icon = "object/mask.png"
    },
    KEY = {
        weight = 0,
        stack_limit = 1,
        icon = "object/key.png"
    },
    APPLE = {
        weight = 1,
        stack_limit = 10,
        icon = "object/apple.png"
    }
}

return item_type
