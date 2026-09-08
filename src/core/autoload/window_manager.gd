extends Node

var panels: Dictionary = {}
var panel_scenes: Dictionary = {
	"game_strip": preload("res://src/gameplay/windows/game_strip/game_strip_window.tscn"),
	"map_panel": preload("res://src/gameplay/windows/map/map_window.tscn"),
	"hero": preload("res://src/gameplay/windows/hero/hero_window.tscn"),
	"stack": preload("res://src/gameplay/windows/stack/stack_window.tscn")
}

# Paneller arası boşluk
const INVENTORY_GAP: int = 15
const SIDE_PANEL_GAP: int = 25

# Scale ayarları
var scale_levels: Array = [1.0, 1.1, 1.2, 1.35]
var current_scale_index: int = 0
var current_scale: float = 1.0

# Pozisyon modları
enum PositionMode {
	CENTER,
	LEFT
}

var current_position_mode: PositionMode = PositionMode.CENTER

func _ready():
	_create_all_panels.call_deferred()

func _process(_delta: float) -> void:
	# Escape tuşu ile drag'ı iptal et
	if Input.is_action_just_pressed("ui_cancel") and DragManager.is_dragging:
		DragManager.cancel_drag()
	
	# Scale kısayolları
	if Input.is_action_just_pressed("scale_up"):
		_change_scale(1)
	elif Input.is_action_just_pressed("scale_down"):
		_change_scale(-1)

func _change_scale(direction: int):
	var new_index = current_scale_index + direction
	
	if new_index >= 0 and new_index < scale_levels.size():
		current_scale_index = new_index
		current_scale = scale_levels[current_scale_index]
		_apply_scale_to_all_panels()
		print("UI Scale: ", current_scale)

func _apply_scale_to_all_panels():
	for panel in panels.values():
		if panel is Control:
			panel.scale = Vector2(current_scale, current_scale)
			panel.pivot_offset = Vector2.ZERO
	
	_update_all_positions()

func _create_all_panels():
	_create_panel("game_strip")
	_create_panel("hero")
	_create_panel("stack")
	_create_panel("map_panel")
	
	# Başlangıç görünürlük durumları
	panels["game_strip"].visible = true
	panels["hero"].visible = false
	panels["stack"].visible = false
	panels["map_panel"].visible = false
	
	_setup_panel_attachments()
	_set_position_mode(PositionMode.CENTER)
	_apply_scale_to_all_panels()

func _create_panel(id: String):
	var panel_instance = panel_scenes[id].instantiate()
	
	# Paneli UILayer'a ekle (veya direkt root'a)
	var ui_layer = _get_or_create_ui_layer()
	ui_layer.add_child(panel_instance)
	
	panels[id] = panel_instance
	
	# Panel sinyallerini bağla
	if panel_instance is DraggablePanel:
		panel_instance.panel_closed.connect(_on_panel_closed.bind(id))
		panel_instance.panel_opened.connect(_on_panel_opened.bind(id))

func _get_or_create_ui_layer() -> CanvasLayer:
	var ui_layer = get_tree().current_scene.get_node_or_null("UILayer")
	
	if not ui_layer:
		ui_layer = CanvasLayer.new()
		ui_layer.name = "UILayer"
		ui_layer.layer = 10
		get_tree().current_scene.add_child(ui_layer)
	
	return ui_layer

func _setup_panel_attachments():
	var game_strip = panels["game_strip"]
	var hero = panels["hero"]
	var stack = panels["stack"]
	var map_panel = panels["map_panel"]
	
	# Panelleri birbirine bağla
	if game_strip is DraggablePanel and hero is DraggablePanel:
		game_strip.attach_panel(hero, Vector2(0, -hero.size.y - INVENTORY_GAP))
	
	if hero is DraggablePanel:
		if stack is DraggablePanel:
			hero.attach_panel(stack, Vector2(-stack.size.x - SIDE_PANEL_GAP, 0))
		if map_panel is DraggablePanel:
			hero.attach_panel(map_panel, Vector2(hero.size.x + SIDE_PANEL_GAP, 0))

func _set_position_mode(mode: PositionMode):
	current_position_mode = mode
	_update_all_positions()

