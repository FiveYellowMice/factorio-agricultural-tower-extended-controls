# Agricultural Tower Extended Controls

[Mod Portal](https://mods.factorio.com/mod/agricultural-tower-extended-controls) | [GitHub](https://github.com/FiveYellowMice/factorio-agricultural-tower-extended-controls)

This Factorio mod adds more circuit controls for agricultural towers, namely:

* Reads the number of fully-grown plants within the range of this agricultural tower.
* Use a circuit condition to enable/disable harvesting of plants while still allowing planting.

## Usage

Connect a circuit wire to an agricultural tower, and open its GUI.

## Technical Characteristics

* Computations for both features are run only when necessary. Minimal per-tick logic.
* Does not scan the world for every agricultural tower, so building more agricultural towers does not make it slower.
* Circuit control settings can be configured for entity ghosts before they are built.
* Supports copy-pasting, blueprints, undoing.
* Handles other mods teleporting/cloning the agricultural tower.
* Handles when multiple players are configuring the same agricultural tower.

# Todo

* Preserve settings for quick-replacements to modded towers.
* Sweep aux entities, rebuild index on configuration changed
* Fix control settings not saved in redo on entity marked for desconstruction
* Add remote interface: get/set control settings
