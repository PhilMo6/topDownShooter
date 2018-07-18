
local Cloneable		= require("objects.Cloneable")
local Player		= Cloneable.clone()
Player.id = 2
Player.type = 'player'


--player defaults
Player.data		= {}
Player.data.speed	= 200
Player.data.deadzone = 0.05
Player.data.hpMax = 100


Player.scale = 1
Player.image = game.images['player']
Player.offsetx,Player.offsety = Player.image:getWidth()/2,Player.image:getHeight()/2

Player.fireimage = game.images['fire']
Player.offsetFirex,Player.offsetFirey = game.animations['fire']:getDimensions()
Player.offsetFirex,Player.offsetFirey = Player.offsetFirex/2,Player.offsetFirey/2

Player.hitImage = game.images[1]
Player.hitOffset = -0.8

--- Initialize the Player
-- joystick = joystick object used for this players input
function Player:initialize(joystick)
	self:setState(game.playerStates.new)
	--add to games player table
	table.insert(game.players,self)
	self.playerID = #game.players
	
	--controls used for input
	if joystick then
		self.joystick = joystick
		self.control = 'joystick'
		game.playerJoysticks[joystick:getID()] = true
	else
		self.keyboard = true
		self.control = 'keyboard'
	end
		
	--players data table with info that can be saved
	self.data 					= {}
	self.data.name				= "none"
	self.data.level				= 0
	self.data.exp				= 0
	self.data.hpMax				= Player.data.hpMax 
	self.data.speed 				= Player.data.speed
	self.data.deadzone 			= Player.data.deadzone
	--control bindings
	self.data.controls = {attack1='rightshoulder',start='start',quit='back'}
	--weapons list
	self.data.weapons = {}
	self:addWeapon(game.weapons['Pistol'])
	self:addWeapon(game.weapons['Rifle'])
	self:addWeapon(game.weapons['uzi'])
	self:addWeapon(game.weapons['Shotgun'])
	self:addWeapon(game.weapons['Railgun'])
	
	--physics object
	object = {}
	object.body = love.physics.newBody(game.world, math.random(-200,200), math.random(-200,200),"dynamic")
	object.shape = love.physics.newCircleShape(15)
	object.fixture = love.physics.newFixture(object.body, object.shape)
	object.fixture:setUserData(self)
	object.body:setLinearDamping(4)
	object.body:setMass(100)
	self.object = object
	
	--runtime data
	self.score = 0
	self.hp = Player.data.hpMax
	self.hpBar = self.hp/self.data.hpMax/100*360
	self.color = game.config.playerColors[self.playerID] or {love.math.random(0,1),love.math.random(0,1),love.math.random(0,1)}
	self.lastLeftX,self.lastLeftY,self.lastRightX,self.lastRightY = 1,0,1,0
	self.angle=0
	--self.animation = game.animations[1]:clone()
	self.fireAnimation = game.animations['fire']:clone()
	self.fireAnimation:pauseAtStart()
	local x,y = self:getRightAxis()
	self.xn,self.yn = math.normalize(x,y)
	self.firex = self.object.body:getX()+self.xn * 22
	self.firey = self.object.body:getY()+self.yn * 22 
	self.selectedWeapon = 1
	self.weapon = self:getWeapon()

	--sounds
	self.soundEffect = game.effect['shot']:clone()
	self.reloadEffect = game.effect['GunReload']:clone()

	self:setState(game.playerStates.mainMenu)
	game.updateGui()
end

function Player:getWeapon()
	return game.weapons[self.data.weapons[self.selectedWeapon].type]
end

function Player:addWeapon(weapon)
	if not self.data.weapons[weapon.type] then
		self.data.weapons[weapon.type] = {type=weapon.type,exp=0,ammo=weapon.ammo}
		table.insert(self.data.weapons,self.data.weapons[weapon.type])
	end
end

