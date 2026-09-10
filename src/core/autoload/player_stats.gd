extends Node

signal stats_changed()

# Oyuncu seviyesi
var level: int = 1

# Base stat konfigürasyonu
# Her stat için: base = level 1 değeri, per_level = her level başına artış
var base_stat_config: Dictionary = {
	StatBonus.StatType.ATTACK:         { "base": 10.0,  "per_level": 5.0 },
	StatBonus.StatType.ATTACK_SPEED:   { "base": 1.0,   "per_level": 0.05 },
	StatBonus.StatType.MAGIC_POWER:    { "base": 0.0,   "per_level": 3.0 },
	StatBonus.StatType.ARMOR:          { "base": 5.0,   "per_level": 2.0 },
	StatBonus.StatType.HEALTH:         { "base": 100.0, "per_level": 20.0 },
	StatBonus.StatType.MANA:           { "base": 50.0,  "per_level": 10.0 },
	StatBonus.StatType.CRIT_CHANCE:    { "base": 5.0,   "per_level": 0.2 },
	StatBonus.StatType.CRIT_DAMAGE:    { "base": 50.0,  "per_level": 2.0 },
	StatBonus.StatType.MOVEMENT_SPEED: { "base": 100.0, "per_level": 0.5 },
	StatBonus.StatType.LIFE_STEAL:     { "base": 0.0,   "per_level": 0.1 },
	StatBonus.StatType.HEALTH_REGEN:   { "base": 1.0,   "per_level": 0.5 },
	StatBonus.StatType.MANA_REGEN:     { "base": 1.0,   "per_level": 0.5 },
}

# Kuşanılmış tüm eşyalar (aynı eşyadan iki tane olabilir - iki yüzük gibi)
var equipped_items: Array[ItemData] = []

func _ready() -> void:
	EventBus.equipment_equipped.connect(_on_equipment_equipped)
	EventBus.equipment_unequipped.connect(_on_equipment_unequipped)

# --- Level ---

func set_level(new_level: int) -> void:
	level = max(1, new_level)
	stats_changed.emit()

func get_level() -> int:
	return level

# --- Base Stat (equipment bonus'suz) ---

func get_base_stat(stat_type: StatBonus.StatType) -> float:
	if not base_stat_config.has(stat_type):
		return 0.0
	
	var config = base_stat_config[stat_type]
	return config["base"] + config["per_level"] * (level - 1)

# --- Toplam Stat (base + equipment bonus) ---

func get_stat(stat_type: StatBonus.StatType) -> float:
	var base_value = get_base_stat(stat_type)
	var flat_bonus = 0.0
	var percent_bonus = 0.0
	
	for item in equipped_items:
		if not item or not item.bonuses:
			continue
		for bonus in item.bonuses:
			if not bonus or bonus.stat_type != stat_type:
				continue
			if bonus.is_percentage:
				percent_bonus += bonus.value
			else:
				flat_bonus += bonus.value
	
	# Formül: (base + flat) * (1 + percent/100)
	return (base_value + flat_bonus) * (1.0 + percent_bonus / 100.0)

# --- Equipment ---

func add_equipment_bonuses(item: ItemData) -> void:
	if item and item not in equipped_items:
		equipped_items.append(item)
		stats_changed.emit()

func remove_equipment_bonuses(item: ItemData) -> void:
	if item and item in equipped_items:
		equipped_items.erase(item)
		stats_changed.emit()

# --- EventBus Callbacks ---

func _on_equipment_equipped(_slot_type: int, item_data: ItemData) -> void:
	add_equipment_bonuses(item_data)

func _on_equipment_unequipped(_slot_type: int, item_data: ItemData) -> void:
	remove_equipment_bonuses(item_data)

# --- Debug ---

func print_all_stats() -> void:
	print("=== PlayerStats (Level %d) ===" % level)
	var keys = StatBonus.StatType.keys()
	for stat_type in StatBonus.StatType.values():
		var stat_name = keys[stat_type]
		var base_val = get_base_stat(stat_type)
		var total_val = get_stat(stat_type)
		if is_equal_approx(base_val, total_val):
			print("  %s: %.2f" % [stat_name, total_val])
		else:
			print("  %s: %.2f (base: %.2f)" % [stat_name, total_val, base_val])