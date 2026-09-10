# test_item_spawner.gd
extends Node

func _ready() -> void:
	await get_tree().process_frame
	spawn_test_items()

func spawn_test_items() -> void:
	var items = [
		create_weapon("sword", "Demir Kılıç", "res://assets/art/_placeholder/equipment/weapon.tres", [
			create_bonus(StatBonus.StatType.ATTACK, 25, false),
			create_bonus(StatBonus.StatType.ATTACK_SPEED, 5, true),
		]),
		create_weapon("axe", "Savaş Baltası", "res://assets/art/_placeholder/equipment/weapon.tres", [
			create_bonus(StatBonus.StatType.ATTACK, 40, false),
			create_bonus(StatBonus.StatType.CRIT_DAMAGE, 15, true),
		]),
		create_armor("helmet", "Demir Miğfer", "res://assets/art/_placeholder/equipment/headset.tres", ItemData.EquipmentType.HELMET, [
			create_bonus(StatBonus.StatType.ARMOR, 30, false),
			create_bonus(StatBonus.StatType.HEALTH, 50, false),
		]),
		create_armor("chest", "Demir Zırh", "res://assets/art/_placeholder/equipment/chest.tres", ItemData.EquipmentType.CHESTPLATE, [
			create_bonus(StatBonus.StatType.ARMOR, 60, false),
			create_bonus(StatBonus.StatType.HEALTH, 100, false),
		]),
		create_armor("boots", "Deri Çizme", "res://assets/art/_placeholder/equipment/foot.tres", ItemData.EquipmentType.FOOT, [
			create_bonus(StatBonus.StatType.MOVEMENT_SPEED, 10, true),
			create_bonus(StatBonus.StatType.ARMOR, 10, false),
		]),
		create_armor("leggings", "Demir Pantolon", "res://assets/art/_placeholder/equipment/leggins.tres", ItemData.EquipmentType.LEGGINS, [
			create_bonus(StatBonus.StatType.ARMOR, 40, false),
		]),
		create_armor("gloves", "Deri Eldiven", "res://assets/art/_placeholder/equipment/hand.tres", ItemData.EquipmentType.HAND, [
			create_bonus(StatBonus.StatType.ATTACK_SPEED, 8, true),
		]),
		create_armor("ring", "Altın Yüzük", "res://assets/art/_placeholder/equipment/ring.tres", ItemData.EquipmentType.RING, [
			create_bonus(StatBonus.StatType.ATTACK_SPEED, 10, true),
			create_bonus(StatBonus.StatType.MAGIC_POWER, 15, false),
		]),
		create_armor("cloak", "Büyülü Pelerin", "res://assets/art/_placeholder/equipment/cloak.tres", ItemData.EquipmentType.CLOAK, [
			create_bonus(StatBonus.StatType.MAGIC_POWER, 25, false),
			create_bonus(StatBonus.StatType.MANA, 75, false),
		]),
		create_armor("gem", "Değerli Taş", "res://assets/art/_placeholder/equipment/gem.tres", ItemData.EquipmentType.GEM, [
			create_bonus(StatBonus.StatType.CRIT_CHANCE, 5, true),
		]),
		create_armor("crown", "Kraliyet Tacı", "res://assets/art/_placeholder/equipment/crown.tres", ItemData.EquipmentType.CROWN, [
			create_bonus(StatBonus.StatType.MAGIC_POWER, 30, false),
			create_bonus(StatBonus.StatType.MANA_REGEN, 20, true),
		]),
		create_armor("quiver", "Ok Kılıfı", "res://assets/art/_placeholder/equipment/quiver.tres", ItemData.EquipmentType.QUIVER, [
			create_bonus(StatBonus.StatType.ATTACK, 15, false),
			create_bonus(StatBonus.StatType.CRIT_CHANCE, 3, true),
		]),
		create_armor("necklace", "Gümüş Kolye", "res://assets/art/_placeholder/equipment/necklace.tres", ItemData.EquipmentType.NECKLACE, [
			create_bonus(StatBonus.StatType.HEALTH_REGEN, 15, true),
			create_bonus(StatBonus.StatType.LIFE_STEAL, 2, true),
		]),
	]
	
	var slot_uis = get_tree().get_nodes_in_group("inventory_slots")
	
	print("Bulunan envanter slotu sayısı: ", slot_uis.size())
	print("Eklenecek eşya sayısı: ", items.size())
	
	for i in range(min(items.size(), slot_uis.size())):
		var slot_data = SlotData.new()
		slot_data.item_data = items[i]
		slot_data.quantity = 1
		slot_uis[i].update_slot(slot_data)
		print("Slot ", i + 1, ": ", items[i].name, " -> ", slot_uis[i].name)
	
	if slot_uis.size() > items.size():
		var potion = ItemData.new()
		potion.id = "potion"
		potion.name = "Sağlık İksiri"
		potion.description = "Can yenileyen sihirli iksir"
		potion.icon = load("res://assets/art/_placeholder/equipment/pouch.tres")
		potion.is_stackable = true
		potion.max_stack_size = 99
		potion.equipment_type = ItemData.EquipmentType.NONE
		
		var potion_slot = SlotData.new()
		potion_slot.item_data = potion
		potion_slot.quantity = 10
		
		slot_uis[items.size()].update_slot(potion_slot)
		print("Slot ", items.size() + 1, ": ", potion.name, " x10")
	
	print("\n=== Test eşyaları eklendi! ===")

# --- Yardımcı Fonksiyonlar ---

func create_weapon(id: String, item_name: String, icon_path: String, bonuses: Array[StatBonus]) -> ItemData:
	return _create_item(id, item_name, icon_path, ItemData.EquipmentType.WEAPON, bonuses)

func create_armor(id: String, item_name: String, icon_path: String, equipment_type: ItemData.EquipmentType, bonuses: Array[StatBonus]) -> ItemData:
	return _create_item(id, item_name, icon_path, equipment_type, bonuses)

func _create_item(id: String, item_name: String, icon_path: String, equipment_type: ItemData.EquipmentType, bonuses: Array[StatBonus]) -> ItemData:
	var item = ItemData.new()
	item.id = id
	item.name = item_name
	item.description = "Test eşyası: " + item_name
	item.icon = load(icon_path)
	item.is_stackable = false
	item.max_stack_size = 1
	item.equipment_type = equipment_type
	item.bonuses = bonuses
	return item

func create_bonus(stat_type: StatBonus.StatType, value: float, is_percentage: bool) -> StatBonus:
	var bonus = StatBonus.new()
	bonus.stat_type = stat_type
	bonus.value = value
	bonus.is_percentage = is_percentage
	return bonus