--dependencies (if you had error caused by something like attempt to index global nil then try to add deps)
require("src/modloader/functiontags")
--mod dependencies (here you should add all lua of your mod here to don't had problems during initialize)
require("mods/ExampleMod/structures/generatepillar")

local ExampleMod = {}

function ExampleMod.initialize()
    --addTagToFunction are used here to unsure that structure will be generated
	addTagToFunction(ExampleMod_generatePillarAtRandomLocation, "generateStructuresatRandomLocation") --this is disabled for now because see the line 5 in structureinit.lua
	addTagToFunction(ExampleMod_generatePillarAtFixedPosition, "generateStructuresInPlayerRange")
	addTagToFunction(ExampleMod_generatePillarAtFixedPosition, "generateStructuresatFixedPositions")
end

return ExampleMod
