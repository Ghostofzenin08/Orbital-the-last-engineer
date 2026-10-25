extends Node

# Save Manager Autoload for ORBITAL: The Last Engineer
# Persists game state to user://savegame.json and settings to user://settings.json

const SAVE_PATH: String = "user://savegame.json"
const SETTINGS_PATH: String = "user://settings.json"
const CURRENT_SAVE_VERSION: int = 1

var mouse_sensitivity: float = 0.002
var master_volume: float = 1.0
var look_mode: String = "mouse" # "mouse" or "arrow_keys"
var game_mode: String = "logical" # "feel" or "logical"

signal look_mode_changed(new_mode: String)
signal game_mode_changed(new_mode: String)

func set_look_mode(new_mode: String) -> void:
	if new_mode != "mouse" and new_mode != "arrow_keys" and new_mode != "arrows":
		new_mode = "mouse"
	if new_mode == "arrows":
		new_mode = "arrow_keys"
	look_mode = new_mode
	save_settings()
	look_mode_changed.emit(look_mode)

func toggle_look_mode() -> String:
	if look_mode == "mouse":
		set_look_mode("arrow_keys")
	else:
		set_look_mode("mouse")
	return look_mode

func set_game_mode(new_mode: String) -> void:
	if new_mode != "feel" and new_mode != "logical":
		new_mode = "logical"
	game_mode = new_mode
	save_settings()
	game_mode_changed.emit(game_mode)

func toggle_game_mode() -> String:
	if game_mode == "logical":
		set_game_mode("feel")
	else:
		set_game_mode("logical")
	return game_mode

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_mappings()
	load_settings()

