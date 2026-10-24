class_name EnvironmentalSensor
extends Interactable

# Environmental Sensor Interactable for ORBITAL: The Last Engineer
# Wall-mounted sensor displaying real-time atmospheric telemetry for its compartment.

@export var compartment_id: String = "engineering_bay"
@export var sensor_name: String = "Atmospheric Sensor"
@export var device_id: String = ""

@onready var indicator_light: OmniLight3D = get_node_or_null("StatusLight")
@onready var indicator_mesh: MeshInstance3D = get_node_or_null("StatusLED")

var _mat_nominal: StandardMaterial3D
var _mat_warning: StandardMaterial3D
var _mat_critical: StandardMaterial3D
var _mat_offline: StandardMaterial3D

func _ready() -> void:
	super._ready()
	if device_id.is_empty():
		var short_id := "eng"
		if compartment_id == "corridors": short_id = "corr"
		elif compartment_id == "life_support": short_id = "ls"
		elif compartment_id == "bridge": short_id = "bridge"
		device_id = "env_sensor_" + short_id
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
	
	_mat_warning = StandardMaterial3D.new()
	_mat_warning.albedo_color = Color(1.0, 0.8, 0.2)
	_mat_warning.emission_enabled = true
	_mat_warning.emission = Color(1.0, 0.8, 0.2)
	_mat_warning.emission_energy_multiplier = 2.0
	
	_mat_critical = StandardMaterial3D.new()
	_mat_critical.albedo_color = Color(1.0, 0.2, 0.1)
	_mat_critical.emission_enabled = true
	_mat_critical.emission = Color(1.0, 0.2, 0.1)
	_mat_critical.emission_energy_multiplier = 2.5
	
	_mat_offline = StandardMaterial3D.new()
	_mat_offline.albedo_color = Color(0.3, 0.3, 0.3)
	_mat_offline.emission_enabled = false

func is_powered() -> bool:
	if ShipSystemManager != null:
		return ShipSystemManager.is_system_online("power_distribution")
	return true

func get_telemetry() -> Dictionary:
	var env_mgr = EnvironmentalManager.instance if ("instance" in EnvironmentalManager and EnvironmentalManager.instance != null) else (get_tree().root.find_child("EnvironmentalManager", true, false) if is_inside_tree() else null)
	if env_mgr != null and env_mgr.has_method("get_compartment_atmosphere"):
		return env_mgr.get_compartment_atmosphere(compartment_id)
	return {
		"o2_level": 100.0,
		"co2_ppm": 420.0,
		"temperature": 294.15,
		"pressure": 101.3
	}

func get_prompt() -> String:
	if not is_powered():
		return "[Offline] %s (No Bus Power)" % sensor_name
	
	var data := get_telemetry()
	var o2 := int(data.get("o2_level", 100.0))
	var co2 := int(data.get("co2_ppm", 420.0))
	var temp_c := float(data.get("temperature", 294.15)) - 273.15
	var press := float(data.get("pressure", 101.3))
	
	return "[E / Enter] Read %s: O2:%d%% | CO2:%dppm | %.1f°C | %.1fkPa" % [
		sensor_name, o2, co2, temp_c, press
	]

func _on_interacted(player: Node) -> void:
	if not is_powered():
		if AudioManager != null:
			AudioManager.play_sfx("denied")
		return
	
	if AudioManager != null:
		AudioManager.play_sfx("click")
	
	var data := get_telemetry()
	var o2: float = float(data.get("o2_level", 100.0))
	var co2: float = float(data.get("co2_ppm", 420.0))
	var temp_c: float = float(data.get("temperature", 294.15)) - 273.15
	var press: float = float(data.get("pressure", 101.3))
	
	var status_str := "NOMINAL"
	if o2 < 60.0 or co2 > 2500.0 or temp_c > 38.0 or temp_c < 10.0 or press < 75.0:
		status_str = "HAZARD / CRITICAL"
	elif o2 < 80.0 or co2 > 1200.0 or temp_c > 30.0 or temp_c < 16.0 or press < 90.0:
		status_str = "CAUTION"
	
	var msg := "[%s] %s // O2: %.1f%% | CO2: %d ppm | TEMP: %.1f°C | PRESS: %.1f kPa" % [
		sensor_name.to_upper(), status_str, o2, int(co2), temp_c, press
	]
	
	if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
		player.hud.show_notification(msg, 5.0)

func _process(_delta: float) -> void:
	_update_visuals()

func _update_visuals() -> void:
	if not is_powered():
		if indicator_mesh != null:
			indicator_mesh.material_override = _mat_offline
		if indicator_light != null:
			indicator_light.light_energy = 0.0
		return
	
	var data := get_telemetry()
	var o2: float = float(data.get("o2_level", 100.0))
	var co2: float = float(data.get("co2_ppm", 420.0))
	var temp: float = float(data.get("temperature", 294.15))
	var press: float = float(data.get("pressure", 101.3))
	
	var mat := _mat_nominal
	var col := Color(0.2, 0.9, 0.4)
	
	if o2 < 60.0 or co2 > 2500.0 or temp > 311.15 or temp < 283.15 or press < 75.0:
		mat = _mat_critical
		col = Color(1.0, 0.2, 0.1)
	elif o2 < 80.0 or co2 > 1200.0 or temp > 303.15 or temp < 289.15 or press < 90.0:
		mat = _mat_warning
		col = Color(1.0, 0.8, 0.2)
	
	if indicator_mesh != null:
		indicator_mesh.material_override = mat
	if indicator_light != null:
		indicator_light.light_color = col
		indicator_light.light_energy = 1.0
