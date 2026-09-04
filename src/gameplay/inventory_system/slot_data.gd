class_name SlotData
extends Resource

@export var item_data: ItemData
@export_range(1, 99) var quantity: int = 1: set = set_quantity

# Adet değiştiğinde sınırlamaları kontrol eder
func set_quantity(value: int) -> void:
	quantity = value
	if item_data and not item_data.is_stackable:
		quantity = 1
	elif item_data and quantity > item_data.max_stack_size:
		quantity = item_data.max_stack_size