function Player:changeWeaponNext()
	if not self.wepSelect and not self.rateOfFire then
		local oldWep = self.weapon
		self.wepSelect = 0.5
		self.selectedWeapon = self.data.weapons[self.selectedWeapon + 1] and self.selectedWeapon + 1 or 1
		self.weapon = self:getWeapon()
		self.image = self.weapon.image
		self.offsetx,self.offsety = self.image:getWidth()/2+self.weapon.offsetx,self.image:getHeight()/2+self.weapon.offsety
		self.reloading = nil
		--set weapons new effect if needed
		if oldWep.sound ~= self.weapon.sound then self.soundEffect:release() self.soundEffect = game.effect[self.weapon.sound]:clone() end
	end
end
function Player:changeWeaponLast()
	if not self.wepSelect and not self.rateOfFire then
		local oldWep = self.weapon
		self.wepSelect = 0.5
		self.selectedWeapon = self.data.weapons[self.selectedWeapon - 1] and self.selectedWeapon - 1 or #self.data.weapons
		self.weapon = self:getWeapon()
		self.image = self.weapon.image
		self.offsetx,self.offsety = self.image:getWidth()/2+self.weapon.offsetx,self.image:getHeight()/2+self.weapon.offsety
		self.reloading = nil
		--set weapons new effect if needed
		if oldWep.sound ~= self.weapon.sound then self.soundEffect:release() self.soundEffect = game.effect[self.weapon.sound]:clone() end
	end
end

function Player:respawn()
	self:setState(game.playerStates.playing)
	self:gainHP()
	self.deadAnimation = self.animation
	self.deadAnimation:gotoFrame(1)
	self.deadAnimation:resume(1)
	self.animation = self.liveAnimation
	self.liveAnimation = nil
	self.image = nil
	self.object.fixture:setFilterData(1, 65535, 0)--reset filter
end

function Player:dead()
	self.respawnTimer = 20
	self:setState(game.playerStates.dead)
	self.liveAnimation = self.animation
	self.animation = self.deadAnimation or game.animations[3]:clone()
	self.image = game.images[3]
	self.object.fixture:setFilterData(1, 0, 0)--set filter so other objects dont get stuck on corpse
end

function Player:takeDamge(amt)
	self.hp = self.hp - amt
	if self.hp <= 0 then
		self:dead()
	end
	game.camera:flash(0.05,{1,0,0,100})
	game.UPDATEGUI = true
end

function Player:gainHP(amt)
	self.hp = amt and self.hp + amt or self.data.hpMax
	game.UPDATEGUI = true
end

function Player:doDamge(target,amt)
	self:gainEXP(amt)
end

function Player:getLeftAxis()
	local x = self.joystick:getGamepadAxis("leftx")
        local y = self.joystick:getGamepadAxis("lefty")
	if math.abs(x) < self.data.deadzone then x = 0 end
	if math.abs(y) < self.data.deadzone then y = 0 end
	return  x,y
end

function Player:getTriggerAxis()
	local x = self.joystick:getGamepadAxis("triggerleft")
        local y = self.joystick:getGamepadAxis("triggerright")
	return  x,y
end

function Player:getRightAxis()
	return  self.lastRightX,self.lastRightY
end

function Player:updateRightAxis()
	local x = self.joystick:getGamepadAxis("rightx")
        local y = self.joystick:getGamepadAxis("righty")
	if x == 0 then x = self.lastRightX else self.lastRightX = x end
	if y == 0 then y = self.lastRightY else self.lastRightY = y end
	self.angle = math.atan2(self.lastRightY,self.lastRightX)
	self.xn,self.yn = math.normalize(self.lastRightX,self.lastRightY)
end

function Player:update(dt)
	game.playerStates.update[self.state](self,dt)
end

