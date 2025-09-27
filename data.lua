local constants = require("constants")

data:extend{
    {
        type = "constant-combinator",
        name = constants.output_combinator_name,
        hidden = true,
        flags = {
            "placeable-off-grid",
            "not-on-map",
            "not-deconstructable",
            "not-blueprintable",
            "hide-alt-info",
            "not-flammable",
        },
        selectable_in_game = false,
        allow_copy_paste = false,
        collision_mask = {
            layers = {},
            not_colliding_with_itself = true,
        },
        draw_copper_wires = false,
        draw_circuit_wires = false,

        activity_led_light_offsets = {{0, 0}, {0, 0}, {0, 0}, {0, 0}},
        circuit_wire_connection_points = {{wire = {}, shadow = {}}, {wire = {}, shadow = {}}, {wire = {}, shadow = {}}, {wire = {}, shadow = {}}},
    },
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