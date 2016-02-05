--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/23/2016
-- Time: 8:23 PM
-- To change this template use File | Settings | File Templates.
--

--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 12/30/2015
-- Time: 6:58 AM
-- To change this template use File | Settings | File Templates.
--

local SecondScene = class("SecondScene", cc.load("mvc").ViewBase)

local DAY_TIME = 120.0
local DAWN_TIME = 10.0
local NIGHT_TIME = 100.0
local DAWN = 0
local DAY = 1
local TWILIGHT = 2
local NIGHT = 3
local MAP_X = 200
local MAP_Y = 200
local STOP = -1
local DOWN = 0
local LEFT = 1
local RIGHT = 2
local UP = 3
local speed = 2.0

local minion_motions = {}
minion_motions[DOWN] = "MINION_DOWN"
minion_motions[LEFT] = "MINION_LEFT"
minion_motions[RIGHT] = "MINION_RIGHT"
minion_motions[UP] = "MINION_UP"

local font = require("app.views.font")
local character = require("app.object.character")
local struct = require("app.object.struct")
local functionality = require("app.object.functionality")
local plants = require("app.object.plants")
local plants_type = require("app.object.plants_type")
local torch = require("app.object.torch")
local identity = require("app.logic.identity")
local minion_logic = require("app.logic.minion_logic")
local fixedDeltaTimeScale = 60.0

SecondScene.minions = {}
SecondScene.torches = {}
SecondScene.minion_size = 1
SecondScene.m_character = {}
SecondScene.screen_ratio = cc.p(1.0, 1.0)
--SecondScene.shader_ratio = cc.p(1.0, 1.0)
SecondScene.width = 0.0
SecondScene.height = 0.0
SecondScene.f_width = 0.0
SecondScene.f_height = 0.0
SecondScene.time = DAWN_TIME
SecondScene.light_status = DAY
SecondScene.day_back = nil
SecondScene.day_char = nil
SecondScene.dawn_back = nil
SecondScene.dawn_char = nil
SecondScene.night_back = nil
SecondScene.night_char = nil
SecondScene.map = {}
SecondScene.map_move_flag = STOP
SecondScene.map_build_index = {}
SecondScene.map_characters = {}
SecondScene.touch_layer = {}
SecondScene.olo = {}
SecondScene.resources = {}
SecondScene.resources_50 = {}
SecondScene.structs_roof = {}
SecondScene.structs_wall = {}
SecondScene.structs = {}
SecondScene.c_node = {}
--SecondScene.slow_down = 0

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
    local a = 2
    local b = 1
    for i = 0, a do
        self:make_minion("John"..(i+1), identity.slave_farm, 250+i*10, -40)
        self.minions[i+1].logic:farm_init(self.structs)
        self.minions[i+1].logic:sleep_init(self.structs)
    end
    for i = 0, b do
        self:make_minion("Jack"..(i+1), identity.free_folk, -150-i*10, 50)
        self.minions[a+i+2].logic:thief_init({1, 2, 3, 4})
    end
end

