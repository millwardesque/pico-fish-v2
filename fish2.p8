pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
package={loaded={},_c={}}
package._c["game_cam"]=function()
game_obj = require('game_obj')

local game_cam = {
    mk = function(name, pos_x, pos_y, width, height, bounds_x, bounds_y)
        local c = game_obj.mk(name, 'camera', pos_x, pos_y)
        c.cam = {
            w = width,
            h = height,
            bounds_x = bounds_x,
            bounds_y = bounds_y,
            target = nil,
        }

        c.update = function(cam)
            -- Track a target
            target = cam.cam.target
            if target ~= nil then
                if target.x < cam.x + cam.cam.bounds_x then
                    cam.x = target.x - cam.cam.bounds_x
                elseif target.x > cam.x + cam.cam.w - cam.cam.bounds_x then
                    cam.x = target.x - cam.cam.w + cam.cam.bounds_x
                end

                if target.y < cam.y + cam.cam.bounds_y then
                    cam.y = target.y - cam.cam.bounds_y
                elseif target.y > cam.y + cam.cam.h - cam.cam.bounds_y then
                    cam.y = target.y - cam.cam.h + cam.cam.bounds_y
                end
            end

            -- Prevent camera from scrolling off the top-left side of the map
            if cam.x < 0 then cam.x = 0 end
            if cam.y < 0 then cam.y = 0 end
        end

        return c
    end,
    draw_start = function (cam)
        camera(cam.x, cam.y)
        clip(0, 0, cam.cam.w, cam.cam.h)
    end,
    draw_end = function(cam)
        camera()
        clip()
    end,
}
return game_cam
end
package._c["game_obj"]=function()
v2 = require('v2')

local game_obj = {
    mk = function(name, type, pos_x, pos_y)
        local g = {
            name = name,
            type = type,
            x = pos_x,
            y = pos_y,
        }
        g.update = function(self)
        end

        g.v2_pos = function(self)
            return v2.mk(self.x, self.y)
        end

        return g
    end
}
return game_obj
end
package._c["v2"]=function()
local v2 = {
    mk = function(x, y)
        local v = {x = x, y = y,}
        setmetatable(v, v2.meta)
        return v;
    end,
    clone = function(x, y)
        return v2.mk(v.x, v.y)
    end,
    zero = function()
        return v2.mk(0, 0)
    end,
    mag = function(v)
        if v.x == 0 and v.y == 0 then
            return 0
        else
            return sqrt(v.x ^ 2 + v.y ^ 2)
        end
    end,
    norm = function(v)
        local m = v2.mag(v)
        if m == 0 then
            return v
        else
            return v2.mk(v.x / m, v.y / m)
        end
    end,
    str = function(v)
        return "("..v.x..", "..v.y..")"
    end,
    meta = {
        __add = function (a, b)
            return v2.mk(a.x + b.x, a.y + b.y)
        end,

        __sub = function (a, b)
            return v2.mk(a.x - b.x, a.y - b.y)
        end,

        __mul = function (a, b)
            if type(a) == "number" then
                return v2.mk(a * b.x, a * b.y)
            elseif type(b) == "number" then
                return v2.mk(b * a.x, b * a.y)
            else
                return v2.mk(a.x * b.x, a.y * b.y)
            end
        end,

        __div = function(a, b)
            v2.mk(a.x / b, a.y / b)
        end,

        __eq = function (a, b)
            return a.x == b.x and a.y == b.y
        end,
    },
}
return v2
end
package._c["log"]=function()
local log = {
    debug = true,
    file = 'debug.log',
    _data = {},

    log = function(msg)
        add(log._data, msg)
    end,
    syslog = function(msg)
        printh(msg, log.file)
    end,
    render = function()
        if log.debug then
            color(7)
            for i = 1, #log._data do
                print(log._data[i], 5, 5 + (8 * (i - 1)))
            end
        end

        log._data = {}
    end,
    tostring = function(any)
        if type(any)=="function" then
            return "function"
        end
        if any==nil then
            return "nil"
        end
        if type(any)=="string" then
            return any
        end
        if type(any)=="boolean" then
            if any then return "true" end
            return "false"
        end
        if type(any)=="table" then
            local str = "{ "
            for k,v in pairs(any) do
                str=str..log.tostring(k).."->"..log.tostring(v).." "
            end
            return str.."}"
        end
        if type(any)=="number" then
            return ""..any
        end
        return "unkown" -- should never show
    end
}
return log
end
package._c["renderer"]=function()
log = require('log')

