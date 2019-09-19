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

        f.x_sprite = 16
        f.y_sprite = 32

        if f.size == 3 then
            f.max_speed *= 0.8
        elseif f.size == 1 then
            f.max_speed *= 1.5
        end

        local target_pos = utils.rnd_v2_near(f.x, f.y, 20, 20)
        f.target.x = target_pos.x
        f.target.y = target_pos.y
        f.speed = f.max_speed * 0.3

        renderer.attach(f, 16)
        -- f.renderable.render = function(r, x, y)
        --     local go = r.game_obj

        --     if go.target_dist(go, go.target) < 0 then
        --         -- Do nothing. This will get cleaned on the next update cycle.
        --         return
        --     else
        --         local tail = v2.mk(x - go.dir_to_target.x * go.length, y - go.dir_to_target.y * go.length)
        --         local head = v2.mk(x, y)

        --         line(tail.x, tail.y, head.x, head.y, go.colour2)

        --         if go.speed >= 0 then
        --             circfill(head.x, head.y, max(1, go.size), go.colour1)
        --         else
        --             circfill(tail.x, tail.y, max(1, go.size), go.colour1)
        --         end

        --         if go.draw_target then
        --             circfill(go.target.x, go.target.y, 1, 15)
        --         end
        --     end
        -- end

        f.renderable.palette = {0,1,2,3,4,f.colour2,f.colour1,7,8,9,10,11,12,13,14,15}

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

            -- Choose sprite based on direction
            if abs(self.dir_to_target.x) > abs(self.dir_to_target.y) then
                self.renderable.sprite = self.x_sprite + self.size - 1
            else
                self.renderable.sprite = self.y_sprite + self.size - 1
            end

            -- Sprite flipping based on direction.
            if self.dir_to_target.x < 0 then
                self.renderable.flip_x = true
            else
                self.renderable.flip_x = false
            end

            if self.dir_to_target.y < 0 then
                self.renderable.flip_y = false
            else
                self.renderable.flip_y = true
            end
        end

        f.str = function(self)
            return(self.name.." sp:"..self.speed.." st:"..self.state.." tg:"..v2.str(self.target.v2_pos(self.target)))
        end

        return f
    end,
}

return fish
