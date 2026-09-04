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
		buttons[i].pressed.connect(func(): switch_tab(i))
	
	switch_tab(0) 

func switch_tab(index: int) -> void:
	for i in range(tabs.size()):
		tabs[i].visible = (i == index)
