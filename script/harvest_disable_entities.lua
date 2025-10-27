-- Hidden entities that facilitate circuit-controlled harvest disabling.
-- Each class controls the lifetime of the entity.

-- How they work together:
-- * An infinity container with exactly 1 shim item, and an empty slot.
-- * A proxy container pointing to the output inventory of the agricultural tower.
-- * An inserter pointing [infinity container] -> [proxy container], with circuit condition set
--   to the inverse of the enable condition.
-- * An inserter pointing [proxy container] -> [infinity container], with circuit condition set
--   to the same of the enable condition.
-- When the enable condition is false, shim items fills the agricultural tower's output slots,
-- so it stops harvesting. When the condition is true, shim items are taken out.
-- This avoids having to evaluate circuit condition ourselves and catch when signals change.
-- The inserters do both the sensing and the actuation for us.

local constants = require("constants")
local AuxiliaryEntity = require("script.auxiliary_entity")


---@class HarvestDisableInserter.class: AuxiliaryEntity.class
---@field create fun(self: self, parent: LuaEntity): HarvestDisableInserter
local HarvestDisableInserter = setmetatable({}, {__index = AuxiliaryEntity})

---@class HarvestDisableInserter: AuxiliaryEntity
HarvestDisableInserter.prototype = setmetatable({}, {__index = AuxiliaryEntity.prototype})
HarvestDisableInserter.prototype.__index = HarvestDisableInserter.prototype

function HarvestDisableInserter.prototype:create(parent)
    AuxiliaryEntity.prototype.create(self, parent)

    for _, connector_id in ipairs{defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green} do
        self.entity.get_wire_connector(connector_id, true).connect_to(parent.get_wire_connector(connector_id, true), false, defines.wire_origin.script)
    end

    self.entity.get_or_create_control_behavior()--[[@as LuaInserterControlBehavior]].circuit_enable_disable = true
end

function HarvestDisableInserter.prototype:make_create_entity_param(parent)
    local param = AuxiliaryEntity.prototype.make_create_entity_param(self, parent)
    param.name = constants.entity_harvest_disable_inserter
    return param
end

---@param pickup LuaEntity
---@param drop LuaEntity
function HarvestDisableInserter.prototype:connect(pickup, drop)
    self.entity.pickup_target = pickup
    self.entity.drop_target = drop
end

---@param condition CircuitConditionDefinition
function HarvestDisableInserter.prototype:set_condition(condition)
    local control = self.entity.get_or_create_control_behavior()--[[@as LuaInserterControlBehavior]]
    control.circuit_enable_disable = true
    control.circuit_condition = condition
end


---@class HarvestDisableInfinityContainer.class: AuxiliaryEntity.class
---@field create fun(self: self, parent: LuaEntity): HarvestDisableInfinityContainer
local HarvestDisableInfinityContainer = setmetatable({}, {__index = AuxiliaryEntity})

---@class HarvestDisableInfinityContainer: AuxiliaryEntity
HarvestDisableInfinityContainer.prototype = setmetatable({}, {__index = AuxiliaryEntity.prototype})
HarvestDisableInfinityContainer.prototype.__index = HarvestDisableInfinityContainer.prototype

function HarvestDisableInfinityContainer.prototype:create(parent)
    AuxiliaryEntity.prototype.create(self, parent)
    self.entity.set_infinity_container_filter(1, {
        name = constants.item_blocked_slot,
        count = 1,
        mode = "exactly",
    })
end

function HarvestDisableInfinityContainer.prototype:make_create_entity_param(parent)
    local param = AuxiliaryEntity.prototype.make_create_entity_param(self, parent)
    param.name = constants.entity_harvest_disable_infinity_container
    return param
end


---@class HarvestDisableProxyContainer.class: AuxiliaryEntity.class
---@field create fun(self: self, parent: LuaEntity): HarvestDisableProxyContainer
local HarvestDisableProxyContainer = setmetatable({}, {__index = AuxiliaryEntity})

---@class HarvestDisableProxyContainer: AuxiliaryEntity
HarvestDisableProxyContainer.prototype = setmetatable({}, {__index = AuxiliaryEntity.prototype})
HarvestDisableProxyContainer.prototype.__index = HarvestDisableProxyContainer.prototype

function HarvestDisableProxyContainer.prototype:create(parent)
    AuxiliaryEntity.prototype.create(self, parent)

    self.entity.proxy_target_entity = parent
    self.entity.proxy_target_inventory = defines.inventory.agricultural_tower_output
end

function HarvestDisableProxyContainer.prototype:make_create_entity_param(parent)
    local param = AuxiliaryEntity.prototype.make_create_entity_param(self, parent)
    param.name = constants.entity_harvest_disable_proxy_container
    return param
end


return {
    HarvestDisableInserter = HarvestDisableInserter,
    HarvestDisableInfinityContainer = HarvestDisableInfinityContainer,
    HarvestDisableProxyContainer = HarvestDisableProxyContainer,
}