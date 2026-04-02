SpeedrunTimerInternal = SpeedrunTimerInternal or {}
local internal = SpeedrunTimerInternal

local SpeedrunTimer = {}

function SpeedrunTimer:new()
    local o = {}
    o.Running = false
    o.RtaTimer = RtaTimer:new()
    o.LrtTimer = LrtTimer:new({ withRtaTimer = o.RtaTimer })
    o.IgtTimer = IgtTimer:new()
    setmetatable(o, self)
    self.__index = self
    return o
end

function SpeedrunTimer:start()
    self.Running = true
    self.RtaTimer:start()
    self.LrtTimer:start()
end

function SpeedrunTimer:stop()
    self.Running = false
    self.RtaTimer:stop()
    self.LrtTimer:stop()
end

function SpeedrunTimer:reset()
    self.Running = false
    self.RtaTimer:reset()
    self.LrtTimer:reset()
end

function SpeedrunTimer:update()
    self.RtaTimer:update()
    self.LrtTimer:update()
end

function SpeedrunTimer:getRealTime()
    return self.RtaTimer:getTime()
end

function SpeedrunTimer:getLoadRemovedTime()
    return self.LrtTimer:getTime()
end

function SpeedrunTimer:getInGameTime()
    return self.IgtTimer:getTime()
end

local ANCHOR_PREFIX = "adamant_SpeedrunTimer:"

local function FormatTimestamp(timestamp)
    if not timestamp then return "00:00.00" end
    local centiseconds = (timestamp % 1) * 100
    local seconds = timestamp % 60
    local minutes = 0
    local hours = 0

    if timestamp > 60 then
        minutes = math.floor((timestamp % 3600) / 60)
    end
    if timestamp > 3600 then
        hours = math.floor(timestamp / 3600)
    end

    if hours == 0 then
        return string.format("%02d:%02d.%02d", minutes, seconds, centiseconds)
    end
    return string.format("%02d:%02d:%02d.%02d", hours, minutes, seconds, centiseconds)
end

local function CreateOverlayLine(anchorName, text, kwargs)
    local textFormat = DeepCopyTable(UIData.CurrentRunDepth.TextFormat)
    local x_pos = kwargs.x_pos or 500
    local y_pos = kwargs.y_pos or 500

    textFormat.Font = kwargs.font or textFormat.Font
    textFormat.FontSize = kwargs.font_size or textFormat.FontSize
    textFormat.Color = kwargs.color or textFormat.Color
    textFormat.Justification = kwargs.justification or textFormat.Justification
    textFormat.ShadowColor = kwargs.shadow_color or { 0, 0, 0, 0 }

    if ScreenAnchors[anchorName] ~= nil then
        ModifyTextBox({
            Id = ScreenAnchors[anchorName],
            Text = text,
            Color = kwargs.color or textFormat.Color,
        })
    else
        ScreenAnchors[anchorName] = CreateScreenObstacle({
            Name = "BlankObstacle",
            X = x_pos,
            Y = y_pos,
            Group = "Combat_Menu_TraitTray_Overlay",
        })
        CreateTextBox(MergeTables(textFormat, {
            Id = ScreenAnchors[anchorName],
            Text = text,
        }))
        ModifyTextBox({
            Id = ScreenAnchors[anchorName],
            FadeTarget = 1,
            FadeDuration = 0.0,
        })
    end
end

local function DestroyAnchor(anchorName)
    if ScreenAnchors[anchorName] ~= nil then
        Destroy({ Id = ScreenAnchors[anchorName] })
        ScreenAnchors[anchorName] = nil --luacheck: ignore 443
    end
end

local function DrawTimer(timerName, timer, yOffset)
    CreateOverlayLine(
        ANCHOR_PREFIX .. timerName,
        FormatTimestamp(timer:getTime()),
        {
            justification = "left",
            x_pos = 1820,
            y_pos = 180 + yOffset,
            font_size = 20,
        }
    )
end

local function CleanupDisplay()
    DestroyAnchor(ANCHOR_PREFIX .. "LRT")
    DestroyAnchor(ANCHOR_PREFIX .. "RTA")
end

local activeTimer = nil
local updateThreadActive = false

local function StopAndCleanup()
    if activeTimer then
        activeTimer:stop()
    end
    activeTimer = nil
    updateThreadActive = false
    CleanupDisplay()
end

function internal.RegisterHooks()
    modutil.mod.Path.Wrap("StartNewRun", function(baseFunc, prevRun, args)
        if not lib.isEnabled(store, public.definition.modpack) then return baseFunc(prevRun, args) end
        if activeTimer then
            StopAndCleanup()
        end
        activeTimer = SpeedrunTimer:new()
        return baseFunc(prevRun, args)
    end)

    modutil.mod.Path.Wrap("RoomEntranceMaterialize", function(baseFunc, ...)
        if not lib.isEnabled(store, public.definition.modpack) then return baseFunc(...) end
        local val = baseFunc(...)

        if activeTimer and not activeTimer.Running then
            activeTimer:start()
        end

        if activeTimer and activeTimer.Running and not updateThreadActive then
            updateThreadActive = true
            thread(function()
                while activeTimer and activeTimer.Running do
                    if not lib.isEnabled(store, public.definition.modpack) then
                        StopAndCleanup()
                        return
                    end
                    activeTimer:update()
                    DrawTimer("LRT", activeTimer.LrtTimer, 30)
                    DrawTimer("RTA", activeTimer.RtaTimer, 50)
                    wait(0.016, "adamant_SpeedrunTimer", true)
                end
                updateThreadActive = false
            end)
        end

        return val
    end)

    modutil.mod.Path.Wrap("ChronosKillPresentation", function(baseFunc, ...)
        if not lib.isEnabled(store, public.definition.modpack) then return baseFunc(...) end
        if activeTimer then
            activeTimer:stop()
        end
        return baseFunc(...)
    end)

    modutil.mod.Path.Wrap("AddTimerBlock", function(baseFunc, currRun, timerBlockName)
        local val = baseFunc(currRun, timerBlockName)
        if lib.isEnabled(store, public.definition.modpack) and timerBlockName == "MapLoad"
                and activeTimer and activeTimer.Running then

            activeTimer.LrtTimer:processLoadEvent(true)
        end
        return val
    end)

    modutil.mod.Path.Wrap("RemoveTimerBlock", function(baseFunc, currRun, timerBlockName)
        local val = baseFunc(currRun, timerBlockName)
        if lib.isEnabled(store, public.definition.modpack) and timerBlockName == "MapLoad"
                and activeTimer and activeTimer.Running then

            activeTimer.LrtTimer:processLoadEvent(false)
        end
        return val
    end)
end

function internal.GetRealTime()
    if activeTimer then return FormatTimestamp(activeTimer:getRealTime()) end
    return "00:00.00"
end

function internal.GetLoadRemovedTime()
    if activeTimer then return FormatTimestamp(activeTimer:getLoadRemovedTime()) end
    return "00:00.00"
end

function internal.GetInGameTime()
    if activeTimer then return FormatTimestamp(activeTimer:getInGameTime()) end
    return "00:00.00"
end
