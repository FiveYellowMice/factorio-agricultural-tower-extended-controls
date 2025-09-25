local constants = require("constants")
local util = require("util")
local callback_timer = require("script.callback_timer")
local ExtendedTower = require("script.extended_tower")
local OutputCombinator = require("script.output_combinator")
local tower_gui = require("script.tower_gui")
local tower_index = require('script.tower_index')

local ExtendedTower_prototype = ExtendedTower.prototype
script.register_metatable("ExtendedTower_prototype", ExtendedTower_prototype)
local OutputCombinator_prototype = OutputCombinator.prototype
script.register_metatable("OutputCombinator_prototype", OutputCombinator_prototype)

script.on_init(
    function()
        ExtendedTower.on_init()
        callback_timer.on_init()
        tower_index.on_init()
    end
)

script.on_configuration_changed(
    function(config_change)
        tower_gui.on_configuration_changed(config_change)
    end
)

script.on_event(defines.events.on_tick,
    function(event)
        callback_timer.on_tick(event)
    end
)


-- GUI events

script.on_event(defines.events.on_gui_opened,
    function(event)
        if event.gui_type ~= defines.gui_type.entity or not event.entity or not event.entity.valid or not ExtendedTower.is_agricultural_tower(event.entity) then
            return
        end
        local player = game.get_player(event.player_index)
        if not player then return end

        tower_gui.destroy(player) -- in case on_gui_closed didn't fire for the last tower GUI
        tower_gui.create(player, event.entity)
    end
)

script.on_event(defines.events.on_gui_closed,
    function(event)
        if event.gui_type ~= defines.gui_type.entity or not event.entity or not event.entity.valid or not ExtendedTower.is_agricultural_tower(event.entity) then
            return
        end
        local player = game.get_player(event.player_index)
        if not player then return end

        tower_gui.destroy(player)
    end
)

script.on_event(
    {
        defines.events.on_gui_checked_state_changed,
        defines.events.on_gui_elem_changed,
    },
    ---@param event
    ---| EventData.on_gui_checked_state_changed
    ---| EventData.on_gui_elem_changed
    function(event)
        local player = game.get_player(event.player_index)
        if not player then return end

        if event.element.tags[constants.gui_changed_event_enabled] then
            tower_gui.on_gui_changed(player)
        end
    end
)


-- Entity creation, plant growth

callback_timer.register_action("on_plant_grown",
    ---@param plant LuaEntity
    function(plant)
        if plant.valid and plant.tick_grown <= game.tick then
            ExtendedTower.on_plant_grown(plant)
        end
    end
)

---@param event
---| EventData.on_tower_planted_seed
---| EventData.on_built_entity
---| EventData.on_robot_built_entity
---| EventData.on_space_platform_built_entity
---| EventData.on_trigger_created_entity
---| EventData.script_raised_built
---| EventData.script_raised_revive
---| EventData.on_entity_cloned
local function built_entity_handler(event)
    local entity = event.plant or event.entity or event.destination

    if entity.type == "plant" then
        -- Wait for the plant to grow
        callback_timer.add(entity.tick_grown, {action = "on_plant_grown", data = entity})

    elseif ExtendedTower.is_agricultural_tower(entity) then
        if event.name == defines.events.on_entity_cloned and event.source then
            ExtendedTower.on_tower_copied(event.source, entity)
        elseif event.tags then
            -- Inherit settings from ghost tags
            ExtendedTower.get_or_create(entity):import_control_settings(event.tags)
        end
    end