function SecondScene:make_minion(name, id, x, y)
    self.minions[self.minion_size] = character:new()
    self.minions[self.minion_size].sprite = display.newSprite(display.getAnimationCache(minion_motions[DOWN]):getFrames()[1]:getSpriteFrame())
    :addTo(self.c_node)
    self.minions[self.minion_size]:set_map_characters(self.map_characters, self.minion_size, self.minions, self.m_character)
    self.minions[self.minion_size]:set_position(self.width / 2 + x, self.height / 2 + y)
    self.minions[self.minion_size]:change_position(0.0, 0.0, self.width / 2, self.height / 2)
    self.minions[self.minion_size]:set_name(name, 0.0)
    self.minions[self.minion_size]:set_id(id)
    self.minions[self.minion_size]:add_shadow()
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
                if self.structs[i].functionality == functionality.LB then
                    back_enter(self.structs[i].walls, "front", day_back)
                    back_enter(self.structs[i].walls, "back", day_back)
                    back_enter(self.structs[i].room1, "storage", day_back)
                    back_enter(self.structs[i].room1, "entrance", day_back)
                    back_enter(self.structs[i].room1, "floor", day_back)
                    back_enter(self.structs[i].room2, "storage", day_back)
                    back_enter(self.structs[i].room2, "entrance", day_back)
                    back_enter(self.structs[i].room2, "floor", day_back)
                    back_enter(self.structs[i].room3, "storage", day_back)
                    back_enter(self.structs[i].room3, "entrance", day_back)
                    back_enter(self.structs[i].room3, "floor", day_back)
                    back_enter(self.structs[i].roofs, "front", day_back)
                    back_enter(self.structs[i].roofs, "back", day_back)
                end
                if self.structs[i].functionality == functionality.FARM then
                    back_enter(self.structs[i].walls, "grass", day_back)
                    back_enter(self.structs[i].walls, "plants", day_back)
                    back_enter(self.structs[i].walls, "fences", day_back)
                end
            end
            if self.light_status == TWILIGHT or self.light_status == DAWN then
                local dawn_back = cc.GLProgramCache:getInstance():getGLProgram("dawn_back")
                if self.structs[i].functionality == functionality.LB then
                    back_enter(self.structs[i].walls, "front", dawn_back)
                    back_enter(self.structs[i].walls, "back", dawn_back)
                    back_enter(self.structs[i].room1, "storage", dawn_back)
                    back_enter(self.structs[i].room1, "entrance", dawn_back)
                    back_enter(self.structs[i].room1, "floor", dawn_back)
                    back_enter(self.structs[i].room2, "storage", dawn_back)
                    back_enter(self.structs[i].room2, "entrance", dawn_back)
                    back_enter(self.structs[i].room2, "floor", dawn_back)
                    back_enter(self.structs[i].room3, "storage", dawn_back)
                    back_enter(self.structs[i].room3, "entrance", dawn_back)
                    back_enter(self.structs[i].room3, "floor", dawn_back)
                    back_enter(self.structs[i].roofs, "front", dawn_back)
                    back_enter(self.structs[i].roofs, "back", dawn_back)
                end
                if self.structs[i].functionality == functionality.FARM then
                    back_enter(self.structs[i].walls, "grass", dawn_back)
                    back_enter(self.structs[i].walls, "plants", dawn_back)
                    back_enter(self.structs[i].walls, "fences", dawn_back)
                end
            end
            if self.light_status == NIGHT then
                local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back")
                if self.structs[i].functionality == functionality.LB then
                    back_enter(self.structs[i].walls, "front", night_back)
                    back_enter(self.structs[i].walls, "back", night_back)
                    back_enter(self.structs[i].room1, "storage", night_back)
                    back_enter(self.structs[i].room1, "entrance", night_back)
                    back_enter(self.structs[i].room1, "floor", night_back)
                    back_enter(self.structs[i].room2, "storage", night_back)
                    back_enter(self.structs[i].room2, "entrance", night_back)
                    back_enter(self.structs[i].room2, "floor", night_back)
                    back_enter(self.structs[i].room3, "storage", night_back)
                    back_enter(self.structs[i].room3, "entrance", night_back)
                    back_enter(self.structs[i].room3, "floor", night_back)
                    back_enter(self.structs[i].roofs, "front", night_back)
                    back_enter(self.structs[i].roofs, "back", night_back)
                end
                if self.structs[i].functionality == functionality.FARM then
                    back_enter(self.structs[i].walls, "grass", night_back)
                    back_enter(self.structs[i].walls, "plants", night_back)
                    back_enter(self.structs[i].walls, "fences", night_back)
                end
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
            self.minions[i]:set_name(self.minions[i].name, 0.0)
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
    --self.touch_layer:unregisterScriptTouchHandler(cc.Handler.EVENT_TOUCH_BEGAN)
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
            if struct.functionality == functionality.LB then
                back_enter(self.structs[i].walls, "front", day_back)
                back_enter(self.structs[i].walls, "back", day_back)
                back_enter(self.structs[i].room1, "storage", day_back)
                back_enter(self.structs[i].room1, "entrance", day_back)
                back_enter(self.structs[i].room1, "floor", day_back)
                back_enter(self.structs[i].room2, "storage", day_back)
                back_enter(self.structs[i].room2, "entrance", day_back)
                back_enter(self.structs[i].room2, "floor", day_back)
                back_enter(self.structs[i].room3, "storage", day_back)
                back_enter(self.structs[i].room3, "entrance", day_back)
                back_enter(self.structs[i].room3, "floor", day_back)
                back_enter(self.structs[i].roofs, "front", day_back)
                back_enter(self.structs[i].roofs, "back", day_back)
            end
            if struct.functionality == functionality.FARM then
                back_enter(self.structs[i].walls, "grass", day_back)
                back_enter(self.structs[i].walls, "plants", day_back)
                back_enter(self.structs[i].walls, "fences", day_back)
                for ii = 0, self.structs[i].map.x - 1 do
                    for jj = 0, self.structs[i].map.y - 1 do
                        if self.structs[i].plants.fruit_sprites[ii][jj] ~= nil then
                            self.structs[i].plants.fruit_sprites[ii][jj]:setGLProgram(day_char)
                        end
                    end
                end
            end
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
            if struct.functionality == functionality.LB then
                back_enter(self.structs[i].walls, "front", dawn_back)
                back_enter(self.structs[i].walls, "back", dawn_back)
                back_enter(self.structs[i].room1, "storage", dawn_back)
                back_enter(self.structs[i].room1, "entrance", dawn_back)
                back_enter(self.structs[i].room1, "floor", dawn_back)
                back_enter(self.structs[i].room2, "storage", dawn_back)
                back_enter(self.structs[i].room2, "entrance", dawn_back)
                back_enter(self.structs[i].room2, "floor", dawn_back)
                back_enter(self.structs[i].room3, "storage", dawn_back)
                back_enter(self.structs[i].room3, "entrance", dawn_back)
                back_enter(self.structs[i].room3, "floor", dawn_back)
                back_enter(self.structs[i].roofs, "front", dawn_back)
                back_enter(self.structs[i].roofs, "back", dawn_back)
            end
            if struct.functionality == functionality.FARM then
                back_enter(self.structs[i].walls, "grass", dawn_back)
                back_enter(self.structs[i].walls, "plants", dawn_back)
                back_enter(self.structs[i].walls, "fences", dawn_back)
                for ii = 0, self.structs[i].map.x - 1 do
                    for jj = 0, self.structs[i].map.y - 1 do
                        if self.structs[i].plants.fruit_sprites[ii][jj] ~= nil then
                            self.structs[i].plants.fruit_sprites[ii][jj]:setGLProgram(dawn_char)
                        end
                    end
                end
            end
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
            if struct.functionality == functionality.LB then
                back_enter(self.structs[i].walls, "front", night_back)
                back_enter(self.structs[i].walls, "back", night_back)
                back_enter(self.structs[i].room1, "storage", night_back)
                back_enter(self.structs[i].room1, "entrance", night_back)
                back_enter(self.structs[i].room1, "floor", night_back)
                back_enter(self.structs[i].room2, "storage", night_back)
                back_enter(self.structs[i].room2, "entrance", night_back)
                back_enter(self.structs[i].room2, "floor", night_back)
                back_enter(self.structs[i].room3, "storage", night_back)
                back_enter(self.structs[i].room3, "entrance", night_back)
                back_enter(self.structs[i].room3, "floor", night_back)
                back_enter(self.structs[i].roofs, "front", night_back)
                back_enter(self.structs[i].roofs, "back", night_back)
            end
            if struct.functionality == functionality.FARM then
                back_enter(self.structs[i].walls, "grass", night_back)
                back_enter(self.structs[i].walls, "plants", night_back)
                back_enter(self.structs[i].walls, "fences", night_back)
                for ii = 0, self.structs[i].map.x - 1 do
                    for jj = 0, self.structs[i].map.y - 1 do
                        if self.structs[i].plants.fruit_sprites[ii][jj] ~= nil then
                            self.structs[i].plants.fruit_sprites[ii][jj]:setGLProgram(night_char)
                        end
                    end
                end
            end
        end
    end
    for i, minion in pairs(self.minions) do
        if self.minions[i].sprite ~= nil then
            self.minions[i].sprite:setGLProgram(night_char)
        end
    end
    self.m_character.sprite:setGLProgram(night_char)
    local lights = {}
    local lights_num = 0
    for i, single_torch in pairs(self.torches) do
        if self.torches[i].sprite ~= nil then
            self.torches[i].sprite:setGLProgram(night_char)
            lights_num = lights_num + 1
            lights[lights_num] = cc.p(math.floor((self.torches[i].position.x - self.m_character.position.x) + display.cx), math.floor((self.torches[i].position.y - self.m_character.position.y + 50) + display.cy))
        end
    end

    self.structs_roof:setGLProgram(night_back)
    self.structs_wall:setGLProgram(night_back)
    local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_back)
    gl_state:setUniformInt("lights_num", lights_num)
    for i, single_light in pairs(lights) do
        gl_state:setUniformVec2("light"..(i-1), single_light)
    end

    local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_char)
    gl_state:setUniformInt("lights_num", lights_num)
    for i, single_light in pairs(lights) do
        gl_state:setUniformVec2("light"..(i-1), single_light)
    end
