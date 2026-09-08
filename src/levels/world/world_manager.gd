extends Node

var current_map: Node2D
var map_scenes: Dictionary = {
	GameManager.Location.FOREST: preload("res://src/levels/world/maps/forest_map.tscn"),
	GameManager.Location.MINE: preload("res://src/levels/world/maps/mine_map.tscn"),
	GameManager.Location.RIVER: preload("res://src/levels/world/maps/river_map.tscn"),
	GameManager.Location.BATTLEFIELD: preload("res://src/levels/world/maps/battlefield_map.tscn")
}

@export var sub_viewport_path: NodePath = "/root/MainGame/UILayer/GameStripPanel/MarginContainer/VBoxContainer/SubViewportContainer/SubViewport"

@onready var sub_viewport: SubViewport

func _ready():
	await get_tree().process_frame
	sub_viewport = get_node_or_null(sub_viewport_path)

func load_map(location: GameManager.Location):
	if not sub_viewport:
		push_warning("SubViewport yok!")
		return

	if current_map:
		current_map.queue_free()

	var map_scene = map_scenes[location]
	if map_scene:
		current_map = map_scene.instantiate()
		sub_viewport.add_child(current_map)
