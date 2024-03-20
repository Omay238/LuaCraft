GamestateKeybindingMainSettings2 = GameStateBase:new()

function GamestateKeybindingMainSettings2:draw()
	_JPROFILER.push("drawMenuSettings")
	local w, h = Lovegraphics.getDimensions()
	local scaleX = w / KeybindingSettingsBackground:getWidth()
	local scaleY = h / KeybindingSettingsBackground:getHeight()

	Lovegraphics.draw(KeybindingSettingsBackground, 0, 0, 0, scaleX, scaleY)

	local posY = _KeybindingMenuSettings.y
	local lineHeight = Font25:getHeight("X")

	-- Title Screen
	drawColorString(_KeybindingMenuSettings.title, _KeybindingMenuSettings.x, posY)
	posY = posY + lineHeight

	-- Choices
	local marque = ""
	local file_content, error_message = customReadFile(Luacraftconfig)

	if file_content then
		local Settings = {}
		local orderedKeys = { "forwardmovementkey", "backwardmovementkey", "leftmovementkey", "rightmovementkey" }

		for _, key in ipairs(orderedKeys) do
			local value = file_content:match(key .. "=(%w+)")
			if value then
				Settings[key] = value
			end
		end

		for n = 1, #_KeybindingMenuSettings.choice do
			if _KeybindingMenuSettings.selection == n then
				marque = "%1*%0 "
			else
				marque = "   "
			end

			local choiceText = _KeybindingMenuSettings.choice[n]
			local numberOfSpaces = 1
			if n == 1 and Settings["forwardmovementkey"] then
				choiceText = choiceText .. string.rep(" ", numberOfSpaces) .. Settings["forwardmovementkey"]
			end

			if n == 2 and Settings["backwardmovementkey"] then
				choiceText = choiceText .. string.rep(" ", numberOfSpaces) .. Settings["backwardmovementkey"]
			end
			if n == 3 and Settings["leftmovementkey"] then
				choiceText = choiceText .. string.rep(" ", numberOfSpaces) .. Settings["leftmovementkey"]
			end
			if n == 4 and Settings["rightmovementkey"] then
				choiceText = choiceText .. string.rep(" ", numberOfSpaces) .. Settings["rightmovementkey"]
			end
			drawColorString(marque .. "" .. choiceText, _KeybindingMenuSettings.x, posY)

			posY = posY + lineHeight
		end
	else
		ThreadLogChannel:push({
			LuaCraftLoggingLevel.ERROR,
			"Failed to read Luacraftconfig.txt. Error: " .. error_message,
		})
	end
	_JPROFILER.pop("drawMenuSettings")
end

function GamestateKeybindingMainSettings2:mousepressed(x, y, b)
	if b == 1 then
		local choiceClicked = math.floor((y - _KeybindingMenuSettings.y) / Font25:getHeight("X"))
		if choiceClicked >= 1 and choiceClicked <= #_KeybindingMenuSettings.choice then
			_KeybindingMenuSettings.selection = choiceClicked
			if choiceClicked == 1 then
				ConfiguringMovementKey = true
			elseif choiceClicked == 2 then
				ConfiguringMovementKey = true
			elseif choiceClicked == 3 then
				ConfiguringMovementKey = true
			elseif choiceClicked == 4 then
				ConfiguringMovementKey = true
			elseif choiceClicked == 5 then
				SetPlayingGamestateMainMenuSettings2()
				_KeybindingMenuSettings.selection = 0
			end
		end
	end
end

function GamestateKeybindingMainSettings2:keypressed(k)
	if type(_KeybindingMenuSettings.choice) == "table" and _KeybindingMenuSettings.selection then
		if k == BackWardKey and ConfiguringMovementKey == false then
			if _KeybindingMenuSettings.selection < #_KeybindingMenuSettings.choice then
				_KeybindingMenuSettings.selection = _KeybindingMenuSettings.selection + 1
			end
		elseif k == ForWardKey and ConfiguringMovementKey == false then
			if _KeybindingMenuSettings.selection > 1 then
				_KeybindingMenuSettings.selection = _KeybindingMenuSettings.selection - 1
			end
		elseif k == "return" then
			if _KeybindingMenuSettings.selection == 1 then
				ConfiguringMovementKey = true
			elseif _KeybindingMenuSettings.selection == 2 then
				ConfiguringMovementKey = true
			elseif _KeybindingMenuSettings.selection == 3 then
				ConfiguringMovementKey = true
			elseif _KeybindingMenuSettings.selection == 4 then
				ConfiguringMovementKey = true
			elseif _KeybindingMenuSettings.selection == 5 then
				SetPlayingGamestateMainMenuSettings2()
				_KeybindingMenuSettings.selection = 0
			end
		end
	end
end