lg = love.graphics
lg.setDefaultFilter("nearest")
io.stdout:setvbuf("no")

--libs
g3d = require("libs/g3d")
lume = require("libs/lume")
Object = require("libs/classic")
scene = require("libs/scene")
--menus
require("src/menus/mainmenu")
require("src/menus/mainmenusettings")
require("src/menus/gameplayingpausemenu")
require("src/menus/playinggamesettings")
require("src/menus/worldcreationmenu")
--client
require("src/client/hud/gamehud")
--utils
require("src/utils/usefull")
--world
require("src/world/chunk")
require("src/world/gamescene")
--modloader
require("src/modloader/structuremodloader")
require("src/modloader/modloaderinit")
require("src/modloader/functiontags")
-- ModsRequireIteration
-- Specify the path to the mods directory
local modsDirectory = "mods/"

-- Print debugging information
print("Checking mods directory:", modsDirectory)

-- Iterate over all items in the mods directory
local items = love.filesystem.getDirectoryItems(modsDirectory)
for _, item in ipairs(items) do
	local fullPath = modsDirectory .. item

	-- Print debugging information
	print("Checking item:", fullPath)

	-- Check if the item is a directory
	if love.filesystem.getInfo(fullPath, "directory") then
		-- Assuming you want to load mods from subdirectories
		local modName = item
		print("Attempting to load mod:", modName)

		-- Load the mod
		local success, mod = pcall(require, "mods." .. modName .. "." .. modName)

		-- Check if the mod loaded successfully
		if success then
			print("Mod loaded successfully:", modName)
			-- Assuming the mod has an initialization function
			if mod.initialize then
				mod.initialize()
			end
		else
			print("Failed to load mod:", modName)
			print("Error:", mod)
		end
	end
end

--profiling
ProFi = require("ProFi")
PROF_CAPTURE = false
_JPROFILER = require("libs/jprofiler/jprof")
--profs instruction
--1 : enable PROF_CAPTURE to enable profiler
--2 : profiling some times
--3 : exiting game
--4 : open a CMD on Jprofiler (SRC)
--5 : use this command : love . LuaCraft _JPROFILER.mpack and you will see the viewer
--init
require("src/init/structureinit")
gamestate = "MainMenu"
gameSceneInstance = nil
globalRenderDistance = nil

enableProfiler = false

--Backgrounds
mainMenuBackground = nil
mainMenuSettingsBackground = nil
gameplayingpausemenu = nil
playinggamesettings = nil
worldCreationBackground = nil

globalVSync = love.window.getVSync()

function toggleVSync()
	globalVSync = not globalVSync
	love.window.setVSync(globalVSync and 1 or 0)

	-- Load current contents of config.conf file
	local content, size = love.filesystem.read("config.conf")

	-- Update vsync value in content
	content = content:gsub("vsync=%d", "vsync=" .. (globalVSync and "1" or "0"))

	-- Rewrite config.conf file with updated content
	love.filesystem.write("config.conf", content)
end

function renderdistanceSetting()
	-- Load current contents of config.conf file
	local content, size = love.filesystem.read("config.conf")

	-- Increment the value of globalRenderDistance by 5
	globalRenderDistance = globalRenderDistance + 5

	-- Check if the value exceeds 25, reduce it to 5
	if globalRenderDistance > 25 then
		globalRenderDistance = 5
	end

	-- Update renderdistance value in content using regular expression
	content = content:gsub("renderdistance=(%d+)", "renderdistance=" .. globalRenderDistance)

	-- Rewrite config.conf file with updated content
	love.filesystem.write("config.conf", content)
end

function love.load()
	_JPROFILER.push("frame")
	_JPROFILER.push("Mainload")
	ModLoaderInitALL()
	love.filesystem.setIdentity("LuaCraft")
	if globalRenderDistance == nil then
		-- Read the config file
		local content = love.filesystem.read("config.conf")

		-- Extract value
		local renderDistance = tonumber(content:match("renderdistance=(%d+)")) -- Make sure the key is lowercase "renderdistance"

		-- If no value in file, use default value
		if not renderDistance then
			renderDistance = 5
		end

		-- Set global variable
		globalRenderDistance = renderDistance
	end

	if enableProfiler then
		ProFi:start()
	end
	mainMenuBackground = love.graphics.newImage("resources/assets/backgrounds/MainMenuBackground.png")
	mainMenuSettingsBackground = love.graphics.newImage("resources/assets/backgrounds/Mainmenusettingsbackground.png")
	gameplayingpausemenu = love.graphics.newImage("resources/assets/backgrounds/gameplayingpausemenu.png")
	playinggamesettings = love.graphics.newImage("resources/assets/backgrounds/playinggamesettings.png")
	worldCreationBackground = love.graphics.newImage("resources/assets/backgrounds/WorldCreationBackground.png")

	if love.filesystem.getInfo("config.conf") then
		local content, size = love.filesystem.read("config.conf")

		local vsyncValue = content:match("vsync=(%d)")
		if vsyncValue then
			love.window.setVSync(tonumber(vsyncValue))
		end

		local renderdistanceValue = content:match("renderdistance=(%d)")

		if not renderdistanceValue then
			-- The renderdistance value does not exist, add the default value of 5
			renderdistanceValue = "5"

			-- Add the new line in the config.conf file only if it does not already exist
			if not content:match("renderdistance=") then
				content = content .. "\nrenderdistance=" .. renderdistanceValue

				-- Update config.conf file with new value
				love.filesystem.write("config.conf", content)
			end
		end
	end
	_JPROFILER.pop("Mainload")
	_JPROFILER.pop("frame")
