# Agricultural Tower Extended Controls

[Mod Portal](https://mods.factorio.com/mod/agricultural-tower-extended-controls) | [GitHub](https://github.com/FiveYellowMice/factorio-agricultural-tower-extended-controls)

This Factorio mod adds more circuit controls for agricultural towers, namely:

* Reads the number of fully-grown plants within the range of this agricultural tower.
* Use a circuit condition to enable/disable harvesting of plants while still allowing planting.

Both functionalities are fairly optimized, performance impact should be minimal.

The control settings of an angricultural tower provided by this mod are preserved accross copy-pasting, and in blueprints.

## Usage

Connect a circuit wire to an agricultural tower, and open its GUI.

# TODO

* Do not require space-age mod
* Remove blocked slot item when tower is destroyed
* Ensure aux entities don't leak when area cloned
* Sweep aux entities, rebuild index on configuration changed
* Handle teleport
* Fix control settings not saved in redo on entity marked for desconstruction
* Remote interface: get/set control settings
