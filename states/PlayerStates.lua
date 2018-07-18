
local PlayerStates		= {"new","mainMenu","playing","dead"}
PlayerStates.new		= 1
PlayerStates.mainMenu	= 2
PlayerStates.playing	= 3
PlayerStates.dead		= 4

PlayerStates.update = {}
PlayerStates.draw = {}
PlayerStates.update[1] = function(player,dt)--no updates on new state
end

PlayerStates.update[2] = function(player,dt)
	if player.joystick:isGamepadDown('back') then
		game:setState(game.gameStates.shutdown)
	end
	if player.joystick:isGamepadDown('start') then
		game:setState(game.gameStates.playing)
	end
end

PlayerStates.update[3] = function(player,dt)
	if player.reloading then 
		player.reloading = player.reloading - dt 
		if player.reloading <= 0 then player:reloaded() end
	end
	if player.rateOfFire then 
		player.rateOfFire = player.rateOfFire - dt 
		if player.rateOfFire <= 0 then player.rateOfFire = nil end
	end
	if player.wepSelect then 
		player.wepSelect = player.wepSelect - dt 
		if player.wepSelect <= 0 then player.wepSelect = nil end
	end
	
	player:move()
	player:updateRightAxis()	
	player:getTriggerAxis()
	if player.joystick:isGamepadDown('rightshoulder') then
		player:fire()
	elseif player.joystick:isGamepadDown('leftshoulder') then
		player:changeWeaponNext()
	end
	if player.joystick:isGamepadDown('y') then
		if player.data.weapons[player.selectedWeapon].ammo ~= player.weapon.ammo then
			player:reload()
		end
	end
	
	if player.joystick:isGamepadDown('x') then
		local tile,chunk = game.map:getTile(player.object.body:getX(),player.object.body:getY())
		print('!',tile.elevation,tile.TESTDATA)
		for i,v in pairs(tile.overLay) do
			print(i)
		end
	end
	
	if player.joystick:isGamepadDown('b') and not player.rateOfFire then
		--[[player:ROF(1)
		local tile,chunk = game.map:getTile(player.object.body:getX()+player.xn * 40,player.object.body:getY()+player.yn * 40)
		tile:setAsWall(1)]]
	end
	if player.joystick:isGamepadDown('back') then
		game:setState(game.gameStates.shutdown)
	end
	if player.animation then player.animation:update(dt) end
	player.fireAnimation:update(dt)
end

PlayerStates.update[4] = function(player,dt)
	player.respawnTimer = player.respawnTimer - dt 
	if player.respawnTimer <= 0 then 
		player:respawn()
	end
	if player.animation then player.animation:update(dt) end
end

return PlayerStates
