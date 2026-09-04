extends Window

class_name DraggableWindow

var is_dragging: bool = false
var drag_start_position: Vector2i
var mouse_start_position: Vector2i

# Bağlı pencereler için
var attached_windows: Array[Window] = []
var parent_window: Window = null
var attached_offsets: Dictionary = {}

# Root window (en üst parent)
var root_window: Window = null

# Statik olarak scene'de belirlenecek tıklanabilir node'lar
@export var clickable_nodes: Array[NodePath] = []

# Grup adı - dinamik olarak eklenecek tıklanabilir node'lar için
const CLICKABLE_GROUP: String = "clickable_area"

# Ekran sınırları için kenar boşluğu
const SCREEN_MARGIN: int = 0

func _ready():
	transparent = true
	transparent_bg = true
	always_on_top = true
	borderless = true
	wrap_controls = true
	
	close_requested.connect(_on_close_requested)
	
	await get_tree().process_frame
	_setup_window()
	_register_clickable_nodes()

func _register_clickable_nodes():
	for node_path in clickable_nodes:
		var node = get_node_or_null(node_path)
		if node and not node.is_in_group(CLICKABLE_GROUP):
			node.add_to_group(CLICKABLE_GROUP)

func _on_close_requested() -> void:
	hide()
	for window in attached_windows:
		window.hide()

func _setup_window():
	pass

func get_root_window() -> Window:
	"""En üst parent'ı bul"""
	if root_window:
		return root_window
	
	var current = self
	while current.parent_window != null:
		current = current.parent_window
	
	root_window = current
	return root_window

func attach_window(window: Window, relative_offset: Vector2i = Vector2i.ZERO):
	"""Bir pencereyi bu pencereye bağla"""
	if not window in attached_windows:
		attached_windows.append(window)
		window.parent_window = self
		attached_offsets[window] = relative_offset
		window.position = position + relative_offset
		_reset_root_window()

func detach_window(window: Window):
	"""Bağlı pencereyi ayır"""
	if window in attached_windows:
		attached_windows.erase(window)
		attached_offsets.erase(window)
		window.parent_window = null
		_reset_root_window()

func _reset_root_window():
	"""Root window referansını sıfırla"""
	root_window = null
	for window in attached_windows:
		if window.has_method("_reset_root_window"):
			window._reset_root_window()

func update_attached_positions():
	"""Bağlı tüm pencerelerin pozisyonlarını güncelle"""
	for window in attached_windows:
		if attached_offsets.has(window):
			window.position = position + attached_offsets[window]
			if window.has_method("update_attached_positions"):
				window.update_attached_positions()

func _clamp_position_to_screen(pos: Vector2i) -> Vector2i:
	"""Pozisyonu ekran sınırları içinde tut"""
	var screen_size = DisplayServer.window_get_size()
	
	# X sınırları
	pos.x = clamp(pos.x, SCREEN_MARGIN, screen_size.x - size.x - SCREEN_MARGIN)
	
	# Y sınırları
	pos.y = clamp(pos.y, SCREEN_MARGIN, screen_size.y - size.y - SCREEN_MARGIN)
	
	return pos

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mouse_pos = DisplayServer.mouse_get_position()
				if _is_mouse_in_window(mouse_pos) and not _is_mouse_on_clickable_area(mouse_pos):
					is_dragging = true
					drag_start_position = position
					mouse_start_position = mouse_pos
					
					# Root window'u da sürükleme moduna al
					var root = get_root_window()
					if root != self:
						root.drag_start_position = root.position
						root.mouse_start_position = mouse_pos
						root.is_dragging = true
			else:
				if is_dragging:
					is_dragging = false
					
					# Root window'un sürüklemesini de durdur
					var root = get_root_window()
					if root != self and root.is_dragging:
						root.is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		var current_mouse_pos = DisplayServer.mouse_get_position()
		var mouse_delta = current_mouse_pos - mouse_start_position
		
		var root = get_root_window()
		if root != self and root.is_dragging:
			# Root window'u hareket ettir ve sınırla
			var new_position = root.drag_start_position + mouse_delta
			new_position = root._clamp_position_to_screen(new_position)
			root.position = new_position
			root.update_attached_positions()
		else:
			# Kendini hareket ettir ve sınırla
			var new_position = drag_start_position + mouse_delta
			new_position = _clamp_position_to_screen(new_position)
			position = new_position
			update_attached_positions()

func _is_mouse_in_window(mouse_pos: Vector2i) -> bool:
	var window_rect = Rect2i(position, size)
	return window_rect.has_point(mouse_pos)

func _is_mouse_on_clickable_area(mouse_pos: Vector2i) -> bool:
	var local_mouse_pos = mouse_pos - position
	
	if _is_point_on_button_recursive(self, local_mouse_pos):
		return true
	
	if _is_point_on_group_nodes(self, local_mouse_pos):
		return true
	
	return false

func _is_point_on_button_recursive(node: Node, point: Vector2i) -> bool:
	for child in node.get_children():
		if child is SubViewport:
			continue
			
		if child.has_method("is_visible_in_tree"):
			if not child.is_visible_in_tree():
				continue
		elif "visible" in child:
			if not child.visible:
				continue
			
		if child is BaseButton:
			var control_rect = Rect2i(child.position, child.size)
			if control_rect.has_point(point):
				return true
		
		elif child is Container:
			var child_point = point - Vector2i(child.position)
			if _is_point_on_button_recursive(child, child_point):
				return true
	
	return false

func _is_point_on_group_nodes(node: Node, point: Vector2i) -> bool:
	for child in node.get_children():
		if child is SubViewport:
			continue
			
		if child.has_method("is_visible_in_tree"):
			if not child.is_visible_in_tree():
				continue
		elif "visible" in child:
			if not child.visible:
				continue
		
		if child.is_in_group(CLICKABLE_GROUP):
			if _is_point_in_node(child, point):
				return true
		
		if child.get_child_count() > 0:
			var child_point = point
			if child is Control:
				child_point = point - Vector2i(child.position)
			if _is_point_on_group_nodes(child, child_point):
				return true
	
	return false

func _is_point_in_node(node: Node, point: Vector2i) -> bool:
	if node is Control:
		var control_rect = Rect2i(node.position, node.size)
		return control_rect.has_point(point)
	
	elif node is Sprite2D and node.texture:
		var texture_size = Vector2i(node.texture.get_size())
		var scaled_size = Vector2i(
			int(texture_size.x * node.scale.x),
			int(texture_size.y * node.scale.y)
		)
		@warning_ignore("integer_division")
		var sprite_rect = Rect2i(
			Vector2i(node.position) - scaled_size / 2,
			scaled_size
		)
		return sprite_rect.has_point(point)
	
	elif node is TextureRect:
		var rect = Rect2i(node.position, node.size)
		return rect.has_point(point)
	
	return false

static func add_clickable_node(node: Node) -> void:
	if not node.is_in_group(CLICKABLE_GROUP):
		node.add_to_group(CLICKABLE_GROUP)

static func remove_clickable_node(node: Node) -> void:
	if node.is_in_group(CLICKABLE_GROUP):
		node.remove_from_group(CLICKABLE_GROUP)
