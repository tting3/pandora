--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/11/2016
-- Time: 7:03 AM
-- To change this template use File | Settings | File Templates.
--

local item_type = require("app.object.item_type")

local plants_type = {
    CROP = {
        id = 1,
        harvest_time = 2,
        growth_time = 10,
        fruit_name = "background/fruit1.png",
        fruit = {
            item_type = item_type.CROP,
            num = 4
        }
    },
    APPLE = {
        id = 2,
        harvest_time = 4,
        growth_time = 10,
        fruit_name = "background/fruit2.png",
        fruit = {
            item_type = item_type.APPLE,
            num = 5
        }
    }
}

return plants_type
