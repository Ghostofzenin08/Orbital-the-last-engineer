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
signal datapad_collected(datapad_id: String, datapad_data: Dictionary)
signal revelation_unlocked(revelation_id: String, revelation_data: Dictionary)

const OBJECTIVES: Array[Dictionary] = [
	{
		"id": "obj_primary_power",
		"title": "Restore Emergency Generator",
		"immediate_task": "Flip Generator Breaker Lever",
		"desc": "Lead Scientist docked at the research facility finding massive chambers in dark disarray and zero power. Proceed to Engineering and engage the primary generator breaker to restore baseline chamber systems."
	},
	{
		"id": "obj_power_distribution",
		"title": "Energize Main Electrical Bus",
		"immediate_task": "Close Main Distribution Bus Relay",
		"desc": "Close the high-voltage distribution bus relay in Engineering to restore power to chamber doors, key-security panels, and the central corridor."
	},
	{
		"id": "obj_life_support",
		"title": "Repair Scrubber Coolant Manifold",
		"immediate_task": "Install Replacement Coupler in Scrubber",
		"desc": "The facility air is choked with toxic bio-spores, leaving it impossible to breathe. Retrieve a spare coupler and install it into Life Support to restore breathable oxygen."
	},
	{
		"id": "obj_communications",
		"title": "Align Comms & Review Research",
		"immediate_task": "Calibrate Dish & Access Research Logs",
		"desc": "Access Bridge communications to review the science team's logs, uncovering the secret biological experiment and the creature that slaughtered the crew."
	},
	{
		"id": "obj_propulsion",
		"title": "Trap Alien & Poison Gas Purge",
		"immediate_task": "Trap Alien & Open Poison Gas Valve",
		"desc": "The adapted alien predator stalks the observatory. Lure the creature into the sealed chamber, open the emergency poisonous gas valve to exterminate it, and engage departure thrusters."
	}
]

