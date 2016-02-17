--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 2/4/2016
-- Time: 9:10 AM
-- To change this template use File | Settings | File Templates.
--

local font = require("app.views.font")

local inventory_row_view = class("inventory_row_view", function()
    return display.newLayer()
end)

function inventory_row_view:ctor(bounceable, new_elements, x, y, size, item_size, cols, row_index, direction, order, main_game)
    self:onEnter(bounceable, new_elements, x, y, size, item_size, cols, row_index, direction, order, main_game)
end

function inventory_row_view.scrollViewDidScroll(view)
    --print("scrollViewDidScroll")
end

function inventory_row_view.scrollViewDidZoom(view)
    --print("scrollViewDidZoom")
end

function inventory_row_view.tableCellTouched(table, cell)
    --release_print("cell touched at index: "..table.row_index..":" .. cell:getIdx())
    table.main_game:inventory_press_call_back(table.elements, table.row_index, cell:getIdx())
end

function inventory_row_view.cellSizeForTable(table,idx)
    return table.item_size.x, table.item_size.y
end

function inventory_row_view.tableCellAtIndex(table, idx)
    local cell = cc.TableViewCell:new()
    if table.elements[idx + 1 + table.cols * table.row_index] ~= nil then
        local table_bg = display.newSprite("object/block.png")
        table_bg:setAnchorPoint(cc.p(0, 0))
        table_bg:setPosition(cc.p(0, 0))
        cell:addChild(table_bg)

        local item_bg = display.newSprite(table.elements[idx + 1 + table.cols * table.row_index].type.icon)
        item_bg:setAnchorPoint(cc.p(0, 0))
        item_bg:setPosition(cc.p(0, 0))
        cell:addChild(item_bg)
        if table.elements[idx + 1 + table.cols * table.row_index].type.stack_limit ~= 1 then
            local num = cc.Label:createWithSystemFont(tostring(table.elements[idx + 1 + table.cols * table.row_index].num), font.GREEK_FONT, 20)
            num:setAnchorPoint(cc.p(0, 0))
            num:setPosition(cc.p(5, 0))
            cell:addChild(num)
        end
    else
        local table_bg = display.newSprite("object/block.png")
        table_bg:setAnchorPoint(cc.p(0, 0))
        table_bg:setPosition(cc.p(0, 0))
        cell:addChild(table_bg)
    end
    return cell
end

function inventory_row_view.numberOfCellsInTableView(table)
    return table.cols
end

function inventory_row_view:onEnter(bounceable, new_elements, x ,y, size, item_size, cols, row_index, direction, order, main_game)
    self.table_view = cc.TableView:create(size)
    self.table_view:setAnchorPoint(cc.p(0, 0))
    self.table_view:setDirection(direction)
    self.table_view:move(x, y)
    self.table_view:setBounceable(bounceable)
    self.table_view:setTouchEnabled(true)
    self.table_view:setDelegate()
    self.table_view.elements = new_elements
    self.table_view.item_size = item_size
    self.table_view.cols = cols
    self.table_view.row_index = row_index
    self.table_view.main_game = main_game
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

return inventory_row_view
