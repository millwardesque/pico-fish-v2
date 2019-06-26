game_obj = require('game_obj')
renderer = require('renderer')
v2 = require('v2')

local fish = {
    mk = function(name, x, y, colour, size)
        local f = game_obj.mk(name, 'fish', x, y)
        f.target = nil
        f.dir = v2.norm(v2.mk(x + 1, y))
        f.speed = 1 * (0.5 + rnd(1))
        f.length = size
        f.size = size
        f.colour = colour

        if f.size >= 7 then
            f.speed *= 0.75
        elseif f.size < 3 then
            f.speed *= 1.25
        end

        renderer.attach(f, 0)
        f.renderable.render = function(r, x, y)
            local go = r.game_obj
            circfill(x, y, max(1, go.size / 2.0), go.colour)
            line(x - go.dir.x * go.length, y - go.dir.y * go.length, x, y, go.colour)
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
                if self.target.colour == self.colour then
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
                self.dir = v2.norm(d)

                local speed = self.speed
                local interest = self.interest(self)
                if interest == 0 then
                    speed *= -1.0
                elseif interest == 1 then
                    speed *= 0
                elseif interest == 2 then
                    speed *= 1
                end

                local new_pos = self.v2_pos(self) + self.dir * speed
                self.x = new_pos.x
                self.y = new_pos.y
            end
        end

        return f
    end,
}

return fish
