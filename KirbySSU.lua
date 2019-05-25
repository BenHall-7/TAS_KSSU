local displayMode1 = 2
local displayMode2 = 3
local display1Set = true
local display2Set = true
local listenForKey = false
local inputs = {}

local game_objects = {}
local hit_collisions = {}
local screenX, screenY

local draw_modes = {
	"game_data",
	"hit_data",
	"mot_data"
}

local mode_funcs = {}

local efc_data = {
	[0] =
	{name = "norm", color = 0x4040f080},
	{name = "weak", color = 0xf0f0f090},
	{name = "slsh", color = 0x00f00070},
	{name = "fire", color = 0xf0000070},
	{name = "frez", color = 0x00f0f070},
	{name = "elec", color = 0xf0f00070}
}

local function get_efc_name(id)
	local efc = efc_data[id]
	if efc then return efc.name end
	return id
end

local function get_efc_color(id)
	local efc = efc_data[id]
	if efc then return efc.color end
	return 0xa0a0a050
end

mode_funcs[draw_modes[1]] = function(y)
	if movie.playing() == true then
		gui.drawtext(0,y,"frame: "..movie.framecount().."/"..movie.length())
		if movie.framecount() < 600 then
			gui.drawtext(0,y+8,"rerecords: "..movie.rerecordcount())
		end
	else
		gui.drawtext(0,y,movie.framecount())
	end
	gui.drawtext(0,y+16,"Game: "..memory.readbyte(0x0205b664))
	gui.drawtext(0,y+24,"Part: "..memory.readbyte(0x0205b665))
	gui.drawtext(1,y+32,"Map: "..memory.readbyte(0x0205b666))

	local rng = memory.readword(0x0204219c)
	gui.drawbox(212,y-1,255,y+7,0x00000080, 0x00000080)
	gui.drawtext(213,y,"rng:"..string.format("%03x",rng))
	for i=1,3 do
		rng = bit.band(rng * 0x3d + 0x79 + 0x500,0xfff)
		gui.drawbox(212,y + 8*i,255,y+7 + 8*i,0x00000080, 0x00000080)
		gui.drawtext(213,y + 8*i,"   :"..string.format("%03x",rng))
	end

	gui.drawtext(0,y+191-8,"0x"..string.format("%x",memory.readword(0x0209f340)))
	gui.drawtext(0,y+191-16,bit.tohex(memory.readdword(0x0209f340+0x2c)))
	gui.drawtext(0,y+191-24,bit.tohex(memory.readdword(0x0209f340+0x30)))
	gui.drawtext(0,y+191-32,bit.tohex(memory.readdword(0x0209f340+0x34)))
	gui.drawtext(0,y+191-40,bit.tohex(memory.readdword(0x0209f340+0x38)))
end

