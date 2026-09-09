class_name DraggablePanel
extends PanelContainer

signal panel_closed
signal panel_opened

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# Bağlı paneller için
var attached_panels: Array[Control] = []
var parent_panel: Control = null
var attached_offsets: Dictionary = {}

# Panel grup bilgileri
var is_group_leader: bool = false

# Ekran sınırları için padding
const SCREEN_PADDING: float = 10.0

# Dikey taşma için deadzone (ayarlanabilir)
var vertical_deadzone: float = 50.0

# Kenar yaslama eşiği (ekran genişliğinin yüzdesi)
const EDGE_THRESHOLD: float = 0.2

# Cache'lenmiş panel listesi
var _cached_all_panels: Array = []
var _cache_dirty: bool = true

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_panel()

func _setup_panel():
	pass

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = get_global_mouse_position() - global_position
				accept_event()
			else:
				is_dragging = false
				if is_group_leader:
					_fix_all_panel_positions()
	elif event is InputEventMouseMotion and is_dragging:
		var new_position = get_global_mouse_position() - drag_offset
		
		if is_group_leader:
			global_position = _clamp_to_screen(new_position, self)
		else:
			global_position = new_position
		
		_update_panels_optimized()
		accept_event()

func _update_panels_optimized():
	if _cache_dirty:
		_cached_all_panels = _get_all_attached_panels()
		_cache_dirty = false
	
	for panel in attached_panels:
		if attached_offsets.has(panel):
			panel.position = position + attached_offsets[panel]
			if panel is DraggablePanel:
				panel._update_child_panels_only()

func _update_child_panels_only():
	for panel in attached_panels:
		if attached_offsets.has(panel):
			panel.position = position + attached_offsets[panel]

func _clamp_to_screen(position: Vector2, panel: Control) -> Vector2:
	var screen_size = DisplayServer.screen_get_size()
	var panel_size = panel.size
	
	position.x = clamp(position.x, SCREEN_PADDING, screen_size.x - panel_size.x - SCREEN_PADDING)
	position.y = clamp(position.y, SCREEN_PADDING, screen_size.y - panel_size.y - SCREEN_PADDING)
	
	return position

func _fix_all_panel_positions():
	if not is_group_leader:
		return
	
	global_position = _clamp_to_screen(global_position, self)
	
	var screen_size = DisplayServer.screen_get_size()
	var game_strip_left = global_position.x
	var game_strip_right = global_position.x + size.x
	
	# Kenar eşiğini kullan
	var edge_distance = screen_size.x * EDGE_THRESHOLD
	var near_left_edge = game_strip_left < edge_distance
	var near_right_edge = game_strip_right > screen_size.x - edge_distance
	
	if near_left_edge:
		_align_panels_to_game_strip_left()
	elif near_right_edge:
		_align_panels_to_game_strip_right()
	else:
		_align_panels_to_game_strip_center_x()
	
	var overflow_info = _check_all_panels_overflow()
	if overflow_info["has_overflow"]:
		_fix_overflow_without_moving_game_strip(overflow_info)
	
	_cache_dirty = true

func _align_panels_to_game_strip_left():
	var visible_panels = _get_visible_panels_cached()
	if visible_panels.is_empty():
		return
	
	visible_panels.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	
	var current_x = global_position.x
	for panel in visible_panels:
		panel.global_position.x = current_x
		current_x += panel.size.x + 5
	
	_update_offsets_recursive()

func _align_panels_to_game_strip_right():
	var visible_panels = _get_visible_panels_cached()
	if visible_panels.is_empty():
		return
	
	visible_panels.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	
	var current_x = global_position.x + size.x
	for i in range(visible_panels.size() - 1, -1, -1):
		var panel = visible_panels[i]
		panel.global_position.x = current_x - panel.size.x
		current_x -= panel.size.x + 5
	
	_update_offsets_recursive()

