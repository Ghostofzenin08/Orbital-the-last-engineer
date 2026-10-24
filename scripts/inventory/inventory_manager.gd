class_name InventoryManagerService
extends Node

# Inventory and Resource Management Autoload for ORBITAL: The Last Engineer
# Manages handheld engineering tools, consumable resources, quick-select slots (1-4),
# tool modes, scanner battery charges, and multi-step repair item validation.

signal inventory_updated
signal tool_equipped(slot_index: int, item_id: String)
signal tool_used(tool_id: String, details: Dictionary)
signal scanner_battery_changed(current: float, max_charge: float)
signal multitool_mode_changed(new_mode: String)
signal consumable_quantity_changed(item_id: String, new_qty: int)
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)

const MULTITOOL_MODES: Array[String] = ["CALIBRATE", "CUT_WELD", "TIGHTEN"]

# Tools state
var tools: Dictionary = {
	"diagnostic_scanner": {
		"id": "diagnostic_scanner",
		"name": "Diagnostic Scanner",
		"battery": 100.0,
		"max_battery": 100.0,
		"drain_per_scan": 10.0,
		"unlocked": true
	},
	"multitool": {
		"id": "multitool",
		"name": "Multitool / Welder",
		"mode": "CALIBRATE",
		"durability": 100.0,
		"unlocked": true
	}
}

# Consumables store item_id -> quantity
var consumables: Dictionary = {
	"spare_fuse": 2,
	"coolant_canister": 1,
	"scrubber_cartridge": 1,
	"battery_cell": 2,
	"coolant_coupler": 0
}

# Quick slots: Slot 1-4
# Slot 1: Diagnostic Scanner
# Slot 2: Multitool / Welder
# Slot 3: Primary Consumable (Fuses / Cartridges / Coolant)
# Slot 4: Portable Battery Cell (Scanner Recharger)
var quick_slots: Array[String] = [
	"diagnostic_scanner",
	"multitool",
	"spare_fuse",
	"battery_cell"
]

var active_slot: int = 1 # 1-indexed (1, 2, 3, 4) or 0 for unequipped

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sync_with_mission_manager()

func reset_to_defaults() -> void:
	tools["diagnostic_scanner"]["battery"] = 100.0
	tools["diagnostic_scanner"]["unlocked"] = true
	tools["multitool"]["mode"] = "CALIBRATE"
	tools["multitool"]["unlocked"] = true
	
	consumables = {
		"spare_fuse": 2,
		"coolant_canister": 1,
		"scrubber_cartridge": 1,
		"battery_cell": 2,
		"coolant_coupler": 0
	}
	
	quick_slots = [
		"diagnostic_scanner",
		"multitool",
		"spare_fuse",
		"battery_cell"
	]
	active_slot = 1
	_sync_with_mission_manager()
	inventory_updated.emit()
	scanner_battery_changed.emit(tools["diagnostic_scanner"]["battery"], tools["diagnostic_scanner"]["max_battery"])
	multitool_mode_changed.emit(tools["multitool"]["mode"])
	tool_equipped.emit(active_slot, get_equipped_item_id())

func equip_slot(slot_idx: int) -> String:
	if slot_idx < 1 or slot_idx > quick_slots.size():
		active_slot = 0
		tool_equipped.emit(0, "")
		return ""
	
	active_slot = slot_idx
	var item_id := quick_slots[slot_idx - 1]
	AudioManager.play_sfx("click")
	tool_equipped.emit(active_slot, item_id)
	return item_id

func set_quick_slot(slot_idx: int, item_id: String) -> bool:
	if slot_idx < 1 or slot_idx > quick_slots.size():
		return false
	quick_slots[slot_idx - 1] = item_id
	inventory_updated.emit()
	if active_slot == slot_idx:
		tool_equipped.emit(active_slot, item_id)
	return true

func get_quick_slots() -> Array[String]:
	return quick_slots.duplicate()

func get_equipped_item_id() -> String:
	if active_slot >= 1 and active_slot <= quick_slots.size():
		return quick_slots[active_slot - 1]
	return ""

func get_equipped_tool() -> Dictionary:
	var item_id := get_equipped_item_id()
	if tools.has(item_id):
		return tools[item_id]
	return {}

func cycle_multitool_mode() -> String:
	var cur_mode: String = tools["multitool"]["mode"]
	var idx := MULTITOOL_MODES.find(cur_mode)
	var next_idx := (idx + 1) % MULTITOOL_MODES.size()
	tools["multitool"]["mode"] = MULTITOOL_MODES[next_idx]
	AudioManager.play_sfx("multitool_ratchet")
	multitool_mode_changed.emit(tools["multitool"]["mode"])
	return tools["multitool"]["mode"]

