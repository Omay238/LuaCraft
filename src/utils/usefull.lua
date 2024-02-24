font25 = lg.newFont(25)
font15 = lg.newFont(15)

local colorMap = {
	["0"] = { 255, 255, 255 }, -- white
	["1"] = { 255, 0, 0 }, -- red
	["2"] = { 0, 255, 0 }, -- green
	["3"] = { 0, 255, 255 }, -- blue
}

function drawColorString(Pstring, Px, Py)
	_JPROFILER.push("drawColorString")
	local rx, ry = Px, Py
	local defaultColor = { 255, 255, 255 }
	local currentColor = defaultColor

	lg.setColor(currentColor)

	local i = 1
	local len = #Pstring

	while i <= len do
		local c = string.sub(Pstring, i, i)

		if c == "%" then
			local colorDigit = string.sub(Pstring, i + 1, i + 1)
			currentColor = colorMap[tostring(colorDigit)] or defaultColor
			lg.setColor(currentColor)
			i = i + 2 -- skip both '%' and the color digit
		else
			lg.print(c, rx, ry)
			local fontWidth = (
				gamestate == "MainMenu"
				or gamestate == "MainMenuSettings"
				or gamestate == "GamePausing"
				or gamestate == "PlayingGameSettings"
			)
					and font25
				or ("WorldCreationMenu" or gamestate == "PlayingGame") and font15
			rx = rx + fontWidth:getWidth(c)
			i = i + 1
		end
	end
	lg.setColor(defaultColor)
	_JPROFILER.pop("drawColorString")
end

local fontTable = {
	MainMenu = font25,
	MainMenuSettings = font25,
	GamePausing = font25,
	PlayingGameSettings = font25,
	WorldCreationMenu = font15,
	PlayingGame = font15,
}

function setFont()
	_JPROFILER.push("setFont")
	local selectedFont = fontTable[gamestate]
	if selectedFont then
		lg.setFont(selectedFont)
	end
	_JPROFILER.pop("setFont")
end

function IsStructureIsGenerated(x, y, z)
	_JPROFILER.push("IsStructureIsGenerated")
	local blockKey = string.format("%d/%d/%d", x, y, z)
	_JPROFILER.pop("IsStructureIsGenerated")
	return StructureMap[blockKey]
end

function isChunkFullyGenerated(scene, chunkX, chunkY, chunkZ)
	local chunkKey = ("%d/%d/%d"):format(chunkX, chunkY, chunkZ)
	local chunk = scene.chunkMap[chunkKey]

	return chunk and chunk.data
end
