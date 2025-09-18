---@param tower LuaEntity
function add_tower_to_cache(tower)
    local radius = tower.prototype.agricultural_tower_radius
    local chunk_pos_1 = point_to_chunk({x = tower.position.x - radius, y = tower.position.y - radius})
    local chunk_pos_2 = point_to_chunk({x = tower.position.x + radius, y = tower.position.y + radius})

    for x = chunk_pos_1.x, chunk_pos_2.x do
        for y = chunk_pos_1.y, chunk_pos_2.y do
            if not storage.tower_cache[{x = x, y = y}] then
                 -- Create a new list if the key does not exist
                storage.tower_cache[{x = x, y = y}] = {}
            end
            -- add the tower to cache
            storage.tower_cache[{x = x, y = y}][tower] = true
        end
    end
end

---@param tower LuaEntity
function remove_tower_from_cache(tower)
    local radius = tower.prototype.agricultural_tower_radius
    local chunk_pos_1 = point_to_chunk({x = tower.position.x - radius, y = tower.position.y - radius})
    local chunk_pos_2 = point_to_chunk({x = tower.position.x + radius, y = tower.position.y + radius})

    for x = chunk_pos_1.x, chunk_pos_2.x do
        for y = chunk_pos_1.y, chunk_pos_2.y do
            if storage.tower_cache[{x = x, y = y}] then
                storage.tower_cache[{x = x, y = y}][tower] = nil
                if next(storage.tower_cache[{x = x, y = y}]) == nil then
                    storage.tower_cache[{x = x, y = y}] = nil
                end
            end
        end
    end
end

---@param point Vector
function get_towers_by_point(point)
    local chunk_pos = point_to_chunk(point)
    local towers = {}
    if storage.tower_cache[chunk_pos] then
        for tower, _ in pairs(storage.tower_cache[chunk_pos]) do
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

---@param point Vector
---@return Vector
function point_to_chunk(point)
    return {x = math.floor(point.x / 32), y = math.floor(point.y / 32)}
end
