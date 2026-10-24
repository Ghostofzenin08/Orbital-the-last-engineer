extends Node

# Ship System Manager Autoload for ORBITAL: The Last Engineer
# Simulates the 5 ship systems and their operational dependencies.

signal system_state_changed(system_id: String, old_state: int, new_state: int)
signal system_fault_cleared(system_id: String)
signal dependency_failed(system_id: String, reason: String)

var systems: Dictionary = {}

# Flags for repair / maintenance actions
var generator_breaker_closed: bool = false
var bus_relay_closed: bool = false
var coolant_coupler_installed: bool = false
var comms_array_aligned: bool = false
var propulsion_primed: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initialize_systems()

func _initialize_systems() -> void:
	systems.clear()
	
	systems["primary_power"] = ShipSystem.new(
		"primary_power",
		"Primary Power Generator",
		ShipSystem.State.OFFLINE,
		[],
		"Generator turbine tripped on emergency stop",
		"Main fusion turbine delivering electrical potential to shipboard busses."
	)
	
	systems["power_distribution"] = ShipSystem.new(
		"power_distribution",
		"Electrical Distribution Bus",
		ShipSystem.State.OFFLINE,
		["primary_power"],
		"Main bus isolation breakers open",
		"High-voltage routing conduits powering life support, doors, and flight consoles."
	)
	
	systems["life_support"] = ShipSystem.new(
		"life_support",
		"Atmospheric Circulation & Scrubbers",
		ShipSystem.State.FAILED,
		["power_distribution"],
		"Atmospheric coolant coupler fractured; pressure scrubber offline",
		"Maintains 1.0 ATM nitrogen-oxygen breathing mixture and climate regulation."
	)
	
	systems["communications"] = ShipSystem.new(
		"communications",
		"Sub-Space Transceiver Array",
		ShipSystem.State.OFFLINE,
		["power_distribution"],
		"Antenna dish servo desynchronized; frequency drift",
		"Long-range quantum communications array and emergency distress beacon."
	)
	
	systems["propulsion"] = ShipSystem.new(
		"propulsion",
		"Sub-Orbital Ion Engines",
		ShipSystem.State.OFFLINE,
		["power_distribution", "life_support", "communications"],
		"Plasma injection conduits cold and unprimed",
		"Reaction mass thrusters required for orbital maneuvering and escape trajectory."
	)

func reset_to_defaults() -> void:
	AudioManager.stop_all()
	generator_breaker_closed = false
	bus_relay_closed = false
	coolant_coupler_installed = false
	comms_array_aligned = false
	propulsion_primed = false
	_initialize_systems()
	if get_node_or_null("/root/ShipState") != null and not ShipState._is_syncing:
		ShipState._is_syncing = true
		ShipState.reset_to_defaults()
		ShipState._is_syncing = false

func get_system(system_id: String) -> ShipSystem:
	if systems.has(system_id):
		return systems[system_id]
	return null

func get_system_state(system_id: String) -> int:
	var sys := get_system(system_id)
	return sys.state if sys != null else ShipSystem.State.OFFLINE

func is_system_online(system_id: String) -> bool:
	return get_system_state(system_id) == ShipSystem.State.ONLINE

func check_prerequisites(system_id: String) -> Dictionary:
	var sys := get_system(system_id)
	if sys == null:
		return {"ok": false, "reason": "Unknown system"}
	
	for prereq_id in sys.prerequisites:
		var prereq := get_system(prereq_id)
		if prereq == null or prereq.state != ShipSystem.State.ONLINE:
			var msg := "Requires %s to be ONLINE" % (prereq.display_name if prereq else prereq_id)
			return {"ok": false, "reason": msg}
	
	return {"ok": true, "reason": "All prerequisites satisfied"}

func set_generator_breaker(closed: bool) -> Dictionary:
	generator_breaker_closed = closed
	var sys: ShipSystem = systems["primary_power"]
	var old_state := sys.state
	
	if closed:
		sys.state = ShipSystem.State.ONLINE
		sys.fault_description = "Nominal output (100% capacity)"
		AudioManager.play_sfx("click")
		AudioManager.play_ambient("generator_hum")
	else:
		sys.state = ShipSystem.State.OFFLINE
		sys.fault_description = "Manual emergency breaker open"
		AudioManager.stop_ambient()
		_cascade_power_failure()
	
	system_state_changed.emit("primary_power", old_state, sys.state)
	if get_node_or_null("/root/ShipState") != null and not ShipState._is_syncing:
		ShipState._is_syncing = true
		ShipState.set_generator_breaker(closed)
		ShipState._is_syncing = false
	return {"ok": true, "state": sys.state}

