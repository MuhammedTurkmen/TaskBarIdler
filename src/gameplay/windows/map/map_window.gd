extends DraggablePanel

@export var map_buttons: Array[Button] = []

func _ready():
	super._ready()
	_setup_map_buttons()
	hide()  # Başlangıçta gizli

func _setup_panel():
	custom_minimum_size = Vector2(310, 429)
	z_index = 80

func _setup_map_buttons():
	if map_buttons.is_empty():
		return
	
	var location_map = [
		GameManager.Location.BATTLEFIELD, 
		GameManager.Location.MINE,        
		GameManager.Location.FOREST,      
		GameManager.Location.RIVER        
	]
	
	for i in range(map_buttons.size()):
		var button = map_buttons[i]
		if button and not button.pressed.is_connected(_on_map_selected):
			button.pressed.connect(_on_map_selected.bind(location_map[i]))

func _on_map_selected(location: GameManager.Location):
	GameManager.change_location(location)
	hide()