--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/23/2016
-- Time: 8:23 PM
-- To change this template use File | Settings | File Templates.
--

local SecondScene = class("SecondScene", cc.load("mvc").ViewBase)

local HOLD_TIME = 0.5
local DAY_TIME = 120.0
local DAWN_TIME = 10.0
local NIGHT_TIME = 100.0
local DAWN = 0
local DAY = 1
local TWILIGHT = 2
local NIGHT = 3
local LIGHT_TIMER = 0.2
local MAP_X = 200
local MAP_Y = 200
local STOP = -1
local DOWN = 0
local LEFT = 1
local RIGHT = 2
local UP = 3
local ONE = 0
local HALF = 1
local FULL = 2
local MAX_TASKS_NUM = 10
local MAX_MINIONS_NUM = 100
local success = 1
local working = 0
local failed = -1
local interaction_pop_speed = 5.0
local inventory_cols = 6
local inventory_rows = 4
local inventory_cols_chest = 8
local inventory_rows_chest = 7

local minion_motions = {}
minion_motions[DOWN] = "MINION_DOWN"
minion_motions[LEFT] = "MINION_LEFT"
minion_motions[RIGHT] = "MINION_RIGHT"
minion_motions[UP] = "MINION_UP"

local torch_motion = "TORCH"
local torch_motion_morning = "TORCH_MORNING"

local font = require("app.views.font")
local character = require("app.object.character")
local struct = require("app.object.struct")
local functionality = require("app.object.functionality")
local plants = require("app.object.plants")
local plants_type = require("app.object.plants_type")
local torch = require("app.object.torch")
local item_type = require("app.object.item_type")
local identity = require("app.logic.identity")
local minion_logic = require("app.logic.minion_logic")
local fixedDeltaTimeScale = 60.0

function SecondScene:init_minion_frame()
    local minion_image = display.loadImage("character/free_folk.png")
    local frameWidth = minion_image:getPixelsWide() / 4
    local frameHeight = minion_image:getPixelsHigh() / 4
    local frame_id = {0, 1, 2, 0, 1, 3}
    local animation_time = 0.2
    for motion, minion_motion in pairs(minion_motions) do
        local frames = {}
        for i, id in pairs(frame_id) do
            frames[i] = display.newSpriteFrame(minion_image, cc.rect(id * frameWidth, frameHeight * motion, frameWidth, frameHeight))
        end
        local animation = display.newAnimation(frames, animation_time)
        display.setAnimationCache(minion_motion, animation)
    end
    self.minion_size = 1
    local names = cc.FileUtils:getInstance():getStringFromFile("res/character/names")
    local num_names = string.len(names) / 5
    math.randomseed(os.time())
    local offset = math.random(num_names)
    local name_table = {}
    for i = 0, num_names - 1 do
        name_table[i + 1] = string.sub(names, (i % num_names) * 5 + 1, (i % num_names) * 5 + 4)
    end
    local iterations = #name_table
    local j
    for i = iterations, 2, -1 do
        j = math.random(i)
        name_table[i], name_table[j] = name_table[j], name_table[i]
    end
    local a = 5
    local b = 0
    local c = 10
    for i = 0, a do
        self:make_minion(name_table[i + 1], identity.slave_farm, 250+i*30, -40)
        self.minions[i+1].logic:farm_init(self.structs)
        self.minions[i+1].logic:sleep_init(self.structs)
    end
    for i = 0, b do
        self:make_minion(name_table[i + a + 2], identity.free_folk, -150-i*30, 50)
        self.minions[a+i+2].logic:thief_init({1, 2, 3, 4}, {identity.bussiness_guy})
    end
    for i = 0, c do
        self:make_minion(name_table[i + a + b + 3], identity.slave_dispose, -150-i*5, 50)
        self.minions[i + a + b + 3].inventory[1] = {}
        self.minions[i + a + b + 3].inventory[1].type = item_type.SWORD
        self.minions[i + a + b + 3].inventory[1].num = 1
        self.minions[i + a + b + 3].inventory[2] = {}
        self.minions[i + a + b + 3].inventory[2].type = item_type.KEY
        self.minions[i + a + b + 3].inventory[2].num = 1
        self.minions[i + a + b + 3].inventory[3] = {}
        self.minions[i + a + b + 3].inventory[3].type = item_type.CROP
        self.minions[i + a + b + 3].inventory[3].num = 5
        self.minions[i + a + b + 3].inventory[4] = {}
        self.minions[i + a + b + 3].inventory[4].type = item_type.COIN
        self.minions[i + a + b + 3].inventory[4].num = 10
        self.minions[i + a + b + 3].inventory.weight = item_type.SWORD.weight + item_type.CROP.weight * self.minions[i + a + b + 3].inventory[3].num
    end
end

function SecondScene:init_torch_frame()
    local torch_images = {}
    torch_images[1] = display.loadImage("background/torch1.png")
    torch_images[2] = display.loadImage("background/torch2.png")
    torch_images[3] = display.loadImage("background/torch3.png")
    local torch_frames = {}
    torch_frames[1] = display.newSpriteFrame(torch_images[1], cc.rect(0, 0, 50, 100))
    torch_frames[2] = display.newSpriteFrame(torch_images[2], cc.rect(0, 0, 50, 100))
    torch_frames[3] = display.newSpriteFrame(torch_images[3], cc.rect(0, 0, 50, 100))
    local animation_time = 0.2
    local animation = display.newAnimation(torch_frames, animation_time)
    display.setAnimationCache(torch_motion, animation)

    local torch_images = {}
    torch_images[1] = display.loadImage("background/torch.png")
    local torch_frames = {}
    torch_frames[1] = display.newSpriteFrame(torch_images[1], cc.rect(0, 0, 50, 100))
    local animation_time = 0.2
    local animation = display.newAnimation(torch_frames, animation_time)
    display.setAnimationCache(torch_motion_morning, animation)
end

function SecondScene:make_minion(name, id, x, y)
    self.minions[self.minion_size] = character:new()
    self.minions[self.minion_size].sprite = display.newSprite(display.getAnimationCache(minion_motions[DOWN]):getFrames()[1]:getSpriteFrame())
    :addTo(self.c_node)
    self.minions[self.minion_size]:set_map_characters(self.map_characters, self.minion_size, self.minions, self.m_character)
    self.minions[self.minion_size]:set_position(self.width / 2 + x, self.height / 2 + y)
    self.minions[self.minion_size]:change_position(0.0, 0.0, self.width / 2, self.height / 2)
    self.minions[self.minion_size]:set_name(name)
    self.minions[self.minion_size]:set_id(id)
    self.minions[self.minion_size]:add_shadow()
    --[[
    for i = 1, inventory_rows * inventory_cols do
        self.minions[self.minion_size].inventory[i] = nil
    end
    ]]
    self.minion_size = self.minion_size + 1
end

local function back_enter(tiledmap, layer_name, light)
    if tiledmap == nil then
        return
    end
    local layer = tiledmap:layerNamed(layer_name)
    if layer ~= nil then
        layer:setGLProgram(light)
    end
end

function SecondScene:struct_shader(i, back_shader, char_shader)
    if self.structs[i].functionality == functionality.LB then
        back_enter(self.structs[i].walls, "front", back_shader)
        back_enter(self.structs[i].walls, "back", back_shader)
        back_enter(self.structs[i].room1, "storage", back_shader)
        back_enter(self.structs[i].room1, "entrance", back_shader)
        back_enter(self.structs[i].room1, "floor", back_shader)
        back_enter(self.structs[i].room1, "beds", back_shader)
        back_enter(self.structs[i].room2, "storage", back_shader)
        back_enter(self.structs[i].room2, "entrance", back_shader)
        back_enter(self.structs[i].room2, "floor", back_shader)
        back_enter(self.structs[i].room2, "beds", back_shader)
        back_enter(self.structs[i].room3, "storage", back_shader)
        back_enter(self.structs[i].room3, "entrance", back_shader)
        back_enter(self.structs[i].room3, "floor", back_shader)
        back_enter(self.structs[i].room3, "beds", back_shader)
        back_enter(self.structs[i].roofs, "front", back_shader)
        back_enter(self.structs[i].roofs, "back", back_shader)
    end
    if self.structs[i].functionality == functionality.FARM then
        back_enter(self.structs[i].walls, "grass", back_shader)
        back_enter(self.structs[i].walls, "plants", back_shader)
        back_enter(self.structs[i].walls, "fences", back_shader)
        for ii = 0, self.structs[i].map.x - 1 do
            for jj = 0, self.structs[i].map.y - 1 do
                if self.structs[i].plants.fruit_sprites[ii][jj] ~= nil then
                    self.structs[i].plants.fruit_sprites[ii][jj]:setGLProgram(char_shader)
                end
            end
        end
    end
end

