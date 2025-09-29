-- GUI attached to vanilla agricultural tower GUI.

local constants = require("constants")
local ExtendedTower = require("script.extended_tower")
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
        name = "harvest-condition-type-flow",
        style = "player_input_horizontal_flow",
    }
    harvest_condition_type_flow.add{
        type = "radiobutton",
        name = "harvest-condition-constant",
        caption = {"agricultural-tower-extended-controls.tower-gui-signal-condition-constant"},
        state = true,
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }
    harvest_condition_type_flow.add{
        type = "radiobutton",
        name = "harvest-condition-signal",
        caption = {"agricultural-tower-extended-controls.tower-gui-signal-condition-signal"},
        state = false,
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }
    
    local enable_harvest_condition_flow = inner_frame.add{
        type = "flow",
        name = "enable-harvest-condition-flow",
        style = "player_input_horizontal_flow",
    }
    enable_harvest_condition_flow.add{
        type = "choose-elem-button",
        name = "first-signal-chooser",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }
    enable_harvest_condition_flow.add{
        type = "drop-down",
        name = "comparator-dropdown",
        style = "circuit_condition_comparator_dropdown",
        items = constants.comparator_names,
        selected_index = 2,
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }
    enable_harvest_condition_flow.add{
        type = "textfield",
        name = "constant-textfield",
        style = constants.gui_style_prefix.."circuit_condition_constant_textbox",
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }
    enable_harvest_condition_flow["constant-textfield"].numeric = true
    enable_harvest_condition_flow["constant-textfield"].allow_decimal = false
    enable_harvest_condition_flow["constant-textfield"].allow_negative = true
    enable_harvest_condition_flow["constant-textfield"].lose_focus_on_confirm = true
    enable_harvest_condition_flow.add{
        type = "choose-elem-button",
        name = "second-signal-chooser",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        tags = {
            [constants.gui_changed_event_enabled] = true,
        },
    }

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

    frame["inner-frame"]["read-mature-plants-checkbox"].state = control_settings.read_mature_plants_enabled
    frame["inner-frame"]["read-mature-plants-signal-table"]["signal-chooser"].elem_value = control_settings.read_mature_plants_signal

    frame["inner-frame"]["read-mature-plants-signal-table"]["label"].enabled = control_settings.read_mature_plants_enabled
    frame["inner-frame"]["read-mature-plants-signal-table"]["signal-chooser"].enabled = control_settings.read_mature_plants_enabled

    frame["inner-frame"]["enable-harvest-checkbox"].state = control_settings.enable_harvest
    frame["inner-frame"]["enable-harvest-condition-flow"]["first-signal-chooser"].elem_value = control_settings.harvest_condition_signal_1
    frame["inner-frame"]["enable-harvest-condition-flow"]["second-signal-chooser"].elem_value = control_settings.harvest_condition_signal_2
    frame["inner-frame"]["enable-harvest-condition-flow"]["comparator-dropdown"].selected_index = control_settings.harvest_condition_comparator_index
    frame["inner-frame"]["enable-harvest-condition-flow"]["constant-textfield"].text = control_settings.harvest_condition_constant
    if control_settings.harvest_condition_type == 'constant' then
        frame["inner-frame"]["harvest-condition-type-flow"]["harvest-condition-constant"].state = true
        frame["inner-frame"]["harvest-condition-type-flow"]["harvest-condition-signal"].state = false
        frame["inner-frame"]["enable-harvest-condition-flow"]["constant-textfield"].visible = true
        frame["inner-frame"]["enable-harvest-condition-flow"]["second-signal-chooser"].visible = false
    else
        frame["inner-frame"]["harvest-condition-type-flow"]["harvest-condition-constant"].state = false
        frame["inner-frame"]["harvest-condition-type-flow"]["harvest-condition-signal"].state = true
        frame["inner-frame"]["enable-harvest-condition-flow"]["constant-textfield"].visible = false
        frame["inner-frame"]["enable-harvest-condition-flow"]["second-signal-chooser"].visible = true
    end
    
    frame["inner-frame"]["harvest-condition-type-flow"]["harvest-condition-constant"].enabled = control_settings.enable_harvest
    frame["inner-frame"]["harvest-condition-type-flow"]["harvest-condition-signal"].enabled = control_settings.enable_harvest
    frame["inner-frame"]["enable-harvest-condition-flow"]["first-signal-chooser"].enabled = control_settings.enable_harvest
    frame["inner-frame"]["enable-harvest-condition-flow"]["comparator-dropdown"].enabled = control_settings.enable_harvest
    frame["inner-frame"]["enable-harvest-condition-flow"]["second-signal-chooser"].enabled = control_settings.enable_harvest
    frame["inner-frame"]["enable-harvest-condition-flow"]["constant-textfield"].enabled = control_settings.enable_harvest
