require 'love.timer'
require 'love.math'
require 'love.image'
require 'ext.table'
require 'ext.math'
local seed,tiles,mapObjects = ...
_G.tiles = tiles
_G.mapObjects = mapObjects
_G.config = require("config")
local Chunk      		= require("objects.Chunk")
local loading = true
local cx,cy,chunkTable,loadedChunks,chunks = 0,0,{},{},{}
local xChanPop,yChanPop = love.thread.getChannel( 'loadX' ),love.thread.getChannel( 'loadY' )
local updateChanPush,unloadChanPush,loadChanPush = love.thread.getChannel( 'updateChunk' ),love.thread.getChannel( 'unloadChunk' ),love.thread.getChannel( 'mapGen' )
local startup = true
local function getDistance(x1,y1,x2,y2) return math.floor(math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)) end

function _G.getChunk(x,y)
	local w = config.chunkWidth
	x,y = math.floor(x / w), math.floor(y / w)
	local xy = x..','..y
	return chunkTable[xy]
end

function _G.getTile(x,y,workingChunk)
	local size = config.tileSize
	local chunk = getChunk(x,y)
	local tilex,tiley = math.floor((x - chunk.xMin) / size),math.floor((y - chunk.yMin) / size)
	local tile = chunk:getTile(tilex,tiley)
	return tile,chunk
end


while loading do
	--push any updates
	for i,v in pairs(chunkTable) do
		if v.needsUpdate and loadedChunks[i] then
			v:genTiles()
			v:updateTiles()
			for i,tile in pairs(v.tiles) do
				tile.chunk = nil
			end
			v.imgData = v.imgData:clone()
			updateChanPush:push(v)
			love.timer.sleep(0.1)
			for i,tile in pairs(v.tiles) do
				tile.chunk = v
			end
			v.needsUpdate = nil
		end
	end
	chunks = {}
	local x,y = xChanPop:pop(), yChanPop:pop()
	if x and x ~= cx or y and y ~= cy or startup then
		local ccx,ccy = x or cx,y or cy
		if getDistance(ccx,ccy,cx,cy) >= 2 or startup then
			startup = nil
			cx,cy = ccx,ccy
			local xy = cx..','..cy
			--find near by chunks
			if not chunkTable[xy] then
				local chunk = Chunk:new(cx,cy,seed)
				chunks[xy] = chunk
			else
				chunks[xy] = chunkTable[xy]
			end
			for i,v in pairs(config.neighborDirs) do
				local x,y = cx+v[1],cy+v[2]
				local xy = x..','..y
				if not chunkTable[xy] then
					local chunk = Chunk:new(x,y,seed)
					chunks[xy] = chunk
				else
					chunks[xy] = chunkTable[xy]
				end
			end
			--unload old chunks
			for i,v in pairs(chunkTable) do
				local xy = i
				if not chunks[xy] then
					if getDistance(v.mapX,v.mapY,cx,cy) >= config.unloadChunkDis then 					
						if loadedChunks[xy] then
							setmetatable(v, {__index = Chunk})
							v:unload()
							unloadChanPush:push(xy)
							loadedChunks[xy] = nil
							chunkTable[xy] = nil
						else
							v:destroy()
							chunkTable[xy] = nil
						end
					end
				end
			end
			--add new chunks to chunkTable
			local count1 = 0
			local count2 = 0
			for i,v in pairs(chunks) do
				local xy = i
				if not chunkTable[xy] then count1 = count1 + 1 chunkTable[xy] = v end
			end
			--load new chunks
			for i,v in pairs(chunks) do
				local xy = i
				if not loadedChunks[xy] and getDistance(v.mapX,v.mapY,cx,cy) <= config.loadChunkDis then
					v:load()
					--local chunkTiles = v.tiles
					--v.tiles = nil
					for i,tile in pairs(v.tiles) do
						tile.chunk = nil
					end
					loadChanPush:push(v)
					for i,tile in pairs(v.tiles) do
						tile.chunk = v
					end
					--v.tiles = chunkTiles
					love.timer.sleep(0.1)
					loadedChunks[xy] = v
					count2 = count2 + 1
				end
			end
print(count1,count2)
		end
	end
	love.timer.sleep(2)
end