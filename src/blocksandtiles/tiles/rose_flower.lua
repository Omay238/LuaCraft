local stone_block = {}

function stone_block.initialize()
	addFunctionToTag("addBlock", function()
		addBlock("ROSE_FLOWER_Block",  TileMode.TileMode,
		CollideMode.NoCannotCollide,
		TilesTransparency.FULL,
		LightSources[0])
	end)
end

return stone_block
