-- A hidden constant combinator used for script-controlled signal output.
-- Controls the lifetime of the entity.

local constants = require("constants")

local OutputCombinator = {}

---@class OutputCombinator
---@field entity LuaEntity
local prototype = {}
prototype.__index = prototype
OutputCombinator.prototype = prototype

---@param parent LuaEntity
---@return OutputCombinator
function OutputCombinator.create(parent)
    local entity = parent.surface.create_entity{
        name = constants.output_combinator_name,
        position = parent.position,
        force = parent.force,
    }
    ---@cast entity LuaEntity

    entity.destructible = false
    entity.minable_flag = false

    for _, connector_id in ipairs{defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green} do
        entity.get_wire_connector(connector_id, true).connect_to(parent.get_wire_connector(connector_id, true), false, defines.wire_origin.script)
    end

    return setmetatable({
        entity = entity,
    }, prototype)
end

function prototype:destroy()
    self.entity.destroy()
end

---@param content LogisticFilter[]
function prototype:set_output(content)
    local control = self.entity.get_or_create_control_behavior()--[[@as LuaConstantCombinatorControlBehavior]]
    local section = control.get_section(1)--[[@as LuaLogisticSection]]
    section.filters = content
end

return OutputCombinator