const CREW_LOGS: Array[Dictionary] = [
	{
		"id": "log_01",
		"author": "Lead Scientist Elena Vasquez",
		"date": "Cycle 2184.102",
		"title": "Biological Observatory Sortie Notes",
		"content": "Our science team has expanded genetic observation across the massive botanical and zoological chambers. Before departing on the external orbital survey, I verified the primary generators and security grid were operating within nominal parameters. Dr. Thorne remained behind to monitor the cellular incubators."
	},
	{
		"id": "log_02",
		"author": "Dr. Aris Thorne",
		"date": "Cycle 2184.105",
		"title": "Secret Chamber Gene Synthesis",
		"content": "Without the Lead Scientist's interference, I have initiated Project Chimera in the sealed subdeck chamber. By cross-splicing Kharon-4 apex predator DNA into our synthetic embryonic stock, we can engineer a resilient organism capable of surviving deep orbital radiation."
	},
	{
		"id": "log_03",
		"author": "Specialist Jian Chen",
		"date": "Cycle 2184.107",
		"title": "Severe Genetic Mutation Warning",
		"content": "Thorne made a critical miscalculation during nucleotide transcription. The specimen in Chamber 4 did not incubate as a passive animal subject—it underwent accelerated adaptation, developing armored chitin and intense predatory aggression. It has doubled in size in six hours."
	},
	{
		"id": "log_04",
		"author": "Quartermaster David Reyes",
		"date": "Cycle 2184.110",
		"title": "Stalking Sounds in the Ventilation",
		"content": "Strange, guttural animal growls and claw scratches are vibrating through the ventilation ducts. Thorne claims the holding cell is secure, but I found the secondary biometric lock torn open. Something massive is crawling inside the bulkheads, stalking our movements."
	},
	{
		"id": "log_05",
		"author": "Chief Engineer Elena Vasquez",
		"date": "Cycle 2184.112",
		"title": "Generator Sabotage & Bus Severing",
		"content": "The mutant beast broke out of the secret chamber! It attacked the main engineering conduit, deliberately tripping the primary generator breaker to shut down the electronic security panels and lock the science team inside the dark corridors. I had to manually sever the main bus."
	},
	{
		"id": "log_06",
		"author": "Commander Evelyn Hayes",
		"date": "Cycle 2184.114",
		"title": "Slaughter of the Science Team",
		"content": "The creature is hunting us down one by one with terrifying anger. Thorne, Chen, and Lin were ambushed in the observatory chambers; not even kinetic sidearms slowed it down. It slashed through the life support lines, releasing toxic bio-spores so that no one in the facility can breathe."
	},
	{
		"id": "log_07",
		"author": "Specialist Jian Chen",
		"date": "Cycle 2184.115",
		"title": "Scrubber Loop Toxic Contamination",
		"content": "The atmospheric scrubber loop is clogged with creature venom. Ambient oxygen is bleeding away while toxic gases flood the corridors. Unless the scrubber's fractured coolant coupler is replaced, any crew survivor will asphyxiate in minutes."
	},
	{
		"id": "log_08",
		"author": "Dr. Aris Thorne",
		"date": "Cycle 2184.117",
		"title": "Creature Vulnerability: Neuro-Toxic Gas",
		"content": "My dying realization: the adapted organism's hyper-developed respiratory system is completely vulnerable to concentrated decontamination gas. Weapons cannot penetrate its carapace, but trapping it in a sealed chamber and opening the poisonous gas valve will destroy it instantly."
	},
	{
		"id": "log_09",
		"author": "Quartermaster David Reyes",
		"date": "Cycle 2184.118",
		"title": "Setting the Chamber Poison Gas Trap",
		"content": "I managed to route the high-pressure poisonous gas line to the starboard chamber isolation valve. Whoever arrives at this facility: do not try to fight the beast directly. Lure it inside the sealed chamber, lock the bulkhead door, and rotate the emergency valve to flood it with gas!"
	},
	{
		"id": "log_10",
		"author": "Astraea Research Station Computer",
		"date": "Cycle 2184.120",
		"title": "Automated Docking Advisory to Scientist",
		"content": "ATTENTION LEAD SCIENTIST: Docking sequence complete. Station in catastrophic status. All research personnel missing. Primary generators offline, security panels dark, and cabin atmosphere toxic. Follow sequential restoration tasks and eliminate the predatory organism to save the station."
	}
]

const EXPANSION_CREW_LOGS: Array[Dictionary] = [
	{
		"id": "log_11",
		"author": "Commander Evelyn Hayes",
		"date": "Cycle 2184.116",
		"title": "Bridge Command Directives",
		"content": "With key-security panels offline and the mutant beast stalking the corridors, I have locked departure clearance behind authorization code 7394-OMEGA. Restore power to the chambers and exterminate the alien menace before initiating orbital burn."
	},
	{
		"id": "log_12",
		"author": "Dr. Aris Thorne",
		"date": "Cycle 2184.111",
		"title": "Infirmary Triage Log",
		"content": "The organism secretes aerosolized toxins that disable human lung function within thirty seconds. If you enter unscrubbed chambers, monitor your O2 level immediately. The medical oxygen booster in Medbay can stabilize acute respiratory trauma."
	},
	{
		"id": "log_13",
		"author": "Quartermaster David Reyes",
		"date": "Cycle 2184.113",
		"title": "Cargo Staging & Crawlway Breach",
		"content": "We attempted to barricade the Cargo Bay with heavy storage crates, but the alien ripped through the hydraulic lift framework like paper. I stashed spare batteries and cutting tools near the crawlway access hatch."
	},
	{
		"id": "log_14",
		"author": "Chief Engineer Elena Vasquez",
		"date": "Cycle 2184.119",
		"title": "Reactor Subdeck Vaults",
		"content": "I verified the auxiliary toxic decontamination tanks on the subdeck manifold. Opening the emergency valve in the sealed chamber will discharge 500 liters of lethal gas—guaranteeing the destruction of the mutant specimen."
	}
]

