-- Representation of an agricultural tower with our extended states.
-- Resides in storage.

local constants = require("constants")
local util = require("script.util")
local tower_index = require("script.tower_index")
local OutputCombinator = require("script.output_combinator")

local ExtendedTower = {}

---Control settings managed by this mod. Value copiable, storable in tags.
---@class (exact) ExtendedTowerControlSettings
---@field read_mature_plants_enabled boolean
---@field read_mature_plants_signal SignalID?
---@field enable_harvest boolean
---@field harvest_condition_type string
---@field harvest_condition_signal_1 SignalID?
---@field harvest_condition_comparator_index int
---@field harvest_condition_constant string
---@field harvest_condition_signal_2 SignalID?
ExtendedTower.default_control_settings = {
    read_mature_plants_enabled = false,
    read_mature_plants_signal = nil,
    enable_harvest = false,
    harvest_condition_type = "constant",
    harvest_condition_signal_1 = nil,
    harvest_condition_comparator_index = 2,
    harvest_condition_constant = "0",  -- should I use string here?
    harvest_condition_signal_2 = nil,
}

---@class ExtendedTower
---@field entity LuaEntity
---@field control_settings ExtendedTowerControlSettings
---@field output_combinator OutputCombinator?
---@field mature_plant_count uint Valid only when read_mature_plants_enabled is true.
local prototype = {}
prototype.__index = prototype
ExtendedTower.prototype = prototype

function ExtendedTower.on_init()
    ---@type table<uint64, ExtendedTower>
    storage.towers = {}
end

---Create an ExtendedTower in storage based on the provided agricultural tower entity.
---Do not call before checking for absence of the object.
---@package
---@param entity LuaEntity
---@return ExtendedTower
function ExtendedTower.create(entity)
    if not entity.valid then
        error("Cannot create ExtendedTower for an invalid entity")
    end
    if not ExtendedTower.is_agricultural_tower(entity) then
        error("Cannot create ExtendedTower for an entity that is not an agricultural tower")
    end

    local instance = setmetatable({
        entity = entity,
        control_settings = util.table.deepcopy(ExtendedTower.default_control_settings),
        mature_plant_count = 0,
    }, ExtendedTower.prototype)

    storage.towers[entity.unit_number] = instance
    script.register_on_object_destroyed(entity)

    tower_index.add_tower(entity)

    instance:on_control_settings_updated()

    return instance
end

---@param entity LuaEntity | uint64
---@return ExtendedTower?
function ExtendedTower.get(entity)
    if type(entity) == "number" then
        return storage.towers[entity]
    else
        return storage.towers[entity.unit_number]
    end
end

---@param entity LuaEntity
---@return ExtendedTower
function ExtendedTower.get_or_create(entity)
    return storage.towers[entity.unit_number] or ExtendedTower.create(entity)
end

---@param unit_number uint64
function ExtendedTower.remove(unit_number)
    local tower = storage.towers[unit_number]
    if not tower then return end

    tower_index.remove_tower(unit_number)
    if tower.output_combinator then
        tower.output_combinator:destroy()
    end

    storage.towers[unit_number] = nil
end

---@param entity LuaEntity
---@return boolean
function ExtendedTower.is_agricultural_tower(entity)
    return entity.type == "agricultural-tower"
end

---@param entity LuaEntity
---@return boolean
function ExtendedTower.is_ghost_agricultural_tower(entity)
    return entity.type == "entity-ghost" and entity.ghost_type == "agricultural-tower"
end

---@param prototype LuaEntityPrototype
---@return boolean
---@diagnostic disable-next-line: redefined-local
function ExtendedTower.is_prototype_agricultural_tower(prototype)
    return prototype.type == "agricultural-tower"
end

---@param entity BlueprintEntity
---@return boolean
function ExtendedTower.is_blueprint_agricultural_tower(entity)
    ---@diagnostic disable-next-line: redefined-local
    local prototype = prototypes.entity[entity.name]
    return prototype ~= nil and ExtendedTower.is_prototype_agricultural_tower(prototype)
end

ExtendedTower.agricultural_tower_event_filter = {
    {
        filter = "type",
        type = "agricultural-tower",
    },
}

