game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local fish = {
    mk = function(name, x, y, colour1, colour2, size)
        local f = game_obj.mk(name, 'fish', x, y)
        f.target = nil
        f.dir_to_lure = v2.norm(v2.mk(x + 1, y))
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

        renderer.attach(f, 0)
        f.renderable.render = function(r, x, y)
            local go = r.game_obj

            if go.lure_dist(go, go.target) < 0 then
                -- Do nothing. This will get cleaned on the next update cycle.
                return
            else
                local tail = v2.mk(x - go.dir_to_lure.x * go.length, y - go.dir_to_lure.y * go.length)
                local head = v2.mk(x, y)

                line(tail.x, tail.y, head.x, head.y, go.colour2)

                if go.speed >= 0 then
                    circfill(head.x, head.y, max(1, go.size / 2.0), go.colour1)
                else
                    circfill(tail.x, tail.y, max(1, go.size / 2.0), go.colour1)
                end
            end
        end

        f.lure_dist = function(self, lure)
            local d = lure.v2_pos(lure) - self.v2_pos(self)
            return v2.mag(d)
        end

        f.interest = function(self)
            matches = 0
            if self.target == nil then
                matches = 0
            else
                if self.target.colour == self.colour1 then
                    matches += 1
                elseif self.target.colour == self.colour2 then
                    matches += 1
                end
                if self.size - self.target.size >= 0 and self.size - self.target.size <= 2 then
                    matches += 1
                end
            end
            return matches
        end

        f.update = function(self)
            if self.target ~= nil then
                local d = self.target.v2_pos(self.target) - self.v2_pos(self)
                local dist = v2.mag(d)
                self.dir_to_lure = v2.norm(d)

                self.speed = self.max_speed
                local interest = self.interest(self)
                if interest == 0 then
                    self.speed *= -1.0
                elseif interest == 1 then
                    self.speed *= 0.0
                elseif interest == 2 then
                    self.speed *= 0.6
                elseif interest == 3 then
                    self.speed *= 1.0
                end

                local new_pos = self.v2_pos(self) + self.dir_to_lure * self.speed
                self.x = new_pos.x
                self.y = new_pos.y
            end
        end

        return f
    end,
}

return fish
