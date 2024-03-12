--TODO put lightning into another thread
local SIXDIRECTIONS = {
	{ x = 0, y = -1, z = 0 }, -- Down
	{ x = 0, y = 1, z = 0 }, -- Up
	{ x = 1, y = 0, z = 0 }, -- Right
	{ x = -1, y = 0, z = 0 }, -- Left
	{ x = 0, y = 0, z = 1 }, -- Forward
	{ x = 0, y = 0, z = -1 }, -- Backward
}
local FOURDIRECTIONS = {
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
	_JPROFILER.push("LightingUpdate")
	_JPROFILER.push("LightingUpdate_LightingRemovalQueue")
	for _, lthing in ipairs(LightingRemovalQueue) do
		lthing:query()
	end
	_JPROFILER.pop("LightingUpdate_LightingRemovalQueue")
	_JPROFILER.push("LightingUpdate_LightingQueue")
	for _, lthing in ipairs(LightingQueue) do
		lthing:query()
	end
	_JPROFILER.pop("LightingUpdate_LightingQueue")
	_JPROFILER.push("LightingUpdate_LightingRemovalQueueReset")
	LightingRemovalQueue = {}
	_JPROFILER.pop("LightingUpdate_LightingRemovalQueueReset")
	_JPROFILER.push("LightingUpdate_LightingQueueReset")
	LightingQueue = {}
	_JPROFILER.pop("LightingUpdate_LightingQueueReset")
	_JPROFILER.pop("LightingUpdate")
end
function NewSunlightAddition(x, y, z, value)
	_JPROFILER.push("NewSunlightAddition")
	local queue = {}
	table.insert(queue, { x = x, y = y, z = z, value = value })

	while #queue > 0 do
		_JPROFILER.push("NewSunlightAddition_inner_loop")
		local item = table.remove(queue, 1)
		local cget, cx, cy, cz = GetChunk(item.x, item.y, item.z)
		if cget then
			_JPROFILER.push("NewSunlightAddition_getVoxel")
			local val = cget:getVoxel(cx, cy, cz)
			_JPROFILER.pop("NewSunlightAddition_getVoxel")

			_JPROFILER.push("NewSunlightAddition_getVoxelFirstData")
			local dat = cget:getVoxelFirstData(cx, cy, cz)
			_JPROFILER.pop("NewSunlightAddition_getVoxelFirstData")

			_JPROFILER.push("NewSunlightAddition_condition")
			if item.value >= 0 and TileSemiLightable(val) and dat < item.value then
				_JPROFILER.push("NewSunlightAddition_setVoxelFirstData")
				cget:setVoxelFirstData(cx, cy, cz, item.value)
				_JPROFILER.pop("NewSunlightAddition_setVoxelFirstData")

				_JPROFILER.push("NewSunlightAddition_insert_queue")
				for _, dir in ipairs(SIXDIRECTIONS) do
					local nx, ny, nz = item.x + dir.x, item.y + dir.y, item.z + dir.z
					table.insert(queue, { x = nx, y = ny, z = nz, value = item.value - 1 })
				end
				_JPROFILER.pop("NewSunlightAddition_insert_queue")
			end
			_JPROFILER.pop("NewSunlightAddition_condition")
		end
		_JPROFILER.pop("NewSunlightAddition_inner_loop")
	end
	_JPROFILER.pop("NewSunlightAddition")
end

function NewSunlightAdditionCreation(x, y, z)
	_JPROFILER.push("NewSunlightAdditionCreation")
	local t = { x = x, y = y, z = z }
	t.query = function(self)
		_JPROFILER.push("NewSunlightAdditionCreation_query")
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			_JPROFILER.pop("NewSunlightAdditionCreation_query")
			return
		end
		local val = cget:getVoxel(cx, cy, cz)
		local dat = cget:getVoxelFirstData(cx, cy, cz)
		if TileSemiLightable(val) and dat > 0 then
			_JPROFILER.push("NewSunlightAdditionCreation_force_addition")
			NewSunlightForceAddition(self.x, self.y, self.z, dat)
			_JPROFILER.pop("NewSunlightAdditionCreation_force_addition")
		end
		_JPROFILER.pop("NewSunlightAdditionCreation_query")
	end
	LightingQueueAdd(t)
	_JPROFILER.pop("NewSunlightAdditionCreation")
end

function NewSunlightForceAddition(x, y, z, value)
	_JPROFILER.push("NewSunlightForceAddition")
	local t = { x = x, y = y, z = z, value = value }
	t.query = function(self)
		_JPROFILER.push("NewSunlightForceAddition_query")
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			_JPROFILER.pop("NewSunlightForceAddition_query")
			return
		end
		local val = cget:getVoxel(cx, cy, cz)
		if self.value >= 0 and TileSemiLightable(val) then
			_JPROFILER.push("NewSunlightForceAddition_set_voxel_first_data")
			cget:setVoxelFirstData(cx, cy, cz, self.value)
			_JPROFILER.pop("NewSunlightForceAddition_set_voxel_first_data")
			for _, dir in ipairs(SIXDIRECTIONS) do
				_JPROFILER.push("NewSunlightForceAddition_loop")
				NewSunlightAddition(self.x + dir.x, self.y + dir.y, self.z + dir.z, self.value - 1)
				_JPROFILER.pop("NewSunlightForceAddition_loop")
			end
		end
		_JPROFILER.pop("NewSunlightForceAddition_query")
	end
	LightingQueueAdd(t)
	_JPROFILER.pop("NewSunlightForceAddition")
end

function NewSunlightDownAddition(x, y, z, value)
	_JPROFILER.push("NewSunlightDownAddition")
	local t = { x = x, y = y, z = z, value = value }
	t.query = function(self)
		_JPROFILER.push("NewSunlightDownAddition_query")
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			_JPROFILER.pop("NewSunlightDownAddition_query")
			return
		end
		local val = cget:getVoxel(cx, cy, cz)
		local dat = cget:getVoxelFirstData(cx, cy, cz)
		if TileLightable(val) and dat <= self.value then
			_JPROFILER.push("NewSunlightDownAddition_set_voxel_first_data")
			cget:setVoxelFirstData(cx, cy, cz, self.value)
			_JPROFILER.pop("NewSunlightDownAddition_set_voxel_first_data")
			_JPROFILER.push("NewSunlightDownAddition_recursive_call")
			NewSunlightDownAddition(self.x, self.y - 1, self.z, self.value)
			_JPROFILER.pop("NewSunlightDownAddition_recursive_call")
			for _, dir in ipairs(FOURDIRECTIONS) do
				_JPROFILER.push("NewSunlightDownAddition_loop")
				NewSunlightAddition(self.x + dir.x, self.y + dir.y, self.z + dir.z, self.value - 1)
				_JPROFILER.pop("NewSunlightDownAddition_loop")
			end
		end
		_JPROFILER.pop("NewSunlightDownAddition_query")
	end
	LightingQueueAdd(t)
	_JPROFILER.pop("NewSunlightDownAddition")
end

function NewSunlightSubtraction(x, y, z, value)
	_JPROFILER.push("NewSunlightSubtraction")
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
					_JPROFILER.push("NewSunlightSubtraction_force_addition")
					NewSunlightForceAddition(item.x, item.y, item.z, fget)
					_JPROFILER.pop("NewSunlightSubtraction_force_addition")
				end
			end
		end
	end
	_JPROFILER.pop("NewSunlightSubtraction")
end

function NewSunlightDownSubtraction(x, y, z)
	_JPROFILER.push("NewSunlightDownSubtraction")
	local queue = {}
	table.insert(queue, { x = x, y = y, z = z })

	while #queue > 0 do
		local item = table.remove(queue, 1)
		if TileSemiLightable(GetVoxel(item.x, item.y, item.z)) then
			SetVoxelFirstData(item.x, item.y, item.z, Tiles.AIR_Block.id)
			table.insert(queue, { x = item.x, y = item.y - 1, z = item.z }) -- Ajouter la case en dessous à la file d'attente
			for _, dir in ipairs(FOURDIRECTIONS) do
				local nx, ny, nz = item.x + dir.x, item.y + dir.y, item.z + dir.z
				_JPROFILER.push("NewSunlightDownSubtraction_recursive_call")
				NewSunlightSubtraction(nx, ny, nz, LightSources[15])
				_JPROFILER.pop("NewSunlightDownSubtraction_recursive_call")
			end
		end
	end
	_JPROFILER.pop("NewSunlightDownSubtraction")
end

function NewLocalLightSubtraction(x, y, z, value)
	_JPROFILER.push("NewLocalLightSubtraction")
	local t = { x = x, y = y, z = z, value = value }
	t.query = function(self)
		_JPROFILER.push("NewLocalLightSubtraction_query")
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			_JPROFILER.pop("NewLocalLightSubtraction_query")
			return
		end
		local val, dat = cget:getVoxel(cx, cy, cz)
		local fget = cget:getVoxelSecondData(cx, cy, cz)
		if fget > 0 and self.value >= 0 and TileSemiLightable(val) then
			if fget < self.value then
				cget:setVoxelSecondData(cx, cy, cz, 0)
				for _, dir in ipairs(SIXDIRECTIONS) do
					local nx, ny, nz = self.x + dir.x, self.y + dir.y, self.z + dir.z
					_JPROFILER.push("NewLocalLightSubtraction_recursive_call")
					NewLocalLightSubtraction(nx, ny, nz, fget)
					_JPROFILER.pop("NewLocalLightSubtraction_recursive_call")
				end
			else
				_JPROFILER.push("NewLocalLightSubtraction_force_addition")
				NewLocalLightForceAddition(self.x, self.y, self.z, fget)
				_JPROFILER.pop("NewLocalLightSubtraction_force_addition")
			end
			_JPROFILER.pop("NewLocalLightSubtraction_query")
			return false
		end
		_JPROFILER.pop("NewLocalLightSubtraction_query")
	end
	LightingRemovalQueueAdd(t)
	_JPROFILER.pop("NewLocalLightSubtraction")
end

function NewLocalLightForceAddition(x, y, z, value)
	_JPROFILER.push("NewLocalLightForceAddition")
	local t = { x = x, y = y, z = z, value = value }
	t.query = function(self)
		_JPROFILER.push("NewLocalLightForceAddition_query")
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			_JPROFILER.pop("NewLocalLightForceAddition_query")
			return
		end
		local val, dis, dat = cget:getVoxel(cx, cy, cz)
		if self.value >= 0 and TileSemiLightable(val) then
			cget:setVoxelSecondData(cx, cy, cz, self.value)
			for _, dir in ipairs(SIXDIRECTIONS) do
				_JPROFILER.push("NewLocalLightForceAddition_loop")
				NewLocalLightAddition(self.x + dir.x, self.y + dir.y, self.z + dir.z, self.value - 1)
				_JPROFILER.pop("NewLocalLightForceAddition_loop")
			end
		end
		_JPROFILER.pop("NewLocalLightForceAddition_query")
	end
	LightingQueueAdd(t)
	_JPROFILER.pop("NewLocalLightForceAddition")
end
function NewLocalLightAddition(x, y, z, value)
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
function NewLocalLightAdditionCreation(x, y, z)
	_JPROFILER.push("NewLocalLightAdditionCreation")
	local t = { x = x, y = y, z = z }
	t.query = function(self)
		_JPROFILER.push("NewLocalLightAdditionCreation_query")
		local cget, cx, cy, cz = GetChunk(self.x, self.y, self.z)
		if cget == nil then
			_JPROFILER.pop("NewLocalLightAdditionCreation_query")
			return
		end
		local val, dis, dat = cget:getVoxel(cx, cy, cz)
		if TileSemiLightable(val) and dat > 0 then
			_JPROFILER.push("NewLocalLightAdditionCreation_force_addition")
			NewLocalLightForceAddition(self.x, self.y, self.z, dat)
			_JPROFILER.pop("NewLocalLightAdditionCreation_force_addition")
		end
		_JPROFILER.pop("NewLocalLightAdditionCreation_query")
	end
	LightingQueueAdd(t)
	_JPROFILER.pop("NewLocalLightAdditionCreation")
end
