local level = {
    mk = function(max_fish, init_fish, target_colour, target_count)
        local l = {
            max_fish = max_fish,
            init_fish = init_fish,
            target_colour = target_colour,
            target_count = target_count,
        }

        l.is_good_catch = function(self, lure, fish)
            if fish.colour1 == self.target_colour then
                return true
            else
                return false
            end
        end

        return l
    end,
}

return level
