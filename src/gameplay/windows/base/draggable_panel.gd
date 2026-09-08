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

# Ekran sınırları için margin
const SCREEN_MARGIN: float = 10.0

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
				# Sürükleme bittiğinde pozisyonları düzelt
				if is_group_leader:
					_fix_all_panel_positions()
	elif event is InputEventMouseMotion and is_dragging:
		var new_position = get_global_mouse_position() - drag_offset
		
		if is_group_leader:
			# Ana paneli ekran sınırlarına göre sınırla
			global_position = _clamp_to_screen(new_position, self)
			_update_attached_panels()
			_check_attached_panels_bounds()
		else:
			# Bağımsız panel - sadece kendini sınırla
			global_position = _clamp_to_screen(new_position, self)
			_update_attached_panels()
		
		accept_event()

func _clamp_to_screen(position: Vector2, panel: Control) -> Vector2:
	var screen_size = DisplayServer.screen_get_size()
	var panel_size = panel.size
	
	position.x = clamp(position.x, SCREEN_MARGIN, screen_size.x - panel_size.x - SCREEN_MARGIN)
	position.y = clamp(position.y, SCREEN_MARGIN, screen_size.y - panel_size.y - SCREEN_MARGIN)
	
	return position

func _check_attached_panels_bounds():
	var screen_size = DisplayServer.screen_get_size()
	
	for panel in attached_panels:
		if not panel.visible:
			continue
		
		var panel_pos = panel.global_position
		var panel_size = panel.size
		var adjusted = false
		
		# Sol sınır kontrolü
		if panel_pos.x < SCREEN_MARGIN:
			global_position.x += (SCREEN_MARGIN - panel_pos.x)
			adjusted = true
		
		# Sağ sınır kontrolü
		if panel_pos.x + panel_size.x > screen_size.x - SCREEN_MARGIN:
			global_position.x -= (panel_pos.x + panel_size.x - (screen_size.x - SCREEN_MARGIN))
			adjusted = true
		
		# Üst sınır kontrolü
		if panel_pos.y < SCREEN_MARGIN:
			global_position.y += (SCREEN_MARGIN - panel_pos.y)
			adjusted = true
		
		# Alt sınır kontrolü
		if panel_pos.y + panel_size.y > screen_size.y - SCREEN_MARGIN:
			global_position.y -= (panel_pos.y + panel_size.y - (screen_size.y - SCREEN_MARGIN))
			adjusted = true
		
		if adjusted:
			_update_attached_panels()
			break

func _fix_all_panel_positions():
	if not is_group_leader:
		return
	
	# Ana paneli sınırla
	global_position = _clamp_to_screen(global_position, self)
	
	# Bağlı panelleri güncelle
	_update_attached_panels()
	
	# Bağlı panellerin durumunu kontrol et
	_fix_attached_panels_positions()

func _fix_attached_panels_positions():
	var screen_size = DisplayServer.screen_get_size()
	
	# Hangi tarafta dışarıda kalan panel var?
	var needs_left_fix = false
	var needs_right_fix = false
	var needs_top_fix = false
	var needs_bottom_fix = false
	
	for panel in attached_panels:
		if not panel.visible:
			continue
		
		if panel.global_position.x < SCREEN_MARGIN:
			needs_left_fix = true
		if panel.global_position.x + panel.size.x > screen_size.x - SCREEN_MARGIN:
			needs_right_fix = true
		if panel.global_position.y < SCREEN_MARGIN:
			needs_top_fix = true
		if panel.global_position.y + panel.size.y > screen_size.y - SCREEN_MARGIN:
			needs_bottom_fix = true
	
	# Yatay düzeltme
	if needs_left_fix:
		_reposition_panels_left()
	elif needs_right_fix:
		_reposition_panels_right()
	
	# Dikey düzeltme
	if needs_top_fix:
		_reposition_panels_bottom()
	elif needs_bottom_fix:
		_reposition_panels_top()

func _reposition_panels_left():
	var screen_size = DisplayServer.screen_get_size()
	
	# Görünür panelleri x pozisyonuna göre sırala
	var sorted_panels = _get_visible_panels_sorted_by_x()
	
	if sorted_panels.is_empty():
		return
	
	# En soldaki paneli ekranın soluna yasla
	var current_x = SCREEN_MARGIN
	for panel in sorted_panels:
		panel.global_position.x = current_x
		current_x += panel.size.x + 5
	
	# Game strip paneli de sola yasla
	global_position.x = SCREEN_MARGIN
	
	# Offset'leri güncelle
	_update_offsets_after_reposition()

func _reposition_panels_right():
	var screen_size = DisplayServer.screen_get_size()
	
	# Görünür panelleri x pozisyonuna göre sırala
	var sorted_panels = _get_visible_panels_sorted_by_x()
	
	if sorted_panels.is_empty():
		return
	
	# En sağdaki paneli ekranın sağına yasla
	var current_x = screen_size.x - SCREEN_MARGIN
	for i in range(sorted_panels.size() - 1, -1, -1):
		var panel = sorted_panels[i]
		panel.global_position.x = current_x - panel.size.x
		current_x -= panel.size.x + 5
	
	# Game strip paneli de sağa yasla
	global_position.x = screen_size.x - size.x - SCREEN_MARGIN
	
	# Offset'leri güncelle
	_update_offsets_after_reposition()

func _reposition_panels_bottom():
	# Panelleri game strip'in altına taşı
	for panel in attached_panels:
		if panel.visible:
			panel.global_position.y = global_position.y + size.y + 5
	
	# Offset'leri güncelle
	_update_offsets_after_reposition()

func _reposition_panels_top():
	# Panelleri game strip'in üstüne taşı
	for panel in attached_panels:
		if panel.visible:
			panel.global_position.y = global_position.y - panel.size.y - 5
	
	# Offset'leri güncelle
	_update_offsets_after_reposition()

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