function SecondScene:detect_struct(i)
    local width = self.structs[i].map.x * self.structs[i].tile.x
    local height = self.structs[i].map.y * self.structs[i].tile.y
    if self.structs[i].in_vision == true then
        local x, y = self.structs_roof:getPosition()
        if self.structs[i].roofs ~= nil then
            self.structs[i].roofs:move(x + self.structs[i].position.x - self.m_character.position.x - display.cx, y + self.structs[i].position.y - self.m_character.position.y - display.cy)
        end
        if self.structs[i].walls ~= nil then
            self.structs[i].walls:move(x + self.structs[i].position.x - self.m_character.position.x - display.cx, y + self.structs[i].position.y - self.m_character.position.y - display.cy)
        end
        if self.structs[i].room1 ~= nil then
            self.structs[i].room1:move(x + self.structs[i].position.x - self.m_character.position.x - display.cx, y + self.structs[i].position.y - self.m_character.position.y - display.cy)
        end
        if self.structs[i].room2 ~= nil then
            self.structs[i].room2:move(x + self.structs[i].position.x - self.m_character.position.x - display.cx, y + self.structs[i].position.y - self.m_character.position.y - display.cy)
        end
        if self.structs[i].room3 ~= nil then
            self.structs[i].room3:move(x + self.structs[i].position.x - self.m_character.position.x - display.cx, y + self.structs[i].position.y - self.m_character.position.y - display.cy)
        end
        if self.structs[i].plants ~= nil then
            for ii = 0, self.structs[i].map.x - 1 do
                for jj = 0, self.structs[i].map.y - 1 do
                    if self.structs[i].plants.fruit_sprites[ii][jj] ~= nil then
                        self.structs[i].plants.fruit_sprites[ii][jj]:move(x + self.structs[i].position.x - display.cx - self.m_character.position.x + self.structs[i].tile.x * ii + 25, y - display.cy + self.structs[i].position.y - self.m_character.position.y + self.structs[i].tile.y * (self.structs[i].map.y - jj - 1) + 25)
                    end
                end
            end
        end
        if self.structs[i].position.x - self.m_character.position.x < 0.0 - display.cx - 2 * width or
                self.structs[i].position.x - self.m_character.position.x > display.cx + 2 * width or
                self.structs[i].position.y - self.m_character.position.y < 0.0 - display.cy - 2 * height or
                self.structs[i].position.y - self.m_character.position.y > display.cy + 2 * height then
            self.structs[i].in_vision = false
        end
    else
        if self.structs[i].position.x - self.m_character.position.x <= display.cx + 2 * width and
                self.structs[i].position.x - self.m_character.position.x >= 0.0 - display.cx - width and
                self.structs[i].position.y - self.m_character.position.y <= display.cy + 2 * height and
                self.structs[i].position.y - self.m_character.position.y >= 0.0 - display.cy - 2 * height then
            self.structs[i].in_vision = true
            if self.light_status == DAY then
                local day_back = cc.GLProgramCache:getInstance():getGLProgram("day_back")
                local day_char = cc.GLProgramCache:getInstance():getGLProgram("day_char")
                self:struct_shader(i, day_back, day_char)
            end
            if self.light_status == TWILIGHT or self.light_status == DAWN then
                local dawn_back = cc.GLProgramCache:getInstance():getGLProgram("dawn_back")
                local dawn_char = cc.GLProgramCache:getInstance():getGLProgram("dawn_char")
                self:struct_shader(i, dawn_back, dawn_char)
            end
            if self.light_status == NIGHT then
                local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back")
                local night_char = cc.GLProgramCache:getInstance():getGLProgram("night_char")
                self:struct_shader(i, night_back, night_char)
            end
        end
    end
end

function SecondScene:detect_torch(i)
    if self.torches[i].sprite ~= nil then
        self.c_node:reorderChild(self.torches[i].sprite, math.floor(display.top - (self.torches[i].position.y - self.m_character.position.y + display.cy)))
        self.torches[i].sprite:move(self.torches[i].position.x - self.m_character.position.x + display.cx, self.torches[i].position.y - self.m_character.position.y + display.cy + 40)
        if self.torches[i].position.x - self.m_character.position.x < 0.0 - display.cx - 8 * self.f_width or
                self.torches[i].position.x - self.m_character.position.x > display.cx + 8 * self.f_width or
                self.torches[i].position.y - self.m_character.position.y < 0.0 - display.cy - 7 * self.f_height or
                self.torches[i].position.y - self.m_character.position.y > display.cy + 7 * self.f_height then
            self.torches[i].sprite:stopAllActions()
            self.torches[i].sprite:removeFromParentAndCleanup(true)
            self.torches[i].sprite = nil
        end
    else
        if self.torches[i].position.x - self.m_character.position.x <= display.cx + 8 * self.f_width and
                self.torches[i].position.x - self.m_character.position.x >= 0.0 - display.cx - 8 * self.f_width and
                self.torches[i].position.y - self.m_character.position.y <= display.cy + 7 * self.f_height and
                self.torches[i].position.y - self.m_character.position.y >= 0.0 - display.cy - 7 * self.f_height then
            self.torches[i].sprite = display.newSprite("background/torch.png")
            :addTo(self.c_node, math.floor(display.top - (self.torches[i].position.y - self.m_character.position.y + display.cy)))
            if self.light_status == DAY then
                local day_char = cc.GLProgramCache:getInstance():getGLProgram("day_char")
                self.torches[i].sprite:setGLProgram(day_char)
            end
            if self.light_status == TWILIGHT or self.light_status == DAWN then
                local dawn_char = cc.GLProgramCache:getInstance():getGLProgram("dawn_char")
                self.torches[i].sprite:setGLProgram(dawn_char)
            end
            if self.light_status == NIGHT then
                local night_char = cc.GLProgramCache:getInstance():getGLProgram("night_char")
                self.torches[i].sprite:playAnimationForever(display.getAnimationCache(torch_motion))
                self.torches[i].sprite:setGLProgram(night_char)
            end
        end
    end
end

function SecondScene:update_minion(i)
    if self.minions[i].sprite ~= nil then
        if self.minions[i].dir ~= STOP and self.minions[i].animated == false then
            self.minions[i].sprite:stopAllActions()
            self.minions[i].sprite:playAnimationForever(display.getAnimationCache(minion_motions[self.minions[i].dir]))
            self.minions[i].animated = true
        elseif self.minions[i].dir == STOP and self.minions[i].animated == true then
            self.minions[i].sprite:stopAllActions()
            self.minions[i].animated = false
        end
    end
end

function SecondScene:detect_minion(i)
    if self.minions[i].sprite ~= nil then
        self.c_node:reorderChild(self.minions[i].sprite, math.floor(display.top - (self.minions[i].position.y - self.m_character.position.y + display.cy)))
        if self.minions[i].height_level ~= 0 then
            local i1 = self.m_character.position.x / 50.0
            local j1 = self.m_character.position.y / 50.0
            i1 = math.floor(i1) + 1
            j1 = math.floor(j1) + 1
            local i2 = self.minions[i].position.x / 50.0
            local j2 = self.minions[i].position.y / 50.0
            i2 = math.floor(i2) + 1
            j2 = math.floor(j2) + 1
            if self.minions[i].height_level ~= self.m_character.height_level or self.map_build_index[i1][j1] ~= self.map_build_index[i2][j2] then
                self.minions[i].sprite:setVisible(false)
            else
                self.minions[i].sprite:setVisible(true)
            end
        else
            self.minions[i].sprite:setVisible(true)
        end
        if self.minions[i].position.x - self.m_character.position.x < 0.0 - display.cx - 2 * self.f_width or
                self.minions[i].position.x - self.m_character.position.x > display.cx + 2 * self.f_width or
                self.minions[i].position.y - self.m_character.position.y < 0.0 - display.cy - 2 * self.f_height or
                self.minions[i].position.y - self.m_character.position.y > display.cy + 2 * self.f_height then
            self.minions[i].name_txt:removeFromParentAndCleanup(true)
            self.minions[i].name_txt = nil
            self.minions[i].sprite:stopAllActions()
            self.minions[i].sprite:removeFromParentAndCleanup(true)
            self.minions[i].sprite = nil
            self.minions[i].animated = false
        end
    else
        if self.minions[i].position.x - self.m_character.position.x <= display.cx + 2 * self.f_width and
                self.minions[i].position.x - self.m_character.position.x >= 0.0 - display.cx - 2 * self.f_width and
                self.minions[i].position.y - self.m_character.position.y <= display.cy + 2 * self.f_height and
                self.minions[i].position.y - self.m_character.position.y >= 0.0 - display.cy - 2 * self.f_height then
            self.minions[i].sprite = display.newSprite(display.getAnimationCache(minion_motions[self.minions[i].last_act]):getFrames()[1]:getSpriteFrame())
            :addTo(self.c_node)
            if self.light_status == DAY then
                local day_char = cc.GLProgramCache:getInstance():getGLProgram("day_char")
                self.minions[i].sprite:setGLProgram(day_char)
            end
            if self.light_status == TWILIGHT or self.light_status == DAWN then
                local dawn_char = cc.GLProgramCache:getInstance():getGLProgram("dawn_char")
                self.minions[i].sprite:setGLProgram(dawn_char)
            end
            if self.light_status == NIGHT then
                local night_char = cc.GLProgramCache:getInstance():getGLProgram("night_char")
                self.minions[i].sprite:setGLProgram(night_char)
            end
            self.minions[i]:set_name(self.minions[i].name)
            self.minions[i].animated = false
            self.minions[i]:add_shadow()
            self.c_node:reorderChild(self.minions[i].sprite, math.floor(display.top - (self.minions[i].position.y - self.m_character.position.y + display.cy)))
            if self.minions[i].height_level ~= 0 then
                local i1 = self.m_character.position.x / 50.0
                local j1 = self.m_character.position.y / 50.0
                i1 = math.floor(i1) + 1
                j1 = math.floor(j1) + 1
                local i2 = self.minions[i].position.x / 50.0
                local j2 = self.minions[i].position.y / 50.0
                i2 = math.floor(i2) + 1
                j2 = math.floor(j2) + 1
                if self.minions[i].height_level ~= self.m_character.height_level or self.map_build_index[i1][j1] ~= self.map_build_index[i2][j2] then
                    self.minions[i].sprite:setVisible(false)
                else
                    self.minions[i].sprite:setVisible(true)
                end
            else
                self.minions[i].sprite:setVisible(true)
            end
        end
    end
    self.minions[i]:change_position(0.0, 0.0, self.m_character.position.x, self.m_character.position.y)
