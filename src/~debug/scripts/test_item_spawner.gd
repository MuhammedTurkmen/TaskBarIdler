# test_item_spawner.gd
extends Node

func _ready() -> void:
    # Test eşyalarını oluştur
    await get_tree().process_frame
    spawn_test_items()

func spawn_test_items() -> void:
    # Tüm test eşyaları
    var items = [
        create_item("sword", "Demir Kılıç", "res://assets/art/_placeholder/equipment/weapon.tres", ItemData.EquipmentType.RIGHT_WEAPON),
        create_item("axe", "Savaş Baltası", "res://assets/art/_placeholder/equipment/weapon.tres", ItemData.EquipmentType.RIGHT_WEAPON),
        create_item("helmet", "Demir Miğfer", "res://assets/art/_placeholder/equipment/headset.tres", ItemData.EquipmentType.HELMET),
        create_item("chest", "Demir Zırh", "res://assets/art/_placeholder/equipment/chest.tres", ItemData.EquipmentType.CHESTPLATE),
        create_item("boots", "Deri Çizme", "res://assets/art/_placeholder/equipment/foot.tres", ItemData.EquipmentType.FOOT),
        create_item("leggings", "Demir Pantolon", "res://assets/art/_placeholder/equipment/leggins.tres", ItemData.EquipmentType.LEGGINS),
        create_item("gloves", "Deri Eldiven", "res://assets/art/_placeholder/equipment/hand.tres", ItemData.EquipmentType.HAND),
        create_item("ring", "Altın Yüzük", "res://assets/art/_placeholder/equipment/ring.tres", ItemData.EquipmentType.RING),
        create_item("cloak", "Büyülü Pelerin", "res://assets/art/_placeholder/equipment/cloak.tres", ItemData.EquipmentType.CLOAK),
        create_item("gem", "Değerli Taş", "res://assets/art/_placeholder/equipment/gem.tres", ItemData.EquipmentType.GEM),
        create_item("crown", "Kraliyet Tacı", "res://assets/art/_placeholder/equipment/crown.tres", ItemData.EquipmentType.CROWN),
        create_item("quiver", "Ok Kılıfı", "res://assets/art/_placeholder/equipment/quiver.tres", ItemData.EquipmentType.QUIVER),
        create_item("necklace", "Gümüş Kolye", "res://assets/art/_placeholder/equipment/necklace.tres", ItemData.EquipmentType.NECKLACE),
    ]
    
    # Normal envanter slotlarını bul
    var slot_uis = get_tree().get_nodes_in_group("inventory_slots")
    
    print("Bulunan envanter slotu sayısı: ", slot_uis.size())
    print("Eklenecek eşya sayısı: ", items.size())
    
    # Her eşyayı bir slota yerleştir
    for i in range(min(items.size(), slot_uis.size())):
        var slot_data = SlotData.new()
        slot_data.item_data = items[i]
        slot_data.quantity = 1
        slot_uis[i].update_slot(slot_data)
        
        print("Slot ", i + 1, ": ", items[i].name, " -> ", slot_uis[i].name)
    
    # İstiflenebilir eşya ekle (eğer boş slot varsa)
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
        print("Slot ", items.size() + 1, ": ", potion.name, " x10 -> ", slot_uis[items.size()].name)
    
    print("\n=== Test eşyaları eklendi! ===")
    print("Artık eşyaları sürükleyip equipment slotlarına taşıyabilirsiniz.")

func create_item(id: String, item_name: String, icon_path: String, equipment_type: int) -> ItemData:
    var item = ItemData.new()
    item.id = id
    item.name = item_name
    item.description = "Test eşyası: " + item_name
    item.icon = load(icon_path)
    item.is_stackable = false
    item.max_stack_size = 1
    item.equipment_type = equipment_type
    return item