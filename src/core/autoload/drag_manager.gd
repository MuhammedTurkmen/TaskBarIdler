# drag_manager.gd
extends Node

signal drag_started(item_data: ItemData, quantity: int)
signal drag_ended()
signal drag_cancelled()

var is_dragging: bool = false
var dragged_item: ItemData = null
var dragged_quantity: int = 1
var origin_slot: Control = null
var origin_slot_data: SlotData = null  # Orijinal veriyi sakla

var drag_layer: CanvasLayer = null
var preview_container: Control = null
var preview_icon: TextureRect = null
var preview_label: Label = null

func _ready():
	_setup_drag_layer()
	_create_preview()

func _setup_drag_layer():
	drag_layer = get_tree().current_scene.get_node_or_null("DragLayer")
	
	if not drag_layer:
		drag_layer = CanvasLayer.new()
		drag_layer.name = "DragLayer"
		drag_layer.layer = 1000
		get_tree().current_scene.add_child(drag_layer)

func _create_preview():
	if not drag_layer:
		return
	
	preview_container = Control.new()
	preview_container.name = "DragPreview"
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_container.visible = false
	preview_container.z_index = 1000
	preview_container.custom_minimum_size = Vector2(40, 40)
	preview_container.size = Vector2(40, 40)
	drag_layer.add_child(preview_container)
	
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = Color(1, 1, 1, 0.8)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	panel.add_theme_stylebox_override("panel", style)
	
	preview_container.add_child(panel)
	
	preview_icon = TextureRect.new()
	preview_icon.name = "Icon"
	preview_icon.custom_minimum_size = Vector2(32, 32)
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_container.add_child(preview_icon)
	
	preview_label = Label.new()
	preview_label.name = "Quantity"
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	preview_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	preview_label.add_theme_font_size_override("font_size", 12)
	preview_label.add_theme_color_override("font_color", Color.WHITE)
	preview_label.add_theme_color_override("font_outline_color", Color.BLACK)
	preview_label.add_theme_constant_override("outline_size", 3)
	preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_container.add_child(preview_label)

func _process(_delta: float):
	if is_dragging and preview_container:
		_update_preview_position()

func _update_preview_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var offset = Vector2(-22, -22)
	preview_container.position = mouse_pos + offset

func start_drag(slot: Control, item: ItemData, quantity: int = 1):
	is_dragging = true
	origin_slot = slot
	dragged_item = item
	dragged_quantity = quantity
	
	# Orijinal slot_data'yı sakla
	if slot is SlotUI or slot is EquipmentSlotUI:
		origin_slot_data = slot.slot_data
	
	_update_preview(item, quantity)
	
	preview_container.visible = true
	_update_preview_position()
	
	drag_started.emit(item, quantity)

func _update_preview(item: ItemData, quantity: int):
	if preview_icon:
		preview_icon.texture = item.icon if item else null
	
	if preview_label:
		if quantity > 1:
			preview_label.text = str(quantity)
			preview_label.visible = true
		else:
			preview_label.text = ""
			preview_label.visible = false

func end_drag():
	# Idempotent - birden fazla çağrılsa bile sorun çıkarmasın
	if not is_dragging:
		return
	
	is_dragging = false
	dragged_item = null
	dragged_quantity = 1
	origin_slot = null
	origin_slot_data = null
	
	if preview_container:
		preview_container.visible = false
	
	drag_ended.emit()

# Drag iptal edildiğinde (drop reddedildiğinde) çağrılır
func cancel_drag():
	if not is_dragging:
		return
	
	# Eşyayı orijinal slota geri koy
	if origin_slot and origin_slot_data:
		if origin_slot.has_method("update_slot"):
			origin_slot.update_slot(origin_slot_data)
	
	end_drag()
	drag_cancelled.emit()