function createLoggingThread()
    local ThreadLogChannel = love.thread.newChannel()
    local thread = love.thread.newThread("src/utils/threads/loggers/loggingThreadCode.lua")
    thread:start(ThreadLogChannel)
    return ThreadLogChannel
end
