-- The blocked slot item can be placed as a building, it then becomes an infinity chest that destroys more of itself put it.

local constants = require("constants")

local BlockedSlotRemover = {}

BlockedSlotRemover.blocked_slot_entity_event_filter = {
    {
        filter = "name",
        name = constants.entity_blocked_slot,
    },
}

---@param entity LuaEntity
---@return boolean
function BlockedSlotRemover.is_block_slot_entity(entity)
    return entity.name == constants.entity_blocked_slot
end

---@param entity LuaEntity
function BlockedSlotRemover.create(entity)
    entity.set_infinity_container_filter(1, {
        name = constants.item_blocked_slot,
        count = 0,
        mode = "at-most",
    })
    entity.remove_unfiltered_items = false
end

return BlockedSlotRemover