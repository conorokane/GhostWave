function initenemies()
	enemies, ghosts, ghostcounter = {}, {}, 1
	-- strip the trailing | from the string
	scheduleraw = sub(scheduleraw, 1, #scheduleraw - 1)
	schedule, scindex, debugtime = split2d(scheduleraw), 1, 0
	if (debugtime > 0) then
		for i = #schedule, 1, -1 do
			if schedule[i][1] < debugtime then
				del(schedule, schedule[i])
			end
		end
	end
end

function updateenemies()
	for e in all(enemies) do
		local etype = e.type
		-- player collisions
		if v2proximity(e.pos, playerpos, e.size) then
			-- hit player
			if etype != 5 or (etype == 5 and not e.dying) then
				if not gameover and not playerdying then
					loselife()
					takedamage(e, 0, 1)
				end
			end
		end

		e.hitcounter -= 1

		if etype == 1 then
			v2simulatefast(e)
			if (e.life > 30) e.vel = v2rotate(e.vel, e.veer)
			if (e.life == 85 and e.pos.y < 70) shootsingle(e)
			if (e.life == 300) del(enemies, e)
		elseif etype == 2 then
			-- tentacles
			if e.spawning then
				-- seek destination
				e.pos = v2lerp(e.pos, e.dest, 0.035)
				if v2proximity(e.pos, e.dest, 3) then
					e.spawning = false 
					setfinaldest(e)
				end
			else
				gyrate(e, 0.3, 0.2, 0.1, 0.15)
				e.shotcounter -= 1
			end
			-- spawn blobs
			if t % 6 == 0 then
				local newblob = {
					pos = v2make(e.pos.x - 4 + rnd(6),e.pos.y - 3),
					vel = v2make(rndrange(-0.1, 0.1), 0),
					force = v2make(0, -0.005 - rnd(0.02)),
					drag = 0.95,
					life = 0
				}
				add(e.blobs, newblob)
			end

			-- update blobs
			for b in all(e.blobs) do
				v2simulate(b)
				if (b.life > 60) del(e.blobs, b)
			end

			if not e.spawning then
				if e.shottype == 1 then
					shootstream(e)
				elseif e.shottype == 2 then
					shootsshotgun(e)
				end
			end
		elseif etype == 3 then
			-- mosquito
			e.pos = v2lerp(e.pos, e.dest, 0.06)
			e.life += 1
			if e.life == 120 then
				shootsingle(e)
			elseif e.life > 120 then
				if not (playerdying) then
					-- seek player
					local toplayer = v2normalize(v2sub(playerpos, e.pos))
					e.dest = v2add(e.dest, toplayer)
				else
					e.dest.y += 1.5
				end
			end
			if (e.pos.y > 130) del(enemies, e)
		elseif etype == 4 then
			-- self-destruct tank
			e.life += 1
			e.shotcounter -= 1
			if e.life < 200 then
				-- seek destination
				e.pos = v2lerp(e.pos, e.dest, 0.02)
			elseif e.life == 200 then
				setfinaldest(e)
			else
				gyrate(e, 0.2, 0.15, 0.1, 0.01)
			end

			if e.life > 200 and e.life <= 260 then
				shoottankspread(e, false)
			end

			if e.life > 400 and e.life < 460 then
				-- vibrate arms before suicide
				if (t % 20 == 0) e.shotcounter = 10
			elseif e.life >= 460 and e.life < 520 then
				if (t % 10 == 0) e.shotcounter = 5
			elseif e.life >= 520 and e.life < 600 then
				shoottankspread(e, true)
			elseif e.life > 600 then
				takedamage(e, 0, 1)
			end
		elseif etype == 5 then 
			-- boss update
			if e.dying then
				e.life += 1
				if e.life % 30 == 0 then
					spawngiblets(e)
					sfx(6 + flr(rnd(2)))
				end
				if e.life == 181 then
					del(enemies, e)
					spawnscore(e.pos.x - e.size, e.pos.y, e.score, 7)
					victory = true
					endgame()
				end
				return
			end
			
			-- seek destination
			if e.spawning then
				e.pos = v2lerp(e.pos, e.dest, 0.013)
				if (v2proximity(e.pos, e.dest, 1.5)) then
					e.spawning = false
					e.finishedspawningtime = time()
					setfinaldest(e)
				end
			else
				gyrate(e, 0.07, 0.2, 0.05, 0.02)
				if not e.invulnerable then
					shootbosspattern(e)
				else
					e.hitpoints += e.initialhitpoints / 150
					if e.hitpoints >= e.initialhitpoints then
						e.invulnerable = false
						e.hitpoints = e.initialhitpoints
					end
				end
			end
		end
	end
end

-- set the destination for an enemy to gyrate about
function setfinaldest(e)
	e.gyratestarttime = time()
end

function updateghosts()
	for g in all(ghosts) do
		g.life += 1
		if (g.life > 180) del(ghosts, g)
		if not playerdying then
			local vectortoplayer = v2sub(playerpos, g.pos)
			local speed = 0.03 * max(0, 60 - v2length(vectortoplayer))
			g.pos = v2add(g.pos, v2scale(v2normalize(vectortoplayer), speed))
		end
		if t % 5 == 0 then
			local newghosttrail = {
				pos = v2make(g.pos.x, g.pos.y),
				life = 0,
				vel = v2scale(v2randominrange(250, 290), 0.5),
				force = v2make(0, 0.001),
				drag = 0.98,
			}
			add(ghosttrails, newghosttrail)
		end
		if v2proximity(g.pos, playerpos, 2) and not playerdying then -- hit player
			del(ghosts, g)
			ghostcounter += 1
			spawnscore(g.pos.x - 16, g.pos.y, 50 * ghostcounter, 14)
			sfx(13, 3)
		end
	end
	-- trails
	for t in all(ghosttrails) do
		v2simulate(t)
		if (t.life > 40) del(ghosttrails, t)
	end
end

function drawghosts()
	fillp()
	for g in all(ghosts) do
		circfill(g.pos.x, g.pos.y, 3, 14)
	end
	for t in all(ghosttrails) do
		size = 2
		if (t.life > 15) size = 1
		if (t.life % 6 > 1) circfill(t.pos.x, t.pos.y, size, 14)
	end
end

function drawenemies()
	-- draw blobs
	fillp()
	for e in all(enemies) do
		if e.type == 2 then
			if e.hitcounter > 0 then
				if e.bonuscountdown > 0 then
					pal(1, 10) 
				else
					pal (1, 4)
				end
			elseif e.bonuscountdown > 0 then
				pal(1, 14)
			else
				pal(1, 1)
			end
			for b in all(e.blobs) do
				local maxsize = 5
				circfill(b.pos.x, b.pos.y, maxsize - (b.life - 20) / 20, 1) -- draw outline
			end
		end
	end

	for e in all(enemies) do
		e.bonuscountdown -= 1
		if e.type == 2 then
			if (e.bonuscountdown > 0) pal(1, 8)
			for b in all(e.blobs) do
				local maxsize = 4
				local blobcolor = 12
				if (b.life > 40) blobcolor = 13 -- darker green 
				circfill(b.pos.x, b.pos.y, maxsize - (b.life - 20) / 20, blobcolor) -- fill
				circfill(b.pos.x - 1, b.pos.y - 1, maxsize - 1 - (b.life - 10) / 20, 11) -- highlight
			end
		end
	end

	for e in all(enemies) do
		local ypos, xpos, etype = e.pos.y, e.pos.x, e.type
		if e.hitcounter > 0 then
			if e.bonuscountdown > 0 then
				pal(1, 10) 
			else
				pal (1, 4)
			end
		elseif e.bonuscountdown > 0 then
			pal(1, 14)
		else
			pal(1, 1)
		end
		if e.type == 1 then
			---=== small enemies ===---
			spr(120, xpos - 8, ypos - 4, 2, 1)
			local tmod16, tailframe = t % 16, 107
			if tmod16 < 4 then
				tailframe = 74
			elseif tmod16 < 8 then
				tailframe = 75
			elseif tmod16 < 12 then
				tailframe = 106
			end
			spr(tailframe, xpos - 4, ypos - 20, 1, 2)
		elseif etype == 2 then
			---=== medium enemies ===---
			ypos -= jitter(e)
			spr(56, xpos - 8, ypos - 8, 2, 1) -- head
			local tentaclesprite = 72
			if (e.shotcounter > 0) tentaclesprite = 58
			spr(tentaclesprite, xpos - 8, ypos, 2, 1) -- tentacles
		elseif etype == 3 then
			---=== flappy enemies ===---
			ypos -= jitter(e)
			spr(46, xpos - 8, ypos - 8, 2, 2, e.flipx) 
			-- wings
			local tmod9 = t % 9
			if tmod9 < 3 then
				spr(126, xpos - 17, ypos - 4, 2, 1)
				spr(126, xpos + 1, ypos - 4, 2, 1, true)
			elseif tmod9 < 6 then
				spr(142, xpos - 17, ypos - 4, 2, 1)
				spr(142, xpos + 1, ypos - 4, 2, 1, true)
			end
		elseif etype == 4 then
			---=== tank enemies ===---
			-- color cycle
			local tmod = t % 12
			if tmod > 9 then
				pal(5, 13) pal(6, 12) pal(7, 11) pal(8, 4)
			elseif tmod > 6 then
				pal(5, 12) pal(6, 11) pal(7, 4) pal(8, 13)
			elseif tmod > 3 then
				pal(5, 11) pal(6, 4) pal(7, 13) pal(8, 12)
			else
				pal(5, 4) pal(6, 13) pal(7, 12) pal(8, 11)
			end
			ypos -= jitter(e)
			local blink = 0
			if (e.hitcounter > 0) blink = 32
			-- claws
			if e.shotcounter > 0 then
				spr(93, xpos - 26, ypos + 4, 2, 1)
				spr(93, xpos + 10, ypos + 4, 2, 1, true)
			else
				spr(95, xpos - 16, ypos + 7, 1, 2)
				spr(95, xpos + 8, ypos + 7, 1, 2, true)
			end
			-- body
			spr(108, xpos - 16, ypos - 12, 2, 3)
			spr(108, xpos, ypos - 12, 2, 3, true)
			-- eyes
			spr(159 + blink, xpos - 8, ypos + 2)
			spr(175 + blink, xpos + 1, ypos + 3)
			pal(1, 1) pal(5, 5) pal(6, 6) pal(7, 7) pal(8, 8)
		elseif etype == 5 then
			---=== BIG BOSS draw ===---
			ypos -= jitter(e)
			-- tentacle animation
			spriteframe = 0
			if (t % 9 > 2) spriteframe = 1
			if (t % 9 > 5) spriteframe = 2
			spr(128 + spriteframe * 4, xpos, ypos - 20, 4, 6)
			spr(136 - spriteframe * 4, xpos - 32, ypos - 20, 4, 6, true)
			-- boss body
			spr(156, xpos, ypos - 20, 3, 5)
			spr(156, xpos - 24, ypos - 20, 3, 5, true)
			-- health bar
			if not e.dying and not e.spawning then
				rectfill(8, 10, 120, 12, 3)
				local healthbarcolor = 12
				if (e.lifestage == 1) healthbarcolor = 11
				if (e.lifestage == 2) healthbarcolor = 4
				local healthfraction = e.hitpoints / e.initialhitpoints
				rectfill(64 - (56 * healthfraction), 10, 64 + (56 * healthfraction), 12, healthbarcolor) 
			elseif e.dying then
				-- shrinking health bar frame
				if e.life < 56 then
					rectfill(8 + 56 * (e.life / 56), 10, 120 - 56 * (e.life / 56), 12, 3)
				end
			end
			if e.spawning then
				for i = 0, 200, 200 do
					if (t % 30 > 3) printshadow("\14 warning! giant alien approaching!", i - t * 1.2 % 200, 50, 4)
					if (t % 30 == 4) sfx(14)
				end
			end
		end
	end
	pal(1, 1)
end

function jitter(e)
	if e.hitcounter > 0 then
		return rndrange(1, 3)
	else
		return 0
	end
end

function shootstream(enemy)
	if (playerdying or gameover) return
	local tmod = t % 240
	if tmod > 80 and tmod < 100 or tmod > 140 and tmod < 160 then
		if t % 4 == 0 then
			enemy.shotcounter = 10
			local shotvector = v2scale(v2normalize(v2sub(playerpos, enemy.pos)), 1.5)
			local newbullet = {
				pos = enemy.pos,
				vel = shotvector,
				color = 9,
				size = 2
			}
			add(enemybullets, newbullet)
			sfx(9, 2)
		end
	end
end

function shootsshotgun(enemy)
	if (playerdying or gameover) return
	if t % 240 == 0 then
		enemy.shotcounter = 10
		for i = 0, 5 do
			local shotangle = 0.7
			if (i % 2 == 0) shotangle = 0.8
			local shotvector = v2make(cos(shotangle), sin(shotangle))
			shotvector = v2scale(shotvector, 1.2 + 0.1 * (i \ 2))
			local newbullet = {
				pos = enemy.pos,
				vel = shotvector,
				drag = 0.995,
				color = 8,
				size = 2
			}
			add(enemybullets, newbullet)
		end
		sfx(9, 2)
	end
end

function shoottankspread(enemy, suicideshot)
	if (playerdying or gameover) return
	local shottime = 10
	if t % shottime == 0 then
		if suicideshot then
			shottime = 7
			sfx(11, 2)
		else
			sfx(10, 2)
		end
		enemy.shotcounter = 10
		for i = 0, 6 do
			local shotangle = 1 / 6 * i
			if (suicideshot) shotangle += t / 200 
			local shotvector = v2make(cos(shotangle), sin(shotangle))
			local newbullet = {
				pos = v2make(enemy.pos.x, enemy.pos.y + 8),
				vel = shotvector,
				drag = 1,
				color = 8,
				size = 3
			}
			add(enemybullets, newbullet)
		end
	end
end

function bossbullet(enemy, spacing, count, offset, _size, speed)
	for i = 0, count - 1 do
		local newbullet = {
			vel = v2make(cos(time() / spacing + i / count + offset) * speed, sin(time() / spacing + i / count + offset) * speed),
			color = 9,
			size = _size
		}
		newbullet.pos = v2add(v2make(enemy.pos.x, enemy.pos.y + 8), v2scale(newbullet.vel, 10))
		add(enemybullets, newbullet)
	end
end

function shootbosspattern(enemy)
	if (playerdying or gameover) return
	if (t % 300 == 0) spawnghost(v2make(enemy.pos.x, enemy.pos.y + 30))

	if enemy.lifestage == 0 then
		-- easy pattern
		if t % 5 == 0 and t % 50 > 30 then -- small bullets
			bossbullet(enemy, 4.5, 6, 0, 2, 0.6)
			bossbullet(enemy, 4.5, 6, 0.01, 2, 0.63)
			bossbullet(enemy, 4.5, 6, 0.02, 2, 0.66)
		end
		if t % 80 == 0 or t % 160 == 10 or t % 160 == 20 then -- aimed shot
			shootsingle(enemy)
		end
	elseif enemy.lifestage == 1 then
		-- middle pattern
		if t % 5 == 0 and t % 100 < 80 then
			bossbullet(enemy, 12, 4, 0, 2, 0.4 + (t % 100) * 0.005)
		end
		if t % 15 == 0 and t % 100 > 10 then
			sfx(10, 2)
			bossbullet(enemy, -10, 4, 0, 2, 0.6)

		end
	else
		-- hard pattern
		if t % 7 == 0 and t % 42 > 13 then -- small bullets
			enemy.shotcounter = 10
			bossbullet(enemy, 15, 5, 0.05, 2, 0.7)
			bossbullet(enemy, 15, 5, -0.05, 2, 0.7)
		end
		if t % 40 == 0 then -- fat bullets
			sfx(10, 2)
			bossbullet(enemy, 15, 5, 0.005, 3, 0.68)
			bossbullet(enemy, 15, 5, -0.005, 3, 0.72)
		end
		if enemy.hitpoints < enemy.initialhitpoints / 2 and (t % 50 == 0) then 
			-- aimed shot after half health gone
			shootsingle(enemy)
		end
	end
end

function shootsingle(enemy)
	if (playerdying or gameover) return
	local bulletsource = v2make(enemy.pos.x, enemy.pos.y)
	bulletcolor = 9
	if enemy.type == 5 then
		bulletsource.y += 12 
		bulletcolor = 10
	end
	local newbullet = {
		pos = bulletsource,
		vel = v2scale(v2normalize(v2sub(playerpos, bulletsource)), 1.5),
		color = bulletcolor,
		size = 2
	}
	add(enemybullets, newbullet)
	sfx(8, 2)
end

function takedamage(e, damage, hitflash)
	e.hitpoints -= damage
	if (damage == 0 and e.type != 5) e.hitpoints = 0 -- special case when colliding with player
	if e.hitpoints <= 0 then
		if e.type == 1 then
			sfx(5, 3)
		else
			sfx(6 + flr(rnd(2)))
		end

		if (e.bonuscountdown > 0) then
			spawnghost(e.pos)
		end

		if e.type == 5 then
			e.invulnerable = true
			if e.lifestage < 2 then
				e.lifestage += 1
				spawngiblets(e)
			else
				e.dying = true
				e.hitcounter = 0
			end
		else
			spawnscore(e.pos.x - e.size, e.pos.y, e.score, 7)

			-- giblets
			spawngiblets(e)
			del(enemies, e)
		end
	else
		e.hitcounter = hitflash
	end
end

function spawnghost(_pos)
	local newghost = {
		pos = _pos,
		life = 0
	}
	add(ghosts, newghost)
end

function spawnscore(posx, posy, _score, _color)
	score += _score>>>16
	local newpoints = {
		x = posx,
		y = posy,
		value = _score,
		color = _color,
		life = 0
	}
	add(deathpoints, newpoints)
end

function spawngiblets(e)
	local gibcount, etype = e.type * 3, e.type
	if (etype == 3) gibcount = 6 
	if (etype == 4) gibcount = 16
	if (etype == 5) gibcount = 30
	for i = 1, gibcount do
		local newgib = {
			pos = v2add(e.pos, v2scale(v2randomnormalized(), rndrange(2, 5))),
			vel = v2scale(v2randominrange(40, 120), rndrange(1, 4)),
			drag = 0.95,
			force = v2make(rndrange(-0.01, 0.01), 0.03),
			life = rndrange(-10, 10),
			sprite = flr(rndrange(76, 80))
		}
		if etype == 4 or etype == 5 then	-- add eyeball gibs to crab enemy
			if i == gibcount - 1 then
				newgib.sprite = 106
				newgib.life = -20
			elseif i == gibcount then
				newgib.sprite = 122
				newgib.life = -20
			end
		end
		newgib.flipx = newgib.vel.x > 0
		add(gibs, newgib)
	end
	-- green splat
	local newsplat = {
		pos = v2make(e.pos.x, e.pos.y), -- need to copy the values, not just pass the e.pos table
		life = 0,
		size = e.type * 2
	}
	if (etype == 3) newsplat.size = 4 
	add(enemysplats, newsplat)
end

function spawnpopcornenemies(bonus, count, startx, starty, startangle, _veer)
	for i = 0, count - 1 do
		local newenemy = {}
		do
			local _ENV = newenemy
			type, bonuscountdown, hitpoints, hitcounter, size, score, pos, veer = 1, bonus, 2, 0, 5, 10, { x = startx, y = starty}, _veer
		end
		newenemy.life = i * -16
		newenemy.vel = v2scale({ x = cos(startangle), y = sin(startangle) }, 1.2)
		newenemy.pos = v2add(newenemy.pos, v2scale(newenemy.vel, -16 * i))
		add(enemies, newenemy)
	end
end

function spawnflappyenemies(bonus, startx, count)
	local _facing = 1
	if (rnd(1) < 0.5) _facing = -1
	for i = 0, count - 1 do
		local newenemy = {}
		do
			local _ENV = newenemy
			type, bonuscountdown, facing, hitcounter, blobs, spawning, hitpoints, size, life, score = 3, bonus, _facing, 0, {}, false, 8, 8, 0 - i * 10, 30
		end
		newenemy.pos, newenemy.dest, newenemy.flipx = v2make(64, -30), v2make(startx + rndrange(-15, 15), 55 - i * 12), rnd(1) < 0.5
		add(enemies, newenemy)
	end
end

function spawnmediumenemies(bonus, startx, destx, desty, count)
	local mediumenemycount = 0
	for e in all(enemies) do
		if (e.type == 2) mediumenemycount += 1
	end
	for i = 0, count - 1 do
		if mediumenemycount < 15 then
			local _shottype = 1
			if (rnd(1) < 0.5) _shottype = 2
			local newenemy = {}
			newenemy.dest, newenemy.pos, newenemy.randomoffset = v2make(destx, desty), v2make(startx, -20), 0.1 * i
			do
				local _ENV = newenemy
				type, bonuscountdown, hitcounter, shotcounter, shottype, blobs, hitpoints, spawning, size, score = 2, bonus, 0, 0, _shottype, {}, 15, true, 8, 50
			end
			
			if i > 0 then
				newenemy.pos = v2add(newenemy.pos, v2scale(v2randomnormalized(), 10))
				newenemy.dest = v2add(newenemy.dest, v2scale(v2randomnormalized(), 20))
				newenemy.dest = v2make(clamp(newenemy.dest.x, 20, 108), clamp(newenemy.dest.y, 20, 80))
			end
			add(enemies, newenemy)
			mediumenemycount += 1
		end
	end
end

function spawntankenemy(bonus, _destx, _desty)
	local newenemy = {}
	do
		local _ENV = newenemy
		type, bonuscountdown, hitpoints, hitcounter, size, shotcounter, life, score = 4, bonus, 250, 0, 12, 0, 0, 400
	end
	newenemy.randomoffset, newenemy.pos, newenemy.dest = rnd(1), v2make(64, -30), v2make(_destx, _desty)
		
	add(enemies, newenemy)
end

function spawnbossenemy()
	local newenemy = {}
	do
		local _ENV = newenemy
		type, bonuscountdown, initialhitpoints, hitpoints, hitcounter, size, shotcounter, life, score, lifestage,  invulnerable, spawning, dying, randomoffset = 5, 0, 600, 0, 0, 22, 0, 0, 500, 0, true, true, false, 0
	end
	newenemy.pos, newenemy.dest = v2make(64, -40), v2make(64, 30)
	add(enemies, newenemy)
end

-- move on a sine/cosine pattern
function gyrate(e, xspeed, xscale, yspeed, yscale)
	e.pos.x += cos(e.randomoffset + (time() - e.gyratestarttime) * xspeed) * xscale
	e.pos.y -= sin(e.randomoffset + (time() - e.gyratestarttime) * yspeed) * yscale
end

function runschedule()
	if scindex <= #schedule and time() - starttime + debugtime > schedule[scindex][1] then
		if schedule[scindex][2] == 1 then
			spawnpopcornenemies(schedule[scindex][3], schedule[scindex][4], schedule[scindex][5], schedule[scindex][6], schedule[scindex][7], schedule[scindex][8])
		elseif schedule[scindex][2] == 2 then
			spawnflappyenemies(schedule[scindex][3], schedule[scindex][4], schedule[scindex][5])
		elseif schedule[scindex][2] == 3 then
			spawnmediumenemies(schedule[scindex][3], schedule[scindex][4], schedule[scindex][5], schedule[scindex][6], schedule[scindex][7])
		elseif schedule[scindex][2] == 4 then
			spawntankenemy(schedule[scindex][3], schedule[scindex][4], schedule[scindex][5], schedule[scindex][6], schedule[scindex][7])
		else
			spawnbossenemy()
		end
		scindex += 1
	end
end