-- Representation of an agricultural tower with our extended states.
-- Resides in storage.

local ExtendedTower = {}

---@class ExtendedTower
---@field entity LuaEntity
---@field output_combinator LuaEntity?
---@field read_mature_plants_enabled boolean
---@field read_mature_plants_signal SignalID?
---@field mature_plant_count uint
local prototype = {}

ExtendedTower.prototype = prototype
ExtendedTower.instance_metatable = {
    __index = prototype,
}

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
    }, ExtendedTower.instance_metatable)

    storage.towers[entity.unit_number] = instance
    script.register_on_object_destroyed(entity)

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

    storage.towers[unit_number] = nil
    if tower.output_combinator and tower.output_combinator.valid then
        tower.output_combinator.destroy()
    end
end

---@param entity LuaEntity
---@return boolean
function ExtendedTower.is_agricultural_tower(entity)
    return entity.type == "agricultural-tower"
end

function prototype:recount_mature_plants()
    local count = 0
    for _, plant in pairs(self.entity.owned_plants) do
        if game.tick >= plant.tick_grown then
            count = count + 1
        end
    end
    self.mature_plant_count = count
end


return ExtendedTower