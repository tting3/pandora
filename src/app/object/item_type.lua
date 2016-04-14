--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/17/2016
-- Time: 6:55 AM
-- To change this template use File | Settings | File Templates.
--

local normal_damage = 0
local bleed_damage = 1
local burn_damage = 2

local item_type = {
    COIN = {
        degree = 45,
        weight = 0,
        stack_limit = math.huge,
        icon = "object/coin.png",
        heat_dur = 15,
        cool_down = 10
    },
    CROP = {
        degree = 135,
        weight = 2,
        stack_limit = 12,
        icon = "object/crop.png",
        burn_dur = 7,
        heat_dur = 10,
        char_dur = 4,
        cool_down = 7
    },
    ROPE = {
        degree = 135,
        weight = 4,
        stack_limit = 1,
        icon = "object/rope.png",
        burn_dur = 15,
        heat_dur = 10,
        cool_down = 7
    },
    CHAR = {
        degree = 135,
        weight = 1,
        stack_limit = 10,
        icon = "object/char.png",
        burn_dur = 15
    },
    BREAD = {
        degree = 105,
        weight = 3,
        stack_limit = 4,
        icon = "object/bread.png",
        burn_dur = 10,
        heat_dur = 10,
        char_dur = 4,
        cool_down = 7
    },
    SWORD = {
        degree = 135,
        weight = 10,
        stack_limit = 1,
        icon = "object/sword.png",
        heat_dur = 20,
        melt_dur = 20,
        cool_down = 15,
        damage = {
            value = 20,
            dur = 0.0,
            type = bleed_damage
        }
    },
    TONGS = {
        degree = 135,
        weight = 5,
        stack_limit = 1,
        icon = "object/tongs.png",
        heat_dur = 20,
        melt_dur = 20,
        cool_down = 15
    },
    MASK = {
        degree = 45,
        weight = 1,
        stack_limit = 5,
        icon = "object/mask.png",
        heat_dur = 20,
        melt_dur = 20,
        cool_down = 15
    },
    KEY = {
        degree = 45,
        weight = 0,
        stack_limit = 1,
        icon = "object/key.png",
        heat_dur = 20,
        melt_dur = 20,
        cool_down = 15
    },
    APPLE = {
        degree = 45,
        weight = 1,
        stack_limit = 10,
        icon = "object/apple.png",
        burn_dur = 1,
        heat_dur = 2,
        char_dur = 4,
        cool_down = 1
    },
    IRON = {
        degree = 135,
        weight = 10,
        stack_limit = 3,
        icon = "object/iron.png",
        heat_dur = 20,
        cool_down = 15
    },
    COPPER = {
        degree = 135,
        weight = 12,
        stack_limit = 3,
        icon = "object/copper.png",
        heat_dur = 20,
        cool_down = 15
    },
    char_init = function(self)
        self.CROP.burned = {
            type = self.CHAR,
            num = 1
        }
        self.BREAD.burned = {
            type = self.CHAR,
            num = 3
        }
        self.APPLE.burned = {
            type = self.CHAR,
            num = 1
        }
    end
}

return item_type