end

function love.update(dt)
	_JPROFILER.push("frame")
	_JPROFILER.push("MainUpdate")
	if gamestate == "PlayingGame" then
		if gameSceneInstance and gameSceneInstance.update then
			gameSceneInstance:update(dt)
		end
	end
	_JPROFILER.pop("MainUpdate")
	_JPROFILER.pop("frame")
end

function love.draw()
	_JPROFILER.push("frame")
	_JPROFILER.push("MainDraw")
	setFont()

	if gamestate == "GamePausing" then
		_JPROFILER.push("drawGamePlayingPauseMenu")
		drawGamePlayingPauseMenu()
		_JPROFILER.pop("drawGamePlayingPauseMenu")
	end
	if gamestate == "WorldCreationMenu" then
		_JPROFILER.push("drawWorldCreationMenu")
		drawWorldCreationMenu()
		_JPROFILER.pop("drawWorldCreationMenu")
	end
	if gamestate == "PlayingGame" then
		_JPROFILER.push("DrawGameScene")
		if not gameSceneInstance then
			gameSceneInstance = GameScene()
			scene(gameSceneInstance)
		end
		if gameSceneInstance and gameSceneInstance.draw then
			gameSceneInstance:draw()
			drawF3MainGame()
		end
		_JPROFILER.pop("DrawGameScene")
	end

	if gamestate == "MainMenuSettings" then
		_JPROFILER.push("drawMainMenuSettings")
		drawMainMenuSettings()
		_JPROFILER.pop("drawMainMenuSettings")
	end

	if gamestate == "MainMenu" then
		_JPROFILER.push("drawMainMenu")
		drawMainMenu()
		_JPROFILER.pop("drawMainMenu")
	end

	if gamestate == "PlayingGameSettings" then
		_JPROFILER.push("drawPlayingMenuSettings")
		drawPlayingMenuSettings()
		_JPROFILER.pop("drawPlayingMenuSettings")
	end

	_JPROFILER.pop("MainDraw")
	_JPROFILER.pop("frame")
end

function love.mousemoved(x, y, dx, dy)
	_JPROFILER.push("frame")
	_JPROFILER.push("Mainmousemoved")
	if gamestate == "PlayingGame" then
		_JPROFILER.push("mousemovedDuringGamePlaying")
		if gameSceneInstance and gameSceneInstance.mousemoved then
			gameSceneInstance:mousemoved(x, y, dx, dy)
		end
		_JPROFILER.pop("mousemovedDuringGamePlaying")
	end
	_JPROFILER.pop("Mainmousemoved")
	_JPROFILER.pop("frame")
end

function love.keypressed(k)
	_JPROFILER.push("frame")
	_JPROFILER.push("MainKeypressed")
	if gamestate == "MainMenu" then
		_JPROFILER.push("keysinitMainMenu")
		keysinitMainMenu(k)
		_JPROFILER.pop("keysinitMainMenu")
	end
	if gamestate == "MainMenuSettings" then
		_JPROFILER.push("keysinitMainMenuSettings")
		keysinitMainMenuSettings(k)
		_JPROFILER.pop("keysinitMainMenuSettings")
	end
	if gamestate == "WorldCreationMenu" then
		_JPROFILER.push("keysInitWorldCreationMenu")
		keysInitWorldCreationMenu(k)
		_JPROFILER.pop("keysInitWorldCreationMenu")
	end
	if gamestate == "PlayingGame" then
		if k == "escape" then
			gamestate = "GamePausing"
		end
	end
	if gamestate == "GamePausing" then
		_JPROFILER.push("keysinitGamePlayingPauseMenu")
		keysinitGamePlayingPauseMenu(k)
		_JPROFILER.pop("keysinitGamePlayingPauseMenu")
	end
	if gamestate == "PlayingGameSettings" then
		_JPROFILER.push("keysinitPlayingMenuSettings")
		keysinitPlayingMenuSettings(k)
		_JPROFILER.pop("keysinitPlayingMenuSettings")
	end
	_JPROFILER.pop("MainKeypressed")
	_JPROFILER.pop("frame")
end

function love.resize(w, h)
	_JPROFILER.push("frame")
	_JPROFILER.push("Mainresize")
	g3d.camera.aspectRatio = w / h
	g3d.camera.updateProjectionMatrix()
	_JPROFILER.pop("Mainresize")
	_JPROFILER.pop("frame")
end

function love.quit()
	_JPROFILER.write("_JPROFILER.mpack")
end