func set_power_distribution(closed: bool) -> Dictionary:
	bus_relay_closed = closed
	var sys: ShipSystem = systems["power_distribution"]
	var old_state := sys.state
	
	if not closed:
		sys.state = ShipSystem.State.OFFLINE
		sys.fault_description = "Distribution bus relay open"
		_cascade_power_failure()
		if get_node_or_null("/root/ShipState") != null and not ShipState._is_syncing:
			ShipState._is_syncing = true
			ShipState.set_bus_relay(false)
			ShipState._is_syncing = false
		system_state_changed.emit("power_distribution", old_state, sys.state)
		return {"ok": true, "state": sys.state}
	
	var prereq_check := check_prerequisites("power_distribution")
	if not prereq_check["ok"]:
		bus_relay_closed = false
		AudioManager.play_sfx("denied")
		dependency_failed.emit("power_distribution", prereq_check["reason"])
		if get_node_or_null("/root/ShipState") != null and not ShipState._is_syncing:
			ShipState._is_syncing = true
			ShipState.set_bus_relay(false)
			ShipState._is_syncing = false
		return prereq_check
	
	sys.state = ShipSystem.State.ONLINE
	sys.fault_description = "Bus energized; circuits active across all compartments"
	AudioManager.play_sfx("click")
	if get_node_or_null("/root/ShipState") != null and not ShipState._is_syncing:
		ShipState._is_syncing = true
		ShipState.set_bus_relay(true)
		ShipState._is_syncing = false
	system_state_changed.emit("power_distribution", old_state, sys.state)
	
	# If life support was already repaired, it can now power up
	if coolant_coupler_installed:
		_evaluate_life_support()
	
	return {"ok": true, "state": sys.state}

func install_coolant_coupler() -> Dictionary:
	coolant_coupler_installed = true
	if get_node_or_null("/root/ShipState") != null and not ShipState._is_syncing:
		ShipState._is_syncing = true
		ShipState.install_coolant_coupler()
		ShipState._is_syncing = false
	system_fault_cleared.emit("life_support")
	AudioManager.play_sfx("repair")
	return _evaluate_life_support()

func _evaluate_life_support() -> Dictionary:
	var sys: ShipSystem = systems["life_support"]
	var old_state := sys.state
	
	if not coolant_coupler_installed:
		sys.state = ShipSystem.State.FAILED
		sys.fault_description = "Atmospheric coolant coupler fractured; pressure scrubber offline"
		system_state_changed.emit("life_support", old_state, sys.state)
		return {"ok": false, "reason": "Coolant coupler missing or broken"}
	
	if not is_system_online("power_distribution"):
		sys.state = ShipSystem.State.DEGRADED
		sys.fault_description = "Coupler installed; awaiting bus electrical power"
		system_state_changed.emit("life_support", old_state, sys.state)
		return {"ok": false, "reason": "Awaiting electrical power from distribution bus"}
	
	sys.state = ShipSystem.State.ONLINE
	sys.fault_description = "Atmospheric circulation nominal; scrubber regenerating O2"
	system_state_changed.emit("life_support", old_state, sys.state)
	return {"ok": true, "state": sys.state}

func align_comms_array() -> Dictionary:
	var prereq_check := check_prerequisites("communications")
	if not prereq_check["ok"]:
		AudioManager.play_sfx("denied")
		dependency_failed.emit("communications", prereq_check["reason"])
		return prereq_check
	
	comms_array_aligned = true
	var sys: ShipSystem = systems["communications"]
	var old_state := sys.state
	sys.state = ShipSystem.State.ONLINE
	sys.fault_description = "Array calibrated; receiving telemetry and incident log data"
	if get_node_or_null("/root/ShipState") != null and not ShipState._is_syncing:
		ShipState._is_syncing = true
		ShipState.align_comms_array()
		ShipState._is_syncing = false
	system_fault_cleared.emit("communications")
	system_state_changed.emit("communications", old_state, sys.state)
	AudioManager.play_sfx("repair")
	return {"ok": true, "state": sys.state}

