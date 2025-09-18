local constants = require("constants")
local callback_timer = require("script.callback_timer")
local ExtendedTower = require("script.extended_tower")
local tower_gui = require("script.tower_gui")

local ExtendedTower_instance_metatable = ExtendedTower.instance_metatable
script.register_metatable("ExtendedTower_instance_metatable", ExtendedTower_instance_metatable)

script.on_init(
    function()
        ExtendedTower.on_init()
        callback_timer.on_init()
    end
)

script.on_configuration_changed(
    function(config_change)
        tower_gui.on_configuration_changed(config_change)
    end
)

script.on_load(
    function()
        callback_timer.on_load()
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
    ---@param unit_number uint64
    function(unit_number)
        local tower = ExtendedTower.get(unit_number)
        if tower then
            tower:recount_mature_plants()
        end
    end
)

script.on_event(defines.events.on_tower_planted_seed,
    function (event)
        local tower = ExtendedTower.get(event.tower)
        if tower then
            callback_timer.add(event.plant.tick_grown, {action = "recount_mature_plants", data = tower.entity.unit_number})
        end
    end
)

script.on_event(defines.events.on_tower_mined_plant,
    function(event)
        local tower = ExtendedTower.get(event.tower)
        if tower then
            tower:recount_mature_plants()
        end
    end
)
