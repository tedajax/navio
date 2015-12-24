local Class = require 'class'
local Vec2 = require 'vec2'

Camera = Class {}

function Camera:init()
    self.position = Vec2(0, 0)
    self.rotation = 0
    self.scale = 1

    self.xTween = nil
    self.yTween = nil
    self.rTween = nil
    self.sTween = nil
end

function Camera:move(x, y)
    local x = x or 0
    local y = y or 0
    self.position.x = self.position.x + x
    self.position.y = self.position.y + y
end

function Camera:look_at(x, y)
    self.position.x = x
    self.position.y = y
end

function Camera:rotate(degrees)
    self.rotation = self.rotation + degrees
end

function Camera:set_rotation(degrees)
    self.rotation = degrees
end

function Camera:zoom(amount)
    self.scale = self.scale + amount
end

function Camera:set_zoom(scale)
    self.scale = scale
end

function Camera:shake(time, magnitude)
    self.xTween = Tween.add(-magnitude, magnitude, time, Tween.functions.random, { count = 1 })
    self.yTween = Tween.add(-magnitude, magnitude, time, Tween.functions.random, { count = 1 })
end

function Camera:push()
    love.graphics.push()

    love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)

    local r = self.rotation
    if self.rTween ~= nil then
        r = r + self.rTween:evaluate()
    end
    love.graphics.rotate(-math.rad(r))


    local s = self.scale
    if self.sTween ~= nil then
        s = s + self.sTween:evaluate()
    end
    love.graphics.scale(s, s)

    local x, y = self.position.x, self.position.y
    if self.xTween ~= nil then
        x = x + self.xTween:evaluate()
    end
    if self.yTween ~= nil then
        y = y + self.yTween:evaluate()
    end
    love.graphics.translate(-x, -y)
end

function Camera:pop()
    love.graphics.pop()
end