--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 2/10/2016
-- Time: 10:20 AM
-- To change this template use File | Settings | File Templates.
--

local font = require("app.views.font")

local inventory_row_view = require("app.views.inventory_row_view")

local inventory_view = class("inventory_view", function()
    return display.newLayer()
end)

function inventory_view:ctor(bounceable, new_elements, x, y, cols, rows, size, item_size, direction, order, main_game)
    self:onEnter(bounceable, new_elements, x, y, cols, rows, size, item_size, direction, order, main_game)
end

function inventory_view.scrollViewDidScroll(view)
    --print("scrollViewDidScroll")
end

function inventory_view.scrollViewDidZoom(view)
    --print("scrollViewDidZoom")
end

function inventory_view.tableCellTouched(table, cell)
    --release_print("rows touched at index: " .. cell:getIdx())
end

function inventory_view.cellSizeForTable(table,idx)
    return table.item_size.x, table.item_size.y
end

function inventory_view.tableCellAtIndex(table, idx)
    local cell = cc.TableViewCell:new()

    local rlayer = inventory_row_view.new(false, table.elements, 0, 0, cc.size(table.cols*table.item_size.x, table.item_size.y), table.item_size, table.cols, idx, kCCScrollViewDirectionHorizontal, kCCTableViewFillTopDown, table.main_game)
    rlayer:setAnchorPoint(cc.p(0, 0))
    rlayer:setPosition(cc.p(0, 0))
    cell:addChild(rlayer)

    return cell
end

function inventory_view.numberOfCellsInTableView(table)
    return table.rows
end

function inventory_view:onEnter(bounceable, new_elements, x ,y, cols, rows, size, item_size, direction, order, main_game)
    self.table_view = cc.TableView:create(size)
    self.table_view:setAnchorPoint(cc.p(0, 0))
    self.table_view:setDirection(direction)
    self.table_view:move(x, y)
    self.table_view:setBounceable(bounceable)
    self.table_view:setTouchEnabled(true)
    --self.table_view:setDelegate()
    self.table_view.elements = new_elements
    self.table_view.item_size = item_size
    self.table_view.cols = cols
    self.table_view.rows = rows
    self.table_view.main_game = main_game
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

    self.inventory_bg = cc.DrawNode:create()
    self.inventory_bg:drawSolidRect(cc.p(x, y + item_size.y * rows), cc.p(x + item_size.x * cols, y + item_size.y * rows + 80), cc.c4f(0,0,0,150/255))
    self:addChild(self.inventory_bg)

    self.weight = cc.Label:createWithSystemFont("", font.GREEK_FONT, 30)
    self.weight:setAnchorPoint(cc.p(0.5, 0))
    self.weight:setPosition(cc.p(x + item_size.x * cols / 2, y + item_size.y * rows))
    self:addChild(self.weight)

    self.name = cc.Label:createWithSystemFont("", font.GREEK_FONT, 30)
    self.name:setAnchorPoint(cc.p(0.5, 0))
    self.name:setPosition(cc.p(x + item_size.x * cols / 2, y + item_size.y * rows + 30))
    self:addChild(self.name)
end

return inventory_view
