--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 12/30/2015
-- Time: 8:34 PM
-- To change this template use File | Settings | File Templates.
--

local DAY_TIME = 120.0
local DAWN_TIME = 10.0
local NIGHT_TIME = 100.0
local DAWN = 0
local DAY = 1
local TWILIGHT = 2
local NIGHT = 3
local STOP = -1
local DOWN = 0
local LEFT = 1
local RIGHT = 2
local UP = 3
local inventory_cols = 6
local inventory_rows = 4
local normal_damage = 0
local bleed_damage = 1
local burn_damage = 2
local hurting = 0
local murdering = 1
local hurted_by_others = 1

local font = require("app.views.font")
local identity = require("app.logic.identity")
local minion_logic = require("app.logic.minion_logic")
local event = require("app.object.event")

local minion_motions = {}
minion_motions[identity.slave] = {}
minion_motions[identity.slave][DOWN] = "SLAVE_DOWN"
minion_motions[identity.slave][LEFT] = "SLAVE_LEFT"
minion_motions[identity.slave][RIGHT] = "SLAVE_RIGHT"
minion_motions[identity.slave][UP] = "SLAVE_UP"
minion_motions[identity.free_folk] = {}
minion_motions[identity.free_folk][DOWN] = "FREE_FOLK_DOWN"
minion_motions[identity.free_folk][LEFT] = "FREE_FOLK_LEFT"
minion_motions[identity.free_folk][RIGHT] = "FREE_FOLK_RIGHT"
minion_motions[identity.free_folk][UP] = "FREE_FOLK_UP"
minion_motions[identity.guard] = {}
minion_motions[identity.guard][DOWN] = "GUARD_DOWN"
minion_motions[identity.guard][LEFT] = "GUARD_LEFT"
minion_motions[identity.guard][RIGHT] = "GUARD_RIGHT"
minion_motions[identity.guard][UP] = "GUARD_UP"

local minion_motions_attack = {}
minion_motions_attack[identity.slave] = {}
minion_motions_attack[identity.slave][DOWN] = "SLAVE_ATTACK_DOWN"
minion_motions_attack[identity.slave][LEFT] = "SLAVE_ATTACK_LEFT"
minion_motions_attack[identity.slave][RIGHT] = "SLAVE_ATTACK_RIGHT"
minion_motions_attack[identity.slave][UP] = "SLAVE_ATTACK_UP"
minion_motions_attack[identity.free_folk] = {}
minion_motions_attack[identity.free_folk][DOWN] = "FREE_FOLK_ATTACK_DOWN"
minion_motions_attack[identity.free_folk][LEFT] = "FREE_FOLK_ATTACK_LEFT"
minion_motions_attack[identity.free_folk][RIGHT] = "FREE_FOLK_ATTACK_RIGHT"
minion_motions_attack[identity.free_folk][UP] = "FREE_FOLK_ATTACK_UP"
minion_motions_attack[identity.guard] = {}
minion_motions_attack[identity.guard][DOWN] = "GUARD_ATTACK_DOWN"
minion_motions_attack[identity.guard][LEFT] = "GUARD_ATTACK_LEFT"
minion_motions_attack[identity.guard][RIGHT] = "GUARD_ATTACK_RIGHT"
minion_motions_attack[identity.guard][UP] = "GUARD_ATTACK_UP"

