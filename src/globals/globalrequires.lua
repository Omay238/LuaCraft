require("src/modloader/modloaderinit")
Cpml = require("libs/cpml")
PROF_CAPTURE = false
_JPROFILER = require("libs/jprofiler/jprof")
--profs instruction
--1 : enable PROF_CAPTURE to enable profiler
--2 : profiling some times
--3 : exiting game
--4 : open a CMD on Jprofiler (SRC)
--5 : use this command : love . LuaCraft _JPROFILER.mpack and you will see the viewer
Ffi = require("ffi")
Perspective = require("src/client/huds/perspective")
Engine = require("engine")

local modules = {
	"menus/mainmenu",
	"menus/gameplayingpausemenu",
	"menus/worldcreationmenu",
	"menus/settings/mainmenusettings",
	"menus/settings/keybindingmenusettings",
	"blocksandtiles/tiledata",
	"utils/things",
	"utils/math",
	"utils/mouseandkeybindlogic",
	"utils/usefull",
	"utils/filesystem",
	"utils/settingshandling",
	"utils/commands/commandsexec",
	"utils/threads/threadtest",
	"utils/threads/loggers/loggingThreadCreator",
	"entities/player",
	"world/lighting",
	"world/updatelogic",
	"world/gen/generator",
	"world/gen/caves",
	"world/utilities/chunkmethods",
	"world/utilities/voxelsmethods",
	"world/chunks/chunkutils",
	"world/chunks/chunkmain",
	"init/!init",
	"client/huds/!draw",
	"client/blocks/blockrendering",
	"client/blocks/tilerendering",
	"modloader/modloaderinit",
}
local function requireGroup(group, path)
	if type(group) == "table" then
		for _, moduleName in ipairs(group) do
			requireGroup(moduleName, path)
		end
	elseif type(group) == "string" then
		require(path .. group)
	else
		error("Invalid group type: " .. type(group))
	end
end
for _, moduleGroup in ipairs(modules) do
	requireGroup(moduleGroup, "src/")
end
modules = nil