const EXPANDED_CREW_LOGS: Array[Dictionary] = EXPANSION_CREW_LOGS

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

# Milestone 5: Narrative Investigation & Crew Mystery
var narrative_datapads: Dictionary = {}
var narrative_datapads_order: Array[String] = []
var narrative_revelations: Dictionary = {}
var narrative_revelations_order: Array[String] = []

var collected_datapads: Array[String] = []
var decrypted_logs: Array[String] = []
var unlocked_revelations: Array[String] = []
var commander_override_code: String = ""
var quarantine_lockout_cleared: bool = false

func _init() -> void:
	_load_narrative_config()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_narrative_config()
	# Hook into ShipSystemManager signals
	ShipSystemManager.system_state_changed.connect(_on_system_state_changed)

func _load_narrative_config() -> void:
	var path := "res://data/narrative_config.json"
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
		if cfg.has("datapads") and cfg["datapads"] is Dictionary:
			narrative_datapads = cfg["datapads"].duplicate(true)
			narrative_datapads_order.clear()
			for k in narrative_datapads.keys():
				var d: Dictionary = narrative_datapads[k]
				if not d.has("compartment_id") and d.has("compartment"):
					d["compartment_id"] = str(d["compartment"])
				narrative_datapads_order.append(str(k))
		if cfg.has("revelations") and cfg["revelations"] is Dictionary:
			narrative_revelations = cfg["revelations"].duplicate(true)
			narrative_revelations_order.clear()
			for k in narrative_revelations.keys():
				var r: Dictionary = narrative_revelations[k]
				if not r.has("bonus_summary") and r.has("bonus_description"):
					r["bonus_summary"] = str(r["bonus_description"])
				narrative_revelations_order.append(str(k))

func reset_missions() -> void:
	current_objective_index = 0
	inventory.clear()
	discovered_rooms.clear()
	airlock_cycles_completed = 0
	breaches_sealed_count = 0
	collected_datapads.clear()
	decrypted_logs.clear()
	unlocked_revelations.clear()
	commander_override_code = ""
	quarantine_lockout_cleared = false
	if has_node("/root/ShipState"):
		var ss = get_node("/root/ShipState")
		if ss.has_method("reset_revelation_bonuses"):
			ss.reset_revelation_bonuses()
	if has_node("/root/InventoryManager"):
		get_node("/root/InventoryManager").reset_to_defaults()
	inventory_changed.emit(inventory)
	_broadcast_current_objective()

func collect_datapad(datapad_id: String, mark_decrypted: bool = true) -> bool:
	if datapad_id == "":
		return false
	var was_collected: bool = collected_datapads.has(datapad_id)
	var was_decrypted: bool = decrypted_logs.has(datapad_id)
	if not was_collected:
		collected_datapads.append(datapad_id)
	var dp_info: Dictionary = get_datapad_data(datapad_id)
	var is_enc: bool = bool(dp_info.get("is_encrypted", false))
	var now_decrypted: bool = was_decrypted
	if mark_decrypted or not is_enc:
		if not was_decrypted:
			decrypted_logs.append(datapad_id)
		now_decrypted = true
	if (not was_collected) or (not was_decrypted and now_decrypted):
		datapad_collected.emit(datapad_id, dp_info)
	_evaluate_revelations()
	return true

func decrypt_datapad(datapad_id: String) -> bool:
	return collect_datapad(datapad_id, true)

func is_datapad_collected(datapad_id: String) -> bool:
	return collected_datapads.has(datapad_id)

func is_datapad_decrypted(datapad_id: String) -> bool:
	if not collected_datapads.has(datapad_id):
		return false
	var dp_info: Dictionary = get_datapad_data(datapad_id)
	if not bool(dp_info.get("is_encrypted", false)):
		return true
	return decrypted_logs.has(datapad_id)

func is_revelation_unlocked(revelation_id: String) -> bool:
	return unlocked_revelations.has(revelation_id)

