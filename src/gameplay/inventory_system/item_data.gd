class_name ItemData
extends Resource

enum EquipmentType {
	NONE = 0,
	HELMET = 1,
	CHESTPLATE = 2,
	LEGGINS = 4,
	FOOT = 8,
	HAND = 16,
	LEFT_WEAPON = 32,
	RIGHT_WEAPON = 64,
	RING = 128,
	CLOAK = 256,
	GEM = 512,
	CROWN = 1024,
	QUIVER = 2048,
	NECKLACE = 5096
}

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var is_stackable: bool = false
@export var max_stack_size: int = 99

@export_flags("Helmet", "Chestplate", "Leggins", "Foot", "Hand", "Left Weapon", "Right Weapon", "Ring", "Cloak", "Gem", "Crown", "Quiver", "Necklace") var equipment_type: int = 0
