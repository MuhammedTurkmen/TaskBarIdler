@tool
extends VBoxContainer

# ============================================
# HBOXCONTAINER / VBOXCONTAINER AYARLARI
# ============================================
@export_group("H-V BoxContainer Settings")
@export var box_custom_minimum_size: Vector2 = Vector2.ZERO
@export var box_custom_maximum_size: Vector2 = Vector2(-1, -1)
@export var box_size_flags_horizontal: Control.SizeFlags = Control.SIZE_SHRINK_CENTER
@export var box_size_flags_vertical: Control.SizeFlags = Control.SIZE_SHRINK_CENTER

# ============================================
# PANELCONTAINER AYARLARI
# ============================================
@export_group("PanelContainer Settings")
@export var panel_custom_minimum_size: Vector2 = Vector2(45, 45)
@export var panel_custom_maximum_size: Vector2 = Vector2(45, 45)
@export var panel_size_flags_horizontal: Control.SizeFlags = Control.SIZE_SHRINK_CENTER
@export var panel_size_flags_vertical: Control.SizeFlags = Control.SIZE_SHRINK_CENTER

# ============================================
# MARGINCONTAINER AYARLARI
# ============================================
@export_group("MarginContainer Settings")
@export var margin_custom_minimum_size: Vector2 = Vector2(35, 35)
@export var margin_custom_maximum_size: Vector2 = Vector2(35, 35)
@export var margin_size_flags_horizontal: Control.SizeFlags = Control.SIZE_FILL
@export var margin_size_flags_vertical: Control.SizeFlags = Control.SIZE_FILL
@export var margin_left: int = 5
@export var margin_top: int = 5
@export var margin_right: int = 5
@export var margin_bottom: int = 5

# ============================================
# TEXTURERECT AYARLARI
# ============================================
@export_group("TextureRect Settings")
@export var texture_rect_custom_minimum_size: Vector2 = Vector2(27, 27)
@export var texture_rect_custom_maximum_size: Vector2 = Vector2(27, 27)
@export var texture_rect_stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_SCALE
@export var texture_rect_size_flags_horizontal: Control.SizeFlags = Control.SIZE_FILL
@export var texture_rect_size_flags_vertical: Control.SizeFlags = Control.SIZE_FILL

# ============================================
# ACTIONS
# ============================================
@export_group("Actions")
@export var apply_to_all: bool = false:
	set(value):
		if value:
			_apply_settings_recursive(self)
			print("[UI Configurator] Tüm değerler uygulandı!")
			apply_to_all = false


func _apply_settings_recursive(node: Node) -> void:
	# Kendini atla (script'in bağlı olduğu node)
	if node == self:
		for child in node.get_children():
			_apply_settings_recursive(child)
		return
	
	# Her tip kontrolünü bağımsız if ile kontrol et
	if node is HBoxContainer or node is VBoxContainer:
		_apply_box_settings(node)
	
	if node is PanelContainer:
		_apply_panel_settings(node)
	
	if node is MarginContainer:
		_apply_margin_settings(node)
	
	if node is TextureRect:
		_apply_texture_rect_settings(node)
	
	# Çocuklara ilerle
	for child in node.get_children():
		_apply_settings_recursive(child)


func _apply_box_settings(box: BoxContainer) -> void:
	box.custom_minimum_size = box_custom_minimum_size
	box.custom_maximum_size = box_custom_maximum_size
	box.size_flags_horizontal = box_size_flags_horizontal
	box.size_flags_vertical = box_size_flags_vertical
	print("  ✓ BoxContainer '%s' ayarlandı" % box.name)


func _apply_panel_settings(panel: PanelContainer) -> void:
	panel.custom_minimum_size = panel_custom_minimum_size
	panel.custom_maximum_size = panel_custom_maximum_size
	panel.size_flags_horizontal = panel_size_flags_horizontal
	panel.size_flags_vertical = panel_size_flags_vertical
	print("  ✓ PanelContainer '%s' ayarlandı" % panel.name)


func _apply_margin_settings(margin: MarginContainer) -> void:
	margin.custom_minimum_size = margin_custom_minimum_size
	margin.custom_maximum_size = margin_custom_maximum_size
	margin.size_flags_horizontal = margin_size_flags_horizontal
	margin.size_flags_vertical = margin_size_flags_vertical
	margin.add_theme_constant_override("margin_left", margin_left)
	margin.add_theme_constant_override("margin_top", margin_top)
	margin.add_theme_constant_override("margin_right", margin_right)
	margin.add_theme_constant_override("margin_bottom", margin_bottom)
	print("  ✓ MarginContainer '%s' ayarlandı" % margin.name)


func _apply_texture_rect_settings(tex_rect: TextureRect) -> void:
	tex_rect.custom_minimum_size = texture_rect_custom_minimum_size
	tex_rect.custom_maximum_size = texture_rect_custom_maximum_size
	tex_rect.stretch_mode = texture_rect_stretch_mode
	tex_rect.size_flags_horizontal = texture_rect_size_flags_horizontal
	tex_rect.size_flags_vertical = texture_rect_size_flags_vertical
	print("  ✓ TextureRect '%s' ayarlandı" % tex_rect.name)
