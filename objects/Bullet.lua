
local Cloneable		= require("objects.Cloneable")
local Bullet		= Cloneable.clone()
Bullet.id =1
Bullet.type = 'bullet'
Bullet.size = 2

--- Initialize the bullet
-- player = player that fired bullet
function Bullet:initialize(player)
	--runtime data
	self.player = player
	self.timeout = 0 --animation timeout
	
	--[[if weapon.phy then
		self.body = love.physics.newBody(game.world, player.firex, player.firey,"dynamic")
		self.shape = love.physics.newCircleShape(2)
		self.fixture = love.physics.newFixture(self.body, self.shape)
		self.fixture:setFriction(0.9)
		self.fixture:setRestitution(0.05)
		self.fixture:setGroupIndex(-1)
		self.fixture:setUserData(self)
		self.body:setBullet(true)
		self.body:applyForce(bulletDx * weapon.phy.force,bulletDy * weapon.phy.force)
		self.maxTimeout = weapon.speed * weapon.range
	else	
		local dis = weapon.speed * weapon.range
		local endX = startX+bulletDx * dis
		local endY = startY+bulletDy * dis
		--do raycast to find hit
		local rayCast = {}
		--bullets hit function
		local function callback(fixture, x, y, xn, yn, fraction)
			table.insert(rayCast,{fixture,x,y})
			return 1
		end
		game.world:rayCast(startX,startY,endX,endY,callback)
		local hit,hitx,hity
		--if bullet strikes any targets set max timeout to match target distance
		for i,v in pairs(rayCast) do
			local userData = v[1]:getUserData()
			local newDis = math.getDistance(startX,startY,v[2],v[3])
			local isDead = userData.playState or game.playStates.playing--make sure target is alive
			if userData.id ~= 2 and newDis < dis and isDead ~= game.playStates.dead then
				hitx,hity=v[2],v[3]
				hit = v[1]
				dis = newDis
			end
		end
		local offset = 0.6
		if hit then 
			local target = hit:getUserData()
			self.hitImage = weapon.hitImage or target.hitImage
			offset = weapon.hitOffset or target.hitOffset or offset
			if target and target.takeDamge then target:takeDamge(weapon.dmg,player) end
		end
		self.maxTimeout = (dis / weapon.speed)-offset
		self.x,self.y, self.dx,self.dy = player.firex,player.firey,bulletDx,bulletDy
		self.speed = weapon.speed
		self.angle = angle
	end]]
	table.insert(game.bullets, self)	
end

function Bullet:update(dt)
	self.timeout = self.timeout+1+dt
	if self.timeout > self.maxTimeout then 
		return self:destroy()
	end
	if not self.body then 
		self.x = self.x + self.dx * (self.speed + dt)
		self.y = self.y + self.dy * (self.speed + dt)
	end
end

function Bullet:destroy()
	if self.hitImage then table.insert(game.damage,{self.hitImage,self.x,self.y,self.angle,0.5}) end
	if self.hit and not self.target:isDead() then self:hit(self.target,self.player,self.dmg) end
	table.removeValue(game.bullets,self)
	if self.fixture then game.destoryQueue[self.fixture] = self.fixture end
	--if self.body then game.destoryQueue[self.body] = self.body end
	--if self.shape then game.destoryQueue[self.shape] = self.shape end
	self = nil
end

function Bullet:move()
	
end

return Bullet
