
local Cloneable		= require("objects.Cloneable")
local Tile		= Cloneable.clone()

Tile.speed = 1

-- Initialize the Tile
function Tile:initialize(chunk,cx,cy)
	self.cx, self.cy = cx,cy
	--self.elevation = 0
	self.chunk = chunk
	self.overLay = {}
end

function Tile:getSpeed()
	return self.speed
end

function Tile:setSpeed(speed)
	if not speed then self.speed = Tile.speed return end
	self.speed = self.speed * speed
end

function Tile:setElevation(elevation)
	if elevation then
		self.elevation = elevation
	elseif not self.elevation then
		self.elevation = love.math.random(1,500)
		self.elevation = self.elevation > 2 and 2 or self.elevation
	end
	self:addGen()
end

function Tile:draw()
	local tileSize = config and config.tileSize or game.config.tileSize
	if self.imgData then
		self.chunk.imgData:paste(self.imgData,self.cx*tileSize, self.cy*tileSize, 0, 0, tileSize, tileSize)
		--self.imgData = nil
	end
	--if self.overLay then self:paste(self.overLay) end
	for i,v in pairs(self.overLay) do
		self:paste(v)
	end
end

function Tile:paste(imgData)
	if self.cx ==30 or self.cy == 30 then
		self.imgData = imgData
		self:draw()
	else
		local tileSize = config.tileSize
		local chunkSize = config.chunkSize
		local chunkWidth = config.chunkWidth
		local tx,ty = self.cx*tileSize, self.cy*tileSize
		local function pixelFunction(x, y, r, g, b, a)
			local cx,cy = x-tx, y-ty
			local ir, ig, ib, ia = imgData:getPixel(cx,cy)
			if ia == 1 then
				r,g,b = ir, ig, ib
			end
			return r,g,b,a
		end
		--print(self.cx*tileSize, self.cy*tileSize)
		self.chunk.imgData:mapPixel(pixelFunction,self.cx*tileSize, self.cy*tileSize, tileSize, tileSize)
	end
end

function Tile:generate()
	if self.elevation == 1 then
		self.imgData = self:getImgData('water')
		local neighbors = self:findNeighbors(math.random(1,4))
		for x,v in pairs(neighbors) do
			for y,tile in pairs(v) do
				if not tile.elevation or tile.elevation > 1 then
					tile:removeGen()
					tile.elevation = self.elevation
					tile.imgData = self:getImgData('water')
					if tile.chunk ~= self.chunk then tile.chunk.needsUpdate = true end
				end
			end
		end
		for x,v in pairs(neighbors) do
			for y,tile in pairs(v) do
				local beachNeighbors = tile:findNeighbors()
				for x,v in pairs(beachNeighbors) do
					for y,tile in pairs(v) do
						if not tile.elevation or tile.elevation > 1 then
							tile:removeGen()
							tile.elevation = 3
							tile:addGen()
							if tile.chunk ~= self.chunk then tile.chunk.needsUpdate = true end
						end
					end
				end
			end
		end
	elseif self.elevation == 2 then
		self.imgData = self:getImgData('grass')
	elseif self.elevation == 3 then
		self.imgData = self:getImgData('dirt')
		local neighbors = self:findNeighbors(math.random(1,3))
		for x,v in pairs(neighbors) do
			for y,tile in pairs(v) do
				if tile.elevation == 3 then
					--tile:removeGen()
					--tile.imgData = self:getImgData('dirt')
					--if tile.chunk ~= self.chunk then tile.chunk.needsUpdate = true end
				elseif not tile.elevation or tile.elevation == 2 then
					tile:removeGen()
					tile.elevation = 3
					tile.imgData = self:getImgData('dirt')
					if tile.chunk ~= self.chunk then tile.chunk.needsUpdate = true end
				end
			end
		end
	end
	self:removeGen()
end

