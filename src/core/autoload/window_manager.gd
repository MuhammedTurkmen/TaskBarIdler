extends Node

var windows: Dictionary = {}
var window_scenes: Dictionary = {
	"game_strip": preload("res://src/gameplay/windows/game_strip/game_strip_window.tscn"),
	"map_panel": preload("res://src/gameplay/windows/map/map_window.tscn"),
	"hero": preload("res://src/gameplay/windows/hero/hero_window.tscn"),
	"stack": preload("res://src/gameplay/windows/stack/stack_window.tscn")
}

# Paneller arası boşluk
const INVENTORY_GAP: int = 15
const SIDE_PANEL_GAP: int = 25

# Pozisyon modları
enum PositionMode {
	CENTER,
	LEFT
}

var current_position_mode: PositionMode = PositionMode.CENTER

func _ready():
	_create_all_windows.call_deferred()

# window_manager.gd'a eklenecek
func _process(_delta: float) -> void:
	# Escape tuşu ile drag'ı iptal et
	if Input.is_action_just_pressed("ui_cancel") and DragManager.is_dragging:
		DragManager.cancel_drag()

func _create_all_windows():
	_create_window("game_strip")
	_create_window("hero")
	_create_window("stack")
	_create_window("map_panel")
	
	windows["game_strip"].show()
	windows["hero"].hide()
	windows["stack"].hide()
	windows["map_panel"].hide()
	
	_setup_window_attachments()
	_set_position_mode(PositionMode.CENTER)

func _create_window(id: String):
	var window_instance = window_scenes[id].instantiate()
	get_tree().root.add_child(window_instance)
	windows[id] = window_instance

func _setup_window_attachments():
	var game_strip = windows["game_strip"]
	var hero = windows["hero"]
	var stack = windows["stack"]
	var map_panel = windows["map_panel"]
	
	game_strip.attach_window(hero, Vector2i(0, -hero.size.y - INVENTORY_GAP))
	hero.attach_window(stack, Vector2i(-stack.size.x - SIDE_PANEL_GAP, 0))
	hero.attach_window(map_panel, Vector2i(hero.size.x + SIDE_PANEL_GAP, 0))

func _set_position_mode(mode: PositionMode):
	current_position_mode = mode
	_update_all_positions()

func _update_all_positions():
	var screen_size = DisplayServer.window_get_size()
	var game_strip = windows["game_strip"]
	var hero = windows["hero"]
	var stack = windows["stack"]
	var map_panel = windows["map_panel"]
	
	match current_position_mode:
		PositionMode.CENTER:
			game_strip.position = Vector2i(
				(screen_size.x - game_strip.size.x) / 2,
				screen_size.y - game_strip.size.y - SIDE_PANEL_GAP
			)
			
			hero.position = Vector2i(
				game_strip.position.x + (game_strip.size.x - hero.size.x) / 2,
				game_strip.position.y - hero.size.y - INVENTORY_GAP
			)
			
			stack.position = Vector2i(
				hero.position.x - stack.size.x - SIDE_PANEL_GAP,
				hero.position.y
			)
			
			map_panel.position = Vector2i(
				hero.position.x + hero.size.x + SIDE_PANEL_GAP,
				hero.position.y
			)
		
		PositionMode.LEFT:
			game_strip.position = Vector2i(
				SIDE_PANEL_GAP,
				screen_size.y - game_strip.size.y - SIDE_PANEL_GAP
			)
			
			hero.position = Vector2i(
				SIDE_PANEL_GAP,
				game_strip.position.y - hero.size.y - INVENTORY_GAP
			)
			
			stack.position = Vector2i(
				hero.position.x - stack.size.x - SIDE_PANEL_GAP,
				hero.position.y
			)
			
			map_panel.position = Vector2i(
				hero.position.x + hero.size.x + SIDE_PANEL_GAP,
				hero.position.y
			)
	
	_update_attachment_offsets()

func _update_attachment_offsets():
	var game_strip = windows["game_strip"]
	var hero = windows["hero"]
	var stack = windows["stack"]
	var map_panel = windows["map_panel"]
	
	game_strip.attached_offsets[hero] = hero.position - game_strip.position
	hero.attached_offsets[stack] = stack.position - hero.position
	hero.attached_offsets[map_panel] = map_panel.position - hero.position

func show_window(id: String):
	if windows.has(id):
		if id == "hero":
			windows[id].show_inventory()
		elif id == "stack":
			windows[id].show()
			windows[id].grab_focus()
		else:
			windows[id].show()
			windows[id].grab_focus()

func hide_window(id: String):
	if windows.has(id):
		if id == "inventory":
			windows[id].hide_inventory()
		else:
			windows[id].hide()
