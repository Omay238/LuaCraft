ModLoaderTable = {}
function addFunctionToTag(tag, func)
	if not ModLoaderTable[tag] then
		ModLoaderTable[tag] = {}
	end
	table.insert(ModLoaderTable[tag], func)
end
local nextId = 1
TilesById = { [0] = {
	blockstringname = "AIR_Block",
} }
BlockThatUseCustomTexturesForTopandSide = {}
function addBlock(
	blockstringname,
	BlockOrLiquidOrTile,
	Cancollide,
	transparency,
	LightSources,
	blockBottomMasterTexture,
	blockSideTexture,
	blockTopTexture
)
	local id = nextId
	Tiles[blockstringname] = {
		id = id,
		blockstringname = blockstringname,
		transparency = transparency,
		LightSources = LightSources,
		Cancollide = Cancollide,
		BlockOrLiquidOrTile = BlockOrLiquidOrTile,
		blockBottomMasterTexture = blockBottomMasterTexture,
		blockSideTexture = blockSideTexture,
		blockTopTexture = blockTopTexture,
	}

	TilesById[id] = Tiles[blockstringname]
	if blockTopTexture ~= nil or blockSideTexture ~= nil then
		if type(blockTopTexture) == "string" then
			blockTopTexture = lovegraphics.newImage(blockTopTexture)
		end
		if type(blockSideTexture) == "string" then
			blockSideTexture = lovegraphics.newImage(blockSideTexture)
		end

		BlockThatUseCustomTexturesForTopandSide[id] = { top = blockTopTexture, side = blockSideTexture }
	end
	nextId = nextId + 1

	return id
end

function LoadMods()
	local modsDirectory = "mods/"
	local items = lovefilesystem.getDirectoryItems(modsDirectory)
	for _, item in ipairs(items) do
		local fullPath = modsDirectory .. item
		if lovefilesystem.getInfo(fullPath, "directory") then
			local modName = item
			local startTime = os.clock()
			local success, mod = pcall(require, "mods." .. modName .. "." .. modName)
			if success then
				if mod.initialize then
					mod.initialize()
				end
				local endTime = os.clock()
				local loadTime = endTime - startTime
				LuaCraftPrintLoggingNormal("Load time for", modName, ":", loadTime, "seconds")
			else
				LuaCraftErrorLogging("Failed to load mod:", modName)
			end
		end
	end
end

function LoadBlocksAndTiles(directory)
	local items = love.filesystem.getDirectoryItems(directory)
	for _, item in ipairs(items) do
		local fullPath = directory .. "/" .. item
		if love.filesystem.getInfo(fullPath).type == "directory" then
			LoadBlocksAndTiles(fullPath)
		elseif item:match("%.lua$") and item ~= "tiledata.lua" then
			local blockName = item:sub(1, -5)
			local success, block = pcall(require, directory:gsub("/", ".") .. "." .. blockName)
			if success then
				if block and type(block) == "table" and block.initialize then
					block.initialize()
				end
			else
				LuaCraftErrorLogging("Failed to load block:", blockName)
			end
		end
	end
end
