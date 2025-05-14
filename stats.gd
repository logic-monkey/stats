extends Node
class_name Stats

@export var stat_resource: StatsResource
static var default_resource: StatsResource = load("res://default.stats.tres")

var base_stats := {}
var modifiers := {}  # { stat_name: { modifier_name: modifier_dict } }

func _ready():
	# Initialize base_stats with [0, value] where 0 is the count of modifiers
	if stat_resource:
		for key in stat_resource.stats.keys():
			base_stats[key] = [0, stat_resource.stats[key]]
	else:
		push_warning("Stats: No stat resource provided, relying on default fallback.")

func get_base_stat(stat: String) -> Variant:
	if base_stats.has(stat):
		return base_stats[stat][1]
	elif default_resource and default_resource.stats.has(stat):
		push_warning("%s: Stat '%s' not found in local stats, using default." % [owner.name, stat])
		var value = default_resource.stats[stat]
		base_stats[stat] = [0, value]
		return value
	else:
		push_warning("%s: Stat '%s' not found in local or default stats." % [owner.name, stat])
		return null

func get_stat(stat: String) -> Variant:
	if not base_stats.has(stat):
		get_base_stat(stat)  # this may load from default

	if not base_stats.has(stat):
		return null  # still not found

	var modifier_count = base_stats[stat][0]
	var value = base_stats[stat][1]

	if modifier_count == 0:
		return value

	var mods = modifiers.get(stat, {})
	for mod in mods.values():
		if mod.type == "add":
			value += mod.value
	for mod in mods.values():
		if mod.type == "mul":
			value *= mod.value
	return value

func add_modifier(stat: String, name: String, mod: Dictionary) -> void:
	if not base_stats.has(stat):
		get_base_stat(stat)  # ensure the stat is loaded or initialized
		if not base_stats.has(stat):
			push_warning("Trying to add modifier to unknown stat '%s'." % stat)
			return

	if not modifiers.has(stat):
		modifiers[stat] = {}
		base_stats[stat][0] = 0

	if not modifiers[stat].has(name):
		base_stats[stat][0] += 1

	modifiers[stat][name] = mod

func remove_modifier(stat: String, name: String) -> void:
	if modifiers.has(stat) and modifiers[stat].has(name):
		modifiers[stat].erase(name)
		base_stats[stat][0] = max(0, base_stats[stat][0] - 1)
		if modifiers[stat].is_empty():
			modifiers.erase(stat)

func has_stat(stat: String) -> bool:
	return base_stats.has(stat) or (default_resource and default_resource.stats.has(stat))

func clear_modifiers(stat: String) -> void:
	if modifiers.has(stat):
		var removed = modifiers[stat].size()
		modifiers.erase(stat)
		if base_stats.has(stat):
			base_stats[stat][0] = 0

func clear_all_modifiers() -> void:
	for stat in modifiers.keys():
		if base_stats.has(stat):
			base_stats[stat][0] = 0
	modifiers.clear()
