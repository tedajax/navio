require 'camera'
require 'lander'
require 'collision'
require 'input'
local json = require 'json'
local Vec2 = require 'vec2'

function love.load()
    Game = {}

    Game.config = json.load("gameconfig.json")

    Game.input = InputManager(Game.config.input)

    Game.collision = CollisionManager(Game.config.physics)

    local groundBody = love.physics.newBody(Game.collision.world)
    local w = love.graphics.getWidth() / 2
    local h = love.graphics.getHeight() / 2
    local groundShape = love.physics.newEdgeShape(-w, h, w, h)
    local groundFixture = love.physics.newFixture(groundBody, groundShape)

    for i = 1, 5 do
        local b = love.physics.newBody(Game.collision.world)
        local x = math.random(-w, w)
        local y = math.random(-h, h)
        local w = math.random(50, 250)
        local s = love.physics.newEdgeShape(x, y, x + w, y)
        love.physics.newFixture(b, s)
    end

    Game.camera = Camera()
    Game.lander = Lander(Vec2(0, 0), Game.config.lander, Game.collision)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    Game.input:keypressed(key)
end

function love.keyreleased(key)
    Game.input:keyreleased(key)
end

function love.mousepressed(x, y, button)
    Game.input:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    Game.input:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    Game.input:mousemoved(x, y, dx, dy)
end

function love.update(dt)
    Game.input:update(dt)
    Game.collision:update(dt)
    Game.lander:update(dt)
end

function love.draw()
    Game.camera:push()

    Game.lander:render()

    Game.collision:render_debug()

    Game.camera:pop()

    love.graphics.setColor(0, 255, 0)
    love.graphics.print("FPS: "..love.timer.getFPS(), 5, 5)
end