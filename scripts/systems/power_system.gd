class_name PowerSystem
extends "res://scripts/systems/subsystem.gd"

# Power System for ORBITAL: The Last Engineer
# Simulates generation (Fusion Reactor), storage (Auxiliary Batteries), distribution (Bus Relays), and consumption.


signal power_grid_updated(generation: float, demand: float, battery_charge: float, efficiency: float)
signal breaker_tripped(breaker_name: String, reason: String)
signal brownout_occurred(unpowered_devices: Array[String])

# Configuration parameters (can be overridden by power_config.json)
var reactor_capacity: float = 150.0 # kW
var reactor_online: bool = false
var reactor_temperature: float = 320.0 # Kelvin
var reactor_temp_critical: float = 650.0
var cooldown_rate: float = 2.5
var coolant_flow_rate: float = 1.0 # 0.0 to 1.0
var thermal_throttled: bool = false

var battery_capacity: float = 60.0 # kWh
var battery_charge: float = 25.0 # kWh
var max_charge_rate: float = 15.0 # kW
var max_discharge_rate: float = 30.0 # kW
var battery_efficiency: float = 0.92

var bus_relay_closed: bool = false
var bus_energized: bool = false

var current_generation: float = 0.0
var current_demand: float = 0.0
var current_supplied: float = 0.0
var net_power: float = 0.0
var grid_efficiency: float = 0.0

func _init() -> void:
	super._init(
		"power",
		"Power Generation & Distribution",
		0, # OFFLINE
		[],
		"Generator turbine tripped; main distribution bus isolated",
		"Fusion generator, electrical distribution bus, and auxiliary power banks."
	)
	_load_config()

func _load_config() -> void:
	var path := "res://data/power_config.json"
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		var cfg: Dictionary = json.data
		if cfg.has("reactor"):
			var r: Dictionary = cfg["reactor"]
			reactor_capacity = float(r.get("nominal_output", reactor_capacity))
			reactor_temperature = float(r.get("temperature_nominal", reactor_temperature))
			reactor_temp_critical = float(r.get("temperature_critical", reactor_temp_critical))
			cooldown_rate = float(r.get("cooldown_rate", cooldown_rate))
		if cfg.has("battery"):
			var b: Dictionary = cfg["battery"]
			battery_capacity = float(b.get("capacity", battery_capacity))
			battery_charge = float(b.get("initial_charge", battery_charge))
			max_charge_rate = float(b.get("max_charge_rate", max_charge_rate))
			max_discharge_rate = float(b.get("max_discharge_rate", max_discharge_rate))
			battery_efficiency = float(b.get("efficiency", battery_efficiency))

func apply_damage(amount: float, _reason: String = "") -> void:
	super.apply_damage(amount, _reason)
	if reactor_online:
		current_generation = reactor_capacity * efficiency
	_update_distribution(0.0)

func repair(amount: float = 1.0) -> void:
	super.repair(amount)
	if reactor_online:
		current_generation = reactor_capacity * efficiency
	_update_distribution(0.0)

func set_generator(closed: bool) -> Dictionary:
	reactor_online = closed
	if closed:
		current_generation = reactor_capacity * efficiency
		fault_description = "Nominal reactor turbine output (100% capacity)"
		if state == 0 or state == 3: # OFFLINE or FAILED
			set_state(2, fault_description) # ONLINE
	else:
		current_generation = 0.0
		fault_description = "Generator breaker open; turbine stopped"
		set_state(0, fault_description) # OFFLINE
		# Cascade: if generator stops, bus relay trips
		if bus_relay_closed:
			set_bus_relay(false)
			breaker_tripped.emit("distribution_bus", "Primary power generator tripped")
	
	_update_distribution(0.0)
	return {"ok": true, "online": reactor_online, "generation": current_generation}

func set_bus_relay(closed: bool) -> Dictionary:
	if closed and not reactor_online:
		bus_relay_closed = false
		bus_energized = false
		return {
			"ok": false,
			"reason": "Cannot energize distribution bus while primary power generator is OFFLINE"
		}
	
	bus_relay_closed = closed
	bus_energized = closed and reactor_online
	_update_distribution(0.0)
	return {"ok": true, "energized": bus_energized}

func tick(delta: float) -> void:
	super.tick(delta)
	_update_distribution(delta)

