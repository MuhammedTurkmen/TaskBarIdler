@tool
extends EditorPlugin

var snapshot_button: Button
var file_dialog: FileDialog
var target_node: CanvasItem

func _enter_tree():
	# Üst bara buton ekle
	snapshot_button = Button.new()
	snapshot_button.text = "📸 Snapshot"
	snapshot_button.tooltip_text = "Seçili CanvasItem'i PNG olarak kaydet"
	snapshot_button.flat = true
	snapshot_button.pressed.connect(_on_snapshot_pressed)
	
	# Butonu editör üst barına ekle
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, snapshot_button)
	
	# FileDialog'u oluştur
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.png ; PNG Görselleri"])
	file_dialog.title = "Shader Görüntüsünü Kaydet"
	file_dialog.current_file = "snapshot.png"
	file_dialog.file_selected.connect(_on_file_selected)
	
	# FileDialog'u editöre ekle
	add_child(file_dialog)

func _exit_tree():
	# Temizlik
	if snapshot_button:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, snapshot_button)
		snapshot_button.queue_free()
	
	if file_dialog:
		file_dialog.queue_free()

func _on_snapshot_pressed():
	# Editörde seçili node'u al
	var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()
	
	if selected_nodes.is_empty():
		push_warning("Lütfen bir CanvasItem node'u seçin!")
		return
	
	# CanvasItem olan ilk node'u bul
	target_node = null
	for node in selected_nodes:
		if node is CanvasItem:
			target_node = node
			break
	
	if not target_node:
		push_warning("Seçili node bir CanvasItem değil!")
		return
	
	# FileDialog'u göster
	file_dialog.popup_centered_ratio(0.6)

func _on_file_selected(path: String) -> void:
	if not target_node:
		return
	
	# Yakalama işlemini başlat
	await _capture_node(path)

func _capture_node(path: String) -> void:
	# Node'un boyutunu ve sınırlarını hesapla
	var node_rect = _get_node_rect(target_node)
	
	if node_rect.size == Vector2.ZERO:
		push_warning("Node'un boyutu sıfır, yakalanamadı!")
		return
	
	# SubViewport oluştur
	var sub_viewport = SubViewport.new()
	sub_viewport.size = Vector2i(node_rect.size)
	sub_viewport.transparent_bg = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	sub_viewport.disable_3d = true
	
	# Node'u kopyala
	var duplicate_node = target_node.duplicate()
	
	# Kopyalanan node'un pozisyonunu ayarla
	if duplicate_node is Control:
		duplicate_node.position = Vector2.ZERO
		duplicate_node.size = target_node.size
	elif duplicate_node is Node2D:
		duplicate_node.position = Vector2.ZERO
	
	# SubViewport'a ekle
	sub_viewport.add_child(duplicate_node)
	
	# SubViewport'u geçici olarak sahneye ekle
	var editor_base = get_editor_interface().get_base_control()
	editor_base.add_child(sub_viewport)
	
	# Render için bekle
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	
	# Görüntüyü al
	var img = sub_viewport.get_texture().get_image()
	
	# Temizlik
	sub_viewport.queue_free()
	
	# Kaydet
	var err = img.save_png(path)
	if err == OK:
		print("Görsel başarıyla kaydedildi: ", path)
	else:
		push_error("Görsel kaydedilemedi, hata kodu: ", err)

func _get_node_rect(node: CanvasItem) -> Rect2:
	# Varsayılan rect
	var default_rect = Rect2(Vector2.ZERO, Vector2(256, 256))
	
	# Node'un gerçek boyutunu hesapla
	if node is Control:
		var control = node as Control
		if control.size != Vector2.ZERO:
			return Rect2(Vector2.ZERO, control.size)
		else:
			return default_rect
			
	elif node is Sprite2D:
		var sprite = node as Sprite2D
		if sprite.texture:
			var texture_size = sprite.texture.get_size()
			if texture_size != Vector2.ZERO:
				return Rect2(Vector2.ZERO, texture_size)
		return default_rect
		
	elif node is AnimatedSprite2D:
		var animated_sprite = node as AnimatedSprite2D
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(animated_sprite.animation):
			var frame_texture = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
			if frame_texture and frame_texture.get_size() != Vector2.ZERO:
				return Rect2(Vector2.ZERO, frame_texture.get_size())
		return default_rect
		
	elif node is Node2D:
		var node2d = node as Node2D
		# Node2D için get_rect() dene
		var rect = node2d.get_rect()
		if rect.size != Vector2.ZERO:
			return rect
		
		# Child'ları kontrol et
		for child in node2d.get_children():
			if child is CanvasItem:
				var child_rect = _get_node_rect(child)
				if child_rect.size != Vector2.ZERO:
					return child_rect
		
		return default_rect
	
	# Diğer CanvasItem türleri için
	return default_rect
