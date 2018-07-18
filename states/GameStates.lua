local Player         	= require("objects.Player")
local Enemy         		= require("objects.Enemy")
local Map      		= require("objects.Map")
local GameStates			= {'new','waitingForPlayers','mainMenu','playing','endGame','shutdown'}
GameStates.new			= 1
GameStates.waitingForPlayers	= 2
GameStates.mainMenu		= 3
GameStates.playing			= 4
GameStates.endGame		= 5
GameStates.shutdown		= 6

GameStates.set = {}
GameStates.update = {}
GameStates.draw = {}

GameStates.update[1] = function(dt)
	--timer to set state to next state after opening animation is done
end

GameStates.draw[1] = function()
	--draw opening animation
end


GameStates.update[2] = function(dt)
	local joysticks = love.joystick.getJoysticks()
	for i, joystick in ipairs(joysticks) do
		if not game.playerJoysticks[joystick:getID()] and joystick:isGamepadDown('a') then
			local player1 = Player:new(joystick)
			game:setState(game.gameStates.mainMenu)
			break
		end
	end
	--update players
	for i,v in ipairs(game.players) do
		v:update(dt)
	end
	if #game.players > 1 then game.camera:setFollowLerp(0) end
end
GameStates.draw[2] = function()
	if not game.tiles then
		game:loadTiles()
		game.map =Map:new()
	end
	love.graphics.setBackgroundColor(0.28, 0.63, 0.05)
	love.graphics.setColor(1,1,1)
	local cx, cy = game.camera:toWorldCoords(10,game.centerY)
	game.print('WAITING FOR PLAYERS!'..#game.players,cx, cy,false,0.3)
	game.drawGui()
	game.map:update(dt)
end
GameStates.set[3] = function()
	for i,v in ipairs(game.players) do
		v:setState(game.playerStates.mainMenu)
	end
end
GameStates.update[3] = GameStates.update[2]
GameStates.draw[3] = GameStates.draw[2]



GameStates.set[4] = function()
	for i,v in ipairs(game.players) do
		v:setState(game.playerStates.playing)
		v.score = 0
	end
end

local xChanPush,yChanPush = love.thread.getChannel( 'loadX' ),love.thread.getChannel( 'loadY' )
GameStates.update[4] = function(dt)
	--update game world
	game.world:update(dt)
	--update players
	for i,v in ipairs(game.players) do
		v:update(dt)
	end
	--update enemies
	for i,v in ipairs(game.enemies) do
		v:update(dt)
	end
	--update bullets
	for i,v in ipairs(game.bullets) do
		v:update(dt)
	end
	--update damge animation
	for i,v in ipairs(game.damage) do
		v[5] = v[5] - dt
		if v[5] < 0 then table.remove(game.damage,i) end
	end
	if game.newSpawn then
		for i=1,game.newSpawn do
			local spawnpoint = game.players[love.math.random(1,#game.players)]
			Enemy:new(spawnpoint.object.body:getX(),spawnpoint.object.body:getY())
			game.newSpawn = nil
			game.UPDATEGUI = true
		end
	end
	
	--scale camera out and update chunks based off location of players
	local chunkx,chunky = 0,0
	local scaleOut, scaleIn,noScale
	local scale,camMaxDis,camMinDis,maxScale ,minScale = game.camera.scale, game.config.camMaxDis, game.config.camMinDis, game.config.maxScale, game.config.minScale
	for i,v in ipairs(game.players) do
		local trigx,trigy = v:getTriggerAxis()
		local x,y = v.object.body:getX(),v.object.body:getY()
		local cx, cy = game.camera:toCameraCoords(x,y)
		local dis = math.getDistance(cx,cy,game.centerX,game.centerY)
		if dis > camMaxDis and scale > minScale then
			scaleOut = true
		elseif dis < camMinDis and scale < maxScale then
			scaleIn = true
		else
			noScale = true
		end
		if trigx > 0 or trigy > 0 then
			scaleIn = nil
			if scale > minScale then
				scaleOut = true
			end
		end
		chunkx,chunky = chunkx + x,chunky + y
	end 
	chunkx,chunky = chunkx/#game.players,chunky/#game.players
	game.camera:follow(chunkx,chunky)
	chunkx = math.floor(chunkx/game.config.chunkWidth)
	chunky = math.floor(chunky/game.config.chunkWidth)
	if chunkx ~= game.chunkx then
		xChanPush:push(chunkx)
		game.chunkx = chunkx
	end
	if chunky ~= game.chunky then
		yChanPush:push(chunky)
		game.chunky = chunky
	end
	if scaleIn and not scaleOut and not noScale  then
		game.camera.scale = game.camera.scale + 0.002
	elseif scaleOut then
		game.camera.scale = game.camera.scale - 0.002
	end
	game.camera:update(dt)
	
	local xy = chunkx..','..chunky
	game.map:update(dt,xy)
	
end
GameStates.draw[4] = function()
	game.camera:attach()
	game.map:draw()
	
	local scale = 1 / game.camera.scale
	if scale < 1 then scale = 1  + scale end
	-- draw the enemies
	for i,v in ipairs(game.enemies) do
		local x,y,r = v.object.body:getX(), v.object.body:getY(), v.object.shape:getRadius()
		love.graphics.setColor(v.color[1],v.color[2],v.color[3])
		love.graphics.circle("line", x, y, r)
		love.graphics.setColor(1,1,1)
		v.animation:draw(v.image, x, y,v.angle,v.scale,v.scale,v.offsetx,v.offsety)
	end
	-- draw the players
	for i,v in ipairs(game.players) do	
		local x,y,r = v.object.body:getX(), v.object.body:getY(), v.object.shape:getRadius()
		--draw hp bar
		--love.graphics.setColor(1,0,0)
		--love.graphics.arc( 'line','open', x, y, r+3,-0.1, v.hpBar )
		--draw player circle
		love.graphics.setColor(v.color[1],v.color[2],v.color[3])
		love.graphics.circle("line", x, y, r*scale)
		--draw aim reticule
		love.graphics.circle("line", x+v.xn * 60*scale, y+v.yn * 60*scale,3*scale)
		--if reloading draw reloading bar
		if v.reloading then 
			love.graphics.arc( 'fill', x, y, (r+6) * scale,-0.1, v.reloading/v:getReloadDelay()*6, 90) 
		else 
			love.graphics.arc( 'line', x, y,(r+6) * scale,-0.1, v:getAmmo()/v:getMaxAmmo()*6, 90 )
		end
		love.graphics.setColor(1,1,1)
		if v.animation then--if player has animation draw that else draw image
			v.animation:draw(v.image, x,y,v.angle,v.scale,v.scale,v.offsetx,v.offsety)
		else
			love.graphics.draw(v.image, x,y,v.angle,v.scale,v.scale,v.offsetx,v.offsety)
		end
		--draw players firing animation
		v.fireAnimation:draw(v.fireimage, v.firex, v.firey,v.angle,v.scale,v.scale,v.offsetFirex,v.offsetFirey)
	end
	love.graphics.setColor(0, 0, 0)
	for i,v in ipairs(game.bullets) do
		if not v.body then
			love.graphics.circle("fill", v.x, v.y, v.size)
		elseif not v.body:isDestroyed() then
			love.graphics.circle("fill", v.body:getX(), v.body:getY(), v.shape:getRadius())
		end
	end
	love.graphics.setColor(1,1,1)
	for i,v in ipairs(game.damage) do
		love.graphics.draw(v[1], v[2], v[3],v[4])
	end
	

	game.map:DrawObjectLayerHigh()
	
	game.drawGui()
	
	
	
	
	local cx, cy = game.camera:toWorldCoords(10,game.centerY+45)
	game.print('FPS '..love.timer.getFPS(),cx, cy,false,0.3 * scale)
	--[[cx, cy = game.camera:toWorldCoords(10,game.centerY)
	local count = 0
	for i,v in pairs(game.testDraw1) do
		local x,y = cx+ (count * game.config.tileSize), cy
		love.graphics.draw(v,x,y)
		count = count + 1
	end
	count = 0
	for i,v in pairs(game.testDraw2) do
		local x,y = cx + (count * game.config.tileSize), cy - game.config.tileSize
		love.graphics.draw(v,x,y)
		count = count + 1
	end
	]]
	
	
	love.graphics.setColor(1,1,1)
	game.camera:detach()
	game.camera:draw()
end

local endgame = false


GameStates.set[5] = function(dt)
	if not endgame then
		endgame = 0
		for i,v in ipairs(game.enemies) do
			table.insert(game.destoryQueue,v)
		end
		game.camera:fade(2,{0.7,0,0,0.1},function()
			endgame = 1
			game.camera:fade(0.1,{0,0,0,0})
		end)
	end
end
GameStates.update[5] = function(dt)
	if endgame == 1 then endgame = endgame + dt end
	if endgame > 120 then 
		endgame = nil 
		game:setState(game.gameStates.mainMenu)
		for i,v in ipairs(game.players) do
			v:respawn()
		end
		game.newSpawn = game.config.defaultSpawn		
	end
end
GameStates.draw[5] = function()
	if endgame >= 1 then 
		love.graphics.setBackgroundColor(0.28, 0.63, 0.05)
		love.graphics.setColor(1,1,1)
		local cx, cy = game.centerX,game.centerY --game.camera:toWorldCoords(game.centerX,game.centerY)
		for i,v in ipairs(players) do
			game.print('Score:'..v.score,cx,cy,false,0.3)
			cy = cy + 20
		end	
		game.print('Total zombies killed',cx, cy,false,0.4)
		game.print(killCount,cx, cy+25,false,0.4)
	else
		game.camera:attach()
		game.map:draw()
		game.drawGui()
		game.camera:detach()
		game.camera:draw()
	end
end

GameStates.update[6] = function(dt)
	love.event.quit()
end
GameStates.draw[6] = function()
end



--[[
GameStates.update[] = function(dt)
end
GameStates.draw[] = function()
end
]]

return GameStates
