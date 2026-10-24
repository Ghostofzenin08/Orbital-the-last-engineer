class_name ShipStateManager
extends Node

# Ship State Manager for ORBITAL: The Last Engineer
# Central coordinator and event bus orchestrating all ship subsystems, devices, faults, and compartments.

const FaultScript = preload("res://scripts/systems/fault.gd")
const ShipDeviceScript = preload("res://scripts/systems/device.gd")
const SubsystemScript = preload("res://scripts/systems/subsystem.gd")
const PowerSystemScript = preload("res://scripts/systems/power_system.gd")

signal subsystem_state_changed(subsystem_id: String, old_state: int, new_state: int)
signal device_updated(device_id: String, is_powered: bool, health: float)
signal fault_added(fault: RefCounted)
signal fault_resolved(fault_id: String)
signal power_grid_updated(telemetry: Dictionary)
signal compartment_updated(compartment_id: String, comp_data: Dictionary)
signal schematic_updated(schematic_data: Dictionary)

var subsystems: Dictionary = {} # subsystem_id: Subsystem
var devices: Dictionary = {}    # device_id: ShipDevice
var active_faults: Dictionary = {} # fault_id: Fault

var power_system: RefCounted = null
var auxiliary_scrubber_active: bool = false
var power_rerouted: bool = false
var power_routes: Dictionary = {} # destination: source
var coolant_bypass_active: bool = false
var manual_overrides: Dictionary = {}

# Milestone 5: Narrative Revelation Gameplay Consequences
var has_revelation_anomaly: bool = false
var has_revelation_quarantine: bool = false
var has_revelation_directive: bool = false
var scrubber_efficiency_multiplier: float = 1.0
var commander_override_code: String = ""
var quarantine_lockout_cleared: bool = false
var thruster_efficiency_boost: float = 1.0

# Milestone 6: Dynamic Multi-Stage Crisis & Cascading Faults
const CrisisManagerScript = preload("res://scripts/systems/crisis_manager.gd")
var crisis_manager: CrisisManager = null


