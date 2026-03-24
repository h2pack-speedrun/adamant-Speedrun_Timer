-- Base Timer class. Provides start/stop/reset/pause/resume interface.
-- Subclasses implement update() and trueUp() based on their timing source.

Timer = {}

function Timer:new(args)
    args = args or {}
    local o = {
        Running = args.Running or false,
        Paused = false,
        WasReset = false,
        ElapsedTime = args.ElapsedTime or 0,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Timer:init(startingOffset)
    self.ElapsedTime = startingOffset or 0
end

function Timer:start(startingOffset)
    self:init(startingOffset)
    self.Running = true
    self.Paused = false
end

function Timer:setTime(time)
    self.ElapsedTime = time
end

function Timer:getTime()
    return self.ElapsedTime
end

function Timer:pause()
    self.Paused = true
    self:trueUp()
end

function Timer:resume()
    self.Paused = false
end

function Timer:stop()
    self.Running = false
    self:trueUp()
end

function Timer:reset()
    self.Running = false
    self.Paused = false
    self.WasReset = true
    self.ElapsedTime = 0
end

function Timer:update() end  --luacheck: ignore 212
function Timer:trueUp() end  --luacheck: ignore 212
