class_name BreakerSwitch
extends Interactable

# Breaker Switch interactable for ORBITAL: The Last Engineer
# Used for toggling generator, bus distribution, and departure sequence.

@export var switch_target: String = "primary_power"
@export var label_name: String = "Generator Breaker"
@export var is_on: bool = false

@onready var handle_node: Node3D = get_node_or_null("Handle")
@onready var indicator_mesh: MeshInstance3D = get_node_or_null("IndicatorLED")
@onready var indicator_light: OmniLight3D = get_node_or_null("IndicatorLight")

var _mat_on: StandardMaterial3D
var _mat_off: StandardMaterial3D

func _ready() -> void:
	super._ready()
	_create_materials()
	sync_state()
	ShipSystemManager.system_state_changed.connect(_on_system_state_changed)

func sync_state() -> void:
	match switch_target:
		"primary_power":
			is_on = ShipSystemManager.generator_breaker_closed
		"power_distribution":
			is_on = ShipSystemManager.bus_relay_closed
		"propulsion":
			is_on = ShipSystemManager.propulsion_primed
	_update_visuals()

func _on_system_state_changed(_sys_id: String, _old: int, _new: int) -> void:
	sync_state()

func _create_materials() -> void:
	_mat_on = StandardMaterial3D.new()
	_mat_on.albedo_color = Color(0.1, 0.9, 0.2)
	_mat_on.emission_enabled = true
	_mat_on.emission = Color(0.2, 1.0, 0.3)
	_mat_on.emission_energy_multiplier = 2.0
	
	_mat_off = StandardMaterial3D.new()
	_mat_off.albedo_color = Color(0.9, 0.1, 0.1)
	_mat_off.emission_enabled = true
	_mat_off.emission = Color(1.0, 0.1, 0.1)
	_mat_off.emission_energy_multiplier = 1.5

func get_prompt() -> String:
	var state_txt := "Open" if is_on else "Close"
	return "[E / Enter] %s %s" % [state_txt, label_name]

func _on_interacted(_player: Node) -> void:
	match switch_target:
		"primary_power":
			var new_state := not is_on
			var res := ShipSystemManager.set_generator_breaker(new_state)
			if res.get("ok", false):
				is_on = new_state
			sync_state()
		"power_distribution":
			var new_state := not is_on
			var res := ShipSystemManager.set_power_distribution(new_state)
			if res.get("ok", false):
				is_on = new_state
			else:
				# Show failure feedback
				is_on = false
			sync_state()
		"propulsion":
			var res := ShipSystemManager.engage_propulsion()
			if res.get("ok", false):
				is_on = true
				sync_state()
				# Transition to mission complete after short delay
				get_tree().create_timer(1.5).timeout.connect(func():
					get_tree().change_scene_to_file("res://scenes/ui/mission_complete.tscn")
				)
			else:
				is_on = false
				sync_state()

func _update_visuals() -> void:
	if handle_node != null:
		handle_node.rotation_degrees.z = 28.0 if is_on else -28.0
	
	if indicator_mesh != null:
		indicator_mesh.material_override = _mat_on if is_on else _mat_off
	
	if indicator_light != null:
		indicator_light.light_color = Color(0.2, 1.0, 0.3) if is_on else Color(1.0, 0.2, 0.2)
		indicator_light.light_energy = 1.0 if is_on else 0.5
