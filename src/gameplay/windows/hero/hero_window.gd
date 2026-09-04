extends DraggableWindow

@export var action_buttons: Array[Button]

func _ready():
	super._ready()
	_setup_window()
	_setup_buttons()

func _setup_window():
	pass

func _setup_buttons():
	if action_buttons.is_empty():
		return
	
	for button in action_buttons:
		if button and not button.pressed.is_connected(_on_action_button_pressed):
			button.pressed.connect(_on_action_button_pressed.bind(button))

func _on_action_button_pressed(button: Button):
	match button.name:
		"Stack":
			_toggle_attached_window("stack")
		"Map":
			_toggle_attached_window("map_panel")
		"Upgrades":
			pass

func _toggle_attached_window(window_id: String):
	var window = WindowManager.windows[window_id]
	if window.visible:
		WindowManager.hide_window(window_id)
	else:
		WindowManager.show_window(window_id)

func hide_inventory():
	for window in attached_windows:
		window.hide()
	hide()

func show_inventory():
	show()