# Compartment definitions
const COMPARTMENTS: Dictionary = {
	"bridge": {
		"id": "bridge",
		"name": "Command Bridge",
		"description": "Sub-space communications array, holotable navigation, and orbital flight helm.",
		"deck": "main"
	},
	"avionics_bay": {
		"id": "avionics_bay",
		"name": "Server Core & Avionics",
		"description": "Optical computing arrays, server core racks, and flight avionics relays.",
		"deck": "main"
	},
	"crew_quarters": {
		"id": "crew_quarters",
		"name": "Crew Habitation & Bunks",
		"description": "Habitation bunks, personal workstations, and hydroponic water recycler.",
		"deck": "main"
	},
	"medbay": {
		"id": "medbay",
		"name": "Medical Infirmary",
		"description": "Diagnostic beds, hyperbaric oxygen booster, and emergency trauma supplies.",
		"deck": "main"
	},
	"life_support": {
		"id": "life_support",
		"name": "Life Support Module",
		"description": "Atmospheric scrubber columns, oxygen circulation manifolds, and environmental monitoring.",
		"deck": "main"
	},
	"corridors": {
		"id": "corridors",
		"name": "Central Transit Spine",
		"description": "Hermetic transition conduits connecting ship compartments via motorized bulkhead doors.",
		"deck": "main"
	},
	"cargo_bay": {
		"id": "cargo_bay",
		"name": "Cargo Hold & Machine Staging",
		"description": "Heavy cargo staging, hydraulic hoists, and salvage container storage.",
		"deck": "main"
	},
	"airlock_chamber": {
		"id": "airlock_chamber",
		"name": "Airlock & EVA Staging",
		"description": "Interlocking dual-door pressure chamber and EVA suit staging locker.",
		"deck": "main"
	},
	"engineering_bay": {
		"id": "engineering_bay",
		"name": "Engineering Bay",
		"description": "Primary fusion generation, high-voltage bus relays, and maintenance storage.",
		"deck": "main"
	},
	"reactor_subdeck": {
		"id": "reactor_subdeck",
		"name": "Fuel Vault & Auxiliary Battery Deck",
		"description": "Auxiliary fuel injection valves, secondary battery banks, and lower deck conduits.",
		"deck": "lower"
	},
	"maintenance_crawlway": {
		"id": "maintenance_crawlway",
		"name": "Breached Maintenance Crawlway",
		"description": "Breached crawlway bypass with low ceiling connecting Cargo Bay to Reactor Subdeck.",
		"deck": "lower"
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialize_ship()

func initialize_ship() -> void:
	subsystems.clear()
	devices.clear()
	active_faults.clear()
	auxiliary_scrubber_active = false
	power_rerouted = false
	power_routes.clear()
	coolant_bypass_active = false
	manual_overrides.clear()
	has_revelation_anomaly = false
	has_revelation_quarantine = false
	has_revelation_directive = false
	scrubber_efficiency_multiplier = 1.0
	commander_override_code = ""
	quarantine_lockout_cleared = false
	thruster_efficiency_boost = 1.0

	if crisis_manager == null:
		crisis_manager = CrisisManagerScript.new()
		crisis_manager.setup(self)
	else:
		crisis_manager.reset()

	_create_subsystems()
	_load_devices_from_config()
	_load_initial_faults()
	
	# Initial tick to balance grid
	tick_systems(0.0)

func _create_subsystems() -> void:
	power_system = PowerSystemScript.new()
	subsystems["power"] = power_system
	power_system.subsystem_state_changed.connect(func(sys, old, n): subsystem_state_changed.emit(sys, old, n))
	power_system.power_grid_updated.connect(func(_g, _d, _b, _e):
		var telem: Dictionary = power_system.get_grid_telemetry()
		power_grid_updated.emit(telem)
	)
	
	var coolant = SubsystemScript.new(
		"coolant",
		"Coolant Circulation & Heat Exchangers",
		SubsystemScript.State.DEGRADED,
		["power"],
		"Atmospheric coolant coupler fractured; manifold cavitation",
		"Liquid heat exchangers regulating fusion reactor core and life support.",
		6.0
	)
	subsystems["coolant"] = coolant
	coolant.subsystem_state_changed.connect(func(sys, old, n): subsystem_state_changed.emit(sys, old, n))
	
	var ls = SubsystemScript.new(
		"life_support",
		"Atmospheric Circulation & Scrubbers",
		SubsystemScript.State.FAILED,
		["power"],
		"Atmospheric coolant coupler fractured; pressure scrubber offline",
		"Maintains 1.0 ATM nitrogen-oxygen breathing mixture and climate regulation.",
		10.0
	)
	subsystems["life_support"] = ls
	ls.subsystem_state_changed.connect(func(sys, old, n): subsystem_state_changed.emit(sys, old, n))
	
	var comms = SubsystemScript.new(
		"communications",
		"Sub-Space Transceiver Array",
		SubsystemScript.State.OFFLINE,
		["power"],
		"Antenna dish servo desynchronized; frequency drift",
		"Long-range quantum communications array and emergency distress beacon.",
		5.0
	)
	subsystems["communications"] = comms
	comms.subsystem_state_changed.connect(func(sys, old, n): subsystem_state_changed.emit(sys, old, n))
	
	var prop = SubsystemScript.new(
		"propulsion",
		"Sub-Orbital Ion Thruster Bank",
		SubsystemScript.State.OFFLINE,
		["power", "life_support", "communications"],
		"Plasma injection conduits cold and unprimed",
		"Reaction mass thrusters required for orbital maneuvering and escape trajectory.",
		20.0
	)
	subsystems["propulsion"] = prop
	prop.subsystem_state_changed.connect(func(sys, old, n): subsystem_state_changed.emit(sys, old, n))
	
	var doors = SubsystemScript.new(
		"doors",
		"Bulkhead Pressure Doors & Airlocks",
		SubsystemScript.State.OFFLINE,
		["power"],
		"Door actuators awaiting distribution bus electrical power",
		"Compartment isolation doors and emergency decompression seals.",
		2.0
	)
	subsystems["doors"] = doors
	doors.subsystem_state_changed.connect(func(sys, old, n): subsystem_state_changed.emit(sys, old, n))
	
	var comp_net = SubsystemScript.new(
		"computer_network",
		"Astraea Data Network & Terminals",
		SubsystemScript.State.OFFLINE,
		["power"],
		"Workstations operating in low-power standby",
		"Internal optical computing bus and diagnostic terminals.",
		3.0
	)
	subsystems["computer_network"] = comp_net
	comp_net.subsystem_state_changed.connect(func(sys, old, n): subsystem_state_changed.emit(sys, old, n))
	
	var struct = SubsystemScript.new(
		"structural",
		"Hull & Structural Integrity",
		SubsystemScript.State.ONLINE,
		[],
		"",
		"Hull plating, micrometeorite shielding, and compartment pressure seals.",
		1.0
	)
	subsystems["structural"] = struct
	struct.subsystem_state_changed.connect(func(sys, old, n): subsystem_state_changed.emit(sys, old, n))
	
	var fuel = SubsystemScript.new(
		"fuel",
		"Fuel Storage & Reactant Feed",
		SubsystemScript.State.ONLINE,
		[],
		"",
		"Deuterium-helium3 cryogenic storage and reactant injection manifolds.",
		1.0
	)
	subsystems["fuel"] = fuel
	fuel.subsystem_state_changed.connect(func(sys, old, n): subsystem_state_changed.emit(sys, old, n))

func _load_devices_from_config() -> void:
	var path := "res://data/devices_config.json"
	var cfg: Dictionary = {}
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			var json := JSON.new()
			if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
				cfg = json.data
			f.close()
	
	# If config not found, fallback to defaults
	if cfg.is_empty():
		cfg = {
			"reactor_primary": {"name": "Fusion Turbine Generator", "subsystem": "power", "compartment": "engineering_bay", "power_draw": 0.0, "power_generation": 150.0, "criticality": 1, "health": 100.0},
			"distribution_bus": {"name": "Main Electrical Distribution Bus", "subsystem": "power", "compartment": "engineering_bay", "power_draw": 5.0, "power_generation": 0.0, "criticality": 1, "health": 100.0},
			"life_support_scrubber": {"name": "Atmospheric Scrubber Loop", "subsystem": "life_support", "compartment": "life_support", "power_draw": 25.0, "power_generation": 0.0, "criticality": 1, "health": 40.0},
			"door_aft": {"name": "Engineering Bulkhead Door", "subsystem": "doors", "compartment": "corridors", "power_draw": 4.0, "power_generation": 0.0, "criticality": 2, "health": 100.0},
			"door_fwd": {"name": "Bridge Bulkhead Door", "subsystem": "doors", "compartment": "corridors", "power_draw": 4.0, "power_generation": 0.0, "criticality": 2, "health": 100.0},
			"eng_terminal": {"name": "Engineering Diagnostics Console", "subsystem": "computer_network", "compartment": "engineering_bay", "power_draw": 3.0, "power_generation": 0.0, "criticality": 2, "health": 100.0},
			"ls_terminal": {"name": "Atmospheric Diagnostics Console", "subsystem": "computer_network", "compartment": "life_support", "power_draw": 3.0, "power_generation": 0.0, "criticality": 2, "health": 100.0},
			"bridge_terminal": {"name": "Bridge Communications Console", "subsystem": "computer_network", "compartment": "bridge", "power_draw": 3.0, "power_generation": 0.0, "criticality": 2, "health": 100.0},
			"comms_array": {"name": "Sub-Space Transceiver Array", "subsystem": "communications", "compartment": "bridge", "power_draw": 15.0, "power_generation": 0.0, "criticality": 3, "health": 75.0},
			"ion_propulsion": {"name": "Sub-Orbital Ion Thruster Bank", "subsystem": "propulsion", "compartment": "bridge", "power_draw": 60.0, "power_generation": 0.0, "criticality": 3, "health": 100.0}
		}
	
	for dev_id in cfg.keys():
		var dinfo: Dictionary = cfg[dev_id]
		var dev = ShipDeviceScript.new(
			dev_id,
			str(dinfo.get("name", dev_id)),
			str(dinfo.get("subsystem", "power")),
			str(dinfo.get("compartment", "engineering_bay")),
			float(dinfo.get("power_draw", 0.0)),
			float(dinfo.get("power_generation", 0.0)),
			int(dinfo.get("criticality", 2)),
			float(dinfo.get("health", 100.0)),
			str(dinfo.get("description", ""))
		)
		devices[dev_id] = dev
		
		# Register to its primary subsystem
		var sub = subsystems.get(dev.subsystem_id, null)
		if sub != null and sub.has_method("register_device"):
			sub.register_device(dev)
		
		# All devices with power draw or generation connect to power_system
		if power_system != null and power_system.has_method("register_device"):
			power_system.register_device(dev)
		
		if dev.has_signal("device_state_changed"):
			dev.device_state_changed.connect(func(did, is_pwr, hp):
				device_updated.emit(did, is_pwr, hp)
			)

func _load_initial_faults() -> void:
	var path := "res://data/faults_config.json"
	var cfg: Dictionary = {}
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			var json := JSON.new()
			if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
				cfg = json.data
			f.close()
	
	for f_id in cfg.keys():
		var finfo: Dictionary = cfg[f_id]
		if not finfo.get("initial_active", true):
			continue
		var symptoms_arr: Array[String] = []
		for s in finfo.get("symptoms", []):
			symptoms_arr.append(str(s))
		var diag_arr: Array[String] = []
		for d in finfo.get("diagnostic_method", []):
			diag_arr.append(str(d))
		var parts_arr: Array[String] = []
		for p in finfo.get("required_parts", []):
			parts_arr.append(str(p))
		var repair_arr: Array[String] = []
		for r in finfo.get("repair_steps", []):
			repair_arr.append(str(r))
		
		var fault = FaultScript.new(
			f_id,
			str(finfo.get("subsystem", "")),
			str(finfo.get("device_id", "")),
			str(finfo.get("root_cause", "")),
			symptoms_arr,
			diag_arr,
			parts_arr,
			repair_arr,
			str(finfo.get("workaround", "")),
			str(finfo.get("consequence", "")),
			str(finfo.get("narrative_clue", ""))
		)
		active_faults[f_id] = fault
		
		# Attach to device
		var dev = devices.get(fault.device_id, null)
		if dev != null and dev.has_method("add_fault"):
			dev.add_fault(fault)
		
		# Attach to subsystem
		var sub = subsystems.get(fault.subsystem_id, null)
		if sub != null and sub.has_method("add_fault"):
			sub.add_fault(fault)

var _is_syncing: bool = false
var _schematic_timer: float = 0.0

func _process(delta: float) -> void:
	tick_systems(delta)

func tick_systems(delta: float) -> void:
	for sub in subsystems.values():
		if sub != null and sub.has_method("tick"):
			sub.tick(delta)
	
	if crisis_manager != null and delta > 0.0:
		crisis_manager.tick(delta)
	
	# Update dependent subsystem states based on power & faults
	_evaluate_subsystem_dependencies()
	
	if delta == 0.0:
		schematic_updated.emit(get_schematic_data())
	else:
		_schematic_timer += delta
		if _schematic_timer >= 0.1: # 10 Hz rate limit
			_schematic_timer = 0.0
			schematic_updated.emit(get_schematic_data())

func _evaluate_subsystem_dependencies() -> void:
	var bus_live: bool = power_system.bus_energized if power_system != null else false
	
	# Coolant subsystem
	var coolant_sub = subsystems.get("coolant", null)
	if coolant_sub != null:
		var has_coolant_fault := active_faults.has("COOLANT_COUPLER_FRACTURE")
		if has_coolant_fault:
			coolant_sub.set_state(SubsystemScript.State.FAILED, "Coolant coupler fractured; manifold cavitation")
			coolant_sub.receive_power(coolant_sub.get_power_draw() * 0.35 if bus_live else 0.0)
			if power_system != null:
				power_system.coolant_flow_rate = 0.35
		else:
			if bus_live:
				coolant_sub.set_state(SubsystemScript.State.ONLINE, "Coolant circulation nominal")
				coolant_sub.receive_power(coolant_sub.get_power_draw())
				if power_system != null:
					power_system.coolant_flow_rate = 1.0
			else:
				coolant_sub.set_state(SubsystemScript.State.DEGRADED, "Awaiting bus electrical power")
				coolant_sub.receive_power(0.0)
				if power_system != null:
					power_system.coolant_flow_rate = 0.6
	
	# Doors subsystem
	var doors_sub = subsystems.get("doors", null)
	if doors_sub != null:
		if bus_live:
			doors_sub.receive_power(doors_sub.get_power_draw())
			if doors_sub.state != SubsystemScript.State.ONLINE:
				doors_sub.set_state(SubsystemScript.State.ONLINE, "Actuators energized")
		else:
			doors_sub.receive_power(0.0)
			if doors_sub.state != SubsystemScript.State.OFFLINE:
				doors_sub.set_state(SubsystemScript.State.OFFLINE, "No electrical bus power")
	
	# Computer Network subsystem
	var comp_sub = subsystems.get("computer_network", null)
	if comp_sub != null:
		if bus_live:
			comp_sub.receive_power(comp_sub.get_power_draw())
			if comp_sub.state != SubsystemScript.State.ONLINE:
				comp_sub.set_state(SubsystemScript.State.ONLINE, "Data network nominal")
		else:
			comp_sub.receive_power(0.0)
			if comp_sub.state != SubsystemScript.State.OFFLINE:
				comp_sub.set_state(SubsystemScript.State.OFFLINE, "Operating in low-power standby")
	
	# Life Support subsystem
	var ls_sub = subsystems.get("life_support", null)
	if ls_sub != null:
		var has_ls_fault := active_faults.has("COOLANT_COUPLER_FRACTURE")
		if has_ls_fault:
			ls_sub.receive_power(ls_sub.get_power_draw() * 0.4 if bus_live else 0.0)
			if ls_sub.state != SubsystemScript.State.FAILED:
				ls_sub.set_state(SubsystemScript.State.FAILED, "Atmospheric coolant coupler fractured; pressure scrubber offline")
		elif bus_live:
			ls_sub.receive_power(ls_sub.get_power_draw())
			if ls_sub.state != SubsystemScript.State.ONLINE:
				ls_sub.set_state(SubsystemScript.State.ONLINE, "Scrubbers regenerating O2")
		else:
			ls_sub.receive_power(0.0)
			if ls_sub.state != SubsystemScript.State.DEGRADED:
				ls_sub.set_state(SubsystemScript.State.DEGRADED, "Coupler installed; awaiting bus electrical power")
	
	# Communications subsystem
	var comms_sub = subsystems.get("communications", null)
	if comms_sub != null:
		var has_comms_fault := active_faults.has("COMMS_SERVO_DESYNC")
		if has_comms_fault:
			comms_sub.receive_power(comms_sub.get_power_draw() * 0.5 if bus_live else 0.0)
			if comms_sub.state != SubsystemScript.State.OFFLINE:
				comms_sub.set_state(SubsystemScript.State.OFFLINE, "Antenna dish servo desynchronized; frequency drift")
		elif bus_live:
			comms_sub.receive_power(comms_sub.get_power_draw())
			if comms_sub.state != SubsystemScript.State.ONLINE:
				comms_sub.set_state(SubsystemScript.State.ONLINE, "Array calibrated and receiving telemetry")
		else:
			comms_sub.receive_power(0.0)
			if comms_sub.state != SubsystemScript.State.OFFLINE:
				comms_sub.set_state(SubsystemScript.State.OFFLINE, "Awaiting distribution bus power")
	
	# Propulsion subsystem
	var prop_sub = subsystems.get("propulsion", null)
	if prop_sub != null:
		var is_prop_online: bool = has_node("/root/ShipSystemManager") and get_node("/root/ShipSystemManager").propulsion_primed
		if is_prop_online and bus_live:
			prop_sub.receive_power(prop_sub.get_power_draw())
			if prop_sub.state != SubsystemScript.State.ONLINE:
				prop_sub.set_state(SubsystemScript.State.ONLINE, "Ion thrusters ignited; departure sequence initiated")
		else:
			prop_sub.receive_power(prop_sub.get_power_draw() * 0.1 if bus_live else 0.0)
			if prop_sub.state != SubsystemScript.State.OFFLINE:
				prop_sub.set_state(SubsystemScript.State.OFFLINE, "Plasma injection conduits cold and unprimed")
	
	# Structural & Fuel subsystems
	var struct_sub = subsystems.get("structural", null)
	if struct_sub != null:
		struct_sub.receive_power(struct_sub.get_power_draw())
	var fuel_sub = subsystems.get("fuel", null)
	if fuel_sub != null:
		fuel_sub.receive_power(fuel_sub.get_power_draw())
	
	# Apply active manual overrides
	for sub_id in manual_overrides.keys():
		var over_sub = subsystems.get(sub_id, null)
		if over_sub != null:
			var is_on: bool = bool(manual_overrides[sub_id])
			over_sub.set_state(SubsystemScript.State.ONLINE if is_on else SubsystemScript.State.OFFLINE, "Manual override applied by engineer")
	
	# Apply active power rerouting connections across simulation ticks
	for dst_id in power_routes.keys():
		var src_id: String = str(power_routes[dst_id])
		var src_dev = devices.get(src_id, null)
		var dst_dev = devices.get(dst_id, null)
		if src_dev != null and dst_dev != null:
			dst_dev.is_powered = src_dev.is_powered

# Interactive control methods
func set_generator_breaker(closed: bool) -> Dictionary:
	var res: Dictionary = power_system.set_generator(closed)
	if closed:
		resolve_fault("GENERATOR_TRIP")
	else:
		_retrigger_fault("GENERATOR_TRIP")
	
	if not _is_syncing and has_node("/root/ShipSystemManager"):
		var ssm = get_node("/root/ShipSystemManager")
		if ssm.generator_breaker_closed != closed:
			_is_syncing = true
			ssm.set_generator_breaker(closed)
			_is_syncing = false
	
	tick_systems(0.0)
	return res

func set_bus_relay(closed: bool) -> Dictionary:
	var res: Dictionary = power_system.set_bus_relay(closed)
	if res.get("ok", false) and closed:
		resolve_fault("BUS_ISOLATION")
	elif not closed:
		_retrigger_fault("BUS_ISOLATION")
	
	if not _is_syncing and has_node("/root/ShipSystemManager"):
		var ssm = get_node("/root/ShipSystemManager")
		var target_state: bool = bool(res.get("ok", false)) and closed
		if ssm.bus_relay_closed != target_state:
			_is_syncing = true
			ssm.set_power_distribution(closed)
			_is_syncing = false
	
	tick_systems(0.0)
	return res

func install_coolant_coupler() -> Dictionary:
	resolve_fault("COOLANT_COUPLER_FRACTURE")
	var ls = subsystems.get("life_support", null)
	var ls_dev = devices.get("life_support_scrubber", null)
	if ls_dev != null and ls_dev.has_method("repair"):
		ls_dev.repair(60.0)
	
	var coolant_sub = subsystems.get("coolant", null)
	if coolant_sub != null and coolant_sub.has_method("repair"):
		coolant_sub.repair(100.0)
	var coolant_dev = devices.get("coolant_pump", null)
	if coolant_dev != null and coolant_dev.has_method("repair"):
		coolant_dev.repair(100.0)
	if power_system != null:
		power_system.coolant_flow_rate = 1.0
	
	if ls != null:
		if power_system != null and power_system.bus_energized:
			ls.set_state(SubsystemScript.State.ONLINE, "Scrubbers regenerating O2")
		else:
			ls.set_state(SubsystemScript.State.DEGRADED, "Coupler installed; awaiting bus electrical power")
	
	if not _is_syncing and has_node("/root/ShipSystemManager"):
		var ssm = get_node("/root/ShipSystemManager")
		if not ssm.coolant_coupler_installed:
			_is_syncing = true
			ssm.install_coolant_coupler()
			_is_syncing = false
	
	tick_systems(0.0)
	return {"ok": true, "installed": true}

func align_comms_array() -> Dictionary:
	if power_system == null or not power_system.bus_energized:
		return {"ok": false, "reason": "Awaiting main distribution bus power"}
	resolve_fault("COMMS_SERVO_DESYNC")
	var comms = subsystems.get("communications", null)
	if comms != null:
		comms.set_state(SubsystemScript.State.ONLINE, "Array calibrated and receiving telemetry")
	var comms_dev = devices.get("comms_array", null)
	if comms_dev != null and comms_dev.has_method("repair"):
		comms_dev.repair(25.0)
	
	if not _is_syncing and has_node("/root/ShipSystemManager"):
		var ssm = get_node("/root/ShipSystemManager")
		if not ssm.comms_array_aligned:
			_is_syncing = true
			ssm.align_comms_array()
			_is_syncing = false
	
	tick_systems(0.0)
	return {"ok": true, "aligned": true}

func engage_propulsion() -> Dictionary:
	var comms_online: bool = subsystems["communications"].is_online() if subsystems.has("communications") else false
	var ls_online: bool = subsystems["life_support"].is_online() if subsystems.has("life_support") else false
	var bus_online: bool = power_system.bus_energized if power_system != null else false
	
	if not (bus_online and ls_online and comms_online):
		var reasons: Array[String] = []
		if not bus_online: reasons.append("Power Distribution")
		if not ls_online: reasons.append("Life Support")
		if not comms_online: reasons.append("Communications")
		return {"ok": false, "reason": "Prerequisites offline: " + ", ".join(reasons)}
	
	var prop = subsystems.get("propulsion", null)
	if prop != null:
		prop.set_state(SubsystemScript.State.ONLINE, "Ion thrusters ignited; departure sequence initiated")
	
	if not _is_syncing and has_node("/root/ShipSystemManager"):
		var ssm = get_node("/root/ShipSystemManager")
		if not ssm.propulsion_primed:
			_is_syncing = true
			ssm.engage_propulsion()
			_is_syncing = false
	
	tick_systems(0.0)
	return {"ok": true, "ignited": true}

func reroute_auxiliary_scrubber(enabled: bool) -> Dictionary:
	auxiliary_scrubber_active = enabled
	var dev = devices.get("ls_scrubber_aux", null)
	if dev != null:
		dev.power_draw = 2.0 if enabled else 0.0
	tick_systems(0.0)
	return {"ok": true, "active": auxiliary_scrubber_active}

func reroute_power(source: String, destination: String) -> Dictionary:
	power_routes[destination] = source
	power_rerouted = not power_routes.is_empty()
	var src_dev = devices.get(source, null)
	var dst_dev = devices.get(destination, null)
	if src_dev != null and dst_dev != null:
		dst_dev.is_powered = src_dev.is_powered
	tick_systems(0.0)
	return {"ok": true, "source": source, "destination": destination}

func clear_power_reroutes() -> void:
	power_routes.clear()
	power_rerouted = false
	tick_systems(0.0)

func reroute_coolant_loop(bypass_active: bool) -> Dictionary:
	coolant_bypass_active = bypass_active
	if power_system != null and "coolant_flow_rate" in power_system:
		power_system.coolant_flow_rate = 0.85 if bypass_active else 1.0
	tick_systems(0.0)
	return {"ok": true, "bypass_active": coolant_bypass_active}

func manual_override_subsystem(subsystem_id: String, state: bool) -> Dictionary:
	manual_overrides[subsystem_id] = state
	var sub = subsystems.get(subsystem_id, null)
	if sub != null:
		var target_state: int = SubsystemScript.State.ONLINE if state else SubsystemScript.State.OFFLINE
		sub.set_state(target_state, "Manual override applied by engineer")
	tick_systems(0.0)
	return {"ok": true, "subsystem": subsystem_id, "state": state}

func simulate_fault(f_id: String, activate: bool) -> void:
	if activate:
		trigger_fault(f_id)
	else:
		resolve_fault(f_id)

func resolve_fault(f_id: String) -> void:
	if active_faults.has(f_id):
		var f = active_faults[f_id]
		if f.has_method("resolve"):
			f.resolve()
		active_faults.erase(f_id)
		
		var dev = devices.get(f.device_id, null)
		if dev != null and dev.has_method("remove_fault"):
			dev.remove_fault(f_id)
		
		var sub = subsystems.get(f.subsystem_id, null)
		if sub != null and sub.has_method("clear_fault"):
			sub.clear_fault(f_id)
		
		fault_resolved.emit(f_id)

func clear_all_faults() -> void:
	for fid in active_faults.keys().duplicate():
		resolve_fault(fid)
	for dev in devices.values():
		if dev != null and "active_faults" in dev:
			dev.active_faults.clear()
	for sub in subsystems.values():
		if sub != null and "active_faults" in sub:
			sub.active_faults.clear()

func trigger_fault(f_id: String) -> RefCounted:
	if active_faults.has(f_id):
		return active_faults[f_id]
	
	var path := "res://data/faults_config.json"
	var cfg: Dictionary = {}
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			var json := JSON.new()
			if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
				cfg = json.data
			f.close()
	
	if not cfg.has(f_id):
		return null
	
	var finfo: Dictionary = cfg[f_id]
	var symptoms_arr: Array[String] = []
	for s in finfo.get("symptoms", []):
		symptoms_arr.append(str(s))
	var diag_arr: Array[String] = []
	for d in finfo.get("diagnostic_method", []):
		diag_arr.append(str(d))
	var parts_arr: Array[String] = []
	for p in finfo.get("required_parts", []):
		parts_arr.append(str(p))
	var repair_arr: Array[String] = []
	for r in finfo.get("repair_steps", []):
		repair_arr.append(str(r))
	
	var fault = FaultScript.new(
		f_id,
		str(finfo.get("subsystem", "")),
		str(finfo.get("device_id", "")),
		str(finfo.get("root_cause", "")),
		symptoms_arr,
		diag_arr,
		parts_arr,
		repair_arr,
		str(finfo.get("workaround", "")),
		str(finfo.get("consequence", "")),
		str(finfo.get("narrative_clue", ""))
	)
	active_faults[f_id] = fault
	
	var dev = devices.get(fault.device_id, null)
	if dev != null and dev.has_method("add_fault"):
		dev.add_fault(fault)
	
	var sub = subsystems.get(fault.subsystem_id, null)
	if sub != null and sub.has_method("add_fault"):
		sub.add_fault(fault)
	
	fault_added.emit(fault)
	tick_systems(0.0)
	return fault

func _retrigger_fault(f_id: String) -> void:
	if not active_faults.has(f_id):
		trigger_fault(f_id)

func get_device(dev_id: String) -> RefCounted:
	return devices.get(dev_id, null)

func get_subsystem(sub_id: String) -> RefCounted:
	return subsystems.get(sub_id, null)

func get_compartment_devices(compartment_id: String) -> Array:
	var result: Array = []
	for dev in devices.values():
		if dev != null and "compartment_id" in dev and dev.compartment_id == compartment_id:
			result.append(dev)
	return result

func get_schematic_data() -> Dictionary:
	var telem: Dictionary = power_system.get_grid_telemetry() if power_system != null else {}
	
	var comp_statuses: Dictionary = {}
	for c_id in COMPARTMENTS.keys():
		var c_devices: Array = get_compartment_devices(c_id)
		var total_draw: float = 0.0
		var powered_count: int = 0
		var compartment_faults: Array[String] = []
		
		for dev in c_devices:
			if dev.has_method("get_power_draw"):
				total_draw += dev.get_power_draw()
			if "is_powered" in dev and dev.is_powered:
				powered_count += 1
			if "active_faults" in dev:
				for f in dev.active_faults:
					if f.is_active:
						compartment_faults.append(f.root_cause)
		
		var is_room_powered: bool = false
		if power_system != null:
			is_room_powered = power_system.bus_energized or (c_id == "engineering_bay" and power_system.reactor_online)
		
		var env_data: Dictionary = {
			"o2_level": 100.0,
			"co2_ppm": 420.0,
			"temperature": 294.15,
			"pressure": 101.3,
			"active_hazards": []
		}
		var env_mgr: Node = null
		if EnvironmentalManager != null and "instance" in EnvironmentalManager and EnvironmentalManager.instance != null:
			env_mgr = EnvironmentalManager.instance
		elif has_node("/root/EnvironmentalManager"):
			env_mgr = get_node("/root/EnvironmentalManager")
		
		if env_mgr != null and env_mgr.has_method("get_compartment_atmosphere"):
			var atmo: Dictionary = env_mgr.get_compartment_atmosphere(c_id)
			if not atmo.is_empty():
				env_data = atmo
		
		comp_statuses[c_id] = {
			"name": COMPARTMENTS[c_id]["name"],
			"is_powered": is_room_powered,
			"devices_count": c_devices.size(),
			"powered_count": powered_count,
			"total_draw": total_draw,
			"faults": compartment_faults,
			"atmosphere": env_data
		}
	
	# Compute high-level actionable guidance
	var primary_warning := ""
	var primary_action := ""
	if power_system != null and not power_system.reactor_online:
		primary_warning = "PRIMARY GENERATOR TRIPPED // TOTAL GRID POWER LOSS IMMINENT"
		primary_action = "Investigate Engineering Bay: Close primary generator breaker."
	elif power_system != null and not power_system.bus_relay_closed:
		primary_warning = "MAIN BUS ISOLATED // SUBSYSTEMS & BULKHEAD DOORS UNPOWERED"
		primary_action = "Investigate Engineering Bay: Energize distribution bus relay."
	elif power_system != null and power_system.thermal_throttled:
		primary_warning = "REACTOR THERMAL THROTTLING // CORE TEMPERATURE EXCEEDS 550K"
		primary_action = "Restore coolant circulation manifold in Life Support to cool reactor."
	elif active_faults.has("CABIN_PRESSURE_LEAK"):
		primary_warning = "HULL BREACH DETECTED // RAPID CABIN DECOMPRESSION"
		primary_action = "Isolate affected compartment bulkhead doors or seal hull puncture."
	elif active_faults.has("THERMAL_RUNAWAY"):
		primary_warning = "THERMAL RUNAWAY // CABIN CLIMATE OVERHEATING CRITICALLY"
		primary_action = "Operate radiator bypass valve or reset climate thermal exchanger."
	elif active_faults.has("CO2_SCRUBBER_SATURATION"):
		primary_warning = "CO2 SCRUBBER SATURATED // TOXIC HYPERCAPNIA IMMINENT"
		primary_action = "Replace scrubber chemical cartridge or trigger terminal emergency purge."
	elif active_faults.has("COOLANT_COUPLER_FRACTURE"):
		primary_warning = "ATMOSPHERIC CAVITATION // OXYGEN VENTING IN LIFE SUPPORT"
		primary_action = "Obtain spare coupler from Engineering; install in Life Support manifold."
	elif active_faults.has("COMMS_SERVO_DESYNC"):
		primary_warning = "COMMS ARRAY DESYNCHRONIZED // INCIDENT LOGS CORRUPTED"
		primary_action = "Access Bridge console; lock sub-space antenna frequency."
	else:
		primary_warning = "ALL CORE SYSTEMS NOMINAL // SHIP INTEGRITY SECURED"
		primary_action = "Verify Helm console on Bridge; engage orbital departure thrusters."
	
	return {
		"power": telem,
		"compartments": comp_statuses,
		"active_faults_count": active_faults.size(),
		"auxiliary_scrubber_active": auxiliary_scrubber_active,
		"has_revelation_anomaly": has_revelation_anomaly,
		"has_revelation_quarantine": has_revelation_quarantine,
		"has_revelation_directive": has_revelation_directive,
		"commander_override_code": commander_override_code,
		"primary_warning": primary_warning,
		"primary_action": primary_action
	}

func get_scrubber_efficiency_multiplier() -> float:
	return scrubber_efficiency_multiplier

func reset_revelation_bonuses() -> void:
	has_revelation_anomaly = false
	has_revelation_quarantine = false
	has_revelation_directive = false
	scrubber_efficiency_multiplier = 1.0
	commander_override_code = ""
	quarantine_lockout_cleared = false
	thruster_efficiency_boost = 1.0
	if power_system != null and power_system.has_method("set_harmonic_damping"):
		power_system.set_harmonic_damping(false)
	var react_dev = devices.get("reactor_primary", null)
	if react_dev != null and "power_generation" in react_dev:
		react_dev.power_generation = 150.0
	var prop_dev = devices.get("ion_propulsion", null)
	if prop_dev != null and "power_draw" in prop_dev:
		prop_dev.power_draw = 60.0
	tick_systems(0.0)

func apply_revelation_bonus(revelation_id: String) -> Dictionary:
	match revelation_id:
		"revelation_anomaly":
			has_revelation_anomaly = true
			if power_system != null and power_system.has_method("set_harmonic_damping"):
				power_system.set_harmonic_damping(true)
			var react_dev = devices.get("reactor_primary", null)
			if react_dev != null and "power_generation" in react_dev:
				react_dev.power_generation = 160.0
			tick_systems(0.0)
			return {
				"ok": true,
				"revelation_id": revelation_id,
				"thermal_accumulation_multiplier": 0.85,
				"auxiliary_headroom_kw": 10.0
			}
		"revelation_quarantine":
			has_revelation_quarantine = true
			scrubber_efficiency_multiplier = 1.20
			tick_systems(0.0)
			return {
				"ok": true,
				"revelation_id": revelation_id,
				"scrubber_efficiency_multiplier": scrubber_efficiency_multiplier
			}
		"revelation_directive":
			has_revelation_directive = true
			commander_override_code = "7394-OMEGA"
			quarantine_lockout_cleared = true
			thruster_efficiency_boost = 1.25
			var prop_dev = devices.get("ion_propulsion", null)
			if prop_dev != null and "power_draw" in prop_dev:
				prop_dev.power_draw = 48.0
			tick_systems(0.0)
			return {
				"ok": true,
				"revelation_id": revelation_id,
				"commander_override_code": commander_override_code,
				"quarantine_lockout_cleared": quarantine_lockout_cleared,
				"thruster_efficiency_boost": thruster_efficiency_boost
			}
	return {"ok": false, "revelation_id": revelation_id}

func reset_to_defaults() -> void:
	initialize_ship()
	if not _is_syncing and has_node("/root/ShipSystemManager"):
		var ssm = get_node("/root/ShipSystemManager")
		if ssm.generator_breaker_closed or ssm.bus_relay_closed or ssm.coolant_coupler_installed:
			_is_syncing = true
			ssm.reset_to_defaults()
			_is_syncing = false

func export_save_data() -> Dictionary:
	var sub_data: Dictionary = {}
	for k in subsystems.keys():
		var s = subsystems[k]
		if s != null and s.has_method("to_dict"):
			sub_data[k] = s.to_dict()
	
	var dev_data: Dictionary = {}
	for k in devices.keys():
		var d = devices[k]
		if d != null and d.has_method("to_dict"):
			dev_data[k] = d.to_dict()
	
	var fault_ids: Array[String] = []
	for fid in active_faults.keys():
		var f = active_faults[fid]
		if f != null and "is_active" in f and f.is_active:
			fault_ids.append(fid)
	
	return {
		"subsystems": sub_data,
		"devices": dev_data,
		"active_fault_ids": fault_ids,
		"auxiliary_scrubber_active": auxiliary_scrubber_active,
		"power_rerouted": power_rerouted,
		"power_routes": power_routes.duplicate(),
		"coolant_bypass_active": coolant_bypass_active,
		"manual_overrides": manual_overrides.duplicate(),
		"has_revelation_anomaly": has_revelation_anomaly,
		"has_revelation_quarantine": has_revelation_quarantine,
		"has_revelation_directive": has_revelation_directive,
		"scrubber_efficiency_multiplier": scrubber_efficiency_multiplier,
		"commander_override_code": commander_override_code,
		"quarantine_lockout_cleared": quarantine_lockout_cleared,
		"thruster_efficiency_boost": thruster_efficiency_boost,
		"crisis_manager": crisis_manager.serialize() if crisis_manager != null else {}
	}

func import_save_data(data: Dictionary) -> void:
	reset_revelation_bonuses()
	if data.has("subsystems"):
		var sdata: Dictionary = data["subsystems"]
		for k in sdata.keys():
			if subsystems.has(k) and subsystems[k].has_method("from_dict"):
				subsystems[k].from_dict(sdata[k])
	
	if data.has("devices"):
		var ddata: Dictionary = data["devices"]
		for k in ddata.keys():
			if devices.has(k) and devices[k].has_method("from_dict"):
				devices[k].from_dict(ddata[k])
	
	if data.has("auxiliary_scrubber_active"):
		auxiliary_scrubber_active = bool(data["auxiliary_scrubber_active"])
		reroute_auxiliary_scrubber(auxiliary_scrubber_active)
	
	power_routes.clear()
	if data.has("power_routes") and data["power_routes"] is Dictionary:
		power_routes = data["power_routes"].duplicate()
		power_rerouted = not power_routes.is_empty()
		for dst_id in power_routes.keys():
			var src_id: String = str(power_routes[dst_id])
			var s_dev = devices.get(src_id, null)
			var d_dev = devices.get(dst_id, null)
			if s_dev != null and d_dev != null:
				d_dev.is_powered = s_dev.is_powered
	else:
		power_rerouted = bool(data.get("power_rerouted", false))
	
	coolant_bypass_active = bool(data.get("coolant_bypass_active", false))
	reroute_coolant_loop(coolant_bypass_active)
	
	if data.has("manual_overrides") and data["manual_overrides"] is Dictionary:
		manual_overrides = data["manual_overrides"].duplicate()
		for sub_id in manual_overrides.keys():
			manual_override_subsystem(sub_id, bool(manual_overrides[sub_id]))
	
	has_revelation_anomaly = bool(data.get("has_revelation_anomaly", false))
	if has_revelation_anomaly:
		apply_revelation_bonus("revelation_anomaly")
	
	has_revelation_quarantine = bool(data.get("has_revelation_quarantine", false))
	if has_revelation_quarantine:
		apply_revelation_bonus("revelation_quarantine")
	
	has_revelation_directive = bool(data.get("has_revelation_directive", false))
	if has_revelation_directive:
		apply_revelation_bonus("revelation_directive")
	
	if data.has("active_fault_ids"):
		var f_ids: Array = data["active_fault_ids"]
		active_faults.clear()
		_load_initial_faults()
		for existing_id in active_faults.keys().duplicate():
			if not f_ids.has(existing_id):
				resolve_fault(existing_id)
		for fid in f_ids:
			if not active_faults.has(str(fid)):
				trigger_fault(str(fid))
	
	if data.has("crisis_manager") and data["crisis_manager"] is Dictionary and crisis_manager != null:
		crisis_manager.deserialize(data["crisis_manager"])
	elif crisis_manager != null:
		crisis_manager.reset()
	
	tick_systems(0.0)

func start_crisis(type: int, start_stage: int = 1) -> void:
	if crisis_manager != null:
		crisis_manager.start_crisis(type, start_stage)

func advance_crisis_stage() -> void:
	if crisis_manager != null:
		crisis_manager.advance_crisis_stage()

func trigger_cascading_fault(arg1: String, arg2: String = "") -> bool:
	if crisis_manager != null:
		var parent := arg1 if arg2 != "" else "SYSTEM_ANOMALY"
		var cascaded := arg2 if arg2 != "" else arg1
		return crisis_manager.trigger_cascading_fault(parent, cascaded)
	return false

func trap_creature_in_chamber(chamber_id: String = "airlock_chamber") -> bool:
	if crisis_manager != null:
		return crisis_manager.trap_creature(chamber_id)
	return false

func purge_creature_with_poison_gas(chamber_id: String = "") -> bool:
	if crisis_manager != null:
		return crisis_manager.execute_poison_gas_purge(chamber_id)
	return false

func resolve_crisis() -> void:
	if crisis_manager != null:
		crisis_manager.resolve_current_crisis()
