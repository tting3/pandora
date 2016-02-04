--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 2/4/2016
-- Time: 9:10 AM
-- To change this template use File | Settings | File Templates.
--

-- local rlayer = require("app.scenes.TableViewLayer").new()
--  rlayer:setAnchorPoint(ccp(0, 0))
--  rlayer:setPosition(ccp(0, 0))
--  self:addChild(rlayer)

local TableViewLayer = class("TableViewLayer", function()
    return display.newLayer()
end)

function TableViewLayer:ctor()
    self:onEnter()
end

function TableViewLayer.scrollViewDidScroll(view)
    --print("scrollViewDidScroll")
end

function TableViewLayer.scrollViewDidZoom(view)
    --print("scrollViewDidZoom")
end

function TableViewLayer.tableCellTouched(table,cell)
    release_print("cell touched at index: " .. cell:getIdx())
end

function TableViewLayer.cellSizeForTable(table,idx)
    return 50,50
end

function TableViewLayer.tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if cell == nil then
        cell = cc.TableViewCell:new()
        local table_bg = display.newSprite("block.png")
        table_bg:setAnchorPoint(cc.p(0,0))
        table_bg:setPosition(cc.p(0, 0))
        cell:addChild(table_bg)

        local label = cc.Label:createWithSystemFont("olo", "", 30)
        label:setAnchorPoint(cc.p(0.0, 0.0))
        label:setPosition(cc.p(0.0, 0.0))
        cell:addChild(label)
    end

    return cell
end

function TableViewLayer.numberOfCellsInTableView(table)
    return 10
end

function TableViewLayer:onEnter()
    local table_view = cc.TableView:create(cc.size(400, 400))
    table_view:setAnchorPoint(cc.p(0, 0))
    table_view:setDirection(kCCScrollViewDirectionVertical)
    table_view:move(300, 100)
    table_view:setBounceable(true)
    self:addChild(table_view)
    release_print("here")
    table_view:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN) --kCCTableViewFillBottomUp
    table_view:registerScriptHandler(self.scrollViewDidScroll,CCTableView.kTableViewScroll)
    table_view:registerScriptHandler(self.scrollViewDidZoom,CCTableView.kTableViewZoom)
    table_view:registerScriptHandler(self.tableCellTouched,CCTableView.kTableCellTouched)
    table_view:registerScriptHandler(self.cellSizeForTable,CCTableView.kTableCellSizeForIndex)
    table_view:registerScriptHandler(self.tableCellAtIndex,CCTableView.kTableCellSizeAtIndex)
    table_view:registerScriptHandler(self.numberOfCellsInTableView,CCTableView.kNumberOfCellsInTableView)
    table_view:reloadData()
end

return TableViewLayer