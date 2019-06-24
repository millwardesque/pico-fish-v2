game_cam = require('game_cam')
game_obj = require('game_obj')
log = require('log')
renderer = require('renderer')
v2 = require('v2')

fish = require('fish')
lure = require('lure')

cam = nil
fishes = nil
active_lure = nil
active_lure_index = nil
available_lures = nil
catch_count = nil
scene = nil
state = "ingame"

function add_fish(target, colour, size)
    local x = flr(rnd(100))
    local y = flr(rnd(100))
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

function check_for_caught()
    for f in all(fishes) do
        if f.lure_dist(f, active_lure) < active_lure.radius(active_lure) then
            remove_fish(f)
            catch_count += 1
        end
    end
end

function _init()
    log.debug = true
    state = "ingame"
    scene = {}

    cam = game_cam.mk("main-cam", 0, 0, 128, 128, 16, 16)
    add(scene, cam)

    available_lures = {}
    add(available_lures, lure.mk('lure-7', 64, 64, 7))
    add(available_lures, lure.mk('lure-8', 64, 64, 8))
    next_lure()

    catch_count = 0

    fishes = {}
    add_fish(active_lure, 7, 4)
    add_fish(active_lure, 7, 2)
    add_fish(active_lure, 8, 4)
    add_fish(active_lure, 8, 8)
end

function _update()
    if state == "ingame" then
        for obj in all(scene) do
            if obj.update then
                obj.update(obj)
            end
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

    -- Debug
    --log.log("Mem: "..(stat(0)/2048.0).."% CPU: "..(stat(1)/1.0).."%")
    log.log("fish: "..#fishes.." caught: "..catch_count)
    log.log("lures: "..#available_lures.." active: "..active_lure_index)
end

function _draw()
    cls(1)

    background = nil
    renderer.render(cam, scene, background)

    log.render()
end
