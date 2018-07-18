local Chunk      		= require("objects.Chunk")
local Cloneable		= require("objects.Cloneable")
local Map			= Cloneable.clone()
local MapObject      	= require("objects.MapObject")
local Tile		      	= require("objects.Tile")


--- Initialize the Map
function Map:initialize()
	--load and start MapLoading thread
	self.thread = love.thread.newThread( 'objects/MapLoading.lua' )
	self.seed = 7478383--love.math.random()
	self.thread:start(self.seed,game.tiles,game.mapObjects)
	
	--setup tables
	self.loadedChunks = {}
	self.canvasUpdates = {}
	self.objects = {}
	self.objectsHigh = {}
	self.objectsLow = {}
end
 
local updateChanPop,unloadChanPop,loadChanPop = love.thread.getChannel( 'updateChunk' ),love.thread.getChannel( 'unloadChunk' ),love.thread.getChannel( 'mapGen' )
function Map:update(dt,xy)
	--pop any data from MapLoading thread and proccess
	local doneChunk = loadChanPop:pop()
	local unloadChunk = unloadChanPop:pop()
	local updateChunk = updateChanPop:pop()
	if unloadChunk then
		self:unloadChunk(unloadChunk)
	end
	if doneChunk then
		self:loadChunk(doneChunk)
	end
	if updateChunk then
		self:updateChunk(updateChunk)
	end
	--look for a canvas update for the chunk the camera is centered on
	if self.canvasUpdates[xy] then
		local chunk = self.canvasUpdates[xy]
		--[[if chunk.needsUpdate then 
			self.loadedChunks[xy]:updateDraw(chunk.imgData)
			self.loadedChunks[xy].tiles = chunk.tiles
			self.canvasUpdates[xy] = nil
		else]] 
			chunk:update()
		--end
		if chunk.loaded then self.canvasUpdates[xy] = nil end
	end
	--update one other chunk from canvasUpdates at a time
	for i,v in pairs(self.canvasUpdates) do
		--[[if v.needsUpdate then 
			self.loadedChunks[i]:updateDraw(v.imgData)
			self.loadedChunks[i].tiles = v.tiles
			self.canvasUpdates[i] = nil
		else ]]
			v:update()
		--end
		if v.loaded then self.canvasUpdates[i] = nil end
		break
	end
end

function Map:removeObject(object)
--print(object.x,object.y,'removeobj',game.mapObjects[object.type][object.objId].depth)
	if object.fixture then game.destoryQueue[object.fixture] = object.fixture end
	if game.mapObjects[object.type][object.objId].depth == 1 then
		self.objectsHigh[object] = nil
	else
		self.objectsLow[object] = nil
	end
	self.objects[object.x..','..object.y] = nil
end

function Map:addObject(object)
--print(object.x,object.y,'addobj',game.mapObjects[object.type][object.objId].depth)
	local xy = object.x..','..object.y
	if not self.objects[xy] then
		self.objects[xy] = object
		local objectIndex = game.mapObjects[object.type][object.objId]
		if objectIndex.depth == 1 then
			self.objectsHigh[object] = object
		else
			self.objectsLow[object] = object
		end
		if objectIndex.radius then
			local body = love.physics.newBody(game.world, object.x, object.y,"static")
			body:setAngle(object.angle)
			local shape = love.physics.newCircleShape(objectIndex.radius)
			local fixture = love.physics.newFixture(body, shape)
			fixture:setUserData(object)
			object.fixture = fixture
		end
	end
end

function Map:loadChunk(chunk)
	local xy = chunk.mapX..','..chunk.mapY
--print('loadChunk',xy,chunk.objects)
	if not self.loadedChunks[xy] then
		setmetatable(chunk, {__index = Chunk})
		if not chunk.loaded then
			self.canvasUpdates[xy] = chunk
		end
		self.loadedChunks[xy] = chunk
		for i,v in pairs(chunk.objects) do
			setmetatable(v, {__index = MapObject})
			self:addObject(v)
		end
		for i,v in pairs(chunk.tiles) do 
			setmetatable(v, {__index = Tile})
		end
	end
end

function Map:unloadChunk(index)
		
	self.canvasUpdates[index] = nil

	for i,v in pairs(self.loadedChunks[index].objects) do
		self:removeObject(v)
	end
	self.loadedChunks[index]:destroy()
	self.loadedChunks[index] = nil
	self.canvasUpdates[index] = nil
end

function Map:updateChunk(chunk)
	--local imgData = chunk.imgData
	--self.loadedChunks[chunk.mapX..','..chunk.mapY]:updateDraw(imgData)
	local xy = chunk.mapX..','..chunk.mapY	
	
	if self.loadedChunks[xy] then
		self:unloadChunk(xy)
		self:loadChunk(chunk)
	else
		print('cannot update',xy)
	end
	--[[if not self.canvasUpdates[xy] and self.loadedChunks[xy] then
		self.canvasUpdates[xy] = chunk
	else
		print('cannot update',xy)
	end]]
end

function Map:getChunk(x,y)
	local xy = x..','..y
	return self.loadedChunks[xy]
end

function Map:getChunkWorld(x,y)
	local chunkWidth = game.config.chunkWidth
	x,y = math.floor(x / chunkWidth), math.floor(y / chunkWidth)
	local xy = x..','..y
	return self.loadedChunks[xy]
end

function Map:getTile(x,y)
	local size = game.config.tileSize
	local chunk = self:getChunkWorld(x,y)
	local tilex,tiley = math.floor((x - chunk.xMin) / size),math.floor((y - chunk.yMin) / size)
	local tile = chunk:getTile(tilex,tiley)
	return tile,chunk,tilex,tiley
end

function Map:getPixel(x,y)
	local r, g, b ,a
	local chunk = self:getChunkWorld(x,y)
	if chunk then
		local size = game.config.tileSize
		local pixelX,pixelY = math.floor((x - chunk.xMin) / size) * size,math.floor((y - chunk.yMin) / size) * size
		r, g, b ,a = chunk.imgData:getPixel(pixelX,pixelY)
	end
	return r,g,b,a
end

function Map:draw()
	love.graphics.setBlendMode("alpha", "premultiplied")
	for i,chunk in pairs(self.loadedChunks) do
		if chunk.drawable then 
			chunk:draw()
		else
			self.canvasUpdates[chunk.mapX..','..chunk.mapY] = chunk
		end
	end
	love.graphics.setBlendMode("alpha")
	self:DrawObjectLayerLow()
end

function Map:DrawObjectLayerLow()
	for i,v in pairs(self.objectsLow) do
		v:draw()
	end
end

function Map:DrawObjectLayerHigh()
	for i,v in pairs(self.objectsHigh) do
		v:draw()
	end
end

return Map
