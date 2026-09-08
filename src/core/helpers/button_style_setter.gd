@tool
extends Node

# --- StyleBox Resources ---
@export_group("Button Styles")
@export var style_normal: StyleBox
@export var style_normal_mirrored: StyleBox
@export var style_pressed: StyleBox
@export var style_pressed_mirrored: StyleBox
@export var style_hover: StyleBox
@export var style_hover_mirrored: StyleBox
@export var style_hover_pressed: StyleBox
@export var style_hover_pressed_mirrored: StyleBox
@export var style_disabled: StyleBox
@export var style_disabled_mirrored: StyleBox
@export var style_focus: StyleBox

# --- Group & Toggle Settings ---
@export_group("Button Properties")
@export var button_group: ButtonGroup
@export var enable_toggle_mode: bool = false
@export var select_first_button: bool = false

## Tüm çocuk Button nesnelerini bulur, stilleri ve özellikleri atar.
func apply_styles_to_children() -> void:
	var style_map := {
		"normal": style_normal,
		"normal_mirrored": style_normal_mirrored,
		"pressed": style_pressed,
		"pressed_mirrored": style_pressed_mirrored,
		"hover": style_hover,
		"hover_mirrored": style_hover_mirrored,
		"hover_pressed": style_hover_pressed,
		"hover_pressed_mirrored": style_hover_pressed_mirrored,
		"disabled": style_disabled,
		"disabled_mirrored": style_disabled_mirrored,
		"focus": style_focus
	}

	var first_button_found: bool = false

	for child in get_children():
		if child is Button:
			# StyleBox atamaları
			for style_name in style_map:
				var style_box: StyleBox = style_map[style_name]
				if style_box != null:
					child.add_theme_stylebox_override(style_name, style_box)
				else:
					child.remove_theme_stylebox_override(style_name)

			# Toggle Mode ayarı
			child.toggle_mode = enable_toggle_mode

			# ButtonGroup ataması
			if button_group != null:
				child.button_group = button_group

			# İlk butonu basılı (pressed) yapma
			if not first_button_found:
				first_button_found = true
				if select_first_button and enable_toggle_mode:
					child.button_pressed = true

@export_group("")

@export_tool_button("Apply") var action = do_something

func do_something():
	apply_styles_to_children()
	Helpers.save_current_scene()
	notify_property_list_changed()