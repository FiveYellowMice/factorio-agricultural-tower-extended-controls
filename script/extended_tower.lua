-- Representation of an agricultural tower with our extended states.
-- Resides in storage.

local tower_index = require("script.tower_index")
local callback_timer = require("script.callback_timer")
local OutputCombinator = require("script.output_combinator")

local ExtendedTower = {}

---@class ExtendedTower
---@field entity LuaEntity
---@field output_combinator OutputCombinator?
---@field read_mature_plants_enabled boolean
---@field read_mature_plants_signal SignalID?
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
        read_mature_plants_enabled = false,
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

ExtendedTower.agricultural_tower_event_filter = {
    filter = "type",
    type = "agricultural-tower",
}

---Called when an agricultural tower is cloned or settings copied.
---@param source LuaEntity
---@param destination LuaEntity
function ExtendedTower.on_tower_copied(source, destination)
    local src_tower = ExtendedTower.get(source)
    if not src_tower then return end

    local dst_tower = ExtendedTower.get_or_create(destination)
    dst_tower.read_mature_plants_enabled = src_tower.read_mature_plants_enabled
    dst_tower.read_mature_plants_signal = src_tower.read_mature_plants_signal

    dst_tower:on_control_settings_updated()
end

---@param plant LuaEntity
function ExtendedTower.on_plant_grown(plant)
    local tower_ids = tower_index.get_towers_ids(plant.position)
    for _, id in ipairs(tower_ids) do
        local tower = ExtendedTower.get(id)
        if tower and tower:valid() and tower.read_mature_plants_enabled then
            -- TODO: check if plant is witin tower range
            tower:recount_mature_plants()
        end
    end
end

callback_timer.register_action("recount_mature_plants",
    ---@param unit_number uint64
    function(unit_number)
        local tower = ExtendedTower.get(unit_number)
        if tower and tower:valid() and tower.read_mature_plants_enabled then
            tower:recount_mature_plants()
        end
    end
)

---@param plant LuaEntity
function ExtendedTower.on_plant_mined(plant)
    local tower_ids = tower_index.get_towers_ids(plant.position)
    for _, id in ipairs(tower_ids) do
        local tower = ExtendedTower.get(id)
        if tower and tower:valid() and tower.read_mature_plants_enabled then
            -- TODO: check if plant is witin tower range

            -- This function gets called from events fired before the entity is actually destroyed
            -- (else we wouldn't get a valid LuaEntity object), so recounting needs to happen 1 tick
            -- after to not count the plant pending destruction.
            callback_timer.add(game.tick + 1, {action = "recount_mature_plants", data = id})
        end
    end
end

---@return boolean
function prototype:valid()
    return self.entity.valid
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
                    quality = self.read_mature_plants_signal.quality or "normal",
                },
                min = self.mature_plant_count,
            }
        })
    end
end


return ExtendedTower