func get_datapad_data(datapad_id: String) -> Dictionary:
	if narrative_datapads.is_empty():
		_load_narrative_config()
	if narrative_datapads.has(datapad_id):
		return narrative_datapads[datapad_id]
	return {
		"id": datapad_id,
		"title": datapad_id.capitalize(),
		"author": "Crew Member",
		"date": "Cycle 2184",
		"compartment": "engineering_bay",
		"compartment_id": "engineering_bay",
		"location_hint": "Ship Interior",
		"is_encrypted": false,
		"requires_scanner_to_decrypt": false,
		"content": "Recovered crew data slate."
	}

func get_all_datapads() -> Array[Dictionary]:
	if narrative_datapads.is_empty():
		_load_narrative_config()
	var list: Array[Dictionary] = []
	for k in narrative_datapads_order:
		if narrative_datapads.has(k):
			list.append(narrative_datapads[k])
	return list

func get_all_narrative_datapads() -> Array[Dictionary]:
	return get_all_datapads()

func get_revelation_data(revelation_id: String) -> Dictionary:
	if narrative_revelations.is_empty():
		_load_narrative_config()
	if narrative_revelations.has(revelation_id):
		return narrative_revelations[revelation_id]
	return {}

func get_all_revelations() -> Array[Dictionary]:
	if narrative_revelations.is_empty():
		_load_narrative_config()
	var list: Array[Dictionary] = []
	for k in narrative_revelations_order:
		if narrative_revelations.has(k):
			list.append(narrative_revelations[k])
	return list

func get_all_narrative_revelations() -> Array[Dictionary]:
	return get_all_revelations()

func _evaluate_revelations() -> void:
	if narrative_revelations.is_empty():
		_load_narrative_config()
	for rev_id in narrative_revelations_order:
		if unlocked_revelations.has(rev_id):
			continue
		var rev_data: Dictionary = narrative_revelations[rev_id]
		var req_list: Array = rev_data.get("required_datapads", [])
		if req_list.is_empty():
			continue
		var all_met := true
		for req_dp in req_list:
			var dp_id := str(req_dp)
			if not is_datapad_collected(dp_id) or not is_datapad_decrypted(dp_id):
				all_met = false
				break
		if all_met:
			unlocked_revelations.append(rev_id)
			_apply_revelation_consequence(rev_id)
			if AudioManager != null and AudioManager.has_method("play_revelation_chime"):
				AudioManager.play_revelation_chime()
			revelation_unlocked.emit(rev_id, rev_data)

func _apply_revelation_consequence(rev_id: String) -> void:
	if rev_id == "revelation_directive":
		commander_override_code = "7394-OMEGA"
		quarantine_lockout_cleared = true
	if has_node("/root/ShipState"):
		var ss = get_node("/root/ShipState")
		if ss.has_method("apply_revelation_bonus"):
			ss.apply_revelation_bonus(rev_id)

func mark_room_discovered(room_id: String) -> void:
	if not discovered_rooms.has(room_id):
		discovered_rooms[room_id] = true
		var room_name := room_id.capitalize()
		if has_node("/root/ShipState"):
			var ss = get_node("/root/ShipState")
			if ss.COMPARTMENTS.has(room_id):
				room_name = ss.COMPARTMENTS[room_id].get("name", room_name)
		room_discovered.emit(room_id, room_name)
	
	if current_objective_index == 4 and (room_id == "airlock_chamber" or room_id == "cargo_bay"):
		if has_node("/root/ShipState"):
			var ss = get_node("/root/ShipState")
			if ss.crisis_manager != null and not ss.crisis_manager.is_creature_trapped:
				ss.trap_creature_in_chamber("airlock_chamber")
				_broadcast_current_objective()

func is_room_discovered(room_id: String) -> bool:
	return discovered_rooms.has(room_id)

func mark_airlock_cycled() -> void:
	airlock_cycles_completed += 1
	if current_objective_index == 4:
		if has_node("/root/ShipState"):
			var ss = get_node("/root/ShipState")
			if ss.crisis_manager != null and not ss.crisis_manager.is_creature_trapped:
				ss.trap_creature_in_chamber("airlock_chamber")
				_broadcast_current_objective()
	airlock_cycled.emit()

