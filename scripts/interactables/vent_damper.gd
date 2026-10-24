class_name VentDamper
extends Interactable

# Atmospheric Vent Damper Interactable for ORBITAL: The Last Engineer
# Allows manual or motorized throttling of air circulation to isolate compartments.

@export var compartment_id: String = "engineering_bay"
@export var damper_name: String = "Atmospheric Vent Damper"
@export var device_id: String = ""
@export var is_open: bool = true

@onready var indicator_mesh: MeshInstance3D = get_node_or_null("StatusLED")
@onready var indicator_light: OmniLight3D = get_node_or_null("StatusLight")
@onready var louvers_node: Node3D = get_node_or_null("Louvers")

var _mat_open: StandardMaterial3D
var _mat_closed: StandardMaterial3D

func _ready() -> void:
	super._ready()
	if device_id.is_empty():
		var short_id := "eng"
		if compartment_id == "corridors": short_id = "corr"
		elif compartment_id == "life_support": short_id = "ls"
		elif compartment_id == "bridge": short_id = "bridge"
		device_id = "vent_damper_" + short_id
	_create_materials()
	_update_visuals()

func _exit_tree() -> void:
	if indicator_mesh != null:
		indicator_mesh.material_override = null

func _create_materials() -> void:
	_mat_open = StandardMaterial3D.new()
	_mat_open.albedo_color = Color(0.2, 0.8, 1.0)
	_mat_open.emission_enabled = true
	_mat_open.emission = Color(0.2, 0.8, 1.0)
	_mat_open.emission_energy_multiplier = 1.8
	
	_mat_closed = StandardMaterial3D.new()
	_mat_closed.albedo_color = Color(1.0, 0.6, 0.1)
	_mat_closed.emission_enabled = true
	_mat_closed.emission = Color(1.0, 0.6, 0.1)
	_mat_closed.emission_energy_multiplier = 1.8

func get_prompt() -> String:
	var state_txt := "Close" if is_open else "Open"
	return "[E / Enter] %s %s" % [state_txt, damper_name]

func _on_interacted(player: Node) -> void:
	is_open = not is_open
	if AudioManager != null:
		AudioManager.play_sfx("door")
	
	var env_mgr = EnvironmentalManager.instance if ("instance" in EnvironmentalManager and EnvironmentalManager.instance != null) else (get_tree().root.find_child("EnvironmentalManager", true, false) if is_inside_tree() else null)
	if env_mgr != null and env_mgr.has_method("set_vent_damper"):
		env_mgr.set_vent_damper(compartment_id, is_open)
	
	_update_visuals()
	
	var msg := "%s: %s [ISOLATION %s]" % [
		damper_name,
		"OPEN (VENTILATING)" if is_open else "CLOSED (ISOLATED)",
		"OFF" if is_open else "ACTIVE"
	]
	if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
		player.hud.show_notification(msg, 3.5)

func _update_visuals() -> void:
	if indicator_mesh != null:
		indicator_mesh.material_override = _mat_open if is_open else _mat_closed
	if indicator_light != null:
		indicator_light.light_color = Color(0.2, 0.8, 1.0) if is_open else Color(1.0, 0.6, 0.1)
		indicator_light.light_energy = 0.8
	if louvers_node != null:
		louvers_node.rotation_degrees.x = 0.0 if is_open else 75.0
