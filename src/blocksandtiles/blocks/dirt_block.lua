local DIRT_Block = nil

local stone_block = {}

function stone_block.initialize()
	addFunctionToTag("addBlock", function()
		addBlock("DIRT_Block", DIRT_Block)
	end)
end

return stone_block