func _update_distribution(delta: float) -> void:
	# Temperature simulation and safety throttling
	if reactor_online and delta > 0.0:
		var sim_dt := clampf(delta, 0.0, 5.0)
		if coolant_flow_rate < 0.8:
			var heat_gain := (1.0 - coolant_flow_rate) * 2.5 * sim_dt
			reactor_temperature = minf(reactor_temp_critical, reactor_temperature + heat_gain)
		else:
			var cool_loss := cooldown_rate * sim_dt
			reactor_temperature = maxf(320.0, reactor_temperature - cool_loss)
		
		if reactor_temperature >= 550.0:
			thermal_throttled = true
			current_generation = minf(current_generation, reactor_capacity * 0.4)
		elif reactor_temperature <= 420.0:
			thermal_throttled = false
			current_generation = reactor_capacity * efficiency
	elif not reactor_online and delta > 0.0:
		var cool_dt := clampf(delta, 0.0, 5.0)
		reactor_temperature = maxf(320.0, reactor_temperature - (cooldown_rate * cool_dt))
		thermal_throttled = false

	current_demand = 0.0
	for dev in devices.values():
		if dev != null and dev.has_method("get_power_draw"):
			current_demand += dev.get_power_draw()
	
	var available_gen := current_generation if reactor_online else 0.0
	var unpowered_list: Array[String] = []
	
	if not bus_energized:
		# Bus is disconnected: 0 kW routed to devices
		current_supplied = 0.0
		net_power = -current_demand
		grid_efficiency = 0.0
		for dev in devices.values():
			if dev != null and dev.has_method("receive_power"):
				dev.receive_power(0.0)
		power_grid_updated.emit(available_gen, current_demand, battery_charge, grid_efficiency)
		return
	
	# Bus is energized: calculate power balance with battery support
	var net := available_gen - current_demand
	var supplied_pool := available_gen
	
	if net >= 0.0:
		# Surplus power: charge battery
		if delta > 0.0 and battery_charge < battery_capacity:
			var charge_amt: float = minf(net, max_charge_rate) * (delta / 3600.0) * battery_efficiency
			battery_charge = minf(battery_capacity, battery_charge + charge_amt)
	else:
		# Deficit: discharge battery to supplement
		var needed_discharge := -net
		var actual_discharge := minf(needed_discharge, max_discharge_rate)
		if delta > 0.0 and battery_charge > 0.0:
			var energy_needed := actual_discharge * (delta / 3600.0)
			if battery_charge >= energy_needed:
				battery_charge -= energy_needed
				supplied_pool += actual_discharge
			else:
				var hours := delta / 3600.0
				var partial_power := (battery_charge / hours) if hours > 0.0 else 0.0
				supplied_pool += minf(partial_power, max_discharge_rate)
				battery_charge = 0.0
	
	current_supplied = minf(supplied_pool, current_demand)
	net_power = available_gen - current_demand
	grid_efficiency = clampf(current_supplied / maxf(1.0, current_demand), 0.0, 1.0)
	
	# Prioritized distribution across devices
	var crit_1: Array = []
	var crit_2: Array = []
	var crit_3: Array = []
	
	for dev in devices.values():
		if dev != null and "criticality" in dev:
			match dev.criticality:
				1: # CRITICAL
					crit_1.append(dev)
				2: # OPERATIONAL
					crit_2.append(dev)
				_:
					crit_3.append(dev)
	
	var remaining_power := supplied_pool
	for group in [crit_1, crit_2, crit_3]:
		for dev in group:
			var req: float = dev.get_power_draw() if dev.has_method("get_power_draw") else 0.0
			if remaining_power >= req:
				dev.receive_power(req)
				remaining_power -= req
			elif remaining_power > 0.0:
				dev.receive_power(remaining_power)
				remaining_power = 0.0
			else:
				dev.receive_power(0.0)
				unpowered_list.append(dev.device_id)
	
	if not unpowered_list.is_empty():
		brownout_occurred.emit(unpowered_list)
	
	power_grid_updated.emit(available_gen, current_demand, battery_charge, grid_efficiency)

func get_grid_telemetry() -> Dictionary:
	return {
		"reactor_online": reactor_online,
		"reactor_capacity": reactor_capacity,
		"current_generation": current_generation if reactor_online else 0.0,
		"reactor_temperature": reactor_temperature,
		"reactor_temp_critical": reactor_temp_critical,
		"thermal_throttled": thermal_throttled,
		"coolant_flow_rate": coolant_flow_rate,
		"bus_relay_closed": bus_relay_closed,
		"bus_energized": bus_energized,
		"current_demand": current_demand,
		"current_supplied": current_supplied,
		"net_power": net_power,
		"battery_charge": battery_charge,
		"battery_capacity": battery_capacity,
		"battery_percentage": (battery_charge / maxf(1.0, battery_capacity)) * 100.0,
		"grid_efficiency": grid_efficiency
	}

func to_dict() -> Dictionary:
	var base := super.to_dict()
	base["reactor_online"] = reactor_online
	base["reactor_temperature"] = reactor_temperature
	base["thermal_throttled"] = thermal_throttled
	base["coolant_flow_rate"] = coolant_flow_rate
	base["bus_relay_closed"] = bus_relay_closed
	base["battery_charge"] = battery_charge
	return base

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	reactor_online = bool(data.get("reactor_online", false))
	reactor_temperature = float(data.get("reactor_temperature", 320.0))
	thermal_throttled = bool(data.get("thermal_throttled", false))
	coolant_flow_rate = float(data.get("coolant_flow_rate", 1.0))
	bus_relay_closed = bool(data.get("bus_relay_closed", false))
	battery_charge = float(data.get("battery_charge", 25.0))
	set_generator(reactor_online)
	set_bus_relay(bus_relay_closed)
