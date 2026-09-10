class_name StatBonus
extends Resource

enum StatType {
	ATTACK,
	ATTACK_SPEED,
	MAGIC_POWER,
	ARMOR,
	HEALTH,
	MANA,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	MOVEMENT_SPEED,
	LIFE_STEAL,
	HEALTH_REGEN,
	MANA_REGEN
}

@export var stat_type: StatType = StatType.ATTACK
@export var value: float = 0.0
@export var is_percentage: bool = false