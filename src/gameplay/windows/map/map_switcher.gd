extends VBoxContainer

@onready var tabs = [
	$MarginContainer/MapPanel/Tabs/Battlefield,
	$MarginContainer/MapPanel/Tabs/Mining,
	$MarginContainer/MapPanel/Tabs/Woodcutting,
	$MarginContainer/MapPanel/Tabs/Fishing
]

@onready var buttons = [
	$MarginContainer/MapPanel/Buttons/Battlefield,
	$MarginContainer/MapPanel/Buttons/Mining,
	$MarginContainer/MapPanel/Buttons/Woodcutting,
	$MarginContainer/MapPanel/Buttons/Fishing
]

func _ready() -> void:
	for i in range(buttons.size()):
		if buttons[i] and not buttons[i].pressed.is_connected(_on_button_pressed):
			buttons[i].pressed.connect(_on_button_pressed.bind(i))
	
	switch_tab(0)

func _on_button_pressed(index: int):
	switch_tab(index)

func switch_tab(index: int) -> void:
	for i in range(tabs.size()):
		if tabs[i]:
			tabs[i].visible = (i == index)