end

---Called when any relavant input element has changed.
---@param player LuaPlayer
---@param clicked_element LuaGuiElement
function tower_gui.on_gui_changed(player, clicked_element)
    local frame = player.gui.relative[constants.gui_name] ---@type LuaGuiElement?
    if not frame then return end
    if not player.opened or player.opened.object_name ~= "LuaEntity" then return end
    local entity = player.opened--[[@as LuaEntity]]
    if not ExtendedTower.is_agricultural_tower(entity) and not ExtendedTower.is_ghost_agricultural_tower(entity) then return end
    
    -- Update radio button state
    if clicked_element.name == "harvest-condition-constant" then
        frame["inner-frame"]["harvest-condition-type-flow"]["harvest-condition-constant"].state = true
        frame["inner-frame"]["harvest-condition-type-flow"]["harvest-condition-signal"].state = false
    elseif clicked_element.name == "harvest-condition-signal" then
        frame["inner-frame"]["harvest-condition-type-flow"]["harvest-condition-constant"].state = false
        frame["inner-frame"]["harvest-condition-type-flow"]["harvest-condition-signal"].state = true
    end
    
    local harvest_condition_type = "constant"
    if frame["inner-frame"]["harvest-condition-type-flow"]["harvest-condition-signal"].state then
        harvest_condition_type = "signal"
    end

    -- Read control settings from GUI input
    ---@type ExtendedTowerControlSettings
    local control_settings = {
        read_mature_plants_enabled = frame["inner-frame"]["read-mature-plants-checkbox"].state,
        read_mature_plants_signal = frame["inner-frame"]["read-mature-plants-signal-table"]["signal-chooser"].elem_value--[[@as SignalID]],
        enable_harvest = frame["inner-frame"]["enable-harvest-checkbox"].state,
        harvest_condition_type = harvest_condition_type,
        harvest_condition_signal_1 = frame["inner-frame"]["enable-harvest-condition-flow"]["first-signal-chooser"].elem_value--[[@as SignalID]],
        harvest_condition_comparator_index = frame["inner-frame"]["enable-harvest-condition-flow"]["comparator-dropdown"].selected_index,
        harvest_condition_constant = frame["inner-frame"]["enable-harvest-condition-flow"]["constant-textfield"].text,
        harvest_condition_signal_2 = frame["inner-frame"]["enable-harvest-condition-flow"]["second-signal-chooser"].elem_value--[[@as SignalID]],
    }

    -- Reject meta signals
    local meta_signals_names = util.list_to_map{"signal-everything", "signal-anything", "signal-each"}
    if
        control_settings.read_mature_plants_signal and
        control_settings.read_mature_plants_signal.type == "virtual" and
        meta_signals_names[control_settings.read_mature_plants_signal.name]
    then
        control_settings.read_mature_plants_signal = nil
    end

    -- Save to entity
    ExtendedTower.set_control_settings(entity, control_settings)

    tower_gui.refresh(nil, entity)
end

return tower_gui