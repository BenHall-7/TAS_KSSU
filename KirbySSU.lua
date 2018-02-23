local displayMode1 = 1
local displayMode2 = 3
local display1Set = true
local display2Set = true
local listenForKey = false
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

	if (displayMode1 == 2 or displayMode2 == 2) then
		drawHitBoxes()
	else
		drawMotCenter()
	end
end

--function #1
function drawGameDetails(Yoffset)
	if movie.playing() == true then
		gui.drawtext(0,Yoffset,"frame: "..movie.framecount().."/"..movie.length())
		if movie.framecount < 600 then
			gui.drawtext(0,Yoffset+8,"rerecords: "..movie.rerecordcount())
		end
	else
		gui.drawtext(0,Yoffset,movie.framecount())
	end
	gui.drawtext(0,Yoffset+16,"Game: "..memory.readbyte(0x0205b664))
	gui.drawtext(0,Yoffset+24,"Part: "..memory.readbyte(0x0205b665))
	gui.drawtext(1,Yoffset+32,"Map: "..memory.readbyte(0x0205b666))

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
	gui.drawbox(0,Yoffset-1,255,(#objects+1)*8+Yoffset-1,0x00000080,0x000000FF)
	gui.text(0*(256/8), Yoffset, "Indx")
	gui.text(1*(256/8), Yoffset, "PosX")
	gui.text(3.5*(256/8), Yoffset, "PosY")
	gui.text(6*(256/8), Yoffset, "SpdX")
	gui.text(7*(256/8), Yoffset, "SpdY")
	for i=1,#objects do
		gui.text(0*(256/8), i*8+Yoffset, objects[i][2])
		gui.text(1*(256/8), i*8+Yoffset, objects[i][4][2])
		gui.text(3.5*(256/8), i*8+Yoffset, objects[i][4][3])
		gui.text(6*(256/8), i*8+Yoffset, objects[i][4][4])
		gui.text(7*(256/8), i*8+Yoffset, objects[i][4][5])
	end
end

function createObjectArray()
	--clear any objects in the table
	for i=1,#objects do
		objects[i] = nil
	end

	--initialize the object tables with addresses
	for i=0x1,0x20 do
		temp = memory.readdword(0x02076f00+4*(i-1))
		while (temp ~= 0 and #objects < 24) do
			--give the table a maximum size of 24 just 'cause
			table.insert(objects,{temp})
			temp2 = temp
			temp = memory.readdword(temp2)
		end
	end

	for i=1,#objects do
		setObjectDetails(i, objects[i][1])
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

	--MOT DETAILS:
	local motDetails = {}
	table.insert(objects[index], motDetails)

	temp = memory.readdword(address+0x38)
	table.insert(motDetails, temp)--1: Addr
	table.insert(motDetails, memory.readdwordsigned(temp+0x80)/0x10000)--2: PosX
	table.insert(motDetails, memory.readdwordsigned(temp+0x84)/0x10000)--3: PosY
	table.insert(motDetails, memory.readwordsigned(temp+0x88))--4: SpeedX
	table.insert(motDetails, memory.readwordsigned(temp+0x8a))--5: SpeedY

end

function drawHitBoxes()
	for i=1, #objects do
		hitDetails = objects[i][3]
		local EfctColor = getEfctColor(hitDetails[7])
		gui.box(hitDetails[2],hitDetails[3]-191,hitDetails[4],hitDetails[5]-191,EfctColor)
		gui.text(hitDetails[4],hitDetails[3]-191,objects[i][2])
	end
end

function drawMotCenter()
	for i=1,#objects do
		motDetails = objects[i][4]
		local color = 0x000080FF
		gui.pixel(motDetails[2]-screenX,motDetails[3]-192-screenY,color)--middle
		gui.pixel(motDetails[2]-screenX,motDetails[3]-192-screenY+1,color)--top
		gui.pixel(motDetails[2]-screenX+1,motDetails[3]-192-screenY,color)--right
		gui.pixel(motDetails[2]-screenX,motDetails[3]-192-screenY-1,color)--bottom
		gui.pixel(motDetails[2]-screenX-1,motDetails[3]-192-screenY,color)--left
		gui.pixel(motDetails[2]-screenX,motDetails[3]-192-screenY+2,color)--top
		gui.pixel(motDetails[2]-screenX+2,motDetails[3]-192-screenY,color)--right
		gui.pixel(motDetails[2]-screenX,motDetails[3]-192-screenY-2,color)--bottom
		gui.pixel(motDetails[2]-screenX-2,motDetails[3]-192-screenY,color)--left
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
		color = 0x8000f060 --blue, less opacity
	elseif EffectID == 1 then
		color = 0xf0f0f080 --white
	elseif EffectID == 2 then
		color = 0x00f00050 --green
	elseif EffectID == 3 then
		color = 0xf0000050 --red
	elseif EffectID == 4 then
		color = 0x00f0f050 --cyan
	elseif EffectID == 5 then
		color = 0xf0f00050 --yellow
	else
		color = 0xa0a0a050 --gray
	end

	return color
end

gui.register(main)
