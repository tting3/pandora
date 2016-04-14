--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 2/24/2016
-- Time: 3:09 PM
-- To change this template use File | Settings | File Templates.
--

local oven_up_cols = 4
local oven_down_cols = 6

local font = require("app.views.font")
local item_type = require("app.object.item_type")

local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
    copy = orig
    end
    return copy
end

local oven_view = class("oven_view", function()
    return display.newLayer()
end)

function oven_view:ctor(oven, x ,y, item_size, main_game)
    self:onEnter(oven, x ,y, item_size, main_game)
end

function oven_view.scrollViewDidScroll(view)
    --print("scrollViewDidScroll")
end

function oven_view.scrollViewDidZoom(view)
    --print("scrollViewDidZoom")
end

function oven_view.tableCellTouched(table, cell)
    --release_print("rows touched at index: " .. cell:getIdx())
end

function oven_view.cellSizeForTable(table,idx)
    return table.item_size.x, table.item_size.y
end

function oven_view.tableCellAtIndex(table, idx)
    local cell = cc.TableViewCell:new()

    if table.elements[idx + 1] ~= nil then
        local table_bg = display.newSprite("object/block.png")
        table_bg:setAnchorPoint(cc.p(0, 0))
        table_bg:setPosition(cc.p(0, 0))
        cell:addChild(table_bg)

        local item_bg = display.newSprite(table.elements[idx + 1].type.icon)
        item_bg:setAnchorPoint(cc.p(0, 0))
        item_bg:setPosition(cc.p(0, 0))
        cell:addChild(item_bg)
        if table.elements[idx + 1].type.stack_limit ~= 1 then
            local num = cc.Label:createWithTTF(tostring(table.elements[idx + 1].num), font.GREEK_FONT, 20)
            num:setAnchorPoint(cc.p(0, 0))
            num:setPosition(cc.p(5, 0))
            cell:addChild(num)
        end
        if table.elements[idx + 1].heat_level ~= nil and table.elements[idx + 1].heat_level ~= 0 then
            if table.elements[idx + 1].heat_level < 100 then
                local heat_level = cc.DrawNode:create()
                heat_level:drawSolidRect(cc.p(0, 0), cc.p(table.item_size.x, table.elements[idx + 1].heat_level / 100.0 * table.item_size.y), font.HEAT1)
                cell:addChild(heat_level)
            else
                local heat_level = cc.DrawNode:create()
                heat_level:drawSolidRect(cc.p(0, 0), cc.p(table.item_size.x, table.item_size.y), font.HEAT1)
                cell:addChild(heat_level)
                local heat_level = cc.DrawNode:create()
                heat_level:drawSolidRect(cc.p(0, 0), cc.p(table.item_size.x, (table.elements[idx + 1].heat_level - 100) / 100.0 * table.item_size.y), font.HEAT2)
                cell:addChild(heat_level)
            end
        elseif table.elements[idx + 1].on_fire ~= nil and table.elements[idx + 1].on_fire ~= 0 then
            local fuel_level = cc.DrawNode:create()
            fuel_level:drawSolidRect(cc.p(0, 0), cc.p(table.item_size.x, table.elements[idx + 1].on_fire / table.elements[idx + 1].type.burn_dur * table.item_size.y), font.FUEL)
            cell:addChild(fuel_level)
        end
    else
        local table_bg = display.newSprite("object/block.png")
        table_bg:setAnchorPoint(cc.p(0, 0))
        table_bg:setPosition(cc.p(0, 0))
        cell:addChild(table_bg)
    end
    return cell
end

function oven_view.numberOfCellsInTableView(table)
    return table.cols
end

function oven_view:update_fire_interact()
    if self.oven.fire_on == false then
        self.fire_interact:setNormalImage(display.newSprite("object/ignite.png"))
    else
        self.fire_interact:setNormalImage(display.newSprite("object/put_out.png"))
    end
end

