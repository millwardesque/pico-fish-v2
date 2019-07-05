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

        renderer.attach(l, 1)
        l.renderable.palette = {0,1,2,3,4,dark_pal[l.colour],l.colour,7,8,9,10,11,12,13,14,15}

        l.renderable.render = function(r, x, y)
            line(62, 0, x, y, 12)

            r.default_render(r, x - 4, y - 4)
        end

        l.update = function(self)
            if self.is_pulsing then
                self.pulse_timer -= 1
                if self.pulse_timer == 0 then
                    self.renderable.palette = {0,1,2,3,4,dark_pal[self.colour],self.colour,7,8,9,10,11,12,13,14,15}
                    self.is_pulsing = false
                end
            else
                self.pulse_timer += 1
                if self.pulse_timer == self.pulse_wait then
                    self.renderable.palette = {0,1,2,3,4,self.colour,self.colour,7,8,9,10,11,12,13,14,15}
                    self.is_pulsing = true
                end
            end
        end

        l.radius = function(self)
            return self.size / 2
        end

        return l
    end,
}

return lure
