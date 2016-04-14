--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 2/27/2016
-- Time: 2:54 PM
-- To change this template use File | Settings | File Templates.
--

local item_type = require("app.object.item_type")

local cook_synthesis = {
    {
        reactants = {
            {
                type = item_type.CROP,
                num = 1
            },
            {
                type = item_type.CROP,
                num = 1
            },
            {
                type = item_type.CROP,
                num = 1
            }
        },
        products = {
            {
                type = item_type.BREAD,
                num = 1
            }
        }
    }
}

return cook_synthesis