function oven_view:check_drag(parent, touch)
    local x, y = touch:getLocation().x, touch:getLocation().y
    local left = self.table_view_up:getPositionX()
    local right = self.table_view_up:getPositionX() + self.table_view_up:getContentSize().width
    local bottom = self.table_view_up:getPositionY()
    local top = self.table_view_up:getPositionY() + self.table_view_up:getContentSize().height
    if x >= left and x < right and y >= bottom and y < top and parent.inventory_block_selected == nil and parent.inventory_selected == nil then
        if self.oven.fire_on == true and (parent.m_character.right_hand == nil or parent.m_character.right_hand.item.type ~= item_type.TONGS) and (parent.m_character.left_hand  or parent.m_character.left_hand.item.type ~= item_type.TONGS) then
            parent.m_character:create_dialog(parent, 2, "Not with my bare hands!")
            return
        end
        local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
        local j = 0
        parent.inventory_block_selected = cc.p(i, j)
        parent.inventory_selected_size = cc.p(oven_up_cols, 1)
        parent.inventory_selected = self.table_view_up.elements
        parent.inventory_init_pos = touch:getLocation()
        parent.hold_time = 0.0
        if parent.drag_item ~= nil then
            parent.drag_item:removeFromParentAndCleanup(true)
            parent.drag_item = nil
        end
    end
    local left = self.table_view_down:getPositionX()
    local right = self.table_view_down:getPositionX() + self.table_view_down:getContentSize().width
    local bottom = self.table_view_down:getPositionY()
    local top = self.table_view_down:getPositionY() + self.table_view_down:getContentSize().height
    if x >= left and x < right and y >= bottom and y < top and parent.inventory_block_selected == nil and parent.inventory_selected == nil then
        if self.oven.fire_on == true and (parent.m_character.right_hand == nil or parent.m_character.right_hand.item.type ~= item_type.TONGS) and (parent.m_character.left_hand  or parent.m_character.left_hand.item.type ~= item_type.TONGS) then
            parent.m_character:create_dialog(parent, 2, "Not with my bare hands!")
            return
        end
        local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
        local j = 0
        if self.table_view_down.elements[i + j * oven_down_cols] ~= nil and self.table_view_down.elements[i + j * oven_down_cols].on_fire ~= nil then
            return
        end
        parent.inventory_block_selected = cc.p(i, j)
        parent.inventory_selected_size = cc.p(oven_down_cols, 1)
        parent.inventory_selected = self.table_view_down.elements
        parent.inventory_init_pos = touch:getLocation()
        parent.hold_time = 0.0
        if parent.drag_item ~= nil then
            parent.drag_item:removeFromParentAndCleanup(true)
            parent.drag_item = nil
        end
    end
end

