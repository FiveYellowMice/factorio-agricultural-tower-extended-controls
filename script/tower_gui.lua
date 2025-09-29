-- GUI attached to vanilla agricultural tower GUI.

local constants = require("constants")
local ExtendedTower = require("script.extended_tower")
local circuit_condition = require("script.circuit_condition")
local util = require("script.util")

local tower_gui = {}

---@param config_change ConfigurationChangedData
function tower_gui.on_configuration_changed(config_change)
    for _, player in pairs(game.players) do
        local frame = player.gui.relative[constants.gui_name] ---@type LuaGuiElement?
        if frame then
            frame.destroy()
        end
        if player.opened and player.opened.object_name == "LuaEntity" then
           tower_gui.create(player, player.opened--[[@as LuaEntity]])
        end
    end
end

---@param player LuaPlayer
---@param entity LuaEntity
---@return LuaGuiElement?
function tower_gui.create(player, entity)
    if
        not entity.valid or
        not (ExtendedTower.is_agricultural_tower(entity) or ExtendedTower.is_ghost_agricultural_tower(entity))
    then
        return
    end

    -- No GUI when entity is not connected to circuit
    for _, id in ipairs{defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green} do
        local connector = entity.get_wire_connector(id, false)
        if connector and connector.connection_count > 0 then goto circuit_connected end
    end
    do return end
    ::circuit_connected::

    local outer_frame = player.gui.relative.add{
        type = "frame",
        name = constants.gui_name,
        caption = {"agricultural-tower-extended-controls.tower-gui-frame-title"},
        direction = "vertical",
        anchor = {
            gui = defines.relative_gui_type.agriculture_tower_gui,
            position = defines.relative_gui_position.right
        },
    }
    local inner_frame = outer_frame.add{
        type = "frame",
        name = "inner-frame",
        style = "inside_shallow_frame_with_padding_and_vertical_spacing",
        direction = "vertical",
    }

    inner_frame.add{
        type = "checkbox",
        name = "read-mature-plants-checkbox",
        style = "caption_checkbox",
        caption = {"agricultural-tower-extended-controls.tower-gui-read-mature-plants-checkbox-label"},
        tooltip = {"agricultural-tower-extended-controls.tower-gui-read-mature-plants-checkbox-tooltip"},
        state = false,
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }
    local mature_signal_table = inner_frame.add{
        type = "table",
        name = "read-mature-plants-signal-table",
        style = "player_input_table",
        column_count = 2,
    }
    mature_signal_table.add{
        type = "label",
        name = "label",
        style = constants.gui_style_prefix.."input_label",
        caption = {"gui-control-behavior-modes-guis.output-signal"},
    }
    mature_signal_table.add{
        type = "choose-elem-button",
        name = "signal-chooser",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }

    inner_frame.add{
        type = "line",
        style = "inside_shallow_frame_with_padding_line",
    }

    inner_frame.add{
        type = "checkbox",
        name = "enable-harvest-checkbox",
        style = "caption_checkbox",
        caption = {"agricultural-tower-extended-controls.tower-gui-enable-harvest-checkbox-label"},
        tooltip = {"agricultural-tower-extended-controls.tower-gui-enable-harvest-checkbox-tooltip"},
        state = false,
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }

    local harvest_condition_type_flow = inner_frame.add{
        type = "flow",
        name = "enable-harvest-condition-type-flow",
        style = "player_input_horizontal_flow",
    }
    harvest_condition_type_flow.add{
        type = "radiobutton",
        name = "option-constant",
        caption = {"agricultural-tower-extended-controls.tower-gui-signal-condition-constant"},
        state = true,
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }
    harvest_condition_type_flow.add{
        type = "radiobutton",
        name = "option-signal",
        caption = {"agricultural-tower-extended-controls.tower-gui-signal-condition-signal"},
        state = false,
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }

    local harvest_condition_flow = inner_frame.add{
        type = "flow",
        name = "enable-harvest-condition-flow",
        style = "player_input_horizontal_flow",
    }
    harvest_condition_flow.add{
        type = "choose-elem-button",
        name = "first-signal-chooser",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }
    harvest_condition_flow.add{
        type = "drop-down",
        name = "comparator-dropdown",
        style = "circuit_condition_comparator_dropdown",
        items = circuit_condition.comparators,
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }
    harvest_condition_flow.add{
        type = "choose-elem-button",
        name = "second-signal-chooser",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }
    local harvest_condition_constant_textbox = harvest_condition_flow.add{
        type = "textfield",
        name = "constant-textfield",
        style = constants.gui_style_prefix.."circuit_condition_constant_textbox",
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }
    harvest_condition_constant_textbox.numeric = true
    harvest_condition_constant_textbox.allow_decimal = false
    harvest_condition_constant_textbox.allow_negative = true
    harvest_condition_constant_textbox.lose_focus_on_confirm = true

    tower_gui.refresh(player, entity)
    return outer_frame
