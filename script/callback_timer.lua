-- Schedule callbacks to be run at a certain ticks.
-- To work around the inability to store functions in storage, a string key to a table of preregistered functions is used instead.
-- Owns the on_tick event, and it will only be enabled when necessary.

local callback_timer = {}

---@class CallbackTimer
---@field action string Name of the action to take
---@field data any Data to pass to the function registered for this action

---@type table<string, fun(any): nil>
local callback_actions = {}

---Register an action for a callback timer to invoke. Should only be called at the control.lua stage.
---@param name string
---@param fun fun(any): nil
function callback_timer.register_action(name, fun)
    callback_actions[name] = fun
end

function callback_timer.on_init()
    ---@type table<MapTick, CallbackTimer[]?>
    storage.callback_timers = {}
end

---@param event EventData.on_tick
function callback_timer.on_tick(event)
    -- Retrieve callbacks of this tick
    local callbacks = storage.callback_timers[event.tick]
    if not callbacks then return end
    storage.callback_timers[event.tick] = nil

    for _, callback in ipairs(callbacks) do
        callback_timer.invoke(callback)
    end
end

---@package
---@param callback CallbackTimer
function callback_timer.invoke(callback)
    local action = callback_actions[callback.action]
    if not action then
        error("Attempting to invoke callback action \""..callback.action.."\" but it is not registered")
    end
    action(callback.data)
end

---Schedule a callback timer.
---@param at_tick MapTick
---@param callback CallbackTimer
function callback_timer.add(at_tick, callback)
    -- Run the callback now if it's not in the future
    if at_tick <= game.tick then
        callback_timer.invoke(callback)
        return
    end

    -- Add the new callback to storage
    local callbacks = storage.callback_timers[at_tick]
    if not callbacks then
        callbacks = {}
        storage.callback_timers[at_tick] = callbacks
    end
    table.insert(callbacks, callback)
end

return callback_timer