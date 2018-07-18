local config= {}
config.defaultSpawn = 0
--config.saveDir = love.filesystem.getSaveDirectory()
--print(config.saveDir)
config.defaultWidth,config.defaultHeight = 800,600
config.alphaOffsetX,config.alphaOffsetY = 62,55
config.gui={{5,10},--topleft
	{config.defaultWidth-(config.alphaOffsetX*2),10,true},--top right
	{5,config.defaultHeight-(config.alphaOffsetY*2),false,true},--bottomleft
	{config.defaultWidth-(config.alphaOffsetX*2),config.defaultHeight-(config.alphaOffsetY*2),true,true},--bottomright
	{},
	{},
	{},
	{}
	}

config.camMaxDis = 200
config.camMinDis = 180
config.maxScale = 1
config.minScale = 0.5
config.tileSize = 32--pixels per tile
config.chunkSize = 30 --tiles per chunk
config.chunkWidth = config.tileSize * config.chunkSize--total pixel width of chunk
config.chunkCount = 7--number of chunks to load from center
config.unloadChunkDis = config.chunkCount +2
config.loadChunkDis = config.chunkCount - 1

config.neighborDirs = {}
for x=-1*config.chunkCount,1*config.chunkCount do
	for y=-1*config.chunkCount,1*config.chunkCount do
		local dx,dy = x,y
		config.neighborDirs[dx..','..dy] = {dx,dy}
	end
end

config.trueDirs = {{-1,0},{0,-1},{1,0},{0,1}}
config.cornerDirs = {{-1,-1},{1,-1},{1,1},{-1,1}}
local angles = {}
for i,v in ipairs(config.trueDirs) do
	local angle = math.getAngle(v[1],v[2],0,0)
	angles[i] = math.deg(angle)
	print(math.deg(angle))
end
config.angles = angles
local cornerAngles = {}
for i,v in ipairs(config.cornerDirs) do
	local angle = math.getAngle(v[1],v[2],0,0)
	cornerAngles[i] = math.deg(angle)
	print(math.deg(angle))
end
config.cornerAngles = cornerAngles

config.playerColors = {
{0,1,0},
{1,0,0},
{0,0,1},
{1,1,0},
{0,1,1},
{1,0,1},
{0,0,0},
{1,1,1}
}


return config