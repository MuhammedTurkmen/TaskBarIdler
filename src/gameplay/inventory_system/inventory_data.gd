class_name InventoryData
extends Resource

signal inventory_updated(inventory_data: InventoryData)

@export var slots: Array[SlotData] = []

# Envantere eşya ekleme fonksiyonu
func add_item(item: ItemData, count: int = 1) -> bool:
	# 1. İstiflenebilir eşyalar için mevcut slotları kontrol et
	if item.is_stackable:
		for slot in slots:
			if slot and slot.item_data == item and slot.quantity < item.max_stack_size:
				var available_space = item.max_stack_size - slot.quantity
				if count <= available_space:
					slot.quantity += count
					inventory_updated.emit(self)
					return true
				else:
					slot.quantity = item.max_stack_size
					count -= available_space

	# 2. Boş bir slota yerleştir
	for i in range(slots.size()):
		if slots[i] == null or slots[i].item_data == null:
			var new_slot = SlotData.new()
			new_slot.item_data = item
			new_slot.quantity = count
			slots[i] = new_slot
			inventory_updated.emit(self)
			return true

	return false # Envanter dolu