local renderer = {
    render = function(cam, scene, bg)
        -- Collect renderables
        local to_render = {};
        for obj in all(scene) do
            if (obj.renderable) then
                if obj.renderable.enabled then
                    add(to_render, obj)
                end
            end
        end

        -- Sort
        renderer.sort(to_render)

        -- Draw
        game_cam.draw_start(cam)

        if bg then
            map(bg.x, bg.y, 0, 0, bg.w, bg.h)
        end

        for obj in all(to_render) do
            obj.renderable.render(obj.renderable, obj.x, obj.y)
        end

        game_cam.draw_end(cam)
    end,

    attach = function(game_obj, sprite)
        local r = {
            game_obj = game_obj,
            sprite = sprite,
            flip_x = false,
            flip_y = false,
            w = 1,
            h = 1,
            draw_order = 0,
            palette = nil,
            enabled = true
        }

        -- Default rendering function
        r.render = function(self, x, y)
            -- Set the palette
            if (self.palette) then
                -- Set colours
                for i = 0, 15 do
                    pal(i, self.palette[i + 1])
                end

                -- Set transparencies
                for i = 17, #self.palette do
                    palt(self.palette[i], true)
                end
            end

            -- Draw
            spr(self.sprite, x, y, self.w, self.h, self.flip_x, self.flip_y)

            -- Reset the palette
            if (self.palette) then
                pal()
            end
        end

        -- Save the default render function in case the obj wants to use it in an overridden render function.
        r.default_render = r.render

        game_obj.renderable = r;
        return game_obj;
    end,

    -- Sort a renderable array by draw-order
    sort = function(list)
        renderer.sort_helper(list, 1, #list)
    end,
    -- Helper function for sorting renderables by draw-order
    sort_helper = function (list, low, high)
        if (low < high) then
            local p = renderer.sort_split(list, low, high)
            renderer.sort_helper(list, low, p - 1)
            renderer.sort_helper(list, p + 1, high)
        end
    end,
    -- Partition a renderable list by draw_order
    sort_split = function (list, low, high)
        local pivot = list[high]
        local i = low - 1
        local temp
        for j = low, high - 1 do
            if (list[j].renderable.draw_order < pivot.renderable.draw_order or
                (list[j].renderable.draw_order == pivot.renderable.draw_order and list[j].y < pivot.y)) then
                i += 1
                temp = list[j]
                list[j] = list[i]
                list[i] = temp
            end
        end

        if (list[high].renderable.draw_order < list[i + 1].renderable.draw_order or
            (list[high].renderable.draw_order == list[i + 1].renderable.draw_order and list[high].y < list[i + 1].y)) then
            temp = list[high]
            list[high] = list[i + 1]
            list[i + 1] = temp
        end

        return i + 1
    end
}
return renderer
end
package._c["fish"]=function()
game_obj = require('game_obj')
renderer = require('renderer')
log = require('log')
v2 = require('v2')

utils = require('utils')

local base_fish_speed = 1
local fish = {
    mk = function(name, x, y, colour1, colour2, size)
        local f = game_obj.mk(name, 'fish', x, y)

        f.lure = nil
        f.draw_target = false   -- Debug flag for drawing the target
        f.target = game_obj.mk(name..'_trgt', 'go', 0, 0)
        f.state = 'idle'
        f.dir_to_target = v2.norm(v2.mk(x + 1, y))
        f.max_speed = base_fish_speed * (0.25 + rnd(1))
        f.speed = 0
        f.length = size * 2
        f.size = size
        f.colour1 = colour1
        f.colour2 = colour2

        if f.size == 3 then
            f.max_speed *= 0.8
        elseif f.size == 1 then
            f.max_speed *= 1.5
        end

        local target_pos = utils.rnd_v2_near(f.x, f.y, 20, 20)
        f.target.x = target_pos.x
        f.target.y = target_pos.y
        f.speed = f.max_speed * 0.3

        renderer.attach(f, 0)
        f.renderable.render = function(r, x, y)
            local go = r.game_obj

            if go.target_dist(go, go.target) < 0 then
                -- Do nothing. This will get cleaned on the next update cycle.
                return
            else
                local tail = v2.mk(x - go.dir_to_target.x * go.length, y - go.dir_to_target.y * go.length)
                local head = v2.mk(x, y)

                line(tail.x, tail.y, head.x, head.y, go.colour2)

                if go.speed >= 0 then
                    circfill(head.x, head.y, max(1, go.size), go.colour1)
                else
                    circfill(tail.x, tail.y, max(1, go.size), go.colour1)
                end

                if go.draw_target then
                    circfill(go.target.x, go.target.y, 1, 15)
                end
            end
        end

        f.target_dist = function(self, target)
            local d = target.v2_pos(target) - self.v2_pos(self)
            return v2.mag(d)
        end

        f.interest = function(self)
            -- 0: wander
            -- -1: avoid
            -- 1: pursue
            local interest = 0
            if self.lure == nil then
                interest = 0
            else
                local col1_match = self.lure.colour == self.colour1
                local col2_match = self.lure.colour == self.colour2
                local too_big = self.lure.size > self.size
                local too_small = self.size - self.lure.size > 1

                if too_small then
                    interest = 0
                elseif too_big then
                    if col1_match or col2_match then
                        interest = 0
                    else
                        interest = -1
                    end
                else
                    if col1_match and col2_match then
                        interest = 2
                    elseif col1_match or col2_match then
                        interest = 1
                    else
                        interest = 0
                    end
                end
            end
            return interest
        end

        f.update = function(self)
            local interest = self.interest(self)
            if self.state == 'idle' then
                if interest ~= 0 then
                    self.state = 'pursuit'
                    self.target = self.lure
                end

                -- Pick new target on arrival at target
                local has_collided = utils.circle_col(self.v2_pos(self), self.size, self.target.v2_pos(self.target), 0)
                if has_collided then
                    local target_pos = utils.rnd_v2_near(self.x, self.y, 20, 20)
                    self.target.x = target_pos.x
                    self.target.y = target_pos.y
                end

            elseif self.state == 'pursuit' then
                if interest == 0 then
                    self.state = 'idle'

                    local target_pos = utils.rnd_v2_near(self.x, self.y, 20, 20)
                    self.target = game_obj.mk(name..'_trgt', 'go', target_pos.x, target_pos.y)
                    self.speed = self.max_speed * 0.3
                else
                    self.speed = self.max_speed
                    if interest < 0 then
                        self.speed *= -1.0
                    elseif interest > 1 then
                        self.speed *= 1.0
                    elseif interest > 0 then
                        self.speed *= 0.6
                    end
                end
            end

            local d = self.target.v2_pos(self.target) - self.v2_pos(self)
            local dist = v2.mag(d)
            self.dir_to_target = v2.norm(d)

            local new_pos = self.v2_pos(self) + self.dir_to_target * self.speed
            self.x = new_pos.x
            self.y = new_pos.y
        end

        f.str = function(self)
            return(self.name.." sp:"..self.speed.." st:"..self.state.." tg:"..v2.str(self.target.v2_pos(self.target)))
        end

        return f
    end,
}

return fish
end
package._c["utils"]=function()
v2 = require('v2')

local utils = {
    rnd_v2_near = function(x, y, min_dist, zone_size)
        local angle = rnd(1.0)
        local dist = min_dist + flr(rnd(zone_size / 2.0))
        local x = x + dist * cos(angle)
        local y = y + dist * sin(angle)
        return v2.mk(x, y)
    end,

    circle_col = function(p1, r1, p2, r2)
        local dist = v2.mag(p2 - p1)
        if dist < 0 then
            -- Negative distance implies int overflow, so clearly the distance is farther than we can track.
            return nil
        elseif dist < (r1 + r2) then
            return true
        else
            return false
        end
    end
}

return utils
end
package._c["level"]=function()
local level = {
    mk = function(max_fish, init_fish, target_colour, target_count)
        local l = {
            max_fish = max_fish,
            init_fish = init_fish,
            target_colour = target_colour,
            target_count = target_count,
        }

        l.is_good_catch = function(self, lure, fish)
            if fish.colour1 == self.target_colour then
                return true
            else
                return false
            end
        end

        return l
    end,
}

return level
end
package._c["lure"]=function()
game_obj = require('game_obj')
renderer = require('renderer')

local dark_pal = {[0]=0,0,1,1,2,1,5,6,2,4,9,3,1,1,2,5}
local lure = {
    mk = function(name, x, y, colour)
        local l = game_obj.mk(name, 'lure', x, y)
        l.size = 5
        l.colour = colour
        l.pulse_timer = 0
        l.pulse_wait = 30
        l.is_pulsing = false
        l.sprites = {1, 2, 3}

        renderer.attach(l, 1)
        l.renderable.palette = {0,1,2,3,4,dark_pal[l.colour],dark_pal[l.colour],7,8,9,10,11,12,13,14,15}

        l.renderable.render = function(r, x, y)
            line(62, 0, x, y - 4, 12)

            r.default_render(r, x - 4, y - 4)
        end

        l.set_size = function(self, size)
            if size <= 1 then
                self.size = 1
            elseif size >= 3 then
                self.size = 3
            else
                self.size = size
            end

            self.renderable.sprite = self.sprites[self.size]
        end

        l.update = function(self)
            if self.is_pulsing then
                self.pulse_timer -= 1
                if self.pulse_timer == 0 then
                    self.renderable.palette = {0,1,2,3,4,dark_pal[self.colour],dark_pal[self.colour],7,8,9,10,11,12,13,14,15}
                    self.is_pulsing = false
                end
            else
                self.pulse_timer += 1
                if self.pulse_timer == self.pulse_wait then
                    self.renderable.palette = {0,1,2,3,4,dark_pal[self.colour],self.colour,7,8,9,10,11,12,13,14,15}
                    self.is_pulsing = true
                end
            end
        end

        l.radius = function(self)
            return self.size
        end

        return l
    end,
}

return lure
end
function require(p)
local l=package.loaded
if (l[p]==nil) l[p]=package._c[p]()
if (l[p]==nil) l[p]=true
return l[p]
end
game_cam = require('game_cam')
game_obj = require('game_obj')
log = require('log')
renderer = require('renderer')
v2 = require('v2')

fish = require('fish')
level = require('level')
lure = require('lure')
utils = require('utils')

cam = nil

level_timer = nil

fishes = nil
max_fish = 10

secs_per_level = 10

active_lure = nil
active_lure_index = nil
available_lures = nil

good_catch_count = nil
bad_catch_count = nil
longest_streak = nil
current_streak = nil

active_level = nil
active_level_index = nil
levels = {
    level.mk(20, 12, 11, 1),
    level.mk(20, 12, 7, 2),
    level.mk(20, 12, 8, 3),
}
levels_completed = 0


scene = nil
state = "ingame"

function add_fish(lure, colour1, colour2, size, is_offscreen)
    local min_dist = 40
    local zone_size = 128 - min_dist

    if is_offscreen then
        min_dist = 128
        zone_size = 20
    end

    local pos = utils.rnd_v2_near(64, 64, min_dist, zone_size)
    local new_fish = fish.mk('f'..#fishes, pos.x, pos.y, colour1, colour2, size)
    new_fish.lure = lure
    add(fishes, new_fish)
    add(scene, new_fish)
end

function prev_lure()
    if active_lure_index == nil or active_lure_index == #available_lures then
        active_lure_index = 1
    elseif active_lure_index < #available_lures then
        active_lure_index += 1
    end

    set_active_lure(available_lures[active_lure_index])
end

function next_lure()
    if active_lure_index == nil or active_lure_index == 1 then
        active_lure_index = #available_lures
    elseif active_lure_index > 1 then
        active_lure_index -= 1
    end

    set_active_lure(available_lures[active_lure_index])
end

function set_active_lure(lure)
    if active_lure ~= nil then
        del(scene, active_lure)
    end

    active_lure = lure
    add(scene, active_lure)

    for f in all(fishes) do
        f.lure = active_lure
    end
end

function remove_fish(fish)
    del(fishes, fish)
    del(scene, fish)
end

function should_add_fish(add_offscreen)
    if active_level.max_fish > #fishes then
        local i = flr(rnd(3))
        local colour1 = 0
        local colour2 = 1
        if i == 0 then
            colour1 = 7
            colour2 = 8
        elseif i == 1 then
            colour1 = 8
            colour2 = 11
        elseif i == 2 then
            colour1 = 11
            colour2 = 7
        end

        local fish_size = 1 + flr(rnd(3))

        add_fish(active_lure, colour1, colour2, fish_size, add_offscreen)
    end
end

function check_for_caught()
    for f in all(fishes) do
        local has_collided = utils.circle_col(f.v2_pos(f), f.size / 2.0, active_lure.v2_pos(active_lure), active_lure.size / 2.0)
        if has_collided == nil then
            remove_fish(f)
            should_add_fish(true)
        elseif has_collided then
            remove_fish(f)

            if active_level.is_good_catch(active_level, active_lure, f) then
                good_catch_count += 1
                current_streak +=1
                if current_streak > longest_streak then
                    longest_streak = current_streak
                end

                if good_catch_count == active_level.target_count then
                    state = "complete"
                    levels_completed += 1
                end
            else
                bad_catch_count += 1
                good_catch_count = 0
            end
        end
    end
end

function next_level()
    active_level_index = (active_level_index % #levels) + 1
    active_level = levels[active_level_index]

    scene = {}

    cam = game_cam.mk("main-cam", 0, 0, 128, 128, 16, 16)
    add(scene, cam)

    level_timer = secs_per_level * stat(8) -- secs * target FPS

    available_lures = {}
    add(available_lures, lure.mk('lure-7', 64, 64, 7))
    add(available_lures, lure.mk('lure-8', 64, 64, 8))
    add(available_lures, lure.mk('lure-11', 64, 64, 11))
    next_lure()
    prev_lure()

    good_catch_count = 0
    bad_catch_count = 0
    longest_streak = 0
    current_streak = 0

    fishes = {}

    for i = 1,active_level.init_fish do
        should_add_fish(false)
    end

    state = "ingame"
end

function restart_level()
    active_level_index -= 1
    next_level()
end

function reset_game()
    active_level_index = 0
    levels_completed = 0
    next_level()
end

function _init()
    log.debug = true

    reset_game()
end

function _update()
    if state == "ingame" then
        for obj in all(scene) do
            if obj.update then
                obj.update(obj)
            end
        end

        if btnp(0) then
            next_lure()
        end
        if btnp(1) then
            prev_lure()
        end

        if btnp(2) then
            active_lure.set_size(active_lure, active_lure.size + 1)
        end
        if btnp(3) then
            active_lure.set_size(active_lure, active_lure.size - 1)
        end

        if btnp(4) then
            restart_level()
        end

        check_for_caught()

        should_add_fish(true)

        level_timer -= 1

        if level_timer == 0 then
            state = "gameover"
        end
    elseif state == "complete" then
        scene = {}
        if btnp(4) then
            next_level()
        end
    elseif state == "gameover" then
        scene = {}
        if btnp(4) then
            reset_game()
        end
    end
end

function _draw()
    cls(1)

    background = nil
    renderer.render(cam, scene, background)

    if state == "ingame" then
        -- Lure selector
        local lure_x = 5
        for l in all(available_lures) do
            if l == active_lure then
                rect(lure_x - 1, 128 - 11, lure_x + 5 + 1, 128 - 4, 10)
            end
            rectfill(lure_x, 128 - 10, lure_x + 5, 128 - 5, l.colour)
            lure_x += 8
        end

        color(active_level.target_colour)
        print("level: "..(levels_completed + 1).." score: "..good_catch_count.. " / "..active_level.target_count, 5, 5)

        color(7)
        print("time: "..flr(level_timer / stat(8)), 5, 13)

        -- @HACK Log an empty message so the logger doesn't print over top of the UI
        log.log()
        log.log()

        -- @DEBUG log.log("Mem: "..(stat(0)/2048.0).."% CPU: "..(stat(1)/1.0).."%")
    elseif state == "complete" then
        color(7)
        log.log("level complete!")
        log.log("press 4 for next level")
    elseif state == "gameover" then
        color(7)
        log.log("game over!")
        log.log("level score: "..good_catch_count.." / "..active_level.target_count)
        log.log("levels completed: "..levels_completed)
        log.log("press 4 to try again")
    end

    log.render()
end
__gfx__
00000000000500000005000000056000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000500000005000000556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000600000006000000655600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000006560000065600000565600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000600000056500060565506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006560000050500006556560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000600000600060000600600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000006000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