end

function SecondScene:step(dt)
    --self.olo:setString(math.floor(self.m_character.position.x).." "..math.floor(self.m_character.position.y))
    self.time = self.time + dt
    if self.light_status == DAWN and self.time >= DAWN_TIME then
        enter_day(self)
        self.light_status = DAY
    end
    if self.light_status == DAY and self.time >= DAY_TIME + DAWN_TIME then
        enter_dawn(self)
        self.light_status = TWILIGHT
    end
    if self.light_status == TWILIGHT and self.time >= DAY_TIME + DAWN_TIME + DAWN_TIME then
        enter_night(self)
        self.light_status = NIGHT
    end
    if self.light_status == NIGHT and self.time >= DAY_TIME + DAWN_TIME + DAWN_TIME + NIGHT_TIME then
        enter_dawn(self)
        self.light_status = DAWN
        self.time = 0.0
    end
    if self.light_status == NIGHT then
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
        gl_state:setUniformInt("lights_num", lights_num)
        for i, single_light in pairs(lights) do
            gl_state:setUniformVec2("light"..(i-1), single_light)
        end

        local night_char = cc.GLProgramCache:getInstance():getGLProgram("night_char")
        local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_char)
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
        update_position(self, 1.0 * speed * dt * fixedDeltaTimeScale, 0.0)
        if self.m_character.last_act ~= RIGHT then
            self.m_character.sprite:stopAllActions()
            self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[RIGHT]))
            self.m_character.last_act = RIGHT
        end
    end
    if self.map_move_flag == LEFT then
        update_position(self, 0.0 - 1.0 * speed * dt * fixedDeltaTimeScale, 0.0)
        if self.m_character.last_act ~= LEFT then
            self.m_character.sprite:stopAllActions()
            self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[LEFT]))
            self.m_character.last_act = LEFT
        end
    end
    if self.map_move_flag == UP then
        update_position(self, 0.0, 1.0 * speed * dt * fixedDeltaTimeScale)
        if self.m_character.last_act ~= UP then
            self.m_character.sprite:stopAllActions()
            self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[UP]))
            self.m_character.last_act = UP
        end
    end
    if self.map_move_flag == DOWN then
        update_position(self, 0.0, 0.0 - 1.0 * speed * dt * fixedDeltaTimeScale)
        if self.m_character.last_act ~= DOWN then
            self.m_character.sprite:stopAllActions()
            self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[DOWN]))
            self.m_character.last_act = DOWN
        end
    end
    if self.map_move_flag ~= STOP then
        --self.structs_roof:move(display.cx - self.m_character.position.x + self.width / 2, display.cy - self.m_character.position.y + self.width / 2)
        --self.structs_wall:move(display.cx - self.m_character.position.x + self.width / 2, display.cy - self.m_character.position.y + self.width / 2)
        self.map:move(display.cx - self.m_character.position.x, display.cy - self.m_character.position.y)
    elseif self.m_character.last_act ~= STOP then
        self.m_character.sprite:stopAllActions()
        self.m_character.sprite:setSpriteFrame(display.getAnimationCache(minion_motions[self.m_character.last_act]):getFrames()[1]:getSpriteFrame())
        self.m_character.last_act = STOP
    end

    for i, minion in pairs(self.minions) do
        self.minions[i].logic:think_about_life(self.m_character, self.minions, self.structs, self.light_status, self.map_build_index, i, dt)
        self:detect_minion(i)
        self:update_minion(i)
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

