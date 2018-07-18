
local Bullet		= require("objects.Bullet")
local Cloneable		= require("objects.Cloneable")
local Weapon		= Cloneable.clone()
Weapon.id =1
Weapon.type = 'Rifle'
Weapon.range = 1000
Weapon.speed = 20
Weapon.accuracy = 1--cone of fire
Weapon.bulletCount = 1--how many bullets to generate per shot
Weapon.bulletSize = 3
Weapon.rateOfFire = 0.6
Weapon.dmg = 75
Weapon.hitCount = 4
Weapon.ammo = 15
Weapon.reload = 2
Weapon.offset = 22
Weapon.sound = 'shot'

Weapon.image = love.graphics.newImage("sprites/human_male/rifle_grip.png")
Weapon.animation = 0
Weapon.offsetx = 2
Weapon.offsety = -1

--- Initialize the weapon
function Weapon:initialize()
	game.weapons[self.id] = self
	game.weapons[self.type] = self
end

function Weapon:fire(player)
	for i=1,self.bulletCount do
		self:getHit(player)
	end
end

function Weapon:getHit(player)
	--find starting location from player
	local x,y = player:getRightAxis()
	local startX,startY = player.object.body:getX(),player.object.body:getY()
	-- the "base" angle for a shot
	local angle = player.angle
	-- modify the angle
  	if self.accuracy ~= 0 then angle = angle + love.math.random(-self.accuracy, self.accuracy) / 100 end
	local bulletDx = math.cos(angle)
	local bulletDy = math.sin(angle)
	local dis = self.speed * self.range
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
	local hit = {}
	--if bullet strikes any targets set max timeout to match target distance
	for i,v in pairs(rayCast) do
		local userData = v[1]:getUserData()
		local newDis = math.getDistance(startX,startY,v[2],v[3])
		local id = userData.randomID or love.math.random(-10,-100000)
		local isDead = userData.isDead and userData:isDead() or false
		if not hit[id] and userData.id ~= 2 and not isDead then
			if hit[1] then
				for i,v in ipairs(table.copy(hit)) do
					if v[4] > newDis then
						table.insert(hit,i,{userData,v[2],v[3],newDis})
						break
					end
				end
			else
				table.insert(hit,{userData,v[2],v[3],newDis})
			end
			hit[id] = true
		end
	end
	local offset = 0.6
	local count = 0
	for i,v in ipairs(hit) do
		local bullet = Bullet:new(player)
		bullet.size = self.bulletSize
		local target = v[1]
		bullet.hitImage = self.hitImage or target.hitImage
		offset = self.hitOffset or target.hitOffset or offset
		bullet.target = target
		if target.takeDamge then bullet.dmg = self.dmg bullet.hit = self.hit  end
		bullet.maxTimeout = (v[4] / self.speed)-offset
		bullet.x,bullet.y, bullet.dx,bullet.dy = player.firex,player.firey,bulletDx,bulletDy
		bullet.speed = self.speed
		bullet.angle = angle
		count = count + 1
		if count > self.hitCount or target.id == 0 then return end
	end
	if not hit[1] then 
		local bullet = Bullet:new(player)
		bullet.size = self.bulletSize
		bullet.maxTimeout = dis
		bullet.x,bullet.y, bullet.dx,bullet.dy = player.firex,player.firey,bulletDx,bulletDy
		bullet.speed = self.speed
		bullet.angle = angle
	end
end

function Weapon:hit(target,player,dmg)
	target:takeDamge(dmg,player)
end

return Weapon
