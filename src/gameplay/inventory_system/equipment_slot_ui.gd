# equipment_slot_ui.gd
class_name EquipmentSlotUI
extends PanelContainer

@onready var icon_rect: TextureRect = $TextureRect

@export_flags("Helmet", "Chestplate", "Leggins", "Foot", "Hand", "Left Weapon", "Right Weapon", "Ring", "Cloak", "Gem", "Crown", "Quiver", "Necklace") var allowed_equipment_types: int = 0

var slot_data: SlotData

func _ready() -> void:
	add_to_group("equipment_slots")

func update_slot(data: SlotData) -> void:
	if slot_data and slot_data.item_data:
		EventBus.equipment_unequipped.emit(allowed_equipment_types, slot_data.item_data)
        
	slot_data = data
    
    # Yeni eşyayı giy
	if slot_data and slot_data.item_data:
		# Equipment slotlarında quantity her zaman 1 olmalı
		if slot_data.quantity != 1:
			slot_data.quantity = 1
            
		icon_rect.texture = slot_data.item_data.icon
		icon_rect.visible = true
			
		EventBus.equipment_equipped.emit(allowed_equipment_types, slot_data.item_data)
	else:
		clear_slot()

func clear_slot() -> void:
	if slot_data and slot_data.item_data:
		EventBus.equipment_unequipped.emit(allowed_equipment_types, slot_data.item_data)
        
	slot_data = null
	if icon_rect:
		icon_rect.texture = null
		icon_rect.visible = false

func is_item_allowed(item: ItemData) -> bool:
	if not item or allowed_equipment_types == 0:
		return false
    # Equipment slotlarına sadece istiflenemeyen eşyalar yerleştirilebilir
	if item.is_stackable:
		return false
	return (item.equipment_type & allowed_equipment_types) != 0

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not slot_data or not slot_data.item_data:
		return null

	var drag_manager = get_node_or_null("/root/DragManager")
	if drag_manager:
		drag_manager.start_drag(self, slot_data.item_data, 1)

	EventBus.item_drag_started.emit(self, slot_data.item_data, 1)

	return {
		"origin_slot": self,
		"slot_data": slot_data,
		"item_data": slot_data.item_data,
		"quantity": 1
	}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false

	if not data.has("item_data"):
		return false

	var incoming_item_data = data["item_data"]
	return is_item_allowed(incoming_item_data)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return

	var origin_slot = data.get("origin_slot")
	var incoming_slot_data = data.get("slot_data")

	if not origin_slot or not incoming_slot_data:
		return

	# Eğer origin slot equipment slot ise ve hedef eşya uygun değilse
	if origin_slot is EquipmentSlotUI and slot_data and slot_data.item_data:
		if not origin_slot.is_item_allowed(slot_data.item_data):
			return

	var temp_slot_data = slot_data
	update_slot(incoming_slot_data)
	origin_slot.update_slot(temp_slot_data)

	EventBus.item_dropped.emit(origin_slot, self, incoming_slot_data.item_data, 1)

	var drag_manager = get_node_or_null("/root/DragManager")
	if drag_manager:
		drag_manager.end_drag()