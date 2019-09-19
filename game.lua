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

background = {x = 0, y = 0, w = 16, h = 16}

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
