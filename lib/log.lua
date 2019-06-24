local log = {
    debug = true,
    file = 'debug.log',
    _data = {},

    log = function(msg)
        add(log._data, msg)
    end,
    syslog = function(msg)
        printh(msg, log.file)
    end,
    render = function()
        if log.debug then
            color(7)
            for i = 1, #log._data do
                print(log._data[i], 5, 5 + (8 * (i - 1)))
            end
        end

        log._data = {}
    end,
}
return log
