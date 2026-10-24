class_name MultiStepRepairPanel
extends Interactable

# Deepened Multi-Step Physical Repair Device for ORBITAL: The Last Engineer
# Implements realistic engineering repair:
# 1. Diagnose with Diagnostic Scanner
# 2. Unclamp housing with Multitool
# 3. Insert replacement consumable
# 4. Calibrate with Multitool
# 5. Run diagnostic system test & energize

signal stage_advanced(new_stage: int, stage_name: String)
signal repair_completed(device_id: String)

enum Stage {
	DIAGNOSE = 0,
	UNCLAMP = 1,
	REPLACE = 2,
	CALIBRATE = 3,
	TEST = 4,
	COMPLETED = 5
}

@export var panel_title: String = "Auxiliary Power Junction"
@export var device_id: String = "training_power_conduit"
@export var associated_fault_id: String = "CONDUIT_BLOWN_FUSE"
@export var required_item: String = "spare_fuse"
@export var component_name: String = "Spare Fuse Pack"
@export var action_name: String = "Calibrate Circuit"
@export var required_multitool_mode: String = "CALIBRATE"
@export var current_stage: int = Stage.DIAGNOSE
@export var is_repaired: bool = false

@onready var indicator_led: MeshInstance3D = get_node_or_null("IndicatorLED")
@onready var indicator_light: OmniLight3D = get_node_or_null("IndicatorLight")
@onready var cover_mesh: MeshInstance3D = get_node_or_null("CoverMesh")
@onready var part_mesh: MeshInstance3D = get_node_or_null("PartMesh")

var _mat_repaired: StandardMaterial3D
var _mat_working: StandardMaterial3D
var _mat_faulty: StandardMaterial3D

func _ready() -> void:
	super._ready()
	_create_materials()
	_update_visuals()

func _create_materials() -> void:
	_mat_repaired = StandardMaterial3D.new()
	_mat_repaired.albedo_color = Color(0.1, 0.9, 0.3)
	_mat_repaired.emission_enabled = true
	_mat_repaired.emission = Color(0.2, 1.0, 0.4)
	_mat_repaired.emission_energy_multiplier = 2.0

	_mat_working = StandardMaterial3D.new()
	_mat_working.albedo_color = Color(0.2, 0.7, 1.0)
	_mat_working.emission_enabled = true
	_mat_working.emission = Color(0.3, 0.8, 1.0)
	_mat_working.emission_energy_multiplier = 1.6

	_mat_faulty = StandardMaterial3D.new()
	_mat_faulty.albedo_color = Color(0.9, 0.25, 0.1)
	_mat_faulty.emission_enabled = true
	_mat_faulty.emission = Color(1.0, 0.3, 0.1)
	_mat_faulty.emission_energy_multiplier = 1.8

func get_stage_name() -> String:
	match current_stage:
		Stage.DIAGNOSE:
			return "DIAGNOSE"
		Stage.UNCLAMP:
			return "UNCLAMP"
		Stage.REPLACE:
			return "REPLACE"
		Stage.CALIBRATE:
			return "CALIBRATE"
		Stage.TEST:
			return "TEST"
		Stage.COMPLETED:
			return "COMPLETED"
		_:
			return "UNKNOWN"

