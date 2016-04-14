--
-- Created by IntelliJ IDEA.
-- User: wzl
-- Date: 1/23/2016
-- Time: 8:23 PM
-- To change this template use File | Settings | File Templates.
--

local SecondScene = class("SecondScene", cc.load("mvc").ViewBase)

local MAGIC_NUMBER = 1136.0/960.0
local HOLD_TIME = 0.5
local DAY_TIME = 120.0
local DAWN_TIME = 10.0
local NIGHT_TIME = 100.0
local OPACITY_COUNT = 1.1
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
local DEAD_BODY = 0
local DROPPED_ITEM = 1
local HELP = 2
local TRADE = 3
local success = 1
local working = 0
local failed = -1
local normal_damage = 0
local bleed_damage = 1
local burn_damage = 2
local interaction_pop_speed = 3.0
local inventory_cols = 6
local inventory_rows = 4
local inventory_cols_chest = 8
local inventory_rows_chest = 7
local oven_up_cols = 4
local oven_down_cols = 6
local oven_light_radius_ratio = 2
local event_spread_dis = 5

local oven_flame_motion = "OVEN_FLAME"
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
local dropped_item = require("app.object.dropped_item")
local dead_body = require("app.object.dead_body")
local shouting = require("app.object.shouting")
local cool_down = require("app.object.cool_down")
local identity = require("app.logic.identity")
local occupation = require("app.logic.occupation")
local minion_logic = require("app.logic.minion_logic")
local drag = require("app.logic.drag")
local fixedDeltaTimeScale = 60.0

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

local movement_image_name = {}
movement_image_name[identity.slave] = "character/slave.png"
movement_image_name[identity.free_folk] = "character/free_folk.png"
movement_image_name[identity.guard] = "character/guard.png"
local attack_image_name = {}
attack_image_name[identity.slave] = "character/slave_attack.png"
attack_image_name[identity.free_folk] = "character/free_folk_attack.png"
attack_image_name[identity.guard] = "character/guard_attack.png"

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

function SecondScene:init_minion_frame()
    for minion_type = identity.slave, identity.guard do
        local minion_image = display.loadImage(movement_image_name[minion_type])
        local frameWidth = minion_image:getPixelsWide() / 4
        local frameHeight = minion_image:getPixelsHigh() / 4
        local frame_id = {0, 1, 2, 0, 1, 3}
        local animation_time = 0.2
        for motion, minion_motion in pairs(minion_motions[minion_type]) do
            local frames = {}
            for i, id in pairs(frame_id) do
                frames[i] = display.newSpriteFrame(minion_image, cc.rect(id * frameWidth, frameHeight * motion, frameWidth, frameHeight))
            end
            local animation = display.newAnimation(frames, animation_time)
            display.setAnimationCache(minion_motion, animation)
        end
        local minion_image = display.loadImage(attack_image_name[minion_type])
        for motion, minion_motion in pairs(minion_motions_attack[minion_type]) do
            local frames = {}
            for i = 0, 2 do
                frames[i + 1] = display.newSpriteFrame(minion_image, cc.rect(i * frameWidth, frameHeight * motion, frameWidth, frameHeight))
            end
            local animation = display.newAnimation(frames, animation_time)
            display.setAnimationCache(minion_motion, animation)
        end
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
    local a = 8
    local b = 0
    local c = 1
    local d = 0
    for i = 0, a do
        self:make_minion(name_table[i + 1], identity.slave, 250+i*30, -40)
        local minion = self.minions[i + 1]
        minion.occupation = occupation.farmer
        minion.logic:farm_init(2, 1, 1)
        minion.logic:sleep_init(3, 1)
        --[[
        minion.inventory[1] = {}
        minion.inventory[1].type = item_type.KEY
        minion.inventory[1].num = 1
        minion.inventory[1].sequence = 1111
        ]]
        --minion:equip_right_hand(minion.inventory[1])
    end
    for i = 0, b do
        self:make_minion(name_table[i + a + 2], identity.guard, -150-i*30, 50)
        local minion = self.minions[a+i+2]
        minion.logic:patroling_guardian_init({1, 2, 3, 4}, {})
        minion.occupation = occupation.patrol
        minion.inventory[1] = {}
        minion.inventory[1].type = item_type.SWORD
        minion.inventory[1].num = 1
        minion.inventory[2] = {}
        minion.inventory[2].type = item_type.ROPE
        minion.inventory[2].num = 1
        minion.inventory.weight = minion.inventory[1].type.weight
        minion:equip_right_hand(minion.inventory[1])
        minion:equip_left_hand(minion.inventory[2])
    end
    for i = 0, c do
        self:make_minion(name_table[i + a + b + 3], identity.slave, -150-i*5, 50)
        local minion = self.minions[i + a + b + 3]
        minion.occupation = occupation.baker
        minion.logic:bake_init(1, 1, 1, 1)
        minion.logic:sleep_init(1, 2)
        minion.inventory[1] = {}
        minion.inventory[1].type = item_type.KEY
        minion.inventory[1].num = 1
        minion.inventory[1].sequence = 1111
        minion.inventory[2] = {}
        minion.inventory[2].type = item_type.TONGS
        minion.inventory[2].num = 1
        minion.inventory.weight = item_type.TONGS.weight
        minion:equip_right_hand(minion.inventory[2])
    end
    for i = 0, d do
        self:make_minion(name_table[i + a + b + c + 4], identity.free_folk, -150-i*30, 50)
        local minion = self.minions[i + a + b + c + 4]
        --minion.chain_target = self.minions[10]
        --minion.chain_target = self.m_character
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

function SecondScene:init_oven_flame_frame()
    local oven_flame_image = display.loadImage("object/oven_flame.png")
    local oven_flame_frames = {}
    oven_flame_frames[1] = display.newSpriteFrame(oven_flame_image, cc.rect(0, 0, 30, 30))
    oven_flame_frames[2] = display.newSpriteFrame(oven_flame_image, cc.rect(30, 0, 30, 30))
    oven_flame_frames[3] = display.newSpriteFrame(oven_flame_image, cc.rect(60, 0, 30, 30))
    local animation_time = 0.2
    local animation = display.newAnimation(oven_flame_frames, animation_time)
    display.setAnimationCache(oven_flame_motion, animation)
end

function SecondScene:make_minion(name, id, x, y)
    self.minions[self.minion_size] = character:new()
    self.minions[self.minion_size].main_game = self
    self.minions[self.minion_size].sprite = display.newSprite(display.getAnimationCache(minion_motions[id][DOWN]):getFrames()[1]:getSpriteFrame())
    :addTo(self.c_node)
    self.minions[self.minion_size]:set_map_characters(self.map_characters, self.minion_size, self.minions, self.m_character)
    self.minions[self.minion_size]:set_position(self.width / 2 + x, self.height / 2 + y)
    self.minions[self.minion_size]:change_position(0.0, 0.0, self.width / 2 + self.m_init_pos.x, self.height / 2 + self.m_init_pos.y)
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

function SecondScene:struct_shader(i, back_shader, char_shader, shadow_shader)
    if self.structs[i].functionality == functionality.LB or self.structs[i].functionality == functionality.SLAVE_LB then
        back_enter(self.structs[i].walls, "front", back_shader)
        back_enter(self.structs[i].walls, "back", back_shader)
        if shadow_shader ~= nil then
            back_enter(self.structs[i].walls_shadow, "front", shadow_shader)
            back_enter(self.structs[i].walls_shadow, "back", shadow_shader)
        end
        back_enter(self.structs[i].room1, "storage", back_shader)
        back_enter(self.structs[i].room1, "oven", back_shader)
        back_enter(self.structs[i].room1, "oven_deco", back_shader)
        back_enter(self.structs[i].room1, "entrance", back_shader)
        back_enter(self.structs[i].room1, "floor", back_shader)
        back_enter(self.structs[i].room1, "beds", back_shader)
        back_enter(self.structs[i].room1, "beds_deco", back_shader)
        back_enter(self.structs[i].room1, "front", back_shader)
        back_enter(self.structs[i].room1, "back", back_shader)
        back_enter(self.structs[i].room1, "deco", back_shader)
        back_enter(self.structs[i].room2, "storage", back_shader)
        back_enter(self.structs[i].room2, "oven", back_shader)
        back_enter(self.structs[i].room2, "oven_deco", back_shader)
        back_enter(self.structs[i].room2, "entrance", back_shader)
        back_enter(self.structs[i].room2, "floor", back_shader)
        back_enter(self.structs[i].room2, "beds", back_shader)
        back_enter(self.structs[i].room2, "beds_deco", back_shader)
        back_enter(self.structs[i].room2, "front", back_shader)
        back_enter(self.structs[i].room2, "back", back_shader)
        back_enter(self.structs[i].room2, "deco", back_shader)
        back_enter(self.structs[i].room3, "storage", back_shader)
        back_enter(self.structs[i].room3, "oven", back_shader)
        back_enter(self.structs[i].room3, "oven_deco", back_shader)
        back_enter(self.structs[i].room3, "entrance", back_shader)
        back_enter(self.structs[i].room3, "floor", back_shader)
        back_enter(self.structs[i].room3, "beds", back_shader)
        back_enter(self.structs[i].room3, "beds_deco", back_shader)
        back_enter(self.structs[i].room3, "front", back_shader)
        back_enter(self.structs[i].room3, "back", back_shader)
        back_enter(self.structs[i].room3, "deco", back_shader)
        back_enter(self.structs[i].roofs, "front", back_shader)
        back_enter(self.structs[i].roofs, "back", back_shader)
        back_enter(self.structs[i].roofs, "deco", back_shader)
        if shadow_shader ~= nil then
            back_enter(self.structs[i].roofs_shadow, "front", shadow_shader)
            back_enter(self.structs[i].roofs_shadow, "back", shadow_shader)
        end
    end
    if self.structs[i].functionality == functionality.FARM then
        back_enter(self.structs[i].walls, "grass", back_shader)
        back_enter(self.structs[i].walls, "dirt", back_shader)
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

function SecondScene:struct_shader_night(i)
    local back_roof = cc.GLProgramCache:getInstance():getGLProgram("night_back_roof")
    local back_map = cc.GLProgramCache:getInstance():getGLProgram("night_back")
    local back_shader = cc.GLProgramCache:getInstance():getGLProgram("night_back_wall")
    local back_shader1 = cc.GLProgramCache:getInstance():getGLProgram("night_back1")
    local back_shader2 = cc.GLProgramCache:getInstance():getGLProgram("night_back2")
    local back_shader3 = cc.GLProgramCache:getInstance():getGLProgram("night_back3")
    local char_shader = cc.GLProgramCache:getInstance():getGLProgram("night_char")
    if self.structs[i].functionality == functionality.LB or self.structs[i].functionality == functionality.SLAVE_LB then
        back_enter(self.structs[i].walls, "front", back_shader)
        back_enter(self.structs[i].walls, "back", back_shader)
        back_enter(self.structs[i].room1, "storage", back_shader1)
        back_enter(self.structs[i].room1, "oven", back_shader1)
        back_enter(self.structs[i].room1, "oven_deco", back_shader1)
        back_enter(self.structs[i].room1, "entrance", back_shader1)
        back_enter(self.structs[i].room1, "floor", back_shader1)
        back_enter(self.structs[i].room1, "beds", back_shader1)
        back_enter(self.structs[i].room1, "beds_deco", back_shader1)
        back_enter(self.structs[i].room1, "front", back_shader1)
        back_enter(self.structs[i].room1, "back", back_shader1)
        back_enter(self.structs[i].room1, "deco", back_shader1)
        back_enter(self.structs[i].room2, "storage", back_shader2)
        back_enter(self.structs[i].room2, "oven", back_shader2)
        back_enter(self.structs[i].room2, "oven_deco", back_shader2)
        back_enter(self.structs[i].room2, "entrance", back_shader2)
        back_enter(self.structs[i].room2, "floor", back_shader2)
        back_enter(self.structs[i].room2, "beds", back_shader2)
        back_enter(self.structs[i].room2, "beds_deco", back_shader2)
        back_enter(self.structs[i].room2, "front", back_shader2)
        back_enter(self.structs[i].room2, "back", back_shader2)
        back_enter(self.structs[i].room2, "deco", back_shader2)
        back_enter(self.structs[i].room3, "storage", back_shader3)
        back_enter(self.structs[i].room3, "oven", back_shader3)
        back_enter(self.structs[i].room3, "oven_deco", back_shader3)
        back_enter(self.structs[i].room3, "entrance", back_shader3)
        back_enter(self.structs[i].room3, "floor", back_shader3)
        back_enter(self.structs[i].room3, "beds", back_shader3)
        back_enter(self.structs[i].room3, "beds_deco", back_shader3)
        back_enter(self.structs[i].room3, "front", back_shader3)
        back_enter(self.structs[i].room3, "back", back_shader3)
        back_enter(self.structs[i].room3, "deco", back_shader3)
        back_enter(self.structs[i].roofs, "front", back_roof)
        back_enter(self.structs[i].roofs, "back", back_roof)
        back_enter(self.structs[i].roofs, "deco", back_roof)
    end
    if self.structs[i].functionality == functionality.FARM then
        back_enter(self.structs[i].walls, "grass", back_map)
        back_enter(self.structs[i].walls, "dirt", back_map)
        back_enter(self.structs[i].walls, "plants", back_map)
        back_enter(self.structs[i].walls, "fences", back_map)
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
        if self.structs[i].roofs_shadow ~= nil then
            self.structs[i].roofs_shadow:move(x + self.structs[i].position.x - self.m_character.position.x - display.cx - self.shadow_offset.x, y + self.structs[i].position.y - self.m_character.position.y - display.cy - self.shadow_offset.y)
        end
        if self.structs[i].walls ~= nil then
            self.structs[i].walls:move(x + self.structs[i].position.x - self.m_character.position.x - display.cx, y + self.structs[i].position.y - self.m_character.position.y - display.cy)
        end
        if self.structs[i].walls_shadow ~= nil then
            self.structs[i].walls_shadow:move(x + self.structs[i].position.x - self.m_character.position.x - display.cx - self.shadow_offset.x, y + self.structs[i].position.y - self.m_character.position.y - display.cy - self.shadow_offset.y)
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
                local day_back_shadow = cc.GLProgramCache:getInstance():getGLProgram("day_back_shadow")
                self:struct_shader(i, day_back, day_char, day_back_shadow)
            end
            if self.light_status == TWILIGHT or self.light_status == DAWN then
                local dawn_back = cc.GLProgramCache:getInstance():getGLProgram("dawn_back")
                local dawn_char = cc.GLProgramCache:getInstance():getGLProgram("dawn_char")
                self:struct_shader(i, dawn_back, dawn_char)
            end
            if self.light_status == NIGHT then
                self:struct_shader_night(i)
            end
        end
    end
