# event_bus.gd
extends Node

signal equipment_equipped(slot_type: int, item_data: ItemData)
signal equipment_unequipped(slot_type: int, item_data: ItemData)

signal stats_updated

# Drag & Drop sinyalleri
signal item_drag_started(origin_slot: Control, item_data: ItemData, quantity: int)
signal item_drag_ended()
signal item_dropped(origin_slot: Control, target_slot: Control, item_data: ItemData, quantity: int)
signal drag_cancelled()