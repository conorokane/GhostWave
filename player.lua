function initplayer()
	playerspeed, playerhsize, playerbulletspeed, playercasespeed, playerrocketammo, playerrocketreloadcounter, playerfirerate, playerfirecounter, playerbanking, playerhudinertia, playerlives, playerdying, playerdeathcounter, playerinvulnerablecountdown, playervel, playerpos, playerbullets, playercases, playerguns, playerrockets = 1.4, 8, 8, 0.5, 3, 0, 4, -1, false, 0.2, 3, false, 0, 0, v2make(0, 0), v2make(64, 100), {}, {}, {}, {}

	playerhudpos, playerguns[1], playerguns[2], playerguns[3], playerguns[4], playertarget = v2make(playerpos.x, playerpos.y), { pos = v2make(-4, 4)}, { pos = v2make(5, 4)}, { pos = v2make(-2, 4)}, { pos = v2make(3, 4)}, v2make(64, 100)

	if inertiaon then
		playerinertia = 0.1
	else
		playerinertia = 1
	end

	victory, score = false, 0
end

function updateplayer()
if (nobuttonspressed()) hasreleasebuttons = true -- prevent firing at the very start

	if playerdying then
		playerdeathcounter += 1
		if playerdeathcounter < 80 and playerdeathcounter % 10 == 0 then
			for i = 0, 5 do
				createexplosionfire(playerpos, true)
			end
		end
		if (playerdeathcounter == 120) respawnplayer()
		return
	elseif playerinvulnerablecountdown > 0 then
		playerinvulnerablecountdown -= 1
	end

	-- === movement ===

	inputvector = v2make(0, 0)
	if (_update60 != updatemenu) then
		if (btn(⬅️)) inputvector.x = -1 
		if (btn(➡️)) inputvector.x = 1 
		if (btn(⬆️)) inputvector.y = -1 
		if (btn(⬇️)) inputvector.y = 1 
		-- clamp diagonals
		if inputvector.x != 0 and inputvector.y != 0 then
			inputvector = v2scale(inputvector, 0.707)
		end
	end
	
	-- scale the input by the speed
	playervel = v2scale(inputvector, playerspeed)
	
	-- move the target
	playertarget = v2add(playertarget, playervel)
	playertarget = v2make(clamp(playertarget.x, 6, 122), clamp(playertarget.y, 8, 120))
	
	-- lerp the player to the target
	playerpos = v2lerp(playerpos, playertarget, playerinertia)
	playerhudpos = v2lerp(playerhudpos, playerpos, playerhudinertia)

	-- === shooting === ---

	if btn(🅾️) and not gameover then -- guns
		if hasreleasebuttons and _update60 != updatemenu then
			playerfirecounter += 1
			if (playerfirecounter == 1 or t % 12 == 0 or t % 15 == 0) sfx(0, 2)
			if (playerfirecounter % playerfirerate == 0) then
				local bankoffset = 0
				if (playerbanking) bankoffset = 2 
				local newbullet1 = { 
					life = 0,
					pos = v2add(playerpos, playerguns[1 + bankoffset].pos),
					vel = v2scale(v2up, playerbulletspeed)
				}
				local newbullet2 = { 
					life = 0,
					pos = v2add(playerpos, playerguns[2 + bankoffset].pos),
					vel = v2scale(v2up, playerbulletspeed)
				}
				add(playerbullets, newbullet1)
				add(playerbullets, newbullet2)

				-- drop 2 shell cases
				local casevelocity1 = v2randominrange(180, 220)
				local casevelocity2 = v2randominrange(320, 360)
				local randomscale1 = rndrange(2,3)
				local randomscale2 = rndrange(2,3)
				casevelocity1 = v2scale(casevelocity1, randomscale1)
				casevelocity2 = v2scale(casevelocity2, randomscale2)
				newcase1 = spawncase(v2add(playerpos, playerguns[1 + bankoffset].pos), casevelocity1)
				newcase2 = spawncase(v2add(playerpos, playerguns[2 + bankoffset].pos), casevelocity2)
				add(playercases, newcase1)
				add(playercases, newcase2)
			end
		end
	else
		playerfirecounter = -1 -- not firing
	end

	if btnp(❎) and _update60 != updatemenu and not gameover and hasreleasebuttons then -- rockets
		if playerrocketammo > 0 then
			sfx(4 - playerrocketammo, 3)
			playerrocketammo -= 1
			if (playerrocketammo == 0) playerrocketreloadcounter = 0
			for i = 0, 1 do
				local rocket = {
					life = 0,
					pos = v2make(playerpos.x - 9 + i * 18, playerpos.y - 14),
					vel = v2scale(v2up, 0.1),
					force = v2scale(v2up, 0.2),
					drag = 1,
				}
				add(playerrockets, rocket)
			end
		end
	end

	-- === reloading ===
	if _update60 != updatemenu then
		playerrocketreloadcounter += 1
		if playerrocketreloadcounter == 600 and playerrocketammo == 0 then
			playerrocketammo = 3
			sfx(4)
		end
	end
