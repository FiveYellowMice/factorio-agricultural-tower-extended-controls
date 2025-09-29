local constants = require("constants")
local util = require("util")

---@type data.EntityWithOwnerPrototype
local hidden_entity_base = {
    type = "",
    name = "",
    hidden = true,
    flags = {
        "not-on-map",
        "not-deconstructable",
        "not-blueprintable",
        "hide-alt-info",
        "not-flammable",
        "not-upgradable",
    },
    selectable_in_game = false,
    allow_copy_paste = false,
    collision_mask = {
        layers = {},
        not_colliding_with_itself = true,
    },
    tile_width = 1,
    tile_height = 1,
    draw_copper_wires = false,
    draw_circuit_wires = false,
}


data:extend{
    util.merge{hidden_entity_base, {
        type = "constant-combinator",
        name = constants.entity_output_combinator,

        activity_led_light_offsets = {{0, 0}, {0, 0}, {0, 0}, {0, 0}},
        circuit_wire_connection_points = {{wire = {}, shadow = {}}, {wire = {}, shadow = {}}, {wire = {}, shadow = {}}, {wire = {}, shadow = {}}},
    }--[[@as data.ConstantCombinatorPrototype]]},

    util.merge{hidden_entity_base, {
        type = "inserter",
        name = constants.entity_harvest_disable_inserter,

        extension_speed = 1,
        rotation_speed = 1,
        insert_position = {0, 0},
        pickup_position = {0, 0},
        energy_source = {type = "void"},
        uses_inserter_stack_size_bonus = false,
        draw_held_item = false,
        draw_inserter_arrow = false,
    }--[[@as data.InserterPrototype]]},

    util.merge{hidden_entity_base, {
        type = "infinity-container",
        name = constants.entity_harvest_disable_infinity_container,

        erase_contents_when_mined = true,
        gui_mode = "none",
        inventory_size = 2,
        inventory_type = "normal",
    }--[[@as data.InfinityContainerPrototype]]},

    util.merge{hidden_entity_base, {
        type = "proxy-container",
        name = constants.entity_harvest_disable_proxy_container,
    }--[[@as data.ProxyContainerPrototype]]},
}


local gui_style = data.raw["gui-style"]["default"]

gui_style[constants.gui_style_prefix.."input_label"] = {
    type = "label_style",
    horizontally_stretchable = "on",
}

gui_style[constants.gui_style_prefix.."circuit_condition_constant_textbox"] = {
    type = "textbox_style",
    width = 40,
    height = 40,

    -- Format text inside
    top_padding = 7,
    bottom_padding = 7,
    left_padding = 2,
    right_padding = 2,
    horizontal_align = "center",
    vertical_align = "center",
    font = "default-game",
    font_color = {1, 1, 1},

    -- Make it look like a slot button when not edited
    default_background = util.table.deepcopy(gui_style["slot_button_in_shallow_frame"].default_graphical_set),
    game_controller_hovered_background = util.table.deepcopy(gui_style["slot_button_in_shallow_frame"].hovered_graphical_set),
    disabled_background = util.table.deepcopy(gui_style["slot_button_in_shallow_frame"].disabled_badge_graphical_set),
}


if settings.startup['debug'].value then
    -- Make Gleba plants grow in 5 seconds
    data.raw["plant"]["yumako-tree"].growth_ticks = 5 * 60
    data.raw["plant"]["jellystem"].growth_ticks = 5 * 60
end