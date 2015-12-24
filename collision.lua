local Class = require 'class'

CollisionFilter = Class {}

function CollisionFilter:init(category, mask, group)
    self.category = category
    self.mask = mask
    self.group = group
end

function CollisionFilter:collides_with(other)
    local c1, m1, g1 = self.category, self.mask, self.group
    local c2, m2, g2 = other.category, other.mask, other.group

    if g1 == g2 and g1 ~= 0 then
        if g1 > 0 then
            return true
        else
            return false
        end
    end

    return bit.band(m1, c2) > 0 and bit.band(m2, 1) > 0
end

function CollisionFilter:get_mask(...)
    local arg = { ... }
    local mask = self.category
    for _, filter in ipairs(arg) do
        mask = mask + filter.category
    end
    return mask
end

function CollisionFilter:unpack()
    return self.category, self.mask, self.group
end

local function fixture_call(fixture, func, ...)
    local obj = fixture:getUserData()
    if type(obj) == "table" then
        if type(obj[func]) == "function" then
            obj[func](obj, ...)
        end
    end
end

local function on_begin(a, b, coll)
    fixture_call(a, "on_collision_begin", b, coll)
    fixture_call(b, "on_collision_begin", a, coll)
end

local function on_end(a, b, coll)
    fixture_call(a, "on_collision_end", b, coll)
    fixture_call(b, "on_collision_end", a, coll)
end

local function on_pre_solve(a, b, coll)
end

local function on_post_solve(a, b, coll, normal1, tangent1, normal2, tangent2)
end

CollisionManager = Class {}

function CollisionManager:init(config)
    love.physics.setMeter(config.meter)
    self.world = love.physics.newWorld(config.gravity.x, config.gravity.y)

    self.world:setCallbacks(on_begin, on_end, on_pre_solve, on_post_solve)

    self.frameRayCasts = {}

    self.filters = {}
    self:register_filter("default", 0x0000, 0x0000, 0)

    if type(config.layers) == "table" then
        for name, layer in pairs(config.layers) do
            self:register_filter(name, unpack(layer))
        end
    end
end

function CollisionManager:register_filter(name, category, mask, group)
    assert(self.filters[name] == nil, "Filter with name \'"..name.."\' already exists!")

    self.filters[name] = CollisionFilter(category, mask, group)
end

function CollisionManager:get_filter(name)
    return self.filters[name]
end

function CollisionManager:ray_cast(start, direction, distance, mask)
    local hitList = {}

    local endpoint = start + direction * distance

    self.world:rayCast(
        start.x, start.y,
        endpoint.x, endpoint.y,
        function(fixture, x, y, xn, yn, fraction)
            if fixture:isSensor() then
                return 1
            end
            local hit = {}
            hit.position = Vec2(x, y)
            hit.normal = Vec2(xn, yn)
            hit.distance = fraction
            hit.fixture = fixture
            if mask then
                local category, _, _ = fixture:getFilterData()
                if bit.band(mask, category) > 0 then
                    table.insert(hit_list, hit)
                    return 0
                else
                    return -1
                end
            else
                table.insert(hit_list, hit)
                return -1
            end
        end
    )

    table.insert(self.frameRayCasts, { s = start, e = endpoint })

    return hitList
end

function CollisionManager:update(dt)
    self.world:update(dt)
    self.frameRayCasts = {}
end

function CollisionManager:render_debug()
    local bodies = self.world:getBodyList()
    for _, b in pairs(bodies) do
        self:draw_body(b)
    end

    love.graphics.setColor(0, 255, 255)
    for _, r in ipairs(self.frameRayCasts) do
        love.graphics.line(r.s.x, r.s.y, r.e.x, r.e.y)
    end
end

function CollisionManager:draw_body(body)
    local fixtures = body:getFixtureList()
    for _, f in pairs(fixtures) do
        if body:isActive() then
            if f:isSensor() then
                love.graphics.setColor(255, 127, 0)
            else
                love.graphics.setColor(255, 0, 255)
            end
        else
            love.graphics.setColor(127, 127, 127)
        end

        local shape = f:getShape()

        local bx = body:getX()
        local by = body:getY()

        love.graphics.push()
        love.graphics.translate(bx, by)
        love.graphics.rotate(body:getAngle())

        if shape:getType() == "circle" then
            local r = shape:getRadius()
            local cx, cy = shape:getPoint()
            love.graphics.circle("line", cx, cy, r)
        elseif shape:getType() == "polygon" then
            local points = { shape:getPoints() }
            for i = 1, #points - 2, 2 do
                love.graphics.line(
                    points[i],
                    points[i + 1],
                    points[i + 2],
                    points[i + 3]
                )
            end

            love.graphics.line(
                points[1],
                points[2],
                points[#points - 1],
                points[#points]
            )
        elseif shape:getType() == "edge" then
            local points = { shape:getPoints() }
            for i = 1, #points - 2, 2 do
                love.graphics.line(
                    points[i],
                    points[i + 1],
                    points[i + 2],
                    points[i + 3]
                )
            end

            love.graphics.line(
                points[1],
                points[2],
                points[#points - 1],
                points[#points]
            )

            for i = 1, #points, 2 do
                love.graphics.circle("fill", points[i], points[i + 1], 4)
            end

        elseif shape:getType() == "chain" then
            local points = { shape:getPoints() }
            for i = 1, #points - 2, 2 do
                love.graphics.line(
                    points[i],
                    points[i + 1],
                    points[i + 2],
                    points[i + 3]
                )
            end


            love.graphics.line(
                points[1],
                points[2],
                points[#points - 1],
                points[#points]
            )

            for i = 1, #points, 2 do
                love.graphics.circle("fill", points[i], points[i + 1], 4)
            end
        end

        love.graphics.pop()
    end
end