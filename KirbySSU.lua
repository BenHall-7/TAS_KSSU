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
	gui.text(2*(256/8),Yoffset,"Efct")
	gui.text(3*(256/8),Yoffset,"Pwr")
	for i=1,#objects do
		gui.text(0*(256/8), i*8+Yoffset, objects[i][2])--index
		gui.text(1*(256/8), i*8+Yoffset, objects[i][3][6])--dmg
		local efct = getEfctName(objects[i][3][7])--efct
		gui.text(2*(256/8), i*8+Yoffset, efct)--writes a text name for efct
		gui.text(3*(256/8), i*8+Yoffset, objects[i][3][8])--pwr
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
		gui.text(0*(256/8), i*8+Yoffset, baseObjects[i][2])
		gui.text(1*(256/8), i*8+Yoffset, baseObjects[i][3])
		gui.text(3.5*(256/8), i*8+Yoffset, baseObjects[i][4])
		--gui.text(6*(256/8), i*8+Yoffset, bit.tohex(baseObjects[i][1]))
		gui.text(6*(256/8), i*8+Yoffset, baseObjects[i][5])
		gui.text(7*(256/8), i*8+Yoffset, baseObjects[i][6])
	end
end

function createObjectArray()
	--clear any objects in the table
	for i=1,#objects do
		objects[i] = nil
	end

	--initialize the object tables with addresses
	for i=0x2,0x20 do --don't show command grab ranges because they block out stuff
		temp = memory.readdword(0x02076f00+4*(i-1))
		while (temp ~= 0 and #objects < 23) do
			--give the table a maximum size of 23 so it doesn't go past the screen
			table.insert(objects,{temp})
			temp2 = temp
			temp = memory.readdword(temp2)
		end
	end

	for i=1,#objects do
		setObjectDetails(i, objects[i][1])
	end

	--real objects
	for i=1,#baseObjects do
		baseObjects[i] = nil
	end

	for i=0x1,0x7 do
		temp = memory.readdword(0x02049dec+4*(i-1))
		while (temp ~= 0 and #baseObjects < 23) do
			--give the table a maximum size of 23 so it doesn't go past the screen
			table.insert(baseObjects,{temp})
			temp2 = temp
			temp = memory.readdword(temp2)
		end
	end

	--mot details for normal objects. Maybe should move to setObjectDetails later
	for i=0x1,#baseObjects do
		table.insert(baseObjects[i],i)
		--Speed/Position
		table.insert(baseObjects[i],memory.readdwordsigned(baseObjects[i][1] + 0x80)/0x10000)
		table.insert(baseObjects[i],memory.readdwordsigned(baseObjects[i][1] + 0x84)/0x10000)
		table.insert(baseObjects[i],memory.readwordsigned(baseObjects[i][1] + 0x88))
		table.insert(baseObjects[i],memory.readwordsigned(baseObjects[i][1] + 0x8a))
	end
end

function setObjectDetails(index,address)
	--objects = {{object1}, {object2}...} where
	--{object#} = {Main Address, Index, {Hit Details}, {Mot details}...}

	table.insert(objects[index], index)--object[i][2] = index in the list

	--HIT DETAILS:
	local hitDetails = {}
	table.insert(objects[index],hitDetails)

	temp = memory.readdword(address+0x14)
	table.insert(hitDetails, temp)--1: Address of hitboxes
	table.insert(hitDetails, memory.readwordsigned(address+0x24)-screenX)--2: X1
	table.insert(hitDetails, memory.readwordsigned(address+0x26)-screenY)--3: Y1
	table.insert(hitDetails, memory.readwordsigned(address+0x28)-screenX)--4: X2
	table.insert(hitDetails, memory.readwordsigned(address+0x2a)-screenY)--5: Y2
	table.insert(hitDetails, memory.readwordsigned(temp+0x4))--6: Dmg
	table.insert(hitDetails, memory.readbyte(temp+0xa))--7: Efct
	table.insert(hitDetails, memory.readbytesigned(temp+0xb))--8: Pwr
	table.insert(hitDetails, memory.readword(address+0x238))--9: HP
end

function drawHitBoxes()
	local condition = (displayMode1 == 2 or displayMode2 == 2)
	--use the condition for which table indeces to write
	for i=#objects,1,-1 do
		hitDetails = objects[i][3]
		local EfctColor = getEfctColor(hitDetails[7])
		gui.box(hitDetails[2],hitDetails[3]-191,hitDetails[4],hitDetails[5]-191,EfctColor, 0xF0F0F080)
		if condition then
			gui.text(hitDetails[4]+1,hitDetails[3]-190,objects[i][2])
			if objects[i][3][9] > 0 then
				gui.text(hitDetails[4]-3,hitDetails[3]-200,objects[i][3][9], 0xFF0000C0)
			end
		end
	end

	if not condition then
		for i=#baseObjects,1,-1 do
			gui.text(baseObjects[i][3]-screenX+1,baseObjects[i][4]-192-screenY,baseObjects[i][2])
		end
	end
end

function drawMotCenter()
	for i=1,#baseObjects do
		local color = 0x80FFFFFF
		gui.pixel(baseObjects[i][3]-screenX,baseObjects[i][4]-192-screenY,color)--middle
		gui.pixel(baseObjects[i][3]-screenX,baseObjects[i][4]-192-screenY+1,color)--bottom
		gui.pixel(baseObjects[i][3]-screenX+1,baseObjects[i][4]-192-screenY,color)--right
		gui.pixel(baseObjects[i][3]-screenX,baseObjects[i][4]-192-screenY-1,color)--top
		gui.pixel(baseObjects[i][3]-screenX-1,baseObjects[i][4]-192-screenY,color)--left
		gui.pixel(baseObjects[i][3]-screenX,baseObjects[i][4]-192-screenY+2,color)--bottom
		gui.pixel(baseObjects[i][3]-screenX+2,baseObjects[i][4]-192-screenY,color)--right
		gui.pixel(baseObjects[i][3]-screenX,baseObjects[i][4]-192-screenY-2,color)--top
		gui.pixel(baseObjects[i][3]-screenX-2,baseObjects[i][4]-192-screenY,color)--left
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
		name = string.format("0x".."%x",EffectID)
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
