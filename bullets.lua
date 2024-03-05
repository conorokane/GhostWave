-- everything to do with bullets

function initbullets()
	hiteffects, sparks, enemybullets = {}, {}, {}
end

function updatebullets()
	for b in all(playerbullets) do
		v2simulatefast(b)
		if (b.pos.y < -15) del(playerbullets, b)

		-- === player bullet collision === --
		for e in all(enemies) do
			if e.pos.y > 0 and v2proximity(b.pos, e.pos, e.size) then -- hit
				local flipx = rnd(1) < 0.5
				newhit = { pos = b.pos, life = 0, flipx }
				newhit.pos.x += -3 + rnd(6)
				newhit.pos.y += 8
				add(hiteffects, newhit)
				for i=1, 2 do -- 2 sparks per hit
					local newspark = {
						pos = newhit.pos,
						life = 0,
						vel = v2scale(v2randominrange(240, 300), 0.5 + rnd(2)),
						drag = 0.95,
					}
					newspark.pos.y -= rndrange(4, 6)
					add(sparks, newspark)
				end
				del(playerbullets, b)
				if (e.type != 5 or (e.type == 5 and not e.invulnerable)) takedamage(e, 1, 6)
			end
		end
	end

	for c in all(playercases) do
		v2simulate(c)
		if (c.life == 30) del(playercases, c)
	end

	for s in all(sparks) do
		v2simulate(s)
		if (s.life) == 15 del(sparks, s)
	end

	for r in all(playerrockets) do
		v2simulate(r)
		-- smoke
		local newsmoke = {
			life = rnd(10),
			pos = v2add(r.pos, v2scale(v2randomnormalized(), rnd(3))),
			vel = v2scale(v2randomnormalized(), 0.1),
			force = v2scale(v2down, rndrange(0.01, 0.04)),
			drag = 0.95,
		}
		newsmoke.pos.y += 10
		add(smoke, newsmoke)

		if (r.pos.y < -10) del(playerrockets, r)
		
		-- rocket collision
		for e in all(enemies) do
			if v2proximity(r.pos, e.pos, e.size + 2) then
				local exp = { pos = v2make(r.pos.x, r.pos.y), life = 0 }
				add(rocketexplosions, exp) -- the explosion will damage enemies
				for i = 0, 5 do -- fire and smoke
					createexplosionfire(r.pos, false)
				end
				for i = 0, 20 do -- sparks
					local newspark = {
						pos = r.pos,
						life = -15,
						vel = v2scale(v2randomnormalized(), 0.5 + rnd(3)),
						drag = 0.95,
					}
					add(sparks, newspark)
				end
				del(playerrockets, r)
			end
		end
	end
	
	for b in all(enemybullets) do
		if v2proximity(b.pos, playerpos, b.size) then -- hit player
			loselife()
			del(enemybullets, b)
		else
			if b.drag then
				v2simulate(b)
			else
				v2simulatefast(b)
			end
			-- cull bullets
			if (b.pos.x > 138 or b.pos.x < -10 or b.pos.y > 138 or b.pos.y < -10) del(enemybullets, b)
		end
	end
end

function createexplosionfire(pos, _forplayerdeath)
	local expfire = {
		pos = v2add(pos, v2scale(v2randomnormalized(), rndrange(2, 5))),
		vel = v2scale(v2randominrange(60, 120), rndrange(1, 2)),
		drag = 0.95,
		life = rndrange(-15, 5),
		flipx = rnd(1) < 0.5,
		flipy = rnd(1) < 0.5,
		forplayerdeath = _forplayerdeath
	}
	if (_forplayerdeath) expfire.vel = v2scale(v2randominrange(140, 300), rndrange(1, 2))
	add(explosionfire, expfire)
end

function spawncase (position, velocity)
	local case = {}
	do
		local _ENV = case
		life, pos, vel, drag, force = 0, position, velocity, 0.85
	end
	case.force = v2make(0, 0.07)
	case.pos.y -= 4 -- to align better with the gun position
	return case
end

function drawplayerbullets()
	-- bullets
	for b in all(playerbullets) do
		local bsprite = 3
		if (b.life > 2) bsprite = 4
		if (b.life > 4) bsprite = 5
		spr(bsprite, b.pos.x - 4, b.pos.y - 8, 1, 2)
	end

	-- rockets
	for r in all(playerrockets) do
		spr(22, r.pos.x - 4, r.pos.y - 4)
		if (t % 4) / 2 == 0 then
			circfill(r.pos.x - 1, r.pos.y + 6, 2, 10)
		end
	end
	
	-- hit effects
	for h in all(hiteffects) do
		if h.life < 3 then
			spr(10, h.pos.x - 4, h.pos.y - 4, 1, 1, h.flipx)
			h.pos.y -= 2
		elseif h.life < 6 then
			spr(11, h.pos.x - 4, h.pos.y - 4, 1, 1, h.flipx)
			h.pos.y -= 1
		else
			del(hiteffects, h)
		end
		h.life += 1
	end

	-- sparks
	for s in all(sparks) do
		for i = 0, 5 do -- draw many sparks for a trail
			local offset = v2scale(s.vel, i * 0.5)
			pset(s.pos.x + offset.x, s.pos.y + offset.y, 15)
		end
	end
end

function drawshellcases()
	for c in all(playercases) do
		if c.life < 20 then
			pset(c.pos.x, c.pos.y, 9)
		else
			pset(c.pos.x, c.pos.y, 5)
		end
	end
end

function drawenemybullets()
	for b in all(enemybullets) do
		circfill(b.pos.x, b.pos.y, b.size + 1, 2) -- outline
	end

	for b in all(enemybullets) do
		circfill(b.pos.x, b.pos.y, b.size, b.color) -- fill
		pset(b.pos.x - 1, b.pos.y - 1, 7) -- highlight
	end
end