end
local built_entity_filter = {
    {
        filter = "type",
        type = "plant",
    },
    ExtendedTower.agricultural_tower_event_filter,
}
script.on_event(defines.events.on_tower_planted_seed, built_entity_handler)
script.on_event(defines.events.on_built_entity, built_entity_handler, built_entity_filter)
script.on_event(defines.events.on_robot_built_entity, built_entity_handler, built_entity_filter)
script.on_event(defines.events.on_space_platform_built_entity, built_entity_handler, built_entity_filter)
script.on_event(defines.events.on_trigger_created_entity, built_entity_handler)
script.on_event(defines.events.script_raised_built, built_entity_handler, built_entity_filter)
script.on_event(defines.events.script_raised_revive, built_entity_handler, built_entity_filter)
script.on_event(defines.events.on_entity_cloned, built_entity_handler, built_entity_filter)


-- Entity destruction, plant harvesting

---@param event
---| EventData.on_tower_mined_plant
---| EventData.on_robot_mined_entity
---| EventData.on_player_mined_entity
---| EventData.on_space_platform_mined_entity
---| EventData.on_entity_died
---| EventData.script_raised_destroy
local function mined_entity_handler(event)
    local entity = event.plant or event.entity

    if entity.type == 'plant' then
        ExtendedTower.on_plant_mined(entity)
    end
end
local mined_entity_filter = {
    {
        filter = "type",
        type = "plant",
    },
}
script.on_event(defines.events.on_tower_mined_plant, mined_entity_handler)
script.on_event(defines.events.on_player_mined_entity, mined_entity_handler, mined_entity_filter)
script.on_event(defines.events.on_robot_mined_entity, mined_entity_handler, mined_entity_filter)
script.on_event(defines.events.on_space_platform_mined_entity, mined_entity_handler, mined_entity_filter)
script.on_event(defines.events.on_entity_died, mined_entity_handler, mined_entity_filter)
script.on_event(defines.events.script_raised_destroy, mined_entity_handler, mined_entity_filter)


-- Tower settings transfer

script.on_event(defines.events.on_entity_settings_pasted,
    function(event)
        if ExtendedTower.is_agricultural_tower(event.destination) then
            ExtendedTower.on_tower_copied(event.source, event.destination)
        end
    end
)

script.on_event(defines.events.on_player_setup_blueprint,
    function(event)
        local player = game.get_player(event.player_index)
        if not player then return end

        local blueprint = nil
        if event.stack and event.stack.valid_for_read then
            blueprint = event.stack
        end
        if event.record and event.record.valid_for_write then
            blueprint = event.record
        end
        if not blueprint then return end

        local entities = blueprint.get_blueprint_entities()
        if not entities then return end
        for _, entity in ipairs(entities) do
            if not ExtendedTower.is_blueprint_agricultural_tower(entity) then goto continue end
            local src_entity = event.mapping.get()[entity.entity_number]--[[@as LuaEntity?]]
            if not src_entity or not ExtendedTower.is_agricultural_tower(src_entity) then goto continue end
            local src_tower = ExtendedTower.get(src_entity)
            if not src_tower then goto continue end

            blueprint.set_blueprint_entity_tags(entity.entity_number, util.merge{
                blueprint.get_blueprint_entity_tags(entity.entity_number) or {},
                src_tower:export_control_settings()
            })
            ::continue::
        end
    end
)

script.on_event(defines.events.on_post_entity_died,
    function(event)
        if ExtendedTower.is_prototype_agricultural_tower(event.prototype) then
            if not event.unit_number or not event.ghost then return end
            -- Inherit extended control settings onto the ghost
            -- Because ExtendedTower instances are removed at the end of the tick, we can still get
            -- one, albeit with an invalid entity.
            local tower = ExtendedTower.get(event.unit_number)
            if not tower then return end

            event.ghost.tags = util.merge{
                event.ghost.tags or {},
                tower:export_control_settings()
            }
        end
    end,
    {ExtendedTower.agricultural_tower_event_filter}
)


-- Ensure the destruction of towers is always caught.
-- Minimize the time invalid entities exist in storage.

script.on_event(defines.events.on_object_destroyed,
    function(event)
        if event.type == defines.target_type.entity and event.useful_id then
            ExtendedTower.remove(event.useful_id)
        end
    end
)