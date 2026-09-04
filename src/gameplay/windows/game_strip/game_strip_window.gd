@tool
extends DraggablePanel

@export var action_buttons: Array[Button]

@export_tool_button("Add Buttons") var collect_button_action = collect_buttons

func collect_buttons():
	action_buttons = Helpers.collect_child_buttons(self)
	Helpers.save_current_scene()
	notify_property_list_changed()

func _ready():
	super._ready()
	_setup_buttons()

func _setup_panel():
	custom_minimum_size = Vector2(340, 100)
	z_index = 100

func _setup_buttons():
	for button in action_buttons:
		if button and not button.pressed.is_connected(_on_action_button_pressed):
			button.pressed.connect(_on_action_button_pressed.bind(button))

func _on_action_button_pressed(button: Button):
	match button.name:
		"Open":
			_toggle_all_panels()
		"Battlefield":
			GameManager.change_location(GameManager.Location.BATTLEFIELD)
		"Mining":
			GameManager.change_location(GameManager.Location.MINE)
		"Woodcutting":
			GameManager.change_location(GameManager.Location.FOREST)
		"Fishing":
			GameManager.change_location(GameManager.Location.RIVER)
		_:
			pass

func _toggle_all_panels():
	var hero = WindowManager.get_panel("hero")
	if hero and hero is DraggablePanel:
		if hero.visible:
			hero.close()
		else:
			hero.open()
