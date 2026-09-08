@tool
extends EditorPlugin

var turkmen_menu: PopupMenu

func _enter_tree() -> void:
	# Turkmen alt menüsünü oluştur
	turkmen_menu = PopupMenu.new()
	turkmen_menu.name = "Turkmen"
	turkmen_menu.add_item("Rescan Filesystem", 0)
	turkmen_menu.id_pressed.connect(_on_turkmen_menu_pressed)
	
	# Project > Tools altına Turkmen submenu'sunu ekle
	add_tool_submenu_item("Turkmen", turkmen_menu)

func _exit_tree() -> void:
	# Temizlik
	remove_tool_menu_item("Turkmen")
	if turkmen_menu:
		turkmen_menu.queue_free()

func _on_turkmen_menu_pressed(id: int) -> void:
	match id:
		0:
			_on_rescan_pressed()

func _on_rescan_pressed() -> void:
	print("Dosya sistemi yeniden taranıyor...")
	
	var filesystem := get_editor_interface().get_resource_filesystem()
	filesystem.scan()
	
	print("Tarama tamamlandı!")