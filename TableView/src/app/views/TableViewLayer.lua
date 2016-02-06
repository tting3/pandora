--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 2/4/2016
-- Time: 9:10 AM
-- To change this template use File | Settings | File Templates.
--

local TableViewLayer = class("TableViewLayer", function()
    return display.newLayer()
end)

function TableViewLayer:ctor(bounceable)
    self:onEnter(bounceable)
end

function TableViewLayer.scrollViewDidScroll(view)
    --print("scrollViewDidScroll")
end

function TableViewLayer.scrollViewDidZoom(view)
    --print("scrollViewDidZoom")
end

function TableViewLayer.tableCellTouched(table, cell)
    release_print("cell touched at index: " .. cell:getIdx())
end

function TableViewLayer.cellSizeForTable(table,idx)
    return 400,50
end

function TableViewLayer.tableCellAtIndex(table, idx)
    local cell = cc.TableViewCell:new()
    local table_bg = display.newSprite("block.png")
    table_bg:setAnchorPoint(cc.p(0, 0))
    table_bg:setPosition(cc.p(0, 0))
    cell:addChild(table_bg)
    local item_bg = display.newSprite("sword.png")
    item_bg:setAnchorPoint(cc.p(0, 0))
    item_bg:setPosition(cc.p(0, 0))
    cell:addChild(item_bg)
    --[[
    local label = cc.Label:createWithSystemFont(idx.."", "", 30)
    label:setAnchorPoint(cc.p(0.0, 0.0))
    label:setPosition(cc.p(0.0, 0.0))
    cell:addChild(label)
    ]]
    return cell
end

function TableViewLayer.numberOfCellsInTableView(table)
    return 20
end

function TableViewLayer:onEnter(bounceable)
    local table_view = cc.TableView:create(cc.size(400, 400))
    table_view:setAnchorPoint(cc.p(0, 0))
    table_view:setDirection(kCCScrollViewDirectionVertical)
    table_view:move(300, 100)
    table_view:setBounceable(bounceable)
    table_view:setTouchEnabled(true)
    table_view:setDelegate()
    self:addChild(table_view)
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