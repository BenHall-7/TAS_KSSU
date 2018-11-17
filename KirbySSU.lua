local displayMode1 = 2
local displayMode2 = 3
local display1Set = true
local display2Set = true
local listenForKey = false
local baseObjects = {}
local objects = {}
local temp2
local temp
local screenX, screenY

local funcTbl = {
	[1] = function(x) drawGameDetails(x) end,
	[2] = function(x) drawhitDetails(x) end,
	[3] = function(x) drawMotDetails(x) end
}

function main()
	screenX=memory.readword(0x0204222e)
	screenY=memory.readword(0x0204222a)

	--use the tilde, numpad, and shift keys to change displays!
	displayModeHandler()

	--create the array of hitboxes and hurtboxes addresses to draw
	createObjectArray()

	--display things on the top and bottom screens
	dispTopBottom()
end

function displayModeHandler()
	if input.get().tilde then
		listenForKey = true
		display1Set = false
		display2Set = false
	end

	if listenForKey then
		setDisplayMode();
	end
end

function setDisplayMode()
	if (display1Set == true) then
		if display2Set == true then
			listenForKey = false
		else --setting displayMode2
			if input.get().shift then
				display2Set = true
			elseif input.get().numpad0 then
				displayMode2 = 0
				display2Set = true
			elseif input.get().numpad1 then
				displayMode2 = 1
				display2Set = true
			elseif input.get().numpad2 then
				displayMode2 = 2
				display2Set = true
			elseif input.get().numpad3 then
				displayMode2 = 3
				display2Set = true
			end
			gui.text(64,-9,"setting display2")
		end
	else --setting displayMode1
		if input.get().shift then
			display1Set = true
		elseif input.get().numpad0 then
			displayMode1 = 0
			display1Set = true
		elseif input.get().numpad1 then
			displayMode1 = 1
			display1Set = true
		elseif input.get().numpad2 then
			displayMode1 = 2
			display1Set = true
		elseif input.get().numpad3 then
			displayMode1 = 3
			display1Set = true
		end
		gui.text(64,-9,"setting display1")
	end
end

function dispTopBottom()
	local topOffset = -191
	local bottomOffset = 1
	--top display
	if (displayMode1 ~= 0) then
		funcTbl[displayMode1](topOffset)
	end

	if (displayMode2 ~= 0) then
		funcTbl[displayMode2](bottomOffset)
	end

	if (not (displayMode1 == 0 and displayMode2 == 0)) then
		drawHitBoxes()
	end
	drawMotCenter()
end

--function #1
function drawGameDetails(Yoffset)
	if movie.playing() == true then
		gui.drawtext(0,Yoffset,"frame: "..movie.framecount().."/"..movie.length())
		if movie.framecount() < 600 then
			gui.drawtext(0,Yoffset+8,"rerecords: "..movie.rerecordcount())
		end
	else
		gui.drawtext(0,Yoffset,movie.framecount())
	end
	gui.drawtext(0,Yoffset+16,"Game: "..memory.readbyte(0x0205b664))
	gui.drawtext(0,Yoffset+24,"Part: "..memory.readbyte(0x0205b665))
	gui.drawtext(1,Yoffset+32,"Map: "..memory.readbyte(0x0205b666))

	local rng = memory.readword(0x0204219c)
	gui.drawbox(212,Yoffset-1,255,Yoffset+7,0x00000080, 0x00000080)
	gui.drawtext(213,Yoffset,"rng:"..string.format("%3x",rng))
	for i=1,3 do
		rng = bit.band(rng * 0x3d + 0x79 + 0x500,0xfff)
		gui.drawbox(212,Yoffset + 8*i,255,Yoffset+7 + 8*i,0x00000080, 0x00000080)
		gui.drawtext(213,Yoffset + 8*i,"   :"..string.format("%3x",rng))
	end

	gui.drawtext(0,Yoffset+191-8,"0x"..string.format("%x",memory.readword(0x0209f340)))
	gui.drawtext(0,Yoffset+191-16,bit.tohex(memory.readdword(0x0209f340+0x2c)))
	gui.drawtext(0,Yoffset+191-24,bit.tohex(memory.readdword(0x0209f340+0x30)))
	gui.drawtext(0,Yoffset+191-32,bit.tohex(memory.readdword(0x0209f340+0x34)))
	gui.drawtext(0,Yoffset+191-40,bit.tohex(memory.readdword(0x0209f340+0x38)))
