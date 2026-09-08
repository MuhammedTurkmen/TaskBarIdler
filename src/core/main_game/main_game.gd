extends Node

@onready var world_manager = $Systems/WorldManager

func _ready():
	GameManager.location_changed.connect(_on_location_changed)
	
	await get_tree().create_timer(0.3).timeout
	world_manager.load_map(GameManager.current_location)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _on_location_changed(new_location: GameManager.Location):
	world_manager.load_map(new_location)