end

function SecondScene:stop()
    self:unscheduleUpdate()
    return self
end

local function enter_day(self)
    local day_back = cc.GLProgramCache:getInstance():getGLProgram("day_back")
    local day_char = cc.GLProgramCache:getInstance():getGLProgram("day_char")
    back_enter(self.map, "ground", day_back)
    back_enter(self.map, "grass", day_back)
    for i, struct in pairs(self.structs) do
        if struct.in_vision == true then
            self:struct_shader(i, day_back, day_char)
        end
    end
    self.structs_roof:setGLProgram(day_back)
    self.structs_wall:setGLProgram(day_back)
    for i, minion in pairs(self.minions) do
        if self.minions[i].sprite ~= nil then
            self.minions[i].sprite:setGLProgram(day_char)
        end
    end
    self.m_character.sprite:setGLProgram(day_char)
    for i, single_torch in pairs(self.torches) do
        if self.torches[i].sprite ~= nil then
            self.torches[i].sprite:setGLProgram(day_char)
        end
    end
end

local function enter_dawn(self)
    local dawn_back = cc.GLProgramCache:getInstance():getGLProgram("dawn_back")
    local dawn_char = cc.GLProgramCache:getInstance():getGLProgram("dawn_char")
    back_enter(self.map, "ground", dawn_back)
    back_enter(self.map, "grass", dawn_back)
    for i, struct in pairs(self.structs) do
        if struct.in_vision == true then
            self:struct_shader(i, dawn_back, dawn_char)
        end
    end
    self.structs_roof:setGLProgram(dawn_back)
    self.structs_wall:setGLProgram(dawn_back)
    for i, minion in pairs(self.minions) do
        if self.minions[i].sprite ~= nil then
            self.minions[i].sprite:setGLProgram(dawn_char)
        end
    end
    self.m_character.sprite:setGLProgram(dawn_char)
    for i, single_torch in pairs(self.torches) do
        if self.torches[i].sprite ~= nil then
            if self.light_status == DAWN then
                self.torches[i].sprite:stopAllActions()
                self.torches[i].sprite:setSpriteFrame(display.getAnimationCache(torch_motion_morning):getFrames()[1]:getSpriteFrame())
            end
            self.torches[i].sprite:setGLProgram(dawn_char)
        end
    end
end

local function enter_night(self)
    local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back")
    local night_char = cc.GLProgramCache:getInstance():getGLProgram("night_char")
    back_enter(self.map, "ground", night_back)
    back_enter(self.map, "grass", night_back)
    for i, struct in pairs(self.structs) do
        if struct.in_vision == true then
            self:struct_shader(i, night_back, night_char)
        end
    end
    for i, minion in pairs(self.minions) do
        if self.minions[i].sprite ~= nil then
            self.minions[i].sprite:setGLProgram(night_char)
        end
    end
    self.m_character.sprite:setGLProgram(night_char)
    for i, single_torch in pairs(self.torches) do
        if self.torches[i].sprite ~= nil then
            self.torches[i].sprite:stopAllActions()
            self.torches[i].sprite:playAnimationForever(display.getAnimationCache(torch_motion))
            self.torches[i].sprite:setGLProgram(night_char)
        end
    end

    self.structs_roof:setGLProgram(night_back)
    self.structs_wall:setGLProgram(night_back)
    local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_back)
    local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_char)
end

function SecondScene:inventory_press_call_back(inventory, row_index, col_index)
    if inventory == self.m_character.inventory then
        --cc.Device:setKeepScreenOn(true)
        --release_print("asd")
    end
end

