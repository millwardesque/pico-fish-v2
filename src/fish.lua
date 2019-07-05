game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

utils = require('utils')

local fish = {
    mk = function(name, x, y, colour1, colour2, size)
        local f = game_obj.mk(name, 'fish', x, y)
        f.lure = nil
        f.draw_target = false   -- Debug flag for drawing the target
        f.target = game_obj.mk(name..'_trgt', 'go', 0, 0)
        f.state = 'idle'
        f.dir_to_target = v2.norm(v2.mk(x + 1, y))
        f.max_speed = 0.5 * (0.25 + rnd(1))
        f.speed = 0
        f.length = size
        f.size = size
        f.colour1 = colour1
        f.colour2 = colour2

        if f.size >= 7 then
            f.max_speed *= 0.75
        elseif f.size < 3 then
            f.max_speed *= 1.25
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
                    circfill(head.x, head.y, max(1, go.size / 2.0), go.colour1)
                else
                    circfill(tail.x, tail.y, max(1, go.size / 2.0), go.colour1)
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
                local too_big = self.lure.size >= self.size
                local too_small = self.size - self.lure.size > 2

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
                local has_collided = utils.circle_col(self.v2_pos(self), self.size / 2.0, self.target.v2_pos(self.target), 0)
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
