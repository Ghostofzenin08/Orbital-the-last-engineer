class_name AirlockController
extends Interactable

# Airlock Safety Interlock & Pressure Cycling Controller for ORBITAL: The Last Engineer
# Milestone 4: Dual-door hermetic interlock, vacuum pressure cycling, and warning lights.

signal cycle_started(target_state: String)
signal cycle_completed(new_state: String)

enum CycleState {
	IDLE,
	CYCLING_TO_EVA,
	CYCLING_TO_CABIN
}

@export var controller_name: String = "Airlock Cycle Controller"
@export var inner_door_path: NodePath
@export var outer_door_path: NodePath
@export var status_light_path: NodePath
@export var airlock_compartment_id: String = "airlock_chamber"
@export var cycle_duration: float = 3.0

var inner_door: BulkheadDoor = null
var outer_door: BulkheadDoor = null
var status_light: OmniLight3D = null

var cycle_state: CycleState = CycleState.IDLE
var cycle_timer: float = 0.0
var _flash_timer: float = 0.0

func _ready() -> void:
	super._ready()
	_bind_doors()
	_update_visuals()

func _bind_doors() -> void:
	if not inner_door_path.is_empty():
		inner_door = get_node_or_null(inner_door_path) as BulkheadDoor
	if inner_door == null and is_inside_tree():
		inner_door = get_tree().root.find_child("AirlockInner", true, false) as BulkheadDoor
	
	if not outer_door_path.is_empty():
		outer_door = get_node_or_null(outer_door_path) as BulkheadDoor
	if outer_door == null and is_inside_tree():
		outer_door = get_tree().root.find_child("AirlockOuter", true, false) as BulkheadDoor
	
	if not status_light_path.is_empty():
		status_light = get_node_or_null(status_light_path) as OmniLight3D
	
	if inner_door != null:
		inner_door.interlock_controller = self
	if outer_door != null:
		outer_door.interlock_controller = self

func can_open_door(door: BulkheadDoor) -> bool:
	if cycle_state != CycleState.IDLE:
		return false
	
	var env_mgr = _get_env_mgr()
	var press: float = 101.3
	if env_mgr != null and env_mgr.compartments.has(airlock_compartment_id):
		press = float(env_mgr.compartments[airlock_compartment_id].get("pressure", 101.3))
	
	if door == inner_door:
		# Safety interlock: Cannot open inner door if outer door is open
		if outer_door != null and outer_door.is_open:
			return false
		# Safety interlock: Cannot open inner door if chamber is depressurized (vacuum)
		if press < 80.0:
			return false
		return true
	
	if door == outer_door:
		# Safety interlock: Cannot open outer door if inner door is open
		if inner_door != null and inner_door.is_open:
			return false
		# Safety interlock: Cannot open outer door to vacuum if chamber is still pressurized
		if press > 15.0:
			return false
		return true
	
	return true

func can_open_inner_door() -> bool:
	return inner_door != null and can_open_door(inner_door)

func can_open_outer_door() -> bool:
	return outer_door != null and can_open_door(outer_door)

func _get_env_mgr() -> Node:
	if EnvironmentalManager != null and "instance" in EnvironmentalManager and EnvironmentalManager.instance != null:
		return EnvironmentalManager.instance
	if has_node("/root/EnvironmentalManager"):
		return get_node("/root/EnvironmentalManager")
	return null

func get_prompt() -> String:
	if cycle_state != CycleState.IDLE:
		return "[Cycling] %s: Equalizing Pressure..." % controller_name
	
	var env_mgr = _get_env_mgr()
	var press: float = 101.3
	if env_mgr != null and env_mgr.compartments.has(airlock_compartment_id):
		press = float(env_mgr.compartments[airlock_compartment_id].get("pressure", 101.3))
	
	if press > 50.0:
		return "[E] %s: Depressurize Airlock for EVA (0 kPa)" % controller_name
	else:
		return "[E] %s: Repressurize Airlock for Cabin Return (101.3 kPa)" % controller_name

func _on_interacted(_player: Node) -> void:
	toggle_cycle()