function SecondScene:interaction_press_call_back(index)
    --release_print("cell at "..index)
    if index == -1 then
        return
    end
    if index + 1 <= #self.last_character_interactions then
        self.pause_flag = true
        self.interact_flag = true
        self.control:setTexture("interact.png")
        self.interact_target = self.last_character_interactions[index + 1]
        self.inventory_layer:setVisible(false)
        if self.chest_flag == true then
            self.left_inventory = require("app.views.inventory_view").new(false, {}, 100, display.cy - inventory_rows * 50 / 2, inventory_cols, inventory_rows, cc.size(inventory_cols * 50, inventory_rows * 50), cc.p(50, 50), kCCScrollViewDirectionVertical, kCCTableViewFillTopDown, self)
            :setAnchorPoint(cc.p(0, 0))
            :setPosition(cc.p(0, 0))
            :addTo(self.inventory_layer)
            self.chest_flag = false
        end
        self.left_inventory:setVisible(true)
    else
        for i = 1, MAX_TASKS_NUM do
            if self.m_character_task[i] == nil then
                self.m_character_task[i] = self.last_object_interactions[index + 1 - #self.last_character_interactions]
                break
            end
        end
        --self.last_object_interactions[index + 1 - #self.last_character_interactions].call_back(self, self.last_object_interactions[index + 1 - #self.last_character_interactions].parameters)
    end
end

function SecondScene:harvest(parameters)
    --release_print(tostring(parameters[1]).." "..tostring(parameters[2]))
    --release_print(tostring(parameters[1]))
    return self.structs[parameters.build_index].plants:harvest_plant(parameters.i, parameters.j, self.dt)
end

function SecondScene:harvest_cancel(parameters)
    self.structs[parameters.build_index].plants:harvest_cancel(parameters.i, parameters.j)
end

function SecondScene:m_check_surroundings()
    local i = self.m_character.position.x / 50.0
    local j = self.m_character.position.y / 50.0
    i = math.floor(i) + 1
    j = math.floor(j) + 1
    local characters = {}
    for ii = i - 1, i + 1 do
        for jj = j - 1, j + 1 do
            if self.map_characters[ii][jj][1] ~= 0 then
                for index = 2, self.map_characters[ii][jj][1] + 1 do
                    if self.map_characters[ii][jj][index] ~= 0 then
                        characters[#characters + 1] = self.map_characters[ii][jj][index]
                    end
                end
            end
        end
    end
    local objects = {}
    local build_index = self.map_build_index[i][j]
    if build_index ~= 0 then
        if self.structs[build_index].functionality == functionality.FARM then
            if self.m_character.height_level == 0 then
                local temp_i = math.floor((self.m_character.position.x - self.structs[build_index].position.x) / self.structs[build_index].tile.x)
                local temp_j = self.structs[build_index].map.y - 1 - math.floor((self.m_character.position.y - self.structs[build_index].position.y) / self.structs[build_index].tile.y)
                if self.structs[build_index].plants:check_plant(temp_i, temp_j, nil) == true then
                    local index = #objects + 1
                    objects[index] = {}
                    objects[index].item = "object/harvest.png"
                    objects[index].call_back = self.harvest
                    objects[index].cancel = self.harvest_cancel
                    objects[index].parameters = {build_index = build_index, i = temp_i, j = temp_j}
                    objects[index].stop_when_walking = true
                end
            end
        end
    end
    local interactions_change_flag = false
    if #self.last_character_interactions ~= #characters then
        interactions_change_flag = true
    elseif #characters ~= 0 then
        for ii = 1, #characters do
            if self.last_character_interactions[ii] ~= characters[ii] then
                interactions_change_flag = true
                break
            end
        end
    end
    local function deepcompare(t1,t2,ignore_mt)
        local ty1 = type(t1)
        local ty2 = type(t2)
        if ty1 ~= ty2 then return false end
        -- non-table types can be directly compared
        if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
        -- as well as tables which have the metamethod __eq
        local mt = getmetatable(t1)
        if not ignore_mt and mt and mt.__eq then return t1 == t2 end
        for k1,v1 in pairs(t1) do
            local v2 = t2[k1]
            if v2 == nil or not deepcompare(v1,v2) then return false end
        end
        for k2,v2 in pairs(t2) do
            local v1 = t1[k2]
            if v1 == nil or not deepcompare(v1,v2) then return false end
        end
        return true
    end
    if #self.last_object_interactions ~= #objects then
        interactions_change_flag = true
    elseif #objects ~= 0 then
        for ii = 1, #objects do
            if deepcompare(self.last_object_interactions[ii], objects[ii], true) == false then
                interactions_change_flag = true
                break
            end
        end
    end
    if interactions_change_flag == true then
        self.last_interactions = {}
        self.last_character_interactions = {}
        for ii, character in pairs(characters) do
            self.last_interactions[ii] = {}
            self.last_interactions[ii].back = "object/character_interaction.png"
            self.last_interactions[ii].item = nil
            self.last_interactions[ii].label = self.minions[character].name
            self.last_character_interactions[ii] = character
        end
        self.last_object_interactions = {}
        for ii, object in pairs(objects) do
            self.last_interactions[ii + #self.last_character_interactions] = {}
            self.last_interactions[ii + #self.last_character_interactions].back = "object/object_interaction.png"
            self.last_interactions[ii + #self.last_character_interactions].item = object.item
            self.last_interactions[ii + #self.last_character_interactions].label = nil
            self.last_object_interactions[ii] = object
        end
        self.interactions.table_view.elements = self.last_interactions
        if (#characters + #objects) <= 6 then
            self.interactions_position_x = display.right - (#characters + #objects)*75
            --self.interactions.table_view:move(display.right - (#characters + #objects)*75, 0)
        else
            self.interactions_position_x = display.right - 6 * 75
            --self.interactions.table_view:move(display.right - 75*6, 0)
        end
        self.interactions.table_view:reloadData()
    end
    if self.interactions.table_view:getPositionX() < self.interactions_position_x then
        if self.interactions.table_view:getPositionX() < self.interactions_position_x + 3*interaction_pop_speed then
            self.interactions.table_view:move(self.interactions.table_view:getPositionX() + 3*interaction_pop_speed, 0)
        else
            self.interactions.table_view:move(self.interactions_position_x, 0)
        end
    elseif self.interactions.table_view:getPositionX() > self.interactions_position_x then
        if self.interactions.table_view:getPositionX() > self.interactions_position_x - interaction_pop_speed then
            self.interactions.table_view:move(self.interactions.table_view:getPositionX() - interaction_pop_speed, 0)
        else
            self.interactions.table_view:move(self.interactions_position_x, 0)
        end
    end
end

function SecondScene:step(dt)
    self.dt = dt
    self:m_check_surroundings()
    if self.inventory_selected ~= nil and self.inventory_block_selected ~= nil then
        if self.drag_item == nil then
            local local_inventory_cols = inventory_cols
            if self.chest_flag == true and self.inventory_selected ~= self.m_character.inventory then
                local_inventory_cols = inventory_cols_chest
            end
            if self.hold_time < HOLD_TIME then
                self.hold_time = self.hold_time + dt
            elseif self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols] ~= nil then
                cc.Device:vibrate(0.03)
                self.drag_item = display.newSprite(self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].type.icon)
                :setAnchorPoint(0.0, 0.0)
                :move(self.inventory_init_pos.x - 25, self.inventory_init_pos.y - 25)
                :addTo(self.inventory_layer, 91)
                if self.drag_num == FULL or self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num == 1 then
                    self.drag_item.item = self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols]
                    self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols] = nil
                elseif self.drag_num == HALF then
                    self.drag_item.item = {}
                    self.drag_item.item.type = self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].type
                    self.drag_item.item.num = math.floor(self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num / 2)
                    self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num = self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num - self.drag_item.item.num
                elseif self.drag_num == ONE then
                    self.drag_item.item = {}
                    self.drag_item.item.type = self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].type
                    self.drag_item.item.num = 1
                    self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num = self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num - self.drag_item.item.num
                end
                self.inventory_selected.weight = self.inventory_selected.weight - self.drag_item.item.type.weight * self.drag_item.item.num
                if self.drag_item.item.type.stack_limit ~= 1 then
                    local num = cc.Label:createWithSystemFont(tostring(self.drag_item.item.num), font.GREEK_FONT, 20)
                    num:setAnchorPoint(cc.p(0, 0))
                    num:setPosition(cc.p(5, 0))
                    self.drag_item:addChild(num)
                end
                if self.left_inventory:isVisible() == true then
                    self.left_inventory.table_view:reloadData()
                    self.left_inventory.weight:setString(self.minions[self.interact_target].inventory.weight.." / "..self.minions[self.interact_target].inventory.weight_limit)
                end
                self.right_inventory.table_view:reloadData()
                self.right_inventory.weight:setString(self.m_character.inventory.weight.." / "..self.m_character.inventory.weight_limit)
            end
        end
    end
    if self.pause_flag == true then
        return
    end
    self.time = self.time + dt
    if self.light_status == DAWN and self.time >= DAWN_TIME then
        self.light_status = DAY
        enter_day(self)
    end
    if self.light_status == DAY and self.time >= DAY_TIME + DAWN_TIME then
        self.light_status = TWILIGHT
        enter_dawn(self)
    end
    if self.light_status == TWILIGHT and self.time >= DAY_TIME + DAWN_TIME + DAWN_TIME then
        self.light_status = NIGHT
        enter_night(self)
    end
    if self.light_status == NIGHT and self.time >= DAY_TIME + DAWN_TIME + DAWN_TIME + NIGHT_TIME then
        self.light_status = DAWN
        self.time = 0.0
        enter_dawn(self)
    end
    if self.light_status == NIGHT then
        self.light_timer = self.light_timer + dt
        if self.light_timer > LIGHT_TIMER and self.light_timer < 2 * LIGHT_TIMER then
            self.light_radius = 61500.0
        elseif self.light_timer > 2 * LIGHT_TIMER then
            self.light_timer = 0
            self.light_radius = 60000.0
        end
        local lights = {}
        local lights_num = 0
        for i, single_torch in pairs(self.torches) do
            if self.torches[i].sprite ~= nil then
                lights_num = lights_num + 1
                lights[lights_num] = cc.p(math.floor((self.torches[i].position.x - self.m_character.position.x) * (self.screen_ratio.x - 1136.0/960.0 + 1) + display.cx * self.screen_ratio.x), math.floor((self.torches[i].position.y - self.m_character.position.y + 50) * self.screen_ratio.y + display.cy * self.screen_ratio.y))
            end
        end

        local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back")
        local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_back)
        gl_state:setUniformFloat("radius", self.light_radius * self.screen_ratio.x)
        gl_state:setUniformInt("lights_num", lights_num)
        for i, single_light in pairs(lights) do
            gl_state:setUniformVec2("light"..(i-1), single_light)
        end

        local night_char = cc.GLProgramCache:getInstance():getGLProgram("night_char")
        local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_char)
        gl_state:setUniformFloat("radius", self.light_radius * self.screen_ratio.x)
        gl_state:setUniformInt("lights_num", lights_num)
        for i, single_light in pairs(lights) do
            gl_state:setUniformVec2("light"..(i-1), single_light)
        end
    end

    local function update_position(self, x, y)
        local leave_enter, struct_index = self.m_character:change_position_m(x, y, self.structs, self.map_build_index)
        if leave_enter == 0 then
            self.structs[struct_index]:leave_and_enter(self.m_character.height_level)
        end
        if leave_enter == 1 then
            self.structs[struct_index]:enter(self.m_character.height_level)
        end
    end
    for i, struct in pairs(self.structs) do
        if struct.functionality == functionality.FARM then
            self.structs[i].plants:plants_grow(self.structs, i, dt)
        end
    end

    if self.map_move_flag == RIGHT then
        update_position(self, self.m_character.speed * dt * fixedDeltaTimeScale, 0.0)
        if self.m_character.last_act ~= RIGHT then
            self.m_character.sprite:stopAllActions()
            self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[RIGHT]))
            self.m_character.last_act = RIGHT
        end
    end
    if self.map_move_flag == LEFT then
        update_position(self, 0.0 - self.m_character.speed * dt * fixedDeltaTimeScale, 0.0)
        if self.m_character.last_act ~= LEFT then
            self.m_character.sprite:stopAllActions()
            self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[LEFT]))
            self.m_character.last_act = LEFT
        end
    end
    if self.map_move_flag == UP then
        update_position(self, 0.0, self.m_character.speed * dt * fixedDeltaTimeScale)
        if self.m_character.last_act ~= UP then
            self.m_character.sprite:stopAllActions()
            self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[UP]))
            self.m_character.last_act = UP
        end
    end
    if self.map_move_flag == DOWN then
        update_position(self, 0.0, 0.0 - self.m_character.speed * dt * fixedDeltaTimeScale)
        if self.m_character.last_act ~= DOWN then
            self.m_character.sprite:stopAllActions()
            self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[DOWN]))
            self.m_character.last_act = DOWN
        end
    end
    if self.map_move_flag ~= STOP then
        self.map:move(display.cx - self.m_character.position.x, display.cy - self.m_character.position.y)
        for i = 1, MAX_TASKS_NUM do
            if self.m_character_task[i] ~= nil and self.m_character_task[i].stop_when_walking == true then
                self.m_character_task[i].cancel(self, self.m_character_task[i].parameters)
                self.m_character_task[i] = nil
            end
        end
    elseif self.m_character.last_act ~= STOP then
        self.m_character.sprite:stopAllActions()
        self.m_character.sprite:setSpriteFrame(display.getAnimationCache(minion_motions[self.m_character.last_act]):getFrames()[1]:getSpriteFrame())
        self.m_character.last_act = STOP
    end

    for i = 1, MAX_TASKS_NUM do
        if self.m_character_task[i] ~= nil then
            local result, item = self.m_character_task[i].call_back(self, self.m_character_task[i].parameters)
            if result == success then
                self.m_character:add_item(item)
                self.m_character_task[i] = nil
            end
        end
    end

    for i = 1, MAX_MINIONS_NUM do
        if self.minions[i] ~= nil then
            self.minions[i].logic:think_about_life(self.m_character, self.minions, self.structs, self.light_status, self.map_build_index, i, dt)
            self:detect_minion(i)
            self:update_minion(i)
        end
    end
    for i, single_torch in pairs(self.torches) do
        self:detect_torch(i)
    end
    for i, struct in pairs(self.structs) do
        self:detect_struct(i)
    end
