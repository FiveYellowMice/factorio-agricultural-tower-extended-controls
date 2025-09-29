-- Add some more functions in addition to the core lualib utils.

local core_util = require("__core__.lualib.util")

---@class myutil: util
local util = setmetatable({}, {__index = core_util})


---@generic T: table
---@param orig T
---@return T
function util.shallow_copy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = v
    end
    return copy
end

---Merge tables, entries in later tables override entries in earlier ones.
---@generic T: table
---@param tables T[]
---@return T
function util.shallow_merge(tables)
    local result = {}
    for _, table in ipairs(tables) do
        for k, v in pairs(table) do
            result[k] = v
        end
    end
    return result
end

---@generic T
---@param arrays T[][]
---@return T[]
function util.array_concat(arrays)
    local result = {}
    for _, array in ipairs(arrays) do
        for _, value in ipairs(array) do
            table.insert(result, value)
        end
    end
    return result
end

---Find the index of a value in a table.
---@generic K, V
---@param table table<K, V>
---@param value V
---@return K?
function util.find(table, value)
    if value == nil then return end
    for k, v in pairs(table) do
        if v == value then
            return k
        end
    end
end

local meta_signals_names = util.list_to_map{"signal-everything", "signal-anything", "signal-each"}

---@param signal SignalID
---@return boolean
function util.is_meta_signal(signal)
    return signal.type == "virtual" and meta_signals_names[signal.name]
end


return util