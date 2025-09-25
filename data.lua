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
            "not-selectable-in-game",
        },
        selectable_in_game = false,
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