end

function SecondScene:create_collision_test(i, loc_x, loc_y)
    self.structs[i] = struct:new()
    self.structs[i].position = cc.p(loc_x + self.width / 2, loc_y + self.height / 2)
    self.structs[i].in_vision = true
    local x, y = self.structs_wall:getPosition()
    self.structs[i].walls = cc.TMXTiledMap:create("background/collision_test.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2, y - display.cy + self.structs[i].position.y - self.height / 2)
    :addTo(self.structs_wall)
    self.structs[i].map = cc.p(self.structs[i].walls:getMapSize().width, self.structs[i].walls:getMapSize().height)
    self.structs[i].tile = cc.p(self.structs[i].walls:getTileSize().width, self.structs[i].walls:getTileSize().height)
    for m = 0, self.structs[i].map.x - 1 do
        for n = 0, self.structs[i].map.y - 1 do
            local ii = (m * self.structs[i].tile.x + self.structs[i].position.x) / (self.f_width)
            local jj = ((self.structs[i].map.y - 1 - n) * self.structs[i].tile.y + self.structs[i].position.y) / (self.f_height)
            ii = math.floor(ii) + 1
            jj = math.floor(jj) + 1
            self.map_build_index[ii][jj] = i
        end
    end
end

function SecondScene:create_lb(i, lb_name, loc_x, loc_y)
    self.structs[i] = struct:new()
    self.structs[i].position = cc.p(loc_x + self.width / 2, loc_y + self.height / 2)
    self.structs[i].name = lb_name
    self.structs[i].functionality = functionality.LB
    self.structs[i].in_vision = true
    local x, y = self.structs_roof:getPosition()
    self.structs[i].roofs = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_roofs.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2, y - display.cy + self.structs[i].position.y - self.height / 2)
    :addTo(self.structs_roof)
    self.structs[i].walls = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_walls.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2, y - display.cy + self.structs[i].position.y - self.height / 2)
    :addTo(self.structs_wall)
    local layer = self.structs[i].walls:layerNamed("collision")
    layer:setVisible(false)
    self.structs[i].room1 = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_room1.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2, y - display.cy + self.structs[i].position.y - self.height / 2)
    :addTo(self.structs_wall)
    local layer = self.structs[i].room1:layerNamed("collision")
    layer:setVisible(false)
    self.structs[i].room1:setVisible(false)
    self.structs[i].room2 = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_room2.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2, y - display.cy + self.structs[i].position.y - self.height / 2)
    :addTo(self.structs_wall)
    local layer = self.structs[i].room2:layerNamed("collision")
    layer:setVisible(false)
    self.structs[i].room2:setVisible(false)
    self.structs[i].map = cc.p(self.structs[i].walls:getMapSize().width, self.structs[i].walls:getMapSize().height)
    self.structs[i].tile = cc.p(self.structs[i].walls:getTileSize().width, self.structs[i].walls:getTileSize().height)
    for m = 0, self.structs[i].map.x - 1 do
        for n = 0, self.structs[i].map.y - 1 do
            local ii = (m * self.structs[i].tile.x + self.structs[i].position.x) / (self.f_width)
            local jj = ((self.structs[i].map.y - 1 - n) * self.structs[i].tile.y + self.structs[i].position.y) / (self.f_height)
            ii = math.floor(ii) + 1
            jj = math.floor(jj) + 1
            self.map_build_index[ii][jj] = i
        end
    end
end