func mark_breach_sealed(comp_id: String = "maintenance_crawlway") -> void:
	breaches_sealed_count += 1
	breach_sealed.emit(comp_id)

# Milestone 7: Extended Chamber Exploration & Final Hunt Gate
var required_chambers_for_final_hunt: int = 5

func can_engage_final_hunt() -> bool:
	return discovered_rooms.size() >= required_chambers_for_final_hunt

func get_expanded_chamber_count() -> int:
	var count: int = 0
	if discovered_rooms.has("specimen_vault"):
		count += 1
	if discovered_rooms.has("research_observatory"):
		count += 1
	return count

func get_exploration_stats() -> Dictionary:
	return {
		"discovered_rooms_count": discovered_rooms.size(),
		"discovered_rooms": discovered_rooms.keys(),
		"airlock_cycles_completed": airlock_cycles_completed,
		"breaches_sealed_count": breaches_sealed_count,
		"collected_datapads_count": collected_datapads.size(),
		"decrypted_logs_count": decrypted_logs.size(),
		"unlocked_revelations_count": unlocked_revelations.size(),
		"expanded_chambers_discovered": get_expanded_chamber_count(),
		"can_engage_final_hunt": can_engage_final_hunt()
	}

func get_current_objective() -> Dictionary:
	if current_objective_index < OBJECTIVES.size():
		return OBJECTIVES[current_objective_index]
	return {
		"id": "obj_completed",
		"title": "Mission Accomplished",
		"desc": "Astraea Research Station secured. Mutant alien exterminated. All systems restored.",
		"immediate_task": "Station Secure"
	}

func get_current_immediate_task() -> String:
	var obj := get_current_objective()
	if current_objective_index == 4 and has_node("/root/ShipState"):
		var ss = get_node("/root/ShipState")
		if ss.crisis_manager != null:
			if not ss.crisis_manager.is_creature_trapped:
				return "Trap Alien & Open Poison Gas Valve"
			elif not ss.crisis_manager.is_creature_eliminated:
				return "Open Poison Gas Valve to Purge Alien"
			else:
				return "Alien Purged - Engage Sub-Orbital Ion Thruster Bank (Bridge)"
	return str(obj.get("immediate_task", "Follow Mission Directives"))

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

func advance_objective() -> void:
	complete_objective(current_objective_index)

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
		"breaches_sealed_count": breaches_sealed_count,
		"collected_datapads": collected_datapads.duplicate(),
		"decrypted_logs": decrypted_logs.duplicate(),
		"unlocked_revelations": unlocked_revelations.duplicate(),
		"commander_override_code": commander_override_code,
		"quarantine_lockout_cleared": quarantine_lockout_cleared
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
	
	collected_datapads.clear()
	var loaded_dp: Array = data.get("collected_datapads", [])
	for dp in loaded_dp:
		collected_datapads.append(str(dp))
	
	decrypted_logs.clear()
	var loaded_dec: Array = data.get("decrypted_logs", [])
	for dl in loaded_dec:
		decrypted_logs.append(str(dl))
	
	unlocked_revelations.clear()
	commander_override_code = ""
	quarantine_lockout_cleared = false
	if has_node("/root/ShipState"):
		var ss = get_node("/root/ShipState")
		if ss.has_method("reset_revelation_bonuses"):
			ss.reset_revelation_bonuses()
	var loaded_rev: Array = data.get("unlocked_revelations", [])
	for rv in loaded_rev:
		var rev_id := str(rv)
		unlocked_revelations.append(rev_id)
		_apply_revelation_consequence(rev_id)
	
	if data.has("commander_override_code"):
		commander_override_code = str(data["commander_override_code"])
	if data.has("quarantine_lockout_cleared"):
		quarantine_lockout_cleared = bool(data["quarantine_lockout_cleared"])
	
	inventory_changed.emit(inventory)
	_broadcast_current_objective()
