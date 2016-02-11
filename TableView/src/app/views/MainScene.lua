
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

MainScene.RESOURCE_FILENAME = "MainScene.csb"


function MainScene:onCreate()
    self.olo = cc.Label:createWithSystemFont("olo", "", 50)
    :move(display.cx, display.top - 50)
    :setTextColor(cc.c3b(230, 214, 44))
    :addTo(self, 100)

    local elements = {}
    for j = 0, 29 do
        for i = 1, 8 do
            if j < 15 then
                if (i + j * 8) % 2 == 1 then
                    elements[i + j * 8] = {back = "block.png", item = "sword.png"}
                else
                    elements[i + j * 8] = {back = "block.png", item = nil}
                end
            else
                if (i + j * 8) % 2 == 1 then
                    elements[i + j * 8] = {back = "block.png", item = nil}
                else
                    elements[i + j * 8] = {back = "block.png", item = "sword.png"}
                end
            end
        end
    end
    local rlayer = require("app.views.inventory").new(true, elements, 50, 100, 6, 40, cc.size(400, 400), cc.p(50, 50), kCCScrollViewDirectionVertical, kCCTableViewFillTopDown)
    rlayer:setAnchorPoint(cc.p(0, 0))
    rlayer:setPosition(cc.p(0, 0))
    self:addChild(rlayer)

    --[[
    local elements = {{back = "block.png", item = nil}, {back = "block.png", item = "sword.png"}}
    local rlayer = require("app.views.TableViewLayer").new(true, elements, display.right - 400, 0, cc.size(400, 50), cc.p(50, 50), kCCScrollViewDirectionHorizontal, kCCTableViewFillTopDown)
    rlayer:setAnchorPoint(cc.p(0, 0))
    rlayer:setPosition(cc.p(0, 0))
    self:addChild(rlayer)

    rlayer.table_view:move(display.right - table.getn(rlayer.elements)*50, 0)
    rlayer.elements[2].item = nil
    elements[2].item = "sword.png"
    rlayer.table_view:reloadData()
    ]]

end

return MainScene