func _update_all_positions():
	var screen_size = get_viewport().get_visible_rect().size
	var game_strip = panels["game_strip"]
	var hero = panels["hero"]
	var stack = panels["stack"]
	var map_panel = panels["map_panel"]
	
	# Scale edilmiş boyutları hesapla
	var scaled_game_strip_size = game_strip.size * current_scale
	var scaled_hero_size = hero.size * current_scale
	var scaled_stack_size = stack.size * current_scale
	var scaled_map_size = map_panel.size * current_scale
	
	match current_position_mode:
		PositionMode.CENTER:
			# GameStrip - altta ortada
			game_strip.position = Vector2(
				(screen_size.x - scaled_game_strip_size.x) / 2,
				screen_size.y - scaled_game_strip_size.y - SIDE_PANEL_GAP
			)
			
			# Hero - game_strip'in üstünde ortada
			hero.position = Vector2(
				game_strip.position.x + (scaled_game_strip_size.x - scaled_hero_size.x) / 2,
				game_strip.position.y - scaled_hero_size.y - INVENTORY_GAP
			)
			
			# Stack - hero'nun solunda
			stack.position = Vector2(
				hero.position.x - scaled_stack_size.x - SIDE_PANEL_GAP,
				hero.position.y
			)
			
			# Map - hero'nun sağında
			map_panel.position = Vector2(
				hero.position.x + scaled_map_size.x + SIDE_PANEL_GAP,
				hero.position.y
			)
		
		PositionMode.LEFT:
			# GameStrip - sol altta
			game_strip.position = Vector2(
				SIDE_PANEL_GAP,
				screen_size.y - scaled_game_strip_size.y - SIDE_PANEL_GAP
			)
			
			# Hero - sol üstte
			hero.position = Vector2(
				SIDE_PANEL_GAP,
				game_strip.position.y - scaled_hero_size.y - INVENTORY_GAP
			)
			
			# Stack - hero'nun solunda
			var stack_x = hero.position.x - scaled_stack_size.x - SIDE_PANEL_GAP
			if stack_x < SIDE_PANEL_GAP:
				stack.position = Vector2(
					hero.position.x + scaled_hero_size.x + SIDE_PANEL_GAP,
					hero.position.y
				)
			else:
				stack.position = Vector2(stack_x, hero.position.y)
			
			# Map - hero'nun sağında
			map_panel.position = Vector2(
				hero.position.x + scaled_hero_size.x + SIDE_PANEL_GAP,
				hero.position.y
			)
	
	_update_attachment_offsets()

func _update_attachment_offsets():
	var game_strip = panels["game_strip"]
	var hero = panels["hero"]
	var stack = panels["stack"]
	var map_panel = panels["map_panel"]
	
	if game_strip is DraggablePanel and hero is DraggablePanel:
		game_strip.attached_offsets[hero] = hero.position - game_strip.position
	
	if hero is DraggablePanel:
		if stack is DraggablePanel:
			hero.attached_offsets[stack] = stack.position - hero.position
		if map_panel is DraggablePanel:
			hero.attached_offsets[map_panel] = map_panel.position - hero.position

func show_panel(id: String):
	if panels.has(id):
		var panel = panels[id]
		
		# Özel gösterim mantığı
		if id == "hero":
			_show_hero_panel()
		elif id == "stack":
			_show_stack_panel()
		else:
			panel.visible = true
			panel.z_index = _get_next_z_index()
			panel.panel_opened.emit() if panel is DraggablePanel else null

func hide_panel(id: String):
	if panels.has(id):
		var panel = panels[id]
		
		# Özel gizleme mantığı
		if id == "hero":
			_hide_hero_panel()
		else:
			panel.visible = false
			panel.panel_closed.emit() if panel is DraggablePanel else null

func toggle_panel(id: String):
	if panels.has(id):
		var panel = panels[id]
		if panel.visible:
			hide_panel(id)
		else:
			show_panel(id)

func _show_hero_panel():
	var hero = panels["hero"]
	var stack = panels["stack"]
	var map_panel = panels["map_panel"]
	
	# Hero paneli göster
	hero.visible = true
	hero.z_index = _get_next_z_index()
	
	# Bağlı panellerin durumunu kontrol et
	if stack.visible:
		stack.z_index = hero.z_index
	if map_panel.visible:
		map_panel.z_index = hero.z_index
	
	if hero is DraggablePanel:
		hero.panel_opened.emit()

func _hide_hero_panel():
	var hero = panels["hero"]
	var stack = panels["stack"]
	var map_panel = panels["map_panel"]
	
	# Hero ve bağlı panelleri gizle
	hero.visible = false
	stack.visible = false
	map_panel.visible = false
	
	if hero is DraggablePanel:
		hero.panel_closed.emit()

func _show_stack_panel():
	var stack = panels["stack"]
	stack.visible = true
	stack.z_index = _get_next_z_index()
	
	if stack is DraggablePanel:
		stack.panel_opened.emit()

func _get_next_z_index() -> int:
	var max_z = 0
	for panel in panels.values():
		if panel is Control and panel.z_index > max_z:
			max_z = panel.z_index
	return max_z + 1

func _on_panel_closed(id: String):
	# Panel kapatıldığında yapılacak işlemler
	print("Panel closed: ", id)

func _on_panel_opened(id: String):
	# Panel açıldığında yapılacak işlemler
	print("Panel opened: ", id)

func get_panel(id: String) -> Control:
	return panels.get(id)
