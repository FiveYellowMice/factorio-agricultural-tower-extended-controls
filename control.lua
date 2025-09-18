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
    function (event)
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
    function (event)
        if event.type == defines.target_type.entity and event.useful_id then
            ExtendedTower.remove(event.useful_id)
        end
    end
)

callback_timer.register_action("recount_mature_plants",
    function(plant)
        ExtendedTower.update_tower(plant)
    end
)

script.on_event(defines.events.on_tower_planted_seed,
    function (event)
        callback_timer.add(event.plant.tick_grown, {action = "recount_mature_plants", data = event.plant})
    end
)

script.on_event(defines.events.on_built_entity,
    function (event)
        if event.entity.type == 'plant' then
            callback_timer.add(event.entity.tick_grown, {action = "recount_mature_plants", data = event.entity})
        end
    end
)

script.on_event(defines.events.on_tower_mined_plant,
    function(event)
        ExtendedTower.update_tower(event.plant)
    end
)

script.on_event({defines.events.on_robot_mined_entity, defines.events.on_player_mined_entity, defines.events.on_entity_died},
    ---@param event
    ---| EventData.on_robot_mined_entity
    ---| EventData.on_player_mined_entity
    ---| EventData.on_entity_died
    function(event)
        if event.entity.type == 'plant' then
            ExtendedTower.update_tower(event.entity)
        end
    end
)
