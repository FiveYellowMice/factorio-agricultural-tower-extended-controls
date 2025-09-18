-- Representation of an agricultural tower with our extended states.
-- Resides in storage.

local tower_index = require('script.tower_index')
local OutputCombinator = require("script.output_combinator")

local ExtendedTower = {}

---@class ExtendedTower
---@field entity LuaEntity
---@field output_combinator OutputCombinator?
---@field read_mature_plants_enabled boolean
---@field read_mature_plants_signal SignalID?
---@field mature_plant_count uint
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
        read_mature_plants_enabled = false,
        mature_plant_count = 0,
    }, ExtendedTower.prototype)

    storage.towers[entity.unit_number] = instance
    script.register_on_object_destroyed(entity)

    tower_index.add_tower(entity)

    instance:recount_mature_plants()

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

    tower_index.remove_tower(tower.entity)
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

---Called when the extended control settings have changed. Update the behaviour and perform necessary changes.
function prototype:on_control_settings_updated()
    -- Create or destroy the output combinator
    if self.read_mature_plants_enabled then
        if not self.output_combinator then
            self.output_combinator = OutputCombinator.create(self.entity)
        end
        self:recount_mature_plants()
    else
        if self.output_combinator then
            self.output_combinator:destroy()
            self.output_combinator = nil
        end
    end
end

---@param plant LuaEntity
function ExtendedTower.update_tower(plant)
    local tower_ids = tower_index.get_towers_ids(plant.position)
    for _, id in ipairs(tower_ids) do
        local tower = ExtendedTower.get(id)
        if tower then
            tower:recount_mature_plants()
        end
    end
end

function prototype:recount_mature_plants()
    local count = 0
    for _, plant in pairs(self.entity.owned_plants) do
        if game.tick >= plant.tick_grown then
            count = count + 1
        end
    end
    self.mature_plant_count = count

    if self.read_mature_plants_enabled and self.read_mature_plants_signal and self.output_combinator then
        self.output_combinator:set_output({
            {
                value = {
                    type = self.read_mature_plants_signal.type,
                    name = self.read_mature_plants_signal.name,
                    quality = self.read_mature_plants_signal.quality,
                },
                min = self.mature_plant_count,
            }
        })
    end
end


return ExtendedTower