-- ghostwave
-- by monorail

function _init()
	initmenu()
	initgame()
	inertiaon, musicon = true, true
	_update60, _draw, gameover = updatemenu, drawmenu, false
end

function initmenu()
	menupage, menuselection, logooffset = 1, 0, 128
end

function initgame()
	--pal()
	pal({[0]=129,0,128,1,138,133,134,7,8,137,10,139,3,131,12,6},1)
	poke(0x5f2e,1) -- keeps the colours on quit
	initbackground()
	initplayer()
	initui()
	initbullets()
	initvfx()
	-- t = 0 -- framecounter
	-- score = 0
	-- testing = false

	t = 0
end

function updategame()
	t += 1
	runschedule()
	updatebackground()
	updateplayer()
	updateenemies()
	updateghosts()
	updatebullets()
	updatevfx()
end

function drawgame()
	cls(0)
	drawbackground()
	drawlowervfx()
	drawghosts()
	drawenemies()
	drawplayerbullets()
	drawshellcases()
	drawuppervfx()
	drawplayer()
	drawenemybullets()
	drawsigns()
	drawui()
end

function updatemenu()
	t += 1
	updatebackground()
	updatevfx()
	updateplayer()	
	if (nobuttonspressed()) hasreleasebuttons = true
end

function drawmenu()
	cls(0)
	drawbackground()
	drawlowervfx()
	drawuppervfx()
	drawplayer()
	drawsigns()
	rectfill(0, 9, 128, 10, 4)
	spr(224, 9 + logooffset, 6, 9, 2)
	spr(233, 42 + logooffset, 21, 8, 2)
	logooffset *= 0.88

	if menupage == 1 then
		printshadow("\14start", 11, 43, 4)
		printshadow("\14instructions", 11, 51, 4)
		if musicon then
			printshadow("\14music: on", 11, 59, 4)
		else
			printshadow("\14music: off", 11, 59, 4)
		end
		if inertiaon then
			printshadow("\14inertia: on", 11, 67, 4)
		else
			printshadow("\14inertia: off", 11, 67, 4)
		end
		-- cursor
		drawcursor(43 + menuselection * 8)

		if (btnp(⬇️)) menuselection += 1 sfx(9)
		if (btnp(⬆️)) menuselection -= 1 sfx(9)
		menuselection = menuselection % 4
		if (not gameover and hasreleasebuttons) and (btnp(❎) or btnp(🅾️)) then
			sfx(8) -- start game sound
				if menuselection == 0 then
					initenemies()
					initplayer()
					hasreleasebuttons = false
					_update60, _draw = updategame, drawgame
					if (musicon) music(0, nil, 3)
					playertarget, starttime = v2make(64, 100), time()
				elseif menuselection == 1 then
					menupage, playertarget = 2, v2make(22, 84)
				elseif menuselection == 2 then
					musicon = not musicon
				else
					inertiaon = not inertiaon
				end
		end
	elseif menupage == 2 then
		printshadow("🅾️ : shoot gun\n❎ : shoot rockets\n\nafter 3 salvos, rockets take\n10 seconds to reload", 10, 40, 4)
		printshadow("rocket ammo is\nindicated here\n\npickup enemy ghosts\nfor a score bonus", 52, 79, 4)
		line(38, 87, 50, 87, 4)

		if (t % 5 > 0) circfill(44, 102, 3, 14)

		printshadow("\14back", 11, 114, 4)
		drawcursor(114)
		
		if (not gameover) and (btnp(❎) or btnp(🅾️)) then
			sfx(8) -- start game sound
			menupage, playertarget = 1, v2make(64, 100)
		end
	end

	gameover = false
end

function drawcursor(y)
	local cursorsprite = 184
	if (t % 20 > 9) cursorsprite = 185
	spr(cursorsprite, 2, y)
end

function updategameover()
	if (nobuttonspressed()) hasreleasebuttons = true
	t += 1
	updatebackground()
	updateplayer()
	updateenemies()
	updatebullets()
	updatevfx()
	if hasreleasebuttons and (btnp(🅾️) or btnp(❎)) then
		sfx(8)
		hasreleasedbuttons = false
		_update60, _draw, enemies = updatemenu, drawmenu, {}
	end
end

function nobuttonspressed()
	return not (btn(🅾️) or btn(❎))
end

function drawgameover()
	cls(0)
	drawbackground()
	drawlowervfx()
	drawenemies()
	drawplayerbullets()
	drawshellcases()
	drawuppervfx()
	drawenemybullets()
	drawsigns()
	drawui()
	if t % 60 > 10 then
		if victory then
			printshadow("\14victory!", 44, 50, 9)
		else
			printshadow("\14game over", 36, 50, 9)
		end
	end
end

function endgame()
	music(-1)
	sfx(26)
	_update60, _draw, gameover, hasreleasebuttons = updategameover, drawgameover, true, false
end