end

function SecondScene:detect_torch(i)
    if self.torches[i].sprite ~= nil then
        self.c_node:reorderChild(self.torches[i].sprite, math.floor(display.top - (self.torches[i].position.y - self.m_character.position.y + display.cy)))
        self.torches[i].sprite:move(self.torches[i].position.x - self.m_character.position.x + display.cx, self.torches[i].position.y - self.m_character.position.y + display.cy + 30)
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

function SecondScene:update_minion(i, dt)
    if self.minions[i].sprite ~= nil then
        if self.minions[i].dir ~= STOP and self.minions[i].animated == false then
            self.minions[i].sprite:stopAllActions()
            --self.minions[i].sprite:playAnimationForever(display.getAnimationCache(minion_motions[self.minions[i].dir]))
            self.minions[i].animated = true
        elseif self.minions[i].dir == STOP and self.minions[i].animated == true then
            self.minions[i].sprite:stopAllActions()
            self.minions[i].animated = false
        end
        if self.minions[i].dir ~= STOP then
            self.minions[i]:update_frame(self.minions[i].dir, dt, self.sleep_purge)
        else
            self.minions[i]:reset_frame(self.sleep_purge, dt)
        end
    end
end

function SecondScene:detect_minion(i)
    if self.sleep_purge == true then
        if self.minions[i].sprite ~= nil then
            self.minions[i].name_txt:removeFromParentAndCleanup(true)
            self.minions[i].name_txt = nil
            if self.minions[i].right_hand ~= nil then
                self.minions[i].right_hand.sprite:removeFromParentAndCleanup(true)
                self.minions[i].right_hand.sprite = nil
            end
            if self.minions[i].left_hand ~= nil then
                self.minions[i].left_hand.sprite:removeFromParentAndCleanup(true)
                self.minions[i].left_hand.sprite = nil
            end
            self.minions[i].sprite:stopAllActions()
            self.minions[i].sprite:removeFromParentAndCleanup(true)
            self.minions[i].sprite = nil
            self.minions[i].animated = false
        end
        return
    end
    if self.minions[i].sprite ~= nil then
        if self.light_status == NIGHT then
            self.minions[i]:change_night_level_shader()
        end
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
            if self.minions[i].right_hand ~= nil then
                self.minions[i].right_hand.sprite:removeFromParentAndCleanup(true)
                self.minions[i].right_hand.sprite = nil
            end
            if self.minions[i].left_hand ~= nil then
                self.minions[i].left_hand.sprite:removeFromParentAndCleanup(true)
                self.minions[i].left_hand.sprite = nil
            end
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
            self.minions[i].sprite = display.newSprite(display.getAnimationCache(minion_motions[self.minions[i].id][self.minions[i].last_act]):getFrames()[1]:getSpriteFrame())
            :addTo(self.c_node)
            if self.light_status == DAY then
                local day_char = cc.GLProgramCache:getInstance():getGLProgram("day_char")
                self.minions[i]:set_gl(day_char)
            end
            if self.light_status == TWILIGHT or self.light_status == DAWN then
                local dawn_char = cc.GLProgramCache:getInstance():getGLProgram("dawn_char")
                self.minions[i]:set_gl(dawn_char)
            end
            if self.light_status == NIGHT then
                self.minions[i]:change_night_level_shader()
            end
            if self.minions[i].right_hand ~= nil then
                self.minions[i]:show_right_hand_item()
            end
            if self.minions[i].left_hand ~= nil then
                self.minions[i]:show_left_hand_item()
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
    local day_back_shadow = cc.GLProgramCache:getInstance():getGLProgram("day_back_shadow")
    back_enter(self.map, "ground", day_back)
    back_enter(self.map, "grass", day_back)
    for i, struct in pairs(self.structs) do
        if struct.in_vision == true then
            self:struct_shader(i, day_back, day_char, day_back_shadow)
        end
    end
    self.structs_roof:setGLProgram(day_back)
    self.structs_roof_shadow:setGLProgram(day_back_shadow)
    self.structs_back:setGLProgram(day_back)
    self.structs_wall:setGLProgram(day_back)
    self.structs_wall_shadow:setGLProgram(day_back_shadow)
    self.structs_room1:setGLProgram(day_back)
    self.structs_room2:setGLProgram(day_back)
    self.structs_room3:setGLProgram(day_back)
    for i = 1, MAX_MINIONS_NUM do
        if self.minions[i] ~= nil then
            if self.minions[i].sprite ~= nil then
                self.minions[i]:set_gl(day_char)
            end
        end
    end
    self.m_character:set_gl(day_char)
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
    self.structs_back:setGLProgram(dawn_back)
    self.structs_wall:setGLProgram(dawn_back)
    self.structs_room1:setGLProgram(dawn_back)
    self.structs_room2:setGLProgram(dawn_back)
    self.structs_room3:setGLProgram(dawn_back)
    for i = 1, MAX_MINIONS_NUM do
        if self.minions[i] ~= nil then
            if self.minions[i].sprite ~= nil then
                self.minions[i]:set_gl(dawn_char)
            end
        end
    end
    self.m_character:set_gl(dawn_char)
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
            self:struct_shader_night(i)
        end
    end
    for i = 1, MAX_MINIONS_NUM do
        if self.minions[i] ~= nil then
            if self.minions[i].sprite ~= nil then
                self.minions[i]:set_gl(night_char)
            end
        end
    end
    self.m_character:change_night_level_shader()
    for i, single_torch in pairs(self.torches) do
        if self.torches[i].sprite ~= nil then
            self.torches[i].sprite:stopAllActions()
            self.torches[i].sprite:playAnimationForever(display.getAnimationCache(torch_motion))
            self.torches[i].sprite:setGLProgram(night_char)
        end
    end
    local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back_roof")
    self.structs_roof:setGLProgram(night_back)
    local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back")
    self.structs_back:setGLProgram(night_back)
    local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back_wall")
    self.structs_wall:setGLProgram(night_back)
    local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back1")
    self.structs_room1:setGLProgram(night_back)
    local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back2")
    self.structs_room2:setGLProgram(night_back)
    local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back3")
    self.structs_room3:setGLProgram(night_back)
    local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_back)
    local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_char)
end

function SecondScene:turn_off_oven()
    self.interact_oven_flag = false
    self.oven_view:setVisible(false)
end

function SecondScene:turn_off_interact()
    self.interact_flag = false
    self.control:setTexture("control.png")
    self.interact_target_name:setVisible(false)
    self.left_inventory:setVisible(false)
end

function SecondScene:turn_off_chest()
    self.interact_chest_flag = false
    self.left_inventory:setVisible(false)
end

function SecondScene:inventory_press_call_back(inventory, row_index, col_index)
    if self.m_character.asleep == true then
        return
    end
    if inventory == self.m_character.inventory then
        local item = self.m_character.inventory[col_index + 1 + row_index * inventory_cols]
        if item == nil then
            return
        end
        if item.type == item_type.BREAD then
            self.m_character:consume_index(col_index + 1 + row_index * inventory_cols)
            self.m_character.inventory.weight = self.m_character.inventory.weight - item.type.weight
            self.right_inventory.table_view:reloadData()
            self.right_inventory.weight:setString(self.m_character.inventory.weight.." / "..self.m_character.inventory.weight_limit)
        else
            self.m_character:equip_right_hand(inventory[col_index + 1 + row_index * inventory_cols])
            self.right_inventory.table_view:reloadData()
        end
    end
end

