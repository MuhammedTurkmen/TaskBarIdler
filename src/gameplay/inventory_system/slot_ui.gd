# slot_ui.gd
class_name SlotUI
extends PanelContainer

@onready var icon_rect: TextureRect = $MarginContainer/TextureRect
@onready var quantity_label: Label = $MarginContainer/TextureRect/Label

var slot_data: SlotData

func _ready() -> void:
	add_to_group("inventory_slots")
	add_to_group("clickable_area")
	# Quantity label ekle (eğer yoksa)
	if not quantity_label:
		quantity_label = Label.new()
		quantity_label.name = "Label"
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		quantity_label.add_theme_font_size_override("font_size", 10)
		icon_rect.add_child(quantity_label)
		quantity_label.set_anchors_preset(Control.PRESET_FULL_RECT)

func update_slot(data: SlotData) -> void:
	slot_data = data
	if slot_data and slot_data.item_data:
		icon_rect.texture = slot_data.item_data.icon
		icon_rect.visible = true
		
		if slot_data.quantity > 1:
			quantity_label.text = str(slot_data.quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
	else:
		clear_slot()

func clear_slot() -> void:
	slot_data = null
	if icon_rect:
		icon_rect.texture = null
		icon_rect.visible = false
	if quantity_label:
		quantity_label.visible = false

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not slot_data or not slot_data.item_data:
		return null
	
	# Global drag manager'ı kullan
	var drag_manager = get_node_or_null("/root/DragManager")
	if drag_manager:
		drag_manager.start_drag(self, slot_data.item_data, slot_data.quantity)
	
	EventBus.item_drag_started.emit(self, slot_data.item_data, slot_data.quantity)
	
	return {
		"origin_slot": self,
		"slot_data": slot_data,
		"item_data": slot_data.item_data,
		"quantity": slot_data.quantity
	}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	
	# Eğer origin_slot yoksa veya item_data yoksa kabul etme
	if not data.has("origin_slot") or not data.has("item_data"):
		return false
	
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return
	
	var origin_slot = data.get("origin_slot")
	var incoming_item_data = data.get("item_data")
	var incoming_quantity = data.get("quantity", 1)
	
	if not origin_slot or not incoming_item_data:
		return
	
	# Equipment slot'tan normal slota drop kontrolü
	if origin_slot is EquipmentSlotUI and slot_data and slot_data.item_data:
		if not origin_slot.is_item_allowed(slot_data.item_data):
			return
	
	# Eşyaları taşı
	var temp_slot_data = slot_data
	
	# Origin slot'tan eşyayı al
	if origin_slot.slot_data:
		update_slot(origin_slot.slot_data)
		origin_slot.clear_slot()
	else:
		clear_slot()
	
	# Hedef slota eşyayı yerleştir
	if temp_slot_data:
		origin_slot.update_slot(temp_slot_data)
	
	EventBus.item_dropped.emit(origin_slot, self, incoming_item_data, incoming_quantity)
	
	# Drag manager'ı temizle
	var drag_manager = get_node_or_null("/root/DragManager")
	if drag_manager:
		drag_manager.end_drag()
