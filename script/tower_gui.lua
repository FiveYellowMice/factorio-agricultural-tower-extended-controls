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
    if not entity.valid or not ExtendedTower.is_agricultural_tower(entity) then return end

    -- No GUI when entity is not connected to circuit
    local circuit_connected = entity.get_circuit_network(defines.wire_connector_id.circuit_red) or entity.get_circuit_network(defines.wire_connector_id.circuit_green)
    if not circuit_connected then return end

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
    local tower = ExtendedTower.get_or_create(entity)

    frame["inner-frame"]["read-mature-plants-checkbox"].state = tower.read_mature_plants_enabled
    frame["inner-frame"]["read-mature-plants-signal-table"]["signal-chooser"].elem_value = tower.read_mature_plants_signal

    frame["inner-frame"]["read-mature-plants-signal-table"]["label"].enabled = tower.read_mature_plants_enabled
    frame["inner-frame"]["read-mature-plants-signal-table"]["signal-chooser"].enabled = tower.read_mature_plants_enabled
end

---Called when any relavant input element has changed.
---@param player LuaPlayer
function tower_gui.on_gui_changed(player)
    local frame = player.gui.relative[constants.gui_name] ---@type LuaGuiElement?
    if not frame then return end
    if not player.opened or player.opened.object_name ~= "LuaEntity" then return end
    local entity = player.opened--[[@as LuaEntity]]
    if not ExtendedTower.is_agricultural_tower(entity) then return end
    local tower = ExtendedTower.get_or_create(entity)

    -- Save input values to storage
    tower.read_mature_plants_enabled = frame["inner-frame"]["read-mature-plants-checkbox"].state
    tower.read_mature_plants_signal = frame["inner-frame"]["read-mature-plants-signal-table"]["signal-chooser"].elem_value--[[@as SignalID]]

    -- Reject meta signals
    local meta_signals_names = util.list_to_map{"signal-everything", "signal-anything", "signal-each"}
    if tower.read_mature_plants_signal and tower.read_mature_plants_signal.type == "virtual" and meta_signals_names[tower.read_mature_plants_signal.name] then
        tower.read_mature_plants_signal = nil
    end

    tower_gui.refresh(nil, entity)
    tower:on_control_settings_updated()
end

return tower_gui