func engage_propulsion() -> Dictionary:
	var prereq_check := check_prerequisites("propulsion")
	if not prereq_check["ok"]:
		AudioManager.play_sfx("denied")
		dependency_failed.emit("propulsion", prereq_check["reason"])
		return prereq_check
	
	if get_node_or_null("/root/ShipState") != null:
		var ss = get_node("/root/ShipState")
		if "crisis_manager" in ss and ss.crisis_manager != null:
			if ss.crisis_manager.current_crisis == 3 and not ss.crisis_manager.is_creature_eliminated:
				AudioManager.play_sfx("denied")
				var reason := "Station in lockdown: Mutant alien predator active. Trap and eliminate with poisonous gas before departure."
				dependency_failed.emit("propulsion", reason)
				return {"ok": false, "reason": reason}
	
	propulsion_primed = true
	var sys: ShipSystem = systems["propulsion"]
	var old_state := sys.state
	sys.state = ShipSystem.State.ONLINE
	sys.fault_description = "Ion drives ignition sequence verified; departure burn initiated"
	if get_node_or_null("/root/ShipState") != null and not ShipState._is_syncing:
		ShipState._is_syncing = true
		ShipState.engage_propulsion()
		ShipState._is_syncing = false
	system_state_changed.emit("propulsion", old_state, sys.state)
	AudioManager.play_sfx("victory")
	return {"ok": true, "state": sys.state}

func _cascade_power_failure() -> void:
	if not is_system_online("primary_power"):
		if is_system_online("power_distribution") or bus_relay_closed:
			bus_relay_closed = false
			var pwr_sys: ShipSystem = systems["power_distribution"]
			var old_pd := pwr_sys.state
			pwr_sys.state = ShipSystem.State.OFFLINE
			pwr_sys.fault_description = "Distribution bus relay tripped due to primary generator loss"
			if get_node_or_null("/root/ShipState") != null and not ShipState._is_syncing:
				ShipState._is_syncing = true
				ShipState.set_bus_relay(false)
				ShipState._is_syncing = false
			system_state_changed.emit("power_distribution", old_pd, pwr_sys.state)
	
	if not is_system_online("power_distribution"):
		# Dependent systems lose operational power
		if is_system_online("life_support"):
			var ls_sys: ShipSystem = systems["life_support"]
			var old_ls := ls_sys.state
			ls_sys.state = ShipSystem.State.DEGRADED if coolant_coupler_installed else ShipSystem.State.FAILED
			system_state_changed.emit("life_support", old_ls, ls_sys.state)
		
		if is_system_online("communications"):
			var comms_sys: ShipSystem = systems["communications"]
			var old_comm := comms_sys.state
			comms_sys.state = ShipSystem.State.OFFLINE
			system_state_changed.emit("communications", old_comm, comms_sys.state)
		
		if is_system_online("propulsion"):
			var prop_sys: ShipSystem = systems["propulsion"]
			var old_prop := prop_sys.state
			prop_sys.state = ShipSystem.State.OFFLINE
			propulsion_primed = false
			system_state_changed.emit("propulsion", old_prop, prop_sys.state)

func export_save_data() -> Dictionary:
	var sys_data := {}
	for k in systems.keys():
		sys_data[k] = (systems[k] as ShipSystem).to_dict()
	var res := {
		"generator_breaker_closed": generator_breaker_closed,
		"bus_relay_closed": bus_relay_closed,
		"coolant_coupler_installed": coolant_coupler_installed,
		"comms_array_aligned": comms_array_aligned,
		"propulsion_primed": propulsion_primed,
		"systems": sys_data
	}
	if get_node_or_null("/root/ShipState") != null:
		res["ship_state"] = ShipState.export_save_data()
	return res

func import_save_data(data: Dictionary) -> void:
	generator_breaker_closed = bool(data.get("generator_breaker_closed", false))
	bus_relay_closed = bool(data.get("bus_relay_closed", false))
	coolant_coupler_installed = bool(data.get("coolant_coupler_installed", false))
	comms_array_aligned = bool(data.get("comms_array_aligned", false))
	propulsion_primed = bool(data.get("propulsion_primed", false))
	
	var sys_data: Dictionary = data.get("systems", {})
	for k in sys_data.keys():
		if systems.has(k):
			var sys: ShipSystem = systems[k]
			var old_st := sys.state
			sys.from_dict(sys_data[k])
			system_state_changed.emit(k, old_st, sys.state)
	
	if data.has("ship_state") and get_node_or_null("/root/ShipState") != null:
		ShipState.import_save_data(data["ship_state"])
	
	if coolant_coupler_installed:
		system_fault_cleared.emit("life_support")
	if comms_array_aligned:
		system_fault_cleared.emit("communications")
	
	# Resume generator audio if powered
	if is_system_online("primary_power"):
		AudioManager.play_ambient("generator_hum")
	else:
		AudioManager.stop_ambient()
