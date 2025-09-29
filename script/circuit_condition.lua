local util = require("script.util")

local circuit_condition = {}

-- Definition of a enable/disable circuit condition.
-- Can represent all states required by GUI.
-- Can be converted to and from the built-in CircuitCondition.
---@class (exact) ModCircuitCondition
---@field comparator ModCircuitCondition.comparator
---@field first_signal SignalID?
---@field second_signal SignalID? Must not coexist with `constant`.
---@field constant int? If exists, means user has selected "constant" for RHS, if not, means user has selected "signal" even when `second_signal` is nil.

---@enum ModCircuitCondition.comparator
circuit_condition.comparators = {
    [1] = ">",
    [2] = "<",
    [3] = "=",
    [4] = "≥",
    [5] = "≤",
    [6] = "≠",
}
circuit_condition.default_comparator_index = 2
circuit_condition.default_comparator = circuit_condition.comparators[circuit_condition.default_comparator_index]


---Remove meta signals that may not exist in a circuit condition.
---@param condition ModCircuitCondition
function circuit_condition.reject_meta_signals(condition)
    -- First signal: allow "every" and "any"
    if condition.first_signal and condition.first_signal.type == "virtual" and condition.first_signal.name == "signal-each" then
        condition.first_signal = nil
    end
    -- Second signal: allow none
    if condition.second_signal and util.is_meta_signal(condition.second_signal) then
        condition.second_signal = nil
    end
end


return circuit_condition