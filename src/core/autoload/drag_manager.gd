# drag_manager.gd
extends CanvasLayer

signal drag_started(item_data: ItemData, quantity: int)
signal drag_ended()

var is_dragging: bool = false
var dragged_item: ItemData = null
var dragged_quantity: int = 1
var origin_slot: Control = null

var preview_window: Window = null
var preview_icon: TextureRect = null
var preview_label: Label = null

func _ready() -> void:
	layer = 1000
	create_preview_window()
	move_preview_to_root()

func _process(_delta: float) -> void:
	if is_dragging and preview_window:
		update_preview_position()
		# Her frame öne çek (garanti için)
		preview_window.move_to_foreground()

func move_preview_to_root() -> void:
	if preview_window:
		# Window'u root'a taşı
		var root = get_tree().root
		
		# Önce mevcut parent'tan çıkar
		if preview_window.get_parent():
			preview_window.get_parent().remove_child(preview_window)
		
		# Root'a ekle
		root.add_child.call_deferred(preview_window)
		
		# move_child yerine sadece move_to_foreground kullan
		# root.move_child satırını KALDIRIN
		
		print("Preview Window root'a taşındı")
		print("Root çocuk sayısı: ", root.get_child_count())

func update_preview_position() -> void:
	var mouse_pos = DisplayServer.mouse_get_position()
	var offset = Vector2i(-22, -22)
	
	# Direkt global pozisyonu kullan
	preview_window.position = mouse_pos + offset

func create_preview_window() -> void:
	preview_window = Window.new()
	preview_window.name = "DragPreview"
	preview_window.size = Vector2i(45, 45)
	preview_window.borderless = true
	preview_window.transparent = true
	preview_window.transparent_bg = true
	preview_window.unresizable = true
	preview_window.always_on_top = true
	preview_window.visible = false
	# preview_window.gui_disable_input = true
	preview_window.mouse_passthrough = true
	
	# Panel
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = Color(1, 1, 1, 0.8)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	panel.add_theme_stylebox_override("panel", style)
	
	preview_window.add_child(panel)
	
	# Margin
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)
	
	# Icon
	preview_icon = TextureRect.new()
	preview_icon.name = "Icon"
	preview_icon.custom_minimum_size = Vector2(32, 32)
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(preview_icon)
	
	# Quantity Label
	preview_label = Label.new()
	preview_label.name = "Quantity"
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	preview_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	preview_label.add_theme_font_size_override("font_size", 12)
	preview_label.add_theme_color_override("font_color", Color.WHITE)
	preview_label.add_theme_color_override("font_outline_color", Color.BLACK)
	preview_label.add_theme_constant_override("outline_size", 3)
	preview_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(preview_label)

func start_drag(slot: Control, item: ItemData, quantity: int = 1) -> void:
	is_dragging = true
	origin_slot = slot
	dragged_item = item
	dragged_quantity = quantity
	
	update_preview(item, quantity)
	
	preview_window.visible = true
	preview_window.move_to_foreground()
	update_preview_position()
	
	print("Drag başladı - Preview görünür: ", preview_window.visible)
	
	drag_started.emit(item, quantity)

func update_preview(item: ItemData, quantity: int) -> void:
	if preview_icon:
		preview_icon.texture = item.icon if item else null
	
	if preview_label:
		if quantity > 1:
			preview_label.text = str(quantity)
			preview_label.visible = true
		else:
			preview_label.text = ""
			preview_label.visible = false

func update_position(pos: Vector2) -> void:
	if is_dragging and preview_window:
		preview_window.position = Vector2i(pos) - Vector2i(22, 22)

func end_drag() -> void:
	if not is_dragging:
		return
		
	is_dragging = false
	dragged_item = null
	dragged_quantity = 1
	origin_slot = null
	
	if preview_window:
		preview_window.visible = false
	
	drag_ended.emit()

func cancel_drag() -> void:
	end_drag()
