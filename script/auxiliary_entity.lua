-- Abstract class owning an entity that exists to implement a feature of a parent entity.
-- An instance of this class controls the lifetime of the auxiliary entity.

local util = require("script.util")

---@class AuxiliaryEntity.class
local AuxiliaryEntity = {}

---@class AuxiliaryEntity
---@field entity LuaEntity
local prototype = {}
prototype.__index = prototype
AuxiliaryEntity.prototype = prototype

---@param parent LuaEntity
---@return AuxiliaryEntity
function AuxiliaryEntity:create(parent)
    local instance = setmetatable({}, self.prototype)
    instance:create(parent)
    return instance
end

---Create the corresponding entity, disregarding the old one if any.
---@param parent LuaEntity
function prototype:create(parent)
    local create_entity_param = self:make_create_entity_param(parent)
    local entity = parent.surface.create_entity(create_entity_param)

    if not entity then
        error("Failed to create auxiliary entity "..create_entity_param.name)
    end

    entity.destructible = false
    entity.minable = false

    self.entity = entity
end

---@param parent LuaEntity
---@return LuaSurface.create_entity_param
function prototype:make_create_entity_param(parent)
    return {
        name = "",
        position = parent.position,
        force = parent.force,
    }
end

function prototype:destroy()
    self.entity.destroy()
end

---@return boolean
function prototype:valid()
    return self.entity.valid
end

---Ensure the entity this manages is valid, if not, recreate it.
---@param parent LuaEntity
function prototype:ensure_valid(parent)
    if not self:valid() then
        self:create(parent)
    end
end

return AuxiliaryEntity