function SecondScene:interaction_press_call_back(index)
    if self.m_character.asleep == true then
        return
    end
    if index == -1 then
        return
    end
    if index + 1 > #self.last_object_interactions then
        self.pause_flag = true
        self.pause:setVisible(true)
        self.interact_flag = true
        self:turn_off_chest()
        self:turn_off_oven()
        self.control:setTexture("interact.png")
        self.interact_target = self.last_character_interactions[index + 1 - #self.last_object_interactions]
        self.inventory_layer:setVisible(false)
        self.left_inventory:setVisible(true)
        self.interact_target_name:setString(self.minions[self.interact_target].name)
        self.interact_target_name:setVisible(true)
    else
        if self.last_object_interactions[index + 1].add_task == true then
            for i = 1, MAX_TASKS_NUM do
                if self.m_character_task[i] == nil then
                    self.m_character_task[i] = self.last_object_interactions[index + 1]
                    break
                end
            end
        elseif self.last_object_interactions[index + 1].call_back ~= nil then
            self.last_object_interactions[index + 1].call_back(self, self.last_object_interactions[index + 1].parameters)
        end
    end
end

function SecondScene:open_close_chest(parameters)
    local result = self.m_character:find_key(parameters.chest.key_sequence)
    if result == 0 then
        self.m_character:create_dialog(self, 2, "Key!")
        return
    elseif result == -1 then
        self.m_character:create_dialog(self, 2, "Key too hot!")
        return
    end
    if self.inventory_layer:isVisible() == false or self.left_inventory:isVisible() == false or self.chest_flag == false then
        self.pause_flag = true
        self.pause:setVisible(true)
        self.interact_chest_flag = true
        self:turn_off_interact()
        self:turn_off_oven()
        if self.chest_flag == false then
            self.left_inventory:removeFromParentAndCleanup(true)
            self.left_inventory = require("app.views.inventory_view").new(false, {}, 25, display.cy - inventory_rows_chest * 50 / 2, inventory_cols_chest, inventory_rows_chest, cc.size(inventory_cols_chest * 50, inventory_rows_chest * 50), cc.p(50, 50), kCCScrollViewDirectionVertical, kCCTableViewFillTopDown, self)
            :setAnchorPoint(cc.p(0, 0))
            :setPosition(cc.p(0, 0))
            :addTo(self.inventory_layer)
            self.chest_flag = true
        end
        self.left_inventory:setVisible(true)
        self.left_inventory.table_view.elements = parameters.chest.inventory
        self.left_inventory.table_view:reloadData()
        self.right_inventory.table_view:reloadData()
        self.left_inventory.name:setString("chest")
        self.right_inventory.weight:setString(self.m_character.inventory.weight.." / "..self.m_character.inventory.weight_limit)
        self.right_inventory.name:setString(self.m_character.name)
        self.inventory_layer:setVisible(true)
    else
        self.interact_chest_flag = false
        self.pause_flag = false
        self.pause:setVisible(false)
        self.inventory_layer:setVisible(false)
    end
end

function SecondScene:open_close_door(parameters)
    local result = self.m_character:find_key(parameters.door.key_sequence)
    if result == 0 then
        self.m_character:create_dialog(self, 2, "Key!")
        return
    elseif result == -1 then
        self.m_character:create_dialog(self, 2, "Key too hot!")
        return
    end
    if parameters.door.locked == false then
        parameters.door.locked = true
    else
        parameters.door.locked = false
    end
end

function SecondScene:m_sleep(parameters)
    if parameters.bed.in_use == false then
        self.sleep_purge = true
        self:turn_off_oven()
        self:turn_off_interact()
        self:turn_off_chest()
        self.inventory_layer:setVisible(false)
        self.pause_flag = false
        self.pause:setVisible(false)
        self.m_character:sleep(self, parameters.bed)
    else
        self.m_character:create_dialog(self, 2, "I don't want to share bed.")
    end
end

function SecondScene:pick_up(parameters)
    if self.m_character:add_item(self, parameters.item.item) == true then
        parameters.item:remove(self)
        self.right_inventory.table_view:reloadData()
        self.right_inventory.weight:setString(self.m_character.inventory.weight.." / "..self.m_character.inventory.weight_limit)
    else
        self.right_inventory.table_view:reloadData()
        self.right_inventory.weight:setString(self.m_character.inventory.weight.." / "..self.m_character.inventory.weight_limit)
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

function SecondScene:interact_oven(parameters)
    if self.oven_view:isVisible() == false then
        self.pause_flag = true
        self.pause:setVisible(true)
        self:turn_off_chest()
        self:turn_off_interact()
        self.interact_oven_flag = true
        self.inventory_layer:setVisible(true)
        self.oven_view.oven = parameters.oven
        self.oven_view.table_view_up.elements = self.oven_view.oven.up
        self.oven_view.table_view_down.elements = self.oven_view.oven.down
        self.oven_view:update_fire_interact()
        self.oven_view.table_view_up:reloadData()
        self.oven_view.table_view_down:reloadData()
        self.right_inventory.table_view:reloadData()
        self.oven_view:setVisible(true)
    else
        self:turn_off_oven()
        self.pause_flag = false
        self.pause:setVisible(false)
        self.inventory_layer:setVisible(false)
    end
end

function SecondScene:add_surroundings_block(target, i, j, local_dis, ii, jj, height_level)
    local can_spread = true
    local struct_index = self.map_build_index[i][j]
    if struct_index > 0 then
        local struct = self.structs[struct_index]
        local level = nil
        if height_level == 0 and struct.walls ~= nil then
            level = struct.walls
        end
        if height_level == 1 and struct.room1 ~= nil then
            level = struct.room1
        end
        if height_level == 2 and struct.room2 ~= nil then
            level = struct.room2
        end
        if height_level == 3 and struct.room3 ~= nil then
            level = struct.room3
        end
        if level == nil then
            return
        end
        local layer = level:layerNamed("collision")
        local struct_i = math.floor(i - 1 - struct.position.x / 50)
        local struct_j = math.floor(struct.map.y - j + struct.position.y / 50)
        if struct_i >= 0 and struct_i < struct.map.x and struct_j >= 0 and struct_j < struct.map.y then
            local gid = layer:tileGIDAt(cc.p(struct_i, struct_j))
            local property = level:propertiesForGID(gid)
            if height_level ~= 0 then
                if property ~= 0 and property ~= 4 and property ~= 6 and property ~= 5 and property ~= 7 then
                    can_spread = false
                end
            else
                if property ~= 0 and property ~= 4 and property ~= 6 and property ~= 5 then
                    can_spread = false
                end
            end
        end
    end
    if local_dis > event_spread_dis or (target.indices_array[ii][jj].value ~= 0 and local_dis >= target.indices_array[ii][jj].dis) or can_spread == false then
        return
    end
    if target.indices_array[ii][jj].value == 0 then
        self.map_emergent_events[i][j][1] = self.map_emergent_events[i][j][1] + 1
        self.map_emergent_events[i][j][self.map_emergent_events[i][j][1] + 1] = target
        target.indices_array[ii][jj].value = self.map_emergent_events[i][j][1] + 1
        target.indices_array[ii][jj].dis = local_dis
    else
        target.indices_array[ii][jj].dis = local_dis
    end
    self:add_surroundings_block(target, i + 1, j, local_dis + 1, ii + 1, jj, height_level)
    self:add_surroundings_block(target, i - 1, j, local_dis + 1, ii - 1, jj, height_level)
    self:add_surroundings_block(target, i, j + 1, local_dis + 1, ii, jj + 1, height_level)
    self:add_surroundings_block(target, i, j - 1, local_dis + 1, ii, jj - 1, height_level)
end

function SecondScene:add_surroundings_none_block(target, i, j, event_spread_dis)
    for ii = i - event_spread_dis, i + event_spread_dis do
        for jj = j - event_spread_dis, j + event_spread_dis do
            self.map_emergent_events[ii][jj][1] = self.map_emergent_events[ii][jj][1] + 1
            self.map_emergent_events[ii][jj][self.map_emergent_events[ii][jj][1] + 1] = target
            target.indices_array[ii - i + event_spread_dis + 1][jj - j + event_spread_dis + 1].value = self.map_emergent_events[ii][jj][1] + 1
        end
    end
end

function SecondScene:remove_surroundings(item, i, j, dis)
    for array_i = 1, 2 * dis + 1 do
        for array_j = 1, 2 * dis + 1 do
            local index = item.indices_array[array_i][array_j]
            if index.value ~= 0 then
                local item_i = array_i - dis - 1 + i
                local item_j = array_j - dis - 1 + j
                for ii = index.value, self.map_emergent_events[item_i][item_j][1] + 1 do
                    if ii == self.map_emergent_events[item_i][item_j][1] + 1 then
                        self.map_emergent_events[item_i][item_j][ii] = nil
                    else
                        self.map_emergent_events[item_i][item_j][ii] = self.map_emergent_events[item_i][item_j][ii + 1]
                        local temp_i = math.floor(self.map_emergent_events[item_i][item_j][ii].position.x / 50.0)
                        local temp_j = math.floor(self.map_emergent_events[item_i][item_j][ii].position.y / 50.0)
                        temp_i = math.floor(temp_i) + 1
                        temp_j = math.floor(temp_j) + 1
                        self.map_emergent_events[item_i][item_j][ii].indices_array[item_i- temp_i + dis + 1][item_j - temp_j + dis + 1].value = self.map_emergent_events[item_i][item_j][ii].indices_array[item_i- temp_i + dis + 1][item_j - temp_j + dis + 1].value - 1
                    end
                end
                self.map_emergent_events[item_i][item_j][1] = self.map_emergent_events[item_i][item_j][1] - 1
            end
        end
    end
end

function SecondScene:drop_new_item(new_item, position, height_level)
    local num = #self.dropped_items
    self.dropped_items[num + 1] = dropped_item:new()
    local i = math.floor(position.x / 50.0)
    local j = math.floor(position.y / 50.0)
    local random_pos = cc.p(math.random(i * 50 + 1, i * 50 + 49), math.random(j * 50 + 1, j * 50 + 49))
    self.dropped_items[num + 1]:init(self.c_node, self.m_character.position, new_item, random_pos, height_level, num + 1)
    i = math.floor(i) + 1
    j = math.floor(j) + 1
    self.map_dropped_items[i][j][1] = self.map_dropped_items[i][j][1] + 1
    self.map_dropped_items[i][j][self.map_dropped_items[i][j][1] + 1] = self.dropped_items[num + 1]
    self.dropped_items[num + 1].index = self.map_dropped_items[i][j][1] + 1
    self.dropped_items[num + 1].indices_array = {}
    for i = 1, event_spread_dis * 2 + 1 do
        self.dropped_items[num + 1].indices_array[i] = {}
        for j = 1, event_spread_dis * 2 + 1 do
            self.dropped_items[num + 1].indices_array[i][j] = {}
            self.dropped_items[num + 1].indices_array[i][j].value = 0
            self.dropped_items[num + 1].indices_array[i][j].dis = event_spread_dis
        end
    end
    self:add_surroundings_block(self.dropped_items[num + 1], i, j, 0, event_spread_dis + 1, event_spread_dis + 1, height_level)
end

function SecondScene:remove_dropped_item(item)
    local i = item.position.x / 50.0
    local j = item.position.y / 50.0
    i = math.floor(i) + 1
    j = math.floor(j) + 1
    local index = item.index
    local index2 = item.index2
    for ii = index, self.map_dropped_items[i][j][1] + 1 do
        if ii == self.map_dropped_items[i][j][1] + 1 then
            self.map_dropped_items[i][j][ii] = nil
        else
            self.map_dropped_items[i][j][ii] = self.map_dropped_items[i][j][ii + 1]
            self.map_dropped_items[i][j][ii].index = self.map_dropped_items[i][j][ii].index - 1
        end
    end
    self.map_dropped_items[i][j][1] = self.map_dropped_items[i][j][1] - 1
    self:remove_surroundings(item, i, j, event_spread_dis)
    for ii = index2, #self.dropped_items do
        if ii == #self.dropped_items then
            self.dropped_items[ii] = nil
        else
            self.dropped_items[ii] = self.dropped_items[ii + 1]
            self.dropped_items[ii].index2 = self.dropped_items[ii].index2 - 1
        end
    end
end

function SecondScene:drop_new_body(id, corpse_status, position, height_level)
    local num = #self.dead_bodies
    self.dead_bodies[num + 1] = dead_body:new()
    self.dead_bodies[num + 1]:init(self.c_node, self.m_character.position, id, corpse_status, position, height_level, num + 1, event_spread_dis)
    local i = math.floor(position.x / 50.0)
    local j = math.floor(position.y / 50.0)
    i = math.floor(i) + 1
    j = math.floor(j) + 1
    self:add_surroundings_block(self.dead_bodies[num + 1], i, j, 0, event_spread_dis + 1, event_spread_dis + 1, height_level)
end

function SecondScene:remove_dead_body(body)
    local i = math.floor(body.position.x / 50.0)
    local j = math.floor(body.position.y / 50.0)
    i = math.floor(i) + 1
    j = math.floor(j) + 1
    self:remove_surroundings(body, i, j, event_spread_dis)
    local index2 = body.index2
    for ii = index2, #self.dead_bodies do
        if ii == #self.dead_bodies then
            self.dead_bodies[ii] = nil
        else
            self.dead_bodies[ii] = self.dead_bodies[ii + 1]
            self.dead_bodies[ii].index2 = self.dead_bodies[ii].index2 - 1
        end
    end
end

function SecondScene:add_shouting(target, type)
    target.shouting = shouting:new()
    target.shouting:init(target.position, target.height_level, type, event_spread_dis)
    local i = math.floor(target.position.x / 50.0)
    local j = math.floor(target.position.y / 50.0)
    i = math.floor(i) + 1
    j = math.floor(j) + 1
    self:add_surroundings_none_block(target.shouting, i, j, event_spread_dis)
end

function SecondScene:remove_shouting(target)
    local i = math.floor(target.position.x / 50.0)
    local j = math.floor(target.position.y / 50.0)
    i = math.floor(i) + 1
    j = math.floor(j) + 1
    self:remove_surroundings(target.shouting, i, j, event_spread_dis)
    target.shouting = nil
end

function SecondScene:m_check_surroundings(dt)
    --release_print(self.time)
    local i = self.m_character.position.x / 50.0
    local j = self.m_character.position.y / 50.0
    i = math.floor(i) + 1
    j = math.floor(j) + 1
    local characters = {}
    for ii = i - 1, i + 1 do
        for jj = j - 1, j + 1 do
            if self.map_characters[ii][jj][1] ~= 0 then
                for index = 2, self.map_characters[ii][jj][1] + 1 do
                    if self.map_characters[ii][jj][index] ~= 0 and self.minions[self.map_characters[ii][jj][index]].height_level == self.m_character.height_level then
                        characters[#characters + 1] = self.map_characters[ii][jj][index]
                    end
                end
            end
        end
    end
    local objects = {}
    if self.map_emergent_events[i][j][1] ~= 0 then
        for ii = 2, self.map_emergent_events[i][j][1] + 1 do
            if self.map_emergent_events[i][j][ii].event_type == DEAD_BODY then
                if self.map_emergent_events[i][j][ii].height_level == self.m_character.height_level or self.map_emergent_events[i][j][ii].height_level == 0 then
                    --[[
                    local index = #objects + 1
                    objects[index] = {}
                    objects[index].item = "object/harvest.png"
                    objects[index].call_back = nil
                    objects[index].cancel = nil
                    objects[index].add_task = false
                    objects[index].parameters = nil
                    objects[index].stop_when_walking = false
                    --]]
                end
            elseif self.map_emergent_events[i][j][ii].event_type == DROPPED_ITEM then
                if self.map_emergent_events[i][j][ii].height_level == self.m_character.height_level or self.map_emergent_events[i][j][ii].height_level == 0 then
                    --[[
                    local index = #objects + 1
                    objects[index] = {}
                    objects[index].item = "object/pick_up.png"
                    objects[index].call_back = nil
                    objects[index].cancel = nil
                    objects[index].add_task = false
                    objects[index].parameters = nil
                    objects[index].stop_when_walking = false
                    --]]
                end
            elseif self.map_emergent_events[i][j][ii].event_type == HELP then
            elseif self.map_emergent_events[i][j][ii].event_type == TRADE then
            end
        end
    end
    local build_index = self.map_build_index[i][j]
    if build_index ~= 0 then
        local temp_i = math.floor((self.m_character.position.x - self.structs[build_index].position.x) / self.structs[build_index].tile.x)
        local temp_j = self.structs[build_index].map.y - 1 - math.floor((self.m_character.position.y - self.structs[build_index].position.y) / self.structs[build_index].tile.y)
        if self.structs[build_index].functionality == functionality.FARM then
            if self.m_character.height_level == 0 then
                if self.structs[build_index].plants:check_plant(temp_i, temp_j, nil) == true then
                    local index = #objects + 1
                    objects[index] = {}
                    objects[index].item = "object/harvest.png"
                    objects[index].call_back = self.harvest
                    objects[index].cancel = self.harvest_cancel
                    objects[index].add_task = true
                    objects[index].parameters = {build_index = build_index, i = temp_i, j = temp_j}
                    objects[index].stop_when_walking = true
                end
            end
        end
        local function check_chest(i, j)
            if self.structs[build_index]:check_chest(self.m_character.height_level, i, j) == true then
                local index = #objects + 1
                objects[index] = {}
                objects[index].item = "object/open_chest.png"
                objects[index].call_back = self.open_close_chest
                objects[index].cancel = nil
                objects[index].add_task = false
                objects[index].parameters = {chest = self.structs[build_index].chests[self.m_character.height_level][i][j]}
                objects[index].stop_when_walking = false
            end
        end
        check_chest(temp_i - 1, temp_j)
        check_chest(temp_i + 1, temp_j)
        check_chest(temp_i, temp_j - 1)
        check_chest(temp_i, temp_j + 1)
        if self.structs[build_index].doors[self.m_character.height_level] ~= nil then
            if self.structs[build_index].doors[self.m_character.height_level][temp_i][temp_j - 1] ~= nil then
                local index = #objects + 1
                objects[index] = {}
                objects[index].item = "object/lock.png"
                objects[index].call_back = self.open_close_door
                objects[index].cancel = nil
                objects[index].add_task = false
                objects[index].parameters = {door = self.structs[build_index].doors[self.m_character.height_level][temp_i][temp_j - 1]}
                objects[index].stop_when_walking = false
            end
            if self.structs[build_index].doors[self.m_character.height_level][temp_i][temp_j + 1] ~= nil then
                local index = #objects + 1
                objects[index] = {}
                objects[index].item = "object/lock.png"
                objects[index].call_back = self.open_close_door
                objects[index].cancel = nil
                objects[index].add_task = false
                objects[index].parameters = {door = self.structs[build_index].doors[self.m_character.height_level][temp_i][temp_j + 1]}
                objects[index].stop_when_walking = false
            end
        end
        if self.structs[build_index].beds[self.m_character.height_level] ~= nil then
            if self.structs[build_index].beds[self.m_character.height_level][temp_i][temp_j] ~= nil then
                local index = #objects + 1
                objects[index] = {}
                objects[index].item = "object/sleep.png"
                objects[index].call_back = self.m_sleep
                objects[index].cancel = nil
                objects[index].add_task = false
                objects[index].parameters = {bed = self.structs[build_index].beds[self.m_character.height_level][temp_i][temp_j]}
                objects[index].stop_when_walking = false
            end
        end
        if self.structs[build_index].ovens[self.m_character.height_level] ~= nil then
            local function check_oven(i, j)
                if self.structs[build_index].ovens[self.m_character.height_level][i][j] ~= nil then
                    local index = #objects + 1
                    objects[index] = {}
                    objects[index].item = "object/oven.png"
                    objects[index].call_back = self.interact_oven
                    objects[index].cancel = nil
                    objects[index].add_task = false
                    objects[index].parameters = {oven = self.structs[build_index].ovens[self.m_character.height_level][i][j]}
                    objects[index].stop_when_walking = false
                end
            end
            check_oven(temp_i + 1, temp_j)
            check_oven(temp_i + 1, temp_j + 1)
            check_oven(temp_i, temp_j + 2)
            check_oven(temp_i - 1, temp_j + 2)
            check_oven(temp_i, temp_j - 1)
            check_oven(temp_i - 1, temp_j - 1)
            check_oven(temp_i - 2, temp_j)
            check_oven(temp_i - 2, temp_j + 1)
        end
    end
    local check_dropped_item = function(i, j)
        if self.map_dropped_items[i][j][1] ~= 0 then
            for ii = 2, self.map_dropped_items[i][j][1] + 1 do
                local dis = (self.map_dropped_items[i][j][ii].position.x - self.m_character.position.x) * (self.map_dropped_items[i][j][ii].position.x - self.m_character.position.x) + (self.map_dropped_items[i][j][ii].position.y - self.m_character.position.y) * (self.map_dropped_items[i][j][ii].position.y - self.m_character.position.y)
                if self.map_dropped_items[i][j][ii].height_level == self.m_character.height_level and dis <= 50 * 50 then
                    local index = #objects + 1
                    objects[index] = {}
                    objects[index].back = "object/pick_up.png"
                    objects[index].item = self.map_dropped_items[i][j][ii].item.type.icon
                    objects[index].call_back = self.pick_up
                    objects[index].cancel = nil
                    objects[index].add_task = false
                    objects[index].parameters = {item = self.map_dropped_items[i][j][ii]}
                    objects[index].stop_when_walking = false
                end
            end
        end
    end
    local i = self.m_character.position.x / 50.0
    local j = self.m_character.position.y / 50.0
    i = math.floor(i) + 1
    j = math.floor(j) + 1
    check_dropped_item(i, j)
    check_dropped_item(i + 1, j)
    check_dropped_item(i - 1, j)
    check_dropped_item(i, j + 1)
    check_dropped_item(i, j - 1)
    check_dropped_item(i + 1, j + 1)
    check_dropped_item(i + 1, j - 1)
    check_dropped_item(i - 1, j + 1)
    check_dropped_item(i - 1, j - 1)
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
        self.last_object_interactions = {}
        for ii, object in pairs(objects) do
            self.last_interactions[ii] = {}
            if object.back == nil then
                self.last_interactions[ii].back = "object/object_interaction.png"
            else
                self.last_interactions[ii].back = object.back
            end
            self.last_interactions[ii].item = object.item
            self.last_interactions[ii].label = nil
            self.last_object_interactions[ii] = object
        end
        self.last_character_interactions = {}
        for ii, character in pairs(characters) do
            self.last_interactions[ii + #self.last_object_interactions] = {}
            self.last_interactions[ii + #self.last_object_interactions].back = "object/character_interaction.png"
            self.last_interactions[ii + #self.last_object_interactions].item = nil
            self.last_interactions[ii + #self.last_object_interactions].label = self.minions[character].name
            self.last_character_interactions[ii] = character
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
        if self.interactions.table_view:getPositionX() < self.interactions_position_x - 3 * interaction_pop_speed * dt * fixedDeltaTimeScale then
            self.interactions.table_view:move(self.interactions.table_view:getPositionX() + 3 * interaction_pop_speed * dt * fixedDeltaTimeScale, 0)
        else
            self.interactions.table_view:move(self.interactions_position_x, 0)
        end
    elseif self.interactions.table_view:getPositionX() > self.interactions_position_x then
        if self.interactions.table_view:getPositionX() > self.interactions_position_x + interaction_pop_speed * dt * fixedDeltaTimeScale then
            self.interactions.table_view:move(self.interactions.table_view:getPositionX() - interaction_pop_speed * dt * fixedDeltaTimeScale, 0)
        else
            self.interactions.table_view:move(self.interactions_position_x, 0)
        end
    end
end

function SecondScene:step(dt)
    self.dt = dt
    for i, item in pairs(self.dropped_items) do
        item:update_counter(dt)
    end
    if self.m_character.ishungry == true then
        self.hunger:setOpacity(self.hunger_opa_counter * 255 / OPACITY_COUNT)
    else
        self.hunger:setOpacity(0)
        self.hunger_opa_counter = 0.0
    end
    if self.m_character.issleepy == true then
        self.sleepiness:setOpacity(self.sleepiness_opa_counter * 255 / OPACITY_COUNT)
    else
        self.sleepiness:setOpacity(0)
        self.sleepiness_opa_counter = 0.0
    end
    if self.hunger_opa_counter_up == true then
        self.hunger_opa_counter = self.hunger_opa_counter + dt
        if self.hunger_opa_counter >= OPACITY_COUNT then
            self.hunger_opa_counter = OPACITY_COUNT
            self.hunger_opa_counter_up = false
        end
    else
        self.hunger_opa_counter = self.hunger_opa_counter - dt
        if self.hunger_opa_counter <= 0.0 then
            self.hunger_opa_counter = 0.0
            self.hunger_opa_counter_up = true
        end
    end
    if self.sleepiness_opa_counter_up == true then
        self.sleepiness_opa_counter = self.sleepiness_opa_counter + dt
        if self.sleepiness_opa_counter >= OPACITY_COUNT then
            self.sleepiness_opa_counter = OPACITY_COUNT
            self.sleepiness_opa_counter_up = false
        end
    else
        self.sleepiness_opa_counter = self.sleepiness_opa_counter - dt
        if self.sleepiness_opa_counter <= 0.0 then
            self.sleepiness_opa_counter = 0.0
            self.sleepiness_opa_counter_up = true
        end
    end

    self:m_check_surroundings(dt)

    self.m_character:update_dialog(self, dt)
    for i = 1, MAX_MINIONS_NUM do
        if self.minions[i] ~= nil then
            self.minions[i]:update_dialog(self, dt)
        end
    end
    if self.inventory_selected ~= nil and self.inventory_block_selected ~= nil then
        if self.drag_item == nil then
            local local_inventory_cols = self.inventory_selected_size.x
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
                    self.drag_item.item = shallowcopy(self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols])
                    self.drag_item.item.num = math.floor(self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num / 2)
                    self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num = self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num - self.drag_item.item.num
                elseif self.drag_num == ONE then
                    self.drag_item.item = shallowcopy(self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols])
                    self.drag_item.item.num = 1
                    self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num = self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * local_inventory_cols].num - self.drag_item.item.num
                end
                self.inventory_selected.weight = self.inventory_selected.weight - self.drag_item.item.type.weight * self.drag_item.item.num
                if self.drag_item.item.type.stack_limit ~= 1 then
                    local num = cc.Label:createWithTTF(tostring(self.drag_item.item.num), font.GREEK_FONT, 20)
                    num:setAnchorPoint(cc.p(0, 0))
                    num:setPosition(cc.p(5, 0))
                    self.drag_item:addChild(num)
                end
                if self.drag_item.item.heat_level ~= nil then
                    self.cool_down:add_item(self.drag_item.item)
                end
                if self.left_inventory:isVisible() == true then
                    self.left_inventory.table_view:reloadData()
                    if self.chest_flag == false then
                        self.left_inventory.weight:setString(self.left_inventory.table_view.elements.weight.." / "..self.left_inventory.table_view.elements.weight_limit)
                    end
                end
                if self.interact_oven_flag == true then
                    self.oven_view.table_view_up:reloadData()
                    self.oven_view.table_view_down:reloadData()
                end
                self.right_inventory.table_view:reloadData()
                self.right_inventory.weight:setString(self.m_character.inventory.weight.." / "..self.m_character.inventory.weight_limit)
            end
        end
    end
    if self.pause_flag == true then
        self.pause:setVisible(true)
        return
    end

    repeat

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
        self.day_num = self.day_num + 1
    end
    if self.light_status == NIGHT and self.m_character.asleep == false then
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
                lights[lights_num] = cc.p(math.floor((self.torches[i].position.x - self.m_character.position.x) * (self.screen_ratio.x - MAGIC_NUMBER + 1) + display.cx * self.screen_ratio.x), math.floor((self.torches[i].position.y - self.m_character.position.y + 50) * self.screen_ratio.y + display.cy * self.screen_ratio.y))
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

        local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back_wall")
        local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_back)
        gl_state:setUniformFloat("radius", self.light_radius * self.screen_ratio.x * 0.85)
        gl_state:setUniformInt("lights_num", lights_num)
        for i, single_light in pairs(lights) do
            single_light.y = single_light.y - 15.0
            gl_state:setUniformVec2("light"..(i-1), single_light)
        end

        local function set_floor_lights(structs, height_level)
            local night_back = cc.GLProgramCache:getInstance():getGLProgram("night_back"..height_level)
            local night_char = cc.GLProgramCache:getInstance():getGLProgram("night_char"..height_level)
            local lights = {}
            local lights_num = 0
            for index, struct in pairs(structs) do
                local ovens = struct:get_ovens(height_level)
                if #ovens ~= 0 then
                    for oven_index, oven in pairs(ovens) do
                        if struct.ovens[height_level][oven.x][oven.y].fire_on == true then
                            lights_num = lights_num + 1
                            local position_x = struct.position.x + oven.x * struct.tile.x + struct.tile.x
                            local position_y = struct.position.y + (struct.map.y - oven.y - 1) * struct.tile.y + struct.tile.y
                            lights[lights_num] = cc.p(math.floor((position_x - self.m_character.position.x) * (self.screen_ratio.x - MAGIC_NUMBER + 1) + display.cx * self.screen_ratio.x), math.floor((position_y - self.m_character.position.y) * self.screen_ratio.y + display.cy * self.screen_ratio.y))
                        end
                    end
                end
            end
            local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_back)
            gl_state:setUniformFloat("radius", self.light_radius * self.screen_ratio.x / oven_light_radius_ratio)
            gl_state:setUniformInt("lights_num", lights_num)
            for i, single_light in pairs(lights) do
                gl_state:setUniformVec2("light"..(i-1), single_light)
            end
            local gl_state = cc.GLProgramState:getOrCreateWithGLProgram(night_char)
            gl_state:setUniformFloat("radius", self.light_radius * self.screen_ratio.x / oven_light_radius_ratio)
            gl_state:setUniformInt("lights_num", lights_num)
            for i, single_light in pairs(lights) do
                gl_state:setUniformVec2("light"..(i-1), single_light)
            end
        end
        local i = self.m_character.position.x / 50.0
        local j = self.m_character.position.y / 50.0
        i = math.floor(i) + 1
        j = math.floor(j) + 1
        if self.m_character.height_level ~= 0 then
            set_floor_lights({self.structs[self.map_build_index[i][j]]}, self.m_character.height_level)
        end
    end

    for i, struct in pairs(self.structs) do
        if struct.functionality == functionality.FARM then
            self.structs[i].plants:plants_grow(self.structs, i, dt)
        end
    end

    if self.m_character.chain_target ~= nil then
        if self.m_character.rope_node == nil then
            self.m_character.rope_node = cc.DrawNode:create()
            self.m_character.rope_node:addTo(self, 2)
            self.m_character.rope_body_node = cc.DrawNode:create()
            self.m_character.rope_body_node:addTo(self.c_node)
        end
        drag(self.m_character.position, self.m_character, self.m_character.chain_target, self.structs, self.map_build_index, 100, 2.0 * dt * fixedDeltaTimeScale)
        self.map_move_flag = STOP
    end
    if self.m_character.asleep == false then
        local function update_position(self, x, y)
            local leave_enter, struct_index = self.m_character:change_position_m(x, y, self.structs, self.map_build_index, self)
            if leave_enter == 0 then
                self.structs[struct_index]:leave_and_enter(self.m_character.height_level)
            end
            if leave_enter == 1 then
                self.structs[struct_index]:enter(self.m_character.height_level)
            end
        end

        if self.map_move_flag == RIGHT then
            update_position(self, self.m_character.speed * dt * fixedDeltaTimeScale, 0.0)
            if self.m_character.last_act ~= RIGHT then
                self.m_character.sprite:stopAllActions()
                --self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[RIGHT]))
                self.m_character.last_act = RIGHT
                self.m_character.last_frame_index = 0
            end
        end
        if self.map_move_flag == LEFT then
            update_position(self, 0.0 - self.m_character.speed * dt * fixedDeltaTimeScale, 0.0)
            if self.m_character.last_act ~= LEFT then
                self.m_character.sprite:stopAllActions()
                --self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[LEFT]))
                self.m_character.last_act = LEFT
                self.m_character.last_frame_index = 0
            end
        end
        if self.map_move_flag == UP then
            update_position(self, 0.0, self.m_character.speed * dt * fixedDeltaTimeScale)
            if self.m_character.last_act ~= UP then
                self.m_character.sprite:stopAllActions()
                --self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[UP]))
                self.m_character.last_act = UP
                self.m_character.last_frame_index = 0
            end
        end
        if self.map_move_flag == DOWN then
            update_position(self, 0.0, 0.0 - self.m_character.speed * dt * fixedDeltaTimeScale)
            if self.m_character.last_act ~= DOWN then
                self.m_character.sprite:stopAllActions()
                --self.m_character.sprite:playAnimationForever(display.getAnimationCache(minion_motions[DOWN]))
                self.m_character.last_act = DOWN
                self.m_character.last_frame_index = 0
            end
        end
        if self.map_move_flag ~= STOP then
            self.m_character:update_frame(self.map_move_flag, dt, self.sleep_purge)
        else
            self.m_character:reset_frame(self.sleep_purge, dt)
        end
        self.map:move(display.cx - self.m_character.position.x, display.cy - self.m_character.position.y)
        if self.map_move_flag ~= STOP then
            for i = 1, MAX_TASKS_NUM do
                if self.m_character_task[i] ~= nil and self.m_character_task[i].cancel ~= nil and self.m_character_task[i].stop_when_walking == true then
                    self.m_character_task[i].cancel(self, self.m_character_task[i].parameters)
                    self.m_character_task[i] = nil
                end
            end
        end
    end

    self.m_character:bio_tik(dt)
    self.m_character:check_damage(self, self.minions, 0, dt, self.time, self.day_num)

    for i, item in pairs(self.dropped_items) do
        item:update_position(self.c_node, self.m_character.position, self.m_character.height_level)
        if item.sprite ~= nil then
            if self.light_status == DAY then
                local day_char = cc.GLProgramCache:getInstance():getGLProgram("day_char")
                item.sprite:setGLProgram(day_char)
            end
            if self.light_status == TWILIGHT or self.light_status == DAWN then
                local dawn_char = cc.GLProgramCache:getInstance():getGLProgram("dawn_char")
                item.sprite:setGLProgram(dawn_char)
            end
            if self.light_status == NIGHT then
                item:change_night_level_shader()
            end
        end
    end

    for i, body in pairs(self.dead_bodies) do
        body:update_position(self.c_node, self.m_character.position, self.m_character.height_level)
        if body.sprite ~= nil then
            if self.light_status == DAY then
                local day_char = cc.GLProgramCache:getInstance():getGLProgram("day_char")
                body.sprite:setGLProgram(day_char)
            end
            if self.light_status == TWILIGHT or self.light_status == DAWN then
                local dawn_char = cc.GLProgramCache:getInstance():getGLProgram("dawn_char")
                body.sprite:setGLProgram(dawn_char)
            end
            if self.light_status == NIGHT then
                body:change_night_level_shader()
            end
        end
    end

    for i = 1, MAX_TASKS_NUM do
        if self.m_character_task[i] ~= nil and self.m_character_task[i].call_back ~= nil then
            local result, item = self.m_character_task[i].call_back(self, self.m_character_task[i].parameters)
            if result == success then
                if self.m_character:add_item(self, item) == false then
                    self:drop_new_item(item, self.m_character.position, self.m_character.height_level)
                end
                self.m_character_task[i] = nil
                self.right_inventory.table_view:reloadData()
            end
        end
    end

    for i = 1, MAX_MINIONS_NUM do
        if self.minions[i] ~= nil then
            self.minions[i].logic:think_about_life(self, self.m_character, self.minions, self.structs, self.light_status, self.map_build_index, i, dt)
            if self.sleep_purge == false then
                self:update_minion(i, dt)
            end
            self:detect_minion(i)
            self.minions[i]:bio_tik(dt)
            self.minions[i]:check_damage(self, self.minions, i, dt, self.time, self.day_num)
        end
    end

    for i, struct in pairs(self.structs) do
        self.structs[i]:update_ovens(self, dt)
    end

    self.cool_down:update(dt)

    until(self.m_character.asleep == false)


    if self.m_character.asleep == false and self.sleep_purge == true then
        self.sleep_purge = false
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
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
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

