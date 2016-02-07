
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

MainScene.RESOURCE_FILENAME = "MainScene.csb"


function MainScene:onCreate()
    self.olo = cc.Label:createWithSystemFont("olo", "", 50)
    :move(display.cx, display.top - 50)
    :setTextColor(cc.c3b(230, 214, 44))
    :addTo(self, 100)

    local elements = {{back = "block.png", item = "sword.png"}, {back = "block.png", item = "sword.png"}, {back = "block.png", item = "sword.png"}}
    local rlayer = require("app.views.TableViewLayer").new(true, elements, 500, 100, cc.size(50, 400), cc.p(50, 50), kCCScrollViewDirectionVertical, kCCTableViewFillTopDown)
    rlayer:setAnchorPoint(cc.p(0, 0))
    rlayer:setPosition(cc.p(0, 0))
    self:addChild(rlayer)

    local elements = {{back = "block.png", item = nil}, {back = "block.png", item = "sword.png"}}
    local rlayer = require("app.views.TableViewLayer").new(true, elements, display.right - 400, 0, cc.size(400, 50), cc.p(50, 50), kCCScrollViewDirectionHorizontal, kCCTableViewFillTopDown)
    rlayer:setAnchorPoint(cc.p(0, 0))
    rlayer:setPosition(cc.p(0, 0))
    self:addChild(rlayer)

    rlayer.table_view:move(display.right - table.getn(rlayer.elements)*50, 0)
    rlayer.elements[2].item = nil
    elements[2].item = "sword.png"
    rlayer.table_view:reloadData()
end

return MainScene