--[[
function SecondScene:draw(renderer, transform, flags)
    --self.olo:setString("here")
end
]]

function SecondScene:onCreate()
    local playButton = cc.MenuItemImage:create("PlayButton.png", "PlayButton.png")
    :onClicked(function()
        self:getApp():enterScene("MainScene")
    end)
    cc.Menu:create(playButton)
    :move(display.right - 120, display.top - 50)
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
    --self:create_collision_test(2, -125, 750)
    --self:create_lb(2, "lb1", -250, 750)

    self:create_farm(2, "farm1", -100, 1300)
    self:create_lb(3, "lb1", -550, 100)
    self:create_lb(4, "lb1", -100, -350)

    self.m_character = character:new()
    self:init_minion_frame(self)
    local frame = display.getAnimationCache(minion_motions[DOWN]):getFrames()[2]
    self.m_character.sprite = display.newSprite(frame:getSpriteFrame())
        :addTo(self.c_node, math.floor(display.cy))
    self.m_character:set_map_characters(self.map_characters, 0, self.minions, self.m_character)
    self.m_character:set_position(self.width / 2, self.height / 2)
    self.m_character:change_position(0.0, 0.0, self.width / 2, self.height / 2)
    self.m_character:set_name("Pandora", 0.2)
    self.m_character:add_shadow()

    local touch_layer = display.newLayer()
    :addTo(self, 90)

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(
        function(touch, event)
            local x, y = touch:getLocation().x, touch:getLocation().y
            if x >= 0 and x < 275 and y >= 0 and y < 200 then
                if x >= 75 and x < 150 and y >= 75 and y < 150 then
                    self.map_move_flag = UP
                    return true
                end
                if x >= 0 and x < 75 and y >= 0 and y < 75 then
                    self.map_move_flag = LEFT
                    return true
                end
                if x >= 75 and x < 150 and y >= 0 and y < 75 then
                    self.map_move_flag = DOWN
                    return true
                end
                if x >= 150 and x < 225 and y >= 0 and y < 75 then
                    self.map_move_flag = RIGHT
                    return true
                end
                self.map_move_flag = STOP
            end
            return true
        end
        ,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(
        function(touch, event)
            local x, y = touch:getLocation().x, touch:getLocation().y
            if x >= 0 and x < 275 and y >= 0 and y < 200 then
                if x >= 75 and x < 150 and y >= 75 and y < 150 then
                    self.map_move_flag = UP
                    return
                end
                if x >= 0 and x < 75 and y >= 32.5 and y < 107.5 then
                    self.map_move_flag = LEFT
                    return
                end
                if x >= 75 and x < 150 and y >= 0 and y < 75 then
                    self.map_move_flag = DOWN
                    return
                end
                if x >= 150 and x < 225 and y >=32.50 and y < 107.5 then
                    self.map_move_flag = RIGHT
                    return
                end
                self.map_move_flag = STOP
            end
            return
        end
        ,cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(
        function(touch, event)
            local x, y = touch:getLocation().x, touch:getLocation().y
            if x >= 0 and x < 275 and y >= 0 and y < 200 then
                self.map_move_flag = STOP
            end
            return
        end
        ,cc.Handler.EVENT_TOUCH_ENDED)
    touch_layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,touch_layer)

    display.newSprite("up.png")
    :move(display.left + 100, display.bottom + 100)
    :addTo(touch_layer)
    display.newSprite("left.png")
    :move(display.left + 25, display.bottom + 57.5)
    :addTo(touch_layer)
    display.newSprite("down.png")
    :move(display.left + 100, display.bottom + 25)
    :addTo(touch_layer)
    display.newSprite("right.png")
    :move(display.left + 175, display.bottom + 57.5)
    :addTo(touch_layer)
    self.time = DAWN_TIME
    self.light_status = DAY

    local x, y = self.c_node:getPosition()
    self.torches[1] = torch:new()
    self.torches[1].position = cc.p(-100 + self.width / 2, 100 + self.height / 2)
    self.torches[1].sprite = display.newSprite("background/torch.png")
        :move(self.torches[1].position.x - self.m_character.position.x + display.cx, self.torches[1].position.y - self.m_character.position.y + display.cy + 40)
        :addTo(self.c_node, math.floor(display.top - (self.torches[1].position.y - self.m_character.position.y + display.cy)))
    self.torches[2] = torch:new()
    self.torches[2].position = cc.p(-700 + self.width / 2, 100 + self.height / 2)
    self.torches[2].sprite = display.newSprite("background/torch.png")
        :move(self.torches[2].position.x - self.m_character.position.x + display.cx, self.torches[2].position.y - self.m_character.position.y + display.cy + 40)
        :addTo(self.c_node, math.floor(display.top - (self.torches[2].position.y - self.m_character.position.y + display.cy)))
    self.torches[3] = torch:new()
    self.torches[3].position = cc.p(-100 + self.width / 2, 1300 + self.height / 2)
    self.torches[3].sprite = display.newSprite("background/torch.png")
        :move(self.torches[3].position.x - self.m_character.position.x + display.cx, self.torches[3].position.y - self.m_character.position.y + display.cy + 40)
        :addTo(self.c_node, math.floor(display.top - (self.torches[3].position.y - self.m_character.position.y + display.cy)))
    local screen_size = cc.Director:getInstance():getWinSize()
    local frame_size = cc.Director:getInstance():getOpenGLView():getFrameSize()
    --cc.Director:getInstance():getOpenGLView():setFrameZoomFactor(screen_size["height"] / frame_size["height"] / cc.Director:getInstance():getOpenGLView():getRetinaFactor())
    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(screen_size["width"], screen_size["height"], cc.ResolutionPolicy.SHOW_ALL)
    --local design_size = cc.Director:getInstance():getOpenGLView():getDesignResolutionSize()
    --local origin = cc.Director:getInstance():getOpenGLView():getVisibleOrigin()
    --local visible_size = cc.Director:getInstance():getVisibleSize()

    --self.screen_ratio = cc.p(screen_size["width"]/frame_size["width"], screen_size["height"]/frame_size["height"])
    self.screen_ratio = cc.p(frame_size["width"]/screen_size["width"], frame_size["height"]/screen_size["height"])
    --self.shader_ratio = cc.p(screen_size["width"]/visible_size["width"], screen_size["height"]/visible_size["height"])
    --self.olo:setString(frame_size["width"]..""..frame_size["height"])
    --self.olo:setString(screen_size["width"]..""..screen_size["height"])
    --self.olo:setString(frame_size["width"]..""..frame_size["height"])
    --self.olo:setString(self.screen_ratio.x..""..self.screen_ratio.y)
    --self.olo:setString(origin.x.." "..origin.y)
    --self.olo:setString(design_size["width"].." "..design_size["height"])
    --self.olo:setString(visible_size["width"].." "..visible_size["height"])

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
