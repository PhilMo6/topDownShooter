local lfs = love.filesystem
love.math.setRandomSeed(os.time())
love.math.random() love.math.random() love.math.random()
require("ext.math") require("ext.table")
local anim8 = require 'ext.anim8'
love.filesystem.createDirectory('chunks')
_G.game = {}
game.config		= require("config")
game.enemies = {}
game.players = {}
game.playerJoysticks = {}
game.bullets = {}
game.damage = {}
game.destoryQueue = {}
game.images = {}
game.animations = {}
game.chunkx,game.chunky = 0,0
game.newSpawn =game.config.defaultSpawn

function game:setState(state)
	if not game.gameStates[state] or game.state == state then return end
	game.state = state
	game.update = game.gameStates.update[state]
	game.draw = game.gameStates.draw[state]
	if game.gameStates.set[state] then game.gameStates.set[state]() end
end

function game.pointInRect( pointX, pointY, left, top, width, height )
	if pointX >= left and pointX <= left + width and pointY >= top and pointY <= top + height then 
		return true
	else
		return false
	end
end

function game.updateGuiOffsets(w,h)
	game.config.gui={{5,10},--topleft
	{w-(game.config.alphaOffsetX*2),10,true},--top right
	{5,h-(game.config.alphaOffsetY*2),false,true},--bottomleft
	{w-(game.config.alphaOffsetX*2),h-(game.config.alphaOffsetY*2),true,true}}--bottomright
end

function game.updateGui()
	love.graphics.setCanvas(game.guiCanvas)
	love.graphics.clear()
	love.graphics.setColor(1,1,1)
	for _,player in ipairs(game.players) do
		local id = player.playerID
		local cx, cy = game.config.gui[id][1],game.config.gui[id][2]
		game.print(''..player.score,cx,cy,game.config.gui[id][3],0.2)
		--draw hp bar
		local hpBar = player.hp/player.data.hpMax*100/2
		love.graphics.setColor(1,0,0)
		love.graphics.rectangle('fill' ,(game.config.gui[id][3] and cx - hpBar or cx) + 10, game.config.gui[id][4] and cy - 20 or cy + 20, hpBar, 10 )
	end
	local zCount = 'Zombies:'..#game.enemies
	game.print(zCount,game.centerX-string.len(zCount),10,false,0.3)
	love.graphics.setCanvas()
end

function game.drawGui()
	local scale = 1 / game.camera.scale
	if scale < 1 then scale = 1  + scale end
	love.graphics.setBlendMode("alpha", "premultiplied")
	local cx, cy = game.camera:toWorldCoords(0,0)
	love.graphics.draw(game.guiCanvas, cx,cy,0,scale,scale)
	love.graphics.setBlendMode("alpha")
end

game.alphanumerics = {}

game.images['alpha'] = love.graphics.newImage('sprites/alphanumericFull.png')

local g = anim8.newGrid(game.config.alphaOffsetX,game.config.alphaOffsetY, game.images['alpha']:getWidth(), game.images['alpha']:getHeight())
local charOffset = string.byte("A")
for i,v in ipairs(g('1-10',1,'1-10',2,'1-6',3)) do 
	game.alphanumerics[string.char(charOffset)]=v
	charOffset = charOffset + 1
 end
 
local charOffset = string.byte("a")
for i,v in ipairs(g('1-10',4,'1-10',5,'1-6',6)) do 
	game.alphanumerics[string.char(charOffset)]=v
	charOffset = charOffset + 1
 end
 
local charOffset = string.byte("0")
for i,v in ipairs(g('1-10',7)) do 
	game.alphanumerics[string.char(charOffset)]=v
	charOffset = charOffset + 1
 end
 
local frames = g('1-9',8)
game.alphanumerics['!']=frames[1]
game.alphanumerics['?']=frames[2]
game.alphanumerics['#']=frames[3]
game.alphanumerics['%']=frames[4]
game.alphanumerics['(']=frames[5]
game.alphanumerics[')']=frames[6]
game.alphanumerics['.']=frames[7]
game.alphanumerics[':']=frames[8]
game.alphanumerics[' ']=frames[9]

 
 function game.print(string,x,y,flip,scale)
	local count = 0
	local x = flip and x - string.len(string) * game.config.alphaOffsetX or x
	scale = scale or 1
	local offset = game.config.alphaOffsetX * scale
	for i in string.gfind(string, ".") do
		count = count + 1
		love.graphics.draw(game.images['alpha'],game.alphanumerics[i] or game.alphanumerics[' '], x + (offset * count), y,0,scale,scale)
	end
 end

game.images['fire'] = love.graphics.newImage('sprites/guns/gunfire_long.png')
local g = anim8.newGrid(10, 8, game.images['fire']:getWidth(), game.images['fire']:getHeight())
game.animations['fire'] = anim8.newAnimation(g(1,'1-9'), 0.01,'pauseAtStart')

