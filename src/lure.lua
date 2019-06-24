game_obj = require('game_obj')
renderer = require('renderer')

local lure = {
    mk = function(name, x, y, colour)
        local l = game_obj.mk(name, 'lure', x, y)
        l.size = 5
        l.colour = colour

        renderer.attach(l, 0)
        l.renderable.render = function(r, x, y)
            local go = r.game_obj
            circfill(x, y, go.radius(go), go.colour)
        end

        l.radius = function(self)
            return self.size / 2
        end

        return l
    end,
}

return lure
