class_name ShipDevice
extends RefCounted

# Ship Device class for ORBITAL: The Last Engineer
# Base physical component in the world that connects to ship subsystems and the power grid.

const FaultScript = preload("res://scripts/systems/fault.gd")

signal device_state_changed(device_id: String, is_powered: bool, health: float)
signal device_fault_added(device_id: String, fault: RefCounted)
signal device_fault_cleared(device_id: String, fault_id: String)

enum Criticality {
	CRITICAL = 1,     # Life Support, Core Breakers, Emergency Lighting
	OPERATIONAL = 2,  # Bulkhead Doors, Terminals, Sensors
	NON_ESSENTIAL = 3 # Ion Propulsion (standby), Comms Transceiver, Holotable
}

var device_id: String = ""
var device_name: String = ""
var subsystem_id: String = ""
var compartment_id: String = ""
var description: String = ""

var power_draw: float = 0.0 # Power drawn when active (kW)
var power_generation: float = 0.0 # Power produced if generator (kW)
var criticality: int = Criticality.OPERATIONAL
var health: float = 100.0 # 0.0 to 100.0
var max_health: float = 100.0
var efficiency: float = 1.0 # 0.0 to 1.0
var is_enabled: bool = true
var is_powered: bool = false
var active_faults: Array = []

func _init(
	p_id: String = "",
	p_name: String = "",
	p_subsystem: String = "",
	p_compartment: String = "",
	p_draw: float = 0.0,
	p_gen: float = 0.0,
	p_crit: int = Criticality.OPERATIONAL,
	p_health: float = 100.0,
	p_desc: String = ""
) -> void:
	device_id = p_id
	device_name = p_name
	subsystem_id = p_subsystem
	compartment_id = p_compartment
	power_draw = p_draw
	power_generation = p_gen
	criticality = p_crit
	health = p_health
	description = p_desc
	efficiency = 1.0 if health > 0.0 else 0.0

func get_efficiency() -> float:
	return efficiency

func GetEfficiency() -> float:
	return get_efficiency()

func get_power_draw() -> float:
	if not is_enabled or health <= 0.0:
		return 0.0
	return power_draw

func GetPowerDraw() -> float:
	return get_power_draw()

func get_power_generation() -> float:
	if not is_enabled or health <= 0.0:
		return 0.0
	return power_generation * efficiency

func GetPowerGeneration() -> float:
	return get_power_generation()

func receive_power(amount: float) -> void:
	var needed := get_power_draw()
	var was_powered := is_powered
	var hp_factor := clampf(health / maxf(1.0, max_health), 0.0, 1.0)
	
	if needed <= 0.0:
		is_powered = is_enabled and health > 0.0
		efficiency = hp_factor if is_powered else 0.0
	else:
		is_powered = amount >= (needed * 0.5)
		if needed > 0.0:
			var pwr_ratio := clampf(amount / needed, 0.0, 1.0)
			efficiency = pwr_ratio * hp_factor
	
	if was_powered != is_powered:
		device_state_changed.emit(device_id, is_powered, health)

func ReceivePower(amount: float) -> void:
	receive_power(amount)

func apply_damage(amount: float, _reason: String = "") -> void:
	health = maxf(0.0, health - amount)
	var hp_factor := clampf(health / maxf(1.0, max_health), 0.0, 1.0)
	if health <= 0.0:
		efficiency = 0.0
		is_powered = false
	else:
		efficiency = minf(efficiency, hp_factor)
	device_state_changed.emit(device_id, is_powered, health)

func ApplyDamage(amount: float, reason: String = "") -> void:
	apply_damage(amount, reason)

func repair(amount: float = 100.0) -> void:
	health = minf(max_health, health + amount)
	var hp_factor := clampf(health / maxf(1.0, max_health), 0.0, 1.0)
	if is_powered or power_draw <= 0.0:
		efficiency = hp_factor
	device_state_changed.emit(device_id, is_powered, health)

func Repair(amount: float = 100.0) -> void:
	repair(amount)

func add_fault(fault: RefCounted) -> void:
	for existing in active_faults:
		if existing.fault_id == fault.fault_id:
			return
	active_faults.append(fault)
	device_fault_added.emit(device_id, fault)

func remove_fault(f_id: String) -> void:
	for i in range(active_faults.size() - 1, -1, -1):
		if active_faults[i].fault_id == f_id:
			active_faults[i].resolve()
			active_faults.remove_at(i)
			device_fault_cleared.emit(device_id, f_id)

func has_fault(f_id: String) -> bool:
	for f in active_faults:
		if f.fault_id == f_id and f.is_active:
			return true
	return false

func tick(delta: float) -> void:
	for f in active_faults:
		f.tick(delta)

func Tick(delta: float) -> void:
	tick(delta)

func get_status() -> Dictionary:
	return {
		"device_id": device_id,
		"device_name": device_name,
		"subsystem_id": subsystem_id,
		"compartment_id": compartment_id,
		"is_powered": is_powered,
		"is_enabled": is_enabled,
		"health": health,
		"efficiency": efficiency,
		"power_draw": get_power_draw(),
		"faults_count": active_faults.size()
	}

func GetStatus() -> Dictionary:
	return get_status()

func to_dict() -> Dictionary:
	var fault_dicts: Array[Dictionary] = []
	for f in active_faults:
		fault_dicts.append(f.to_dict())
	return {
		"device_id": device_id,
		"device_name": device_name,
		"subsystem_id": subsystem_id,
		"compartment_id": compartment_id,
		"power_draw": power_draw,
		"power_generation": power_generation,
		"criticality": criticality,
		"health": health,
		"efficiency": efficiency,
		"is_enabled": is_enabled,
		"is_powered": is_powered,
		"active_faults": fault_dicts
	}

func from_dict(data: Dictionary) -> void:
	health = float(data.get("health", health))
	efficiency = float(data.get("efficiency", efficiency))
	is_enabled = bool(data.get("is_enabled", is_enabled))
	is_powered = bool(data.get("is_powered", is_powered))
	
	active_faults.clear()
	var f_data: Array = data.get("active_faults", [])
	for fd in f_data:
		if fd is Dictionary:
			var f = FaultScript.new()
			f.from_dict(fd)
			active_faults.append(f)
