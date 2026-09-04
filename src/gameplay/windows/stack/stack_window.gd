extends DraggablePanel

func _ready():
	super._ready()

func _setup_panel():
	custom_minimum_size = Vector2(310, 429)
	z_index = 70