game.images[1] = love.graphics.newImage('sprites/hit_small.png')

game.images['hit2'] = love.graphics.newImage('sprites/hit2.png')
game.images['hit3'] = love.graphics.newImage('sprites/hit3.png')

game.images['player'] = love.graphics.newImage("sprites/human_male/pistol_grip.png")
--local g = anim8.newGrid(31, 23, game.images[1]:getWidth(), game.images[1]:getHeight())
--game.animations[1] = anim8.newAnimation(g(1,'1-1'), 0.1)

game.images[2] = love.graphics.newImage('sprites/enemies/ZOMBIE_A_WALK.png')
local g = anim8.newGrid(29,19, game.images[2]:getWidth(), game.images[2]:getHeight())
game.animations[2] = anim8.newAnimation(g(1,'1-4'), 0.1)

game.images[3] = love.graphics.newImage('sprites/enemies/ZOMBIE_A_DEATH_2.png')
local g = anim8.newGrid(55,23, game.images[3]:getWidth(), game.images[3]:getHeight())
game.animations[3] = anim8.newAnimation(g(1,'1-7'), 0.1,'pauseAtEnd')

game.weapons = {}
local dir = "objects/weapons"
local files =lfs.getDirectoryItems(dir)
for k, file in ipairs(files) do
	if string.match(file, "(.+)%.lua") then
		local weapon = require(string.gsub(dir, "/", ".")..'.'..string.gsub(file,'.lua','')) 
		weapon:new()
	end
end

function game.loadTiles()
	local tileSize = game.config.tileSize
	local tileCenter = tileSize/2
	local function applyAngles(imgData,corner)
		local imgAngles = {}
		for i,angle in ipairs(game.config.angles) do
			if angle ~= 0 then
				local canvas = love.graphics.newCanvas(tileSize,tileSize)
				love.graphics.setCanvas(canvas)
				love.graphics.draw(love.graphics.newImage(imgData),tileCenter,tileCenter,math.rad(angle),1,1,tileCenter,tileCenter)
				love.graphics.setCanvas()
				local newImage = canvas:newImageData( )
				imgAngles[angle] = newImage
				if corner then 
					imgAngles[game.config.cornerAngles[i]]  = newImage
	--print(game.config.cornerAngles[i],angle)
					local drawable = love.graphics.newImage(newImage)
					table.insert(game.testDraw2,drawable)
				else
					local drawable = love.graphics.newImage(newImage)
					table.insert(game.testDraw1,drawable)
				end
				table.insert(imgAngles,newImage)
			else
				imgAngles[angle] = imgData
				if corner then 
					imgAngles[game.config.cornerAngles[i]]  = imgData
	--print(game.config.cornerAngles[i],angle)
					local drawable = love.graphics.newImage(imgData)
					table.insert(game.testDraw2,drawable)
				else
					local drawable = love.graphics.newImage(imgData)
					table.insert(game.testDraw1,drawable)
				end
				table.insert(imgAngles,imgData)
			end
		end
		return imgAngles
	end

	local tiles = {}
	game.walls = {}



	game.testDraw1 = {}
	game.testDraw2 = {}

	--load tiles and apply angles to each tile variation.
	--tiles are indexed by type and angle
	local tileSpriteSheet = love.image.newImageData('sprites/terrain2.png')


	local y = 1 * tileSize
	for i=0,3 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['dirtEdge'..i] = applyAngles(rawImg)
	end
	index = 0
	for i=4,7 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['dirtInCorner'..index] = applyAngles(rawImg,true)
		index = index + 1
	end


	local y = 0 * tileSize
	for i=0,3 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['water'..i] = applyAngles(rawImg)
	end
	local index = 0
	for i=4,7 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['dirtOutCorner'..index] = applyAngles(rawImg,true)
		index = index + 1
	end




	local y = 2 * tileSize
	for i=0,3 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['dirt'..i] = applyAngles(rawImg)
	end
	index = 0
	for i=4,7 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['grassOutCorner'..index] = applyAngles(rawImg,true)
		index = index + 1
	end

	local y = 3 * tileSize
	for i=0,3 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['grassEdge'..i] = applyAngles(rawImg)
	end
	index = 0
	for i=4,7 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['grassInCorner'..index] = applyAngles(rawImg,true)
		index = index + 1
	end

	local y = 4 * tileSize
	for i=0,3 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['grass'..i] = applyAngles(rawImg)
	end
	index = 0
	for i=4,7 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['waterGrassCorner'..index] = applyAngles(rawImg)
		index = index + 1
	end

	local y = 5 * tileSize
	for i=0,3 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['waterGrass'..i] = applyAngles(rawImg)
	end
	index = 0
	for i=4,7 do
		local x = i * tileSize
		local rawImg = love.image.newImageData( tileSize, tileSize )
		rawImg:paste( tileSpriteSheet, 0, 0, x, y, tileSize, tileSize )
		tiles['grassWaterCorner'..index] = applyAngles(rawImg)
		index = index + 1
	end
	index = nil
	game.tiles = tiles
