local tower_index = {}

---@param point Vector
---@return Vector
local function point_to_chunk(point)
    return {x = math.floor(point.x / 32), y = math.floor(point.y / 32)}
end

---@param chunk_pos Vector
local function chunk_to_key(chunk_pos)
    return chunk_pos.x .. "," .. chunk_pos.y
end

function tower_index.on_init()
    storage.tower_index = {}
end

---@param tower LuaEntity
function tower_index.add_tower_to_cache(tower)
    local radius = tower.prototype.agricultural_tower_radius
    local chunk_pos_1 = point_to_chunk({x = tower.position.x - radius, y = tower.position.y - radius})
    local chunk_pos_2 = point_to_chunk({x = tower.position.x + radius, y = tower.position.y + radius})

    for x = chunk_pos_1.x, chunk_pos_2.x do
        for y = chunk_pos_1.y, chunk_pos_2.y do
            local key = chunk_to_key({x = x, y = y})
            if not storage.tower_index[key] then
                 -- Create a new list if the key does not exist
                storage.tower_index[key] = {}
            end
            -- add the tower to cache
            storage.tower_index[key][tower] = true
        end
    end
end

---@param tower LuaEntity
function tower_index.remove_tower_from_cache(tower)
    local radius = tower.prototype.agricultural_tower_radius
    local chunk_pos_1 = point_to_chunk({x = tower.position.x - radius, y = tower.position.y - radius})
    local chunk_pos_2 = point_to_chunk({x = tower.position.x + radius, y = tower.position.y + radius})

    for x = chunk_pos_1.x, chunk_pos_2.x do
        for y = chunk_pos_1.y, chunk_pos_2.y do
            local key = chunk_to_key({x = x, y = y})
            if storage.tower_index[key] then
                storage.tower_index[key][tower] = nil
                if next(storage.tower_index[key]) == nil then
                    storage.tower_index[key] = nil
                end
            end
        end
    end
end

---@param point Vector
function tower_index.get_towers_by_point(point)
    local key = chunk_to_key(point_to_chunk(point))
    local towers = {}
    if storage.tower_index[key] then
        for tower, _ in pairs(storage.tower_index[key]) do
            local radius = tower.prototype.agricultural_tower_radius
            -- todo check if the plant is actually registered?
            if point.x >= tower.position.x - radius and point.x <= tower.position.x + radius then
                if point.y >= tower.position.y - radius and point.y <= tower.position.y + radius then
                    table.insert(towers, tower)
                end
            end
        end
    end
    return towers
end

return tower_index
