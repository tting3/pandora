
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

MainScene.RESOURCE_FILENAME = "MainScene.csb"


function MainScene:onCreate()
    self.olo = cc.Label:createWithSystemFont("olo", "", 50)
    :move(display.cx, display.top - 50)
    :setTextColor(cc.c3b(230, 214, 44))
    :addTo(self, 100)

    local rlayer = require("app.views.TableViewLayer").new(true)
    rlayer:setAnchorPoint(cc.p(0, 0))
    rlayer:setPosition(cc.p(0, 0))
    self:addChild(rlayer)

end

return MainScene
