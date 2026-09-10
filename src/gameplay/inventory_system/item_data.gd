class_name ItemData
extends Resource

enum EquipmentType {
	NONE,
	HELMET,
	CHESTPLATE,
	LEGGINS,
	FOOT,
	HAND,
	WEAPON,
	RING,
	CLOAK,
	GEM,
	CROWN,
	QUIVER,
	NECKLACE
}

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var is_stackable: bool = false
@export var max_stack_size: int = 99

@export var equipment_type: EquipmentType = EquipmentType.NONE
@export var bonuses: Array[StatBonus] = []

# Bonus'ları okunabilir formatta döndürür (UI için)
func get_bonus_description() -> String:
	var lines: Array[String] = []
	for bonus in bonuses:
		if not bonus:
			continue
		var stat_name = _get_stat_display_name(bonus.stat_type)
		var value_text = ""
		if bonus.is_percentage:
			value_text = "+%d%%" % int(bonus.value)
		else:
			value_text = "+%d" % int(bonus.value)
		lines.append("%s %s" % [value_text, stat_name])
	return "\n".join(lines)

func _get_stat_display_name(stat_type: StatBonus.StatType) -> String:
	match stat_type:
		StatBonus.StatType.ATTACK: return "Saldırı"
		StatBonus.StatType.ATTACK_SPEED: return "Saldırı Hızı"
		StatBonus.StatType.MAGIC_POWER: return "Büyü Gücü"
		StatBonus.StatType.ARMOR: return "Zırh"
		StatBonus.StatType.HEALTH: return "Can"
		StatBonus.StatType.MANA: return "Mana"
		StatBonus.StatType.CRIT_CHANCE: return "Kritik Şansı"
		StatBonus.StatType.CRIT_DAMAGE: return "Kritik Hasarı"
		StatBonus.StatType.MOVEMENT_SPEED: return "Hareket Hızı"
		StatBonus.StatType.LIFE_STEAL: return "Can Çalma"
		StatBonus.StatType.HEALTH_REGEN: return "Can Yenilenmesi"
		StatBonus.StatType.MANA_REGEN: return "Mana Yenilenmesi"
	return ""