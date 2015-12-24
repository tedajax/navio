-- Math extensions

function math.lerp(a, b, t)
    return a + (b - a) * t
end

function math.clamp(a, min, max)
    if a < min then return min end
    if a > max then return max end
    return a
end