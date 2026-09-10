# slot_ui.gd
class_name SlotUI
extends PanelContainer

@onready var icon_rect: TextureRect = $MarginContainer/TextureRect
@onready var quantity_label: Label = $MarginContainer/TextureRect/Label

var slot_data: SlotData

func _ready() -> void:
	add_to_group("inventory_slots")
	add_to_group("clickable_area")
	if not quantity_label:
		quantity_label = Label.new()
		quantity_label.name = "Label"
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		quantity_label.add_theme_font_size_override("font_size", 10)
		icon_rect.add_child(quantity_label)
		quantity_label.set_anchors_preset(Control.PRESET_FULL_RECT)

# Drag bittiğinde (başarılı veya başarısız) DragManager'ı temizle
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		var drag_manager = get_node_or_null("/root/DragManager")
		if drag_manager and drag_manager.is_dragging:
			drag_manager.end_drag()

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
	
	if not data.has("origin_slot") or not data.has("item_data"):
		return false
	
	var origin_slot = data["origin_slot"]
	
	# Kendine drop etmeyi engelle
	if origin_slot == self:
		return false
	
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return
	
	var origin_slot = data.get("origin_slot")
	var incoming_slot_data = data.get("slot_data")
	
	if not origin_slot or not incoming_slot_data:
		return
	
	# YENİ MANTIK: Önce hedefin durumunu sakla
	var target_slot_data = slot_data
	
	# Origin'den eşyayı al (henüz temizleme)
	# Hedefe eşyayı koy
	update_slot(incoming_slot_data)
	
	# Origin'e hedefteki eşyayı koy (swap)
	if target_slot_data:
		origin_slot.update_slot(target_slot_data)
	else:
		origin_slot.clear_slot()
	
	EventBus.item_dropped.emit(origin_slot, self, incoming_slot_data.item_data, incoming_slot_data.quantity)
	
	# Drag manager'ı temizle
	var drag_manager = get_node_or_null("/root/DragManager")
	if drag_manager:
		drag_manager.end_drag()