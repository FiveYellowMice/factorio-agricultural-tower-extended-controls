-- A hidden constant combinator used for script-controlled signal output.
-- Controls the lifetime of the entity.

local constants = require("constants")
local AuxiliaryEntity = require("script.auxiliary_entity")

---@class OutputCombinator.class: AuxiliaryEntity.class
---@field create fun(self: self, parent: LuaEntity): OutputCombinator
local OutputCombinator = setmetatable({}, {__index = AuxiliaryEntity})

---@class OutputCombinator: AuxiliaryEntity
local prototype = setmetatable({}, {__index = AuxiliaryEntity.prototype})
prototype.__index = prototype
OutputCombinator.prototype = prototype

function prototype:create(parent)
    AuxiliaryEntity.prototype.create(self, parent)

    for _, connector_id in ipairs{defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green} do
        self.entity.get_wire_connector(connector_id, true).connect_to(parent.get_wire_connector(connector_id, true), false, defines.wire_origin.script)
    end
end

function prototype:make_create_entity_param(parent)
    local param = AuxiliaryEntity.prototype.make_create_entity_param(self, parent)
    param.name = constants.output_combinator_name
    return param
end

---@param content LogisticFilter[]
function prototype:set_output(content)
    local control = self.entity.get_or_create_control_behavior()--[[@as LuaConstantCombinatorControlBehavior]]
    local section = control.get_section(1)--[[@as LuaLogisticSection]]
    section.filters = content
end

return OutputCombinator