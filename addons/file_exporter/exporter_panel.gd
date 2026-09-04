@tool
extends PanelContainer

var settings: Object
var file_tree: Tree
var select_all_button: Button
var deselect_all_button: Button
var export_button: Button
var copy_logs_button: Button
var info_label: Label
var filter_container: HBoxContainer
var filter_checkboxes: Dictionary = {}
var include_addons_checkbox: CheckBox
var save_path: String
var export_path: String

func _ready():
	# Settings'i yükle
	var SettingsClass = load("res://addons/file_exporter/exporter_settings.gd")
	settings = SettingsClass.new()
	save_path = settings.get_save_path()
	export_path = settings.get_export_path()
	
	# Node'ları bul
	file_tree = get_node("VBox/Tree")
	select_all_button = get_node("VBox/HBox/SelectAll")
	deselect_all_button = get_node("VBox/HBox/DeselectAll")
	copy_logs_button = get_node("VBox/HBox/CopyLogs")
	
	export_button = get_node("VBox/HBox/Export")
	info_label = get_node("VBox/HBox/Info")
	filter_container = get_node("VBox/FilterContainer")
	
	# Butonları bağla
	select_all_button.pressed.connect(_on_select_all)
	deselect_all_button.pressed.connect(_on_deselect_all)
	copy_logs_button.pressed.connect(_on_copy_logs)
	export_button.pressed.connect(_on_export)
	file_tree.item_edited.connect(_on_item_edited)
	
	# Filtreleri oluştur
	_create_filter_checkboxes()
	
	# Dosyaları yükle
	_populate_tree()
	_load_selections()
	
	info_label.text = "✅ Hazır!"

func _create_filter_checkboxes():
	# Eski checkbox'ları temizle
	for child in filter_container.get_children():
		child.queue_free()
	
	filter_checkboxes.clear()
	
	# Addons checkbox'ı
	include_addons_checkbox = CheckBox.new()
	include_addons_checkbox.text = "Addons Klasörü"
	include_addons_checkbox.pressed.connect(_on_include_addons_toggled)
	include_addons_checkbox.button_pressed = settings.get_include_addons()
	filter_container.add_child(include_addons_checkbox)
	
	# Ayırıcı
	var separator = VSeparator.new()
	filter_container.add_child(separator)
	
	var filters = settings.get_filters()
	
	# "Tümü" checkbox'ı
	var all_checkbox = CheckBox.new()
	all_checkbox.text = "Tümü"
	all_checkbox.pressed.connect(_on_all_filter_toggled)
	all_checkbox.button_pressed = true
	filter_container.add_child(all_checkbox)
	filter_checkboxes["all"] = all_checkbox
	
	# Diğer filtreler - tüm uzantılar için checkbox oluştur
	for ext in filters:
		var checkbox = CheckBox.new()
		checkbox.text = "." + ext  # Nokta ekleyerek göster
		checkbox.pressed.connect(_on_filter_changed)
		checkbox.button_pressed = true
		filter_container.add_child(checkbox)
		filter_checkboxes[ext] = checkbox

func _on_include_addons_toggled():
	_populate_tree()
	_load_selections()

func _on_all_filter_toggled():
	var is_all = filter_checkboxes["all"].button_pressed
	for key in filter_checkboxes.keys():
		if key != "all":
			filter_checkboxes[key].button_pressed = is_all
	_on_filter_changed()

func _on_filter_changed():
	_populate_tree()
	_load_selections()

func _populate_tree():
	file_tree.clear()
	
	file_tree.columns = 2
	file_tree.set_column_title(0, "Dosya Adı")
	file_tree.set_column_title(1, "✓")
	file_tree.set_column_expand(0, true)
	file_tree.set_column_expand(1, false)
	
	var root = file_tree.create_item()
	root.set_text(0, "📁 Proje Dosyaları")
	root.set_editable(0, false)
	
	_scan_folder("res://", root)

func _is_extension_filtered(extension: String) -> bool:
	# "Tümü" seçiliyse hepsini göster
	if filter_checkboxes.has("all") and filter_checkboxes["all"].button_pressed:
		return true
	
	# Uzantı için checkbox var mı kontrol et
	if filter_checkboxes.has(extension):
		return filter_checkboxes[extension].button_pressed
	
	# Checkbox yoksa varsayılan olarak göster
	return true

