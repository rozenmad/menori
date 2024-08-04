function love.conf(t)
    t.window.width = 960
    t.window.height = 480
    if love._version_major > 11 then
        t.window.depth = true
    else
        t.window.depth = 24
    end
    t.window.title = "Menori Examples"
    t.window.vsync = true
    t.highdpi = true
    t.window.fullscreen = false
end