func set_multitool_mode(mode: String) -> void:
	if MULTITOOL_MODES.has(mode):
		tools["multitool"]["mode"] = mode
		multitool_mode_changed.emit(mode)

func get_multitool_mode() -> String:
	return str(tools["multitool"].get("mode", "CALIBRATE"))

# Consumables API
func has_item(item_id: String) -> bool:
	if tools.has(item_id):
		return bool(tools[item_id].get("unlocked", false))
	return consumables.get(item_id, 0) > 0

func get_item_count(item_id: String) -> int:
	if tools.has(item_id):
		return 1 if tools[item_id].get("unlocked", false) else 0
	return int(consumables.get(item_id, 0))

func add_item(item_id: String, count: int = 1) -> void:
	if count <= 0:
		return
	
	if tools.has(item_id):
		tools[item_id]["unlocked"] = true
	else:
		consumables[item_id] = consumables.get(item_id, 0) + count
		consumable_quantity_changed.emit(item_id, consumables[item_id])
	
	item_added.emit(item_id, count)
	inventory_updated.emit()
	_sync_with_mission_manager()

func remove_item(item_id: String, count: int = 1) -> bool:
	if count <= 0:
		return false
	
	if tools.has(item_id):
		return false # Tools are persistent
	
	var cur_qty: int = consumables.get(item_id, 0)
	if cur_qty >= count:
		consumables[item_id] = cur_qty - count
		consumable_quantity_changed.emit(item_id, consumables[item_id])
		item_removed.emit(item_id, count)
		inventory_updated.emit()
		_sync_with_mission_manager()
		return true
	return false

# Battery & Recharging API
func get_scanner_battery() -> float:
	return float(tools["diagnostic_scanner"].get("battery", 0.0))

func drain_scanner_battery(amount: float = 10.0) -> bool:
	var cur_bat: float = tools["diagnostic_scanner"]["battery"]
	if cur_bat < amount:
		return false
	tools["diagnostic_scanner"]["battery"] = maxf(0.0, cur_bat - amount)
	scanner_battery_changed.emit(tools["diagnostic_scanner"]["battery"], tools["diagnostic_scanner"]["max_battery"])
	return true

func recharge_scanner(amount: float = 100.0) -> float:
	var max_b: float = tools["diagnostic_scanner"]["max_battery"]
	var old_b: float = tools["diagnostic_scanner"]["battery"]
	tools["diagnostic_scanner"]["battery"] = minf(max_b, old_b + amount)
	AudioManager.play_sfx("recharge")
	scanner_battery_changed.emit(tools["diagnostic_scanner"]["battery"], max_b)
	return tools["diagnostic_scanner"]["battery"]

func use_battery_cell() -> bool:
	if get_item_count("battery_cell") <= 0:
		AudioManager.play_sfx("denied")
		return false
	
	var max_b: float = tools["diagnostic_scanner"]["max_battery"]
	var cur_b: float = tools["diagnostic_scanner"]["battery"]
	if cur_b >= max_b:
		# Already full
		return false
	
	if remove_item("battery_cell", 1):
		recharge_scanner(50.0)
		return true
	return false

# Tool actions
func perform_diagnostic_scan(target: Node) -> Dictionary:
	var drain_cost: float = float(tools["diagnostic_scanner"].get("drain_per_scan", 10.0))
	if not drain_scanner_battery(drain_cost):
		AudioManager.play_sfx("denied")
		return {
			"ok": false,
			"error": "INSUFFICIENT_CHARGE",
			"reason": "Diagnostic Scanner battery depleted. Recharge at Workbench or use Battery Cell [4]."
		}
	
	AudioManager.play_sfx("scanner_scan")
	
	var telem: Dictionary = _extract_target_telemetry(target)
	tool_used.emit("diagnostic_scanner", telem)
	return {
		"ok": true,
		"telemetry": telem
	}

func perform_multitool_action(action_type: String, target: Node = null) -> Dictionary:
	var cur_mode: String = get_multitool_mode()
	if action_type.to_upper() == "WELD" or cur_mode == "CUT_WELD":
		AudioManager.play_sfx("multitool_weld")
	else:
		AudioManager.play_sfx("multitool_ratchet")
	
	var result := {
		"action": action_type,
		"mode": cur_mode,
		"target_name": target.name if target != null else "None",
		"timestamp": Time.get_ticks_msec()
	}
	tool_used.emit("multitool", result)
	return {"ok": true, "details": result}

