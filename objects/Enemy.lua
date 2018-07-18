
local Cloneable		= require("objects.Cloneable")
local Enemy		= Cloneable.clone()
Enemy.id = 3
Enemy.type = 'mob'

Enemy.speed	= 170
Enemy.hpMax 	= 100
Enemy.dmg	= 10
Enemy.rateOfAttack = 0.5
Enemy.color 					= {0.1,0.1,1}

Enemy.scale = 1.1
Enemy.offsetx,Enemy.offsety = 14.5,9.5
Enemy.image = game.images[2]
Enemy.hitImage = game.images[1]
Enemy.hitOffset = -0.8


--- Initialize the Enemy object
function Enemy:initialize(x,y)
	self:setState(game.enemyStates.new)
	
	self.randomID= love.math.random(-10,-100000)
	--runtime data
	self.hp = Enemy.hpMax
	self.lastLeftX,self.lastLeftY,self.lastRightX,self.lastRightY = 1,1,1,1
	self.angle=0
	self.animation = game.animations[2]:clone()
	self:setMoveState(game.mobileStates.running)
	
	object = {}
	object.body = love.physics.newBody(game.world, x and x + math.random(-200,200)*10 or 0, y and y + math.random(-200,200)*10 or 0,"dynamic")
	object.shape = love.physics.newCircleShape(15)
	object.fixture = love.physics.newFixture(object.body, object.shape)
	object.fixture:setUserData(self)
	object.body:setLinearDamping(4)
	object.body:setMass(100)
	self.object = object
	
	table.insert(game.enemies,self)
	self:setState(game.enemyStates.playing)
end


function Enemy:respawn()
	self.hp = self.hpMax
	self:setState(game.enemyStates.playing)
	self.deadAnimation = self.animation
	self.deadAnimation:gotoFrame(1)
	self.deadAnimation:resume(1)
	self.animation = self.liveAnimation
	self.liveAnimation = nil
	self.image = nil
	self.object.fixture:setFilterData(1, 65535, 0)--reset filter
	self.object.body:setPosition(self.object.body:getX() + math.random(-200,200)*10, self.object.body:getY() + math.random(-200,200)*10)
end

function Enemy:dead()
	if not self:isDead() then
		--level up every death
		self.speed = self.speed + 10
		self.hpMax = self.hpMax + 5
		
		self.respawnTimer = 20
		self:setState(game.enemyStates.dead)
		self.liveAnimation = self.animation
		self.animation = self.deadAnimation or game.animations[3]:clone()
		self.image = game.images[3]
		self.object.fixture:setFilterData(1, 0, 0)--set filter so other objects dont get stuck on corpse
	end
end

function Enemy:takeDamge(amt,player)
	self.hp = self.hp - amt
	if self.hp <= 0 then
		self:dead()
		if player then
			player:gainScore()
		end
		game.newSpawn = game.newSpawn and game.newSpawn + 1 or 1
	end
	if player then self.target = player end
end


function Enemy:doDamge(target,amt)
end

function Enemy:mobAttack(target)
	if not self.rateOfFire and not self.reloading then
		target:takeDamge(self.dmg)
		self.target = target
		self:ROF()
	end
end


function Enemy:getLeftAxis()
	return  self.lastLeftX,self.lastLeftY
end

function Enemy:getRightAxis()
	return  self.lastRightX,self.lastRightY
end

function Enemy:updateRightAxis()
	local x = self.lastRightX or 0
        local y = self.lastRightY or 0
	if x == 0 then x = self.lastRightX else self.lastRightX = x end
	if y == 0 then y = self.lastRightY else self.lastRightY = y end
	--self.angle = math.atan2(self.lastRightY,self.lastRightX)
end

function Enemy:update(dt)
	game.enemyStates.update[self.state](self,dt)
end

function Enemy:move()
	if not self.target or self.target:isDead() then
		self:findTarget()
	end
	if not self.target then return end
	local mx,my,tx,ty = self.object.body:getX(),self.object.body:getY(), self.target.object.body:getX() ,self.target.object.body:getY()
	
	--set speed based off tile
	local tileSpeed = game.map:getTile(mx,my):getSpeed()
	local speed= self.speed * tileSpeed
		
	self.angle = math.getAngle(mx,my,tx,ty)
	local dx = tx - mx
	local dy = ty - my
	local distance = math.sqrt(dx*dx+dy*dy)
	local x = dx / distance
	local y = dy / distance
	if distance < 5 then
		if not self.paused then
			self:setMoveState(game.mobileStates.standing)
			self.animation:pauseAtStart()
			self.paused = true
		end
		x,y = 0,0
	else
		if self.animation and self.paused then
			self:setMoveState(game.mobileStates.running)
			self.animation:resume()
			self.paused = nil
		end
	end
	self.object.body:setLinearVelocity(x*speed,y*speed)
end

function Enemy:isDead()
	return self.state == game.enemyStates.dead
end

function Enemy:ROF()
	if not self.rateOfFire then
		local delay = self.rateOfAttack
		self.rateOfFire = delay
	end
end

function Enemy:findTarget()
	local endGame = true
	for i,v in ipairs(game.players) do 
		if not v:isDead() then
			endGame = false
		end
	end
	if endGame then 
		game:setState(game.gameStates.endGame)
	else
		self.target = game.players[love.math.random(1,#game.players)]
	end
end

function Enemy:reload(delay)
	if not self.reloading then
		self.reloading = delay
	end
end

--- Set ID.
-- id = The ID to set.
function Enemy:setID(id)
	self.id = id
end

--- Gets current ID.
function Enemy:getID()
	return self.id
end

--- Set movement state.
-- state = The state to set, should be part of mobileState table.
function Enemy:setMoveState(state)
	if not game.mobileStates[state] or self.moveState == state then return end
	self.moveState = state
end

--- Gets current movement state.
function Enemy:getMoveState()
	return self.moveState
end

--- Set play state.
-- state = The state to set.
function Enemy:setState(state)
	if not game.enemyStates[state] or self.state == state then return end
	self.state = state
end

--- Gets current state.
function Enemy:getState()
	return self.state
end

--- Returns the string-value of the Enemy.
function Enemy:toString()
	return self.id
end

function Enemy:getStatus()
	return game.enemyStates[self:getState()].. ' ' .. game.mobileStates[self:getMoveState()].. ' ' .. self.hp
end

function Enemy:destroy()
	table.removeValue(game.enemies,self)
	game.destoryQueue[self.object.fixture] = self.object.fixture 
	--game.destoryQueue[self.object.body] = self.body
	--game.destoryQueue[self.object.shape] = self.shape
	self = nil
end

return Enemy
