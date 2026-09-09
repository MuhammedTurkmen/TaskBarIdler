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
			# Game strip panel her zaman ekran sınırları içinde kalır
			global_position = _clamp_to_screen(new_position, self)
		else:
			# Diğer paneller serbestçe hareket edebilir
			global_position = new_position
		
		# Bağlı panelleri güncelle (zincirleme)
		_update_attached_panels_recursive()
		
		accept_event()

func _clamp_to_screen(position: Vector2, panel: Control) -> Vector2:
	var screen_size = DisplayServer.screen_get_size()
	var panel_size = panel.size
	
	position.x = clamp(position.x, SCREEN_PADDING, screen_size.x - panel_size.x - SCREEN_PADDING)
	position.y = clamp(position.y, SCREEN_PADDING, screen_size.y - panel_size.y - SCREEN_PADDING)
	
	return position

func _update_attached_panels_recursive():
	# Doğrudan bağlı panelleri güncelle
	for panel in attached_panels:
		if attached_offsets.has(panel):
			panel.position = position + attached_offsets[panel]
			
			# Eğer bağlı panel de DraggablePanel ise onun bağlı panellerini de güncelle
			if panel is DraggablePanel:
				panel._update_attached_panels_recursive()

func _fix_all_panel_positions():
	if not is_group_leader:
		return
	
	# Game strip'i ekran sınırlarına clamp et (zaten sürükleme sırasında clamp'liydi)
	global_position = _clamp_to_screen(global_position, self)
	
	# Game strip'in ekrandaki konumunu belirle
	var screen_size = DisplayServer.screen_get_size()
	var game_strip_left = global_position.x
	var game_strip_right = global_position.x + size.x
	var game_strip_center = global_position.x + size.x / 2
	
	# Sol kenara yakın mı?
	var near_left_edge = game_strip_left < screen_size.x * 0.3
	
	# Sağ kenara yakın mı?
	var near_right_edge = game_strip_right > screen_size.x * 0.7
	
	# Diğer panelleri game strip'in kenarına göre hizala
	if near_left_edge:
		_align_panels_to_game_strip_left()
	elif near_right_edge:
		_align_panels_to_game_strip_right()
	else:
		_align_panels_to_game_strip_center_x()
	
	# Taşma kontrolü yap
	var overflow_info = _check_all_panels_overflow()
	
	if overflow_info["has_overflow"]:
		# Taşma varsa düzelt (sadece diğer panelleri, game strip sabit)
		_fix_overflow_without_moving_game_strip(overflow_info)
	
	# Son olarak bağlı panelleri güncelle
	_update_attached_panels_recursive()

func _align_panels_to_game_strip_left():
	# Game strip'in sol kenarına göre panelleri hizala
	var all_panels = _get_all_attached_panels()
	var visible_panels = []
	
	for panel in all_panels:
		if panel.visible:
			visible_panels.append(panel)
	
	if visible_panels.is_empty():
		return
	
	# Panelleri x pozisyonuna göre sırala
	visible_panels.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	
	# Game strip'in sol kenarından başlayarak panelleri yerleştir
	var current_x = global_position.x
	for panel in visible_panels:
		panel.global_position.x = current_x
		current_x += panel.size.x + 5
	
	# Offset'leri güncelle
	_update_offsets_recursive()

func _align_panels_to_game_strip_right():
	# Game strip'in sağ kenarına göre panelleri hizala
	var all_panels = _get_all_attached_panels()
	var visible_panels = []
	
	for panel in all_panels:
		if panel.visible:
			visible_panels.append(panel)
	
	if visible_panels.is_empty():
		return
	
	# Panelleri x pozisyonuna göre sırala
	visible_panels.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	
	# Game strip'in sağ kenarına doğru panelleri yerleştir
	var current_x = global_position.x + size.x
	for i in range(visible_panels.size() - 1, -1, -1):
		var panel = visible_panels[i]
		panel.global_position.x = current_x - panel.size.x
		current_x -= panel.size.x + 5
	
	# Offset'leri güncelle
	_update_offsets_recursive()

