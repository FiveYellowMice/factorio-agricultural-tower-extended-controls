local constants = require("constants")

data:extend({
    {
        type = "bool-setting",
        name = constants.setting_debug,
        setting_type = "startup",
        default_value = false,
        order = "z"
    }
})