local tileFilter={}
tileFilter[1] = {false,false,true}--water looks for dirt
tileFilter[1].paste = 'dirt'
tileFilter[2] = {false,false,false}--grass looks for nothing
--tileFilter[2].paste = 'dirt'
tileFilter[3] = {false,true,false}--dirt looks for grass
tileFilter[3].paste = 'grass'
function Tile:findWeight()

	if tileFilter[self.elevation].paste then
		self.overLay = {}
		local trueDir,cornerDir = {},{}
		local edgeNeighbors = self:findTrueNeighbors(tileFilter[self.elevation])
		for x,v in pairs(edgeNeighbors) do
			for y,tile in pairs(v) do
				if tile.elevation ~= self.elevation then
					table.insert(trueDir,{x,y,tile})
				end
			end
		end
		local cornerNeighbors = self:findCornerNeighbors(tileFilter[self.elevation])
		for x,v in pairs(cornerNeighbors) do
			for y,tile in pairs(v) do
				if tile.elevation ~= self.elevation then
					table.insert(cornerDir,{x,y,tile})
				end
			end
		end
		local trueAngle,trueX,trueY
		if trueDir[1] then
			local x,y
			for i,v in ipairs(trueDir) do
				x = x and x + v[1] or v[1]
				y = y and y + v[2] or v[2]
			end
			trueX,trueY = x,y
			trueAngle = math.deg(math.getAngle(0,0,x,y))
			--print('true',x,y,trueAngle)
		end
		local cornerAngle,cornerX,cornerY
		if cornerDir[1] then
			local x,y
			for i,v in ipairs(cornerDir) do
				x = x and x + v[1] or v[1]
				y = y and y + v[2] or v[2]
			end
			cornerX,cornerY = x,y
			cornerAngle = math.deg(math.getAngle(0,0,x,y))
			--print('corner',x,y,cornerAngle)
		end

		
		--!!look for compleatly surrounded first??
		
		if not trueDir[1] and cornerDir[1] then
		self.TESTDATA = 'not trueDir[1]'
		self.TESTDATA = self.TESTDATA .. ' '..#trueDir.. ' '..#cornerDir.. ' '..(trueAngle or 'nil').. ' '..(cornerAngle or 'nil')
		
			if #cornerDir == 1 then
				local imgData = self:getImgData(tileFilter[self.elevation].paste..'OutCorner',cornerAngle)
				self.overLay[cornerAngle] = imgData
			else
				for i,v in ipairs(cornerDir) do
					local x,y,tile = v[1],v[2],v[3]
					local angle = math.deg(math.getAngle(0,0,x,y))
					local imgData = self:getImgData(tileFilter[self.elevation].paste..'OutCorner',angle)
					self.overLay[angle] = imgData
				end
			end
		elseif #trueDir == 2 then
		self.TESTDATA = '#trueDir == 2'
		self.TESTDATA = self.TESTDATA .. ' '..#trueDir.. ' '..#cornerDir.. ' '..(trueAngle or 'nil').. ' '..(cornerAngle or 'nil')
		
			local imgData = self:getImgData(tileFilter[self.elevation].paste..'InCorner',trueAngle)
			self.overLay[trueAngle] = imgData
		elseif #cornerDir >= 2 then
		self.TESTDATA = '#cornerDir >= 2'
		self.TESTDATA = self.TESTDATA .. ' '..#trueDir.. ' '..#cornerDir.. ' '..(trueAngle or 'nil').. ' '..(cornerAngle or 'nil')
		
			if trueAngle == cornerAngle then
				local imgData = self:getImgData(tileFilter[self.elevation].paste..'Edge',trueAngle)
				self.overLay[trueAngle] = imgData
			else
				for i,v in ipairs(trueDir) do
					local x,y,tile = v[1],v[2],v[3]
					local angle = math.deg(math.getAngle(0,0,x,y))
					local imgData = self:getImgData(tileFilter[self.elevation].paste..'Edge',angle)
					self.overLay[angle] = imgData
				end
			end
			
			if #trueDir == 3 then

			print('TEST2',trueAngle,cornerAngle)
			
				for i,v in ipairs(cornerDir) do
					local x,y,tile = v[1],v[2],v[3]
					local angle = math.deg(math.getAngle(0,0,x,y))
					local imgData = self:getImgData(tileFilter[self.elevation].paste..'InCorner',angle)
					self.overLay[angle] = imgData
				end
			end			
		elseif trueDir[1] then

		self.TESTDATA = 'trueDir[1]'
		self.TESTDATA = self.TESTDATA .. ' '..#trueDir.. ' '..#cornerDir.. ' '..(trueAngle or 'nil').. ' '..(cornerAngle or 'nil')
		
			if trueAngle then
				local imgData = self:getImgData(tileFilter[self.elevation].paste..'Edge',trueAngle)
				self.overLay[trueAngle] = imgData
			else
				for i,v in ipairs(trueDir) do
					local x,y,tile = v[1],v[2],v[3]
					local angle = math.deg(math.getAngle(0,0,x,y))
					local imgData = self:getImgData(tileFilter[self.elevation].paste..'Edge',angle)
					self.overLay[angle] = imgData
				end
			end
		end
			--[[local imgData,angle
			if cornerAngle == trueAngle then--this is an edge tile
				local tileType = tileFilter[self.elevation].paste
				imgData = self:getImgData(tileType..'Edge',trueAngle)
				angle = trueAngle
			elseif cornerAngle then
				local tileType = tileFilter[self.elevation].paste
				imgData = self:getImgData(tileType..'OutCorner',cornerAngle)
				angle = cornerAngle
			--elseif trueAngle then
			--	local tileType = tileFilterTrue[self.elevation].paste
			--	imgData = self:getImgData(tileType..'Edge',trueAngle)
			end
			if imgData then self.overLay[angle] = imgData end]]
	end