func get_prompt() -> String:
	if is_repaired or current_stage >= Stage.COMPLETED:
		return "[Operational] %s Tested & Restored" % panel_title
	
	var equipped := InventoryManager.get_equipped_item_id()
	
	match current_stage:
		Stage.DIAGNOSE:
			if equipped == "diagnostic_scanner":
				return "[E / Enter] Scan with Diagnostic Scanner [1]"
			return "[E / Enter] Diagnostic Scan Required (Equip Scanner [1])"
		
		Stage.UNCLAMP:
			if equipped == "multitool":
				return "[E / Enter] Unclamp Housing with Multitool [2]"
			return "[E / Enter] Unclamp Housing (Equip Multitool [2])"
		
		Stage.REPLACE:
			if InventoryManager.has_item(required_item):
				return "[E / Enter] Insert %s [3]" % component_name
			return "[E / Enter] Missing %s (Check Locker or Workbench)" % component_name
		
		Stage.CALIBRATE:
			var cur_mode := InventoryManager.get_multitool_mode()
			if equipped == "multitool":
				if required_multitool_mode != "" and cur_mode != required_multitool_mode:
					return "[E / Enter] Switch Multitool to %s Mode (Current: %s)" % [required_multitool_mode, cur_mode]
				return "[E / Enter] %s with Multitool [2]" % action_name
			return "[E / Enter] %s (Equip Multitool [2])" % action_name
		
		Stage.TEST:
			return "[E / Enter] Run System Diagnostic Test"
		
		_:
			return "[E / Enter] Inspect %s" % panel_title

func can_interact(_player: Node) -> bool:
	return not is_repaired

func _on_interacted(player: Node) -> void:
	if is_repaired or current_stage >= Stage.COMPLETED:
		return
	
	var equipped := InventoryManager.get_equipped_item_id()
	
	match current_stage:
		Stage.DIAGNOSE:
			if equipped != "diagnostic_scanner":
				AudioManager.play_sfx("denied")
				_notify(player, "Tool Mismatch: Equip Diagnostic Scanner [1] to diagnose.")
				return
			
			var scan_res := InventoryManager.perform_diagnostic_scan(self)
			if not scan_res.get("ok", false):
				_notify(player, str(scan_res.get("reason", "Scan Failed")))
				return
			
			current_stage = Stage.UNCLAMP
			_update_visuals()
			stage_advanced.emit(current_stage, get_stage_name())
			_notify(player, "Diagnosis Complete: Fault verified. Unclamp housing with Multitool [2].")
		
		Stage.UNCLAMP:
			if equipped != "multitool":
				AudioManager.play_sfx("denied")
				_notify(player, "Tool Mismatch: Equip Multitool [2] to unbolt housing clamps.")
				return
			
			InventoryManager.perform_multitool_action("UNCLAMP", self)
			current_stage = Stage.REPLACE
			_update_visuals()
			stage_advanced.emit(current_stage, get_stage_name())
			_notify(player, "Housing Unclamped. Insert replacement %s." % component_name)
		
		Stage.REPLACE:
			if not InventoryManager.has_item(required_item):
				AudioManager.play_sfx("denied")
				_notify(player, "Missing %s! Retrieve from Supply Locker or Workbench." % component_name)
				return
			
			InventoryManager.remove_item(required_item, 1)
			AudioManager.play_sfx("click")
			current_stage = Stage.CALIBRATE
			_update_visuals()
			stage_advanced.emit(current_stage, get_stage_name())
			_notify(player, "%s Installed. %s with Multitool [2]." % [component_name, action_name])
		
		Stage.CALIBRATE:
			if equipped != "multitool":
				AudioManager.play_sfx("denied")
				_notify(player, "Tool Mismatch: Equip Multitool [2] to %s." % action_name.to_lower())
				return
			
			var cur_mode := InventoryManager.get_multitool_mode()
			if required_multitool_mode != "" and cur_mode != required_multitool_mode:
				AudioManager.play_sfx("denied")
				_notify(player, "Mode Mismatch: Switch Multitool to %s mode [2] / [Q] (Currently %s)." % [required_multitool_mode, cur_mode])
				return
			
			InventoryManager.perform_multitool_action(required_multitool_mode, self)
			current_stage = Stage.TEST
			_update_visuals()
			stage_advanced.emit(current_stage, get_stage_name())
			_notify(player, "%s complete. Run final diagnostic test." % action_name)
		
		Stage.TEST:
			is_repaired = true
			current_stage = Stage.COMPLETED
			AudioManager.play_sfx("repair")
			_update_visuals()
			
			# Resolve fault in ShipState
			var ship_state = get_node_or_null("/root/ShipState")
			if ship_state != null:
				if associated_fault_id != "":
					ship_state.resolve_fault(associated_fault_id)
				if device_id != "" and ship_state.devices.has(device_id):
					ship_state.devices[device_id].repair(100.0)
			
			stage_advanced.emit(current_stage, get_stage_name())
			repair_completed.emit(device_id)
			_notify(player, "%s Restored: ALL SYSTEMS NOMINAL!" % panel_title)

