function initbackground()
	basescrollspeed, roadscrollspeed, signsscrollspeed, overpassscrollspeed, overpasscounter, debris, wreck1, wreck2 = 0.7, 0.8, 0.9, 3, 0, {}, { pos = v2make(30, 60), sprite = 40, width = 2, height = 1, flipx = false, burning = true }, { pos = v2make(94, 80), sprite = 40, width = 2, height = 1, flipx = false, burning = false }

	add(debris, wreck1)
	add(debris, wreck2)
end

function updatebackground()
	for d in all(debris) do
		d.pos.y += roadscrollspeed
		if d.pos.y > 200 then -- respawn
			 d.pos.y = -100 - rnd(100)
			 if rnd(1) > 0.5 then
				d.pos.x = 22 + rnd(20)
			 else
				d.pos.x = 84 + rnd(20)
			 end

			 if rnd(1) < 0.5 then
				 d.flipx = true
			 else
				 d.flipx = false;
			 end

			 d.sprite = 38 + flr(rnd(3)) * 2
			 d.burning = rnd(2) < 1
		end
	end
end

function drawbackground()
	for i=-1, 3 do -- stripes
		map(8, 0, 0, i * 48 + (t * basescrollspeed) % 48, 2, 6)
		map(6, 0, 48, i * 48 + (t * basescrollspeed) % 48, 4, 6)
		map(6, 0, 112, i * 48 + (t * basescrollspeed) % 48, 2, 6)
	end

	for x=0, 1 do -- road
		for y=-1, 3 do 
			map(0, 0, 8 + x * 65, y * 48 + (t * roadscrollspeed) % 48, 6, 6)
		end
	end

	for d in all(debris) do
		spr(d.sprite, d.pos.x - d.width/2*8, d.pos.y - d.height/2*8, d.width, d.height, d.flipx, false)
		if d.burning and t % 3 == 0 then
			fireparticle = { 
				pos = v2make(d.pos.x, d.pos.y - 3),
				vel = v2make(-0.4 + rnd(0.8), roadscrollspeed - rnd(1)),
				force = v2make(0, -0.01),
				drag = 0.95,
				life = 0
			}
			add(fires, fireparticle)
		end
	end
end

function drawsigns()
	map(0, 6, 0, -16 + (t * signsscrollspeed) % 600, 16, 1)
	map(0, 7, 0, -150 + (t * signsscrollspeed) % 600, 5, 1)
	map(5, 7, 80, -350 + (t * signsscrollspeed) % 600, 6, 1)
end