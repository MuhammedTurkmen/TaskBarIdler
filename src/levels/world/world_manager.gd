extends Node

var current_map: Node2D
var map_scenes: Dictionary = {
	GameManager.Location.FOREST: preload("res://src/levels/world/maps/forest_map.tscn"),
	GameManager.Location.MINE: preload("res://src/levels/world/maps/mine_map.tscn"),
	GameManager.Location.RIVER: preload("res://src/levels/world/maps/river_map.tscn"),
	GameManager.Location.BATTLEFIELD: preload("res://src/levels/world/maps/battlefield_map.tscn")
}

func load_map(location: GameManager.Location):
	# Mevcut map'i temizle
	if current_map:
		current_map.queue_free()
	
	# Yeni map'i yükle
	var map_scene = map_scenes[location]
	if map_scene:
		current_map = map_scene.instantiate()
		add_child(current_map)