function oven_view:check_drop(parent, touch)
    local function check(table_view, local_inventory_cols, i, j)
        if table_view.elements[i + j * local_inventory_cols] ~= nil and table_view.elements[i + j * local_inventory_cols].on_fire ~= nil then
            if parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x] ~= nil then
                parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x].num = parent.drag_item.item.num + parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x].num
                parent.inventory_selected.weight = parent.inventory_selected.weight + parent.drag_item.item.type.weight * parent.drag_item.item.num
            else
                parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x] = parent.drag_item.item
                parent.inventory_selected.weight = parent.inventory_selected.weight + parent.drag_item.item.type.weight * parent.drag_item.item.num
            end
            return
        end
        if (table_view.elements[i + j * local_inventory_cols] ~= nil and table_view.elements[i + j * local_inventory_cols].type == item_type.CHAR) or table_view.elements[i + j * local_inventory_cols] == nil then
            if table_view.elements[i + j * local_inventory_cols] ~= nil then
                if table_view.elements[i + j * local_inventory_cols].type ~= parent.drag_item.item.type then
                    if parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x] ~= nil then
                        parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x].num = parent.drag_item.item.num + parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x].num
                        parent.inventory_selected.weight = parent.inventory_selected.weight + parent.drag_item.item.type.weight * parent.drag_item.item.num
                    else
                        parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x] = parent.drag_item.item
                        parent.inventory_selected.weight = parent.inventory_selected.weight + parent.drag_item.item.type.weight * parent.drag_item.item.num
                    end
                else
                    parent.drag_item.item.num = parent.drag_item.item.num + table_view.elements[i + j * local_inventory_cols].num
                    table_view.elements.weight = table_view.elements.weight - table_view.elements[i + j * local_inventory_cols].type.weight * table_view.elements[i + j * local_inventory_cols].num
                    if parent.drag_item.item.num > table_view.elements[i + j * local_inventory_cols].type.stack_limit then
                        local num = parent.drag_item.item.num - table_view.elements[i + j * local_inventory_cols].type.stack_limit
                        parent.drag_item.item.num = table_view.elements[i + j * local_inventory_cols].type.stack_limit
                        table_view.elements[i + j * local_inventory_cols].num = num
                        if parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x] ~= nil then
                            parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x] = table_view.elements[i + j * local_inventory_cols]
                            parent.inventory_selected.weight = parent.inventory_selected.weight + table_view.elements[i + j * local_inventory_cols].type.weight * table_view.elements[i + j * local_inventory_cols].num
                        else
                            parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x] = table_view.elements[i + j * local_inventory_cols]
                            parent.inventory_selected.weight = parent.inventory_selected.weight + table_view.elements[i + j * local_inventory_cols].type.weight * table_view.elements[i + j * local_inventory_cols].num
                        end
                    end
                    table_view.elements[i + j * local_inventory_cols] = parent.drag_item.item
                    table_view.elements.weight = table_view.elements.weight + parent.drag_item.item.type.weight * parent.drag_item.item.num
                end
            else
                if parent.drag_item.item.type ~= item_type.CHAR then
                    table_view.elements[i + j * local_inventory_cols] = shallowcopy(parent.drag_item.item)
                    table_view.elements[i + j * local_inventory_cols].num = 1
                    table_view.elements.weight = table_view.elements.weight + table_view.elements[i + j * local_inventory_cols].type.weight * table_view.elements[i + j * local_inventory_cols].num
                    parent.drag_item.item.num = parent.drag_item.item.num - 1
                    if table_view.elements[i + j * local_inventory_cols].heat_level ~= nil then
                        parent.cool_down:add_item(table_view.elements[i + j * local_inventory_cols])
                    end
                    if parent.drag_item.item.num > 0 then
                        if parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x] ~= nil then
                            parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x].num = parent.drag_item.item.num + parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x].num
                            parent.inventory_selected.weight = parent.inventory_selected.weight + parent.drag_item.item.type.weight * parent.drag_item.item.num
                        else
                            parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x] = parent.drag_item.item
                            parent.inventory_selected.weight = parent.inventory_selected.weight + parent.drag_item.item.type.weight * parent.drag_item.item.num
                        end
                    end
                else
                    table_view.elements[i + j * local_inventory_cols] = parent.drag_item.item
                    table_view.elements.weight = table_view.elements.weight + parent.drag_item.item.type.weight * parent.drag_item.item.num
                end
            end
        else
            if parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x] ~= nil then
                parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x].num = parent.drag_item.item.num + parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x].num
                parent.inventory_selected.weight = parent.inventory_selected.weight + parent.drag_item.item.type.weight * parent.drag_item.item.num
            else
                parent.inventory_selected[parent.inventory_block_selected.x + parent.inventory_block_selected.y * parent.inventory_selected_size.x] = parent.drag_item.item
                parent.inventory_selected.weight = parent.inventory_selected.weight + parent.drag_item.item.type.weight * parent.drag_item.item.num
            end
        end
    end
    local out_side_flag = true
    local x, y = touch:getLocation().x, touch:getLocation().y
    local left = self.table_view_up:getPositionX()
    local right = self.table_view_up:getPositionX() + self.table_view_up:getContentSize().width
    local bottom = self.table_view_up:getPositionY()
    local top = self.table_view_up:getPositionY() + self.table_view_up:getContentSize().height
    if x >= left and x < right and y >= bottom and y < top then
        out_side_flag = false
        local local_inventory_cols = oven_up_cols
        local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
        local j = 0
        local table_view = self.table_view_up
        check(table_view, local_inventory_cols, i, j)
    end

    local left = self.table_view_down:getPositionX()
    local right = self.table_view_down:getPositionX() + self.table_view_down:getContentSize().width
    local bottom = self.table_view_down:getPositionY()
    local top = self.table_view_down:getPositionY() + self.table_view_down:getContentSize().height
    if x >= left and x < right and y >= bottom and y < top then
        out_side_flag = false
        local local_inventory_cols = oven_down_cols
        local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
        local j = 0
        local table_view = self.table_view_down
        check(table_view, local_inventory_cols, i, j)
    end
    self.table_view_up:reloadData()
    self.table_view_down:reloadData()
    return out_side_flag
end

