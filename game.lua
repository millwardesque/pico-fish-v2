game_cam = require('game_cam')
game_obj = require('game_obj')
log = require('log')
renderer = require('renderer')
v2 = require('v2')

fish = require('fish')
lure = require('lure')
utils = require('utils')

cam = nil

level_timer = nil

fishes = nil
max_fish = 10

active_lure = nil
active_lure_index = nil
available_lures = nil

good_catch_count = nil
bad_catch_count = nil
longest_streak = nil
current_streak = nil

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

function should_add_fish()
    if max_fish > #fishes then
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

        add_fish(active_lure, colour1, colour2, fish_size, true)
    end
end

function check_for_caught()
    for f in all(fishes) do
        local has_collided = utils.circle_col(f.v2_pos(f), f.size / 2.0, active_lure.v2_pos(active_lure), active_lure.size / 2.0)
        if has_collided == nil then
            remove_fish(f)
            should_add_fish()
        elseif has_collided then
            remove_fish(f)

            if f.colour1 == active_lure.colour then
                good_catch_count += 1
                current_streak +=1
                if current_streak > longest_streak then
                    longest_streak = current_streak
                end
            else
                bad_catch_count += 1
                current_streak = 0
            end
        end
    end
end

function _init()
    log.debug = true
    state = "ingame"
    scene = {}

    level_timer = 30 * stat(8) -- secs * target FPS

    cam = game_cam.mk("main-cam", 0, 0, 128, 128, 16, 16)
    add(scene, cam)

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

    local fish_size = nil
    for i = 1,3 do
        fish_size = 1 + flr(rnd(3))
        add_fish(active_lure, 7, 8, fish_size, false)
    end

    for i = 1,4 do
        fish_size = 1 + flr(rnd(3))
        add_fish(active_lure, 8, 11, fish_size, false)
    end

    for i = 1,4 do
        fish_size = 1 + flr(rnd(3))
        add_fish(active_lure, 11, 7, fish_size, false)
    end
end

function _update()
    if state == "ingame" then
        for obj in all(scene) do
            if obj.update then
                obj.update(obj)
            end
        end

        if btnp(0) then
            active_lure.set_size(active_lure, active_lure.size - 1)
        end
        if btnp(1) then
            active_lure.set_size(active_lure, active_lure.size + 1)
        end

        if btnp(2) then
            next_lure()
        end
        if btnp(3) then
            prev_lure()
        end

        if btnp(4) then
            _init()
        end

        check_for_caught()

        should_add_fish()

        level_timer -= 1

        if level_timer == 0 then
            state = "gameover"
        end
    elseif state == "gameover" then
        scene = {}
        if btnp(4) then
            _init()
        end
    end
end

function _draw()
    cls(1)

    background = nil
    renderer.render(cam, scene, background)

    -- @DEBUG log.log("Mem: "..(stat(0)/2048.0).."% CPU: "..(stat(1)/1.0).."%")

    if state == "ingame" then
        -- Lure selector
        local lure_y = 40
        for l in all(available_lures) do
            if l == active_lure then
                rect(4, lure_y - 1, 11, lure_y + 5 + 1, 10)
            end
            rectfill(5, lure_y, 10, lure_y + 5, l.colour)
            lure_y += 8
        end

        log.log("streak: "..current_streak.. " (best: "..longest_streak..")")
        log.log("time: "..flr(level_timer / stat(8)))
    elseif state == "gameover" then
        log.log("game over!")
        log.log("best streak: "..longest_streak)
        log.log("press 4 to try again")
    end

    log.render()
end
