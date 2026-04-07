local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

lib = mods['adamant-ModpackLib']
modutil = mods['SGG_Modding-ModUtil']
local chalk = mods['SGG_Modding-Chalk']
local reload = mods['SGG_Modding-ReLoad']
local dataDefaults = import("config.lua")
local config = chalk.auto('config.lua')

-- =============================================================================
-- MODULE DEFINITION
-- =============================================================================

public.definition = {
    id           = "SpeedrunTimer",
    name         = "Speedrun Timer",
    category     = "QoL",
    subgroup     = "QoL",
    tooltip      = "Displays RTA and load-removed timers on screen during runs.",
    default      = dataDefaults.Enabled,
    affectsRunData = false,
    modpack      = "speedrun",
}

public.store = lib.createStore(config, public.definition, dataDefaults)
store = public.store

-- =============================================================================
-- TIMER IMPORTS
-- =============================================================================

import 'timer/RtaTimer.lua'
import 'timer/LrtTimer.lua'
import 'timer/IgtTimer.lua'
import 'timer/Runtime.lua'
local internal = SpeedrunTimerInternal

-- =============================================================================
-- PUBLIC API
-- =============================================================================

public.getRealTime = internal.GetRealTime
public.getLoadRemovedTime = internal.GetLoadRemovedTime
public.getInGameTime = internal.GetInGameTime

-- =============================================================================
-- Wiring
-- =============================================================================

local loader = reload.auto_single()

local function init()
    import_as_fallback(rom.game)
    internal.RegisterHooks()
end

modutil.once_loaded.game(function()
    loader.load(init, init)
end)

local uiCallback = lib.standaloneUI(public.definition, store)
rom.gui.add_to_menu_bar(uiCallback)
