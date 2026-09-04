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
	custom_minimum_size = Vector2(310, 429)
	z_index = 90

func _setup_buttons():
	print(str(action_buttons.size()) + " tane buton var")
	for button in action_buttons:
		if button and not button.pressed.is_connected(_on_action_button_pressed):
			button.pressed.connect(_on_action_button_pressed.bind(button))

func _on_action_button_pressed(button: Button):
	print("Pressed: " + button.name)
	match button.name:
		"Stack":
			_toggle_attached_panel("stack")
		"Map":
			_toggle_attached_panel("map_panel")
		"Upgrades":
			pass

func _toggle_attached_panel(panel_id: String):
	var panel = WindowManager.get_panel(panel_id)
	if panel and panel is DraggablePanel:
		if panel.visible:
			panel.close()
		else:
			panel.open()