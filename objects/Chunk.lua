
local Cloneable		= require("objects.Cloneable")
local Chunk		= Cloneable.clone()
local Tile      		= require("objects.Tile")
local MapObject      	= require("objects.MapObject")
local MapObjects	 = mapObjects or game.mapObjects

--- Initialize the Chunk
function Chunk:initialize(x,y,seed)
	local chunkWidth = config.chunkWidth
	local nextSeed = seed + x + y
	love.math.setRandomSeed(nextSeed)
	self.tiles={}
	self.objects = {}
	self.mapX,self.mapY = x,y
	self.xMin, self.yMin = x * chunkWidth, y * chunkWidth
	self.imgData = love.image.newImageData( chunkWidth, chunkWidth)
	self.gen={{},{},{},{},{}}
	
	--add any non exsistant tiles and set elevation
	for tx=0,config.chunkSize do
		for ty=0,config.chunkSize do
			self:addTile(tx,ty):setElevation()
		end
	end
end

function Chunk:addToGen(tile)
	if not self.gen then self.gen={{},{},{},{},{}} end
	self.gen[tile.elevation][tile] = tile
end

function Chunk:removeFromGen(tile)
	if self.gen then 
		self.gen[tile.elevation][tile] = nil
	end
end

function Chunk:addTile(x,y)
	local xy = x..','..y
	if not self.tiles[xy] then
		local tile = Tile:new(self,x,y)
		self.tiles[xy] = tile
	end
	return self.tiles[xy]
end

function Chunk:getTile(x,y)
	local xy = x..','..y
	if not self.tiles[xy] then self:addTile(x,y) end
	return self.tiles[xy]
end

function Chunk:genTiles()
	if self.gen then 
		for i,typ in ipairs(self.gen) do
			for i,v in pairs(typ) do
				v:generate()
			end
		end
	end
	self.gen = nil
end

function Chunk:addObject(object,tile)
	local xy = object.x..','..object.y
	if not self.objects[xy] then
		self.objects[xy] = object
		if MapObjects[object.type][object.objId].speed then
			local tile = tile or self:getTile(object.x,object.y)
			tile:setSpeed(MapObjects[object.type][object.objId].speed)
		end	
	end	
end

function Chunk:removeObject(object)
	local xy = object.x..','..object.y
	if self.objects[xy] then
		self.objects[xy] = nil
	end	
end

function Chunk:load()
	self:genTiles()
	local tileSize = config.tileSize
	for i,v in pairs(self.tiles) do
		v:findWeight()
		v:draw()
		if v.elevation == 2 and love.math.random(1,100) == 1 then
			
			local dx,dy =math.floor((self.xMin + (tileSize * v.cx))-(tileSize/2)), math.floor((self.yMin + (tileSize * v.cy))-(tileSize/2))
			local tree = MapObject:new('tree',v.cx,v.cy,dx,dy)
			self:addObject(tree,v)
			--self.objects[v.cx..','..v.cy] = MapObject:new('tree',v.cx,v.cy,dx,dy)
		elseif v.elevation == 1 then
			v:setSpeed(0.5)
		end	
	end
end

function Chunk:unload()

	self:destroy()
end

function Chunk:destroy()


	--print(self.mapX,self.mapY,self,'dest')

	if self.tiles then
		for i,v in pairs(self.tiles) do
			if v.destroy then v:destroy() end
			self.tiles[i] = nil
		end
	end
	if self.objects then
		for i,v in pairs(self.objects) do
			if game and v.fixture then
				game.destoryQueue[v.fixture] = v.fixture
			end
		end
	end
	self.tiles = nil
	self.objects = nil
	self.imgData:release()
	self.imgData = nil
	if self.drawable then self.drawable:release() end
	self.drawable = nil
	self = nil
end

function Chunk:update()
	if self.drawable then self.drawable:release() self.drawable = nil end
	self.drawable = love.graphics.newImage(self.imgData)
	self.loaded = true
end

function Chunk:updateDraw(imgData)
	if imgData then
		local chunkSize = config and config.chunkSize or game.config.chunkSize
		self.imgData:paste(imgData,0,0, 0, 0, chunkSize, chunkSize)
	end
	--self:updateTiles()
	self:update()
end

function Chunk:updateTiles()
	local tileSize = config and config.tileSize or game.config.tileSize
	for i,tile in pairs(self.tiles) do
		tile:findWeight()
		tile:draw()
		--if tile.destroy then tile:destroy() end
		--self.tiles[i] = nil
	end
end

function Chunk:draw()
	if self.drawable then love.graphics.draw(self.drawable, self.xMin, self.yMin) end
end


return Chunk
