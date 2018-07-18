
local Cloneable		= require("objects.Cloneable")
local Object		= Cloneable.clone()

local offset = 60
local MapObjects = mapObjects or game.mapObjects

Object.id=0

-- Initialize the Object
function Object:initialize(objType,x,y,dx,dy,angle,id)
	self.x, self.y, self.dx, self.dy = x,y,dx,dy
	self.type = objType
	self.angle = angle or math.rad(love.math.random(1,360))
	self.objId = id or love.math.random(1,#MapObjects[objType])
	self.hitImage = MapObjects[objType].hitImage
	self.hitOffset = MapObjects[objType].hitOffset
end

function Object:draw()
	local index = MapObjects[self.type]
	love.graphics.draw(index.image,index[self.objId].quad,self.dx,self.dy,self.angle,1,1,offset,offset)
end

function Object:destroy()
	--[[if self.fixture then
		self.fixture:destroy()
	end]]
	self = nil
end

--[[
function Object:takeDamge(amt,player)
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
]]

return Object
