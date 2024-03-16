local FileSystemSettings = {}
local logFilePath = UserDirectory .. "\\.LuaCraft\\Luacraftconfig.log"

function writeToLog(string, message)
	local file, err = io.open(logFilePath, "a") -- "a" stands for append mode

	if file then
		file:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. string .. message .. "\n")
		file:close()
	else
		LuaCraftErrorLogging("Failed to open log file. Error: " .. err)
	end
end

local ffi = require("ffi")

ffi.cdef([[
    int CreateDirectoryA(const char* lpPathName, void* lpSecurityAttributes);
    int GetLastError(void);
    int _access(const char* path, int mode);
]])

function directoryExists(path)
	return ffi.C._access(path, 0) == 0
end

function createDirectoryIfNotExists(directoryPath)
	if not directoryExists(directoryPath) then
		local success = ffi.C.CreateDirectoryA(directoryPath, nil)

		if success == 0 then
			local err = ffi.C.GetLastError()
			LuaCraftErrorLogging("Failed to create directory. Error code: " .. err)
		end
	end
end

function saveLogsToOldLogsFolder()
	local oldLogsFolder = UserDirectory .. ".LuaCraft\\old_logs\\"
	local timestamp = os.date("%Y%m%d%H%M%S")
	local newLogFilePath = oldLogsFolder .. "luacraftlog_" .. timestamp .. ".txt"

	createDirectoryIfNotExists(oldLogsFolder)

	local currentLogContent, error_message = customReadFile(logFilePath)

	if currentLogContent then
		local file, error_message = io.open(newLogFilePath, "w")
		if file then
			file:write(currentLogContent)
			file:close()
			LuaCraftPrintLoggingNormal("Logs saved to old_logs folder.")

			local resetFile, resetError = io.open(logFilePath, "w")
			if resetFile then
				resetFile:close()
			else
				LuaCraftErrorLogging("Failed to reset main log file. Error: " .. resetError)
			end
		else
			LuaCraftErrorLogging("Failed to open file for writing. Error: " .. error_message)
		end
	else
		LuaCraftErrorLogging("Failed to read current log file. Error: " .. error_message)
	end
end

function checkAndUpdateDefaults(Settings)
	_JPROFILER.push("checkAndUpdateDefaults")
	if Settings["vsync"] == nil then
		Settings["vsync"] = true
	elseif Settings["LuaCraftPrintLoggingNormal"] == nil then
		Settings["LuaCraftPrintLoggingNormal"] = true
	elseif Settings["LuaCraftWarnLogging"] == nil then
		Settings["LuaCraftWarnLogging"] = true
	elseif Settings["LuaCraftErrorLogging"] == nil then
		Settings["LuaCraftErrorLogging"] = true
	elseif Settings["renderdistance"] == nil then
		Settings["renderdistance"] = 2
	elseif Settings["fullscreen"] == nil then
		Settings["fullscreen"] = false
	end
	_JPROFILER.pop("checkAndUpdateDefaults")
end

function customReadFile(filePath)
	--_JPROFILER.push("customReadFile")

	local file, error_message = io.open(filePath, "r")

	if file then
		local content = file:read("*a") -- *a read all things in the configurations
		file:close()
		--	_JPROFILER.pop("customReadFile")
		return content
	else
		return nil, error_message
	end
end

function createFileIfNotExists(filePath)
	local file, err = io.open(filePath, "r")

	if not file then
		local directory = filePath:match("(.+\\).-$")
		os.execute('mkdir "' .. directory .. '"')

		file, err = io.open(filePath, "w")

		if not file then
			error("Failed to create file. Error: " .. err)
		end

		file:close()
		LuaCraftPrintLoggingNormal("Created file: " .. filePath)
	else
		file:close()
	end
end

function loadAndSaveLuaCraftFileSystem()
	_JPROFILER.push("loadAndSaveLuaCraftFileSystem")

	LuaCraftPrintLoggingNormal("Attempting to load LuaCraft settings")

	local luaCraftDirectory = UserDirectory .. ".LuaCraft\\"
	local configFilePath = luaCraftDirectory .. "Luacraftconfig.txt"

	createFileIfNotExists(configFilePath)

	LuaCraftPrintLoggingNormal("Directory contents before attempting to load settings:")
	for _, item in ipairs(love.filesystem.getDirectoryItems(luaCraftDirectory)) do
		LuaCraftPrintLoggingNormal(item)
	end

	LuaCraftPrintLoggingNormal("Config file path: " .. configFilePath)

	local file_content, error_message = customReadFile(configFilePath)

	if file_content then
		local orderedKeys = {
			"vsync",
			"LuaCraftPrintLoggingNormal",
			"LuaCraftWarnLogging",
			"LuaCraftErrorLogging",
			"renderdistance",
			"fullscreen",
		}

		for _, key in ipairs(orderedKeys) do
			local value = file_content:match(key .. "=(%w+)")
			if value then
				local numValue = tonumber(value)
				FileSystemSettings[key] = numValue or (value == "true")
			end
		end

		LuaCraftPrintLoggingNormal("Settings loaded successfully.")

		checkAndUpdateDefaults(FileSystemSettings)

		-- Open the file in Writter mod
		local file, error_message = io.open(configFilePath, "w")

		if file then
			-- Write parameters with verifications
			for _, key in ipairs(orderedKeys) do
				file:write(key .. "=" .. tostring(FileSystemSettings[key]) .. "\n")
			end

			file:close()
			LuaCraftPrintLoggingNormal("Settings loaded and saved to Luacraftconfig.txt")
		else
			LuaCraftErrorLogging("Failed to open file for writing. Error: " .. error_message)
		end
	else
		LuaCraftErrorLogging("Failed to open file for reading. Error: " .. error_message)
	end
	_JPROFILER.pop("loadAndSaveLuaCraftFileSystem")
end

function getLuaCraftPrintLoggingNormalValue()
	local file_content, error_message = customReadFile(Luacraftconfig)
	return file_content and file_content:match("LuaCraftPrintLoggingNormal=(%d)")
end

function getLuaCraftPrintLoggingWarnValue()
	local file_content, error_message = customReadFile(Luacraftconfig)
	return file_content and file_content:match("LuaCraftWarnLogging=(%d)")
end

function getLuaCraftPrintLoggingErrorValue()
	local file_content, error_message = customReadFile(Luacraftconfig)
	return file_content and file_content:match("LuaCraftErrorLogging=(%d)")
end

function LuaCraftPrintLoggingNormal(...)
	if EnableLuaCraftPrintLoggingNormalLogging then
		local message = table.concat({ ... }, " ")
		writeToLog("[NORMAL]", message)
		print("[NORMAL]", message)
	end
end

EnableLuaCraftLoggingWarn = getLuaCraftPrintLoggingWarnValue()

function LuaCraftWarnLogging(...)
	if EnableLuaCraftLoggingWarn then
		local message = table.concat({ ... }, " ")
		writeToLog("[WARN]", message)
		print("[WARN]", message)
	end
end

EnableLuaCraftLoggingError = getLuaCraftPrintLoggingErrorValue()

function LuaCraftErrorLogging(...)
	if EnableLuaCraftLoggingError then
		local message = table.concat({ ... }, " ")
		writeToLog("[FATAL]", message)
		error(message)
	end
end

local logFilePath = UserDirectory .. "\\.LuaCraft\\Luacraftconfig.log"

function writeToLog(string, message)
	local file, err = io.open(logFilePath, "a") -- "a" stands for append mode

	if file then
		file:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. string .. message .. "\n")
		file:close()
	else
	end
end