func _align_panels_to_game_strip_center_x():
	# Game strip'in ortasına göre panelleri hizala
	var game_strip_center = global_position.x + size.x / 2
	
	# Hero paneli game strip'in ortasına hizala
	for panel in attached_panels:
		if panel.visible and attached_offsets.has(panel):
			panel.global_position.x = game_strip_center - panel.size.x / 2
	
	# Diğer panelleri recursive olarak güncelle
	for panel in attached_panels:
		if panel is DraggablePanel:
			panel._update_attached_panels_recursive()
	
	# Offset'leri güncelle
	_update_offsets_recursive()

func _check_all_panels_overflow() -> Dictionary:
	var screen_size = DisplayServer.screen_get_size()
	
	var result = {
		"has_overflow": false,
		"left_overflow": false,
		"right_overflow": false,
		"top_overflow": false,
		"bottom_overflow": false
	}
	
	# Tüm panelleri topla (recursive)
	var all_panels = _get_all_attached_panels()
	
	for panel in all_panels:
		if not panel.visible:
			continue
		
		var panel_pos = panel.global_position
		var panel_size = panel.size
		
		# Sol taşma kontrolü
		if panel_pos.x < SCREEN_PADDING:
			result["left_overflow"] = true
			result["has_overflow"] = true
		
		# Sağ taşma kontrolü
		if panel_pos.x + panel_size.x > screen_size.x - SCREEN_PADDING:
			result["right_overflow"] = true
			result["has_overflow"] = true
		
		# Üst taşma kontrolü (deadzone ile)
		if panel_pos.y < vertical_deadzone:
			result["top_overflow"] = true
			result["has_overflow"] = true
		
		# Alt taşma kontrolü (deadzone ile)
		if panel_pos.y + panel_size.y > screen_size.y - vertical_deadzone:
			result["bottom_overflow"] = true
			result["has_overflow"] = true
	
	return result

func _get_all_attached_panels() -> Array:
	var all_panels = []
	
	# Doğrudan bağlı panelleri ekle
	for panel in attached_panels:
		all_panels.append(panel)
		
		# Eğer bağlı panel de DraggablePanel ise onun bağlı panellerini de ekle
		if panel is DraggablePanel:
			all_panels.append_array(panel._get_all_attached_panels())
	
	return all_panels

func _fix_overflow_without_moving_game_strip(overflow_info: Dictionary):
	var screen_size = DisplayServer.screen_get_size()
	var all_panels = _get_all_attached_panels()
	var visible_panels = []
	
	for panel in all_panels:
		if panel.visible:
			visible_panels.append(panel)
	
	if visible_panels.is_empty():
		return
	
	# Yatay düzeltme
	if overflow_info["left_overflow"]:
		# Panelleri ekranın soluna yasla
		visible_panels.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
		var current_x = SCREEN_PADDING
		for panel in visible_panels:
			panel.global_position.x = current_x
			current_x += panel.size.x + 5
	
	elif overflow_info["right_overflow"]:
		# Panelleri ekranın sağına yasla
		visible_panels.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
		var current_x = screen_size.x - SCREEN_PADDING
		for i in range(visible_panels.size() - 1, -1, -1):
			var panel = visible_panels[i]
			panel.global_position.x = current_x - panel.size.x
			current_x -= panel.size.x + 5
	
	# Dikey düzeltme
	if overflow_info["top_overflow"]:
		for panel in visible_panels:
			panel.global_position.y = global_position.y + size.y + 5
	
	elif overflow_info["bottom_overflow"]:
		for panel in visible_panels:
			panel.global_position.y = global_position.y - panel.size.y - 5
	
	# Offset'leri güncelle
	_update_offsets_recursive()

func _update_offsets_recursive():
	# Doğrudan bağlı panellerin offset'lerini güncelle
	for panel in attached_panels:
		if attached_offsets.has(panel):
			attached_offsets[panel] = panel.global_position - global_position
			
			# Eğer bağlı panel de DraggablePanel ise onun offset'lerini de güncelle
			if panel is DraggablePanel:
				panel._update_offsets_recursive()

func attach_panel(panel: Control, offset: Vector2 = Vector2.ZERO):
	if panel not in attached_panels:
		attached_panels.append(panel)
		attached_offsets[panel] = offset
		panel.parent_panel = self
		panel.position = position + offset

func _update_attached_panels():
	# Eski metod - geriye dönük uyumluluk için
	_update_attached_panels_recursive()

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