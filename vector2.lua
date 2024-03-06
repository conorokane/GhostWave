-- 2d vector math
-- assumes vectors are in the form v = { x = 0, y = 0}

-- use this to create a vector 2
function v2make(_x, _y)
	return { x = _x, y = _y }
end

v2zero, v2up, v2down, v2left, v2right = v2make(0, 0), v2make(0, -1), v2make(0, 1), v2make(-1, 0), v2make(1, 0)
-- don't assign variables to be equal to these vectors, that will link them both ways!
-- a = v2zero is the same as v2zero = a
-- only use these for comparison

function v2length(v)
	return sqrt(v.x * v.x + v.y * v.y)
end

-- a quick way to check length without a square-root
-- function v2squarelength(v)
-- 	return v.x * v.x + v.y * v.y
-- end

-- function v2dot(v1, v2)
-- 	return (v1.x * v2.x + v1.y * v2.y)
-- end

function v2normalize(v)
	return v2scale(v, 1 / v2length(v))
end

function v2scale(v, amount)
	return v2make(v.x * amount, v.y * amount)
end

function v2add(v1, v2)
	return v2make(v1.x + v2.x, v1.y + v2.y)
end

-- subtract v2 from v1
function v2sub(v1, v2)
	return v2make(v1.x - v2.x, v1.y - v2.y)
end

function v2rotate(v, angle)
	local x2 = cos(angle) * v.x - sin(angle) * v.y
	local y2 = sin(angle) * v.x + cos(angle) * v.y
	return {x = x2, y = y2}
end

-- returns a random unit-length vector
function v2randomnormalized()
	local angle = rnd(1) -- pico-8 angles go from 0 to 1 (turns), starting at 3 o'clock going anti-clockwise
	return v2make(cos(angle), sin(angle))
end

-- returns a random unit-length vector between min and max angle.
-- Zero is 3 o'clock, angles increase anti-clockwise, inputs are in degrees
function v2randominrange(min, max)
	if (min > max) min -= 360
	min = min / 360
	max = max / 360
	local randomangle = min + rnd(abs(max - min))
	return v2make(cos(randomangle), sin(randomangle))
end

-- a quick way to check if 2 points are close, returns true if p2 is within p1's bounding box distance
function v2proximity(p1, p2, distance)
	if abs(p1.x - p2.x) > distance then
		return false
	elseif abs(p1.y - p2.y) > distance then
		return false
	else
		return true
	end
end

function v2lerp(v1, v2, t)
	return v2make(lerp(v1.x, v2.x, t), lerp(v1.y, v2.y, t))
end

-- simulate a particle
-- requires a particle p = { life = 0, pos = v2zero, vel = v2zero, drag = 1 (no drag), force = v2zero (optional) }
function v2simulate(p)
	if p.force then
		p.vel = v2scale(v2add(p.vel, p.force), p.drag)
	else
		p.vel = v2scale(p.vel, p.drag)
	end
	p.pos = v2add(p.pos, p.vel)
	if (p.life)	p.life += 1
end

-- fast simulation for bullets with no drag, force
function v2simulatefast(p)
	p.pos = v2add(p.pos, p.vel)
	if (p.life)	p.life += 1
end