func get_diagnostic_telemetry() -> Dictionary:
	var integrity: float = 100.0 if is_repaired else (25.0 + current_stage * 15.0)
	var fault_list: Array[Dictionary] = []
	if not is_repaired and associated_fault_id != "":
		fault_list.append({
			"fault_id": associated_fault_id,
			"root_cause": "Component failure / broken circuit connection",
			"repair_steps": [
				"1. Diagnose root cause with Scanner [1]",
				"2. Unclamp housing with Multitool [2]",
				"3. Insert replacement " + component_name,
				"4. Calibrate with Multitool [2]",
				"5. Perform final system test"
			],
			"required_parts": [required_item],
			"escalation": "CRITICAL"
		})
	
	return {
		"target_name": panel_title,
		"device_id": device_id,
		"device_name": panel_title,
		"integrity": integrity,
		"power_draw": 0.5,
		"temperature_c": 22.5,
		"is_powered": true,
		"active_faults": fault_list,
		"repair_steps": [
			"Diagnose unit",
			"Unclamp housing",
			"Insert replacement part",
			"Calibrate circuit",
			"Run system test"
		],
		"current_stage": current_stage,
		"stage_name": get_stage_name(),
		"recommended_tool": "Diagnostic Scanner [1]" if current_stage == 0 else ("Multitool (%s Mode) [2]" % required_multitool_mode if current_stage == 3 else ("Multitool [2]" if current_stage == 1 else component_name))
	}

func _update_visuals() -> void:
	if is_repaired or current_stage >= Stage.COMPLETED:
		if indicator_led != null:
			indicator_led.material_override = _mat_repaired
		if indicator_light != null:
			indicator_light.light_color = Color(0.2, 1.0, 0.4)
			indicator_light.light_energy = 1.4
		if cover_mesh != null:
			cover_mesh.position.y = 0.6 # Closed
		if part_mesh != null:
			part_mesh.visible = true
	elif current_stage == Stage.DIAGNOSE:
		if indicator_led != null:
			indicator_led.material_override = _mat_faulty
		if indicator_light != null:
			indicator_light.light_color = Color(1.0, 0.25, 0.1)
			indicator_light.light_energy = 1.0
		if cover_mesh != null:
			cover_mesh.position.y = 0.6 # Closed
		if part_mesh != null:
			part_mesh.visible = false
	else:
		# In progress
		if indicator_led != null:
			indicator_led.material_override = _mat_working
		if indicator_light != null:
			indicator_light.light_color = Color(0.2, 0.7, 1.0)
			indicator_light.light_energy = 1.2
		if cover_mesh != null:
			cover_mesh.position.y = 0.9 # Unclamped / open
		if part_mesh != null:
			part_mesh.visible = current_stage >= Stage.CALIBRATE

func _notify(player: Node, msg: String) -> void:
	if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
		player.hud.show_notification(msg)
	elif get_tree() != null and get_tree().root != null:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud != null and hud.has_method("show_notification"):
			hud.show_notification(msg)

func export_save_data() -> Dictionary:
	return {
		"current_stage": current_stage,
		"is_repaired": is_repaired
	}

func import_save_data(data: Dictionary) -> void:
	current_stage = int(data.get("current_stage", Stage.DIAGNOSE))
	is_repaired = bool(data.get("is_repaired", false))
	_update_visuals()
