class_name Subsystem
extends RefCounted

# Subsystem base class for ORBITAL: The Last Engineer
# Represents a major functional domain of the ship (Power, Life Support, Comms, etc.)

const FaultScript = preload("res://scripts/systems/fault.gd")
const ShipDeviceScript = preload("res://scripts/systems/device.gd")

signal subsystem_state_changed(subsystem_id: String, old_state: int, new_state: int)
signal subsystem_efficiency_changed(subsystem_id: String, efficiency: float)
signal fault_cleared(fault_id: String)

enum State {
	OFFLINE = 0,
	DEGRADED = 1,
	ONLINE = 2,
	FAILED = 3
}

var subsystem_id: String = ""
var display_name: String = ""
var state: int = State.OFFLINE
var efficiency: float = 1.0
var base_power_draw: float = 0.0
var prerequisites: Array[String] = []
var description: String = ""
var fault_description: String = ""

var devices: Dictionary = {} # device_id: ShipDevice
var active_faults: Array = []

func _init(
	p_id: String = "",
	p_name: String = "",
	p_initial_state: int = State.OFFLINE,
	p_prereqs: Array[String] = [],
	p_fault: String = "",
	p_desc: String = "",
	p_draw: float = 0.0
) -> void:
	subsystem_id = p_id
	display_name = p_name
	state = p_initial_state
	prerequisites = p_prereqs
	fault_description = p_fault
	description = p_desc
	base_power_draw = p_draw

func is_online() -> bool:
	return state == State.ONLINE

func register_device(dev: RefCounted) -> void:
	if dev != null and "device_id" in dev:
		devices[dev.device_id] = dev

func unregister_device(device_id: String) -> void:
	if devices.has(device_id):
		devices.erase(device_id)

func get_device(device_id: String) -> RefCounted:
	return devices.get(device_id, null)

# Core Prompt API Requirements:
# GetStatus()
# GetEfficiency()
# GetPowerDraw()
# ReceivePower(amount)
# ApplyDamage(amount, reason)
# Repair(amount)
# Tick(delta_time)

func get_status() -> Dictionary:
	return {
		"subsystem_id": subsystem_id,
		"display_name": display_name,
		"state": state,
		"state_string": get_state_string(),
		"efficiency": efficiency,
		"power_draw": get_power_draw(),
		"devices_count": devices.size(),
		"fault_description": fault_description
	}

func GetStatus() -> Dictionary:
	return get_status()

func get_efficiency() -> float:
	return efficiency

func GetEfficiency() -> float:
	return get_efficiency()

func get_power_draw() -> float:
	var total_draw: float = base_power_draw
	for dev in devices.values():
		if dev != null and dev.has_method("get_power_draw"):
			total_draw += dev.get_power_draw()
	return total_draw

func GetPowerDraw() -> float:
	return get_power_draw()

func receive_power(amount: float) -> void:
	var needed := get_power_draw()
	if needed <= 0.0:
		efficiency = 1.0
		return
	efficiency = clampf(amount / needed, 0.0, 1.0)
	subsystem_efficiency_changed.emit(subsystem_id, efficiency)

func ReceivePower(amount: float) -> void:
	receive_power(amount)

func apply_damage(amount: float, _reason: String = "") -> void:
	efficiency = maxf(0.0, efficiency - (amount / 100.0))
	if efficiency <= 0.0 and state == State.ONLINE:
		set_state(State.FAILED, "Subsystem integrity failed: " + _reason)
	subsystem_efficiency_changed.emit(subsystem_id, efficiency)

func ApplyDamage(amount: float, reason: String = "") -> void:
	apply_damage(amount, reason)

func repair(amount: float = 1.0) -> void:
	efficiency = minf(1.0, efficiency + (amount / 100.0))
	if efficiency >= 0.5 and state == State.FAILED:
		set_state(State.DEGRADED, "Partial repair completed")
	subsystem_efficiency_changed.emit(subsystem_id, efficiency)

func Repair(amount: float = 1.0) -> void:
	repair(amount)

func tick(delta: float) -> void:
	for dev in devices.values():
		if dev != null and dev.has_method("tick"):
			dev.tick(delta)
	for fault in active_faults:
		if fault != null and fault.has_method("tick"):
			fault.tick(delta)

func Tick(delta: float) -> void:
	tick(delta)

func set_state(new_state: int, new_fault_desc: String = "") -> void:
	if state == new_state and (new_fault_desc == "" or fault_description == new_fault_desc):
		return
	var old_state := state
	state = new_state
	if new_fault_desc != "":
		fault_description = new_fault_desc
	subsystem_state_changed.emit(subsystem_id, old_state, new_state)

func add_fault(fault: RefCounted) -> void:
	for existing in active_faults:
		if existing.fault_id == fault.fault_id:
			return
	active_faults.append(fault)

func clear_fault(f_id: String) -> void:
	for i in range(active_faults.size() - 1, -1, -1):
		if active_faults[i].fault_id == f_id:
			active_faults[i].resolve()
			active_faults.remove_at(i)
			fault_cleared.emit(f_id)

func get_state_string() -> String:
	match state:
		State.OFFLINE:
			return "OFFLINE"
		State.DEGRADED:
			return "DEGRADED"
		State.ONLINE:
			return "ONLINE"
		State.FAILED:
			return "FAILED"
		_:
			return "UNKNOWN"

func to_dict() -> Dictionary:
	var dev_dicts: Dictionary = {}
	for k in devices.keys():
		var d = devices[k]
		if d != null and d.has_method("to_dict"):
			dev_dicts[k] = d.to_dict()
	return {
		"subsystem_id": subsystem_id,
		"state": state,
		"efficiency": efficiency,
		"fault_description": fault_description,
		"devices": dev_dicts
	}

func from_dict(data: Dictionary) -> void:
	if data.has("state"):
		state = int(data["state"])
	if data.has("efficiency"):
		efficiency = float(data["efficiency"])
	if data.has("fault_description"):
		fault_description = str(data["fault_description"])
	if data.has("devices"):
		var dev_data: Dictionary = data["devices"]
		for k in dev_data.keys():
			if devices.has(k) and devices[k].has_method("from_dict"):
				devices[k].from_dict(dev_data[k])
