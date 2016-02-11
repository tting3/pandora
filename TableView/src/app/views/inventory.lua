--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 2/10/2016
-- Time: 10:20 AM
-- To change this template use File | Settings | File Templates.
--

local inventory = class("inventory", function()
    return display.newLayer()
end)

function inventory:ctor(bounceable, new_elements, x, y, cols, rows, size, item_size, direction, order)
    self:onEnter(bounceable, new_elements, x, y, cols, rows, size, item_size, direction, order)
end

function inventory.scrollViewDidScroll(view)
    --print("scrollViewDidScroll")
end

function inventory.scrollViewDidZoom(view)
    --print("scrollViewDidZoom")
end

function inventory.tableCellTouched(table, cell)
    --release_print("rows touched at index: " .. cell:getIdx())
end

function inventory.cellSizeForTable(table,idx)
    return table.item_size.x, table.item_size.y
end

function inventory.tableCellAtIndex(table, idx)
    local cell = cc.TableViewCell:new()

    local elements = {}
    for i = 1, table.cols do
        elements[i] = table.elements[i + table.cols * idx]
    end
    local rlayer = require("app.views.TableViewLayer").new(false, elements, 0, 0, cc.size(table.cols*table.item_size.x, table.item_size.y), table.item_size, idx, kCCScrollViewDirectionHorizontal, kCCTableViewFillTopDown)
    rlayer:setAnchorPoint(cc.p(0, 0))
    rlayer:setPosition(cc.p(0, 0))
    cell:addChild(rlayer)

    return cell
end

function inventory.numberOfCellsInTableView(TABLE)
    return TABLE.rows
end

function inventory:onEnter(bounceable, new_elements, x ,y, cols, rows, size, item_size, direction, order)
    self.elements = {}
    for i, element in pairs(new_elements) do
        self.elements[i] = {}
        self.elements[i].back = element.back
        self.elements[i].item = element.item
    end
    self.table_view = cc.TableView:create(size)
    self.table_view:setAnchorPoint(cc.p(0, 0))
    self.table_view:setDirection(direction)
    self.table_view:move(x, y)
    self.table_view:setBounceable(bounceable)
    self.table_view:setTouchEnabled(true)
    --self.table_view:setDelegate()
    self.table_view.elements = self.elements
    self.table_view.item_size = item_size
    self.table_view.cols = cols
    self.table_view.rows = rows
    self.table_view.x = x
    self.table_view.y = y
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

return inventory