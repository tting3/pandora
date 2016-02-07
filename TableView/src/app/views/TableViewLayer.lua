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

function TableViewLayer:ctor(bounceable, new_elements, x, y, size, item_size, direction, order)
    self:onEnter(bounceable, new_elements, x, y, size, item_size, direction, order)
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
    return table.item_size.x, table.item_size.y
end

function TableViewLayer.tableCellAtIndex(table, idx)
    local cell = cc.TableViewCell:new()
    if table.elements[idx+1].back ~= nil then
        local table_bg = display.newSprite(table.elements[idx+1].back)
        table_bg:setAnchorPoint(cc.p(0, 0))
        table_bg:setPosition(cc.p(0, 0))
        cell:addChild(table_bg)
    end
    if table.elements[idx+1].item ~= nil then
        local item_bg = display.newSprite(table.elements[idx+1].item)
        item_bg:setAnchorPoint(cc.p(0, 0))
        item_bg:setPosition(cc.p(0, 0))
        cell:addChild(item_bg)
    end
    return cell
end

function TableViewLayer.numberOfCellsInTableView(TABLE)
    return table.getn(TABLE.elements)
end

function TableViewLayer:onEnter(bounceable, new_elements, x ,y, size, item_size, direction, order)
    self.elements = {}
    for i, element in pairs(new_elements) do
        self.elements[i] = {}
        self.elements[i].back = element.back
        self.elements[i].item = element.item
    end
    self.item_size = item_size
    self.table_view = cc.TableView:create(size)
    self.table_view:setAnchorPoint(cc.p(0, 0))
    self.table_view:setDirection(direction)
    self.table_view:move(x, y)
    self.table_view:setBounceable(bounceable)
    self.table_view:setTouchEnabled(true)
    self.table_view:setDelegate()
    self.table_view.elements = self.elements
    self.table_view.item_size = self.item_size
    self:addChild(self.table_view)
    self.table_view:setVerticalFillOrder(order) --kCCTableViewFillBottomUp
    self.table_view:registerScriptHandler(self.scrollViewDidScroll,CCTableView.kTableViewScroll)
    self.table_view:registerScriptHandler(self.scrollViewDidZoom,CCTableView.kTableViewZoom)
    self.table_view:registerScriptHandler(self.tableCellTouched,CCTableView.kTableCellTouched)
    self.table_view:registerScriptHandler(self.cellSizeForTable,CCTableView.kTableCellSizeForIndex)
    self.table_view:registerScriptHandler(self.tableCellAtIndex,CCTableView.kTableCellSizeAtIndex)
    self.table_view:registerScriptHandler(self.numberOfCellsInTableView,CCTableView.kNumberOfCellsInTableView)
    self.table_view:reloadData()
end

return TableViewLayer