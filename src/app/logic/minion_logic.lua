--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/8/2016
-- Time: 4:05 AM
-- To change this template use File | Settings | File Templates.
--

local success = 1
local working = 0
local failed = -1
local DAWN = 0
local DAY = 1
local TWILIGHT = 2
local NIGHT = 3
local LOOKING_FOR_FARM = 0
local STOP = -1
local fixedDeltaTimeScale = 60.0

local hurted_by_others = 1

local identity = require("app.logic.identity")
local occupation = require("app.logic.occupation")
local baker = require("app.logic.baker")
local farmer = require("app.logic.farmer")
local thief = require("app.logic.thief")
local guardian_patrol = require("app.logic.guardian_patrol")
local sleep = require("app.logic.sleep")
local task = require("app.logic.task")
local drag = require("app.logic.drag")
local item_type = require("app.object.item_type")
local functionality = require("app.object.functionality")

local minion_logic = {
    curr_task = nil,
    queued_tasks = {},
    queued_tasks_num = 0,
    patroling_guardian_init = function(self, target_structs, new_targets_list)
        local task_index = self:find_task(task.PATROLING)
        if task_index == -1 then
            self.queued_tasks_num = self.queued_tasks_num + 1
            task_index = self.queued_tasks_num
        end
        self.queued_tasks[task_index] = guardian_patrol:new()
        self.queued_tasks[task_index].task_index = task_index
        self.queued_tasks[task_index].task_name = task.PATROLING
        self.queued_tasks[task_index]:patrol_init(target_structs, new_targets_list)
    end,
    farm_init = function(self, farm_index, storage_index, storage_level)
        local task_index = self:find_task(task.FARMING)
        if task_index == -1 then
            self.queued_tasks_num = self.queued_tasks_num + 1
            task_index = self.queued_tasks_num
        end
        self.queued_tasks[task_index] = farmer:new()
        self.queued_tasks[task_index].task_index = task_index
        self.queued_tasks[task_index].task_name = task.FARMING
        self.queued_tasks[task_index].farm_index = farm_index
        self.queued_tasks[task_index].storage_index = storage_index
        self.queued_tasks[task_index].storage_level = storage_level
    end,
    farm = function(self, parent, minions, structs, map, index, dt)
        if self.curr_task.task_name == task.FARMING then
            local result = self.curr_task:do_farming(parent, minions, structs, map, index, dt)
            if result == working then
            else
            end
        end
    end,
    bake_init = function(self, storage_index, storage_level, oven_index, oven_level)
        local task_index = self:find_task(task.BAKING)
        if task_index == -1 then
            self.queued_tasks_num = self.queued_tasks_num + 1
            task_index = self.queued_tasks_num
        end
        self.queued_tasks[task_index] = baker:new()
        self.queued_tasks[task_index].task_index = task_index
        self.queued_tasks[task_index].task_name = task.BAKING
        self.queued_tasks[task_index].storage_index = storage_index
        self.queued_tasks[task_index].storage_level = storage_level
        self.queued_tasks[task_index].oven_index = oven_index
        self.queued_tasks[task_index].oven_level = oven_level
    end,
    bake = function(self, parent, minions, structs, map, index, dt)
        if self.curr_task.task_name == task.BAKING then
            local result = self.curr_task:do_baking(parent, minions, structs, map, index, dt)
            if result == working then
            else
            end
        end
    end,
    sleep_init = function(self, sleep_index, bed_level)
        local task_index = self:find_task(task.GOING_TO_BED)
        if task_index == -1 then
            self.queued_tasks_num = self.queued_tasks_num + 1
            task_index = self.queued_tasks_num
        end
        self.queued_tasks[task_index] = sleep:new()
        self.queued_tasks[task_index].task_index = task_index
        self.queued_tasks[task_index].task_name = task.GOING_TO_BED
        self.queued_tasks[task_index].sleep_index = sleep_index
        self.queued_tasks[task_index].bed_level = bed_level
    end,
    go_to_bed = function(self, parent, minions, structs, map, index, dt)
        if self.curr_task.task_name == task.GOING_TO_BED then
            local result, bed = self.curr_task:go_to_bed(minions, structs, map, index, dt)
            if result == success and bed ~= nil then
                minions[index]:sleep(parent, bed)
                minions[index].dir = STOP
            end
        end
    end,
    thief_init = function(self, target_structs, new_ids_list)
        local task_index = self:find_task(task.STEALING)
        if task_index == -1 then
            self.queued_tasks_num = self.queued_tasks_num + 1
            task_index = self.queued_tasks_num
        end
        self.queued_tasks[task_index] = thief:new()
        self.queued_tasks[task_index].task_index = task_index
        self.queued_tasks[task_index].task_name = task.STEALING
        self.queued_tasks[task_index]:patrol_init(target_structs, new_ids_list)
    end,
    steal = function(self, m_character, minions, structs, map, index, dt)
        if self.curr_task.task_name == task.STEALING then
            local result = self.curr_task:steal(m_character, minions, structs, map, index, dt)
            if result == success then
            end
        end
    end,
    guardian_patroling = function(self, m_character, minions, structs, map, index, dt)
        if self.curr_task.task_name == task.PATROLING then
            local result = self.curr_task:patroling(m_character, minions, structs, map, index, dt)
            if result == success then
            end
        end
    end,
    farmer_logic = function(self, parent, m_character, minions, structs, time, map, index, dt)
        if minions[index].ishungry == true then
            local result = minions[index]:find_item(item_type.BREAD, 1)
            if result ~= nil then
                minions[index]:consume_index(result[1])
            end
        end
        if minions[index].issleepy == false and minions[index].asleep == false then
            if self.curr_task == nil then
                local task_index = self:find_task(task.FARMING)
                self.curr_task = self.queued_tasks[task_index]
            end
            if self.curr_task.task_name == task.GOING_TO_BED then
                self.curr_task:reset()
                local task_index = self:find_task(task.FARMING)
                self.curr_task = self.queued_tasks[task_index]
            end
            self:farm(parent, minions, structs, map, index, dt)
        else
            if minions[index].asleep == false then
                if self.curr_task == nil then
                    local task_index = self:find_task(task.GOING_TO_BED)
                    self.curr_task = self.queued_tasks[task_index]
                elseif self.curr_task.task_name == task.FARMING then
                    if self.curr_task.status == LOOKING_FOR_FARM then
                        self.curr_task:reset()
                        local task_index = self:find_task(task.GOING_TO_BED)
                        self.curr_task = self.queued_tasks[task_index]
                    else
                        self:farm(parent, minions, structs, map, index, dt)
                    end
                end
                if self.curr_task.task_name == task.GOING_TO_BED then
                    self:go_to_bed(parent, minions, structs, map, index, dt)
                end
            end
        end
    end,
    baker_logic = function(self, parent, m_character, minions, structs, time, map, index, dt)
        if minions[index].ishungry == true then
            local result = minions[index]:find_item(item_type.BREAD, 1)
            if result ~= nil then
                minions[index]:consume_index(result[1])
            end
        end
        if minions[index].issleepy == false and minions[index].asleep == false then
            if self.curr_task == nil then
                local task_index = self:find_task(task.BAKING)
                self.curr_task = self.queued_tasks[task_index]
            end
            if self.curr_task.task_name == task.GOING_TO_BED then
                self.curr_task:reset()
                local task_index = self:find_task(task.BAKING)
                self.curr_task = self.queued_tasks[task_index]
                for i = 1, minions[index].inventory_size do
                    if minions[index].inventory[i] ~= nil and minions[index].inventory[i].type == item_type.TONGS then
                        minions[index]:equip_right_hand(minions[index].inventory[i])
                    end
                end
            end
            self:bake(parent, minions, structs, map, index, dt)
        else
            if minions[index].asleep == false then
                if self.curr_task == nil then
                    local task_index = self:find_task(task.GOING_TO_BED)
                    self.curr_task = self.queued_tasks[task_index]
                elseif self.curr_task.task_name == task.BAKING then
                    self.curr_task:reset()
                    local task_index = self:find_task(task.GOING_TO_BED)
                    self.curr_task = self.queued_tasks[task_index]
                end
                if self.curr_task.task_name == task.GOING_TO_BED then
                    self:go_to_bed(parent, minions, structs, map, index, dt)
                end
            end
        end
    end,
    patrol_logic = function(self, parent, m_character, minions, structs, time, map, index, dt)
        if self.curr_task == nil then
            local task_index = self:find_task(task.PATROLING)
            self.curr_task = self.queued_tasks[task_index]
        elseif self.curr_task.task_name == task.PATROLING then
            self:guardian_patroling(m_character, minions, structs, map, index, dt)
        end
    end,
    free_mind = function(self, parent, m_character, minions, structs, time, map, index, dt)
        if minions[index].signals[hurted_by_others] ~= 0 then

        end
    end,
    think_about_life = function(self, parent, m_character, minions, structs, time, map, index, dt)
        if minions[index].chain_target ~= nil then
            if minions[index].sprite ~= nil and minions[index].chain_target.sprite ~= nil then
                if minions[index].rope_node == nil then
                    minions[index].rope_node = cc.DrawNode:create()
                    minions[index].rope_node:addTo(parent, 2)
                    minions[index].rope_body_node = cc.DrawNode:create()
                    minions[index].rope_body_node:addTo(parent.c_node)
                end
            else
                if minions[index].rope_node ~= nil then
                    minions[index].rope_node:clear()
                    minions[index].rope_node = nil
                    minions[index].rope_body_node:clear()
                    minions[index].rope_body_node = nil
                end
            end
            drag(m_character.position, minions[index], minions[index].chain_target, structs, map, 100, 2.0 * dt * fixedDeltaTimeScale)
            return
        end
        if minions[index].id == identity.slave and minions[index].occupation == occupation.farmer then
            self:farmer_logic(parent, m_character, minions, structs, time, map, index, dt)
        elseif minions[index].id == identity.slave and minions[index].occupation == occupation.baker then
            self:baker_logic(parent, m_character, minions, structs, time, map, index, dt)
        elseif minions[index].id == identity.guard and minions[index].occupation == occupation.patrol then
            self:patrol_logic(parent, m_character, minions, structs, time, map, index, dt)
        elseif minions[index].id == identity.free_folk then
            self:free_mind(parent, m_character, minions, structs, time, map, index, dt)
        end
    end,
    find_task = function(self, task_name)
        if self.queued_tasks_num <= 0 then
            return -1
        end
        for i = 1, self.queued_tasks_num do
            if self.queued_tasks[i] ~= nil then
                if self.queued_tasks[i].task_name == task_name then
                    return i
                end
            end
        end
        return -1
    end
}

function minion_logic:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.curr_task = nil
    o.queued_tasks = {}
    o.queued_tasks_num = 0
    return o
end

return minion_logic
