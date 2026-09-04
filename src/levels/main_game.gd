extends Node


@onready var world_manager = $Systems/WorldManager
var window_container: Node

func _ready():
	get_window().transparent = true
	get_window().transparent_bg = true
	get_window().borderless = true
	get_window().unfocusable = false
	
	# world_manager.load_map(GameManager.current_location)
	
	# GameManager.location_changed.connect(_on_location_changed)

	window_container = get_node_or_null("WindowContainer")
	if not window_container:
		window_container = Node.new()
		window_container.name = "WindowContainer"
		add_child(window_container)

	await get_tree().process_frame
	move_windows_to_container()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _on_location_changed(new_location: GameManager.Location):
	world_manager.load_map(new_location)

func move_windows_to_container() -> void:
	var root = get_tree().root

	for child in root.get_children():
		if child is Window and child.name != "DragPreview":
			# Window'u container'a taşı
			root.remove_child(child)
			window_container.add_child(child)
			print("Window taşındı: ", child.name, " -> WindowContainer")

	# Ayrıca MainGame altındaki Window'ları da taşı
	for child in get_children():
		if child is Window and child.name != "DragPreview":
			remove_child(child)
			window_container.add_child(child)
			print("Window taşındı: ", child.name, " -> WindowContainer")