function SecondScene:create_bakery(i, name, loc_x, loc_y, sequence, allowed_id, allowed_minion_indices)
    self.structs[i] = struct:new()
    self.structs[i].position = cc.p(loc_x + self.width / 2, loc_y + self.height / 2)
    self.structs[i].name = name
    self.allowed_id = allowed_id
    self.allowed_minion_indices = allowed_minion_indices
    self.structs[i].functionality = functionality.LB
    self.structs[i].in_vision = true
    local x, y = self.structs_roof:getPosition()
    self.structs[i].roofs = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_roofs.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_roof)
    self.structs[i].roofs_shadow = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_roofs.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x - self.shadow_offset.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y - self.shadow_offset.y)
    :addTo(self.structs_roof_shadow)
    :setVisible(false)
    self.structs[i].walls = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_walls.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_wall)
    self.structs[i].walls_shadow = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_walls.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x - self.shadow_offset.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y - self.shadow_offset.y)
    :addTo(self.structs_wall_shadow)
    :setVisible(false)
    local layer = self.structs[i].walls:layerNamed("collision")
    layer:setVisible(false)
    local layer = self.structs[i].walls_shadow:layerNamed("collision")
    layer:setVisible(false)
    local layer = self.structs[i].roofs_shadow:layerNamed("deco")
    layer:setVisible(false)
    self.structs[i].room1 = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_room1.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_room1)
    local layer = self.structs[i].room1:layerNamed("collision")
    layer:setVisible(false)
    self.structs[i].room1:setVisible(false)
    self.structs[i].room2 = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_room2.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_room2)
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
    self.structs[i]:init_chests(nil)
    self.structs[i]:init_doors(sequence, false)
    self.structs[i]:init_beds()
    self.structs[i]:init_ovens()
    --[[
    for ii = 1, inventory_rows_chest * inventory_cols_chest - 1 do
        self.structs[i].chests[1][2][4].inventory[ii] = {}
        self.structs[i].chests[1][2][4].inventory[ii].type = item_type.CROP
        self.structs[i].chests[1][2][4].inventory[ii].num = item_type.CROP.stack_limit
    end
    self.structs[i].chests[1][2][4].inventory[inventory_rows_chest * inventory_cols_chest] = {}
    self.structs[i].chests[1][2][4].inventory[inventory_rows_chest * inventory_cols_chest].type = item_type.CROP
    self.structs[i].chests[1][2][4].inventory[inventory_rows_chest * inventory_cols_chest].num = item_type.CROP.stack_limit - 2
    for ii = 1, inventory_rows_chest * inventory_cols_chest - 1 do
        self.structs[i].chests[1][6][4].inventory[ii] = {}
        self.structs[i].chests[1][6][4].inventory[ii].type = item_type.CROP
        self.structs[i].chests[1][6][4].inventory[ii].num = item_type.CROP.stack_limit
    end
    self.structs[i].chests[1][6][4].inventory[inventory_rows_chest * inventory_cols_chest] = {}
    self.structs[i].chests[1][6][4].inventory[inventory_rows_chest * inventory_cols_chest].type = item_type.CROP
    self.structs[i].chests[1][6][4].inventory[inventory_rows_chest * inventory_cols_chest].num = item_type.CROP.stack_limit - 2
    ]]
