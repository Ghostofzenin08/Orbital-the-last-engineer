extends Node

# Mission Manager Autoload for ORBITAL: The Last Engineer
# Manages sequential objectives, inventory items, and crew narrative logs.

signal objective_updated(current_index: int, title: String, description: String)
signal objective_completed(completed_index: int, title: String)
signal inventory_changed(items: Array[String])
signal all_objectives_completed
signal room_discovered(room_id: String, room_name: String)
signal airlock_cycled
signal breach_sealed(compartment_id: String)

const OBJECTIVES: Array[Dictionary] = [
	{
		"id": "obj_primary_power",
		"title": "Restore Emergency Generator",
		"desc": "Locate the primary fusion generator in the Engineering Bay and close the manual generator breaker."
	},
	{
		"id": "obj_power_distribution",
		"title": "Energize Main Electrical Bus",
		"desc": "Flip the main distribution bus switch in the Engineering Bay to route power to bulkhead doors and ship modules."
	},
	{
		"id": "obj_life_support",
		"title": "Repair Atmospheric Coolant Coupler",
		"desc": "Retrieve a spare coupler from the Engineering storage rack, proceed through the corridor to the Life Support Module, and install it into the coolant manifold."
	},
	{
		"id": "obj_communications",
		"title": "Align Comms Array & Access Logs",
		"desc": "Enter the Bridge, access the Communications Terminal, calibrate the antenna dish, and review the crew's emergency logs."
	},
	{
		"id": "obj_propulsion",
		"title": "Initiate Orbital Departure Burn",
		"desc": "At the Bridge Helm Console, verify all subsystems nominal and engage the orbital departure thruster switch."
	}
]

const CREW_LOGS: Array[Dictionary] = [
	{
		"id": "log_01",
		"author": "Chief Engineer Vasquez",
		"date": "Cycle 2184.102",
		"title": "Turbine Harmonic Resonance",
		"content": "Generator turbine 2 is showing high-frequency harmonic vibration following our braking burn near Kharon-4. Diagnostics report no blade deformation, but the magnetic containment coils are running 14% hotter than spec. I've locked the breaker on local manual override until we calibrate the bus."
	},
	{
		"id": "log_02",
		"author": "Commander Hayes",
		"date": "Cycle 2184.105",
		"title": "Orbital Capture Anomalies",
		"content": "Navigation confirmed we are locked in low orbit around Kharon-4. The planet's magnetic field is erratic—far denser than spectroscopic models predicted. We caught a high-intensity microwave pulse from the southern hemisphere during perigee. All telemetry instruments flickered for three seconds."
	},
	{
		"id": "log_03",
		"author": "Specialist Chen",
		"date": "Cycle 2184.107",
		"title": "Coolant Cavitation Notice",
		"content": "Atmospheric scrubber loop B experienced violent cavitation during the last orbital transit. The primary ceramic coupler fractured cleanly at the seal. I've salvaged two functional spare couplers and placed them in the Engineering Bay storage rack near the generator."
	},
	{
		"id": "log_04",
		"author": "Dr. Aris Thorne",
		"date": "Cycle 2184.110",
		"title": "Physiological Advisory",
		"content": "Three crew members reported severe auditory illusions—specifically, rhythmic metallic tapping through the bulkheads that does not correlate with hull vibration sensors. Sleep architecture in all subjects is degraded. The planet below radiates an ELF resonance directly through our shielding."
	},
	{
		"id": "log_05",
		"author": "Chief Engineer Vasquez",
		"date": "Cycle 2184.112",
		"title": "Bus Isolation Implemented",
		"content": "To protect flight avionics from whatever is pulsing from the planet's surface, I have severed the main electrical distribution bus. Only emergency battery conduits remain live. Re-engaging the bus requires closing the primary generator breaker first."
	},
	{
		"id": "log_06",
		"author": "Commander Hayes",
		"date": "Cycle 2184.114",
		"title": "Evacuation of Pod Bay 1",
		"content": "Catastrophic electrical surge occurred at 0400 hours. Pod Bay 1 jettisoned prematurely with six crew members aboard. Orbital vectors indicate their trajectory descended toward Kharon-4's upper stratosphere. Sub-space comms are completely scrambled."
	},
	{
		"id": "log_07",
		"author": "Specialist Chen",
		"date": "Cycle 2184.115",
		"title": "Atmospheric Containment Loss",
		"content": "Scrubber loop failed completely. Ambient oxygen levels are bleeding into the venting conduits whenever main bus power is lost. If life support is not supplied with both electrical power and a sound coupler, atmospheric asphyxiation is inevitable."
	},
	{
		"id": "log_08",
		"author": "Nav Officer Lin",
		"date": "Cycle 2184.117",
		"title": "Orbital Decay Calculation",
		"content": "Atmospheric drag at 220 km is pulling Astraea-7 inward. Without an immediate orbital departure burn from the ion engines, the hull will enter thermal re-entry in approximately 12 hours. We cannot ignite the drives until power, life support, and comms telemetry are restored."
	},
	{
		"id": "log_09",
		"author": "Chief Engineer Vasquez",
		"date": "Cycle 2184.118",
		"title": "Final Engineering Directive",
		"content": "The commander and remaining bridge officers have gone dark. I am sealing the Engineering Bay and setting the automated stasis pod to awaken the standby engineer if life support drops below threshold. If you are reading this: follow the restoration sequence, prime the drives, and get Astraea-7 out of this orbit."
	},
	{
		"id": "log_10",
		"author": "Astraea-7 Central Computer",
		"date": "Cycle 2184.120",
		"title": "Automated Beacon Status",
		"content": "SYSTEM SUMMARY: Distress beacon broadcast pending antenna servo alignment. Ion propulsion primed upon bus re-energization and atmospheric stabilization. Standby engineer awaken signal dispatched."
	}
]