mode_funcs[draw_modes[2]] = function(y)
	gui.drawbox(0,y-1,127,(#hit_collisions+1)*8+y-1,0x00000080,0x000000FF)
	gui.text(0*(256/8),y,"Indx")
	gui.text(1*(256/8),y,"Dmg")
	gui.text(2*(256/8),y,"Efc")
	gui.text(3*(256/8),y,"Pwr")
	for i=1,#hit_collisions do
		gui.text(0*(256/8), i*8+y, hit_collisions[i].index)
		gui.text(1*(256/8), i*8+y, hit_collisions[i].hitDetails.dmg)
		local efc = get_efc_name(hit_collisions[i].hitDetails.efc)
		gui.text(2*(256/8), i*8+y, efc)--writes a text name for efc
		gui.text(3*(256/8), i*8+y, hit_collisions[i].hitDetails.pwr)
	end
end

mode_funcs[draw_modes[3]] = function(y)
	gui.drawbox(0,y-1,255,(#game_objects+1)*8+y-1,0x00000080,0x000000FF)
	gui.text(0*(256/8), y, "Indx")
	gui.text(1*(256/8), y, "PosX")
	gui.text(3.5*(256/8), y, "PosY")
	gui.text(6*(256/8), y, "SpdX")
	gui.text(7*(256/8), y, "SpdY")
	for i, obj in ipairs(game_objects) do
		gui.text(0  *(256/8), i*8+y, obj.index)
		gui.text(1  *(256/8), i*8+y, obj.x)
		gui.text(3.5*(256/8), i*8+y, obj.y)
		gui.text(6  *(256/8), i*8+y, obj.spd_x)
		gui.text(7  *(256/8), i*8+y, obj.spd_y)
	end
end

local function set_display_mode()
	if display1Set then
		if display2Set then
			listenForKey = false
		else --setting displayMode2
			if inputs.shift then
				display2Set = true
			elseif inputs.numpad0 then
				displayMode2 = 0
				display2Set = true
			elseif inputs.numpad1 then
				displayMode2 = 1
				display2Set = true
			elseif inputs.numpad2 then
				displayMode2 = 2
				display2Set = true
			elseif inputs.numpad3 then
				displayMode2 = 3
				display2Set = true
			end
			gui.text(64,-9,"setting display2")
		end
	else --setting displayMode1
		if inputs.shift then
			display1Set = true
		elseif inputs.numpad0 then
			displayMode1 = 0
			display1Set = true
		elseif inputs.numpad1 then
			displayMode1 = 1
			display1Set = true
		elseif inputs.numpad2 then
			displayMode1 = 2
			display1Set = true
		elseif inputs.numpad3 then
			displayMode1 = 3
			display1Set = true
		end
		gui.text(64,-9,"setting display1")
	end
end

local function read_hit_data(index,address)
	hit_collisions[index].index = index

	local temp = memory.readdword(address+0x14)
	hit_collisions[index].hitDetails = {
		hit_addr = temp,
		x1  = memory.readwordsigned(address+0x24),
		y1  = memory.readwordsigned(address+0x26),
		x2  = memory.readwordsigned(address+0x28),
		y2  = memory.readwordsigned(address+0x2a),
		hp  = memory.readword(address+0x238),
		dmg = memory.readwordsigned(temp+0x14),
		efc = memory.readbyte(temp+0xa),
		pwr = memory.readbytesigned(temp+0xb)
	}
end



local function draw_hit_collisions()
	local condition = (displayMode1 == 2 or displayMode2 == 2)
	--use the condition for which table indeces to write
	for i=#hit_collisions,1,-1 do
		local hitDetails = hit_collisions[i].hitDetails
		local EfctColor = get_efc_color(hitDetails.efc)
		gui.box(hitDetails.x1 - screenX, hitDetails.y1 - 191 - screenY,
			hitDetails.x2 - screenX, hitDetails.y2 - 191 - screenY,
			EfctColor, 0xF0F0F080)
		if condition then
			gui.text(hitDetails.x2 - screenX, hitDetails.y2 - screenY - 191,
				hit_collisions[i].index)
			if hit_collisions[i].hitDetails.hp > 0 then
				gui.text(hitDetails.x2 - screenX, hitDetails.y1 - screenY - 199,
				hitDetails.hp, 0xFF0000C0)
			end
		end
	end

	if not condition then
		for i=#game_objects,1,-1 do
			gui.text(game_objects[i].x - screenX + 1, game_objects[i].y - 192 - screenY,
			game_objects[i].index)
		end
	end
end

local function draw_mot_center()
	for i, obj in ipairs(game_objects) do
		local cl = 0x80FFFFFF
		local x, y = obj.x - screenX, obj.y - 192 - screenY
		gui.pixel(x    , y    , cl)
		gui.pixel(x    , y + 1, cl)
		gui.pixel(x + 1, y    , cl)
		gui.pixel(x    , y - 1, cl)
		gui.pixel(x - 1, y    , cl)
		gui.pixel(x    , y + 2, cl)
		gui.pixel(x + 2, y    , cl)
		gui.pixel(x    , y - 2, cl)
		gui.pixel(x - 2, y    , cl)
	end
end

local function handle_display_mode()
	if inputs.tilde then
		listenForKey = true
		display1Set = false
		display2Set = false
	end

	if listenForKey then
		set_display_mode();
	end
end

local function create_object_table()
	--clear any objects in the table
	hit_collisions = {}
	local temp

	--initialize the object tables with addresses
	for i=0x2,0x20 do --grab range = 1. Don't display
		temp = memory.readdword(0x02076f00+4*(i-1))
		while (temp ~= 0 and #hit_collisions < 23) do
			table.insert(hit_collisions, {
				addr = temp,
				hitDetails = {}
			})
			temp = memory.readdword(temp)
		end
	end

	for i=1,#hit_collisions do
		read_hit_data(i, hit_collisions[i].addr)
	end

	for i=1,#game_objects do
		game_objects[i] = nil
	end

	for i=0x1,0x7 do
		temp = memory.readdword(0x02049dec+4*(i-1))
		while (temp ~= 0 and #game_objects < 23) do
			--give the table a maximum size of 23 so it doesn't go past the screen
			table.insert(game_objects, { 
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

	for i, obj in ipairs(game_objects) do
		temp = obj.addr
		obj.index = i
		obj.x = memory.readdwordsigned(temp + 0x80)/0x10000
		obj.y = memory.readdwordsigned(temp + 0x84)/0x10000
		obj.spd_x = memory.readwordsigned(temp + 0x88)
		obj.spd_y = memory.readwordsigned(temp + 0x8a)
	end
end

local function draw_display()
	local topOffset = -191
	local bottomOffset = 1

	if (displayMode1 ~= 0) then
		mode_funcs[draw_modes[displayMode1]](topOffset)
	end

	if (displayMode2 ~= 0) then
		mode_funcs[draw_modes[displayMode2]](bottomOffset)
	end

	if not (displayMode1 == 0 and displayMode2 == 0) then
		draw_hit_collisions()
	end
	draw_mot_center()
end

local function main()
	inputs = input.get()

	screenX=memory.readword(0x0204222e)
	screenY=memory.readword(0x0204222a)

	--use the tilde, numpad, and shift keys to change displays!
	handle_display_mode()

	--create the array of hitboxes and hurtboxes addresses to draw
	create_object_table()

	--display things on the top and bottom screens
	draw_display()
end

gui.register(main)