func _scan_folder(path: String, parent_item: TreeItem):
	var dir = DirAccess.open(path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		
		var full_path = path.path_join(file_name)
		var is_dir = dir.current_is_dir()
		
		# .godot klasörünü her zaman atla
		if is_dir and file_name == ".godot":
			file_name = dir.get_next()
			continue
		
		# addons klasörünü checkbox durumuna göre dahil et
		if is_dir and file_name == "addons" and not include_addons_checkbox.button_pressed:
			file_name = dir.get_next()
			continue
		
		if not is_dir:
			var extension = file_name.get_extension()
			if not _is_extension_filtered(extension):
				file_name = dir.get_next()
				continue
		
		var item = file_tree.create_item(parent_item)
		item.set_text(0, file_name)
		item.set_editable(0, false)
		item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
		item.set_editable(1, true)
		item.set_meta("path", full_path)
		item.set_meta("is_dir", is_dir)
		item.set_meta("name", file_name)
		
		if is_dir:
			_scan_folder(full_path, item)
		
		file_name = dir.get_next()

func _on_item_edited():
	var item = file_tree.get_edited()
	if not item:
		return
	
	var column = file_tree.get_edited_column()
	if column != 1:
		return
	
	var is_dir = item.get_meta("is_dir", false)
	if is_dir:
		var checked = item.is_checked(1)
		_set_all_children_checked(item, checked)

func _set_all_children_checked(item: TreeItem, checked: bool):
	if not item:
		return
	
	var child = item.get_first_child()
	while child:
		if not child.get_meta("is_dir", false):
			child.set_checked(1, checked)
		else:
			_set_all_children_checked(child, checked)
		child = child.get_next()

func _load_selections():
	var config = ConfigFile.new()
	if config.load(save_path) == OK:
		for section in config.get_sections():
			var path = config.get_value(section, "path", "")
			var selected = config.get_value(section, "selected", false)
			if path != "":
				_set_item_selected(path, selected)

func _set_item_selected(path: String, selected: bool):
	_set_item_selected_recursive(file_tree.get_root(), path, selected)

func _set_item_selected_recursive(item: TreeItem, path: String, selected: bool):
	if not item:
		return
	
	var item_path = item.get_meta("path", "")
	if item_path == path:
		item.set_checked(1, selected)
		return
	
	var child = item.get_first_child()
	while child:
		_set_item_selected_recursive(child, path, selected)
		child = child.get_next()

func _on_select_all():
	_set_all_checked(file_tree.get_root(), true)
	info_label.text = "✅ Tüm dosyalar seçildi"

func _on_deselect_all():
	_set_all_checked(file_tree.get_root(), false)
	info_label.text = "❌ Tüm seçimler kaldırıldı"
	
	# Tüm filtre checkbox'larını kaldır
	if filter_checkboxes.has("all"):
		filter_checkboxes["all"].button_pressed = false
	for key in filter_checkboxes.keys():
		if key != "all":
			filter_checkboxes[key].button_pressed = false
	
	# Addons checkbox'ını da kaldır
	if include_addons_checkbox:
		include_addons_checkbox.button_pressed = false
	
	info_label.text = "❌ Tüm seçimler ve filtreler kaldırıldı"

func _set_all_checked(item: TreeItem, checked: bool):
	if not item:
		return
	
	if not item.get_meta("is_dir", false):
		item.set_checked(1, checked)
	
	var child = item.get_first_child()
	while child:
		_set_all_checked(child, checked)
		child = child.get_next()

func _on_export():
	_save_selections()
	
	var selected_files = _collect_selected_files(file_tree.get_root())
	
	if selected_files.is_empty():
		info_label.text = "⚠️ Hiç dosya seçilmedi!"
		return
	
	_export_files(selected_files)

func _collect_selected_files(item: TreeItem) -> Array:
	var selected_files = []
	_collect_selected_recursive(item, selected_files)
	return selected_files

func _collect_selected_recursive(item: TreeItem, selected_files: Array):
	if not item:
		return
	
	var path = item.get_meta("path", "")
	var is_dir = item.get_meta("is_dir", false)
	
	if path != "" and not is_dir and item.is_checked(1):
		selected_files.append({
			"path": path,
			"name": item.get_meta("name", path.get_file())
		})
	
	var child = item.get_first_child()
	while child:
		_collect_selected_recursive(child, selected_files)
		child = child.get_next()

func _export_files(selected_files: Array):
	var report = ""
	var found_files = []
	var not_found_files = []
	
	for file_data in selected_files:
		var file = FileAccess.open(file_data.path, FileAccess.READ)
		if file:
			found_files.append(file_data)
			file.close()
		else:
			not_found_files.append(file_data)
	
	report += "===== SEÇİLEN DOSYALAR =====\n"
	report += "Toplam: " + str(selected_files.size()) + " dosya\n"
	
	report += "Bulunan: " + str(found_files.size()) + " dosya\n"
	if found_files.is_empty():
		report += "- yok\n"
	else:
		for file_data in found_files:
			report += "- " + file_data.name + "\n"
	
	report += "Bulunamayan: " + str(not_found_files.size()) + " dosya\n"
	if not_found_files.is_empty():
		report += "- yok\n"
	else:
		for file_data in not_found_files:
			report += "- " + file_data.name + "\n"
	
	var time = Time.get_time_dict_from_system()
	report += "Tarih: " + str(time.hour).pad_zeros(2) + ":" + str(time.minute).pad_zeros(2) + "\n"
	report += "--------------------------------------------\n\n"
	
	for file_data in found_files:
		var file = FileAccess.open(file_data.path, FileAccess.READ)
		if file:
			var extension = file_data.path.get_extension().to_lower()
			report += "=== " + file_data.name + " ===\n\n"
			
			# .tres ve .res dosyaları için özel işleme
			if extension == "tres" or extension == "res":
				report += _process_tres_file(file_data.path, file)
			else:
				report += file.get_as_text()
			
			report += "\n\n\n"
			file.close()
	
	report += "=== folder tree ===\n\n"
	
	# Tüm proje yapısını tara
	var tree_dict = {}
	_scan_full_project_tree("res://", tree_dict)
	
	report += _tree_to_string(tree_dict, 0) + "\n"
	
	var output_file = FileAccess.open(export_path, FileAccess.WRITE)
	if output_file:
		output_file.store_string(report)
		output_file.close()
		info_label.text = "✅ " + str(selected_files.size()) + " dosya dışa aktarıldı"
		OS.shell_open(ProjectSettings.globalize_path(export_path))
	else:
		info_label.text = "❌ Rapor kaydedilemedi!"

func _process_tres_file(path: String, file: FileAccess) -> String:
	"""
	.tres ve .res dosyaları için özel işleme.
	Bu dosyalar binary veya text formatında olabilir.
	"""
	var content = ""
	
	# Dosyanın başlangıcını kontrol et
	file.seek(0)
	var header = file.get_buffer(4)
	file.seek(0)
	
	# Binary format kontrolü (genellikle "RSRC" veya benzeri bir başlık ile başlar)
	var is_binary = false
	for byte in header:
		if byte < 32 or byte > 126:  # ASCII olmayan karakterler
			is_binary = true
			break
	
	if is_binary:
		content += "[BINARY FORMAT - Cannot display content]\n"
		content += "File: " + path + "\n"
		content += "Size: " + str(file.get_length()) + " bytes\n"
	else:
		# Text formatındaki .tres dosyasını oku
		content = file.get_as_text()
		
		# .tres dosyalarındaki external resource referanslarını düzelt
		content = _fix_resource_references(content)
	
	return content

func _fix_resource_references(content: String) -> String:
	"""
	.tres dosyalarındaki external resource referanslarını daha okunabilir hale getirir.
	"""
	var lines = content.split("\n")
	var fixed_lines = []
	
	for line in lines:
		# uid referanslarını kısalt
		if "uid://" in line:
			var parts = line.split("uid://")
			if parts.size() > 1:
				var uid = parts[1].split("\"")[0]
				line = line.replace("uid://" + uid, "uid://" + uid.substr(0, 8) + "...")
		
		fixed_lines.append(line)
	
	return "\n".join(fixed_lines)

func _scan_full_project_tree(path: String, tree: Dictionary):
	var dir = DirAccess.open(path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		
		var full_path = path.path_join(file_name)
		var is_dir = dir.current_is_dir()
		
		if is_dir and file_name == ".godot":
			file_name = dir.get_next()
			continue
		
		# addons klasörünü checkbox durumuna göre dahil et
		if is_dir and file_name == "addons" and not include_addons_checkbox.button_pressed:
			file_name = dir.get_next()
			continue
		
		if is_dir:
			tree[file_name] = {}
			_scan_full_project_tree(full_path, tree[file_name])
		else:
			tree[file_name] = true
		
		file_name = dir.get_next()

func _tree_to_string(tree: Dictionary, indent: int) -> String:
	var result = ""
	var spaces = ""
	for i in range(indent):
		spaces += "    "
	
	# Önce klasörleri sırala, sonra dosyaları
	var folders = []
	var files = []
	
	for key in tree.keys():
		if tree[key] is Dictionary:
			folders.append(key)
		else:
			files.append(key)
	
	folders.sort()
	files.sort()
	
	for folder in folders:
		result += spaces + "📁 " + folder + "/\n"
		result += _tree_to_string(tree[folder], indent + 1)
	
	for file in files:
		result += spaces + "📄 " + file + "\n"
	
	return result

func _save_selections():
	var config = ConfigFile.new()
	_save_selections_recursive(file_tree.get_root(), config, 0)
	config.save(save_path)

func _save_selections_recursive(item: TreeItem, config: ConfigFile, index: int) -> int:
	if not item:
		return index
	
	var path = item.get_meta("path", "")
	if path != "":
		config.set_value("item_" + str(index), "path", path)
		config.set_value("item_" + str(index), "selected", item.is_checked(1))
		index += 1
	
	var child = item.get_first_child()
	while child:
		index = _save_selections_recursive(child, config, index)
		child = child.get_next()
	
	return index
	
func _on_copy_logs():
	var log_path := "user://logs/godot.log"
	
	if FileAccess.file_exists(log_path):
		var file := FileAccess.open(log_path, FileAccess.READ)
		if file:
			var content := file.get_as_text()
			file.close()
			
			if content.strip_edges().is_empty():
				info_label.text = "⚠️ Log dosyası boş!"
			else:
				DisplayServer.clipboard_set(content)
				info_label.text = "📋 Hata logları panoya kopyalandı!"
		else:
			info_label.text = "❌ Log dosyası okunamadı!"
	else:
		info_label.text = "⚠️ Log dosyası bulunamadı! (File Logging kapalı olabilir)"