const EXPANSION_CREW_LOGS: Array[Dictionary] = [
	{
		"id": "log_11",
		"author": "Commander Hayes",
		"date": "Cycle 2184.116",
		"title": "Bridge Command Directives",
		"content": "With telemetry failing and Kharon-4's pulse disabling avionics, I have ordered all non-essential crew to pod staging. The navigation holotable is locked with departure coordinates to the jump gate. If engineering can stabilize the reactor and bus, engage the departure burn immediately."
	},
	{
		"id": "log_12",
		"author": "Dr. Aris Thorne",
		"date": "Cycle 2184.111",
		"title": "Infirmary Triage Log",
		"content": "Infirmary is flooded with acute carbon dioxide and hypoxia casualties. We've depleted half our trauma kits. The medical oxygen booster in Medbay is operational but requires auxiliary bus power. Do not let the scrubber loop offline again."
	},
	{
		"id": "log_13",
		"author": "Quartermaster Reyes",
		"date": "Cycle 2184.113",
		"title": "Cargo Staging & Crawlway Breach",
		"content": "Cargo staging crane is jammed from the inertia dampener failure. We stashed high-capacity battery cells and salvage crates near the aft maintenance access hatch. Beware: the crawlway plating took a direct micrometeoroid strike during braking—hull integrity is breached in there."
	},
	{
		"id": "log_14",
		"author": "Chief Engineer Vasquez",
		"date": "Cycle 2184.119",
		"title": "Reactor Subdeck Vaults",
		"content": "I've locked the auxiliary fuel flow valve in the subdeck. If the primary turbine trips or starves, manual feed override from this deck can inject auxiliary deuterium. I have left the secondary battery vault online. Keep this ship alive."
	}
]

func get_all_crew_logs() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	list.append_array(CREW_LOGS)
	list.append_array(EXPANSION_CREW_LOGS)
	return list

func get_crew_log(id: String) -> Dictionary:
	for l in CREW_LOGS:
		if l.get("id") == id:
			return l
	for l in EXPANSION_CREW_LOGS:
		if l.get("id") == id:
			return l
	return {}


var current_objective_index: int = 0
var inventory: Array[String] = []

var discovered_rooms: Dictionary = {}
var airlock_cycles_completed: int = 0
var breaches_sealed_count: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Hook into ShipSystemManager signals
	ShipSystemManager.system_state_changed.connect(_on_system_state_changed)

func reset_missions() -> void:
	current_objective_index = 0
	inventory.clear()
	discovered_rooms.clear()
	airlock_cycles_completed = 0
	breaches_sealed_count = 0
	if has_node("/root/InventoryManager"):
		get_node("/root/InventoryManager").reset_to_defaults()
	inventory_changed.emit(inventory)
	_broadcast_current_objective()

