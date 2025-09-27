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


data.raw["gui-style"]["default"][constants.gui_style_prefix.."input_label"] = {
    type = "label_style",
    horizontally_stretchable = "on",
}


if settings.startup['debug'].value then
    -- Make Gleba plants grow in 5 seconds
    data.raw["plant"]["yumako-tree"].growth_ticks = 5 * 60
    data.raw["plant"]["jellystem"].growth_ticks = 5 * 60
end