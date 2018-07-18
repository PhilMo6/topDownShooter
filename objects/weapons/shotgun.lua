
local Bullet		= require("objects.Bullet")
local Cloneable		= require("objects.Cloneable")
local Weapon		= Cloneable.clone()
Weapon.id =2
Weapon.type = 'Shotgun'
Weapon.range = 50
Weapon.speed = 15
Weapon.accuracy = 40--cone of fire
Weapon.bulletCount = 9--how many bullets to generate per shot
Weapon.bulletSize = 3
Weapon.rateOfFire = 1
Weapon.dmg = 25
Weapon.ammo = 10
Weapon.reload = 5
Weapon.offset = 24
Weapon.sound = 'ShotgunPump'

Weapon.image = love.graphics.newImage("sprites/human_male/shotgun_grip.png")
Weapon.animation = 0
Weapon.offsetx = 0
Weapon.offsety = 0

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
	local hit,hitx,hity
	--if bullet strikes any targets set max timeout to match target distance
	for i,v in pairs(rayCast) do
		local userData = v[1]:getUserData()
		local newDis = math.getDistance(startX,startY,v[2],v[3])
		local isDead = userData.isDead and userData:isDead() or false
		if userData.id ~= 2 and newDis < dis and not isDead then
			hitx,hity=v[2],v[3]
			hit = v[1]
			dis = newDis
		end
	end
	local offset = 0.6
	local bullet = Bullet:new(player)
	if hit then 
		local target = hit:getUserData()
		bullet.hitImage = self.hitImage or target.hitImage
		offset = self.hitOffset or target.hitOffset or offset
		bullet.target = target
		if target and target.takeDamge then bullet.dmg = self.dmg bullet.hit = self.hit  end
	end
	bullet.size = self.bulletSize
	bullet.maxTimeout = (dis / self.speed)-offset
	bullet.x,bullet.y, bullet.dx,bullet.dy = player.firex,player.firey,bulletDx,bulletDy
	bullet.speed = self.speed
	bullet.angle = angle
end

function Weapon:hit(target,player,dmg)
	target:takeDamge(dmg,player)
end

return Weapon