func _ensure_input_mappings() -> void:
	var defs := {
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"interact": [KEY_E, KEY_ENTER, KEY_KP_ENTER],
		"pause": [KEY_ESCAPE],
		"sprint": [KEY_SHIFT]
	}
	for action in defs.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in defs[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			ev.keycode = key
			if not InputMap.action_has_event(action, ev):
				InputMap.action_add_event(action, ev)


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(player: Node3D = null, environmental_mgr: Node = null) -> bool:
	var save_dict := {
		"version": CURRENT_SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"missions": MissionManager.export_save_data(),
		"systems": ShipSystemManager.export_save_data(),
		"game_mode": game_mode,
		"look_mode": look_mode,
	}
	
	if environmental_mgr != null and environmental_mgr.has_method("export_save_data"):
		save_dict["environment"] = environmental_mgr.export_save_data()
	
	if get_node_or_null("/root/ShipState") != null:
		save_dict["ship_state"] = ShipState.export_save_data()
	
	if get_node_or_null("/root/InventoryManager") != null:
		save_dict["inventory"] = InventoryManager.export_save_data()
	
	if player != null and is_instance_valid(player):
		save_dict["player"] = {
			"pos_x": player.global_position.x,
			"pos_y": player.global_position.y,
			"pos_z": player.global_position.z,
			"rot_y": player.rotation.y
		}
	
	var root := get_tree().root
	var door_aft = root.find_child("DoorAft", true, false)
	var door_fwd = root.find_child("DoorForward", true, false)
	var doors_dict: Dictionary = {
		"door_aft_open": door_aft.is_open if door_aft else false,
		"door_fwd_open": door_fwd.is_open if door_fwd else false
	}
	var all_doors = root.find_children("*", "BulkheadDoor", true, false)
	var doors_by_id: Dictionary = {}
	for d in all_doors:
		var key = d.device_id if d.device_id != "" else d.name
		doors_by_id[key] = d.export_save_data()
	doors_dict["all_doors"] = doors_by_id
	save_dict["doors"] = doors_dict
	
	var lockers_data: Dictionary = {}
	var lockers = root.find_children("*", "StorageLocker", true, false)
	for l in lockers:
		if l.interactable_id != "":
			lockers_data[l.interactable_id] = l.export_save_data()
	if not lockers_data.is_empty():
		save_dict["lockers"] = lockers_data

	var repairs_data: Dictionary = {}
	var repairs = root.find_children("*", "MultiStepRepairPanel", true, false)
	for r in repairs:
		if r.device_id != "":
			repairs_data[r.device_id] = r.export_save_data()
	if not repairs_data.is_empty():
		save_dict["multi_step_repairs"] = repairs_data

	var single_repairs_data: Dictionary = {}
	var single_repairs = root.find_children("*", "RepairPanel", true, false)
	for r in single_repairs:
		var key = r.device_id if r.device_id != "" else r.name
		if r.has_method("export_save_data"):
			single_repairs_data[key] = r.export_save_data()
	if not single_repairs_data.is_empty():
		save_dict["single_step_repairs"] = single_repairs_data

	var airlocks_data: Dictionary = {}
	var airlocks = root.find_children("*", "AirlockController", true, false)
	for a in airlocks:
		airlocks_data[a.name] = a.export_save_data()
	if not airlocks_data.is_empty():
		save_dict["airlocks"] = airlocks_data

	var crates_data: Dictionary = {}
	var crates = root.find_children("*", "SalvageCrate", true, false)
	for c in crates:
		var key = c.device_id if c.device_id != "" else c.name
		crates_data[key] = c.export_save_data()
	if not crates_data.is_empty():
		save_dict["salvage_crates"] = crates_data

	var breach_data: Dictionary = {}
	var breaches = root.find_children("*", "HullBreachSeal", true, false)
	for b in breaches:
		var key = b.device_id if b.device_id != "" else b.name
		breach_data[key] = b.export_save_data()
	if not breach_data.is_empty():
		save_dict["hull_breach_seals"] = breach_data

	var datapads_data: Dictionary = {}
	var datapads = root.find_children("*", "DatapadPickup", true, false)
	for dp in datapads:
		var key = dp.datapad_id if dp.datapad_id != "" else dp.name
		datapads_data[key] = dp.export_save_data()
	if not datapads_data.is_empty():
		save_dict["datapads"] = datapads_data

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: %s" % SAVE_PATH)
		return false
	
	var json_str := JSON.stringify(save_dict, "\t")
	file.store_string(json_str)
	file.close()
	return true

func load_game(player: Node3D = null, environmental_mgr: Node = null) -> bool:
	if not has_save_file():
		return false
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: %s" % SAVE_PATH)
		return false
	
	var content := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(content)
	if error != OK:
		push_error("JSON Parse Error in save file: %s" % json.get_error_message())
		return false
	
	var data: Dictionary = json.data
	if not data is Dictionary:
		return false
	
	if data.has("systems"):
		ShipSystemManager.import_save_data(data["systems"])
	
	if data.has("missions"):
		MissionManager.import_save_data(data["missions"])
	
	if environmental_mgr != null and data.has("environment") and environmental_mgr.has_method("import_save_data"):
		environmental_mgr.import_save_data(data["environment"])
	
	if get_node_or_null("/root/ShipState") != null:
		if data.has("ship_state"):
			var sdata: Dictionary = data["ship_state"]
			if not sdata.has("crisis_manager") and data.has("crisis"):
				sdata["crisis"] = data["crisis"]
			ShipState.import_save_data(sdata)
		elif data.has("crisis"):
			if ShipState.crisis_manager != null:
				ShipState.crisis_manager.deserialize(data["crisis"])
		else:
			if ShipState.crisis_manager != null:
				ShipState.crisis_manager.reset()
	
	if data.has("inventory") and get_node_or_null("/root/InventoryManager") != null:
		InventoryManager.import_save_data(data["inventory"])
	
	if data.has("doors"):
		var root := get_tree().root
		var door_aft = root.find_child("DoorAft", true, false)
		var door_fwd = root.find_child("DoorForward", true, false)
		var ddata: Dictionary = data["doors"]
		if door_aft and ddata.get("door_aft_open", false):
			door_aft.set_door_state(true, true)
		if door_fwd and ddata.get("door_fwd_open", false):
			door_fwd.set_door_state(true, true)
		if ddata.has("all_doors"):
			var all_doors_data: Dictionary = ddata["all_doors"]
			var all_doors = root.find_children("*", "BulkheadDoor", true, false)
			for d in all_doors:
				var key = d.device_id if d.device_id != "" else d.name
				if all_doors_data.has(key):
					d.import_save_data(all_doors_data[key])
	
	if data.has("lockers"):
		var root := get_tree().root
		var ldata: Dictionary = data["lockers"]
		var lockers = root.find_children("*", "StorageLocker", true, false)
		for l in lockers:
			if ldata.has(l.interactable_id):
				l.import_save_data(ldata[l.interactable_id])

	if data.has("multi_step_repairs"):
		var root := get_tree().root
		var rdata: Dictionary = data["multi_step_repairs"]
		var repairs = root.find_children("*", "MultiStepRepairPanel", true, false)
		for r in repairs:
			if rdata.has(r.device_id):
				r.import_save_data(rdata[r.device_id])

	if data.has("single_step_repairs"):
		var root := get_tree().root
		var srdata: Dictionary = data["single_step_repairs"]
		var single_repairs = root.find_children("*", "RepairPanel", true, false)
		for r in single_repairs:
			var key = r.device_id if r.device_id != "" else r.name
			if srdata.has(key) and r.has_method("import_save_data"):
				r.import_save_data(srdata[key])

	if data.has("airlocks"):
		var root := get_tree().root
		var adata: Dictionary = data["airlocks"]
		var airlocks = root.find_children("*", "AirlockController", true, false)
		for a in airlocks:
			if adata.has(a.name):
				a.import_save_data(adata[a.name])

	if data.has("salvage_crates"):
		var root := get_tree().root
		var cdata: Dictionary = data["salvage_crates"]
		var crates = root.find_children("*", "SalvageCrate", true, false)
		for c in crates:
			var key = c.device_id if c.device_id != "" else c.name
			if cdata.has(key):
				c.import_save_data(cdata[key])

	if data.has("hull_breach_seals"):
		var root := get_tree().root
		var bdata: Dictionary = data["hull_breach_seals"]
		var breaches = root.find_children("*", "HullBreachSeal", true, false)
		for b in breaches:
			var key = b.device_id if b.device_id != "" else b.name
			if bdata.has(key):
				b.import_save_data(bdata[key])

	var root_for_dp := get_tree().root
	var dpdata: Dictionary = data.get("datapads", {}) if data.get("datapads", {}) is Dictionary else {}
	var datapads = root_for_dp.find_children("*", "DatapadPickup", true, false)
	for dp in datapads:
		var key = dp.datapad_id if dp.datapad_id != "" else dp.name
		if dpdata.has(key):
			dp.import_save_data(dpdata[key])
		else:
			var col: bool = MissionManager.is_datapad_collected(dp.datapad_id)
			var dec: bool = MissionManager.is_datapad_decrypted(dp.datapad_id) if col else (not dp.is_encrypted)
			dp.import_save_data({
				"is_collected": col,
				"is_decrypted": dec
			})


	
	if data.has("game_mode"):
		set_game_mode(str(data["game_mode"]))
	if data.has("look_mode"):
		set_look_mode(str(data["look_mode"]))

	if player != null and is_instance_valid(player) and data.has("player"):
		var pdata: Dictionary = data["player"]
		player.global_position = Vector3(
			float(pdata.get("pos_x", player.global_position.x)),
			float(pdata.get("pos_y", player.global_position.y)),
			float(pdata.get("pos_z", player.global_position.z))
		)
		player.rotation.y = float(pdata.get("rot_y", player.rotation.y))
	
	return true

func delete_save() -> void:
	if has_save_file():
		DirAccess.remove_absolute(SAVE_PATH)

func get_save_summary() -> Dictionary:
	if not has_save_file():
		return {}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	
	var content := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(content) == OK and json.data is Dictionary:
		return json.data
	return {}

func save_settings() -> void:
	var settings := {
		"mouse_sensitivity": mouse_sensitivity,
		"master_volume": master_volume,
		"look_mode": look_mode,
		"game_mode": game_mode
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(settings))
		file.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var content := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(content) == OK and json.data is Dictionary:
		mouse_sensitivity = float(json.data.get("mouse_sensitivity", 0.002))
		master_volume = float(json.data.get("master_volume", 1.0))
		look_mode = str(json.data.get("look_mode", "mouse"))
		game_mode = str(json.data.get("game_mode", "logical"))
		AudioManager.set_volume(master_volume)
		look_mode_changed.emit(look_mode)
		game_mode_changed.emit(game_mode)
