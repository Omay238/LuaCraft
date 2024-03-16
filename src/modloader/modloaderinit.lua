--TODO : FIX CRASH WHILE PROFILING
function addFunctionToTag(tag, func)
	--_JPROFILER.push("addFunctionToTag")
	if not ModLoaderTable[tag] then
		ModLoaderTable[tag] = {}
	end
	table.insert(ModLoaderTable[tag], func)
	--_JPROFILER.pop("addFunctionToTag")
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
	--_JPROFILER.push("addBlock")
	if Tiles[blockstringname] then
		LuaCraftErrorLogging("Error: Duplicate blockstringname detected: " .. tostring(blockstringname))
		return
	end

	local properties =
		{ "transparency", "LightSources", "Cancollide", "BlockOrLiquidOrTile", "blockBottomMasterTexture" }
	local block = {
		BlockOrLiquidOrTile = BlockOrLiquidOrTile,
		Cancollide = Cancollide,
		transparency = transparency,
		LightSources = LightSources,
		blockBottomMasterTexture = blockBottomMasterTexture,
	}

	if blockSideTexture ~= nil then
		block.blockSideTexture = blockSideTexture
	end

	if blockTopTexture ~= nil then
		block.blockTopTexture = blockTopTexture
	end

	local seen = {}

	for _, prop in ipairs(properties) do
		if block[prop] ~= nil then
			if seen[prop] then
				LuaCraftErrorLogging(
					"Error: Property " .. prop .. " is defined more than once in block " .. tostring(blockstringname)
				)
			else
				seen[prop] = true
			end
		else
			if prop == "LightSources" then
				LuaCraftErrorLogging(
					"Error: Missing property or not in range property for "
						.. prop
						.. " in block "
						.. tostring(blockstringname)
						.. ". please ensure that 'LightSources' is within the range of 0 to 15"
				)
			else
				LuaCraftErrorLogging("Error: Missing property " .. prop .. " in block " .. tostring(blockstringname))
			end
		end
	end
	seen = {}
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
			blockTopTexture = Lovegraphics.newImage(blockTopTexture)
		end
		if type(blockSideTexture) == "string" then
			blockSideTexture = Lovegraphics.newImage(blockSideTexture)
		end

		if BlockThatUseCustomTexturesForTopandSide[id] then
			LuaCraftErrorLogging(
				"Key already exists in BlockThatUseCustomTexturesForTopandSide: " .. block.blockstringname
			)
			return
		end

		BlockThatUseCustomTexturesForTopandSide[id] = { top = blockTopTexture, side = blockSideTexture }
	end
	nextId = nextId + 1
	--_JPROFILER.pop("addBlock")

	return id
end

function LoadMods()
	--_JPROFILER.push("LoadMods")
	local fullPath
	local modsDirectory = "mods/"
	local items = Lovefilesystem.getDirectoryItems(modsDirectory)
	for _, item in ipairs(items) do
		fullPath = modsDirectory .. item
		if Lovefilesystem.getInfo(fullPath, "directory") then
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
	fullPath = nil
	--_JPROFILER.pop("LoadMods")
end

function LoadBlocksAndTiles(directory)
	--_JPROFILER.push("LoadBlocksAndTiles")
	local fullPath
	local items = love.filesystem.getDirectoryItems(directory)
	for _, item in ipairs(items) do
		fullPath = directory .. "/" .. item
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
	fullPath = nil
	--_JPROFILER.pop("LoadBlocksAndTiles")
end
