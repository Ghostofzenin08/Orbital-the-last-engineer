class_name RepairPanel
extends Interactable

# Repair Panel interactable for ORBITAL: The Last Engineer
# Used for replacing faulty fuses and couplers (Life Support coolant manifold).

@export var device_id: String = ""
@export var panel_title: String = "Coupler Manifold"
@export var required_item: String = "coolant_coupler"
@export var component_name: String = "Coolant Coupler"
@export var is_repaired: bool = false

@onready var indicator_mesh: MeshInstance3D = get_node_or_null("IndicatorLED")
@onready var indicator_light: OmniLight3D = get_node_or_null("IndicatorLight")
@onready var fuse_socket_mesh: MeshInstance3D = get_node_or_null("SocketMesh")

var _mat_repaired: StandardMaterial3D
var _mat_faulty: StandardMaterial3D

func _ready() -> void:
	super._ready()
	_create_materials()
	_sync_state()
	ShipSystemManager.system_state_changed.connect(_on_system_state_changed)
	ShipSystemManager.system_fault_cleared.connect(_on_system_fault_cleared)

func _sync_state() -> void:
	if device_id.is_empty():
		if ShipSystemManager.coolant_coupler_installed:
			is_repaired = true
	else:
		if has_node("/root/ShipState"):
			var ss = get_node("/root/ShipState")
			var dev = ss.get_device(device_id)
			if dev != null and dev.health >= 90.0 and dev.active_faults.is_empty():
				is_repaired = true
	_update_visuals()

func _on_system_state_changed(sys_id: String, _old: int, _new: int) -> void:
	if sys_id == "life_support":
		_sync_state()

func _on_system_fault_cleared(sys_id: String) -> void:
	if sys_id == "life_support":
		_sync_state()

func _create_materials() -> void:
	_mat_repaired = StandardMaterial3D.new()
	_mat_repaired.albedo_color = Color(0.1, 0.9, 0.3)
	_mat_repaired.emission_enabled = true
	_mat_repaired.emission = Color(0.2, 1.0, 0.4)
	_mat_repaired.emission_energy_multiplier = 2.0
	
	_mat_faulty = StandardMaterial3D.new()
	_mat_faulty.albedo_color = Color(0.9, 0.2, 0.1)
	_mat_faulty.emission_enabled = true
	_mat_faulty.emission = Color(1.0, 0.2, 0.1)
	_mat_faulty.emission_energy_multiplier = 1.5

func get_prompt() -> String:
	if is_repaired:
		return "[Repaired] %s Operational" % panel_title
	if MissionManager.has_item(required_item):
		return "[E / Enter] Install Spare %s" % component_name
	return "[E / Enter] Missing %s (Check Engineering Storage)" % component_name

func can_interact(_player: Node) -> bool:
	return not is_repaired

func _on_interacted(_player: Node) -> void:
	if is_repaired:
		return
	
	if not MissionManager.has_item(required_item):
		AudioManager.play_sfx("denied")
		return
	
	MissionManager.remove_inventory_item(required_item)
	if device_id.is_empty():
		ShipSystemManager.install_coolant_coupler()
	else:
		if has_node("/root/ShipState"):
			var ss = get_node("/root/ShipState")
			var dev = ss.get_device(device_id)
			if dev != null and dev.has_method("repair"):
				dev.repair(100.0)
	AudioManager.play_sfx("repair")
	is_repaired = true
	_update_visuals()

func _update_visuals() -> void:
	if indicator_mesh != null:
		indicator_mesh.material_override = _mat_repaired if is_repaired else _mat_faulty
	
	if indicator_light != null:
		indicator_light.light_color = Color(0.2, 1.0, 0.4) if is_repaired else Color(1.0, 0.2, 0.1)
		indicator_light.light_energy = 1.2 if is_repaired else 0.8
	
	if fuse_socket_mesh != null:
		fuse_socket_mesh.visible = is_repaired

func export_save_data() -> Dictionary:
	return {
		"is_repaired": is_repaired,
		"device_id": device_id
	}

func import_save_data(data: Dictionary) -> void:
	is_repaired = bool(data.get("is_repaired", false))
	_update_visuals()
