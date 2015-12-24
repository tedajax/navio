local Class = require 'class'
require 'mathx'

gValidateInputData = true

InputBinding = Class {}

function InputBinding:init(config)
    self.type = config.type
    self.name = config.name
    self.device = config.device
    self.value = config.value

    if self.device == "keyboard" then
        self.key = config.key
    elseif self.device == "mousebutton" then
        self.button = config.button
    elseif self.device == "mouseposition" then
        assert(config.mouse_axis == "x" or config.mouse_axis == "y", "Unknown mouse axis: "..config.mouse_axis)
        self.mouseAxis = config.mouse_axis
    elseif self.device == "mousemove" then
        assert(config.mouse_axis == "x" or config.mouse_axis == "y", "Unknown mouse axis: "..config.mouse_axis)
        self.mouseAxis = config.mouse_axis
    else
        assert(false, "Unknown binding device type: "..self.device)
    end
end

function InputBinding:get_value(inputState)
    if self.device == "keyboard" then
        if inputState.keys[self.key] then
            return true, self.value
        end
    elseif self.device == "mousebutton" then
        if inputState.mouse.buttons[self.button] then
            return true, self.value
        end
    elseif self.device == "mouseposition" then
        if self.mouseAxis == "x" then
            local x = inputState.mouse.x
            local w = love.graphics.getWidth()
            x = x / (w / 2) - 1
            return true, self.value * x
        elseif self.mouseAxis == "y" then
            local y = inputState.mouse.y
            local h = love.graphics.getHeight()
            y = y / (h / 2) - 1
            return true, self.value * y
        end
    elseif self.device == "mousemove" then
        if self.mouseAxis == "x" then
            return true, self.value * inputState.mouse.dx
        elseif self.mouseAxis == "y" then
            return true, self.value * inputState.mouse.dy
        end
    end

    return false, 0
end

InputState = Class {}

function InputState:init()
    self.keys = {}
    self.mouse = { x = 0, y = 0, dx = 0, dy = 0, buttons = {} }
end

InputManager = Class {}

function InputManager:init(config)
    self.axes = {}
    self.buttons = {}

    self.bindings = {}

    for name, axis in pairs(config.axes) do
        self.axes[name] = InputAxis(axis)
    end

    for name, button in pairs(config.buttons) do
        self.buttons[name] = InputButton(button)
    end

    for _, binding in ipairs(config.bindings) do
        table.insert(self.bindings, InputBinding(binding))
    end

    self.state = InputState()
end

function InputManager:keypressed(key)
    self.state.keys[key] = true
end

function InputManager:keyreleased(key)
    self.state.keys[key] = false
end

function InputManager:mousepressed(x, y, button)
    self.state.mouse.x = x
    self.state.mouse.y = y
    self.state.mouse.buttons[button] = true
end

function InputManager:mousereleased(x, y, button)
    self.state.mouse.x = x
    self.state.mouse.y = y
    self.state.mouse.buttons[button] = false
end

function InputManager:mousemoved(x, y, dx, dy)
    self.state.mouse.x = x
    self.state.mouse.y = y
    self.state.mouse.dx = dx
    self.state.mouse.dy = dy
end

function InputManager:update(dt)
    for _, axis in pairs(self.axes) do
        axis:reset_value()
    end

    for _, button in pairs(self.buttons) do
        button:reset_value()
    end

    for _, binding in ipairs(self.bindings) do
        local hasValue, value = binding:get_value(self.state)

        if hasValue then
            if binding.type == "axis" then
                local axis = self.axes[binding.name]
                assert(axis ~= nil, "Unable to find axis: "..binding.name)
                axis.value = axis.value + value
                axis.value = math.clamp(axis.value, axis.min, axis.max)
            elseif binding.type == "button" then
                local button = self.buttons[binding.name]
                assert(button ~= nil, "Unable to find button: "..binding.name)
                if value ~= buttonn.base_value then
                    button.base_value = value
                end
            end
        end
    end
end

function InputManager:get_axis(name)
    return self.axes[name]:get_value()
end

function InputManager:get_button(name)
    return self.buttons[name]:get_value()
end

function InputManager:add_binding(binding)
    if gValidateInputData then
        if binding.type == "axis" then
            assert(self.axes[binding.name] ~= nil, "Unknown axis: "..binding.name)
        elseif binding.type == "button" then
            assert(self.buttons[binding.name] ~= nil, "Unkown button: "..binding.name)
        else
            assert(false, "Unknown binding type: "..binding.type)
        end
    end

    table.insert(self.bindings, binding)
end

InputAxis = Class {}

function InputAxis:init(name, config)
    self.name = name

    local config = config or {}

    self.baseValue = config.base_value or 0
    self.min = config.min or -1
    self.max = config.max or 1
    self.deadZone = config.dead_zone or 0

    self.deadMin = self.baseValue - self.deadZone
    self.deadMax = self.baseValue + self.deadZone

    self.value = self.baseValue
end

function InputAxis:reset_value()
    self.value = self.baseValue
end

function InputAxis:get_value()
    if self.value >= self.deadMin and self.value <= self.deadMax then
        return self.baseValue
    else
        return self.value
    end
end

InputButton = Class {}

function InputButton:init(name, config)
    self.name = name

    self.baseValue = config.base_value

    self.value = self.baseValue
end

function InputButton:reset_value()
    self.value = self.baseValue
end

function InputButton:get_value()
    return self.value
end