func _align_panels_to_game_strip_center_x():
	var game_strip_center = global_position.x + size.x / 2
	
	for panel in attached_panels:
		if panel.visible and attached_offsets.has(panel):
			panel.global_position.x = game_strip_center - panel.size.x / 2
			
			if panel is DraggablePanel:
				panel._update_child_panels_only()
				for child_panel in panel.attached_panels:
					if child_panel.visible and panel.attached_offsets.has(child_panel):
						var child_offset = panel.attached_offsets[child_panel]
						child_panel.global_position.x = panel.global_position.x + child_offset.x
	
	_update_offsets_recursive()

func _get_visible_panels_cached() -> Array:
	if _cache_dirty:
		_cached_all_panels = _get_all_attached_panels()
		_cache_dirty = false
	
	var visible_panels = []
	for panel in _cached_all_panels:
		if panel.visible:
			visible_panels.append(panel)
	
	return visible_panels

func _check_all_panels_overflow() -> Dictionary:
	var screen_size = DisplayServer.screen_get_size()
	
	var result = {
		"has_overflow": false,
		"left_overflow": false,
		"right_overflow": false,
		"top_overflow": false,
		"bottom_overflow": false
	}
	
	for panel in _cached_all_panels:
		if not panel.visible:
			continue
		
		var panel_pos = panel.global_position
		var panel_size = panel.size
		
		if panel_pos.x < SCREEN_PADDING:
			result["left_overflow"] = true
			result["has_overflow"] = true
		
		if panel_pos.x + panel_size.x > screen_size.x - SCREEN_PADDING:
			result["right_overflow"] = true
			result["has_overflow"] = true
		
		if panel_pos.y < vertical_deadzone:
			result["top_overflow"] = true
			result["has_overflow"] = true
		
		if panel_pos.y + panel_size.y > screen_size.y - vertical_deadzone:
			result["bottom_overflow"] = true
			result["has_overflow"] = true
	
	return result

func _get_all_attached_panels() -> Array:
	var all_panels = []
	
	for panel in attached_panels:
		all_panels.append(panel)
		if panel is DraggablePanel:
			all_panels.append_array(panel.attached_panels)
	
	return all_panels

func _fix_overflow_without_moving_game_strip(overflow_info: Dictionary):
	var screen_size = DisplayServer.screen_get_size()
	var visible_panels = _get_visible_panels_cached()
	
	if visible_panels.is_empty():
		return
	
	if overflow_info["left_overflow"]:
		visible_panels.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
		var current_x = SCREEN_PADDING
		for panel in visible_panels:
			panel.global_position.x = current_x
			current_x += panel.size.x + 5
	
	elif overflow_info["right_overflow"]:
		visible_panels.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
		var current_x = screen_size.x - SCREEN_PADDING
		for i in range(visible_panels.size() - 1, -1, -1):
			var panel = visible_panels[i]
			panel.global_position.x = current_x - panel.size.x
			current_x -= panel.size.x + 5
	
	if overflow_info["top_overflow"]:
		for panel in visible_panels:
			panel.global_position.y = global_position.y + size.y + 5
	
	elif overflow_info["bottom_overflow"]:
		for panel in visible_panels:
			panel.global_position.y = global_position.y - panel.size.y - 5
	
	_update_offsets_recursive()

func _update_offsets_recursive():
	for panel in attached_panels:
		if attached_offsets.has(panel):
			attached_offsets[panel] = panel.global_position - global_position
			if panel is DraggablePanel:
				panel._update_offsets_recursive()

func attach_panel(panel: Control, offset: Vector2 = Vector2.ZERO):
	if panel not in attached_panels:
		attached_panels.append(panel)
		attached_offsets[panel] = offset
		panel.parent_panel = self
		panel.position = position + offset
		_cache_dirty = true

func _update_attached_panels():
	_update_panels_optimized()

func open():
	visible = true
	panel_opened.emit()
	if is_group_leader:
		_fix_all_panel_positions()

func close():
	visible = false
	panel_closed.emit()
	for panel in attached_panels:
		panel.visible = false

func toggle():
	if visible:
		close()
	else:
		open()