end


function SecondScene:create_guard_station(i, name, loc_x, loc_y, sequence, allowed_id, allowed_minion_indices)
    self.structs[i] = struct:new()
    self.structs[i].position = cc.p(loc_x + self.width / 2, loc_y + self.height / 2)
    self.structs[i].name = name
    self.allowed_id = allowed_id
    self.allowed_minion_indices = allowed_minion_indices
    self.structs[i].functionality = functionality.LB
    self.structs[i].in_vision = true
    local x, y = self.structs_roof:getPosition()
    self.structs[i].roofs = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_roofs.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_roof)
    self.structs[i].roofs_shadow = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_roofs.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x - self.shadow_offset.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y - self.shadow_offset.y)
    :addTo(self.structs_roof_shadow)
    :setVisible(false)
    self.structs[i].walls = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_walls.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_wall)
    self.structs[i].walls_shadow = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_walls.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x - self.shadow_offset.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y - self.shadow_offset.y)
    :addTo(self.structs_wall_shadow)
    :setVisible(false)
    local layer = self.structs[i].walls:layerNamed("collision")
    layer:setVisible(false)
    local layer = self.structs[i].walls_shadow:layerNamed("collision")
    layer:setVisible(false)
    local layer = self.structs[i].roofs_shadow:layerNamed("deco")
    layer:setVisible(false)
    self.structs[i].room1 = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_room1.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_room1)
    local layer = self.structs[i].room1:layerNamed("collision")
    layer:setVisible(false)
    self.structs[i].room1:setVisible(false)
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
    self.structs[i]:init_doors(sequence, false)
end

