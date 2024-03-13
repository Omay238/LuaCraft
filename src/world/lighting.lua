--TODO put lightning into another thread
local SIXDIRECTIONS = {
	{ x = 0, y = -1, z = 0 }, -- Down
	{ x = 0, y = 1, z = 0 }, -- Up
	{ x = 1, y = 0, z = 0 }, -- Right
	{ x = -1, y = 0, z = 0 }, -- Left
	{ x = 0, y = 0, z = 1 }, -- Forward
	{ x = 0, y = 0, z = -1 }, -- Backward
}

local LightingQueue = {}
local LightingRemovalQueue = {}

-- Function to add an item to the lighting queue
local function LightingQueueAdd(lthing)
	LightingQueue[#LightingQueue + 1] = lthing
	return lthing
end

-- Function to add an item to the lighting removal queue
local function LightingRemovalQueueAdd(lthing)
	LightingRemovalQueue[#LightingRemovalQueue + 1] = lthing
	return lthing
end

function LightingUpdate()
	for _, lthing in ipairs(LightingRemovalQueue) do
		lthing:query()
	end
	for _, lthing in ipairs(LightingQueue) do
		lthing:query()
	end
	LightingRemovalQueue = {}
	LightingQueue = {}
end
local function NewSunlightAddition(x, y, z, value)
	local queue = {}
	table.insert(queue, { x = x, y = y, z = z, value = value })

	while #queue > 0 do
		local item = table.remove(queue, 1)
		local cget, cx, cy, cz = GetChunk(item.x, item.y, item.z)
		if cget then
			local val = cget:getVoxel(cx, cy, cz)
			local dat = cget:getVoxelFirstData(cx, cy, cz)
			if item.value >= 0 and TileSemiLightable(val) and dat < item.value then
				cget:setVoxelFirstData(cx, cy, cz, item.value)
				for _, dir in ipairs(SIXDIRECTIONS) do
					local nx, ny, nz = item.x + dir.x, item.y + dir.y, item.z + dir.z
					table.insert(queue, { x = nx, y = ny, z = nz, value = item.value - 1 })
				end
			end
		end
	end
end

local function NewSunlightForceAddition(x, y, z, value)
	local t = { x = x, y = y, z = z, value = value }
	t.query = function(self)
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			return
		end
		local val = cget:getVoxel(cx, cy, cz)
		if self.value >= 0 and TileSemiLightable(val) then
			cget:setVoxelFirstData(cx, cy, cz, self.value)
			for _, dir in ipairs(SIXDIRECTIONS) do
				NewSunlightAddition(self.x + dir.x, self.y + dir.y, self.z + dir.z, self.value - 1)
			end
		end
	end
	LightingQueueAdd(t)
end
local function NewSunlightAdditionCreation(x, y, z)
	local t = { x = x, y = y, z = z }
	t.query = function(self)
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			return
		end
		local val = cget:getVoxel(cx, cy, cz)
		local dat = cget:getVoxelFirstData(cx, cy, cz)
		if TileSemiLightable(val) and dat > 0 then
			NewSunlightForceAddition(self.x, self.y, self.z, dat)
		end
	end
	LightingQueueAdd(t)
end

local function NewSunlightDownAddition(x, y, z, value)
	local t = { x = x, y = y, z = z, value = value }
	t.query = function(self)
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			return
		end
		local val = cget:getVoxel(cx, cy, cz)
		local dat = cget:getVoxelFirstData(cx, cy, cz)
		if TileLightable(val) and dat <= self.value then
			cget:setVoxelFirstData(cx, cy, cz, self.value)
			NewSunlightDownAddition(self.x, self.y - 1, self.z, self.value)
			for _, dir in ipairs(SIXDIRECTIONS) do
				NewSunlightAddition(self.x + dir.x, self.y + dir.y, self.z + dir.z, self.value - 1)
			end
		end
	end
	LightingQueueAdd(t)
end
local function NewLocalLightAddition(x, y, z, value)
	local queue = {}
	table.insert(queue, { x = x, y = y, z = z, value = value })

	while #queue > 0 do
		local item = table.remove(queue, 1)
		local chunk = GetChunk(item.x, item.y, item.z)
		if chunk then
			local cx, cy, cz = Localize(item.x, item.y, item.z)
			local val, dis, dat = chunk:getVoxel(cx, cy, cz)
			if TileSemiLightable(val) and dat < item.value then
				chunk:setVoxelSecondData(cx, cy, cz, item.value)
				if item.value > 1 then
					for _, dir in ipairs(SIXDIRECTIONS) do
						local nx, ny, nz = item.x + dir.x, item.y + dir.y, item.z + dir.z
						table.insert(queue, { x = nx, y = ny, z = nz, value = item.value - 1 })
					end
				end
			end
		end
	end
end
local function NewLocalLightForceAddition(x, y, z, value)
	local t = { x = x, y = y, z = z, value = value }
	t.query = function(self)
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			return
		end
		local val, dis, dat = cget:getVoxel(cx, cy, cz)
		if self.value >= 0 and TileSemiLightable(val) then
			cget:setVoxelSecondData(cx, cy, cz, self.value)
			for _, dir in ipairs(SIXDIRECTIONS) do
				NewLocalLightAddition(self.x + dir.x, self.y + dir.y, self.z + dir.z, self.value - 1)
			end
		end
	end
	LightingQueueAdd(t)
end
local function NewSunlightSubtraction(x, y, z, value)
	local queue = {}
	table.insert(queue, { x = x, y = y, z = z, value = value })

	while #queue > 0 do
		local item = table.remove(queue, 1)
		local cget, cx, cy, cz = GetChunk(item.x, item.y, item.z)

		if cget then
			local val = cget:getVoxel(cx, cy, cz)
			local fget = cget:getVoxelFirstData(cx, cy, cz)

			if fget > 0 and item.value >= 0 and TileSemiLightable(val) then
				if fget < item.value then
					cget:setVoxelFirstData(cx, cy, cz, Tiles.AIR_Block.id)
					for _, dir in ipairs(SIXDIRECTIONS) do
						local nx, ny, nz = item.x + dir.x, item.y + dir.y, item.z + dir.z
						table.insert(queue, { x = nx, y = ny, z = nz, value = fget })
					end
				else
					NewSunlightForceAddition(item.x, item.y, item.z, fget)
				end
			end
		end
	end
end

local function NewSunlightDownSubtraction(x, y, z)
	local queue = {}
	table.insert(queue, { x = x, y = y, z = z })

	while #queue > 0 do
		local item = table.remove(queue, 1)
		if TileSemiLightable(GetVoxel(item.x, item.y, item.z)) then
			SetVoxelFirstData(item.x, item.y, item.z, Tiles.AIR_Block.id)
			table.insert(queue, { x = item.x, y = item.y - 1, z = item.z })
			for _, dir in ipairs(SIXDIRECTIONS) do
				local nx, ny, nz = item.x + dir.x, item.y + dir.y, item.z + dir.z
				NewSunlightSubtraction(nx, ny, nz, LightSources[15])
			end
		end
	end
end
local function NewLocalLightSubtraction(x, y, z, value)
	local t = { x = x, y = y, z = z, value = value }
	t.query = function(self)
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			return
		end
		local val, dat = cget:getVoxel(cx, cy, cz)
		local fget = cget:getVoxelSecondData(cx, cy, cz)
		if fget > 0 and self.value >= 0 and TileSemiLightable(val) then
			if fget < self.value then
				cget:setVoxelSecondData(cx, cy, cz, 0)
				for _, dir in ipairs(SIXDIRECTIONS) do
					local nx, ny, nz = self.x + dir.x, self.y + dir.y, self.z + dir.z
					NewLocalLightSubtraction(nx, ny, nz, fget)
				end
			else
				NewLocalLightForceAddition(self.x, self.y, self.z, fget)
			end
			return false
		end
	end
	LightingRemovalQueueAdd(t)
end
local function NewLocalLightAdditionCreation(x, y, z)
	local t = { x = x, y = y, z = z }
	t.query = function(self)
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			return
		end
		local val, dis, dat = cget:getVoxel(cx, cy, cz)
		if TileSemiLightable(val) and dat > 0 then
			NewLocalLightForceAddition(self.x, self.y, self.z, dat)
		end
	end
	LightingQueueAdd(t)
end

function LightOperation(x, y, z, operation, value)
	if operation == "NewSunlightAddition" then
		NewSunlightAddition(x, y, z, value)
	elseif operation == "NewSunlightAdditionCreation" then
		NewSunlightAdditionCreation(x, y, z)
	elseif operation == "NewSunlightForceAddition" then
		NewSunlightForceAddition(x, y, z, value)
	elseif operation == "NewSunlightDownAddition" then
		NewSunlightDownAddition(x, y, z, value)
	elseif operation == "NewSunlightSubtraction" then
		NewSunlightSubtraction(x, y, z, value)
	elseif operation == "NewSunlightDownSubtraction" then
		NewSunlightDownSubtraction(x, y, z)
	elseif operation == "NewLocalLightSubtraction" then
		NewLocalLightSubtraction(x, y, z, value)
	elseif operation == "NewLocalLightForceAddition" then
		NewLocalLightForceAddition(x, y, z, value)
	elseif operation == "NewLocalLightAddition" then
		NewLocalLightAddition(x, y, z, value)
	elseif operation == "NewLocalLightAdditionCreation" then
		NewLocalLightAdditionCreation(x, y, z)
	else
		LuaCraftErrorLogging("using wrong operation for LightOperation")
		return
	end
end
