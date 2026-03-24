-- In-Game Time timer. Thin wrapper around the engine's _worldTime global.

IgtTimer = {}

function IgtTimer:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function IgtTimer:getTime()  --luacheck: ignore 212
    return _worldTime
end
