local constants = require("constants")
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

script.on_event(defines.events.on_object_destroyed,
    function(event)
        if event.type == defines.target_type.entity and event.useful_id then
            ExtendedTower.remove(event.useful_id)
        end
    end
)

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
local function built_entity_handler(event)
    local entity = event.plant or event.entity

    if entity.type == "plant" then
        -- Wait for the plant to grow
        callback_timer.add(entity.tick_grown, {action = "on_plant_grown", data = entity})
    end
end
local built_entity_filter = {
    {
        filter = "type",
        type = "plant",
    },
}
script.on_event(defines.events.on_tower_planted_seed, built_entity_handler)
script.on_event(defines.events.on_built_entity, built_entity_handler, built_entity_filter)
script.on_event(defines.events.on_robot_built_entity, built_entity_handler, built_entity_filter)
script.on_event(defines.events.on_space_platform_built_entity, built_entity_handler, built_entity_filter)
script.on_event(defines.events.on_trigger_created_entity, built_entity_handler)
script.on_event(defines.events.script_raised_built, built_entity_handler, built_entity_filter)
script.on_event(defines.events.script_raised_revive, built_entity_handler, built_entity_filter)

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
