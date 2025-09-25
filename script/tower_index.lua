-- Index for quickly finding agricultural towers potentially covering a given map position.
-- To do this, we divide the map into a grid of square chunks, where the index maps chunk coordinates to sets of towers.
-- When a tower is added or removed from the index, it is registered in all chunks that intersect with its influence radius.
-- This enables efficient spatial queries to find all towers that could affect a given position on the map.

local constants = require("constants")
local tower_index = {}

---@param point MapPosition
---@return Vector
local function position_to_chunk(point)
    return {x = math.floor(point.x / constants.index_chunk_size), y = math.floor(point.y / constants.index_chunk_size)}
end

---@alias TowerIndexKey string
---@param chunk_pos Vector
---@return TowerIndexKey
local function index_key(surface_index, chunk_pos)
    return surface_index .. ":" .. chunk_pos.x .. "," .. chunk_pos.y
end

function tower_index.on_init()
    ---@type table<TowerIndexKey, table<LuaEntity, true>>
    storage.tower_index = {}
end

---@param tower LuaEntity
function tower_index.add_tower(tower)
    local radius = tower.prototype.agricultural_tower_radius * tower.prototype.growth_grid_tile_size
    local chunk_pos_1 = position_to_chunk({x = tower.bounding_box.left_top.x - radius, y = tower.bounding_box.left_top.y - radius})
    local chunk_pos_2 = position_to_chunk({x = tower.bounding_box.right_bottom.x + radius, y = tower.bounding_box.right_bottom.y + radius})
    for x = chunk_pos_1.x, chunk_pos_2.x do
        for y = chunk_pos_1.y, chunk_pos_2.y do
            local key = index_key(tower.surface_index, {x = x, y = y})
            if not storage.tower_index[key] then
                 -- Create a new list if the key does not exist
                storage.tower_index[key] = {}
            end
            -- add the tower to cache
            storage.tower_index[key][tower.unit_number] = true
        end
    end
end

---@param tower_id uint64
function tower_index.remove_tower(tower_id)
    for key, towers in pairs(storage.tower_index) do
        if towers[tower_id] then
            towers[tower_id] = nil
            if next(storage.tower_index[key]) == nil then
                storage.tower_index[key] = nil
            end
        end
    end
end

---@param tower LuaEntity
function tower_index.remove_tower_within_range(tower)
    local radius = tower.prototype.agricultural_tower_radius * tower.prototype.growth_grid_tile_size
    local chunk_pos_1 = position_to_chunk({x = tower.bounding_box.left_top.x - radius, y = tower.bounding_box.left_top.y - radius})
    local chunk_pos_2 = position_to_chunk({x = tower.bounding_box.right_bottom.x + radius, y = tower.bounding_box.right_bottom.y + radius})
    for x = chunk_pos_1.x, chunk_pos_2.x do
        for y = chunk_pos_1.y, chunk_pos_2.y do
            local key = index_key(tower.surface_index, {x = x, y = y})
            if storage.tower_index[key] then
                storage.tower_index[key][tower.unit_number] = nil
                if next(storage.tower_index[key]) == nil then
                    storage.tower_index[key] = nil
                end
            end
        end
    end
end

---@param surface_index integer
---@param position MapPosition
---@return uint64[]
function tower_index.get_towers_ids(surface_index, position)
    local key = index_key(surface_index, position_to_chunk(position))
    local towers = {}
    if storage.tower_index[key] then
        for tower_uid, _ in pairs(storage.tower_index[key]) do
            table.insert(towers, tower_uid)
        end
    end
    return towers
end

return tower_index
