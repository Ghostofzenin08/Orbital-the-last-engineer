class_name StorageLocker
extends Interactable

# Storage Locker / Supply Cabinet for ORBITAL: The Last Engineer
# Physical interactive container in ship chambers to store and retrieve spare parts, tools, and consumables.

signal locker_opened(locker_id: String, items_taken: Dictionary)
signal locker_updated(items_remaining: Dictionary)

@export var locker_name: String = "Engineering Supply Locker"
@export var stored_items: Dictionary = {} # item_id: count

@onready var indicator_led: MeshInstance3D = get_node_or_null("IndicatorLED")
@onready var indicator_light: OmniLight3D = get_node_or_null("IndicatorLight")

var _mat_available: StandardMaterial3D
var _mat_empty: StandardMaterial3D

func _ready() -> void:
	super._ready()
	if interactable_id == "":
		interactable_id = name
	_create_materials()
	_update_visuals()

func _create_materials() -> void:
	_mat_available = StandardMaterial3D.new()
	_mat_available.albedo_color = Color(0.1, 0.85, 0.4)
	_mat_available.emission_enabled = true
	_mat_available.emission = Color(0.2, 1.0, 0.5)
	_mat_available.emission_energy_multiplier = 1.5

	_mat_empty = StandardMaterial3D.new()
	_mat_empty.albedo_color = Color(0.3, 0.35, 0.4)
	_mat_empty.emission_enabled = true
	_mat_empty.emission = Color(0.4, 0.4, 0.45)
	_mat_empty.emission_energy_multiplier = 0.3

func has_items() -> bool:
	for count in stored_items.values():
		if int(count) > 0:
			return true
	return false

func get_stored_items() -> Dictionary:
	return stored_items.duplicate()

func get_item_count(item_id: String) -> int:
	return int(stored_items.get(item_id, 0))

func get_prompt() -> String:
	if not has_items():
		var equipped := InventoryManager.get_equipped_item_id()
		if equipped != "" and equipped != "diagnostic_scanner" and equipped != "multitool":
			var dname := _get_item_display_name(equipped)
			return "[E / Enter] Deposit %s into %s" % [dname, locker_name]
		return "[Empty] %s" % locker_name
	
	var item_names := []
	for item_id in stored_items.keys():
		var count: int = int(stored_items[item_id])
		if count > 0:
			var display_name := _get_item_display_name(item_id)
			if count > 1:
				item_names.append("%s (x%d)" % [display_name, count])
			else:
				item_names.append(display_name)
	
	var list_str := ", ".join(item_names)
	return "[E / Enter] Open %s [Take: %s]" % [locker_name, list_str]

func can_interact(_player: Node) -> bool:
	return true

func _on_interacted(player: Node) -> void:
	if has_items():
		take_all(player)
		return
	
	var equipped := InventoryManager.get_equipped_item_id()
	if equipped != "" and equipped != "diagnostic_scanner" and equipped != "multitool":
		if store_item(equipped, 1):
			var dname := _get_item_display_name(equipped)
			_notify(player, "Stored 1x %s in %s." % [dname, locker_name])
			return
	
	AudioManager.play_sfx("denied")
	_notify(player, "Locker is empty. Equip a consumable item [3]/[4] to store.")

func _notify(player: Node, msg: String) -> void:
	if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
		player.hud.show_notification(msg)
	elif get_tree() != null and get_tree().root != null:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud != null and hud.has_method("show_notification"):
			hud.show_notification(msg)

func take_all(player: Node = null) -> Dictionary:
	var items_taken: Dictionary = {}
	var notify_names := []
	
	for item_id in stored_items.keys():
		var count: int = int(stored_items[item_id])
		if count > 0:
			InventoryManager.add_item(item_id, count)
			items_taken[item_id] = count
			stored_items[item_id] = 0
			var dname := _get_item_display_name(item_id)
			notify_names.append("%s x%d" % [dname, count] if count > 1 else dname)
	
	AudioManager.play_sfx("locker_open")
	_update_visuals()
	locker_opened.emit(interactable_id, items_taken)
	locker_updated.emit(stored_items)
	
	# Show HUD notification if player / HUD available
	if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
		player.hud.show_notification("Locker Retrieved: " + ", ".join(notify_names))
	elif get_tree() != null and get_tree().root != null:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud != null and hud.has_method("show_notification"):
			hud.show_notification("Locker Retrieved: " + ", ".join(notify_names))
	
	return items_taken

func take_item(item_id: String, count: int = 1) -> bool:
	var cur: int = int(stored_items.get(item_id, 0))
	if cur >= count and count > 0:
		stored_items[item_id] = cur - count
		InventoryManager.add_item(item_id, count)
		AudioManager.play_sfx("locker_open")
		_update_visuals()
		locker_updated.emit(stored_items)
		return true
	return false

func store_item(item_id: String, count: int = 1) -> bool:
	if count <= 0:
		return false
	if InventoryManager.has_item(item_id) and InventoryManager.remove_item(item_id, count):
		stored_items[item_id] = stored_items.get(item_id, 0) + count
		AudioManager.play_sfx("click")
		_update_visuals()
		locker_updated.emit(stored_items)
		return true
	return false

func _update_visuals() -> void:
	var available := has_items()
	if indicator_led != null:
		indicator_led.material_override = _mat_available if available else _mat_empty
	if indicator_light != null:
		indicator_light.light_color = Color(0.2, 1.0, 0.4) if available else Color(0.4, 0.5, 0.6)
		indicator_light.light_energy = 0.8 if available else 0.2

func _get_item_display_name(item_id: String) -> String:
	match item_id:
		"diagnostic_scanner":
			return "Diagnostic Scanner"
		"multitool":
			return "Multitool"
		"spare_fuse":
			return "Spare Fuse"
		"coolant_canister":
			return "Coolant Canister"
		"scrubber_cartridge":
			return "Filter Cartridge"
		"battery_cell":
			return "Battery Cell"
		"coolant_coupler":
			return "Coolant Coupler"
		_:
			return item_id.capitalize()

func export_save_data() -> Dictionary:
	return {
		"stored_items": stored_items.duplicate()
	}

func import_save_data(data: Dictionary) -> void:
	if data.has("stored_items") and data["stored_items"] is Dictionary:
		stored_items = data["stored_items"].duplicate()
		_update_visuals()
