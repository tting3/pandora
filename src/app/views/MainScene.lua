
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

MainScene.RESOURCE_FILENAME = "MainScene.csb"

local font = require("app.views.font")

function MainScene:onCreate()
    --printf("resource node = %s", tostring(self:getResourceNode()))

    local playButton = cc.MenuItemImage:create("PlayButton.png", "PlayButton.png")
    :onClicked(function()
        self:getApp():enterScene("SecondScene")
    end)
    cc.Menu:create(playButton)
    :move(display.cx, display.cy - 200)
    :addTo(self)

    cc.Label:createWithTTF("lol", font.GREEK_FONT, 100)
    :setTextColor(font.YELLOW)
    :align(display.CENTER, display.center)
    :addTo(self)

end

return MainScene
