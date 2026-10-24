class_name ScrubberPanel
extends Interactable

# CO2 Scrubber Service Panel Interactable for ORBITAL: The Last Engineer
# Provides physical maintenance / cartridge replacement for the Life Support CO2 scrubber columns.

@export var panel_name: String = "CO2 Scrubber Service Panel"
@export var device_id: String = "life_support_scrubber"

@onready var indicator_mesh: MeshInstance3D = get_node_or_null("StatusLED")
@onready var indicator_light: OmniLight3D = get_node_or_null("StatusLight")
@onready var cartridge_mesh: MeshInstance3D = get_node_or_null("CartridgeMesh")

var _mat_nominal: StandardMaterial3D
var _mat_saturated: StandardMaterial3D

func _ready() -> void:
	super._ready()
	_create_materials()
	_update_visuals()

func _exit_tree() -> void:
	if indicator_mesh != null:
		indicator_mesh.material_override = null

func _create_materials() -> void:
	_mat_nominal = StandardMaterial3D.new()
	_mat_nominal.albedo_color = Color(0.1, 0.8, 0.7)
	_mat_nominal.emission_enabled = true
	_mat_nominal.emission = Color(0.1, 0.8, 0.7)
	_mat_nominal.emission_energy_multiplier = 1.8
	
	_mat_saturated = StandardMaterial3D.new()
	_mat_saturated.albedo_color = Color(1.0, 0.7, 0.1)
	_mat_saturated.emission_enabled = true
	_mat_saturated.emission = Color(1.0, 0.7, 0.1)
	_mat_saturated.emission_energy_multiplier = 2.2

func is_saturated() -> bool:
	if ShipState != null and "active_faults" in ShipState:
		return ShipState.active_faults.has("CO2_SCRUBBER_SATURATION")
	return false

func get_prompt() -> String:
	if is_saturated():
		return "[E / Enter] Flush & Replace Saturated CO2 Scrubber Cartridge"
	return "[E / Enter] Inspect %s (Lithium-Hydroxide Bed Nominal)" % panel_name

func _on_interacted(player: Node) -> void:
	if is_saturated():
		if ShipState != null:
			ShipState.resolve_fault("CO2_SCRUBBER_SATURATION")
			var dev = ShipState.get_device("life_support_scrubber")
			if dev != null and dev.has_method("repair"):
				dev.repair(100.0)
		
		var env_mgr = EnvironmentalManager.instance if ("instance" in EnvironmentalManager and EnvironmentalManager.instance != null) else (get_tree().root.find_child("EnvironmentalManager", true, false) if is_inside_tree() else null)
		if env_mgr != null and env_mgr.has_method("trigger_co2_purge"):
			env_mgr.trigger_co2_purge()
		
		if AudioManager != null:
			AudioManager.play_sfx("repair")
		
		_update_visuals()
		
		var msg := "CO2 Scrubber Cartridge replaced. Chemical absorption restored."
		if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
			player.hud.show_notification(msg, 4.0)
	else:
		if AudioManager != null:
			AudioManager.play_sfx("click")
		var msg := "Scrubber Column Status: 100% capacity. CO2 absorption nominal."
		if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
			player.hud.show_notification(msg, 3.5)

func _process(_delta: float) -> void:
	_update_visuals()

func _update_visuals() -> void:
	var saturated := is_saturated()
	if indicator_mesh != null:
		indicator_mesh.material_override = _mat_saturated if saturated else _mat_nominal
	if indicator_light != null:
		indicator_light.light_color = Color(1.0, 0.7, 0.1) if saturated else Color(0.1, 0.8, 0.7)
		indicator_light.light_energy = 1.2 if saturated else 0.8