func mark_room_discovered(room_id: String) -> void:
	if not discovered_rooms.has(room_id):
		discovered_rooms[room_id] = true
		var room_name := room_id.capitalize()
		if has_node("/root/ShipState"):
			var ss = get_node("/root/ShipState")
			if ss.COMPARTMENTS.has(room_id):
				room_name = ss.COMPARTMENTS[room_id].get("name", room_name)
		room_discovered.emit(room_id, room_name)

func is_room_discovered(room_id: String) -> bool:
	return discovered_rooms.has(room_id)

func mark_airlock_cycled() -> void:
	airlock_cycles_completed += 1
	airlock_cycled.emit()

func mark_breach_sealed(comp_id: String = "maintenance_crawlway") -> void:
	breaches_sealed_count += 1
	breach_sealed.emit(comp_id)

func get_exploration_stats() -> Dictionary:
	return {
		"discovered_rooms_count": discovered_rooms.size(),
		"discovered_rooms": discovered_rooms.keys(),
		"airlock_cycles_completed": airlock_cycles_completed,
		"breaches_sealed_count": breaches_sealed_count
	}


func get_current_objective() -> Dictionary:
	if current_objective_index < OBJECTIVES.size():
		return OBJECTIVES[current_objective_index]
	return {
		"id": "obj_completed",
		"title": "Mission Accomplished",
		"desc": "Astraea-7 is breaking orbit. All systems restored."
	}

func get_objective_count() -> int:
	return OBJECTIVES.size()

func _broadcast_current_objective() -> void:
	var obj := get_current_objective()
	objective_updated.emit(current_objective_index, obj["title"], obj["desc"])

func complete_objective(index: int) -> void:
	if index == current_objective_index:
		var title: String = OBJECTIVES[index]["title"]
		objective_completed.emit(index, title)
		current_objective_index += 1
		AudioManager.play_sfx("repair")
		
		if current_objective_index >= OBJECTIVES.size():
			all_objectives_completed.emit()
		else:
			_broadcast_current_objective()

func add_inventory_item(item_id: String) -> void:
	if not inventory.has(item_id):
		inventory.append(item_id)
		AudioManager.play_sfx("pickup")
		inventory_changed.emit(inventory)
	if has_node("/root/InventoryManager"):
		var im = get_node("/root/InventoryManager")
		if not im.has_item(item_id):
			im.add_item(item_id, 1)

func has_item(item_id: String) -> bool:
	if inventory.has(item_id):
		return true
	if has_node("/root/InventoryManager"):
		var im = get_node("/root/InventoryManager")
		return im.has_item(item_id)
	return false

func remove_inventory_item(item_id: String) -> bool:
	var idx := inventory.find(item_id)
	var removed := false
	if idx != -1:
		inventory.remove_at(idx)
		inventory_changed.emit(inventory)
		removed = true
	if has_node("/root/InventoryManager"):
		var im = get_node("/root/InventoryManager")
		if im.has_item(item_id):
			im.remove_item(item_id, 1)
			removed = true
	return removed


func _on_system_state_changed(system_id: String, _old_state: int, new_state: int) -> void:
	if new_state != ShipSystem.State.ONLINE:
		return
	
	match current_objective_index:
		0:
			if system_id == "primary_power":
				complete_objective(0)
		1:
			if system_id == "power_distribution":
				complete_objective(1)
		2:
			if system_id == "life_support":
				complete_objective(2)
		3:
			if system_id == "communications":
				complete_objective(3)
		4:
			if system_id == "propulsion":
				complete_objective(4)

func export_save_data() -> Dictionary:
	return {
		"current_objective_index": current_objective_index,
		"inventory": inventory,
		"discovered_rooms": discovered_rooms.duplicate(),
		"airlock_cycles_completed": airlock_cycles_completed,
		"breaches_sealed_count": breaches_sealed_count
	}

func import_save_data(data: Dictionary) -> void:
	current_objective_index = int(data.get("current_objective_index", 0))
	inventory.clear()
	var loaded_inv: Array = data.get("inventory", [])
	for item in loaded_inv:
		inventory.append(str(item))
	discovered_rooms.clear()
	if data.has("discovered_rooms") and data["discovered_rooms"] is Dictionary:
		discovered_rooms = data["discovered_rooms"].duplicate()
	airlock_cycles_completed = int(data.get("airlock_cycles_completed", 0))
	breaches_sealed_count = int(data.get("breaches_sealed_count", 0))
	inventory_changed.emit(inventory)
	_broadcast_current_objective()
