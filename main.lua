require("preload")
game.gameStates	= require("states.GameStates")
game.mobileStates	= require("states.MobileStates")
game.playerStates	= require("states.PlayerStates")
game.enemyStates	= require("states.EnemyStates")
local Camera		= require 'ext.Camera'
local Player         	= require("objects.Player")
local Enemy         	= require("objects.Enemy")

local function beginContact(a, b, coll)
	local userData1 =  a:getUserData()
	local userData2 = b:getUserData()
	if userData2.id == 1 and userData1.id == 0 then
		userData2:destroy()
	end
	if userData2.id == 2 and userData1.id == 3 then
		userData1.contact = userData2	
	end
	if userData1.id == 2 and userData2.id == 3 then
		userData2.contact = userData1			
	end 
end
 
local function endContact(a, b, coll)
	local userData1 =  a:getUserData()
	local userData2 = b:getUserData()

	if userData2.id == 2 and userData1.id == 3 then
		userData1.contact = nil	
	end
	if userData1.id == 2 and userData2.id == 3 then
		userData2.contact = nil			
	end
end
 
local function preSolve(a, b, coll)
 
end
 
local function postSolve(a, b, coll, normalimpulse, tangentimpulse)
 
end


function love.load()
	--love.graphics.setDefaultFilter('nearest', 'nearest')
	--love.graphics.setBlendMode( 'replace' )
	--[[game.bg_image = love.graphics.newImage("background.png")
	game.bg_image:setWrap("repeat", "repeat")
	game. bg_quad = love.graphics.newQuad(0, 0, 20000, 20000, game.bg_image:getWidth(), game.bg_image:getHeight())
	]]
	
	--love.window.setFullscreen(true)
	love.window.setMode(800,600,{resizable=true})
	game.guiCanvas = love.graphics.newCanvas()
	game.centerX = 800/2
	game.centerY = 600/2
	
	game.world = love.physics.newWorld(0,0, true)
	game.world:setCallbacks(beginContact, endContact, preSolve, postSolve)
	game.camera = Camera()
	game.camera:setFollowStyle('NO_DEADZONE')
	game.camera:setFollowLerp(0.05)
	
	
	game.objects = {} -- table to all our physical objects
 	--[[
	local block = {}
	block.body = love.physics.newBody(game.world, 650/2, 650-50/2,"static") --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
	block.shape = love.physics.newRectangleShape(650, 50) --make a rectangle with a width of 650 and a height of 50
	block.fixture = love.physics.newFixture(block.body, block.shape) --attach shape to body
	block.fixture:setUserData(game.wallUserData)
	table.insert(game.objects,block)
	for i=1,6000 do 
		local block = {}
		block.body = love.physics.newBody(game.world, math.random(-15000,15000), math.random(-15000,15000),"static")
		block.shape = love.physics.newRectangleShape(math.random(20,300), math.random(20,300))
		block.fixture = love.physics.newFixture(block.body, block.shape)
		block.fixture:setUserData(game.wallUserData)
		table.insert(game.objects,block)	
	end
	]]
	for i,v in pairs(game.music) do
		v:setVolume(0)
	end
	game.currentMusic = game.music[love.math.random(1,#game.music)]
	game.currentMusic:play()
	game:setState(game.gameStates.waitingForPlayers)
end




function love.update(dt)
	
	--update game based off game state
	game.update(dt)
	
	--destroy any objects in the queue
	for i,v in pairs(game.destoryQueue) do
		v:destroy()
	end
	game.destoryQueue = {}
	
	--play next song
	if not game.currentMusic:isPlaying( ) then
		game.currentMusic = game.music[love.math.random(1,#game.music)]
		game.currentMusic:play()
	end
end

function love.draw()
	--draw game
	game.draw()
	if game.UPDATEGUI then game.updateGui() game.UPDATEGUI = nil end
	--debug stuff
	--[[local cx, cy = game.camera:toWorldCoords(10,game.centerY+35)
	game.print('FPS '..love.timer.getFPS(),cx, cy,false,0.3)
	local loading = 0
	for i,v in pairs(game.canvasUpdates) do loading = loading +1 end
	local loadBar = loading/100*100
	love.graphics.setColor(0,1,1)
	love.graphics.rectangle('fill' ,cx, cy+32, loadBar, 10 )]]
end

function love.resize(w,h)
	game.camera.w = w
	game.camera.h = h
	game.centerX = w/2
	game.centerY = h/2
	game.updateGuiOffsets(w,h)
	game.guiCanvas = love.graphics.newCanvas()
	game.updateGui()
end
