game_cam = require('game_cam')
game_obj = require('game_obj')
log = require('log')
renderer = require('renderer')
v2 = require('v2')

fish = require('fish')
lure = require('lure')

cam = nil

level_timer = nil

fishes = nil
max_fish = 10

active_lure = nil
active_lure_index = nil
available_lures = nil

good_catch_count = nil
bad_catch_count = nil

scene = nil
state = "ingame"

function add_fish(target, colour, size, is_offscreen)
    local min_dist = 20
    local zone_size = 128 - min_dist

    if is_offscreen then
        min_dist = 128
        zone_size = 20
    end

    local x = 64 + min_dist + flr(rnd(zone_size)) - zone_size / 2
    local y = 64 + min_dist + flr(rnd(zone_size)) - zone_size / 2

    local new_fish = fish.mk('f'..#fishes, x, y, colour, size)
    new_fish.target = target
    add(fishes, new_fish)
    add(scene, new_fish)
end

function next_lure()
    if active_lure_index == nil or active_lure_index == #available_lures then
        active_lure_index = 1
    elseif active_lure_index < #available_lures then
        active_lure_index += 1
    end

    set_active_lure(available_lures[active_lure_index])
end

function prev_lure()
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
        f.target = active_lure
    end
end

function remove_fish(fish)
    del(fishes, fish)
    del(scene, fish)
end

function should_add_fish()
    if max_fish > #fishes then
        local i = flr(rnd(2))
        local fish_colour = 0
        if i == 0 then
            fish_colour = 7
        elseif i == 1 then
            fish_colour = 8
        end

        local fish_size = 1 + flr(rnd(8))

        add_fish(active_lure, fish_colour, fish_size, true)
    end
end

function check_for_caught()
    for f in all(fishes) do
        if f.lure_dist(f, active_lure) < active_lure.radius(active_lure) then
            remove_fish(f)

            if f.colour == 7 then
                good_catch_count += 1
            else
                bad_catch_count += 1
            end
        end
    end
end

function _init()
    log.debug = true
    state = "ingame"
    scene = {}

    level_timer = 15 * stat(8) -- secs * target FPS

    cam = game_cam.mk("main-cam", 0, 0, 128, 128, 16, 16)
    add(scene, cam)

    available_lures = {}
    add(available_lures, lure.mk('lure-7', 64, 64, 7))
    add(available_lures, lure.mk('lure-8', 64, 64, 8))
    next_lure()

    good_catch_count = 0
    bad_catch_count = 0

    fishes = {}

    local fish_size = nil
    for i = 1,6 do
        fish_size = 1 + flr(rnd(8))
        add_fish(active_lure, 7, fish_size, false)
    end

    for i = 1,6 do
        fish_size = 1 + flr(rnd(8))
        add_fish(active_lure, 8, fish_size, false)
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
            active_lure.size = max(1, active_lure.size - 1)
        end
        if btnp(1) then
            active_lure.size = min(10, active_lure.size + 1)
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

        -- Debug
        --log.log("Mem: "..(stat(0)/2048.0).."% CPU: "..(stat(1)/1.0).."%")
        log.log("fish: "..#fishes.." caught: "..(good_catch_count + bad_catch_count).." ("..good_catch_count.." vs. "..bad_catch_count..")")
        log.log("lures: "..#available_lures.." active: "..active_lure_index)
        log.log("time: "..flr(level_timer / stat(8)))
    elseif state == "gameover" then
        scene = {}
        log.log("game over!")
        log.log("score: "..max(0, good_catch_count - bad_catch_count))
        log.log("press 4 to try again")

        if btnp(4) then
            _init()
        end
    end
end

function _draw()
    cls(1)

    background = nil
    renderer.render(cam, scene, background)

    log.render()
end