local character = {
    main_game = nil,
    position = cc.p(0.0, 0.0),
    name = "",
    name_txt = nil,
    shadow = nil,
    asleep = false,
    sprite = nil,
    animated = false,
    last_act = DOWN,
    logic = nil,
    dir = STOP,
    last_act = STOP,
    height_level = 0,
    map_characters = nil,
    minions = nil,
    m_character = nil,
    last_map_index = -1,
    index = 0,
    id = identity.free_folk,
    occpuation = nil,
    hp = 100,
    happiness = 100,
    BIOCLK = {},
    top_speed = 2.0,
    speed = 2.0,
    left_hand = nil,
    right_hand = nil,
    left_hand_swing = false,
    right_hand_swing = false,
    head = nil,
    armor = nil,
    skills = {
        thief = 0,
        fight = 0,
        heal = 0,
        craft = 0
    },
    damage_sources = {},
    enermy_list = {},
    signals = {},
    shouting = nil,
    dialog = nil,
    inventory = {},
    inventory_size = inventory_cols * inventory_rows,
    events = {},
    bed = nil,
    last_frame_index = 1,
    chain_target = nil,
    chain_points = {},
    chain_points_height = {},
    chain_blocked = false,
    rope_node = nil,
    check_event = function(self, new_event)
        if new_event.type == hurting and self:check_enermy(new_event.initiator) ~= -1 then
            return -1
        end
        for i, old_event in pairs(self.events) do
            if old_event.type == new_event.type and old_event.initiator == new_event.initiator and old_event.accepter == new_event.accepter then
                return i
            end
        end
        return 0
    end,
    add_event = function(self, new_event)
        if self:check_event(new_event) ~= 0 then
            return
        end
        self.events[#self.events + 1] = new_event
    end,
    check_enermy = function(self, target)
        local num = #(self.enermy_list)
        for i = 1, num do
            if self.enermy_list[i] == target then
                return i
            end
        end
        return -1
    end,
    add_enermy = function(self, target)
        if self:check_enermy(target) ~= -1 then
            return
        end
        local num = #(self.enermy_list)
        self.enermy_list[num + 1] = target
    end,
    add_damage = function(self, damage)
        self.damage_sources[#self.damage_sources + 1] = damage
    end,
    check_damage = function(self, parent, minions, index, dt, time, date)
        local num = #self.damage_sources
        if num == 0 then
            return
        end
        local new_damage_index = 1
        local damage_type = normal_damage
        for i = 1, num do
            local damage = self.damage_sources[i]
            self.damage_sources[i] = nil
            local last_dur = damage.duration
            damage.duration = damage.duration - dt
            local times = math.floor(last_dur) - math.floor(damage.duration)
            if times > 0 then
                self.hp = self.hp - times * damage.value
            end
            if damage.duration > 0 then
                self.damage_sources[new_damage_index] = damage
                new_damage_index = new_damage_index + 1
            end
            if damage.type > damage_type then
                damage_type = damage.type
            end
            if damage.source ~= self then
                local new_event = event:new()
                new_event:init(hurting, damage.source, self, time, date, self.position, self.height_level)
                self:add_event(new_event)
                self:add_enermy(damage.source)
            end
        end
        if self.hp <= 0 then
            if self.right_hand ~= nil then
                self:remove_right_hand()
            end
            if self.left_hand ~= nil then
                self:remove_left_hand()
            end
            if self.dialog ~= nil then
                self.dialog.label:removeFromParentAndCleanup(true)
            end
            if self.rope_node ~= nil then
                self.rope_node:clear()
                self.rope_node = nil
                self.rope_body_node:clear()
                self.rope_body_node = nil
            end
            if self.sprite ~= nil then
                self.sprite:removeFromParentAndCleanup(true)
            end
            for i = 1, self.inventory_size do
                if self.inventory[i] ~= nil then
                    parent:drop_new_item(self.inventory[i], self.position, self.height_level)
                    self.inventory[i] = nil
                end
            end
            parent:drop_new_body(self.id, damage_type, self.position, self.height_level)
            local old_i = math.floor(self.position.x / 50.0) + 1
            local old_j = math.floor(self.position.y / 50.0) + 1
            local old_num = self.map_characters[old_i][old_j][1]
            for i = self.last_map_index, old_num + 1 do
                if i ~= old_num + 1 then
                    self.map_characters[old_i][old_j][i] = self.map_characters[old_i][old_j][i + 1]
                    if self.map_characters[old_i][old_j][i] ~= 0 and self.map_characters[old_i][old_j][i] ~= nil then
                        self.minions[self.map_characters[old_i][old_j][i]].last_map_index = self.minions[self.map_characters[old_i][old_j][i]].last_map_index - 1
                    end
                    if self.map_characters[old_i][old_j][i] == 0 then
                        self.m_character.last_map_index = self.m_character.last_map_index - 1
                    end
                else
                    self.map_characters[old_i][old_j][i] = nil
                end
            end
            self.map_characters[old_i][old_j][1] = old_num - 1
            if index ~= 0 then
                parent.minions[index] = nil
            else
                release_print("Game Over!")
            end
        end
    end,
    deal_damage = function(self, target, damage)
        self:add_enermy(target)
        target:add_damage(damage)
    end,
    find_damage_target = function(self, parent, damage)
        local offset_x = 0
        local offset_y = 0
        if self.last_act == DOWN then
            offset_y = -25
        elseif self.last_act == LEFT then
            offset_x = -25
        elseif self.last_act == RIGHT then
            offset_x = 25
        elseif self.last_act == UP then
            offset_y = 25
        end
        local position = cc.p(self.position.x + offset_x, self.position.y + offset_y)
        local i = math.floor(position.x / 50.0)
        local j = math.floor(position.y / 50.0)
        i = math.floor(i) + 1
        j = math.floor(j) + 1
        local target_dis = 0
        local target = nil
        local find_in_block = function(i, j)
            for index = 2, parent.map_characters[i][j][1] + 1 do
                local minion
                if parent.map_characters[i][j][index] == 0 then
                    minion = parent.m_character
                else
                    minion = parent.minions[parent.map_characters[i][j][index]]
                end
                if minion.index ~= self.index and minion.height_level == self.height_level then
                    local dis = (position.x - minion.position.x) * (position.x - minion.position.x) + (position.y - minion.position.y) * (position.y - minion.position.y)
                    if dis <= 25 * 25 then
                        dis = (self.position.x - minion.position.x) * (self.position.x - minion.position.x) + (self.position.y - minion.position.y) * (self.position.y - minion.position.y)
                        if target_dis > dis or target == nil then
                            target_dis = dis
                            target = minion
                        end
                    end
                end
            end
        end
        find_in_block(i, j)
        find_in_block(i + 1, j)
        find_in_block(i - 1, j)
        find_in_block(i, j + 1)
        find_in_block(i, j - 1)
        find_in_block(i + 1, j + 1)
        find_in_block(i + 1, j - 1)
        find_in_block(i - 1, j + 1)
        find_in_block(i - 1, j - 1)
        if target ~= nil then
            self:deal_damage(target, damage)
        end
    end,
    set_position = function(self, x, y)
        self.position = cc.p(x, y)
    end,
    enter_next_level = function(self)
        self.height_level = self.height_level + 1
        if self.main_game.light_status == NIGHT then
            self:change_night_level_shader()
        end
    end,
    enter_prev_level = function(self)
        self.height_level = self.height_level - 1
        if self.main_game.light_status == NIGHT then
            self:change_night_level_shader()
        end
    end,
    check_move = function(self, x, y, structs, map)
        if self:check_chained(x, y) == false then
            return false
        end
        local can_move = true
        local i = (self.position.x + x) / 50.0
        local j = (self.position.y + y) / 50.0
        i = math.floor(i) + 1
        j = math.floor(j) + 1
        local ii = map[i][j]
        if ii > 0 then
            local struct = structs[ii]
            local level = nil
            if self.height_level == 0 and struct.walls ~= nil then
                level = struct.walls
            end
            if self.height_level == 1 and struct.room1 ~= nil then
                level = struct.room1
            end
            if self.height_level == 2 and struct.room2 ~= nil then
                level = struct.room2
            end
            if self.height_level == 3 and struct.room3 ~= nil then
                level = struct.room3
            end
            if level ~= nil then
                local layer = level:layerNamed("collision")
                local function check(self, newx, newy)
                    local i =  (newx - struct.position.x) / struct.tile.x
                    local j =  (struct.position.y + struct.map.y * struct.tile.y - newy) / struct.tile.y
                    i = math.floor(i)
                    j = math.floor(j)
                    if i >= 0 and i < struct.map.x and j >= 0 and j < struct.map.y then
                        local gid = layer:tileGIDAt(cc.p(i, j))
                        local property = level:propertiesForGID(gid)
                        if self.height_level ~= 0 then
                            if property ~= 0 and property ~= 4 and property ~= 6 and property ~= 5 and property ~= 7 then
                                --self:set_name(self.position.x..""..self.position.y, 5.0)
                                --self:set_name(newx, 5.0)
                                can_move = false
                            end
                        else
                            if property ~= 0 and property ~= 4 and property ~= 6 and property ~= 5 then
                                --self:set_name(self.position.x..""..self.position.y, 5.0)
                                --self:set_name(newx, 5.0)
                                can_move = false
                            end
                        end
                    end
                end
                local newx = self.position.x + x
                local newy = self.position.y + y
                check(self, newx, newy)
            end
        end
        return can_move
    end,
    check_chained = function(self, x ,y)
        if self.right_hand ~= nil and self.right_hand.item.chained_target ~= nil and self.right_hand.item.chained_target.chain_blocked == true then
            local dis = (self.right_hand.item.chained_target.position.x - self.position.x) * (self.right_hand.item.chained_target.position.x - self.position.x) + (self.right_hand.item.chained_target.position.y - self.position.y) * (self.right_hand.item.chained_target.position.y - self.position.y)
            local new_dis = (self.right_hand.item.chained_target.position.x - self.position.x - x) * (self.right_hand.item.chained_target.position.x - self.position.x - x) + (self.right_hand.item.chained_target.position.y - self.position.y - y) * (self.right_hand.item.chained_target.position.y - self.position.y - y)
            if new_dis > dis then
                return false
            end
        end
        if self.left_hand ~= nil and self.left_hand.item.chained_target ~= nil and self.left_hand.item.chained_target.chain_blocked == true then
            local dis = (self.left_hand.item.chained_target.position.x - self.position.x) * (self.left_hand.item.chained_target.position.x - self.position.x) + (self.left_hand.item.chained_target.position.y - self.position.y) * (self.left_hand.item.chained_target.position.y - self.position.y)
            local new_dis = (self.left_hand.item.chained_target.position.x - self.position.x - x) * (self.left_hand.item.chained_target.position.x - self.position.x - x) + (self.left_hand.item.chained_target.position.y - self.position.y - y) * (self.left_hand.item.chained_target.position.y - self.position.y - y)
            if new_dis > dis then
                return false
            end
        end
        return true
    end,
    check_in_sight = function(self, target_pos, target_height_level, map, structs)
        if target_height_level ~= 0 then
            if target_height_level == self.height_level then
                return true
            else
                return false
            end
        else
            if self.height_level == 0 then
                local function check_under_roof(pos)
                    local i = pos.x / 50.0
                    local j = pos.y / 50.0
                    i = math.floor(i) + 1
                    j = math.floor(j) + 1
                    local struct_index = map[i][j]
                    if struct_index ~= 0 then
                        local level = structs[struct_index].roofs
                        if level ~= nil then
                            local struct_i = math.floor(i - 1 - structs[struct_index].position.x / 50)
                            local struct_j = math.floor(structs[struct_index].map.y - j + structs[struct_index].position.y / 50)
                            local function check_roofs(layer)
                                if layer ~= nil and struct_i >= 0 and struct_i < structs[struct_index].map.x and struct_j >= 0 and struct_j < structs[struct_index].map.y then
                                    local gid = layer:tileGIDAt(cc.p(struct_i, struct_j))
                                    local property = level:propertiesForGID(gid)
                                    if property ~= 0 then
                                        return struct_index
                                    end
                                end
                                return 0
                            end
                            local layer = level:layerNamed("front")
                            local result = check_roofs(layer)
                            if result ~= 0 then
                                return result
                            end
                            local layer = level:layerNamed("back")
                            local result = check_roofs(layer)
                            if result ~= 0 then
                                return result
                            end
                            local layer = level:layerNamed("deco")
                            local result = check_roofs(layer)
                            if result ~= 0 then
                                return result
                            end
                        end
                    end
                    return 0
                end
                local result = check_under_roof(target_pos)
                if result ~= 0 then
                    if result ~= check_under_roof(self.position) then
                        return false
                    end
                end
            end
            return true
        end
    end,
    change_position_m = function(self, x, y, structs, map, parent)
        if self:check_chained(x, y) == false then
            return -1 ,0
        end
        local leave_enter = -1
        local struct_index = 0
        local i = (self.position.x + x) / 50.0
        local j = (self.position.y + y) / 50.0
        i = math.floor(i) + 1
        j = math.floor(j) + 1
        local ii = map[i][j]
        if ii > 0 then
            local struct = structs[ii]
            local level = nil
            if self.height_level == 0 and struct.walls ~= nil then
                level = struct.walls
            end
            if self.height_level == 1 and struct.room1 ~= nil then
                level = struct.room1
            end
            if self.height_level == 2 and struct.room2 ~= nil then
                level = struct.room2
            end
            if self.height_level == 3 and struct.room3 ~= nil then
                level = struct.room3
            end
            if struct.in_vision == true and level ~= nil then
                local layer = level:layerNamed("collision")
                local function check(self, newx, newy, offset)
                    local i =  (newx - struct.position.x) / struct.tile.x
                    local j =  (struct.position.y + struct.map.y * struct.tile.y - newy) / struct.tile.y
                    i = math.floor(i)
                    j = math.floor(j)
                    if i >= 0 and i < struct.map.x and j >= 0 and j < struct.map.y then
                        local gid = layer:tileGIDAt(cc.p(i, j))
                        local property = level:propertiesForGID(gid)
                        if property == 1 or property == 2 or property == 3 then
                            return 0
                        end
                        if property == 6 or property == 7 then
                            if struct.doors[self.height_level][i][j].locked == true then
                                self:create_dialog(parent, 2, "Locked!")
                                return 0
                            end
                        end
                        local old_property = -1
                        local i =  (self.position.x - struct.position.x) / struct.tile.x
                        local j =  (struct.position.y + struct.map.y * struct.tile.y - self.position.y) / struct.tile.y
                        i = math.floor(i)
                        j = math.floor(j)
                        if i >= 0 and i < struct.map.x and j >= 0 and j < struct.map.y then
                            local old_gid = layer:tileGIDAt(cc.p(i, j))
                            old_property = level:propertiesForGID(old_gid)
                        end
                        if property == 4 then
                            if old_property ~= 4 then
                                self:enter_prev_level()
                                leave_enter = 0
                                struct_index = ii
                            end
                        end
                        if property == 5 then
                            if old_property ~= 5 then
                                self:enter_next_level()
                                leave_enter = 1
                                struct_index = ii
                            end
                        end
                        if property == 6 then
                            if old_property ~= 6 then
                                self:enter_prev_level()
                                leave_enter = 0
                                struct_index = ii
                            end
                        end
                        if property == 7 then
                            if old_property ~= 7 then
                                self:enter_next_level()
                                leave_enter = 1
                                struct_index = ii
                            end
                        end
                    end
                    return offset
                end
                local newx = self.position.x + x
                local newy = self.position.y
                x = check(self, newx, newy, x)
                local newx = self.position.x
                local newy = self.position.y + y
                y = check(self, newx, newy, y)
            end
        end
        self:update_position(x, y)
        return leave_enter, struct_index
    end,
    change_night_level_shader = function(self)
        if self.sprite == nil or self.sprite:isVisible() == false then
            return
        end
        if self.height_level ~= 0 then
            local night_char = cc.GLProgramCache:getInstance():getGLProgram("night_char"..self.height_level)
            if self.sprite:getGLProgram() ~= night_char then
                self.sprite:setGLProgram(night_char)
                if self.right_hand ~= nil and self.right_hand.sprite ~= nil then
                    self.right_hand.sprite:setGLProgram(night_char)
                end
                if self.left_hand ~= nil then
                    self.left_hand.sprite:setGLProgram(night_char)
                end
            end
        else
            local night_char = cc.GLProgramCache:getInstance():getGLProgram("night_char")
            if self.sprite:getGLProgram() ~= night_char then
                self.sprite:setGLProgram(night_char)
                if self.right_hand ~= nil and self.right_hand.sprite ~= nil then
                    self.right_hand.sprite:setGLProgram(night_char)
                end
                if self.left_hand ~= nil and self.left_hand.sprite ~= nil then
                    self.left_hand.sprite:setGLProgram(night_char)
                end
            end
        end
    end,
    set_gl = function(self, shader)
        self.sprite:setGLProgram(shader)
        if self.right_hand ~= nil and self.right_hand.sprite ~= nil then
            self.right_hand.sprite:setGLProgram(shader)
        end
        if self.left_hand ~= nil and self.left_hand.sprite ~= nil then
            self.left_hand.sprite:setGLProgram(shader)
        end
    end,
    update_position = function(self, x, y)
        self:update_map_characters(x, y)
        self.position = cc.p(self.position.x + x, self.position.y + y)
    end,
    change_position = function(self, x, y, sx, sy)
        self:update_position(x, y)
        if self.sprite ~= nil then
            self.sprite:move(self.position.x - sx + display.cx, self.position.y - sy + display.cy + 25)
        end
    end,
    set_name = function(self, name)
        self.name = name
        if self.sprite ~= nil and name ~= "" then
            if self.name_txt ~= nil then
                self.name_txt:removeFromParentAndCleanup(true)
                self.name_txt = nil
            end
            self.name_txt = cc.Label:createWithTTF(self.name, font.GREEK_FONT, 20)
                :move(25, 65)
                :setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
                :setTextColor(font.BLACK)
                :addTo(self.sprite)
        end
    end,
    set_id = function(self, new_id)
        self.id = new_id
        self.logic = minion_logic:new()
    end,
    add_shadow = function(self)
        self.shadow = display.newSprite("character/c_shadow.png")
            :setAnchorPoint(0.0, 0.5)
            :addTo(self.sprite)
    end,
    set_map_characters = function(self, new_map_characters, index, minions, m_character)
        self.index = index
        self.map_characters = new_map_characters
        self.minions = minions
        self.m_character = m_character
    end,
    update_map_characters = function(self, x, y)
        local new_i = math.floor((self.position.x + x) / 50.0) + 1
        local new_j = math.floor((self.position.y + y) / 50.0) + 1
        if self.last_map_index ~= -1 then
            local old_i = math.floor(self.position.x / 50.0) + 1
            local old_j = math.floor(self.position.y / 50.0) + 1
            if old_i == new_i and old_j == new_j then
                return
            end
            local old_num = self.map_characters[old_i][old_j][1]
            for i = self.last_map_index, old_num + 1 do
                if i ~= old_num + 1 then
                    self.map_characters[old_i][old_j][i] = self.map_characters[old_i][old_j][i + 1]
                    if self.map_characters[old_i][old_j][i] ~= 0 and self.map_characters[old_i][old_j][i] ~= nil then
                        self.minions[self.map_characters[old_i][old_j][i]].last_map_index = self.minions[self.map_characters[old_i][old_j][i]].last_map_index - 1
                    end
                    if self.map_characters[old_i][old_j][i] == 0 then
                        self.m_character.last_map_index = self.m_character.last_map_index - 1
                    end
                else
                    self.map_characters[old_i][old_j][i] = nil
                end
            end
            self.map_characters[old_i][old_j][1] = old_num - 1
        end
        local num = self.map_characters[new_i][new_j][1]
        num = num + 1
        self.map_characters[new_i][new_j][1] = num
        self.last_map_index = num + 1
        self.map_characters[new_i][new_j][num + 1] = self.index
    end,
    add_item = function(self, parent, item)
        local nil_marker = 0
        for i = 1, self.inventory_size do
            if self.inventory[i] == nil and nil_marker == 0 then
                nil_marker = i
            end
            if self.inventory[i] ~= nil and self.inventory[i].type == item.type then
                local diff = self.inventory[i].type.stack_limit - self.inventory[i].num
                if diff < item.num then
                    local heat = 0
                    if item.heat_level ~= nil then
                        heat = heat + item.heat_level * diff
                    end
                    if self.inventory[i].heat_level ~= nil then
                        heat = heat + self.inventory[i].heat_level * self.inventory[i].num
                    end
                    item.num = item.num - diff
                    self.inventory[i].num = self.inventory[i].num + diff
                    self.inventory.weight = self.inventory.weight + diff * item.type.weight
                    if heat ~= 0 then
                        if self.inventory[i].heat_level == nil then
                            parent.cool_down:add_item(self.inventory[i])
                        end
                        self.inventory[i].heat_level = heat / self.inventory[i].num
                    end
                else
                    local heat = 0
                    if item.heat_level ~= nil then
                        heat = heat + item.heat_level * item.num
                    end
                    if self.inventory[i].heat_level ~= nil then
                        heat = heat + self.inventory[i].heat_level * self.inventory[i].num
                    end
                    self.inventory[i].num = self.inventory[i].num + item.num
                    self.inventory.weight = self.inventory.weight + item.num * item.type.weight
                    item.num = 0
                    if heat ~= 0 then
                        if self.inventory[i].heat_level == nil then
                            parent.cool_down:add_item(self.inventory[i])
                        end
                        self.inventory[i].heat_level = heat / self.inventory[i].num
                    end
                    return true
                end
            end
        end
        if nil_marker ~= 0 then
            self.inventory[nil_marker] = item
            self.inventory.weight = self.inventory.weight + item.num * item.type.weight
            return true
        end
        return false
    end,
    find_key = function(self, key_sequence)
        if key_sequence == nil then
            return 1
        end
        for i = 1, self.inventory_size do
            if self.inventory[i] ~= nil and self.inventory[i].sequence == key_sequence then
                if self.inventory[i].heat_level ~= nil then
                    return -1
                end
                return 1
            end
        end
        return 0
    end,
    find_item = function(self, type, num)
        local results = {}
        for i = 1, self.inventory_size do
            if self.inventory[i] ~= nil and self.inventory[i].type == type then
                if num <= self.inventory[i].num then
                    results[#results + 1] = i
                    return results
                else
                    num = num - self.inventory[i].num
                    results[#results + 1] = i
                end
            end
        end
        return nil
    end,
    create_dialog = function(self, parent, duration, text)
        if self.dialog ~= nil then
            self.dialog.label:removeFromParentAndCleanup(true)
        end
        self.dialog = {}
        self.dialog.time = 0
        self.dialog.duration = duration
        self.dialog.label = display.newNode()
        :setAnchorPoint(0.0, 0.0)
        :move(display.cx + self.position.x - parent.m_character.position.x, display.cy + 50 + self.position.y - parent.m_character.position.y)
        :addTo(parent, 100)
        if string.len(text) <= 7 then
            self.dialog.bg = display.newSprite("character/dialog.png")
            :setAnchorPoint(0.0, 0.0)
            :move(0.0, 0.0)
            :addTo(self.dialog.label)
            self.dialog.text = cc.Label:createWithTTF(text, font.GREEK_FONT, 20)
            :setTextColor(font.BLACK)
            :setAnchorPoint(cc.p(0.5, 0.5))
            :move(75.0/2, 75.0/2 + 3)
            :addTo(self.dialog.label)
        elseif string.len(text) <= 14 then
            self.dialog.bg = display.newSprite("character/dialog_long.png")
            :setAnchorPoint(0.0, 0.0)
            :move(0.0, 0.0)
            :addTo(self.dialog.label)
            self.dialog.text = cc.Label:createWithTTF(text, font.GREEK_FONT, 20)
            :setTextColor(font.BLACK)
            :setAnchorPoint(cc.p(0.5, 0.5))
            :move(150.0/2, 75.0/2 + 5)
            :addTo(self.dialog.label)
        else
            self.dialog.bg = display.newSprite("character/dialog_very_long.png")
            :setAnchorPoint(0.0, 0.0)
            :move(0.0, 0.0)
            :addTo(self.dialog.label)
            self.dialog.text = cc.Label:createWithTTF(text, font.GREEK_FONT, 20)
            :setWidth(140)
            :setTextColor(font.BLACK)
            :setAnchorPoint(cc.p(0.5, 0.5))
            :move(150.0/2 + 13, 125.0/2 + 15)
            :addTo(self.dialog.label)
        end
    end,
    update_dialog = function(self, parent, dt)
        if self.dialog ~= nil then
            self.dialog.label:move(display.cx + self.position.x - parent.m_character.position.x, display.cy + 50 + self.position.y - parent.m_character.position.y)
            self.dialog.time = self.dialog.time + dt
            if self.dialog.time >= self.dialog.duration then
                self.dialog.bg:removeFromParentAndCleanup(true)
                self.dialog.text:removeFromParentAndCleanup(true)
                self.dialog.label:removeFromParentAndCleanup(true)
                self.dialog = nil
            end
        end
    end,
    bio_tik = function(self, dt)
        if self.asleep == false then
            if self.sleepiness_clk >= self.BIOCLK.sleepiness.start then
                self.issleepy = true
                if self.sleepiness_clk >= self.BIOCLK.sleepiness.start + self.BIOCLK.sleepiness.penalty_start and self.speed ~= self.top_speed * self.penalty.sleepiness then
                    self.speed = self.top_speed * self.penalty.sleepiness
                else
                    self.sleepiness_clk = self.sleepiness_clk + dt
                end
            else
                self.sleepiness_clk = self.sleepiness_clk + dt
            end
            if self.hunger_clk >= self.BIOCLK.hunger.start then
                self.ishungry = true
                if self.hunger_clk >= self.BIOCLK.hunger.start + self.BIOCLK.hunger.duration then
                    local damage = {value = self.penalty.hunger, duration = 0.0, type = normal_damage, source = self}
                    self:add_damage(damage)
                    self.hunger_clk = 0.0
                    self.ishungry = false
                    --release_print(self.hp)
                end
            end
            self.hunger_clk = self.hunger_clk + dt
        else
            if self.sleepiness_clk >= self.sleep_time then
                self.asleep = false
                self.sleepiness_clk = 0.0
                --release_print("Awaken")
                if self.bed ~= nil then
                    self.bed.in_use = false
                    self.bed = nil
                end
                self.speed = self.top_speed
            else
                self.sleepiness_clk = self.sleepiness_clk + dt
            end
        end
    end,
    consume_index = function(self, i)
        self:consume(self.inventory[i])
        self.inventory[i].num  = self.inventory[i].num - 1
        self.inventory.weight = self.inventory.weight - self.inventory[i].type.weight * 1
        if self.inventory[i].num <= 0 then
            self.inventory[i] = nil
        end
    end,
    consume = function(self, item)
        self.hunger_clk = 0.0
        self.ishungry = false
        self.hp = self.hp + 20
        if self.hp > 100 then
            self.hp = 100
        end
    end,
    sleep = function(self, parent, bed)
        self.bed = bed
        self.bed.in_use = true
        --release_print(tostring(bed))
        self.sleepiness_clk = 0.0
        self.asleep = true
        self.issleepy = false
        if self.right_hand ~= nil then
            self:remove_right_hand()
        end
        if self.left_hand ~= nil then
            self:remove_left_hand()
        end
        if parent.time < DAY_TIME + DAWN_TIME or parent.time >= DAY_TIME + DAWN_TIME + DAWN_TIME + NIGHT_TIME / 2 then
            self.sleep_time = self.BIOCLK.sleepiness.duration
        else
            self.sleep_time = DAY_TIME + DAWN_TIME + DAWN_TIME + NIGHT_TIME - parent.time
        end
    end,
    show_right_hand_item = function(self)
        self.right_hand.sprite = display.newSprite(self.right_hand.item.type.icon)
        self.right_hand.sprite:addTo(self.sprite, 10)
        self:update_right_hand(self.last_act, 1)
        if self.sprite:getGLProgram() ~= nil then
            self.right_hand.sprite:setGLProgram(self.sprite:getGLProgram())
        end
    end,
    remove_right_hand = function(self)
        self.right_hand.item.equipped = nil
        self.right_hand.item = nil
        if self.right_hand.sprite ~= nil then
            self.right_hand.sprite:removeFromParentAndCleanup(true)
        end
        self.right_hand = nil
    end,
    equip_right_hand = function(self, item)
        if self.right_hand ~= nil then
            self:remove_right_hand()
        end
        self.right_hand = {}
        self.right_hand.item = item
        if self.left_hand ~= nil and self.left_hand.item == item then
            self:remove_left_hand()
        end
        self.right_hand.item.equipped = 0
        if self.sprite ~= nil then
            self:show_right_hand_item()
        end
    end,
    show_left_hand_item = function(self)
        self.left_hand.sprite = display.newSprite(self.left_hand.item.type.icon)
        self.left_hand.sprite:addTo(self.sprite, 10)
        self:update_left_hand(self.last_act, 1)
        if self.sprite:getGLProgram() ~= nil then
            self.left_hand.sprite:setGLProgram(self.sprite:getGLProgram())
        end
    end,
    remove_left_hand = function(self)
        self.left_hand.item.equipped = nil
        self.left_hand.item = nil
        if self.left_hand.sprite ~= nil then
            self.left_hand.sprite:removeFromParentAndCleanup(true)
            self.left_hand.sprite = nil
        end
        self.left_hand = nil
    end,
    equip_left_hand = function(self, item)
        if self.left_hand ~= nil then
            if self.left_hand.sprite ~= nil then
                self.left_hand.item.equipped = nil
                self.left_hand.sprite:removeFromParentAndCleanup(true)
            end
        end
        self.left_hand = {}
        self.left_hand.item = item
        if self.right_hand ~= nil and self.right_hand.item == item then
            self:remove_right_hand()
        end
        self.left_hand.item.equipped = 1
        if self.sprite ~= nil then
            self:show_left_hand_item()
        end
    end,
    update_left_hand = function(self, dir, index)
        if self.left_hand.sprite == nil then
            return
        end
        if self.left_hand_swing == true then
            if dir == DOWN then
                self.left_hand.sprite:setZOrder(10)
                self.left_hand.sprite:move(25 - 4, 50 - 36.0 + (50 / 2 - 10) / 2 - 9 + 5)
                self.left_hand.sprite:setRotation(-45)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(40)
                self.left_hand.sprite:setSkewY(40)
            elseif dir == LEFT then
                self.left_hand.sprite:setZOrder(10)
                self.left_hand.sprite:move(29.0 - 8 - 7, 50 - 42.0 + 4)
                self.left_hand.sprite:setRotation(-45)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(0)
                self.left_hand.sprite:setSkewY(0)
            elseif dir == RIGHT then
                self.left_hand.sprite:setZOrder(-1)
                self.left_hand.sprite:move(29.0 + 11 + 7, 50 - 42.0 + 5)
                self.left_hand.sprite:setRotation(self.left_hand.item.type.degree)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(0)
                self.left_hand.sprite:setSkewY(0)
            elseif dir == UP then
                self.left_hand.sprite:setZOrder(-1)
                self.left_hand.sprite:move(4, -21 + 5)
                self.left_hand.sprite:setRotation(135)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(42)
                self.left_hand.sprite:setSkewY(42)
            end
            return
        end
        if dir == DOWN then
            if index == 1 or index == 4 then
                self.left_hand.sprite:setZOrder(10)
                self.left_hand.sprite:move(25 - 4, 50 - 36.0 + (50 / 2 - 10) / 2 - 10)
                self.left_hand.sprite:setRotation(-45)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(42)
                self.left_hand.sprite:setSkewY(42)
            elseif index == 2 or index == 5 then
                self.left_hand.sprite:setZOrder(10)
                self.left_hand.sprite:move(25 - 4, 50 - 36.0 + (50 / 2 - 10) / 2 - 9)
                self.left_hand.sprite:setRotation(-45)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(42)
                self.left_hand.sprite:setSkewY(42)
            elseif index == 3 then
                self.left_hand.sprite:setZOrder(10)
                self.left_hand.sprite:move(25 - 4, 50 - 36.0 + (50 / 2 - 10) / 2 - 5)
                self.left_hand.sprite:setRotation(-45)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(42)
                self.left_hand.sprite:setSkewY(42)
            elseif index == 6 then
                self.left_hand.sprite:setZOrder(10)
                self.left_hand.sprite:move(25 - 4, 50 - 36.0 + (50 / 2 - 10) / 2 - 7)
                self.left_hand.sprite:setRotation(-45)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(39)
                self.left_hand.sprite:setSkewY(39)
            end
        elseif dir == LEFT then
            if index == 1 or index == 4 then
                self.left_hand.sprite:setZOrder(10)
                self.left_hand.sprite:move(29.0 - 7, 50 - 42.0)
                self.left_hand.sprite:setRotation(-45)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(0)
                self.left_hand.sprite:setSkewY(0)
            elseif index == 2 or index == 5 then
                self.left_hand.sprite:setZOrder(10)
                self.left_hand.sprite:move(29.0 - 8, 50 - 42.0)
                self.left_hand.sprite:setRotation(-45)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(0)
                self.left_hand.sprite:setSkewY(0)
            elseif index == 3 then
                self.left_hand.sprite:setZOrder(10)
                self.left_hand.sprite:move(29.0 - 5, 50 - 39.0)
                self.left_hand.sprite:setRotation(-45)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(0)
                self.left_hand.sprite:setSkewY(0)
            elseif index == 6 then
                self.left_hand.sprite:setZOrder(10)
                self.left_hand.sprite:move(29.0 - 10, 50 - 39.0)
                self.left_hand.sprite:setRotation(-45)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(0)
                self.left_hand.sprite:setSkewY(0)
            end
        elseif dir == RIGHT then
            if index == 1 or index == 4 then
                self.left_hand.sprite:setZOrder(-1)
                self.left_hand.sprite:move(29.0 + 12, 50 - 42.0)
                self.left_hand.sprite:setRotation(self.left_hand.item.type.degree)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(0)
                self.left_hand.sprite:setSkewY(0)
            elseif index == 2 or index == 5 then
                self.left_hand.sprite:setZOrder(-1)
                self.left_hand.sprite:move(29.0 + 11, 50 - 42.0)
                self.left_hand.sprite:setRotation(self.left_hand.item.type.degree)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(0)
                self.left_hand.sprite:setSkewY(0)
            elseif index == 3 then
                self.left_hand.sprite:setZOrder(-1)
                self.left_hand.sprite:move(29.0 + 15, 50 - 39.0)
                self.left_hand.sprite:setRotation(self.left_hand.item.type.degree)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(0)
                self.left_hand.sprite:setSkewY(0)
            elseif index == 6 then
                self.left_hand.sprite:setZOrder(-1)
                self.left_hand.sprite:move(29.0 + 9, 50 - 39.0)
                self.left_hand.sprite:setRotation(self.left_hand.item.type.degree)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(0)
                self.left_hand.sprite:setSkewY(0)
            end
        elseif dir == UP then
            if index == 1 or index == 4 then
                self.left_hand.sprite:setZOrder(-1)
                self.left_hand.sprite:move(4, -21)
                self.left_hand.sprite:setRotation(135)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(42)
                self.left_hand.sprite:setSkewY(42)
            elseif index == 2 or index == 5 then
                self.left_hand.sprite:setZOrder(-1)
                self.left_hand.sprite:move(4, -21)
                self.left_hand.sprite:setRotation(135)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(42)
                self.left_hand.sprite:setSkewY(42)
            elseif index == 3 then
                self.left_hand.sprite:setZOrder(-1)
                self.left_hand.sprite:move(4, -19)
                self.left_hand.sprite:setRotation(135)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(39)
                self.left_hand.sprite:setSkewY(39)
            elseif index == 6 then
                self.left_hand.sprite:setZOrder(-1)
                self.left_hand.sprite:move(4, -21)
                self.left_hand.sprite:setRotation(135)
                self.left_hand.sprite:setScale(0.5, 0.5)
                self.left_hand.sprite:setSkewX(42)
                self.left_hand.sprite:setSkewY(42)
            end
        end
    end,
    update_right_hand = function(self, dir, index)
        if self.right_hand.sprite == nil then
            return
        end
        if self.right_hand_swing == true then
            if dir == DOWN then
                self.right_hand.sprite:setZOrder(10)
                self.right_hand.sprite:move(4, 50 - 36.0 + (50 / 2 - 10) / 2 - 9 + 5)
                self.right_hand.sprite:setRotation(-45)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(40)
                self.right_hand.sprite:setSkewY(40)
            elseif dir == LEFT then
                self.right_hand.sprite:setZOrder(-1)
                self.right_hand.sprite:move(16.0 - 8 - 7, 50 - 41.0 + 4)
                self.right_hand.sprite:setRotation(-45)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(0)
                self.right_hand.sprite:setSkewY(0)
            elseif dir == RIGHT then
                self.right_hand.sprite:setZOrder(10)
                self.right_hand.sprite:move(16.0 + 12 + 7, 50 - 40.0 + 5)
                self.right_hand.sprite:setRotation(self.right_hand.item.type.degree)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(0)
                self.right_hand.sprite:setSkewY(0)
            elseif dir == UP then
                self.right_hand.sprite:setZOrder(-1)
                self.right_hand.sprite:move(23, -21 + 5)
                self.right_hand.sprite:setRotation(135)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(42)
                self.right_hand.sprite:setSkewY(42)
            end
            return
        end
        if dir == DOWN then
            if index == 1 or index == 4 then
                self.right_hand.sprite:setZOrder(10)
                self.right_hand.sprite:move(4, 50 - 36.0 + (50 / 2 - 10) / 2 - 10)
                self.right_hand.sprite:setRotation(-45)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(42)
                self.right_hand.sprite:setSkewY(42)
            elseif index == 2 or index == 5 then
                self.right_hand.sprite:setZOrder(10)
                self.right_hand.sprite:move(4, 50 - 36.0 + (50 / 2 - 10) / 2 - 9)
                self.right_hand.sprite:setRotation(-45)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(42)
                self.right_hand.sprite:setSkewY(42)
            elseif index == 3 then
                self.right_hand.sprite:setZOrder(10)
                self.right_hand.sprite:move(4, 50 - 36.0 + (50 / 2 - 10) / 2 - 7)
                self.right_hand.sprite:setRotation(-45)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(42)
                self.right_hand.sprite:setSkewY(42)
            elseif index == 6 then
                self.right_hand.sprite:setZOrder(10)
                self.right_hand.sprite:move(4, 50 - 36.0 + (50 / 2 - 10) / 2 - 5)
                self.right_hand.sprite:setRotation(-45)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(39)
                self.right_hand.sprite:setSkewY(39)
            end
        elseif dir == LEFT then
            if index == 1 or index == 4 then
                self.right_hand.sprite:setZOrder(-1)
                self.right_hand.sprite:move(16.0 - 7, 50 - 42.0)
                self.right_hand.sprite:setRotation(-45)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(0)
                self.right_hand.sprite:setSkewY(0)
            elseif index == 2 or index == 5 then
                self.right_hand.sprite:setZOrder(-1)
                self.right_hand.sprite:move(16.0 - 8, 50 - 41.0)
                self.right_hand.sprite:setRotation(-45)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(0)
                self.right_hand.sprite:setSkewY(0)
            elseif index == 3 then
                self.right_hand.sprite:setZOrder(-1)
                self.right_hand.sprite:move(16.0 - 10, 50 - 39.0)
                self.right_hand.sprite:setRotation(-45)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(0)
                self.right_hand.sprite:setSkewY(0)
            elseif index == 6 then
                self.right_hand.sprite:setZOrder(-1)
                self.right_hand.sprite:move(16.0 - 4, 50 - 39.0)
                self.right_hand.sprite:setRotation(-45)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(0)
                self.right_hand.sprite:setSkewY(0)
            end
        elseif dir == RIGHT then
            if index == 1 or index == 4 then
                self.right_hand.sprite:setZOrder(10)
                self.right_hand.sprite:move(16.0 + 12, 50 - 42.0)
                self.right_hand.sprite:setRotation(self.right_hand.item.type.degree)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(0)
                self.right_hand.sprite:setSkewY(0)
            elseif index == 2 or index == 5 then
                self.right_hand.sprite:setZOrder(10)
                self.right_hand.sprite:move(16.0 + 12, 50 - 40.0)
                self.right_hand.sprite:setRotation(self.right_hand.item.type.degree)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(0)
                self.right_hand.sprite:setSkewY(0)
            elseif index == 3 then
                self.right_hand.sprite:setZOrder(10)
                self.right_hand.sprite:move(16.0 + 9, 50 - 39.0)
                self.right_hand.sprite:setRotation(self.right_hand.item.type.degree)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(0)
                self.right_hand.sprite:setSkewY(0)
            elseif index == 6 then
                self.right_hand.sprite:setZOrder(10)
                self.right_hand.sprite:move(16.0 + 15, 50 - 39.0)
                self.right_hand.sprite:setRotation(self.right_hand.item.type.degree)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(0)
                self.right_hand.sprite:setSkewY(0)
            end
        elseif dir == UP then
            if index == 1 or index == 4 then
                self.right_hand.sprite:setZOrder(-1)
                self.right_hand.sprite:move(23, -20)
                self.right_hand.sprite:setRotation(135)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(42)
                self.right_hand.sprite:setSkewY(42)
            elseif index == 2 or index == 5 then
                self.right_hand.sprite:setZOrder(-1)
                self.right_hand.sprite:move(23, -21)
                self.right_hand.sprite:setRotation(135)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(42)
                self.right_hand.sprite:setSkewY(42)
            elseif index == 3 then
                self.right_hand.sprite:setZOrder(-1)
                self.right_hand.sprite:move(23, -19)
                self.right_hand.sprite:setRotation(135)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(42)
                self.right_hand.sprite:setSkewY(42)
            elseif index == 6 then
                self.right_hand.sprite:setZOrder(-1)
                self.right_hand.sprite:move(23, -17)
                self.right_hand.sprite:setRotation(135)
                self.right_hand.sprite:setScale(0.5, 0.5)
                self.right_hand.sprite:setSkewX(39)
                self.right_hand.sprite:setSkewY(39)
            end
        end
    end,
    update_frame = function(self, dir, dt, sleep_gurge)
        local index = math.floor(self.frame_counter / 0.2) + 1
        if sleep_gurge == false and index ~= self.last_frame_index then
            if self.left_hand_swing == true and self.right_hand_swing == true then
                self.sprite:setSpriteFrame(display.getAnimationCache(minion_motions_attack[self.id][dir]):getFrames()[2]:getSpriteFrame())
            elseif self.left_hand_swing == true then
                self.sprite:setSpriteFrame(display.getAnimationCache(minion_motions_attack[self.id][dir]):getFrames()[1]:getSpriteFrame())
            elseif self.right_hand_swing == true then
                self.sprite:setSpriteFrame(display.getAnimationCache(minion_motions_attack[self.id][dir]):getFrames()[3]:getSpriteFrame())
            else
                self.sprite:setSpriteFrame(display.getAnimationCache(minion_motions[self.id][dir]):getFrames()[index]:getSpriteFrame())
            end
            if self.right_hand ~= nil then
                self:update_right_hand(dir, index)
            end
            if self.left_hand ~= nil then
                self:update_left_hand(dir, index)
            end
        end
        self.last_frame_index = index
        self.frame_counter = self.frame_counter + dt
        if self.frame_counter >= 0.2 * 6 then
            self.frame_counter = self.frame_counter - 0.2 *  6
        end
        if self.left_hand_swing == true or self.right_hand_swing == true then
            if self.swing_frame_counter >= 0.2 then
                self.left_hand_swing = false
                self.right_hand_swing = false
                self.swing_frame_counter = 0.0
            end
            self.swing_frame_counter = self.swing_frame_counter + dt
        end
    end,
    reset_frame = function(self, sleep_purge, dt)
        if sleep_purge == false then
            if self.last_frame_index == 1 and self.left_hand_swing == false and self.right_hand_swing == false then
                return
            end
            self.sprite:stopAllActions()
            if self.left_hand_swing == true and self.right_hand_swing == true then
                self.sprite:setSpriteFrame(display.getAnimationCache(minion_motions_attack[self.id][self.last_act]):getFrames()[2]:getSpriteFrame())
                if self.right_hand ~= nil then
                    self:update_right_hand(self.last_act, 1)
                end
                if self.left_hand ~= nil then
                    self:update_left_hand(self.last_act, 1)
                end
            elseif self.left_hand_swing == true then
                self.sprite:setSpriteFrame(display.getAnimationCache(minion_motions_attack[self.id][self.last_act]):getFrames()[1]:getSpriteFrame())
                if self.left_hand ~= nil then
                    self:update_left_hand(self.last_act, 1)
                end
            elseif self.right_hand_swing == true then
                self.sprite:setSpriteFrame(display.getAnimationCache(minion_motions_attack[self.id][self.last_act]):getFrames()[3]:getSpriteFrame())
                if self.right_hand ~= nil then
                    self:update_right_hand(self.last_act, 1)
                end
            else
                self.sprite:setSpriteFrame(display.getAnimationCache(minion_motions[self.id][self.last_act]):getFrames()[1]:getSpriteFrame())
                if self.right_hand ~= nil then
                    self:update_right_hand(self.last_act, 1)
                end
                if self.left_hand ~= nil then
                    self:update_left_hand(self.last_act, 1)
                end
            end
            if self.swing_frame_counter >= 0.2 then
                if self.left_hand_swing == true or self.right_hand_swing == true then
                    self.left_hand_swing = false
                    self.right_hand_swing = false
                    self.sprite:setSpriteFrame(display.getAnimationCache(minion_motions[self.id][self.last_act]):getFrames()[1]:getSpriteFrame())
                    if self.right_hand ~= nil then
                        self:update_right_hand(self.last_act, 1)
                    end
                    if self.left_hand ~= nil then
                        self:update_left_hand(self.last_act, 1)
                    end
                end
                self.last_frame_index = 1
                self.swing_frame_counter = 0.0
            end
            self.swing_frame_counter = self.swing_frame_counter + dt
        end
    end
}

function character:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.main_game = nil
    o.frame_counter = 0
    o.swing_frame_counter = 0
    o.position = cc.p(0.0, 0.0)
    o.name = ""
    o.name_txt = nil
    o.shadow = nil
    o.asleep = false
    o.sprite = nil
    o.animated = false
    o.last_act = DOWN
    o.logic = nil
    o.dir = STOP
    o.height_level = 0
    o.map_characters = nil
    o.minions = nil
    o.m_character = nil
    o.last_map_index = -1
    o.id = identity.free_folk
    o.occpuation = nil
    o.index = 0
    o.hp = 100
    o.happiness = 100
    o.BIOCLK = {
        hunger = {
            start = 50.0,
            duration = 20.0,
        },
        sleepiness = {
            start = 120.0,
            penalty_start = 20.0,
            duration = 100.0
        }
    }
    o.penalty = {
        hunger = 20.0,
        sleepiness = 0.5
    }
    o.hunger_clk = 0.0
    o.sleepiness_clk = 0.0
    o.ishungry = false
    o.issleepy = false
    o.top_speed = 2.0
    o.speed = o.top_speed
    o.left_hand = nil
    o.right_hand = nil
    o.left_hand_swing = false
    o.right_hand_swing = false
    o.head = nil
    o.armor = nil
    o.damage_sources = {}
    o.enermy_list = {}
    o.signals = {}
    for i = 1, 5 do
        o.signals[i] = 0
    end
    o.shouting = nil
    o.dialog = nil
    o.inventory = {}
    o.inventory_size = inventory_cols * inventory_rows
    o.inventory.weight = 0
    o.inventory.weight_limit = 100
    o.skills.thief = 0
    o.skills.fight = 0
    o.skills.heal = 0
    o.skills.craft = 0
    o.events = {}
    o.bed = nil
    o.last_frame_index = 1
    o.chain_target = nil
    o.chain_points = {}
    o.chain_points_height = {}
    o.chain_blocked = false
    o.rope_node = nil
    return o
end

return character