function oven_view:onEnter(oven, x ,y, item_size, main_game)
    self.oven = oven

    self.oven_bg = display.newSprite("object/oven_interact.png")
    :setAnchorPoint(cc.p(0.5, 0.5))
    :move(x, y)
    self:addChild(self.oven_bg)

    self.fire_interact = cc.MenuItemImage:create("object/ignite.png", nil)
    :onClicked(function()
        if self.oven.fire_on == false then
            if self.oven:ignite() == true then
                self.fire_interact:setNormalImage(display.newSprite("object/put_out.png"))
                self.table_view_up:reloadData()
                self.table_view_down:reloadData()
            end
        else
            if self.oven:put_out() == true then
                self.fire_interact:setNormalImage(display.newSprite("object/ignite.png"))
                self.table_view_up:reloadData()
                self.table_view_down:reloadData()
            end
        end
    end)
    cc.Menu:create(self.fire_interact)
    :setAnchorPoint(cc.p(0.5, 0.5))
    :move(x, y - 150)
    :addTo(self)

    if self.oven.fire_on == false then
        self.fire_interact:setNormalImage(display.newSprite("object/ignite.png"))
    else
        self.fire_interact:setNormalImage(display.newSprite("object/put_out.png"))
    end

    self.table_view_up = cc.TableView:create(cc.size(oven_up_cols * item_size.x, 1 * item_size.y))
    self.table_view_up:setAnchorPoint(cc.p(0.0, 0.0))
    self.table_view_up:setDirection(kCCScrollViewDirectionHorizontal)
    self.table_view_up:move(x - oven_up_cols / 2 * item_size.x, y + 50)
    self.table_view_up:setBounceable(false)
    self.table_view_up:setTouchEnabled(true)
    self.table_view_up:setDelegate()
    self.table_view_up.elements = self.oven.up
    self.table_view_up.item_size = item_size
    self.table_view_up.main_game = main_game
    self.table_view_up.cols = oven_up_cols
    self.table_view_up.rows = 1
    self:addChild(self.table_view_up)
    self.table_view_up:setVerticalFillOrder(kCCTableViewFillTopDown) --kCCTableViewFillBottomUp
    self.table_view_up:registerScriptHandler(self.scrollViewDidScroll,CCTableView.kTableViewScroll)
    self.table_view_up:registerScriptHandler(self.scrollViewDidZoom,CCTableView.kTableViewZoom)
    self.table_view_up:registerScriptHandler(self.tableCellTouched,CCTableView.kTableCellTouched)
    self.table_view_up:registerScriptHandler(self.cellSizeForTable,CCTableView.kTableCellSizeForIndex)
    self.table_view_up:registerScriptHandler(self.tableCellAtIndex,CCTableView.kTableCellSizeAtIndex)
    self.table_view_up:registerScriptHandler(self.numberOfCellsInTableView,CCTableView.kNumberOfCellsInTableView)
    self.table_view_up:reloadData()

    self.table_view_down = cc.TableView:create(cc.size(oven_down_cols * item_size.x, 1 * item_size.y))
    self.table_view_down:setAnchorPoint(cc.p(0.0, 0.0))
    self.table_view_down:setDirection(kCCScrollViewDirectionHorizontal)
    self.table_view_down:move(x - oven_down_cols / 2 * item_size.x, y - 100)
    self.table_view_down:setBounceable(false)
    self.table_view_down:setTouchEnabled(true)
    self.table_view_down:setDelegate()
    self.table_view_down.elements = self.oven.down
    self.table_view_down.item_size = item_size
    self.table_view_down.main_game = main_game
    self.table_view_down.cols = oven_down_cols
    self.table_view_down.rows = 1
    self:addChild(self.table_view_down)
    self.table_view_down:setVerticalFillOrder(kCCTableViewFillTopDown) --kCCTableViewFillBottomUp
    self.table_view_down:registerScriptHandler(self.scrollViewDidScroll,CCTableView.kTableViewScroll)
    self.table_view_down:registerScriptHandler(self.scrollViewDidZoom,CCTableView.kTableViewZoom)
    self.table_view_down:registerScriptHandler(self.tableCellTouched,CCTableView.kTableCellTouched)
    self.table_view_down:registerScriptHandler(self.cellSizeForTable,CCTableView.kTableCellSizeForIndex)
    self.table_view_down:registerScriptHandler(self.tableCellAtIndex,CCTableView.kTableCellSizeAtIndex)
    self.table_view_down:registerScriptHandler(self.numberOfCellsInTableView,CCTableView.kNumberOfCellsInTableView)
    self.table_view_down:reloadData()
end

return oven_view
