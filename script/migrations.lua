-- Migrations triggered on_configuration_changed. We roll our own migration mechanism because
-- Factorio's built-in migrations run even when this mod is newly added, but we want migrations
-- to only run when the mod is upgraded.

local migrations = {}

---@param config_change ConfigurationChangedData
function migrations.on_configuration_changed(config_change)
    local this_mod_change = config_change.mod_changes[script.mod_name]
    if this_mod_change and this_mod_change.old_version then
        for version, func in pairs(migrations.this_mod_migrations) do
            if helpers.compare_versions(this_mod_change.old_version, version) < 0 then
                log("Migrations run for version "..version)
                func()
            end
        end
    end
end

---Migrations applicable to this mod.
---Ensure this is ordered in ascending versions.
---@type table<string, function>
migrations.this_mod_migrations = {
    ["0.1.3"] = function()
        for _, tower in pairs(storage.towers) do
            -- Recreate harvest disable inserters and infinity container, because their creation behaviour have changed.
            if tower.harvest_disable_inserter_1 then tower.harvest_disable_inserter_1:destroy() end
            if tower.harvest_disable_inserter_2 then tower.harvest_disable_inserter_2:destroy() end
            if tower.harvest_disable_infinity_container then tower.harvest_disable_infinity_container:destroy() end
            tower:on_control_settings_or_status_updated()
        end
    end,
}

return migrations