function SecondScene:create_slave_lb(i, lb_name, loc_x, loc_y, allowed_id, allowed_minion_indices)
    self.structs[i] = struct:new()
    self.structs[i].position = cc.p(loc_x + self.width / 2, loc_y + self.height / 2)
    self.structs[i].name = lb_name
    self.allowed_id = allowed_id
    self.allowed_minion_indices = allowed_minion_indices
    self.structs[i].functionality = functionality.SLAVE_LB
    self.structs[i].in_vision = true
    local x, y = self.structs_roof:getPosition()
    self.structs[i].roofs = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_roofs.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_roof)
    self.structs[i].roofs_shadow = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_roofs.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x - self.shadow_offset.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y - self.shadow_offset.y)
    :addTo(self.structs_roof_shadow)
    :setVisible(false)
    self.structs[i].walls = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_walls.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_wall)
    self.structs[i].walls_shadow = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_walls.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x - self.shadow_offset.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y - self.shadow_offset.y)
    :addTo(self.structs_wall_shadow)
    :setVisible(false)
    local layer = self.structs[i].walls:layerNamed("collision")
    layer:setVisible(false)
    local layer = self.structs[i].walls_shadow:layerNamed("collision")
    layer:setVisible(false)
    self.structs[i].room1 = cc.TMXTiledMap:create("background/"..self.structs[i].name.."_room1.tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_room1)
    local layer = self.structs[i].room1:layerNamed("collision")
    layer:setVisible(false)
    self.structs[i].room1:setVisible(false)
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
    self.structs[i]:init_beds()
end

function SecondScene:create_farm(i, farm_name, loc_x, loc_y, allowed_id, allowed_minion_indices)
    self.structs[i] = struct:new()
    self.structs[i].position = cc.p(loc_x + self.width / 2, loc_y + self.height / 2)
    self.structs[i].name = farm_name
    self.allowed_id = allowed_id
    self.allowed_minion_indices = allowed_minion_indices
    self.structs[i].functionality = functionality.FARM
    self.structs[i].in_vision = true
    local x, y = self.structs_back:getPosition()
    self.structs[i].walls = cc.TMXTiledMap:create("background/"..self.structs[i].name..".tmx")
    :move(x + self.structs[i].position.x - display.cx - self.width / 2 - self.m_init_pos.x, y - display.cy + self.structs[i].position.y - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_back)
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
    self.structs[i].plants:init_plants(self.structs[i], self.structs_back, self.width, self.height)
end

function SecondScene:check_drag(touch)
    local x, y = touch:getLocation().x, touch:getLocation().y
    if self.inventory_layer:isVisible() == true then
        if self.left_inventory:isVisible() == true then
            local left = self.left_inventory.table_view:getPositionX()
            local right = self.left_inventory.table_view:getPositionX() + self.left_inventory.table_view:getContentSize().width
            local bottom = self.left_inventory.table_view:getPositionY()
            local top = self.left_inventory.table_view:getPositionY() + self.left_inventory.table_view:getContentSize().height
            if x >= left and x < right and y >= bottom and y < top and self.inventory_block_selected == nil and self.inventory_selected == nil then
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
                if self.left_inventory.table_view.elements[i + j * local_inventory_cols].equipped == nil then
                    self.inventory_block_selected = cc.p(i, j)
                    self.inventory_selected_size = cc.p(local_inventory_cols, local_inventory_rows)
                    self.inventory_selected = self.left_inventory.table_view.elements
                    self.inventory_init_pos = touch:getLocation()
                    self.hold_time = 0.0
                    if self.drag_item ~= nil then
                        self.drag_item:removeFromParentAndCleanup(true)
                        self.drag_item = nil
                    end
                end
            end
        elseif self.interact_oven_flag == true then
            self.oven_view:check_drag(self, touch)
        end
        local left = self.right_inventory.table_view:getPositionX()
        local right = self.right_inventory.table_view:getPositionX() + self.right_inventory.table_view:getContentSize().width
        local bottom = self.right_inventory.table_view:getPositionY()
        local top = self.right_inventory.table_view:getPositionY() + self.right_inventory.table_view:getContentSize().height
        if x >= left and x < right and y >= bottom and y < top and self.inventory_block_selected == nil and self.inventory_selected == nil then
            local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
            local j = inventory_rows - (math.floor((touch:getLocation().y - bottom) / 50.0) + 1)
            if self.right_inventory.table_view.elements[i + j * inventory_cols].equipped == nil then
                self.inventory_block_selected = cc.p(i, j)
                self.inventory_selected_size = cc.p(inventory_cols, inventory_rows)
                self.inventory_selected = self.m_character.inventory
                self.inventory_init_pos = touch:getLocation()
                self.hold_time = 0.0
                if self.drag_item ~= nil then
                    self.drag_item:removeFromParentAndCleanup(true)
                    self.drag_item = nil
                end
            end
        end
    end
end

function SecondScene:onCreate()
    self.sleep_purge = false
    self.start_position = nil
    self.end_position = nil
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
    self.day_num = 1
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
    --self.map_area_index = {}
    self.map_characters = {}
    self.touch_layer = {}
    self.dropped_items = {}
    self.map_dropped_items = {}
    self.dead_bodies = {}
    self.map_emergent_events = {}
    self.pause = nil
    self.resources = {}
    self.resources_50 = {}
    self.structs_roof = {}
    self.structs_back = {}
    self.structs_wall = {}
    self.structs_room1 = {}
    self.structs_room2 = {}
    self.structs_room3 = {}
    self.structs = {}
    self.shadow_offset = cc.p(0.0, 0.0)
    self.c_node = {}
    self.last_character_interactions = {}
    self.last_object_interactions = {}
    self.last_interactions = {}
    self.pause_flag = false
    self.interact_flag = false
    self.interact_chest_flag = false
    self.interact_oven_flag = false
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
    self.hunger_opa_counter = 0.0
    self.hunger_opa_counter_up = true
    self.sleepiness_opa_counter = 0.0
    self.sleepiness_opa_counter_up = true
    self.clicked_times = 0
    self.cool_down = cool_down
    self.m_init_pos = cc.p(-200.0, -50.0)
    item_type:char_init()
    local exitButton = cc.MenuItemImage:create("exit.png", "exit.png")
    :onClicked(function()
        if self.m_character.asleep == true then
            return
        end
        self:getApp():enterScene("MainScene")
    end)
    cc.Menu:create(exitButton)
    :move(display.left + 75/2, display.top - 75/2)
    :addTo(self, 100)

    local left_button = cc.MenuItemImage:create("left.png", "left.png")
    cc.Menu:create(left_button)
    :move(display.right - 75 - 75 / 2, display.bottom + 75 / 2)
    :addTo(self, 89)

    local right_button = cc.MenuItemImage:create("right.png", "right.png")
    cc.Menu:create(right_button)
    :move(display.right - 75 / 2, display.bottom + 75 / 2)
    :addTo(self, 89)

    local inventory = cc.MenuItemImage:create("inventory.png", "inventory.png")
    :onClicked(function()
        if self.m_character.asleep == true then
            return
        end
        if self.interact_flag == true or self.interact_chest_flag == true or self.interact_oven_flag == true then
        else
            if self.inventory_layer:isVisible() == false then
                self.pause_flag = true
                self.pause:setVisible(true)
                self.left_inventory:setVisible(false)
                self.right_inventory.table_view:reloadData()
                self.inventory_layer:setVisible(true)
            else
                self.pause_flag = false
                self.pause:setVisible(false)
                self.left_inventory:setVisible(false)
                self.inventory_layer:setVisible(false)
            end
        end
    end)
    cc.Menu:create(inventory)
    :move(display.right - 25 - 75, display.top - 75/2)
    :addTo(self, 100)

    local notes = cc.MenuItemImage:create("notes.png", "notes.png")
    :onClicked(function()
        --TODO
    end)
    cc.Menu:create(notes)
    :move(display.right - 75/2, display.top - 75/2)
    :addTo(self, 100)

    self.hunger = display.newSprite("hunger.png")
    :setOpacity(0)
    :setAnchorPoint(0.0, 0.0)
    :move(display.left, display.top - 75*2)
    :addTo(self, 100)

    self.sleepiness = display.newSprite("sleepiness.png")
    :setOpacity(0)
    :setAnchorPoint(0.0, 0.0)
    :move(display.left, display.top - 75*3)
    :addTo(self, 100)

    self.pause = cc.Label:createWithTTF("PAUSE", font.GREEK_FONT, 50)
    :move(display.cx, display.top - 50)
    :setTextColor(font.YELLOW)
    :addTo(self, 100)
    :setVisible(false)
    self.c_node = display.newNode()
    :move(0, 0)
    :addTo(self, 4)

    self.f_width = 50
    self.f_height = 50
    self.width = MAP_X * self.f_width
    self.height = MAP_Y * self.f_height

    self:init_oven_flame_frame()

    self.structs_back = display.newSprite()
    :move(display.cx, display.cy)
    :addTo(self, 1)
    self.structs_wall = display.newSprite()
    :move(display.cx, display.cy)
    :addTo(self, 1)
    self.structs_room1 = display.newSprite()
    :move(display.cx, display.cy)
    :addTo(self, 1)
    self.structs_room2 = display.newSprite()
    :move(display.cx, display.cy)
    :addTo(self, 1)
    self.structs_room3 = display.newSprite()
    :move(display.cx, display.cy)
    :addTo(self, 1)
    self.structs_wall_shadow = display.newSprite()
    :move(display.cx, display.cy)
    :addTo(self, 50)
    self.structs_roof_shadow = display.newSprite()
    :move(display.cx, display.cy)
    :addTo(self, 50)
    self.structs_roof = display.newSprite()
    :move(display.cx, display.cy)
    :addTo(self, 50)
    self.map = cc.TMXTiledMap:create("background/background.tmx")
    :move(display.cx - self.width / 2 - self.m_init_pos.x, display.cy - self.height / 2 - self.m_init_pos.y)
    :addTo(self.structs_back)

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
    for i = 1, MAP_X do
        self.map_dropped_items[i] = {}
        for j = 1, MAP_Y do
            self.map_dropped_items[i][j] = {}
            self.map_dropped_items[i][j][1] = 0
        end
    end
    for i = 1, MAP_X do
        self.map_emergent_events[i] = {}
        for j = 1, MAP_Y do
            self.map_emergent_events[i][j] = {}
            self.map_emergent_events[i][j][1] = 0
        end
    end
    --[[
    for i = 1, MAP_X do
        self.map_area_index[i] = {}
        for j = 1, MAP_Y do
            self.map_area_index[i][j] = {}
            self.map_area_index[i][j][1] = 0
        end
    end
    ]]

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

    self:create_bakery(1, "bakery1", -100, 100, 1111, {identity.slave, identity.guard, identity.officer, identity.king}, {})
    self:create_farm(2, "farm1", -100, -450, {identity.slave, identity.guard, identity.officer, identity.king}, {})
    self:create_slave_lb(3, "slavelb1", -100, 500, {identity.slave, identity.guard, identity.officer, identity.king}, {})
    self:create_bakery(4, "bakery1", -850, 100, 1234, {identity.slave, identity.guard, identity.officer, identity.king}, {})
    self:create_guard_station(5, "guard_station1", 600, 100, 2345, {identity.guard, identity.officer, identity.king}, {})

    self.m_character = character:new()
    self.m_character.main_game = self
    self:init_minion_frame()
    local frame = display.getAnimationCache(minion_motions[self.m_character.id][DOWN]):getFrames()[2]
    self.m_character.sprite = display.newSprite(frame:getSpriteFrame())
    :addTo(self.c_node, math.floor(display.cy))
    self.m_character:set_map_characters(self.map_characters, 0, self.minions, self.m_character)
    self.m_character:set_position(self.width / 2 + self.m_init_pos.x, self.height / 2 + self.m_init_pos.y)
    self.m_character:change_position(0.0, 0.0, self.width / 2 + self.m_init_pos.x, self.height / 2 + self.m_init_pos.y)
    self.m_character:set_name("Pandora")
    self.m_character:add_shadow()
    self.m_character.inventory[1] = {}
    self.m_character.inventory[1].type = item_type.KEY
    self.m_character.inventory[1].num = 1
    self.m_character.inventory[1].sequence = 1111
    self.m_character.inventory[2] = {}
    self.m_character.inventory[2].type = item_type.BREAD
    self.m_character.inventory[2].num = 3
    self.m_character.inventory[3] = {}
    self.m_character.inventory[3].type = item_type.KEY
    self.m_character.inventory[3].num = 1
    self.m_character.inventory[3].sequence = 1112
    self.m_character.inventory[4] = {}
    self.m_character.inventory[4].type = item_type.KEY
    self.m_character.inventory[4].num = 1
    self.m_character.inventory[4].sequence = 1234
    self.m_character.inventory[5] = {}
    self.m_character.inventory[5].type = item_type.CHAR
    self.m_character.inventory[5].num = 8
    self.m_character.inventory[6] = {}
    self.m_character.inventory[6].type = item_type.BREAD
    self.m_character.inventory[6].num = 3
    self.m_character.inventory[7] = {}
    self.m_character.inventory[7].type = item_type.TONGS
    self.m_character.inventory[7].num = 1
    self.m_character.inventory[8] = {}
    self.m_character.inventory[8].type = item_type.SWORD
    self.m_character.inventory[8].num = 1
    self.m_character.inventory[9] = {}
    self.m_character.inventory[9].type = item_type.COIN
    self.m_character.inventory[9].num = 10
    self.m_character.inventory[10] = {}
    self.m_character.inventory[10].type = item_type.CROP
    self.m_character.inventory[10].num = 4
    self.m_character.inventory[11] = {}
    self.m_character.inventory[11].type = item_type.ROPE
    self.m_character.inventory[11].num = 1
    for i = 1, #self.m_character.inventory do
        self.m_character.inventory.weight = self.m_character.inventory.weight + self.m_character.inventory[i].type.weight * self.m_character.inventory[i].num
    end
    self.m_character:equip_right_hand(self.m_character.inventory[8])
    self.m_character:equip_left_hand(self.m_character.inventory[11])
    --self.m_character.left_hand.item.chained_target = self.minions[13]
    --self.m_character.chain_target = self.minions[10]
    --self.minions[10].left_hand.item.chained_target = self.m_character
    --self.minions[10].chain_target = self.minions[13]
    --[[
    for i = 1, inventory_rows * inventory_cols - 1 do
        self.m_character.inventory[i] = {}
        self.m_character.inventory[i].type = item_type.CROP
        self.m_character.inventory[i].num = item_type.CROP.stack_limit
        self.m_character.inventory.weight = self.m_character.inventory.weight + item_type.CROP.weight * item_type.CROP.stack_limit
    end
    self.m_character.inventory[inventory_rows * inventory_cols] = {}
    self.m_character.inventory[inventory_rows * inventory_cols].type = item_type.CROP
    self.m_character.inventory[inventory_rows * inventory_cols].num = item_type.CROP.stack_limit - 2
    self.m_character.inventory.weight = self.m_character.inventory.weight + item_type.CROP.weight * (item_type.CROP.stack_limit - 2)
    ]]

    local touch_layer = display.newLayer()
    :addTo(self, 90)

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(
        function(touch, event)
            if self.m_character.asleep == true then
                return true
            end
            self.clicked_times = self.clicked_times + 1
            local x, y = touch:getLocation().x, touch:getLocation().y
            if x >= display.right - 75 * 2 and x < display.right - 75 and y >= display.bottom and y < display.bottom + 75 then
                self.m_character.left_hand_swing = true
                if self.m_character.left_hand == nil then
                    local damage = {value = 5, duration = 0.0, type = normal_damage, source = self.m_character}
                    self.m_character:find_damage_target(self, damage)
                elseif self.m_character.left_hand ~= nil and self.m_character.left_hand.item.type.damage ~= nil then
                    local damage = {}
                    damage.value = self.m_character.left_hand.item.type.damage.value
                    damage.duration = self.m_character.left_hand.item.type.damage.dur
                    damage.type = self.m_character.left_hand.item.type.damage.type
                    damage.source = self.m_character
                    self.m_character:find_damage_target(self, damage)
                end
                --self:drop_new_body(identity.free_folk, 1, self.m_character.position, self.m_character.height_level)
                return true
            end
            if x >= display.right - 75 and x < display.right and y >= display.bottom and y < display.bottom + 75 then
                self.m_character.right_hand_swing = true
                if self.m_character.right_hand == nil then
                    local damage = {value = 5, duration = 0.0, type = normal_damage, source = self.m_character}
                    self.m_character:find_damage_target(self, damage)
                elseif self.m_character.right_hand ~= nil and self.m_character.right_hand.item.type.damage ~= nil then
                    local damage = {}
                    damage.value = self.m_character.right_hand.item.type.damage.value
                    damage.duration = self.m_character.right_hand.item.type.damage.dur
                    damage.type = self.m_character.right_hand.item.type.damage.type
                    damage.source = self.m_character
                    self.m_character:find_damage_target(self, damage)
                end
                --[[
                local i = math.floor(self.m_character.position.x / 50.0)
                local j = math.floor(self.m_character.position.y / 50.0)
                i = math.floor(i) + 1
                j = math.floor(j) + 1
                if self.map_emergent_events[i][j][1] > 0 then
                    for index = 2, self.map_emergent_events[i][j][1] + 1 do
                        local temp_i = math.floor(self.map_emergent_events[i][j][index].position.x / 50.0)
                        local temp_j = math.floor(self.map_emergent_events[i][j][index].position.y / 50.0)
                        temp_i = math.floor(temp_i) + 1
                        temp_j = math.floor(temp_j) + 1
                        if i == temp_i and j == temp_j then
                            self.map_emergent_events[i][j][index]:remove(self)
                            break
                        end
                    end
                end
                --]]
                return true
            end
            if x >= 0 and x < 150 and y >= 0 and y < 150 then
                if self.interact_flag == false and self.m_character.chain_target ~= nil then
                    self.map_move_flag = STOP
                    return true
                end
                if x < 150 and y < 150 then
                    if x + y <= 150 then
                        if x <= y then
                            if self.interact_flag == true then
                                self.map_move_flag = STOP
                                if self.interact_target ~= 0 then
                                    if self.chest_flag == true then
                                        self.left_inventory:removeFromParentAndCleanup(true)
                                        self.left_inventory = require("app.views.inventory_view").new(false, {}, 100, display.cy - inventory_rows * 50 / 2, inventory_cols, inventory_rows, cc.size(inventory_cols * 50, inventory_rows * 50), cc.p(50, 50), kCCScrollViewDirectionVertical, kCCTableViewFillTopDown, self)
                                        :setAnchorPoint(cc.p(0, 0))
                                        :setPosition(cc.p(0, 0))
                                        :addTo(self.inventory_layer)
                                        self.chest_flag = false
                                    end
                                    self.left_inventory.table_view.elements = self.minions[self.interact_target].inventory
                                    self.left_inventory.table_view:reloadData()
                                    self.right_inventory.table_view:reloadData()
                                    if self.chest_flag == false then
                                        self.left_inventory.weight:setString(self.minions[self.interact_target].inventory.weight.." / "..self.minions[self.interact_target].inventory.weight_limit)
                                    end
                                    self.left_inventory.name:setString(self.minions[self.interact_target].name)
                                    self.right_inventory.weight:setString(self.m_character.inventory.weight.." / "..self.m_character.inventory.weight_limit)
                                    self.right_inventory.name:setString(self.m_character.name)
                                    self.inventory_layer:setVisible(true)
                                end
                                return true
                            end
                        else
                            if self.interact_flag == true then
                                self.interact_flag = false
                                self.pause_flag = false
                                self.pause:setVisible(false)
                                self.map_move_flag = STOP
                                self.control:setTexture("control.png")
                                self.inventory_layer:setVisible(false)
                                self.interact_target_name:setVisible(false)
                                return true
                            end
                        end
                    else
                        if x <= y then
                            if self.interact_flag == true then
                                self.map_move_flag = STOP
                                return true
                            end
                        else
                            if self.interact_flag == true then
                                self.map_move_flag = STOP
                                return true
                            end
                        end
                    end
                    self.start_position = touch:getLocation()
                end
                self.map_move_flag = STOP
            end
            self:check_drag(touch)
            return true
        end
        ,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(
        function(touch, event)
            if self.m_character.asleep == true then
                return
            end
            local x, y = touch:getLocation().x, touch:getLocation().y
            if self.start_position ~= nil then
                local dis = 0
                if self.end_position ~= nil then
                    dis = (x - self.end_position.x) * (x - self.end_position.x) + (y - self.end_position.y) * (y - self.end_position.y)
                end
                if self.end_position == nil or dis <= 10000 or self.clicked_times == 1 then
                    local dx = x - self.start_position.x
                    local dy = y - self.start_position.y
                    if math.abs(dx) >= math.abs(dy) then
                        if dx < 0 then
                            self.map_move_flag = LEFT
                        else
                            self.map_move_flag = RIGHT
                        end
                    else
                        if dy > 0 then
                            self.map_move_flag = UP
                        else
                            self.map_move_flag = DOWN
                        end
                    end
                    self.end_position = touch:getLocation()
                end
            end
            if self.drag_item ~= nil then
                self.drag_item:move(touch:getLocation().x - 25, touch:getLocation().y - 25)
            else
                self:check_drag(touch)
            end
            return
        end
        ,cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(
        function(touch, event)
            if self.m_character.asleep == true then
                return
            end
            self.clicked_times = self.clicked_times - 1
            local x, y = touch:getLocation().x, touch:getLocation().y
            if self.end_position ~= nil and x == self.end_position.x and y == self.end_position.y then
                self.start_position = nil
                self.map_move_flag = STOP
            end
            local out_side_flag = true
            if self.inventory_selected ~= nil and self.inventory_block_selected ~= nil and self.drag_item ~= nil then
                if self.left_inventory:isVisible() == true then
                    local left = self.left_inventory.table_view:getPositionX()
                    local right = self.left_inventory.table_view:getPositionX() + self.left_inventory.table_view:getContentSize().width
                    local bottom = self.left_inventory.table_view:getPositionY()
                    local top = self.left_inventory.table_view:getPositionY() + self.left_inventory.table_view:getContentSize().height
                    if x >= left and x < right and y >= bottom and y < top then
                        out_side_flag = false
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
                        if self.left_inventory.table_view.elements[i + j * local_inventory_cols] ~= nil and self.left_inventory.table_view.elements[i + j * local_inventory_cols].equipped ~= nil then
                            if self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] == nil then
                                self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] = self.drag_item.item
                                self.inventory_selected.weight = self.inventory_selected.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                            else
                                self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x].num = self.drag_item.item.num + self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x].num
                                self.inventory_selected.weight = self.inventory_selected.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                            end
                        else
                            if self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] == nil or self.left_inventory.table_view.elements[i + j * local_inventory_cols] == nil then
                                if self.left_inventory.table_view.elements[i + j * local_inventory_cols] ~= nil then
                                    if self.left_inventory.table_view.elements[i + j * local_inventory_cols].type ~= self.drag_item.item.type then
                                        self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] = self.left_inventory.table_view.elements[i + j * local_inventory_cols]
                                        self.left_inventory.table_view.elements.weight = self.left_inventory.table_view.elements.weight - self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.weight * self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                        self.inventory_selected.weight = self.inventory_selected.weight + self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.weight * self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                    else
                                        local heat = 0
                                        if self.drag_item.item.heat_level ~= nil then
                                            heat = heat + self.drag_item.item.heat_level * self.drag_item.item.num
                                        end
                                        if self.left_inventory.table_view.elements[i + j * local_inventory_cols].heat_level ~= nil then
                                            heat = heat + self.left_inventory.table_view.elements[i + j * local_inventory_cols].heat_level * self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                        end
                                        self.drag_item.item.num = self.drag_item.item.num + self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                        if heat ~= 0 then
                                            if self.drag_item.item.heat_level == nil then
                                                self.cool_down:add_item(self.drag_item.item)
                                            end
                                            self.drag_item.item.heat_level = heat / self.drag_item.item.num
                                        end
                                        self.left_inventory.table_view.elements.weight = self.left_inventory.table_view.elements.weight - self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.weight * self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                        if self.drag_item.item.num > self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.stack_limit then
                                            local num = self.drag_item.item.num - self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.stack_limit
                                            self.drag_item.item.num = self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.stack_limit
                                            self.left_inventory.table_view.elements[i + j * local_inventory_cols].num = num
                                            if heat ~= 0 then
                                                if self.left_inventory.table_view.elements[i + j * local_inventory_cols].heat_level == nil then
                                                    self.cool_down:add_item(self.left_inventory.table_view.elements[i + j * local_inventory_cols])
                                                end
                                                self.left_inventory.table_view.elements[i + j * local_inventory_cols].heat_level = self.drag_item.item.heat_level
                                            end
                                            self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] = self.left_inventory.table_view.elements[i + j * local_inventory_cols]
                                            self.inventory_selected.weight = self.inventory_selected.weight + self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.weight * self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                        end
                                    end
                                end
                                self.left_inventory.table_view.elements[i + j * local_inventory_cols] = self.drag_item.item
                                self.left_inventory.table_view.elements.weight = self.left_inventory.table_view.elements.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                            elseif self.left_inventory.table_view.elements[i + j * local_inventory_cols].type == self.drag_item.item.type and self.drag_item.item.num + self.left_inventory.table_view.elements[i + j * local_inventory_cols].num <= self.left_inventory.table_view.elements[i + j * local_inventory_cols].type.stack_limit then
                                local heat = 0
                                if self.drag_item.item.heat_level ~= nil then
                                    heat = heat + self.drag_item.item.heat_level * self.drag_item.item.num
                                end
                                if self.left_inventory.table_view.elements[i + j * local_inventory_cols].heat_level ~= nil then
                                    heat = heat + self.left_inventory.table_view.elements[i + j * local_inventory_cols].heat_level * self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                end
                                self.left_inventory.table_view.elements[i + j * local_inventory_cols].num = self.drag_item.item.num + self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                self.left_inventory.table_view.elements.weight = self.left_inventory.table_view.elements.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                                if heat ~= 0 then
                                    if self.left_inventory.table_view.elements[i + j * local_inventory_cols].heat_level == nil then
                                        self.cool_down:add_item(self.left_inventory.table_view.elements[i + j * local_inventory_cols])
                                    end
                                    self.left_inventory.table_view.elements[i + j * local_inventory_cols].heat_level = heat / self.left_inventory.table_view.elements[i + j * local_inventory_cols].num
                                end
                            else
                                self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x].num = self.drag_item.item.num + self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x].num
                                self.inventory_selected.weight = self.inventory_selected.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                            end
                        end
                    end
                elseif self.interact_oven_flag == true then
                    out_side_flag = self.oven_view:check_drop(self, touch)
                end
                local left = self.right_inventory.table_view:getPositionX()
                local right = self.right_inventory.table_view:getPositionX() + self.right_inventory.table_view:getContentSize().width
                local bottom = self.right_inventory.table_view:getPositionY()
                local top = self.right_inventory.table_view:getPositionY() + self.right_inventory.table_view:getContentSize().height
                if x >= left and x < right and y >= bottom and y < top then
                    out_side_flag = false
                    local i = math.floor((touch:getLocation().x - left) / 50.0) + 1
                    local j = inventory_rows - (math.floor((touch:getLocation().y - bottom) / 50.0) + 1)
                    if self.right_inventory.table_view.elements[i + j * inventory_cols] ~= nil and self.right_inventory.table_view.elements[i + j * inventory_cols].equipped ~= nil then
                        if self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] == nil then
                            self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] = self.drag_item.item
                            self.inventory_selected.weight = self.inventory_selected.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                        else
                            self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x].num = self.drag_item.item.num + self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x].num
                            self.inventory_selected.weight = self.inventory_selected.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                        end
                    else
                        if self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] == nil or self.right_inventory.table_view.elements[i + j * inventory_cols] == nil then
                            local swap = true
                            if self.right_inventory.table_view.elements[i + j * inventory_cols] ~= nil then
                                if self.right_inventory.table_view.elements[i + j * inventory_cols].type ~= self.drag_item.item.type then
                                    if self.interact_oven_flag == true then
                                        self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] = self.drag_item.item
                                        self.inventory_selected.weight = self.inventory_selected.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                                        swap = false
                                    else
                                        self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] = self.right_inventory.table_view.elements[i + j * inventory_cols]
                                        self.right_inventory.table_view.elements.weight = self.right_inventory.table_view.elements.weight - self.right_inventory.table_view.elements[i + j * inventory_cols].type.weight * self.right_inventory.table_view.elements[i + j * inventory_cols].num
                                        self.inventory_selected.weight = self.inventory_selected.weight + self.right_inventory.table_view.elements[i + j * inventory_cols].type.weight * self.right_inventory.table_view.elements[i + j * inventory_cols].num
                                    end
                                else
                                    local heat = 0
                                    if self.drag_item.item.heat_level ~= nil then
                                        heat = heat + self.drag_item.item.heat_level * self.drag_item.item.num
                                    end
                                    if self.right_inventory.table_view.elements[i + j * inventory_cols].heat_level ~= nil then
                                        heat = heat + self.right_inventory.table_view.elements[i + j * inventory_cols].heat_level * self.right_inventory.table_view.elements[i + j * inventory_cols].num
                                    end
                                    self.drag_item.item.num = self.drag_item.item.num + self.right_inventory.table_view.elements[i + j * inventory_cols].num
                                    if heat ~= 0 then
                                        if self.drag_item.item.heat_level == nil then
                                            self.cool_down:add_item(self.drag_item.item)
                                        end
                                        self.drag_item.item.heat_level = heat / self.drag_item.item.num
                                    end
                                    self.right_inventory.table_view.elements.weight = self.right_inventory.table_view.elements.weight - self.right_inventory.table_view.elements[i + j * inventory_cols].type.weight * self.right_inventory.table_view.elements[i + j * inventory_cols].num
                                    if self.drag_item.item.num > self.right_inventory.table_view.elements[i + j * inventory_cols].type.stack_limit then
                                        local num = self.drag_item.item.num - self.right_inventory.table_view.elements[i + j * inventory_cols].type.stack_limit
                                        self.drag_item.item.num = self.right_inventory.table_view.elements[i + j * inventory_cols].type.stack_limit
                                        self.right_inventory.table_view.elements[i + j * inventory_cols].num = num
                                        if heat ~= 0 then
                                            if self.right_inventory.table_view.elements[i + j * inventory_cols].heat_level == nil then
                                                self.cool_down:add_item(self.right_inventory.table_view.elements[i + j * inventory_cols])
                                            end
                                            self.right_inventory.table_view.elements[i + j * inventory_cols].heat_level = self.drag_item.item.heat_level
                                        end
                                        self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] = self.right_inventory.table_view.elements[i + j * inventory_cols]
                                        self.inventory_selected.weight = self.inventory_selected.weight + self.right_inventory.table_view.elements[i + j * inventory_cols].type.weight * self.right_inventory.table_view.elements[i + j * inventory_cols].num
                                    end
                                end
                            end
                            if swap == true then
                                self.right_inventory.table_view.elements[i + j * inventory_cols] = self.drag_item.item
                                self.right_inventory.table_view.elements.weight = self.right_inventory.table_view.elements.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                                self.right_inventory.table_view.elements[i + j * inventory_cols].fire_on = nil
                            end
                        elseif self.right_inventory.table_view.elements[i + j * inventory_cols].type == self.drag_item.item.type and self.drag_item.item.num + self.right_inventory.table_view.elements[i + j * inventory_cols].num <= self.right_inventory.table_view.elements[i + j * inventory_cols].type.stack_limit then
                            local heat = 0
                            if self.drag_item.item.heat_level ~= nil then
                                heat = heat + self.drag_item.item.heat_level * self.drag_item.item.num
                            end
                            if self.right_inventory.table_view.elements[i + j * inventory_cols].heat_level ~= nil then
                                heat = heat + self.right_inventory.table_view.elements[i + j * inventory_cols].heat_level * self.right_inventory.table_view.elements[i + j * inventory_cols].num
                            end
                            self.right_inventory.table_view.elements[i + j * inventory_cols].num = self.drag_item.item.num + self.right_inventory.table_view.elements[i + j * inventory_cols].num
                            self.right_inventory.table_view.elements.weight = self.right_inventory.table_view.elements.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                            if heat ~= 0 then
                                if self.right_inventory.table_view.elements[i + j * inventory_cols].heat_level == nil then
                                    self.cool_down:add_item(self.right_inventory.table_view.elements[i + j * inventory_cols])
                                end
                                self.right_inventory.table_view.elements[i + j * inventory_cols].heat_level = heat / self.right_inventory.table_view.elements[i + j * inventory_cols].num
                            end
                            self.right_inventory.table_view.elements[i + j * inventory_cols].fire_on = nil
                        else
                            self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x].num = self.drag_item.item.num + self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x].num
                            self.inventory_selected.weight = self.inventory_selected.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                        end
                    end
                end
                if out_side_flag == true then
                    self.drag_item.item.fire_on = nil
                    self:drop_new_item(self.drag_item.item, self.m_character.position, self.m_character.height_level)
                end
                if self.left_inventory:isVisible() == true then
                    self.left_inventory.table_view:reloadData()
                    if self.chest_flag == false then
                        self.left_inventory.weight:setString(self.left_inventory.table_view.elements.weight.." / "..self.left_inventory.table_view.elements.weight_limit)
                    end
                end
                if self.interact_oven_flag == true then
                    self.oven_view.table_view_up:reloadData()
                    self.oven_view.table_view_down:reloadData()
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
            if self.m_character.asleep == true then
                return
            end
            self.map_move_flag = STOP
            if self.inventory_selected ~= nil and self.inventory_block_selected ~= nil and self.drag_item ~= nil then
                if self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] == nil then
                    self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x] = self.drag_item.item
                else
                    self.inventory_selected[self.inventory_block_selected.x + self.inventory_block_selected.y * self.inventory_selected_size.x].num = self.drag_item.item.num
                end
                self.inventory_selected.weight = self.inventory_selected.weight + self.drag_item.item.type.weight * self.drag_item.item.num
                if self.left_inventory:isVisible() == true then
                    self.left_inventory.table_view:reloadData()
                    if self.chest_flag == false then
                        self.left_inventory.weight:setString(self.left_inventory.table_view.elements.weight.." / "..self.left_inventory.table_view.elements.weight_limit)
                    end
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

    self.interact_target_name = cc.Label:createWithTTF("", font.GREEK_FONT, 50)
    :setAnchorPoint(0.5, 0.0)
    :move(display.left + 75, display.bottom + 150)
    :setTextColor(font.YELLOW)
    :addTo(touch_layer)
    :setVisible(false)

    self.interactions = require("app.views.interactions").new(true, self.last_interactions, display.right, 0, cc.size(75*6, 75), cc.p(75, 75), kCCScrollViewDirectionHorizontal, kCCTableViewFillTopDown, self)
    self.interactions:setAnchorPoint(cc.p(0, 0))
    self.interactions:setPosition(cc.p(0, 75))
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

    self.oven_view = require("app.views.oven_view").new({up = {}, down = {}, fire_on = false}, 50 + 200, display.cy + 50, cc.p(50, 50), self)
    :setAnchorPoint(cc.p(0, 0))
    :setPosition(cc.p(0, 0))
    :addTo(self.inventory_layer)
    :setVisible(false)

    self.inventory_layer:setVisible(false)

    self.time = DAWN_TIME
    self.light_status = DAY

    self:init_torch_frame()
    local x, y = self.c_node:getPosition()
    self.torches[1] = torch:new()
    self.torches[1].position = cc.p(-100 + self.width / 2, 100 + self.height / 2)
    self.torches[1].sprite = display.newSprite("background/torch.png")
    :move(self.torches[1].position.x - self.m_character.position.x + display.cx, self.torches[1].position.y - self.m_character.position.y + display.cy + 30)
    :addTo(self.c_node, math.floor(display.top - (self.torches[1].position.y - self.m_character.position.y + display.cy)))
    self.torches[2] = torch:new()
    self.torches[2].position = cc.p(-700 + self.width / 2, 100 + self.height / 2)
    self.torches[2].sprite = display.newSprite("background/torch.png")
    :move(self.torches[2].position.x - self.m_character.position.x + display.cx, self.torches[2].position.y - self.m_character.position.y + display.cy + 30)
    :addTo(self.c_node, math.floor(display.top - (self.torches[2].position.y - self.m_character.position.y + display.cy)))
    self.torches[3] = torch:new()
    self.torches[3].position = cc.p(-100 + self.width / 2, 450 + self.height / 2)
    self.torches[3].sprite = display.newSprite("background/torch.png")
    :move(self.torches[3].position.x - self.m_character.position.x + display.cx, self.torches[3].position.y - self.m_character.position.y + display.cy + 30)
    :addTo(self.c_node, math.floor(display.top - (self.torches[3].position.y - self.m_character.position.y + display.cy)))
    self.torches[4] = torch:new()
    self.torches[4].position = cc.p(800 + self.width / 2, 50 + self.height / 2)
    self.torches[4].sprite = display.newSprite("background/torch.png")
    :move(self.torches[4].position.x - self.m_character.position.x + display.cx, self.torches[4].position.y - self.m_character.position.y + display.cy + 30)
    :addTo(self.c_node, math.floor(display.top - (self.torches[4].position.y - self.m_character.position.y + display.cy)))
    self.torches[5] = torch:new()
    self.torches[5].position = cc.p(1300 + self.width / 2, 50 + self.height / 2)
    self.torches[5].sprite = display.newSprite("background/torch.png")
    :move(self.torches[5].position.x - self.m_character.position.x + display.cx, self.torches[5].position.y - self.m_character.position.y + display.cy + 30)
    :addTo(self.c_node, math.floor(display.top - (self.torches[5].position.y - self.m_character.position.y + display.cy)))

    --[[
    local clound_shadow = display.newSprite("object/cloud_shadow.png")
    :move(display.cx - 100, display.cy + 50)
    :addTo(self, 100)
    ]]

    local screen_size = cc.Director:getInstance():getWinSize()
    local frame_size = cc.Director:getInstance():getOpenGLView():getFrameSize()
    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(screen_size["width"], screen_size["height"], cc.ResolutionPolicy.SHOW_ALL)

    self.screen_ratio = cc.p(frame_size["width"]/screen_size["width"], frame_size["height"]/screen_size["height"])

    local day_back = cc.GLProgram:createWithFilenames("background/back_shadow.vsh", "background/day_shadow.fsh")
    day_back:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    day_back:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    day_back:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    day_back:link()
    day_back:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(day_back, "day_back_shadow")
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
    local night_back = cc.GLProgram:createWithFilenames("background/back.vsh", "background/night_roof.fsh")
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_back:link()
    night_back:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_back, "night_back_roof")
    local night_back = cc.GLProgram:createWithFilenames("background/back.vsh", "background/night_wall.fsh")
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_back:link()
    night_back:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_back, "night_back_wall")
    local night_back = cc.GLProgram:createWithFilenames("background/back.vsh", "background/night.fsh")
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_back:link()
    night_back:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_back, "night_back")
    local night_back = cc.GLProgram:createWithFilenames("background/back.vsh", "background/night.fsh")
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_back:link()
    night_back:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_back, "night_back1")
    local night_back = cc.GLProgram:createWithFilenames("background/back.vsh", "background/night.fsh")
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_back:link()
    night_back:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_back, "night_back2")
    local night_back = cc.GLProgram:createWithFilenames("background/back.vsh", "background/night.fsh")
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_back:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_back:link()
    night_back:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_back, "night_back3")
    local night_char = cc.GLProgram:createWithFilenames("background/char.vsh", "background/night.fsh")
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_char:link()
    night_char:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_char, "night_char")
    local night_char = cc.GLProgram:createWithFilenames("background/char.vsh", "background/night.fsh")
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_char:link()
    night_char:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_char, "night_char1")
    local night_char = cc.GLProgram:createWithFilenames("background/char.vsh", "background/night.fsh")
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_char:link()
    night_char:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_char, "night_char2")
    local night_char = cc.GLProgram:createWithFilenames("background/char.vsh", "background/night.fsh")
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
    night_char:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
    night_char:link()
    night_char:updateUniforms()
    cc.GLProgramCache:getInstance():addGLProgram(night_char, "night_char3")
    self:scheduleUpdate(handler(self, self.step))
    enter_day(self)
end

function SecondScene:onCleanup()
    self:removeAllEventListeners()
end

return SecondScene
