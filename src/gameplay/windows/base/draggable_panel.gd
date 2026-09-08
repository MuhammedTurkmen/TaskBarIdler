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

# Game strip'in default pozisyonu (ortaya dönmek için)
var default_x_position: float = 0.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_panel()
	# Default pozisyonu kaydet
	default_x_position = position.x

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
				# Sürükleme bittiğinde pozisyonları düzelt
				if is_group_leader:
					_fix_all_panel_positions()
	elif event is InputEventMouseMotion and is_dragging:
		var new_position = get_global_mouse_position() - drag_offset
		
		if is_group_leader:
			# Game strip panel her zaman ekran sınırları içinde kalır
			global_position = _clamp_to_screen(new_position, self)
			_update_attached_panels()
		else:
			# Diğer paneller serbestçe hareket edebilir
			global_position = new_position
			_update_attached_panels()
		
		accept_event()

func _clamp_to_screen(position: Vector2, panel: Control) -> Vector2:
	var screen_size = DisplayServer.screen_get_size()
	var panel_size = panel.size
	
	position.x = clamp(position.x, SCREEN_PADDING, screen_size.x - panel_size.x - SCREEN_PADDING)
	position.y = clamp(position.y, SCREEN_PADDING, screen_size.y - panel_size.y - SCREEN_PADDING)
	
	return position

func _fix_all_panel_positions():
	if not is_group_leader:
		return
	
	# Önce game strip'i ekran sınırlarına clamp et
	global_position = _clamp_to_screen(global_position, self)
	_update_attached_panels()
	
	# Taşan panelleri kontrol et
	var has_overflow = _check_panel_overflow()
	
	if has_overflow:
		# Taşma varsa düzelt
		_fix_overflow()
	else:
		# Taşma yoksa game strip'i ortaya döndür (sadece x ekseninde)
		_return_to_center_x()
	
	# Son olarak bağlı panelleri güncelle
	_update_attached_panels()

func _check_panel_overflow() -> bool:
	var screen_size = DisplayServer.screen_get_size()
	var has_overflow = false
	
	for panel in attached_panels:
		if not panel.visible:
			continue
		
		var panel_pos = panel.global_position
		var panel_size = panel.size
		
		# Sol taşma kontrolü
		if panel_pos.x < SCREEN_PADDING:
			return true
		
		# Sağ taşma kontrolü
		if panel_pos.x + panel_size.x > screen_size.x - SCREEN_PADDING:
			return true
		
		# Üst taşma kontrolü (deadzone ile)
		if panel_pos.y < vertical_deadzone:
			return true
		
		# Alt taşma kontrolü (deadzone ile)
		if panel_pos.y + panel_size.y > screen_size.y - vertical_deadzone:
			return true
	
	return false

func _fix_overflow():
	var screen_size = DisplayServer.screen_get_size()
	
	# Taşan panelleri bul
	var left_overflow = false
	var right_overflow = false
	var top_overflow = false
	var bottom_overflow = false
	
	for panel in attached_panels:
		if not panel.visible:
			continue
		
		var panel_pos = panel.global_position
		var panel_size = panel.size
		
		if panel_pos.x < SCREEN_PADDING:
			left_overflow = true
		if panel_pos.x + panel_size.x > screen_size.x - SCREEN_PADDING:
			right_overflow = true
		if panel_pos.y < vertical_deadzone:
			top_overflow = true
		if panel_pos.y + panel_size.y > screen_size.y - vertical_deadzone:
			bottom_overflow = true
	
	# Yatay düzeltme
	if left_overflow:
		_reposition_panels_left()
	elif right_overflow:
		_reposition_panels_right()
	
	# Dikey düzeltme
	if top_overflow:
		_reposition_panels_below_game_strip()
	elif bottom_overflow:
		_reposition_panels_above_game_strip()

func _reposition_panels_left():
	var sorted_panels = _get_visible_panels_sorted_by_x()
	
	if sorted_panels.is_empty():
		return
	
	# En soldaki paneli padding'e yasla
	var current_x = SCREEN_PADDING
	for panel in sorted_panels:
		panel.global_position.x = current_x
		current_x += panel.size.x + 5
	
	# Game strip'i de sola yasla
	global_position.x = SCREEN_PADDING
	
	# Offset'leri güncelle
	_update_offsets_after_reposition()

func _reposition_panels_right():
	var screen_size = DisplayServer.screen_get_size()
	var sorted_panels = _get_visible_panels_sorted_by_x()
	
	if sorted_panels.is_empty():
		return
	
	# En sağdaki paneli padding'e yasla
	var current_x = screen_size.x - SCREEN_PADDING
	for i in range(sorted_panels.size() - 1, -1, -1):
		var panel = sorted_panels[i]
		panel.global_position.x = current_x - panel.size.x
		current_x -= panel.size.x + 5
	
	# Game strip'i de sağa yasla
	global_position.x = screen_size.x - size.x - SCREEN_PADDING
	
	# Offset'leri güncelle
	_update_offsets_after_reposition()

func _reposition_panels_below_game_strip():
	# Panelleri game strip'in altına taşı
	for panel in attached_panels:
		if panel.visible:
			panel.global_position.y = global_position.y + size.y + 5
	
	# Offset'leri güncelle
	_update_offsets_after_reposition()

func _reposition_panels_above_game_strip():
	# Panelleri game strip'in üstüne taşı
	for panel in attached_panels:
		if panel.visible:
			panel.global_position.y = global_position.y - panel.size.y - 5
	
	# Offset'leri güncelle
	_update_offsets_after_reposition()

func _return_to_center_x():
	var screen_size = DisplayServer.screen_get_size()
	
	# Game strip'i x ekseninde ortaya döndür
	global_position.x = (screen_size.x - size.x) / 2
	
	# Bağlı panelleri güncelle
	_update_attached_panels()

func _get_visible_panels_sorted_by_x() -> Array:
	var visible_panels = []
	
	for panel in attached_panels:
		if panel.visible:
			visible_panels.append(panel)
	
	visible_panels.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	
	return visible_panels

func _update_offsets_after_reposition():
	# Tüm bağlı panellerin offset'lerini güncelle
	for panel in attached_panels:
		if attached_offsets.has(panel):
			attached_offsets[panel] = panel.global_position - global_position

func attach_panel(panel: Control, offset: Vector2 = Vector2.ZERO):
	if panel not in attached_panels:
		attached_panels.append(panel)
		attached_offsets[panel] = offset
		panel.parent_panel = self
		panel.position = position + offset

func _update_attached_panels():
	for panel in attached_panels:
		if attached_offsets.has(panel):
			panel.position = position + attached_offsets[panel]

func open():
	visible = true
	panel_opened.emit()
	
	# Açılışta pozisyonları kontrol et
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