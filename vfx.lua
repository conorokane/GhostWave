function initvfx()
	smokefills, firefills, smoke, fires, wind, rocketexplosions, explosionfire, gibs, bigtrails, enemysplats, ghosttrails, hudsize, hudspeed, hudcolor = split("0b1010111110101111.1, 0b1011111110101111.1, 0b1011111111101111.1, 0b1011111111111111.1"), split("0b1111010111110101.1,	0b1111010111111101.1, 0b1111011111111101.1,	0b1111011111111111.1"), {}, {}, v2make(0, 0), {}, {}, {}, {}, {}, {}, 12, 0.5, 180
end

function updatevfx()
	wind.x = sin(time() / 20) / 15
	wind.y = cos(time() / 25) / 20

	for s in all(smoke) do
		v2simulate(s)
		s.force = v2add(s.force, v2scale(v2randomnormalized(), 0.004)) -- turbulence
		s.vel = v2add(s.vel, wind) -- add wind
		if (s.life > 50) del(smoke, s)
	end

	for f in all(fires) do
		v2simulate(f)
		f.vel = v2add(f.vel, wind) -- add wind
		if (f.life > 90) del(fires, f)
	end

	for f in all(explosionfire) do
		v2simulate(f)
		if (f.life > 55) del(explosionfire, f)
	end

	for exp in all(rocketexplosions) do
		if exp.life == 0 and not exp.forplayerdeath then -- look for nearby enemies to damage
			-- damage nearby enemies
			for e in all(enemies) do
				if e.pos.y > 0 and v2proximity(exp.pos, e.pos, 30) then
					if (e.type != 5 or (e.type == 5 and not e.invulnerable)) takedamage(e, 20, 25)
				end
			end
		end
		exp.life += 1
		if (exp.life > 40) del(rocketexplosions, exp)
	end

	for g in all(gibs) do
		v2simulate(g)
		if t % 5 == 0 then
			local newgibtrail = {
				pos = g.pos,
				life = rndrange(-5, 0),
			}
			add(gibtrails, newgibtrail)
		end
		if (g.life > 40) del(gibs, g)
	end

	for gt in all(gibtrails) do
		gt.life += 1
		gt.pos.y += 0.3
		if (gt.life > 20) del(gibtrails, gt)
	end

	for splat in all(enemysplats) do
		splat.life += 1
		if (splat.life > 10) then
			del(enemysplats, splat)
		else
			splat.pos.y -= 4
		end
	end
end

function drawuppervfx() -- visual effects that draw above the enemies
	-- rocket trails
	local smokesize = 6
	for s in all(smoke) do
		if s.life < 10 then 
			fillp(smokefills[1])
		elseif s.life < 20 then
			fillp(smokefills[2])
			smokesize = 5
		elseif s.life < 30 then
			fillp(smokefills[3])
			smokesize = 4
		else
			fillp(smokefills[4])
			smokesize = 3
		end
		circfill(s.pos.x, s.pos.y, smokesize, 15)
	end
	
	-- gibtrails & gibs
	fillp()
	for gt in all(gibtrails) do
		local gibsize, gibcolor = 3, 11
		if (gt.life > 15) then
		 	gibcolor = 13 gibsize = 2
		elseif (gt.life > 15) then
			gibcolor = 12 gibsize = 2
		elseif (gt.life > 5) then
			gibsize = 2
		end
		circfill(gt.pos.x, gt.pos.y, gibsize, gibcolor)
	end

	for g in all(gibs) do
		spr(g.sprite, g.pos.x - 4, g.pos.y - 4, 1, 1, g.flipx)
	end
	
	

	-- explosions
	fillp()
	for exp in all(rocketexplosions) do
		local flashcolor = 7
		if exp.life < 8 then
			if (exp.life > 4) flashcolor = 15
			circfill(exp.pos.x, exp.pos.y, 20 - exp.life * 2, flashcolor) -- flash
			oval(exp.pos.x - exp.life * 5, exp.pos.y - exp.life * 3, exp.pos.x + exp.life * 5, exp.pos.y + exp.life * 3, 7)
		end
	end

	for f in all(explosionfire) do
		if f.life < 5 then
			spr(12, f.pos.x - 8, f.pos.y - 8, 2, 2, f.flipx, f.flipy)
		elseif f.life < 15 then
			spr(14, f.pos.x - 8, f.pos.y - 8, 2, 2, f.flipx, f.flipy)
		elseif f.life < 25 then
			spr(44, f.pos.x - 8, f.pos.y - 8, 2, 2, f.flipx, f.flipy)
		elseif f.life < 35 then
			fillp(0b1010111110101111.1)
			circfill(f.pos.x, f.pos.y, 6, 5)
			fillp()
		else
			fillp(0b1010111110101111.1)
			circfill(f.pos.x, f.pos.y, 6, 2)
			fillp()
		end
	end

	-- enemy splats
	for es in all(enemysplats) do
		local splatcolor = 4
		if (rnd(1) < 0.5) splatcolor = 11
		local splatsize = min(rndrange(es.size * 4, es.size * 6), 15)
		if (es.life > 7) fillp(░)
		circfill(es.pos.x + rndrange(-3, 3), es.pos.y + rndrange(-3, 3), splatsize, splatcolor)
	end
	fillp()
end

function drawlowervfx() -- visual effects that draw below the enemies
	-- fires
	for f in all(fires) do
		local firesize = rndrange(0.7, 1.1)
		local firecolor = 10 -- yellow
		if f.life < 5 then
			fillp() -- no fill pattern
		elseif f.life < 15 then
			fillp(firefills[1])
			firesize, firecolor = 2, 9
		elseif f.life < 22 then
			fillp(firefills[1])
			firesize, firecolor = 4, 8
		elseif f.life < 40 then
			fillp(firefills[1])
			firesize, firecolor = 8, 1
		elseif f.life < 60 then
			fillp(firefills[2])
			firesize, firecolor = 8, 1
		elseif f.life < 75 then
			fillp(firefills[3])
			firesize, firecolor = 10, 1
		else
			fillp(firefills[4])
			firesize, firecolor = 15, 1
		end
		circfill(f.pos.x, f.pos.y, firesize, firecolor)
	end
end