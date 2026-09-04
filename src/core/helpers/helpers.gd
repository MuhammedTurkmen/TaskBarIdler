@tool
class_name Helpers
extends RefCounted

static func collect_child_buttons(node: Node) -> Array[Button]:
	var buttons = node.find_children("*", "Button", true, false)
	var result: Array[Button] = []
	
	for button in buttons:
		if button is Button:
			result.append(button)
	
	print("Toplanan buton sayısı: ", result.size())
	return result

static func save_current_scene() -> bool:
	if not Engine.is_editor_hint():
		print("Bu fonksiyon sadece editörde çalışır!")
		return false
	
	var tree = Engine.get_main_loop()
	if not tree or not tree.edited_scene_root:
		print("Düzenlenen sahne yok!")
		return false
	
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(tree.edited_scene_root)
	
	if result == OK:
		var scene_path = tree.edited_scene_root.scene_file_path
		if scene_path != "":
			ResourceSaver.save(packed_scene, scene_path)
			print("Sahne kaydedildi: ", scene_path)
			return true
		else:
			print("Sahne dosyası bulunamadı!")
			return false
	else:
		print("Sahne paketlenemedi: ", result)
		return false