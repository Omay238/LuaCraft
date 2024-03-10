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

function addBlock(blockstringname, BlockOrLiquidOrTile, Cancollide, transparency, LightSources)
	if Tiles[blockstringname] then
		LuaCraftErrorLogging("Error: Duplicate blockstringname detected: " .. tostring(blockstringname))
		return
	end

	local properties = { "transparency", "LightSources", "Cancollide", "BlockOrLiquidOrTile" }
	local block = {
		BlockOrLiquidOrTile = BlockOrLiquidOrTile,
		Cancollide = Cancollide,
		transparency = transparency,
		LightSources = LightSources,
	}

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

	local id = nextId
	Tiles[blockstringname] = {
		id = id,
		blockstringname = blockstringname,
		transparency = transparency,
		LightSources = LightSources,
		Cancollide = Cancollide,
		BlockOrLiquidOrTile = BlockOrLiquidOrTile,
	}

	TilesById[id] = Tiles[blockstringname]

	nextId = nextId + 1

	return id
end
--TODO MADE THIS MORE EFFICIANT
function useCustomTextureFORHUDTile(block, textureTOP, textureSIDE)
	if HUDTilesTextureListPersonalizedLookup[block] ~= nil then
		LuaCraftErrorLogging("Key already exists in HUDTilesTextureListPersonalizedLookup: " .. getTileName(block))
	end
	if textureTOP == nil or textureSIDE == nil then
		LuaCraftErrorLogging("Both textureTOP and textureSIDE must be provided")
	end
	HUDTilesTextureListPersonalizedLookup[block] = { top = textureTOP, side = textureSIDE }
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