func toggle_cycle(immediate: bool = false) -> void:
	if cycle_state != CycleState.IDLE and not immediate:
		return
	var env_mgr = _get_env_mgr()
	var press: float = 101.3
	if env_mgr != null and env_mgr.compartments.has(airlock_compartment_id):
		press = float(env_mgr.compartments[airlock_compartment_id].get("pressure", 101.3))
	
	if press > 50.0:
		cycle_to_eva(immediate)
	else:
		cycle_to_cabin(immediate)

func cycle_to_eva(immediate: bool = false) -> void:
	if cycle_state != CycleState.IDLE and not immediate:
		return
	if inner_door != null and inner_door.is_open:
		inner_door.set_door_state(false, immediate)
	
	cycle_started.emit("EVA")
	AudioManager.play_sfx("door")
	AudioManager.play_sfx("gas_hiss")
	
	var env_mgr = _get_env_mgr()
	if env_mgr != null and env_mgr.has_method("start_airlock_depressurization"):
		env_mgr.start_airlock_depressurization(immediate)
	
	if immediate:
		cycle_state = CycleState.IDLE
		_on_cycle_complete("EVA")
	else:
		cycle_state = CycleState.CYCLING_TO_EVA
		cycle_timer = cycle_duration

func cycle_to_cabin(immediate: bool = false) -> void:
	if cycle_state != CycleState.IDLE and not immediate:
		return
	if outer_door != null and outer_door.is_open:
		outer_door.set_door_state(false, immediate)
	
	cycle_started.emit("CABIN")
	AudioManager.play_sfx("door")
	AudioManager.play_sfx("gas_hiss")
	
	var env_mgr = _get_env_mgr()
	if env_mgr != null and env_mgr.has_method("start_airlock_pressurization"):
		env_mgr.start_airlock_pressurization(immediate)
	
	if immediate:
		cycle_state = CycleState.IDLE
		_on_cycle_complete("CABIN")
	else:
		cycle_state = CycleState.CYCLING_TO_CABIN
		cycle_timer = cycle_duration

func _process(delta: float) -> void:
	if cycle_state == CycleState.IDLE:
		_update_visuals()
		return
	
	_flash_timer += delta * 6.0
	if status_light != null:
		status_light.light_color = Color(1.0, 0.85, 0.1)
		status_light.light_energy = 1.8 if int(_flash_timer) % 2 == 0 else 0.3
	
	cycle_timer -= delta
	if cycle_timer <= 0.0:
		var target := "EVA" if cycle_state == CycleState.CYCLING_TO_EVA else "CABIN"
		cycle_state = CycleState.IDLE
		_on_cycle_complete(target)

func _on_cycle_complete(target: String) -> void:
	AudioManager.play_sfx("repair")
	cycle_completed.emit(target)
	if has_node("/root/MissionManager"):
		var mm = get_node("/root/MissionManager")
		if mm.has_method("mark_airlock_cycled"):
			mm.mark_airlock_cycled()
	_update_visuals()

func _update_visuals() -> void:
	if status_light == null:
		return
	var env_mgr = _get_env_mgr()
	var press: float = 101.3
	if env_mgr != null and env_mgr.compartments.has(airlock_compartment_id):
		press = float(env_mgr.compartments[airlock_compartment_id].get("pressure", 101.3))
	
	if press >= 90.0:
		# Cabin pressure nominal (Green)
		status_light.light_color = Color(0.2, 0.9, 0.3)
		status_light.light_energy = 1.0
	elif press <= 10.0:
		# Vacuum depressurized (Cyan/Blue)
		status_light.light_color = Color(0.1, 0.5, 1.0)
		status_light.light_energy = 1.0
	else:
		# In-between / Hazard (Amber)
		status_light.light_color = Color(1.0, 0.6, 0.1)
		status_light.light_energy = 1.2

func export_save_data() -> Dictionary:
	return {
		"cycle_state": int(cycle_state),
		"cycle_timer": cycle_timer
	}

func import_save_data(data: Dictionary) -> void:
	cycle_state = int(data.get("cycle_state", CycleState.IDLE)) as CycleState
	cycle_timer = float(data.get("cycle_timer", 0.0))
	_update_visuals()