end

---@param player LuaPlayer
function tower_gui.destroy(player)
    local frame = player.gui.relative[constants.gui_name] ---@type LuaGuiElement?
    if frame then
        frame.destroy()
    end
end

---Refresh GUI states based on the underlying data, if the player has the GUI of the specified entity open.
---If player is nil, refresh for every player who has the entity open.
---@param player LuaPlayer?
---@param entity LuaEntity
function tower_gui.refresh(player, entity)
    if not player then
        for _, each_player in pairs(game.players) do
            tower_gui.refresh(each_player, entity)
        end
        return
    end

    local frame = player.gui.relative[constants.gui_name] ---@type LuaGuiElement?
    if not frame then return end
    if not entity.valid or player.opened ~= entity then return end

    local control_settings = ExtendedTower.get_control_settings(entity) or ExtendedTower.default_control_settings

    -- Read mature plants
    frame["inner-frame"]["read-mature-plants-checkbox"].state = control_settings.read_mature_plants_enabled
    frame["inner-frame"]["read-mature-plants-signal-table"]["signal-chooser"].elem_value = control_settings.read_mature_plants_signal

    -- Enable/disable controls of read mature plants
    frame["inner-frame"]["read-mature-plants-signal-table"]["label"].enabled = control_settings.read_mature_plants_enabled
    frame["inner-frame"]["read-mature-plants-signal-table"]["signal-chooser"].enabled = control_settings.read_mature_plants_enabled

    -- Enable harvest
    frame["inner-frame"]["enable-harvest-checkbox"].state = control_settings.enable_harvest_enabled
    frame["inner-frame"]["enable-harvest-condition-flow"]["first-signal-chooser"].elem_value = control_settings.enable_harvest_condition.first_signal
    frame["inner-frame"]["enable-harvest-condition-flow"]["second-signal-chooser"].elem_value = control_settings.enable_harvest_condition.second_signal
    frame["inner-frame"]["enable-harvest-condition-flow"]["comparator-dropdown"].selected_index =
        util.find(circuit_condition.comparators, control_settings.enable_harvest_condition.comparator) or
        circuit_condition.default_comparator_index
    frame["inner-frame"]["enable-harvest-condition-flow"]["constant-textfield"].text = tostring(control_settings.enable_harvest_condition.constant or "")

    -- Enable harvest: second signal or constant, conditionally show controls of either
    if control_settings.enable_harvest_condition.constant then
        frame["inner-frame"]["enable-harvest-condition-type-flow"]["option-constant"].state = true
        frame["inner-frame"]["enable-harvest-condition-type-flow"]["option-signal"].state = false
        frame["inner-frame"]["enable-harvest-condition-flow"]["constant-textfield"].visible = true
        frame["inner-frame"]["enable-harvest-condition-flow"]["second-signal-chooser"].visible = false
    else
        frame["inner-frame"]["enable-harvest-condition-type-flow"]["option-constant"].state = false
        frame["inner-frame"]["enable-harvest-condition-type-flow"]["option-signal"].state = true
        frame["inner-frame"]["enable-harvest-condition-flow"]["constant-textfield"].visible = false
        frame["inner-frame"]["enable-harvest-condition-flow"]["second-signal-chooser"].visible = true
    end

    -- Enable/disable controls of enable harvest
    frame["inner-frame"]["enable-harvest-condition-type-flow"]["option-constant"].enabled = control_settings.enable_harvest_enabled
    frame["inner-frame"]["enable-harvest-condition-type-flow"]["option-signal"].enabled = control_settings.enable_harvest_enabled
    frame["inner-frame"]["enable-harvest-condition-flow"]["first-signal-chooser"].enabled = control_settings.enable_harvest_enabled
    frame["inner-frame"]["enable-harvest-condition-flow"]["comparator-dropdown"].enabled = control_settings.enable_harvest_enabled
    frame["inner-frame"]["enable-harvest-condition-flow"]["second-signal-chooser"].enabled = control_settings.enable_harvest_enabled
    frame["inner-frame"]["enable-harvest-condition-flow"]["constant-textfield"].enabled = control_settings.enable_harvest_enabled
