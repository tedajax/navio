local Class = require 'class'
local Vec2 = require 'vec2'

Lander = Class {}

function Lander:init(position, config, collision)
    self.position = position:clone()
    self.width = config.width
    self.height = config.height

    self.thrust = Vec2(config.thrust.x, config.thrust.y)

    self.body = love.physics.newBody(collision.world, 0, 0, "dynamic")
    self.body:setPosition(self.position.x, self.position.y)
    self.body:setMass(config.mass)
    self.body:setFixedRotation(true)

    self.shape = love.physics.newRectangleShape(self.width, self.height)

    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setUserData(self)
    self.fixture:setFilterData(collision:get_filter("lander"):unpack())
end

function Lander:set_position(position)
    self.body:setPosition(position.x, position.y)
    self.position = position:clone()
end

function Lander:update(dt)
    self.position.x, self.position.y = self.body:getPosition()

    local horizontal = Game.input:get_axis("horizontal")
    local vertical = Game.input:get_axis("vertical")

    local force = Vec2(
        self.thrust.x * horizontal,
        self.thrust.y * vertical
    )

    self.body:applyForce(force.x, force.y)
end

function Lander:render()
    local w, h = self.width / 2, self.height / 2
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("fill", self.position.x - w, self.position.y - h, self.width, self.height)
end