class_name EmergencyValve
extends Interactable

# Emergency Mechanical Valve Interactable for ORBITAL: The Last Engineer
# Handwheel valve used for physical resolution of Pressure Leaks and Thermal Runaway.

@export var valve_type: String = "pressure" # "pressure" or "cooling"
@export var valve_name: String = "Emergency Isolation Valve"
@export var device_id: String = ""

@onready var wheel_node: Node3D = get_node_or_null("Handwheel")
@onready var indicator_mesh: MeshInstance3D = get_node_or_null("StatusLED")
@onready var indicator_light: OmniLight3D = get_node_or_null("StatusLight")

var _mat_nominal: StandardMaterial3D
var _mat_alarm: StandardMaterial3D
var _is_fault_active: bool = false
var _last_visual_state: int = -1

func _ready() -> void:
	super._ready()
	if device_id.is_empty():
		device_id = "pressure_relief_valve" if valve_type == "pressure" else "radiator_bypass_valve"
	_create_materials()
	_update_visuals()

func _exit_tree() -> void:
	if indicator_mesh != null:
		indicator_mesh.material_override = null

func _create_materials() -> void:
	_mat_nominal = StandardMaterial3D.new()
	_mat_nominal.albedo_color = Color(0.2, 0.9, 0.4)
	_mat_nominal.emission_enabled = true
	_mat_nominal.emission = Color(0.2, 0.9, 0.4)
	_mat_nominal.emission_energy_multiplier = 1.8
	
	_mat_alarm = StandardMaterial3D.new()
	_mat_alarm.albedo_color = Color(1.0, 0.2, 0.1)
	_mat_alarm.emission_enabled = true
	_mat_alarm.emission = Color(1.0, 0.2, 0.1)
	_mat_alarm.emission_energy_multiplier = 2.5

func check_fault_active() -> bool:
	if valve_type == "poison_gas" or valve_type == "toxic_gas":
		if ShipState != null and "crisis_manager" in ShipState and ShipState.crisis_manager != null:
			return not ShipState.crisis_manager.is_creature_eliminated
		return true
	if device_id == "medical_oxygen_booster" or valve_type == "oxygen_booster":
		if EnvironmentalManager != null and "instance" in EnvironmentalManager and EnvironmentalManager.instance != null:
			if EnvironmentalManager.instance.poison_environment_active:
				return true
	if ShipState == null or not ("active_faults" in ShipState):
		return false
	if valve_type == "pressure":
		return ShipState.active_faults.has("CABIN_PRESSURE_LEAK")
	elif valve_type == "cooling":
		return ShipState.active_faults.has("THERMAL_RUNAWAY")
	return false

func get_prompt() -> String:
	_is_fault_active = check_fault_active()
	if valve_type == "poison_gas" or valve_type == "toxic_gas":
		var target := "airlock_chamber"
		if ShipState != null and "crisis_manager" in ShipState and ShipState.crisis_manager != null:
			target = ShipState.crisis_manager.target_chamber_id
		if _is_fault_active:
			return "[E] Open %s (FLOOD %s WITH POISONOUS DECONTAMINATION GAS / Release Red Poison Gas)" % [valve_name, target]
		else:
			return "[Purged] %s (Decontamination Purge Completed - Creature PURGED)" % valve_name
	if device_id == "medical_oxygen_booster" or valve_type == "oxygen_booster":
		if EnvironmentalManager != null and "instance" in EnvironmentalManager and EnvironmentalManager.instance != null:
			if EnvironmentalManager.instance.poison_environment_active:
				return "[E] Turn %s (Normalize & Stabilize Oxygen)" % valve_name
			elif EnvironmentalManager.instance.medbay_poison_recovery_completed:
				return "[Normalized] %s (100%% O2 Stable)" % valve_name
	if _is_fault_active:
		if valve_type == "pressure":
			return "[E] Rotate %s (Seal Cabin Leak)" % valve_name
		else:
			return "[E] Reset %s (Dump Excess Heat)" % valve_name
	return "[E] Inspect %s" % valve_name