function Player:move()
	local x,y = self:getLeftAxis()
	if x == 0 and y == 0 then
		self:setMoveState(game.mobileStates.standing)
		--[[
		if not self.paused then
			self.animation:pauseAtStart()
			self.paused = true
		end]]
	else
		self:setMoveState(game.mobileStates.running)
		--[[
		if self.animation and self.paused then
			self.animation:resume()
			self.paused = nil
		end
		]]
	end
	local tileSpeed = game.map:getTile(self.object.body:getX(),self.object.body:getY()):getSpeed()
	local speed= self.data.speed * tileSpeed
	self.object.body:setLinearVelocity(x * speed,y * speed)
end

function Player:ROF(delay)
	if not self.rateOfFire then
		delay = delay or self.weapon.rateOfFire
		self.rateOfFire = delay
	end
end
function Player:reload()
	if not self.reloading then
		local delay = self.weapon.reload
		self.reloading = delay
	end
end
function Player:reloaded()
	self.reloading = nil
	self.data.weapons[self.selectedWeapon].ammo = self.weapon.ammo
	self.reloadEffect:play()
end

function Player:fire()
	if not self.reloading and not self.rateOfFire then
		if self.data.weapons[self.selectedWeapon].ammo <= 0 then
			return self:reload()
		else
			self:ROF()
		end
		self.data.weapons[self.selectedWeapon].ammo = self.data.weapons[self.selectedWeapon].ammo - 1
		self.firex = self.object.body:getX()+self.xn * self.weapon.offset
		self.firey = self.object.body:getY()+self.yn * self.weapon.offset 
		self.weapon:fire(self)
		self.fireAnimation:resume()
		self.soundEffect:play()
	end
end

function Player:getReloadDelay()
	return self.weapon.reload
end
function Player:getMaxAmmo()
	return self.weapon.ammo
end

function Player:getAmmo()
	return self.data.weapons[self.selectedWeapon].ammo
end

function Player:gainScore()
	self.score = self.score +1
	game.UPDATEGUI = true
end

function Player:gainEXP(ammount)
	self.data.exp = self.data.exp + ammount
	while self.data.exp >= self:nextLevel() do
		self:gainLevel()
	end
end

--gain exp
--if next level in a class gain level
function Player:gainEXP(ammount)
	self.data.exp = self.data.exp + ammount
	while self.data.exp >= self:nextLevel() do
		self:gainLevel()
	end
end

--find the next level for player
function Player:nextLevel()
    local rate = 2.5
    local baseEXP = 100
    return math.floor(baseEXP * (self:getLevel() ^ rate))
end

--gain a level
function Player:gainLevel()
	self.data.level = self.data.level + 1
	self.data.hpMax = self.data.hpMax * 2
end

--return player level
function Player:getLevel()
	return self.data.level
end

--return player exp
function Player:getEXP()
	return self.data.exp
end

--- Returns the string-value of the Player.
function Player:toString()
	return 'player'..self:getID()
end

--- Assign a name.
-- @param name Name to assign.
function Player:setName(name)
	self.data.name = name
end

--- Get current name.
-- @return Current name.
function Player:getName()
	return self.data.name
end


--- Set ID.
-- id = The ID to set.
function Player:setID(id)
	self.id = id
end

--- Gets current ID.
function Player:getID()
	return self.playerID
end

--- Set movement state.
-- state = The state to set, should be part of mobileState table.
function Player:setMoveState(state)
	self.moveState = state
end

--- Gets current movement state.
function Player:getMoveState()
	return self.moveState
end

--- Set state.
-- state = The state to set, should be part of playState table.
function Player:setState(state)
	if not game.playerStates[state] or self.state == state then return end
	self.state = state
end

--- Gets current state.
function Player:getState()
	return self.state
end

function Player:isDead()
	return self.state == game.playerStates.dead
end

--get players status for debugging
function Player:getStatus()
	return game.playerStates[self:getState()].. ' ' .. game.mobileStates[self:getMoveState()].. ' ' .. self.hp
end

return Player