end

--function #2
function drawhitDetails(Yoffset)
	gui.drawbox(0,Yoffset-1,127,(#objects+1)*8+Yoffset-1,0x00000080,0x000000FF)
	gui.text(0*(256/8),Yoffset,"Indx")
	gui.text(1*(256/8),Yoffset,"Dmg")
	gui.text(2*(256/8),Yoffset,"Efc")
	gui.text(3*(256/8),Yoffset,"Pwr")
	for i=1,#objects do
		gui.text(0*(256/8), i*8+Yoffset, objects[i].index)--index
		gui.text(1*(256/8), i*8+Yoffset, objects[i].hitDetails.dmg)--dmg
		local efc = getEfctName(objects[i].hitDetails.efc)--efc
		gui.text(2*(256/8), i*8+Yoffset, efc)--writes a text name for efc
		gui.text(3*(256/8), i*8+Yoffset, objects[i].hitDetails.pwr)--pwr
	end
end

--function #3
function drawMotDetails(Yoffset)
	gui.drawbox(0,Yoffset-1,255,(#baseObjects+1)*8+Yoffset-1,0x00000080,0x000000FF)
	gui.text(0*(256/8), Yoffset, "Indx")
	gui.text(1*(256/8), Yoffset, "PosX")
	gui.text(3.5*(256/8), Yoffset, "PosY")
	gui.text(6*(256/8), Yoffset, "SpdX")
	gui.text(7*(256/8), Yoffset, "SpdY")
	for i=1,#baseObjects do
		gui.text(0*(256/8), i*8+Yoffset, baseObjects[i].index)
		gui.text(1*(256/8), i*8+Yoffset, baseObjects[i].x)
		gui.text(3.5*(256/8), i*8+Yoffset, baseObjects[i].y)
		gui.text(6*(256/8), i*8+Yoffset, baseObjects[i].spd_x)
		gui.text(7*(256/8), i*8+Yoffset, baseObjects[i].spd_y)
	end
end

function createObjectArray()
	--clear any objects in the table
	objects = {}

	--initialize the object tables with addresses
	for i=0x2,0x20 do --grab range = 1. Don't display
		temp = memory.readdword(0x02076f00+4*(i-1))
		while (temp ~= 0 and #objects < 23) do
			table.insert(objects, {
				addr = temp,
				index = nil,
				hitDetails = {}
			})
			temp = memory.readdword(temp)
		end
	end

	for i=1,#objects do
		setObjectDetails(i, objects[i].addr)
	end

	--real objects
	for i=1,#baseObjects do
		baseObjects[i] = nil
	end

	for i=0x1,0x7 do
		temp = memory.readdword(0x02049dec+4*(i-1))
		while (temp ~= 0 and #baseObjects < 23) do
			--give the table a maximum size of 23 so it doesn't go past the screen
			table.insert(baseObjects, { 
				addr = temp,
				index = nil,
				x = nil,
				y = nil,
				spd_x = nil,
				spd_y = nil
			})
			temp = memory.readdword(temp)
		end
	end

	--mot details for normal objects. Maybe should move to setObjectDetails later
	for i=0x1,#baseObjects do
		temp = baseObjects[i].addr
		baseObjects[i].index = i
		baseObjects[i].x = memory.readdwordsigned(temp + 0x80)/0x10000
		baseObjects[i].y = memory.readdwordsigned(temp + 0x84)/0x10000
		baseObjects[i].spd_x = memory.readwordsigned(temp + 0x88)
		baseObjects[i].spd_y = memory.readwordsigned(temp + 0x8a)
	end
end

function setObjectDetails(index,address)
	objects[index].index = index

	temp = memory.readdword(address+0x14)
	objects[index].hitDetails = {
		hit_addr = temp,
		x1 = memory.readwordsigned(address+0x24),
		y1 = memory.readwordsigned(address+0x26),
		x2 = memory.readwordsigned(address+0x28),
		y2 = memory.readwordsigned(address+0x2a),
		hp = memory.readword(address+0x238),
		dmg = memory.readwordsigned(temp+0x14),
		efc = memory.readbyte(temp+0xa),
		pwr = memory.readbytesigned(temp+0xb)
	}
end

function drawHitBoxes()
	local condition = (displayMode1 == 2 or displayMode2 == 2)
	--use the condition for which table indeces to write
	for i=#objects,1,-1 do
		hitDetails = objects[i].hitDetails
		local EfctColor = getEfctColor(hitDetails.efc)
		gui.box(hitDetails.x1 - screenX, hitDetails.y1 - 191 - screenY,
			hitDetails.x2 - screenX, hitDetails.y2 - 191 - screenY,
			EfctColor, 0xF0F0F080)
		if condition then
			gui.text(hitDetails.x2 - screenX, hitDetails.y2 - screenY - 191,
				objects[i].index)
			if objects[i].hitDetails.hp > 0 then
				gui.text(hitDetails.x2 - screenX, hitDetails.y1 - screenY - 199,
				hitDetails.hp, 0xFF0000C0)
			end
		end
	end

	if not condition then
		for i=#baseObjects,1,-1 do
			gui.text(baseObjects[i].x - screenX + 1, baseObjects[i].y - 192 - screenY,
			baseObjects[i].index)
		end
	end
end

function drawMotCenter()
	for i=1,#baseObjects do
		local cl = 0x80FFFFFF
		gui.pixel(baseObjects[i].x - screenX, baseObjects[i].y - 192 - screenY,cl)
		gui.pixel(baseObjects[i].x - screenX, baseObjects[i].y - 192 - screenY + 1,cl)
		gui.pixel(baseObjects[i].x - screenX + 1, baseObjects[i].y - 192 - screenY,cl)
		gui.pixel(baseObjects[i].x - screenX, baseObjects[i].y - 192 - screenY - 1,cl)
		gui.pixel(baseObjects[i].x - screenX - 1, baseObjects[i].y - 192 - screenY,cl)
		gui.pixel(baseObjects[i].x - screenX, baseObjects[i].y - 192 - screenY + 2,cl)
		gui.pixel(baseObjects[i].x - screenX + 2, baseObjects[i].y - 192 - screenY,cl)
		gui.pixel(baseObjects[i].x - screenX, baseObjects[i].y - 192 - screenY - 2,cl)
		gui.pixel(baseObjects[i].x - screenX - 2, baseObjects[i].y - 192 - screenY,cl)
	end
end

function getEfctName(EffectID)
	local name

	if EffectID == 0 then
		name = "norm"
	elseif EffectID == 1 then
		name = "weak"
	elseif EffectID == 2 then
		name = "slsh"
	elseif EffectID == 3 then
		name = "fire"
	elseif EffectID == 4 then
		name = "ice"
	elseif EffectID == 5 then
		name = "elec"
	else
		name = EffectID
	end

	return name
end

function getEfctColor(EffectID)
	local color

	if EffectID == 0 then
		color = 0x4040f080 --blue
	elseif EffectID == 1 then
		color = 0xf0f0f090 --white
	elseif EffectID == 2 then
		color = 0x00f00070 --green
	elseif EffectID == 3 then
		color = 0xf0000070 --red
	elseif EffectID == 4 then
		color = 0x00f0f070 --cyan
	elseif EffectID == 5 then
		color = 0xf0f00070 --yellow
	else
		color = 0xa0a0a050 --gray
	end

	return color
end

gui.register(main)