---Get the extended control settings of a tower or a ghost.
---@param entity LuaEntity | uint64 An agricultural tower, a ghost of one, or a unit number of one.
---@return ExtendedTowerControlSettings?
function ExtendedTower.get_control_settings(entity)
    if type(entity) == "number" --[[@cast entity LuaEntity]] or ExtendedTower.is_agricultural_tower(entity) then
        local tower = ExtendedTower.get(entity)
        if tower then
            return tower:get_control_settings()
        end
        return
    end
    ---@cast entity LuaEntity

    if ExtendedTower.is_ghost_agricultural_tower(entity) then 
        if entity.tags and type(entity.tags[constants.entity_tag_control_settings]) == "table" then
            return entity.tags[constants.entity_tag_control_settings] --[[@as ExtendedTowerControlSettings]]
        end
    end
end

---Set the extended control settings of a tower or a ghost.
---@param entity LuaEntity An agricultural tower or a ghost of one.
---@param control_settings ExtendedTowerControlSettings
function ExtendedTower.set_control_settings(entity, control_settings)
    if ExtendedTower.is_ghost_agricultural_tower(entity) then
        local tags = entity.tags or {}
        tags[constants.entity_tag_control_settings] = control_settings
        entity.tags = tags

    elseif ExtendedTower.is_agricultural_tower(entity) then
        local dst_tower = ExtendedTower.get_or_create(entity)
        dst_tower:set_control_settings(control_settings)
    end
end

---@param plant LuaEntity
function ExtendedTower.on_plant_grown(plant)
    local tower_ids = tower_index.get_towers_ids(plant.surface_index, plant.position)
    for _, id in ipairs(tower_ids) do
        local tower = ExtendedTower.get(id)
        if tower and tower:valid() and tower.control_settings.read_mature_plants_enabled then
            -- TODO: check if plant is within tower range
            tower:recount_mature_plants()
        end
    end
end

---@param plant LuaEntity
function ExtendedTower.on_plant_mined(plant)
    local tower_ids = tower_index.get_towers_ids(plant.surface_index, plant.position)
    for _, id in ipairs(tower_ids) do
        local tower = ExtendedTower.get(id)
        if tower and tower:valid() and tower.control_settings.read_mature_plants_enabled then
            -- TODO: check if plant is witin tower range

            -- This function gets called from events fired before the entity is actually destroyed
            -- (else we wouldn't get a valid LuaEntity object), so recounting needs to exclude the
            -- entity pending destruction from being counted.
            tower:recount_mature_plants(plant)
        end
    end
end

---@return boolean
function prototype:valid()
    return self.entity.valid
end

---@return ExtendedTowerControlSettings
function prototype:get_control_settings()
    return util.table.deepcopy(self.control_settings)
end

---@param control_settings ExtendedTowerControlSettings
function prototype:set_control_settings(control_settings)
    self.control_settings = util.table.deepcopy(control_settings)
    self:on_control_settings_updated()
end

---Called when the extended control settings have changed. Update the behaviour and perform necessary changes.
function prototype:on_control_settings_updated()
    -- Create or destroy the output combinator
    if self.control_settings.read_mature_plants_enabled then
        if not self.output_combinator then
            self.output_combinator = OutputCombinator:create(self.entity)
        end
        self:recount_mature_plants()
    else
        if self.output_combinator then
            self.output_combinator:destroy()
            self.output_combinator = nil
        end
    end
end

---Recount the number of mature plants from scratch.
---Assumes tower entity is valid.
---@param exclude LuaEntity? Exclude an entity from being counted, e.g. an entity pending destruction.
function prototype:recount_mature_plants(exclude)
    local count = 0
    for _, plant in pairs(self.entity.owned_plants) do
        if plant == exclude then goto continue end
        if game.tick >= plant.tick_grown then
            count = count + 1
        end
        ::continue::
    end
    self.mature_plant_count = count

    if self.control_settings.read_mature_plants_enabled and self.control_settings.read_mature_plants_signal and self.output_combinator then
        self.output_combinator:ensure_valid(self.entity)
        self.output_combinator:set_output({
            {
                value = {
                    type = self.control_settings.read_mature_plants_signal.type,
                    name = self.control_settings.read_mature_plants_signal.name,
                    quality = self.control_settings.read_mature_plants_signal.quality or "normal",
                },
                min = self.mature_plant_count,
            }
        })
    end
end


return ExtendedTower