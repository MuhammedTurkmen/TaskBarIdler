extends DraggableWindow

@export var character_sprite: Texture2D
@export var action_buttons: Array[Button]

func _ready():
	super._ready()
	_setup_window()
	# Kapatma butonunu gizle
	_setup_uncloseable()

func _setup_window():
	always_on_top = true
	
	if action_buttons.is_empty():
		return
	
	for button in action_buttons:
		if button and not button.pressed.is_connected(_on_action_button_pressed):
			button.pressed.connect(_on_action_button_pressed.bind(button))

func _setup_uncloseable():
	# Close butonunu devre dışı bırak
	close_requested.disconnect(_on_close_requested)
	close_requested.connect(_on_close_requested_blocked)
	
	# Borderless yaparak close butonunu tamamen kaldır
	borderless = true

func _on_close_requested_blocked():
	# Kapatma isteğini engelle, hiçbir şey yapma
	pass

func _on_action_button_pressed(button: Button):
	match button.name:
		"Open":
			_toggle_all_panels()
		_:
			pass

func _toggle_all_panels():
	var hero = WindowManager.windows["hero"]
	if hero.visible:
		hero.hide_inventory()
	else:
		hero.show_inventory()
