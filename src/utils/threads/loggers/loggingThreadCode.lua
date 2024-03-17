ThreadLogChannel = ...
local Lovez = love
local Lovefilesystem = Lovez.filesystem
local UserDirectory = Lovefilesystem.getUserDirectory()
local Luacraftconfig = UserDirectory .. ".LuaCraft\\Luacraftconfig.txt"
local LogFilePath = UserDirectory .. "\\.LuaCraft\\Luacraft.log"
local function openLogFile(mode)
	return io.open(LogFilePath, mode)
end
local function closeLogFile(file)
	if file then
		file:close()
	end
end
function customReadFile(filePath)
	local file, error_message = io.open(filePath, "r")
	if file then
		local content = file:read("*a") -- *a read all things in the configurations
		file:close()
		return content
	else
		return nil, error_message
	end
end
local function writeToLog(level, ...)
	local file, err = openLogFile("a") -- "a" stands for append mode

	if file then
		local message = os.date("[%Y-%m-%d %H:%M:%S] ") .. "[" .. level .. "] " .. table.concat({ ... }, " ") .. "\n"
		file:write(message)
		closeLogFile(file)
	else
		print("Failed to open log file. Error:", err)
	end
end
local function getLuaCraftPrintLoggingNormalValue()
	local file_content, error_message = customReadFile(Luacraftconfig)
	return file_content and file_content:match("LuaCraftPrintLoggingNormal=(%a+)")
end

local function getLuaCraftPrintLoggingWarnValue()
	local file_content, error_message = customReadFile(Luacraftconfig)
	return file_content and file_content:match("LuaCraftWarnLogging=(%a+)")
end

local function getLuaCraftPrintLoggingErrorValue()
	local file_content, error_message = customReadFile(Luacraftconfig)
	return file_content and file_content:match("LuaCraftErrorLogging=(%a+)")
end

local function log(level, enable, ...)
	if enable then
		local message = table.concat({ ... }, " ")
		writeToLog("[" .. level .. "]", message)
		print("[" .. level .. "]", message)
	end
end
EnableLuaCraftPrintLoggingNormal = getLuaCraftPrintLoggingNormalValue()
local function LuaCraftPrintLoggingNormal(...)
	log("NORMAL", EnableLuaCraftPrintLoggingNormal, ...)
end
EnableLuaCraftLoggingWarn = getLuaCraftPrintLoggingWarnValue()
local function LuaCraftWarnLogging(...)
	log("WARN", EnableLuaCraftLoggingWarn, ...)
end
EnableLuaCraftLoggingError = getLuaCraftPrintLoggingErrorValue()

local function LuaCraftErrorLogging(...)
	log("FATAL", EnableLuaCraftLoggingError, ...)
end

--TODO MADE THIS CAN BE ACCESSED ON MAIN THREAD
LuaCraftLoggingLevel = {
    NORMAL = "NORMAL",
    WARNING = "WARN",
    ERROR = "FATAL",
}

while true do
	local message = ThreadLogChannel:demand()
	if message then
		local level, logMessage = unpack(message)
		if level == "WARN" then
			LuaCraftWarnLogging(logMessage)
		elseif level == "NORMAL" then
			LuaCraftPrintLoggingNormal(logMessage)
		elseif level == "FATAL" then
			LuaCraftErrorLogging(logMessage)
        else
            LuaCraftErrorLogging("You used a wrong level for logging:" .. level)
		end
	end
end