end


--setup map objects
game.mapObjects = {}

--Tree spriteSheet
game.images['trees'] = love.graphics.newImage('sprites/treeSet.png')

game.mapObjects['tree'] = {}
game.mapObjects['tree'].image = game.images['trees']
game.mapObjects['tree'].hitImage = game.images['hit3']
game.mapObjects['tree'].hitOffset = 1

--find quads for trees and set mapObject info
local g = anim8.newGrid(120,120, game.images['trees']:getWidth(), game.images['trees']:getHeight())
for i,v in ipairs(g(1,1)) do 
	table.insert(game.mapObjects['tree'],{quad=v,depth=0})
 end
for i,v in ipairs(g('2-7',1,'1-7',2,1,3)) do 
	table.insert(game.mapObjects['tree'],{quad=v,depth=0,speed=0.9})
 end
 for i,v in ipairs(g(2,3)) do 
	table.insert(game.mapObjects['tree'],{quad=v,depth=0,speed=0.8,radius=8})
 end 
 for i,v in ipairs(g('2-7',3,'1-7',4,'1-4',5)) do 
	table.insert(game.mapObjects['tree'],{quad=v,depth=0,speed=0.5,radius=15})
 end
  for i,v in ipairs(g('5-7',5,'1-5',6)) do 
	table.insert(game.mapObjects['tree'],{quad=v,depth=1,speed=0.5,radius=20})
 end
for i,v in ipairs(g('6-7',6,1,7)) do 
	table.insert(game.mapObjects['tree'],{quad=v,depth=1,radius=10})
 end







--[[
local dir = "tiles/tiles"
local files =lfs.getDirectoryItems(dir)
for _, tile in ipairs(files) do
	if not tiles[tile] then tiles[tile] = {} end
	local angles =lfs.getDirectoryItems(dir..'/'..tile)
	for _, angle in ipairs(angles) do
		if not tiles[tile][angle] then tiles[tile][angle] = {} end
		local drawAngles =lfs.getDirectoryItems(dir..'/'..tile..'/'..angle)
		for _, drawangle in ipairs(drawAngles) do
			local fileToLoad = dir..'/'..tile..'/'..angle..'/'..drawangle.. '/'..'0.png'
			local img = love.image.newImageData(fileToLoad)
			if tile == 'deep0' then img:setPixel(0,0,0,0,1,1)
			elseif string.match(tile, "grass") then img:setPixel(0,0,0,1,0,1)
			end
			tiles[tile][angle][drawangle] = img
		end
	end
end]]

--[[local dir = "tiles"
local files =lfs.getDirectoryItems(dir)
for k, file in ipairs(files) do
	if string.match(file, "(.+)%.png") then
		local tile = love.graphics.newImage(dir..'/'..file)
		tile:setWrap("repeat", "repeat")
		game.tiles[string.gsub(file,'.png','')] = tile
		table.insert(game.tiles,tile)
	end
end]]
--[[
game.images['tileset'] = love.graphics.newImage('tiles/terrain3.png')
game.images['tileset2'] = love.graphics.newImage('tiles/tileset1.png')
--local g = anim8.newGrid(32,32,  tilesetW, tilesetH)

local tilesetW, tilesetH = game.images['tileset']:getWidth(), game.images['tileset']:getHeight()
local tileW,tileH = 33,33
for y = 0,5 do
	for x = 0, 7 do
		table.insert(game.tiles,love.graphics.newQuad(x*tileW, y*tileH, tileW, tileH, tilesetW, tilesetH))
	end
end

for i=1,6 do
	for id,v in pairs(g('1-8',i)) do 
		table.insert(game.tiles,v)
	end
end

local g = anim8.newGrid(32,32, game.images['tileset2']:getWidth(), game.images['tileset2']:getHeight())
for i,v in pairs(g(1,3)) do 
	table.insert(game.walls,v)
end
]]


game.music = {}
game.effect = {}
local dir = "sound"
local files =lfs.getDirectoryItems(dir)
for k, file in ipairs(files) do
	if string.match(file, "(.+)%.mp3") or string.match(file, "(.+)%.ogg") then
		local music =  love.audio.newSource(dir..'/'..file,'stream')
		game.music[string.gsub(file,'.mp3','')] = music
		table.insert(game.music,music)
		music:setLooping(false)
		music:setVolume(0.5)
	elseif  string.match(file, "(.+)%.wav") then
		local effect = love.audio.newSource(dir..'/'..file,'static')
		game.effect[string.gsub(file,'.wav','')] = effect
		table.insert(game.effect,effect)
		effect:setLooping(false)
	end
end
game.effect['GunReload']:setVolume(5)

game.wallUserData = {id=0,type='wall',hitImage = game.images['hit2'],hitOffset = 1}
--game.treeUserData = {id=0,type='tree',hitImage = game.images['hit3'],hitOffset = 1}