end

function Tile:getImgData(tileType,angle)
	angle = angle or love.math.random(1,4)
	return tiles[tileType..love.math.random(0,3)][angle]
end

function Tile:addGen()
	self.chunk:addToGen(self)
end

function Tile:removeGen()
	if self.elevation then self.chunk:removeFromGen(self) end
end

function Tile:findTrueNeighbors(filter)
	local tileSize = config and config.tileSize or game.config.tileSize
	local neighbors = {}
	local cx,cy = math.floor(self.chunk.xMin + (tileSize * self.cx)), math.floor(self.chunk.yMin + (tileSize * self.cy))
	for i,v in ipairs(config.trueDirs) do
		local tx,ty = cx+(v[1]*tileSize),cy+(v[2]*tileSize)
		local tile = getTile(tx,ty)
		if tile and tile ~= self and (not filter or filter[tile.elevation or 0]) then
			if not neighbors[v[1]] then neighbors[v[1]] = {} end
			neighbors[v[1]][v[2]] = tile
		end		
	end
	return neighbors
end

function Tile:findCornerNeighbors(filter)
	local tileSize = config and config.tileSize or game.config.tileSize
	local neighbors = {}
	local cx,cy = math.floor(self.chunk.xMin + (tileSize * self.cx)), math.floor(self.chunk.yMin + (tileSize * self.cy))
	for i,v in ipairs(config.cornerDirs) do
		local tx,ty = cx+(v[1]*tileSize),cy+(v[2]*tileSize)
		local tile = getTile(tx,ty)
		if tile and tile ~= self and (not filter or filter[tile.elevation or 0]) then
			if not neighbors[v[1]] then neighbors[v[1]] = {} end
			neighbors[v[1]][v[2]] = tile
		end		
	end
	return neighbors
end

function Tile:findNeighbors(count)
	local tileSize = config and config.tileSize or game.config.tileSize
	count = count or 1
	local neighbors = {}
	local cx,cy = math.floor(self.chunk.xMin + (tileSize * self.cx)), math.floor(self.chunk.yMin + (tileSize * self.cy))
	for x=-1*count,1*count do
		for y=-1*count,1*count do
			local tx,ty = cx+(x*tileSize),cy+(y*tileSize)
			local tile = getTile(tx,ty)
			if tile and tile ~= self then
				if not neighbors[x] then neighbors[x] = {} end
				neighbors[x][y] = tile
			end
		end
	end
	return neighbors
end

--[[
function Tile:setAsWall(quad)
	self.quad = game.walls[quad or 1]
	self.img = game.images['tileset2']
	local halfsize = self.config.tileSize / 2
	self.body = love.physics.newBody(game.world, self.xMin-halfsize, self.yMin-halfsize,"static")
	self.shape = love.physics.newRectangleShape(self.config.tileSize, self.config.tileSize) 
	self.fixture = love.physics.newFixture(self.body, self.shape)
	self.fixture:setUserData(game.wallUserData)
	--self.chunk:updateCanvas()
end
]]

function Tile:destroy()
	if self.fixture then
		self.fixture:destroy()
	end
	self.chunk = nil
	self = nil
end

function Tile:unload()
	
end

return Tile
