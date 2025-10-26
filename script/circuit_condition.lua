local util = require("script.util")

local circuit_condition = {}

-- Definition of a enable/disable circuit condition.
-- Can represent all states required by GUI.
-- Can be converted to the built-in CircuitCondition.
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

---@type table<ModCircuitCondition.comparator, ModCircuitCondition.comparator>
circuit_condition.comparator_inverse_mapping = {
    [">"] = "≤",
    ["≤"] = ">",
    ["<"] = "≥",
    ["≥"] = "<",
    ["="] = "≠",
    ["≠"] = "=",
}


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

---Convert to the built-in CircuitCondition.
---@param condition ModCircuitCondition
---@param invert boolean Whether to invert the condition.
---@return CircuitCondition
function circuit_condition.export(condition, invert)
    if not invert then
        if circuit_condition.is_complete(condition) then
            -- Meanings are the same if the condition is complete
            return {
                comparator = condition.comparator,
                first_signal = condition.first_signal,
                second_signal = condition.second_signal,
                constant = condition.constant,
            }
        else
            -- Incomplete conditions, no matter how it is incomplete, can only be represented with the first signal being blank
            return {}
        end
    else
        if circuit_condition.is_complete(condition) then
            -- Invert the comparator
            local inverse_comparator = circuit_condition.comparator_inverse_mapping[condition.comparator]
            -- Invert "every" and "any" if they are present in the first signal
            -- Second signal does need the same processing as such meta signals are not allowed there
            local inverse_first_signal = util.table.deepcopy(condition.first_signal--[[@as SignalID]])
            if inverse_first_signal.type == "virtual" and inverse_first_signal.name == "signal-everything" then
                inverse_first_signal.name = "signal-anything"
            elseif inverse_first_signal.type == "virtual" and inverse_first_signal.name == "signal-anything" then
                inverse_first_signal.name = "signal-everything"
            end
            return {
                comparator = inverse_comparator,
                first_signal = inverse_first_signal,
                second_signal = condition.second_signal,
                constant = condition.constant,
            }
        else
            -- Incomplete conditions are always false, so inverts to always true
            return {
                comparator = "=",
                first_signal = {type = "virtual", name = "signal-0"},
                second_signal = {type = "virtual", name = "signal-0"},
            }
        end
    end
end

---Check if the circuit condition is completely defined, thus not always false.
---@param condition ModCircuitCondition
---@return boolean
function circuit_condition.is_complete(condition)
    return (condition.first_signal and (condition.second_signal or condition.constant)) ~= nil
end


return circuit_condition