end

---Called when any relavant input element has changed.
---@param player LuaPlayer
---@param element LuaGuiElement
function tower_gui.on_gui_changed(player, element)
    local frame = player.gui.relative[constants.gui_name] ---@type LuaGuiElement?
    if not frame then return end
    if not player.opened or player.opened.object_name ~= "LuaEntity" then return end
    local entity = player.opened--[[@as LuaEntity]]
    if not ExtendedTower.is_agricultural_tower(entity) and not ExtendedTower.is_ghost_agricultural_tower(entity) then return end

    -- Read most control settings from GUI input
    ---@type ExtendedTowerControlSettings
    local control_settings = {
        read_mature_plants_enabled = frame["inner-frame"]["read-mature-plants-checkbox"].state,
        read_mature_plants_signal = frame["inner-frame"]["read-mature-plants-signal-table"]["signal-chooser"].elem_value--[[@as SignalID?]],
        enable_harvest_enabled = frame["inner-frame"]["enable-harvest-checkbox"].state,
        enable_harvest_condition = {
            comparator = circuit_condition.comparators[frame["inner-frame"]["enable-harvest-condition-flow"]["comparator-dropdown"].selected_index] or circuit_condition.default_comparator,
            first_signal = frame["inner-frame"]["enable-harvest-condition-flow"]["first-signal-chooser"].elem_value--[[@as SignalID?]],
        },
    }

    -- Read enable harvest condition depending on type
    -- Type is selected by radio buttons
    if
        frame["inner-frame"]["enable-harvest-condition-type-flow"]["option-constant"].state and
        not (
            frame["inner-frame"]["enable-harvest-condition-type-flow"]["option-signal"].state and -- if both are true
            element == frame["inner-frame"]["enable-harvest-condition-type-flow"]["option-signal"] -- see which's just been clicked
        )
    then
        local text = frame["inner-frame"]["enable-harvest-condition-flow"]["constant-textfield"].text
        -- Allow -0 so the negative sign is preserved when typed first.
        control_settings.enable_harvest_condition.constant = tonumber(text) or text:sub(1, 1) == "-" and -0 or 0
    else
        control_settings.enable_harvest_condition.second_signal = frame["inner-frame"]["enable-harvest-condition-flow"]["second-signal-chooser"].elem_value--[[@as SignalID?]]
    end

    -- Reject meta signals
    if control_settings.read_mature_plants_signal and util.is_meta_signal(control_settings.read_mature_plants_signal) then
        control_settings.read_mature_plants_signal = nil
    end
    circuit_condition.reject_meta_signals(control_settings.enable_harvest_condition)

    -- Save to entity
    ExtendedTower.set_control_settings(entity, control_settings)

    tower_gui.refresh(nil, entity)
end

return tower_gui