func _on_interacted(player: Node) -> void:
	_is_fault_active = check_fault_active()
	
	if wheel_node != null and is_inside_tree():
		var tw := create_tween()
		if tw != null:
			tw.tween_property(wheel_node, "rotation_degrees:z", wheel_node.rotation_degrees.z + 180.0, 0.4)
	
	if ShipState != null and not device_id.is_empty():
		var vdev = ShipState.get_device(device_id)
		if vdev != null and vdev.has_method("repair"):
			vdev.repair(100.0)
	
	if valve_type == "poison_gas" or valve_type == "toxic_gas":
		var st = get_tree().root.find_child("AlienStalker", true, false) if is_inside_tree() else null
		if st != null and st.has_method("eliminate"):
			st.eliminate()
		if ShipState != null and "crisis_manager" in ShipState and ShipState.crisis_manager != null:
			var comp_id: String = get_parent().name.to_snake_case() if get_parent() != null else "airlock_chamber"
			if comp_id.is_empty() or comp_id == "root":
				comp_id = "airlock_chamber"
			ShipState.crisis_manager.execute_poison_gas_purge(comp_id)
		if EnvironmentalManager != null and "instance" in EnvironmentalManager and EnvironmentalManager.instance != null:
			if EnvironmentalManager.instance.has_method("activate_poison_gas_environment"):
				EnvironmentalManager.instance.activate_poison_gas_environment()
		if AudioManager != null:
			AudioManager.play_sfx("gas_hiss")
			AudioManager.play_sfx("creature_roar")
		var msg := "RED POISON GAS RELEASED! Alien killed! Run to Medical Chamber & turn the Oxygen Booster Valve (-5% O2 / 5s)!"
		var hud = (player.hud if (player != null and "hud" in player and player.hud != null) else (get_tree().root.find_child("HUD", true, false) if is_inside_tree() else null))
		if hud != null and hud.has_method("show_notification"):
			hud.show_notification(msg, 4.5)
		if has_node("/root/MissionManager"):
			get_node("/root/MissionManager")._broadcast_current_objective()
		_update_visuals()
		return
	
	if device_id == "medical_oxygen_booster" or valve_type == "oxygen_booster":
		var env_mgr_med = EnvironmentalManager.instance if ("instance" in EnvironmentalManager and EnvironmentalManager.instance != null) else (get_tree().root.find_child("EnvironmentalManager", true, false) if is_inside_tree() else null)
		if env_mgr_med != null and env_mgr_med.has_method("normalize_poison_oxygen_in_medbay") and (env_mgr_med.poison_environment_active or not env_mgr_med.medbay_poison_recovery_completed):
			env_mgr_med.normalize_poison_oxygen_in_medbay()
			if AudioManager != null:
				AudioManager.play_sfx("gas_hiss")
				AudioManager.play_sfx("repair")
			var msg_med := "OXYGEN NORMALIZED & STABILIZED (100% O2)! Final Task: Run to the Command Bridge & flip the Departure Switch!"
			var hud_med = (player.hud if (player != null and "hud" in player and player.hud != null) else (get_tree().root.find_child("HUD", true, false) if is_inside_tree() else null))
			if hud_med != null and hud_med.has_method("show_notification"):
				hud_med.show_notification(msg_med, 5.0)
			if has_node("/root/MissionManager"):
				get_node("/root/MissionManager")._broadcast_current_objective()
			_update_visuals()
			return
	
	if _is_fault_active:
		var env_mgr = EnvironmentalManager.instance if ("instance" in EnvironmentalManager and EnvironmentalManager.instance != null) else (get_tree().root.find_child("EnvironmentalManager", true, false) if is_inside_tree() else null)
		
		if valve_type == "pressure":
			if ShipState != null:
				ShipState.resolve_fault("CABIN_PRESSURE_LEAK")
				var dev = ShipState.get_device("atmospheric_pressure_regulator")
				if dev != null and dev.has_method("repair"):
					dev.repair(100.0)
			if env_mgr != null and env_mgr.has_method("trigger_pressurization_override"):
				env_mgr.trigger_pressurization_override()
			if AudioManager != null:
				AudioManager.play_sfx("repair")
			
			var msg := "Pressure Isolation Valve CLOSED. Atmospheric leak halted."
			if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
				player.hud.show_notification(msg, 4.0)
		else:
			if ShipState != null:
				ShipState.resolve_fault("THERMAL_RUNAWAY")
				var dev = ShipState.get_device("climate_thermal_exchanger")
				if dev != null and dev.has_method("repair"):
					dev.repair(100.0)
			if env_mgr != null and env_mgr.has_method("trigger_thermal_reset"):
				env_mgr.trigger_thermal_reset()
			if AudioManager != null:
				AudioManager.play_sfx("repair")
			
			var msg := "Radiator Cooling Bypass RESET. Thermal runaway disengaged."
			if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
				player.hud.show_notification(msg, 4.0)
		
		_update_visuals()
	else:
		if AudioManager != null:
			AudioManager.play_sfx("click")
		var msg := "%s verified. Flow mechanics operating normally." % valve_name
		if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
			player.hud.show_notification(msg, 3.0)

func _process(_delta: float) -> void:
	_update_visuals()

func _update_visuals() -> void:
	var active := check_fault_active()
	var st: int = 1 if active else 0
	if st == _last_visual_state:
		return
	_last_visual_state = st
	if indicator_mesh != null:
		indicator_mesh.material_override = _mat_alarm if active else _mat_nominal
	if indicator_light != null:
		indicator_light.light_color = Color(1.0, 0.2, 0.1) if active else Color(0.2, 0.9, 0.4)
		indicator_light.light_energy = 1.2 if active else 0.8