end

function drawplayer()
	if playerdying then
		if (playerdeathcounter < 60) circfill(playerpos.x + rndrange(-6, 6), playerpos.y + rndrange(-6, 6), rndrange(3, 5), 7)
	return
	end

	-- HUD
	if playerinvulnerablecountdown < 100 then
		if t % 3 < 2 then -- draw hud
			-- hud frame
			spr(88, playerhudpos.x - 16, playerhudpos.y - 14, 2, 2)
			spr(88, playerhudpos.x, playerhudpos.y - 14, 2, 2, true)
			
			for e in all(enemies) do
				if v2proximity(e.pos, v2make(64, 64), 64) then -- only draw hud for onscreen enemies
					local linetoplayer = v2sub(playerpos, e.pos)
					if e.bonuscountdown > 0 then -- target lock on bonus enemies
						fillp(0b1111000011110000) -- fill pattern for hud
						local hudcolor = 180
						if (t % 2 == 0) hudcolor = 75
						
						-- diamond
						line(e.pos.x + cos(time() * hudspeed) * hudsize,
							e.pos.y + sin(time() * hudspeed) * hudsize,
							e.pos.x + cos(0.25 + time() * hudspeed) * hudsize,
							e.pos.y + sin(0.25 + time() * hudspeed) * hudsize, hudcolor)
						line(e.pos.x + cos(0.5 + time() * hudspeed) * hudsize,
							e.pos.y + sin(0.5 + time() * hudspeed) * hudsize, hudcolor)
						line(e.pos.x + cos(0.75 + time() * hudspeed) * hudsize,
							e.pos.y + sin(0.75 + time() * hudspeed) * hudsize, hudcolor)
						line(e.pos.x + cos(time() * hudspeed) * hudsize,
							e.pos.y + sin(time() * hudspeed) * hudsize, hudcolor)
							
						-- lines to player
						hudcolor = 188
						line(e.pos.x + linetoplayer.x * 0.2, e.pos.y + linetoplayer.y * 0.2, e.pos.x + linetoplayer.x * 0.25, e.pos.y + linetoplayer.y * 0.25, hudcolor)
						line(e.pos.x + linetoplayer.x * 0.3, e.pos.y + linetoplayer.y * 0.3, e.pos.x + linetoplayer.x * 0.35, e.pos.y + linetoplayer.y * 0.35, hudcolor)
						line(e.pos.x + linetoplayer.x * 0.4, e.pos.y + linetoplayer.y * 0.4, e.pos.x + linetoplayer.x * 0.45, e.pos.y + linetoplayer.y * 0.45, hudcolor)
					end
					-- dot
					fillp()
					circfill(e.pos.x + linetoplayer.x * 0.85,  e.pos.y + linetoplayer.y * 0.85, 1, 4)
				end
			end
			
			-- rocket ammo
			print("RKT", playerhudpos.x + 4, playerhudpos.y + 5, 11)
			
			if playerrocketammo > 0 then
				rectfill(playerhudpos.x + 4, playerhudpos.y + 2, playerhudpos.x + 6, playerhudpos.y + 4, 4)
			else
				if t % 30 > 15 then
					pset(playerhudpos.x + 4, playerhudpos.y + 4, 4)
				end
			end
			if playerrocketammo > 1 then
				rectfill(playerhudpos.x + 8, playerhudpos.y + 2, playerhudpos.x + 10, playerhudpos.y + 4, 4)
			else
				if playerrocketammo != 0 then
					pset(playerhudpos.x + 8, playerhudpos.y + 4, 4)
				elseif t % 30 > 15 then
					pset(playerhudpos.x + 8, playerhudpos.y + 4, 4)
				end
			end
			if playerrocketammo > 2 then
				rectfill(playerhudpos.x + 12, playerhudpos.y + 2, playerhudpos.x + 14, playerhudpos.y + 4, 4)
			else
				if playerrocketammo != 0 then
					pset(playerhudpos.x + 12, playerhudpos.y + 4, 4)
				elseif t % 30 > 15 then
					pset(playerhudpos.x + 12, playerhudpos.y + 4, 4)
				end
			end
		end
	end

	-- heli
	if (playerinvulnerablecountdown > 0 and t % 6 > 2) -- flashes when invulnerable after respawn
	or playerinvulnerablecountdown == 0 then 
		if inputvector.x == 0 then -- not banking
			spr(1, playerpos.x - playerhsize, playerpos.y - 6, 2, 2)
			playerbanking = false
		elseif inputvector.x < 0 then
			spr(8, playerpos.x - playerhsize, playerpos.y - 6, 2, 2)
			playerbanking = true
		else
			spr(8, playerpos.x - playerhsize, playerpos.y - 6, 2, 2, true, false)
			playerbanking = true
		end
	end

	-- muzzleflash
	local flashsprite = 6 + (playerfirecounter % 9) / 3

	if flashsprite < 8 then
		local gun1, gun2 = -9, 1
		if playerbanking then
			gun1, gun2 = -7, -1
		end

		spr(flashsprite, playerpos.x + gun1, playerpos.y -8, 1, 1)
		spr(flashsprite, playerpos.x + gun2 , playerpos.y -8, 1, 1, true, false)
	end

	-- lights
	if not playerbanking then
		pset(playerpos.x - 3, playerpos.y + 8, 8)
		pset(playerpos.x + 2, playerpos.y + 8, 11)
	elseif inputvector.x < 0 then
		pset(playerpos.x + 2, playerpos.y + 8, 11)
	else
		pset(playerpos.x - 3, playerpos.y + 8, 8)
	end

	-- rotors
	local rotorsprite = 32 + (t % 24) / 4
	spr(rotorsprite, playerpos.x - playerhsize, playerpos.y - 7, 1, 2)
	spr(rotorsprite, playerpos.x, playerpos.y - 7, 1, 2, true, true)
end

function loselife()
	if (playerinvulnerablecountdown > 0 or playerdying) return
	playerlives -= 1
	sfx(12)
	local exp = { pos = v2make(playerpos.x, playerpos.y), life = 0 }
	add(rocketexplosions, exp)
	-- wipe bullets
	for b in all(enemybullets) do
		del(enemybullets, b)
	end
	playerdeathcounter = -1
	playerdying = true

	if playerlives == 0 then
		victory = false
		endgame()
	end
end

function respawnplayer()
	playerdying, playerinvulnerablecountdown, playerpos, playerhudpos, playertarget = false, 120, v2make(64, 140), v2make(64, 64), v2make(64, 120)
end