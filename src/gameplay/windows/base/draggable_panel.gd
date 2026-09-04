class_name DraggablePanel
extends PanelContainer

signal panel_closed
signal panel_opened

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# Bağlı paneller için
var attached_panels: Array[Control] = []
var parent_panel: Control = null
var attached_offsets: Dictionary = {}

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_panel()

func _setup_panel():
	pass

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = get_global_mouse_position() - global_position
				accept_event()
			else:
				is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset
		_update_attached_panels()
		accept_event()

func attach_panel(panel: Control, offset: Vector2 = Vector2.ZERO):
	if panel not in attached_panels:
		attached_panels.append(panel)
		attached_offsets[panel] = offset
		panel.parent_panel = self
		panel.position = position + offset

func _update_attached_panels():
	for panel in attached_panels:
		if attached_offsets.has(panel):
			panel.position = position + attached_offsets[panel]

func open():
	visible = true
	panel_opened.emit()

func close():
	visible = false
	panel_closed.emit()
	for panel in attached_panels:
		panel.visible = false

func toggle():
	if visible:
		close()
	else:
		open()