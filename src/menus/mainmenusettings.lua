_MainMenuSettings = {}
_MainMenuSettings.x = 50
_MainMenuSettings.y = 50
_MainMenuSettings.title = "Settings"
_MainMenuSettings.choice = {}
_MainMenuSettings.choice[1] = "Enable Vsync?"
_MainMenuSettings.choice[2] = "Render Distance"
_MainMenuSettings.choice[3] = "Exiting to main menu"
_MainMenuSettings.selection = 0 -- initialize to 0 to prevent unwanted object selection

function drawMainMenuSettings()
	local w, h = lg.getDimensions()
	local scaleX = w / mainMenuSettingsBackground:getWidth()
	local scaleY = h / mainMenuSettingsBackground:getHeight()

	lg.draw(mainMenuSettingsBackground, 0, 0, 0, scaleX, scaleY)

	local posY = _MainMenuSettings.y
	local lineHeight = font25:getHeight("X")

	-- Title Screen
	drawColorString(_MainMenuSettings.title, _MainMenuSettings.x, posY)
	posY = posY + lineHeight

	-- Choices
	local marque = ""
	for n = 1, #_MainMenuSettings.choice do
		if _MainMenuSettings.selection == n then
			marque = "%1*%0 "
		else
			marque = "   "
		end

		local choiceText = _MainMenuSettings.choice[n]
		if n == 1 then
			local vsyncValue = love.filesystem.read("config.conf"):match("vsync=(%d)")
			if vsyncValue and tonumber(vsyncValue) == 1 then
				choiceText = choiceText .. " X"
			end
		end
		if n == 2 then
			local renderdistancevalue = love.filesystem.read("config.conf"):match("renderdistance=(%d)")
			if renderdistancevalue then
				choiceText = choiceText .. " " .. globalRenderDistance
			end
		end
		drawColorString(marque .. "" .. choiceText, _MainMenuSettings.x, posY)

		posY = posY + lineHeight
	end

	-- Help
	--drawColorString("   [%3Fleches%0] Move the Selection", _MainMenuSettings.x, posY)
	--posY = posY + lineHeight
	--drawColorString("   [%3Retour%0] Valider", _MainMenuSettings.x, posY)
end

function keysinitMainMenuSettings(k)
	if type(_MainMenuSettings.choice) == "table" and _MainMenuSettings.selection then
		if k == "s" then
			if _MainMenuSettings.selection < #_MainMenuSettings.choice then
				_MainMenuSettings.selection = _MainMenuSettings.selection + 1
			end
		elseif k == "z" then
			if _MainMenuSettings.selection > 1 then
				_MainMenuSettings.selection = _MainMenuSettings.selection - 1
			end
		elseif k == "return" then
			if _MainMenuSettings.selection == 1 then
				toggleVSync()
			elseif _MainMenuSettings.selection == 2 then
				renderdistanceSetting()
			elseif _MainMenuSettings.selection == 3 then
				gamestate = "MainMenu"
				_MainMenuSettings.selection = 0
			end
		end
	end
end

function destroyMainMenuSettings()
	_MainMenuSettings = nil
end