func _extract_target_telemetry(target: Node) -> Dictionary:
	var result: Dictionary = {
		"target_name": target.name if target != null else "Unknown",
		"device_id": "",
		"device_name": target.name if target != null else "Unknown Device",
		"integrity": 100.0,
		"power_draw": 0.0,
		"temperature_c": 21.0,
		"is_powered": true,
		"active_faults": [],
		"repair_steps": [],
		"recommended_tool": "Multitool [2]"
	}
	
	if target == null:
		return result
	
	# Check if target provides custom telemetry
	if target.has_method("get_diagnostic_telemetry"):
		var custom_telem: Dictionary = target.get_diagnostic_telemetry()
		for k in custom_telem.keys():
			result[k] = custom_telem[k]
		return result
	
	# Determine device_id
	var dev_id: String = ""
	if "device_id" in target and str(target.device_id) != "":
		dev_id = str(target.device_id)
	elif "interactable_id" in target and str(target.interactable_id) != "":
		dev_id = str(target.interactable_id)
	elif target is RepairPanel:
		dev_id = "life_support_scrubber"
	elif target.name.contains("Generator") or target.name.contains("reactor"):
		dev_id = "reactor_primary"
	elif target.name.contains("Bus") or target.name.contains("distribution"):
		dev_id = "distribution_bus"
	elif target.name.contains("Scrubber"):
		dev_id = "life_support_scrubber"
	elif target.name.contains("Conduit"):
		dev_id = "training_power_conduit"
	elif target.name.contains("Valve"):
		dev_id = "pressure_relief_valve"
	
	result["device_id"] = dev_id
	
	# Query ShipState if device exists
	var ship_state = get_node_or_null("/root/ShipState")
	if ship_state != null and dev_id != "" and ship_state.devices.has(dev_id):
		var dev = ship_state.devices[dev_id]
		result["device_name"] = dev.device_name
		result["integrity"] = dev.health
		result["power_draw"] = dev.get_power_draw()
		result["is_powered"] = dev.is_powered
		
		# Find active faults
		var fault_descs: Array[Dictionary] = []
		for f in dev.active_faults:
			fault_descs.append({
				"fault_id": f.fault_id,
				"root_cause": f.root_cause,
				"repair_steps": f.repair_steps,
				"required_parts": f.required_parts,
				"escalation": f.get_stage_string()
			})
			if result["repair_steps"].is_empty():
				result["repair_steps"] = f.repair_steps
		result["active_faults"] = fault_descs
	
	# Temperature readout from EnvironmentalManager if compartment known
	var env_mgr = get_tree().root.find_child("EnvironmentalManager", true, false)
	if env_mgr != null and env_mgr.has_method("get_compartment_atmosphere"):
		var cid: String = "engineering_bay"
		if "compartment_id" in target and str(target.compartment_id) != "":
			cid = str(target.compartment_id)
		var atmo: Dictionary = env_mgr.get_compartment_atmosphere(cid)
		result["temperature_c"] = atmo.get("temperature", 294.15) - 273.15
	
	return result

func _sync_with_mission_manager() -> void:
	var mm = get_node_or_null("/root/MissionManager")
	if mm != null:
		var changed := false
		for item_id in consumables.keys():
			if consumables[item_id] > 0:
				if not mm.inventory.has(item_id):
					mm.inventory.append(item_id)
					changed = true
			else:
				if mm.inventory.has(item_id):
					mm.inventory.erase(item_id)
					changed = true
		for t_id in tools.keys():
			if tools[t_id].get("unlocked", false):
				if not mm.inventory.has(t_id):
					mm.inventory.append(t_id)
					changed = true
			else:
				if mm.inventory.has(t_id):
					mm.inventory.erase(t_id)
					changed = true
		if changed:
			mm.inventory_changed.emit(mm.inventory)

func export_save_data() -> Dictionary:
	return {
		"tools": tools.duplicate(true),
		"consumables": consumables.duplicate(true),
		"quick_slots": quick_slots.duplicate(),
		"active_slot": active_slot
	}

func import_save_data(data: Dictionary) -> void:
	if data.has("tools") and data["tools"] is Dictionary:
		for t in data["tools"].keys():
			if tools.has(t):
				tools[t] = data["tools"][t]
	
	if data.has("consumables") and data["consumables"] is Dictionary:
		for c in data["consumables"].keys():
			consumables[c] = int(data["consumables"][c])
	
	if data.has("quick_slots") and data["quick_slots"] is Array:
		quick_slots.clear()
		for s in data["quick_slots"]:
			quick_slots.append(str(s))
	
	active_slot = int(data.get("active_slot", 1))
	_sync_with_mission_manager()
	inventory_updated.emit()
	scanner_battery_changed.emit(tools["diagnostic_scanner"]["battery"], tools["diagnostic_scanner"]["max_battery"])
	multitool_mode_changed.emit(tools["multitool"]["mode"])
	tool_equipped.emit(active_slot, get_equipped_item_id())
