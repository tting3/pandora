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


local identity = require("app.logic.identity")
local farmer = require("app.logic.farmer")
local thief = require("app.logic.thief")
local sleep = require("app.logic.sleep")
local task = require("app.logic.task")
local functionality = require("app.object.functionality")

local minion_logic = {
    curr_task = nil,
    queued_tasks = {},
    queued_tasks_num = 0,
    thief_init = function(self)

    end,
    farm_init = function(self, structs)
        local task_index = self:find_task(task.FARMING)
        if task_index == -1 then
            self.queued_tasks_num = self.queued_tasks_num + 1
            task_index = self.queued_tasks_num
        end
        self.queued_tasks[task_index] = farmer:new()
        self.queued_tasks[task_index].task_index = task_index
        self.queued_tasks[task_index].task_name = task.FARMING
        for i, struct in pairs(structs) do
            if struct.functionality == functionality.FARM then
                self.queued_tasks[task_index].farm_index = i
                break
            end
        end
        for i, struct in pairs(structs) do
            if struct.functionality == functionality.LB then
                self.queued_tasks[task_index].storage_index = i
                self.queued_tasks[task_index].storage_level = 1
                break
            end
        end
    end,
    farm = function(self, minions, structs, map, index, dt)
        if self.curr_task.task_name == task.FARMING then
            local result = self.curr_task:do_farming(minions, structs, map, index, dt)
            if result == working then
            else
            end
        end
    end,
    sleep_init = function(self, structs)
        local task_index = self:find_task(task.GOING_TO_BED)
        if task_index == -1 then
            self.queued_tasks_num = self.queued_tasks_num + 1
            task_index = self.queued_tasks_num
        end
        self.queued_tasks[task_index] = sleep:new()
        self.queued_tasks[task_index].task_index = task_index
        self.queued_tasks[task_index].task_name = task.GOING_TO_BED
        for i, struct in pairs(structs) do
            if struct.functionality == functionality.LB then
                self.queued_tasks[task_index].sleep_index = i
                self.queued_tasks[task_index].bed_level = 2
                self.queued_tasks[task_index].bed_pos = cc.p(2, 2)
                break
            end
        end
    end,
    go_to_bed = function(self, minions, structs, map, index, dt)
        if self.curr_task.task_name == task.GOING_TO_BED then
            local result = self.curr_task:go_to_bed(minions, structs, map, index, dt)
            if result == success then
                minions[index].asleep = true
                minions[index].dir = STOP
            end
        end
    end,
    thief_init = function(self, target_structs)
        local task_index = self:find_task(task.STEALING)
        if task_index == -1 then
            self.queued_tasks_num = self.queued_tasks_num + 1
            task_index = self.queued_tasks_num
        end
        self.queued_tasks[task_index] = thief:new()
        self.queued_tasks[task_index].task_index = task_index
        self.queued_tasks[task_index].task_name = task.STEALING
        self.queued_tasks[task_index]:patrol_init(target_structs)
    end,
    steal = function(self, minions, structs, map, index, dt)
        if self.curr_task.task_name == task.STEALING then
            local result = self.curr_task:steal(minions, structs, map, index, dt)
            if result == success then
            end
        end
    end,
    think_about_life = function(self, m_character, minions, structs, time, map, index, dt)
        --minions[index]:set_name(minions[index].last_map_index, 0.0)
        if minions[index].id == identity.slave_farm then
            if time == DAY or time == DAWN then
                if self.curr_task == nil then
                    local task_index = self:find_task(task.FARMING)
                    self.curr_task = self.queued_tasks[task_index]
                end
                if self.curr_task.task_name == task.GOING_TO_BED then
                    self.curr_task.entrance_pos = cc.p(-1, -1)
                    self.curr_task.path = nil
                    self.queued_tasks[self.curr_task.task_index] = self.curr_task
                    local task_index = self:find_task(task.FARMING)
                    self.curr_task = self.queued_tasks[task_index]
                    minions[index].asleep = false
                end
                self:farm(minions, structs, map, index, dt)
            else
                if minions[index].asleep == false then
                    if self.curr_task == nil then
                        local task_index = self:find_task(task.GOING_TO_BED)
                        self.curr_task = self.queued_tasks[task_index]
                    elseif self.curr_task.task_name == task.FARMING then
                        if self.curr_task.status == LOOKING_FOR_FARM then
                            self.curr_task.entrance_pos = cc.p(-1, -1)
                            self.curr_task.path = nil
                            self.queued_tasks[self.curr_task.task_index] = self.curr_task
                            local task_index = self:find_task(task.GOING_TO_BED)
                            self.curr_task = self.queued_tasks[task_index]
                        else
                            self:farm(minions, structs, map, index, dt)
                        end
                    elseif self.curr_task.task_name == task.GOING_TO_BED then
                        self:go_to_bed(minions, structs, map, index, dt)
                    end
                end
            end
        elseif minions[index].id == identity.free_folk then
            if self.curr_task == nil then
                local task_index = self:find_task(task.STEALING)
                self.curr_task = self.queued_tasks[task_index]
            elseif self.curr_task.task_name == task.STEALING then
                self:steal(m_character, minions, structs, map, index, dt)
            end
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