function SecondScene:create_farm(i, farm_name, loc_x, loc_y)
    self.structs[i] = struct:new()
    self.structs[i].position = cc.p(loc_x + self.width / 2, loc_y + self.height / 2)
    self.structs[i].name = farm_name
    self.structs[i].functionality = functionality.FARM
    self.structs[i].in_vision = true
    local x, y = self.structs_wall:getPosition()
    self.structs[i].walls = cc.TMXTiledMap:create("background/"..self.structs[i].name..".tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2, y - display.cy + self.structs[i].position.y - self.height / 2)
    :addTo(self.structs_wall)
    local layer = self.structs[i].walls:layerNamed("collision")
    layer:setVisible(false)
    self.structs[i].map = cc.p(self.structs[i].walls:getMapSize().width, self.structs[i].walls:getMapSize().height)
    self.structs[i].tile = cc.p(self.structs[i].walls:getTileSize().width, self.structs[i].walls:getTileSize().height)
    for m = 0, self.structs[i].map.x - 1 do
        for n = 0, self.structs[i].map.y - 1 do
            local ii = (m * self.structs[i].tile.x + self.structs[i].position.x) / (self.f_width)
            local jj = ((self.structs[i].map.y - 1 - n) * self.structs[i].tile.y + self.structs[i].position.y) / (self.f_height)
            ii = math.floor(ii) + 1
            jj = math.floor(jj) + 1
            self.map_build_index[ii][jj] = i
        end
    end
    self.structs[i].plants = plants:new()
    self.structs[i].plants:init_plants(self.structs[i], self.structs_wall, self.width, self.height)
end

function SecondScene:onCreate()
    self.minions = {}
    self.torches = {}
    self.minion_size = 1
    self.m_character = {}
    self.m_character_task = {}
    self.screen_ratio = cc.p(1.0, 1.0)
    self.width = 0.0
    self.height = 0.0
    self.f_width = 0.0
    self.f_height = 0.0
    self.time = DAWN_TIME
    self.light_status = DAY
    self.light_radius = 60000.0
    self.light_timer = 0.0
    self.day_back = nil
    self.day_char = nil
    self.dawn_back = nil
    self.dawn_char = nil
    self.night_back = nil
    self.night_char = nil
    self.map = {}
    self.map_move_flag = STOP
    self.map_build_index = {}
    self.map_characters = {}
    self.touch_layer = {}
    self.olo = {}
    self.resources = {}
    self.resources_50 = {}
    self.structs_roof = {}
    self.structs_wall = {}
    self.structs = {}
    self.c_node = {}
    self.last_character_interactions = {}
    self.last_object_interactions = {}
    self.last_interactions = {}
    self.pause_flag = false
    self.interact_flag = false
    self.interact_target = 0
    self.inventory_layer = nil
    self.left_inventory = nil
    self.right_inventory = nil
    self.inventory_init_pos = nil
    self.inventory_selected = nil
    self.inventory_block_selected = nil
    self.hold_time = 0.0
    self.drag_item = nil
    self.drag_num_sprite = nil
    self.plus = nil
    self.minus = nil
    self.chest_flag = false
    local exitButton = cc.MenuItemImage:create("exit.png", "exit.png")
    :onClicked(function()
        self:getApp():enterScene("MainScene")
    end)
    cc.Menu:create(exitButton)
    :move(display.left + 75/2, display.top - 75/2)
    :addTo(self, 100)

    local inventory = cc.MenuItemImage:create("inventory.png", "inventory.png")
    :onClicked(function()
        if self.interact_flag == true then
        else
            if self.inventory_layer:isVisible() == false then
                self.pause_flag = true
                self.left_inventory:setVisible(false)
                self.inventory_layer:setVisible(true)
            else
                self.pause_flag = false
                self.left_inventory:setVisible(false)
                self.inventory_layer:setVisible(false)
            end
        end
    end)
    cc.Menu:create(inventory)
    :move(display.right - 25, display.top - 25)
    :addTo(self, 100)

    self.olo = cc.Label:createWithSystemFont("olo", font.GREEK_FONT, 50)
    :move(display.cx, display.top - 50)
    :setTextColor(font.YELLOW)
    :addTo(self, 100)
    self.c_node = display.newNode()
    :move(0, 0)
    :addTo(self, 4)

    self.f_width = 50
    self.f_height = 50
    self.width = MAP_X * self.f_width
    self.height = MAP_Y * self.f_height

    self.structs_wall = display.newSprite()
    :move(display.cx, display.cy)
    :addTo(self, 1)
    self.structs_roof = display.newSprite()
    :move(display.cx, display.cy)
    :addTo(self, 50)
    self.map = cc.TMXTiledMap:create("background/background.tmx")
    :move(display.cx - self.width / 2, display.cy - self.height / 2)
    :addTo(self.structs_wall)

    self.map_characters = {}
    for i = 1, MAP_X do
        self.map_build_index[i] = {}
        self.map_characters[i] = {}
        for j = 1, MAP_Y do
            self.map_build_index[i][j] = 0
            self.map_characters[i][j] = {}
            self.map_characters[i][j][1] = 0
        end
    end

    self.resources = cc.TMXTiledMap:create("background/resources.tmx")
    local brickwithgrass = self.resources:layerNamed("brickwithgrass")

    math.randomseed(os.time())
    local layer = self.map:layerNamed("grass")
    local gid = brickwithgrass:tileGIDAt(cc.p(0, 0))
    for i = 0, MAP_X / 2 - 1 do
        for j = 0, MAP_Y / 2 - 1 do
            if math.random(20) <= 2 then
                layer:setTileGID(gid, cc.p(i, j))
            end
        end
    end

    self.resources_50 = cc.TMXTiledMap:create("background/resources_50.tmx")

    self:create_lb(1, "lb1", -100, 100)
    --self:create_lb(2, "lb1", -250, 750)

    self:create_farm(2, "farm1", -100, 1300)
    self:create_lb(3, "lb1", -550, 100)
    self:create_lb(4, "lb1", -100, -350)
    --self:create_collision_test(5, -125, 750)

    self.m_character = character:new()
    self:init_minion_frame()
    local frame = display.getAnimationCache(minion_motions[DOWN]):getFrames()[2]
    self.m_character.sprite = display.newSprite(frame:getSpriteFrame())
    :addTo(self.c_node, math.floor(display.cy))
    self.m_character:set_map_characters(self.map_characters, 0, self.minions, self.m_character)
    self.m_character:set_position(self.width / 2, self.height / 2)
    self.m_character:change_position(0.0, 0.0, self.width / 2, self.height / 2)
    self.m_character:set_name("Pandora")
    self.m_character:add_shadow()
    --[[
    for i = 1, inventory_rows * inventory_cols do
        self.m_character.inventory[i] = nil
    end
    ]]

    local touch_layer = display.newLayer()
    :addTo(self, 90)

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(
        function(touch, event)
            local x, y = touch:getLocation().x, touch:getLocation().y
            if x >= 0 and x < 200 and y >= 0 and y < 200 then
                if x < 150 and y < 150 then
                    if x + y <= 150 then
                        if x <= y then
                            if self.interact_flag == false then
                                self.map_move_flag = LEFT
                                return true
                            else
                                self.map_move_flag = STOP
                                if self.interact_target ~= 0 then
                                    self.left_inventory.table_view.elements = self.minions[self.interact_target].inventory
                                    self.left_inventory.table_view:reloadData()
                                    self.right_inventory.table_view:reloadData()
                                    self.left_inventory.weight:setString(self.minions[self.interact_target].inventory.weight.." / "..self.minions[self.interact_target].inventory.weight_limit)
                                    self.left_inventory.name:setString(self.minions[self.interact_target].name)
                                    self.right_inventory.weight:setString(self.m_character.inventory.weight.." / "..self.m_character.inventory.weight_limit)
                                    self.right_inventory.name:setString(self.m_character.name)
                                    self.inventory_layer:setVisible(true)
                                end
                                return true
                            end
                        else
                            if self.interact_flag == false then
                                self.map_move_flag = DOWN
                                return true
                            else
                                self.interact_flag = false
                                self.pause_flag = false
                                self.map_move_flag = STOP
                                self.control:setTexture("control.png")
                                self.inventory_layer:setVisible(false)
                                return true
                            end
                        end
                    else
                        if x <= y then
                            if self.interact_flag == false then
                                self.map_move_flag = UP
                                return true
                            else
                                self.map_move_flag = STOP
                                return true
                            end
                        else
                            if self.interact_flag == false then
                                self.map_move_flag = RIGHT
                                return true
                            else
                                self.map_move_flag = STOP
                                return true
                            end
                        end
                    end
                end
                self.map_move_flag = STOP
            end
            if self.inventory_layer:isVisible() == true then
                if self.left_inventory:isVisible() == true then
                    local left = self.left_inventory.table_view:getPositionX()
                    local right = self.left_inventory.table_view:getPositionX() + self.left_inventory.table_view:getContentSize().width
                    local bottom = self.left_inventory.table_view:getPositionY()
                    local top = self.left_inventory.table_view:getPositionY() + self.left_inventory.table_view:getContentSize().height
                    if x >= left and x < right and y >= bottom and y < top and self.inventory_block_selected == nil and self.inventory_selected == nil then
                        local local_inventory_rows
                        if self.chest_flag == false then
                            local_inventory_rows = inventory_rows
                        else
                            local_inventory_rows = inventory_rows_chest
                        end
                        local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
                        local j = local_inventory_rows - (math.floor((touch:getLocation().y - bottom) / 50.0) + 1)
                        self.inventory_block_selected = cc.p(i, j)
                        self.inventory_selected = self.minions[self.interact_target].inventory
                        self.inventory_init_pos = touch:getLocation()
                        self.hold_time = 0.0
                        if self.drag_item ~= nil then
                            self.drag_item:removeFromParentAndCleanup(true)
                            self.drag_item = nil
                        end
                    end
                end
                local left = self.right_inventory.table_view:getPositionX()
                local right = self.right_inventory.table_view:getPositionX() + self.right_inventory.table_view:getContentSize().width
                local bottom = self.right_inventory.table_view:getPositionY()
                local top = self.right_inventory.table_view:getPositionY() + self.right_inventory.table_view:getContentSize().height
                if x >= left and x < right and y >= bottom and y < top and self.inventory_block_selected == nil and self.inventory_selected == nil then
                    local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
                    local j = inventory_rows - (math.floor((touch:getLocation().y - bottom) / 50.0) + 1)
                    self.inventory_block_selected = cc.p(i, j)
                    self.inventory_selected = self.m_character.inventory
                    self.inventory_init_pos = touch:getLocation()
                    self.hold_time = 0.0
                    if self.drag_item ~= nil then
                        self.drag_item:removeFromParentAndCleanup(true)
                        self.drag_item = nil
                    end
                end
            end
            return true
        end
        ,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(
        function(touch, event)
            local x, y = touch:getLocation().x, touch:getLocation().y
            if x >= 0 and x < 200 and y >= 0 and y < 200 then
                if x < 150 and y < 150 then
                    if x + y <= 150 then
                        if x <= y then
                            if self.interact_flag == false then
                                self.map_move_flag = LEFT
                                return
                            end
                        else
                            if self.interact_flag == false then
                                self.map_move_flag = DOWN
                                return
                            end
                        end
                    else
                        if x <= y then
                            if self.interact_flag == false then
                                self.map_move_flag = UP
                                return
                            end
                        else
                            if self.interact_flag == false then
                                self.map_move_flag = RIGHT
                                return
                            end
                        end
                    end
                end
                self.map_move_flag = STOP
            end
            if self.drag_item ~= nil then
                self.drag_item:move(touch:getLocation().x - 25, touch:getLocation().y - 25)
            else
                if self.inventory_layer:isVisible() == true then
                    if self.left_inventory:isVisible() == true then
                        local left = self.left_inventory.table_view:getPositionX()
                        local right = self.left_inventory.table_view:getPositionX() + self.left_inventory.table_view:getContentSize().width
                        local bottom = self.left_inventory.table_view:getPositionY()
                        local top = self.left_inventory.table_view:getPositionY() + self.left_inventory.table_view:getContentSize().height
                        if x >= left and x < right and y >= bottom and y < top then
                            local local_inventory_rows
                            if self.chest_flag == false then
                                local_inventory_rows = inventory_rows
                            else
                                local_inventory_rows = inventory_rows_chest
                            end
                            local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
                            local j = local_inventory_rows - (math.floor((touch:getLocation().y - bottom) / 50.0) + 1)
                            self.inventory_block_selected = cc.p(i, j)
                            self.inventory_selected = self.minions[self.interact_target].inventory
                            self.inventory_init_pos = touch:getLocation()
                            local xx = touch.getPreviousLocation().x
                            local yy = touch.getPreviousLocation().y
                            if (xx - x) * (xx - x) + (yy - y) * (yy - y) >= 1.0 then
                                self.hold_time = 0.0
                            end
                            if self.drag_item ~= nil then
                                self.drag_item:removeFromParentAndCleanup(true)
                                self.drag_item = nil
                            end
                        end
                    end
                    local left = self.right_inventory.table_view:getPositionX()
                    local right = self.right_inventory.table_view:getPositionX() + self.right_inventory.table_view:getContentSize().width
                    local bottom = self.right_inventory.table_view:getPositionY()
                    local top = self.right_inventory.table_view:getPositionY() + self.right_inventory.table_view:getContentSize().height
                    if x >= left and x < right and y >= bottom and y < top then
                        local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
                        local j = inventory_rows - (math.floor((touch:getLocation().y - bottom) / 50.0) + 1)
                        self.inventory_block_selected = cc.p(i, j)
                        self.inventory_selected = self.m_character.inventory
                        self.inventory_init_pos = touch:getLocation()
                        local xx = touch.getPreviousLocation().x
                        local yy = touch.getPreviousLocation().y
                        if (xx - x) * (xx - x) + (yy - y) * (yy - y) >= 1.0 then
                            self.hold_time = 0.0
                        end
                        if self.drag_item ~= nil then
                            self.drag_item:removeFromParentAndCleanup(true)
                            self.drag_item = nil
                        end
                    end
                end
            end
            return
        end
        ,cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(
        function(touch, event)
            local x, y = touch:getLocation().x, touch:getLocation().y
            if x >= 0 and x < 200 and y >= 0 and y < 200 then
                self.map_move_flag = STOP
            end
            if self.inventory_selected ~= nil and self.inventory_block_selected ~= nil and self.drag_item ~= nil then
                if self.left_inventory:isVisible() == true then
                    local left = self.left_inventory.table_view:getPositionX()
                    local right = self.left_inventory.table_view:getPositionX() + self.left_inventory.table_view:getContentSize().width
                    local bottom = self.left_inventory.table_view:getPositionY()
                    local top = self.left_inventory.table_view:getPositionY() + self.left_inventory.table_view:getContentSize().height
                    if x >= left and x < right and y >= bottom and y < top then
                        local local_inventory_cols
                        local local_inventory_rows
                        if self.chest_flag == false then
                            local_inventory_rows = inventory_rows
                            local_inventory_cols = inventory_cols
                        else
                            local_inventory_rows = inventory_rows_chest
                            local_inventory_cols = inventory_cols_chest
                        end
                        local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
                        local j = local_inventory_rows - (math.floor((touch:getLocation().y - bottom) / 50.0) + 1)
                        if self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols] == nil or self.left_inventory.table_view.elements[i + j * local_inventory_cols] == nil then
                            if self.left_inventory.table_view.elements[i + j * local_inventory_cols] ~= nil then
                                if self.left_inventory.table_view.elements[i + j * local_inventory_cols].type ~= self.drag_item.item.type then
                                    self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols] = self.left_inventory.table_view.elements[i + j * local_inventory_cols]
                                    self.left_inventory.table_view.elements.weight = self.left_inventory.table_view.elements.weight - self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.weight * self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                    self.inventory_selected.weight = self.inventory_selected.weight + self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.weight * self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                else
                                    self.drag_item.item.num = self.drag_item.item.num + self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                    self.left_inventory.table_view.elements.weight = self.left_inventory.table_view.elements.weight - self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.weight * self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                    if self.drag_item.item.num > self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.stack_limit then
                                        local num = self.drag_item.item.num - self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.stack_limit
                                        self.drag_item.item.num = self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.stack_limit
                                        self.left_inventory.table_view.elements[i + j * local_inventory_cols].num = num
                                        self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols] = self.left_inventory.table_view.elements[i + j * local_inventory_cols]
                                        self.inventory_selected.weight = self.inventory_selected.weight + self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.weight * self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                    end
                                end
                            end
                            self.left_inventory.table_view.elements[i + j * local_inventory_cols] = self.drag_item.item
                            self.left_inventory.table_view.elements.weight = self.left_inventory.table_view.elements.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                        elseif self.left_inventory.table_view.elements[i + j * local_inventory_cols].type == self.drag_item.item.type and self.drag_item.item.num + self.left_inventory.table_view.elements[i + j * local_inventory_cols].num <= self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.stack_limit then
                            self.left_inventory.table_view.elements[i + j * local_inventory_cols].num = self.drag_item.item.num + self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                            self.left_inventory.table_view.elements.weight = self.left_inventory.table_view.elements.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                        else
                            self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num = self.drag_item.item.num + self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num
                            self.inventory_selected.weight = self.inventory_selected.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                        end
                    end
                end
                local left = self.right_inventory.table_view:getPositionX()
                local right = self.right_inventory.table_view:getPositionX() + self.right_inventory.table_view:getContentSize().width
                local bottom = self.right_inventory.table_view:getPositionY()
                local top = self.right_inventory.table_view:getPositionY() + self.right_inventory.table_view:getContentSize().height
                if x >= left and x < right and y >= bottom and y < top then
                    local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
                    local j = inventory_rows - (math.floor((touch:getLocation().y - bottom) / 50.0) + 1)
                    if self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * inventory_cols] == nil or self.right_inventory.table_view.elements[i + j * inventory_cols] == nil then
                        if self.right_inventory.table_view.elements[i + j * inventory_cols] ~= nil then
                            if self.right_inventory.table_view.elements[i + j * inventory_cols].type ~= self.drag_item.item.type then
                                self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * inventory_cols] = self.right_inventory.table_view.elements[i + j * inventory_cols]
                                self.right_inventory.table_view.elements.weight = self.right_inventory.table_view.elements.weight - self.right_inventory.table_view.elements[i + j * inventory_cols].type.weight * self.right_inventory.table_view.elements[i + j * inventory_cols].num
                                self.inventory_selected.weight = self.inventory_selected.weight + self.right_inventory.table_view.elements[i + j * inventory_cols].type.weight * self.right_inventory.table_view.elements[i + j * inventory_cols].num
                            else
                                self.drag_item.item.num = self.drag_item.item.num + self.right_inventory.table_view.elements[i + j * inventory_cols].num
                                self.right_inventory.table_view.elements.weight = self.right_inventory.table_view.elements.weight - self.right_inventory.table_view.elements[i + j * inventory_cols].type.weight * self.right_inventory.table_view.elements[i + j * inventory_cols].num
                                if self.drag_item.item.num > self.right_inventory.table_view.elements[i + j * inventory_cols].type.stack_limit then
                                    local num = self.drag_item.item.num - self.right_inventory.table_view.elements[i + j * inventory_cols].type.stack_limit
                                    self.drag_item.item.num = self.right_inventory.table_view.elements[i + j * inventory_cols].type.stack_limit
                                    self.right_inventory.table_view.elements[i + j * inventory_cols].num = num
                                    self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * inventory_cols] = self.right_inventory.table_view.elements[i + j * inventory_cols]
                                    self.inventory_selected.weight = self.inventory_selected.weight + self.right_inventory.table_view.elements[i + j * inventory_cols].type.weight * self.right_inventory.table_view.elements[i + j * inventory_cols].num
                                end
                            end
                        end
                        self.right_inventory.table_view.elements[i + j * inventory_cols] = self.drag_item.item
                        self.right_inventory.table_view.elements.weight = self.right_inventory.table_view.elements.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                    elseif self.right_inventory.table_view.elements[i + j * inventory_cols].type == self.drag_item.item.type and self.drag_item.item.num + self.right_inventory.table_view.elements[i + j * inventory_cols].num <= self.right_inventory.table_view.elements[i + j * inventory_cols].type.stack_limit then
                        self.right_inventory.table_view.elements[i + j * inventory_cols].num = self.drag_item.item.num + self.right_inventory.table_view.elements[i + j * inventory_cols].num
                        self.right_inventory.table_view.elements.weight = self.right_inventory.table_view.elements.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                    else
                        self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * inventory_cols].num = self.drag_item.item.num + self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * inventory_cols].num
                        self.inventory_selected.weight = self.inventory_selected.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                    end
                end
                if self.left_inventory:isVisible() == true then
                    self.left_inventory.table_view:reloadData()
                    self.left_inventory.weight:setString(self.left_inventory.table_view.elements.weight.." / "..self.left_inventory.table_view.elements.weight_limit)
                end
                self.right_inventory.table_view:reloadData()
                self.right_inventory.weight:setString(self.right_inventory.table_view.elements.weight.." / "..self.right_inventory.table_view.elements.weight_limit)
            end
            self.inventory_selected = nil
            self.inventory_block_selected = nil
            self.hold_time = 0.0
            if self.drag_item ~= nil then
                self.drag_item:removeFromParentAndCleanup(true)
                self.drag_item = nil
            end
            return
        end
        ,cc.Handler.EVENT_TOUCH_ENDED)
    listener:registerScriptHandler(
        function(touch, event)
            self.map_move_flag = STOP
            if self.inventory_selected ~= nil and self.inventory_block_selected ~= nil and self.drag_item ~= nil then
                local local_inventory_cols = inventory_cols
                if self.chest_flag == true and self.inventory_selected ~= self.m_character.inventory then
                    local_inventory_cols = inventory_cols_chest
                end
                if self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols] == nil then
                    self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols] = self.drag_item.item
                else
                    self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num = self.drag_item.item.num
                end
                self.inventory_selected.weight = self.inventory_selected.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                if self.left_inventory:isVisible() == true then
                    self.left_inventory.table_view:reloadData()
                    self.left_inventory.weight:setString(self.minions[self.interact_target].inventory.weight.." / "..self.minions[self.interact_target].inventory.weight_limit)
                end
                self.right_inventory.table_view:reloadData()
                self.right_inventory.weight:setString(self.m_character.inventory.weight.." / "..self.m_character.inventory.weight_limit)
            end
            self.inventory_selected = nil
            self.inventory_block_selected = nil
            self.hold_time = 0.0
            if self.drag_item ~= nil then
                self.drag_item:removeFromParentAndCleanup(true)
                self.drag_item = nil
            end
            return
        end
        ,cc.Handler.EVENT_TOUCH_CANCELLED)

    self.control = display.newSprite("control.png")
    :setAnchorPoint(0.0, 0.0)
    :move(display.left, display.bottom)
    :addTo(touch_layer)
    self.control:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self.control)

    self.interactions = require("app.views.interactions").new(true, self.last_interactions, display.right, 0, cc.size(75*6, 75), cc.p(75, 75), kCCScrollViewDirectionHorizontal, kCCTableViewFillTopDown, self)
    self.interactions:setAnchorPoint(cc.p(0, 0))
    self.interactions:setPosition(cc.p(0, 0))
    self:addChild(self.interactions, 90)
    self.interactions_position_x = display.right

    self.inventory_layer = display.newLayer()
    :addTo(self, 90)

    self.drag_num_sprite = display.newSprite("full.png")
    :move(display.cx, display.cy)
    :addTo(self.inventory_layer)

    self.plus = cc.MenuItemImage:create("plus.png", "plus.png")
    :onClicked(function()
        if self.drag_num ~= FULL then
            self.drag_num = self.drag_num + 1
            if self.drag_num == HALF then
                self.drag_num_sprite:setTexture("half.png")
            else
                self.drag_num_sprite:setTexture("full.png")
            end
        end
    end)
    cc.Menu:create(self.plus)
    :move(display.cx, display.cy + 75)
    :addTo(self.inventory_layer)

    self.minus = cc.MenuItemImage:create("minus.png", "minus.png")
    :onClicked(function()
        if self.drag_num ~= ONE then
            self.drag_num = self.drag_num - 1
            if self.drag_num == HALF then
                self.drag_num_sprite:setTexture("half.png")
            else
                self.drag_num_sprite:setTexture("one.png")
            end
        end
    end)
    cc.Menu:create(self.minus)
    :move(display.cx, display.cy - 75)
    :addTo(self.inventory_layer)

    self.drag_num = FULL

    --[[
    self.chest_flag = true
    self.left_inventory = require("app.views.inventory_view").new(false, {}, 100, display.cy - inventory_rows_chest * 50 / 2, inventory_cols_chest, inventory_rows_chest, cc.size(inventory_cols_chest * 50, inventory_rows_chest * 50), cc.p(50, 50), kCCScrollViewDirectionVertical, kCCTableViewFillTopDown, self)
    :setAnchorPoint(cc.p(0, 0))
    :setPosition(cc.p(0, 0))
    :addTo(self.inventory_layer)
    ]]

    self.left_inventory = require("app.views.inventory_view").new(false, {}, 100, display.cy - inventory_rows * 50 / 2, inventory_cols, inventory_rows, cc.size(inventory_cols * 50, inventory_rows * 50), cc.p(50, 50), kCCScrollViewDirectionVertical, kCCTableViewFillTopDown, self)
    :setAnchorPoint(cc.p(0, 0))
    :setPosition(cc.p(0, 0))
    :addTo(self.inventory_layer)

    self.right_inventory = require("app.views.inventory_view").new(false, self.m_character.inventory, display.right - 100 - inventory_cols * 50, display.cy - inventory_rows * 50 / 2, inventory_cols, inventory_rows, cc.size(inventory_cols * 50, inventory_rows * 50), cc.p(50, 50), kCCScrollViewDirectionVertical, kCCTableViewFillTopDown, self)
    :setAnchorPoint(cc.p(0, 0))
    :setPosition(cc.p(0, 0))
    :addTo(self.inventory_layer)
    self.right_inventory.table_view:reloadData()
    self.right_inventory.weight:setString(self.m_character.inventory.weight.." / "..self.m_character.inventory.weight_limit)
    self.right_inventory.name:setString(self.m_character.name)

    self.inventory_layer:setVisible(false)

    self.time = DAWN_TIME
    self.light_status = DAY

    self:init_torch_frame()
    local x, y = self.c_node:getPosition()
    self.torches[1] = torch:new()
    self.torches[1].position = cc.p(-100 + self.width / 2, 100 + self.height / 2)
    self.torches[1].sprite = display.newSprite("background/torch.png")
    :move(self.torches[1].position.x - self.m_character.position.x + display.cx, self.torches[1].position.y - self.m_character.position.y + display.cy + 60)
    :addTo(self.c_node, math.floor(display.top - (self.torches[1].position.y - self.m_character.position.y + display.cy)))
    self.torches[2] = torch:new()
    self.torches[2].position = cc.p(-700 + self.width / 2, 100 + self.height / 2)
    self.torches[2].sprite = display.newSprite("background/torch.png")
    :move(self.torches[2].position.x - self.m_character.position.x + display.cx, self.torches[2].position.y - self.m_character.position.y + display.cy + 60)
    :addTo(self.c_node, math.floor(display.top - (self.torches[2].position.y - self.m_character.position.y + display.cy)))
    self.torches[3] = torch:new()
    self.torches[3].position = cc.p(-100 + self.width / 2, 1300 + self.height / 2)
    self.torches[3].sprite = display.newSprite("background/torch.png")
    :move(self.torches[3].position.x - self.m_character.position.x + display.cx, self.torches[3].position.y - self.m_character.position.y + display.cy + 60)
    :addTo(self.c_node, math.floor(display.top - (self.torches[3].position.y - self.m_character.position.y + display.cy)))
    local screen_size = cc.Director:getInstance():getWinSize()
    local frame_size = cc.Director:getInstance():getOpenGLView():getFrameSize()
    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(screen_size["width"], screen_size["height"], cc.ResolutionPolicy.SHOW_ALL)

    self.screen_ratio = cc.p(frame_size["width"]/screen_size["width"], frame_size["height"]/screen_size["height"])

    local day_back = cc.GLProgram:createWithFilenames("background/back.vsh", "background/day.fsh")
    day_back:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    day_back:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    day_back:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    day_back:link()
    day_back:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(day_back, "day_back")
    local day_char = cc.GLProgram:createWithFilenames("background/char.vsh", "background/day.fsh")
    day_char:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    day_char:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    day_char:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    day_char:link()
    day_char:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(day_char, "day_char")
    local dawn_back = cc.GLProgram:createWithFilenames("background/back.vsh", "background/dawn.fsh")
    dawn_back:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    dawn_back:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    dawn_back:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    dawn_back:link()
    dawn_back:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(dawn_back, "dawn_back")
    local dawn_char = cc.GLProgram:createWithFilenames("background/char.vsh", "background/dawn.fsh")
    dawn_char:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    dawn_char:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    dawn_char:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    dawn_char:link()
    dawn_char:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(dawn_char, "dawn_char")
    local night_back = cc.GLProgram:createWithFilenames("background/back.vsh", "background/night.fsh")
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_back:link()
    night_back:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_back, "night_back")
    local night_char = cc.GLProgram:createWithFilenames("background/char.vsh", "background/night.fsh")
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_char:link()
    night_char:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_char, "night_char")
    self:scheduleUpdate(handler(self, self.step))
end

function SecondScene:onCleanup()
    self:removeAllEventListeners()
end

return SecondScene
