class_name EnvironmentalManager
extends Node

# Environmental Manager for ORBITAL: The Last Engineer
# Milestone 2: Dynamic Multi-Compartment Life Support & Atmospheric Physics Simulation.
# Simulates Oxygen, Carbon Dioxide, Temperature, Pressure, and Inter-compartment Gas Diffusion.

signal oxygen_level_changed(level: float, is_depleting: bool)
signal oxygen_critical(level: float)
signal oxygen_depleted
signal atmosphere_updated(compartment_id: String, telemetry: Dictionary)
signal player_status_updated(afflictions: Array[String], telemetry: Dictionary)
signal environmental_alert(alert_type: String, message: String, severity: String)

# Legacy scalar compatibility
var oxygen_level: float = 100.0
var max_oxygen: float = 100.0
var depletion_rate: float = 0.35 # % per second when life support is offline
var replenishment_rate: float = 2.5 # % per second when life support is online
var is_active: bool = true
var _critical_alert_active: bool = false

# Player tracking
var player_compartment_id: String = "engineering_bay"
var player_afflictions: Array[String] = []

# Compartment data dictionary
var compartments: Dictionary = {}

# Diegetic audio timers
var _hiss_timer: float = 0.0
var _alarm_timer: float = 0.0
var _gasp_timer: float = 0.0

# Airlock cycling state
var airlock_cycling: bool = false
var airlock_target_pressure: float = 101.3
var airlock_cycle_speed: float = 33.7 # ~3s from 101.3 to 0

# Red Poison Gas Environment State (Post-Valve Open until Medbay O2 Valve Turned)
var poison_environment_active: bool = false
var medbay_poison_recovery_completed: bool = false
var _left_airlock_after_poison: bool = false
var poison_o2_drain_rate: float = 1.0 # 5% per 5 seconds (1.0% per second)

static var instance: EnvironmentalManager = null

func _init() -> void:
	instance = self

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_PAUSABLE
	initialize_atmosphere()

func initialize_atmosphere() -> void:
	compartments.clear()
	oxygen_level = 100.0
	poison_environment_active = false
	medbay_poison_recovery_completed = false
	_left_airlock_after_poison = false
	_critical_alert_active = false
	
	var default_comps: Dictionary = {
		"engineering_bay": {
			"id": "engineering_bay",
			"name": "Engineering Bay",
			"volume_m3": 360.0,
			"o2_level": 100.0,
			"co2_ppm": 420.0,
			"temperature": 296.15, # ~23°C near reactor
			"pressure": 101.3,     # 101.3 kPa = 1.0 ATM
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		},
		"corridors": {
			"id": "corridors",
			"name": "Central Transit Spine",
			"volume_m3": 240.0,
			"o2_level": 100.0,
			"co2_ppm": 420.0,
			"temperature": 294.15, # 21°C
			"pressure": 101.3,
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		},
		"life_support": {
			"id": "life_support",
			"name": "Life Support Module",
			"volume_m3": 360.0,
			"o2_level": 100.0,
			"co2_ppm": 450.0,
			"temperature": 294.15, # 21°C
			"pressure": 101.3,
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		},
		"bridge": {
			"id": "bridge",
			"name": "Command Bridge",
			"volume_m3": 320.0,
			"o2_level": 100.0,
			"co2_ppm": 410.0,
			"temperature": 293.15, # 20°C
			"pressure": 101.3,
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		},
		"avionics_bay": {
			"id": "avionics_bay",
			"name": "Server Core & Avionics",
			"volume_m3": 180.0,
			"o2_level": 100.0,
			"co2_ppm": 420.0,
			"temperature": 291.15,
			"pressure": 101.3,
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		},
		"crew_quarters": {
			"id": "crew_quarters",
			"name": "Crew Habitation & Bunks",
			"volume_m3": 220.0,
			"o2_level": 100.0,
			"co2_ppm": 430.0,
			"temperature": 295.15,
			"pressure": 101.3,
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		},
		"medbay": {
			"id": "medbay",
			"name": "Medical Infirmary",
			"volume_m3": 200.0,
			"o2_level": 100.0,
			"co2_ppm": 415.0,
			"temperature": 294.15,
			"pressure": 101.3,
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		},
		"cargo_bay": {
			"id": "cargo_bay",
			"name": "Cargo Hold & Machine Staging",
			"volume_m3": 380.0,
			"o2_level": 100.0,
			"co2_ppm": 425.0,
			"temperature": 292.15,
			"pressure": 101.3,
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		},
		"airlock_chamber": {
			"id": "airlock_chamber",
			"name": "Airlock & EVA Staging",
			"volume_m3": 120.0,
			"o2_level": 100.0,
			"co2_ppm": 420.0,
			"temperature": 293.15,
			"pressure": 101.3,
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		},
		"reactor_subdeck": {
			"id": "reactor_subdeck",
			"name": "Fuel Vault & Auxiliary Battery Deck",
			"volume_m3": 260.0,
			"o2_level": 100.0,
			"co2_ppm": 425.0,
			"temperature": 297.15,
			"pressure": 101.3,
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		},
		"maintenance_crawlway": {
			"id": "maintenance_crawlway",
			"name": "Breached Maintenance Crawlway",
			"volume_m3": 90.0,
			"o2_level": 98.0,
			"co2_ppm": 430.0,
			"temperature": 286.15,
			"pressure": 98.5,
			"vents_open": true,
			"leak_rate": 0.3,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		}
	}
	
	# Load external json if present
	var cfg_path := "res://data/environment_config.json"
	if FileAccess.file_exists(cfg_path):
		var f := FileAccess.open(cfg_path, FileAccess.READ)
		if f != null:
			var json := JSON.new()
			if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
				for cid in json.data.keys():
					if cid == "specimen_vault" or cid == "research_observatory":
						continue
					var d: Dictionary = json.data[cid]
					if not default_comps.has(cid):
						default_comps[cid] = {
							"id": cid,
							"name": str(d.get("name", cid.capitalize())),
							"volume_m3": float(d.get("volume_m3", 250.0)),
							"o2_level": float(d.get("initial_o2_pct", 100.0)),
							"co2_ppm": float(d.get("initial_co2_ppm", 420.0)),
							"temperature": float(d.get("initial_temp_k", 294.15)),
							"pressure": float(d.get("initial_pressure_kpa", 101.3)),
							"vents_open": true,
							"leak_rate": float(d.get("leak_rate", 0.0)),
							"heaters_active": true,
							"cooling_active": true,
							"scrubbers_active": true,
							"o2_generators_active": true,
							"active_hazards": []
						}
					else:
						default_comps[cid]["name"] = str(d.get("name", default_comps[cid]["name"]))
						default_comps[cid]["volume_m3"] = float(d.get("volume_m3", default_comps[cid]["volume_m3"]))
						default_comps[cid]["o2_level"] = float(d.get("initial_o2_pct", 100.0))
						default_comps[cid]["co2_ppm"] = float(d.get("initial_co2_ppm", 420.0))
						default_comps[cid]["temperature"] = float(d.get("initial_temp_k", 294.15))
						default_comps[cid]["pressure"] = float(d.get("initial_pressure_kpa", 101.3))
						if d.has("leak_rate"):
							default_comps[cid]["leak_rate"] = float(d["leak_rate"])
			f.close()
	
	compartments = default_comps

func _process(delta: float) -> void:
	if not is_active:
		return
	
	if compartments.is_empty():
		initialize_atmosphere()
	
	# Determine system state
	var ls_online: bool = ShipSystemManager.is_system_online("life_support")
	
	# Check active faults from ShipState if available
	var has_co2_fault: bool = false
	var has_pressure_fault: bool = false
	var has_thermal_fault: bool = false
	var reactor_temp_excess: float = 0.0
	
	if ShipState != null and "active_faults" in ShipState:
		has_co2_fault = ShipState.active_faults.has("CO2_SCRUBBER_SATURATION")
		has_pressure_fault = ShipState.active_faults.has("CABIN_PRESSURE_LEAK")
		has_thermal_fault = ShipState.active_faults.has("THERMAL_RUNAWAY")
		if ShipState.power_system != null:
			if ShipState.power_system.reactor_online and ShipState.power_system.reactor_temperature > 450.0:
				reactor_temp_excess = (ShipState.power_system.reactor_temperature - 450.0) / 200.0
	
	# Update player position and compartment if player is available
	_update_player_compartment()
	
	# 1. Update each compartment's internal chemistry & thermodynamics
	for cid in compartments.keys():
		var comp: Dictionary = compartments[cid]
		_simulate_compartment(comp, ls_online, has_co2_fault, has_pressure_fault, has_thermal_fault, reactor_temp_excess, delta)
	
	# 2. Inter-compartment gas and thermal diffusion across open doors & vents
	_simulate_diffusion(delta)
	
	# 3. Synchronize legacy oxygen_level with player's compartment (or minimum across ship)
	var old_level := oxygen_level
	if poison_environment_active:
		if player_compartment_id != "airlock_chamber":
			_left_airlock_after_poison = true
		if player_compartment_id == "airlock_chamber" and not _left_airlock_after_poison:
			oxygen_level = 100.0
			if compartments.has("airlock_chamber"):
				compartments["airlock_chamber"]["o2_level"] = 100.0
		else:
			# Player left Airlock Chamber into poison environment:
			# Oxygen keeps decreasing 5% per 5 seconds (1.0% per second) until player turns MedicalOxygenBooster valve in Medbay!
			oxygen_level = maxf(0.0, old_level - (poison_o2_drain_rate * delta))
			for cid in compartments.keys():
				if cid == "airlock_chamber":
					compartments[cid]["o2_level"] = 100.0
				else:
					compartments[cid]["o2_level"] = oxygen_level
	elif compartments.has(player_compartment_id):
		oxygen_level = compartments[player_compartment_id]["o2_level"]
	else:
		# Fallback to mean O2
		var total_o2 := 0.0
		for c in compartments.values():
			total_o2 += float(c.get("o2_level", 100.0))
		oxygen_level = total_o2 / maxf(1.0, float(compartments.size()))
	
	# Fallback simulation if isolated node outside tree with no player
	var rev_scrub_mult: float = get_scrubber_optimization_multiplier()
	if not is_inside_tree() and delta > 0.0 and not poison_environment_active:
		if ls_online:
			oxygen_level = minf(max_oxygen, old_level + (replenishment_rate * rev_scrub_mult * delta))
		else:
			oxygen_level = maxf(0.0, old_level - (depletion_rate * delta))
		for c in compartments.values():
			c["o2_level"] = oxygen_level
	
	# Check critical alarms and asphyxiation
	if oxygen_level <= 25.0 and not _critical_alert_active:
		_critical_alert_active = true
		if AudioManager != null:
			AudioManager.play_alarm_loop("alarm")
		oxygen_critical.emit(oxygen_level)
	elif oxygen_level > 30.0 and _critical_alert_active:
		_critical_alert_active = false
		if AudioManager != null:
			AudioManager.stop_alarm()
	
	if oxygen_level <= 0.0:
		_on_asphyxiation()
		return
	
	if not is_equal_approx(old_level, oxygen_level):
		oxygen_level_changed.emit(oxygen_level, poison_environment_active or not ls_online)
	
	# 4. Evaluate player status effects & hazards
	_evaluate_player_afflictions(delta)

func get_scrubber_optimization_multiplier() -> float:
	if ShipState != null and "has_revelation_quarantine" in ShipState and ShipState.has_revelation_quarantine:
		return float(ShipState.scrubber_efficiency_multiplier) if "scrubber_efficiency_multiplier" in ShipState else 1.20
	return 1.0

func _simulate_compartment(
	comp: Dictionary,
	ls_online: bool,
	has_co2_fault: bool,
	has_pressure_fault: bool,
	has_thermal_fault: bool,
	reactor_temp_excess: float,
	delta: float
) -> void:
	if delta <= 0.0:
		return
	
	var cid: String = comp["id"]
	var is_player_here: bool = (cid == player_compartment_id)
	var opt_mult: float = get_scrubber_optimization_multiplier()
	
	# Check auxiliary scrubber bank (rerouted power)
	var aux_scrub_active: bool = false
	if ShipState != null and "auxiliary_scrubber_active" in ShipState and ShipState.auxiliary_scrubber_active:
		if ShipSystemManager.is_system_online("power_distribution"):
			aux_scrub_active = true
	
	# --- A. OXYGEN DYNAMICS ---
	if ls_online and comp["o2_generators_active"]:
		# Oxygen replenishment (boosted +20% when Revelation II unlocked)
		if comp["o2_level"] < max_oxygen:
			comp["o2_level"] = minf(max_oxygen, comp["o2_level"] + (replenishment_rate * opt_mult * delta))
	else:
		# Depletion
		var dep := depletion_rate * delta
		if is_player_here:
			dep += 0.15 * delta # Occupant respiration
		comp["o2_level"] = maxf(0.0, comp["o2_level"] - dep)
	
	# --- B. CO2 DYNAMICS ---
	# Respiration generation
	var co2_gen := 4.0 * delta # base background buildup
	if is_player_here:
		co2_gen += 22.0 * delta # human occupant CO2 exhalation
	
	# Interconnected Coupling: High temperatures (>320 K / 47°C) thermally stress amine beds
	if comp["temperature"] > 320.0 and cid == "life_support":
		co2_gen += 15.0 * delta * ((comp["temperature"] - 320.0) / 10.0)
		if comp["temperature"] > 330.0 and not has_co2_fault and ShipState != null and "trigger_fault" in ShipState:
			# Thermal runaway cascades into Scrubber Saturation
			ShipState.trigger_fault("CO2_SCRUBBER_SATURATION")
	
	# CO2 scrubbing
	var co2_scrub := 0.0
	if ls_online and comp["scrubbers_active"] and not (has_co2_fault and cid == "life_support"):
		# Functional primary scrubber reduces CO2 towards baseline 420 ppm
		if comp["co2_ppm"] > 420.0:
			var scrub_rate := (75.0 if cid == "life_support" else 45.0) * opt_mult
			# Thermal degradation: At elevated temperatures > 315K, amine bed efficiency falls off linearly
			var scrub_eff := 1.0
			if comp["temperature"] > 315.0:
				scrub_eff = clampf(1.0 - (comp["temperature"] - 315.0) / 10.0, 0.0, 1.0)
			co2_scrub = minf(comp["co2_ppm"] - 420.0, scrub_rate * scrub_eff * delta)
	elif aux_scrub_active and cid == "life_support":
		# Rerouted power to auxiliary scrubber restores scrubbing during primary fault
		if comp["co2_ppm"] > 420.0:
			co2_scrub = minf(comp["co2_ppm"] - 420.0, 50.0 * opt_mult * delta)
	
	if has_co2_fault and cid == "life_support":
		# Saturated filter releases back trapped gas unless auxiliary scrubber is active
		if not aux_scrub_active:
			co2_gen += 35.0 * delta
		else:
			co2_gen += 10.0 * delta
	
	comp["co2_ppm"] = maxf(420.0, comp["co2_ppm"] + co2_gen - co2_scrub)
	
	# --- C. TEMPERATURE DYNAMICS (Kelvin) ---
	var target_temp := 294.15 # 21.0°C nominal
	var temp: float = comp["temperature"]
	
	# Space radiation heat loss (towards 255K)
	var thermal_drift := -0.25 * delta
	
	# Engineering proximity to reactor
	if cid == "engineering_bay":
		thermal_drift += (0.2 + reactor_temp_excess * 1.5) * delta
	
	# Thermal Runaway Fault (coolant loop bypass dumping heat into Life Support)
	if has_thermal_fault:
		if cid == "life_support":
			thermal_drift += 2.4 * delta
		elif cid == "engineering_bay":
			thermal_drift += 1.6 * delta
		else:
			thermal_drift += 0.8 * delta
	
	# Interconnected Coupling: Extreme thermal runaway (>335 K / 62°C) blows manifold seals
	if comp["temperature"] > 335.0 and cid == "life_support":
		if not has_pressure_fault and ShipState != null and "trigger_fault" in ShipState:
			ShipState.trigger_fault("CABIN_PRESSURE_LEAK")
	
	# Interconnected Coupling: Air density ratio affects convective heat regulation
	var nominal_press := 101.3
	var press_ratio: float = clampf(comp["pressure"] / nominal_press, 0.15, 1.0)
	
	# Climate control regulation (heaters and cooling coils)
	if ls_online and not has_thermal_fault:
		var diff := target_temp - temp
		var reg_speed := 1.8 * delta * press_ratio
		if absf(diff) > 0.05:
			temp += clampf(diff, -reg_speed, reg_speed)
	else:
		# In depressurized compartment, loss of convective stability accelerates thermal drift
		var drift_mult := 1.0 + (1.0 - press_ratio) * 0.5
		temp += thermal_drift * drift_mult
	
	comp["temperature"] = clampf(temp, 240.0, 360.0)
	
	# --- D. PRESSURE DYNAMICS (kPa) ---
	var press: float = comp["pressure"]
	
	# Check leak status
	var leak := float(comp.get("leak_rate", 0.0))
	if has_pressure_fault and cid == "life_support":
		leak = maxf(leak, 3.4) # 3.4 kPa/s leak rate
	
	if cid == "airlock_chamber" and airlock_cycling:
		var p_diff := airlock_target_pressure - press
		var p_step := airlock_cycle_speed * delta
		if absf(p_diff) <= p_step:
			press = airlock_target_pressure
			comp["o2_level"] = 100.0 if airlock_target_pressure > 50.0 else 0.0
			airlock_cycling = false
		else:
			press += signf(p_diff) * p_step
			if airlock_target_pressure < 50.0:
				comp["o2_level"] = maxf(0.0, float(comp["o2_level"]) - (33.3 * delta))
			else:
				comp["o2_level"] = minf(100.0, float(comp["o2_level"]) + (33.3 * delta))
	elif leak > 0.0:
		press = maxf(0.0, press - (leak * delta))
		# Pressure leak vents oxygen faster
		comp["o2_level"] = maxf(0.0, comp["o2_level"] - (leak * 0.6 * delta))
	elif ls_online and press < nominal_press:
		# Cabin pressurization pump
		press = minf(nominal_press, press + (1.8 * delta))
	
	comp["pressure"] = clampf(press, 0.0, 120.0)

func start_airlock_depressurization(immediate: bool = false) -> void:
	if immediate:
		airlock_cycling = false
		if compartments.has("airlock_chamber"):
			compartments["airlock_chamber"]["pressure"] = 0.0
			compartments["airlock_chamber"]["o2_level"] = 0.0
	else:
		airlock_cycling = true
		airlock_target_pressure = 0.0

func start_airlock_pressurization(immediate: bool = false) -> void:
	if immediate:
		airlock_cycling = false
		if compartments.has("airlock_chamber"):
			compartments["airlock_chamber"]["pressure"] = 101.3
			compartments["airlock_chamber"]["o2_level"] = 100.0
	else:
		airlock_cycling = true
		airlock_target_pressure = 101.3

func is_airlock_depressurized() -> bool:
	return float(compartments.get("airlock_chamber", {}).get("pressure", 101.3)) <= 5.0

func is_airlock_pressurized() -> bool:
	return float(compartments.get("airlock_chamber", {}).get("pressure", 0.0)) >= 95.0

func seal_hull_breach(comp_id: String = "maintenance_crawlway") -> void:
	if compartments.has(comp_id):
		compartments[comp_id]["leak_rate"] = 0.0

func is_breach_sealed(comp_id: String = "maintenance_crawlway") -> bool:
	return float(compartments.get(comp_id, {}).get("leak_rate", 0.0)) <= 0.0

func _simulate_diffusion(delta: float) -> void:
	if delta <= 0.0 or compartments.size() < 2:
		return
	
	# Inspect door states
	var door_aft_open: bool = false
	var door_fwd_open: bool = false
	var door_avionics_open: bool = false
	var door_crew_open: bool = false
	var door_medbay_open: bool = false
	var door_cargo_open: bool = false
	var airlock_inner_open: bool = false
	var airlock_outer_open: bool = false
	var door_subdeck_open: bool = false
	var door_crawlway_cargo_open: bool = false
	var door_crawlway_eng_open: bool = false
	var door_wing_port_open: bool = false
	var door_wing_starboard_open: bool = false

	if is_inside_tree():
		var root := get_tree().root
		var d_aft = root.find_child("DoorAft", true, false)
		if d_aft != null and "is_open" in d_aft: door_aft_open = d_aft.is_open
		var d_fwd = root.find_child("DoorForward", true, false)
		if d_fwd != null and "is_open" in d_fwd: door_fwd_open = d_fwd.is_open
		var d_av = root.find_child("DoorAvionics", true, false)
		if d_av != null and "is_open" in d_av: door_avionics_open = d_av.is_open
		var d_cr = root.find_child("DoorCrew", true, false)
		if d_cr != null and "is_open" in d_cr: door_crew_open = d_cr.is_open
		var d_med = root.find_child("DoorMedbay", true, false)
		if d_med != null and "is_open" in d_med: door_medbay_open = d_med.is_open
		var d_cgo = root.find_child("DoorCargo", true, false)
		if d_cgo != null and "is_open" in d_cgo: door_cargo_open = d_cgo.is_open
		var d_ain = root.find_child("AirlockInner", true, false)
		if d_ain != null and "is_open" in d_ain: airlock_inner_open = d_ain.is_open
		var d_aout = root.find_child("AirlockOuter", true, false)
		if d_aout != null and "is_open" in d_aout: airlock_outer_open = d_aout.is_open
		var d_sub = root.find_child("DoorSubdeck", true, false)
		if d_sub != null and "is_open" in d_sub: door_subdeck_open = d_sub.is_open
		var d_cc = root.find_child("DoorCrawlwayCargo", true, false)
		if d_cc != null and "is_open" in d_cc: door_crawlway_cargo_open = d_cc.is_open
		var d_ce = root.find_child("DoorCrawlwayEng", true, false)
		if d_ce != null and "is_open" in d_ce: door_crawlway_eng_open = d_ce.is_open
		var d_wp = root.find_child("DoorWingPort", true, false)
		if d_wp != null and "is_open" in d_wp: door_wing_port_open = d_wp.is_open
		var d_ws = root.find_child("DoorWingStarboard", true, false)
		if d_ws != null and "is_open" in d_ws: door_wing_starboard_open = d_ws.is_open

	var eng: Dictionary = compartments.get("engineering_bay", {})
	var corr: Dictionary = compartments.get("corridors", {})
	var ls: Dictionary = compartments.get("life_support", {})
	var bridge: Dictionary = compartments.get("bridge", {})
	var avionics: Dictionary = compartments.get("avionics_bay", {})
	var crew: Dictionary = compartments.get("crew_quarters", {})
	var medbay: Dictionary = compartments.get("medbay", {})
	var cargo: Dictionary = compartments.get("cargo_bay", {})
	var airlock: Dictionary = compartments.get("airlock_chamber", {})
	var subdeck: Dictionary = compartments.get("reactor_subdeck", {})
	var crawlway: Dictionary = compartments.get("maintenance_crawlway", {})
	
	# Diffusion rate coefficient (per second)
	var diff_coeff := 0.22 * delta
	
	# Connection 1: Engineering Bay <-> Corridors (controlled by Door Aft and Vents)
	if door_aft_open or (eng.get("vents_open", true) and corr.get("vents_open", true)):
		var eff_rate := diff_coeff if door_aft_open else (diff_coeff * 0.3)
		_diffuse_pair(eng, corr, eff_rate)
	
	# Connection 2: Corridors <-> Life Support (open transition arch / primary duct)
	if corr.get("vents_open", true) and ls.get("vents_open", true):
		_diffuse_pair(corr, ls, diff_coeff * 1.2)
	
	# Connection 3: Corridors <-> Bridge (controlled by Door Forward and Vents)
	if door_fwd_open or (corr.get("vents_open", true) and bridge.get("vents_open", true)):
		var eff_rate := diff_coeff if door_fwd_open else (diff_coeff * 0.3)
		_diffuse_pair(corr, bridge, eff_rate)

	# Connection 4: Bridge <-> Avionics Bay
	if door_avionics_open or (bridge.get("vents_open", true) and avionics.get("vents_open", true)):
		var eff_rate := diff_coeff if door_avionics_open else (diff_coeff * 0.3)
		_diffuse_pair(bridge, avionics, eff_rate)

	# Connection 5: Corridors <-> Crew Quarters (Port Wing)
	var port_fwd_open := door_crew_open or door_wing_port_open
	if port_fwd_open or (corr.get("vents_open", true) and crew.get("vents_open", true)):
		var eff_rate := diff_coeff if port_fwd_open else (diff_coeff * 0.3)
		_diffuse_pair(corr, crew, eff_rate)

	# Connection 6: Corridors <-> Medbay (Starboard Wing)
	var stbd_fwd_open := door_medbay_open or door_wing_starboard_open
	if stbd_fwd_open or (corr.get("vents_open", true) and medbay.get("vents_open", true)):
		var eff_rate := diff_coeff if stbd_fwd_open else (diff_coeff * 0.3)
		_diffuse_pair(corr, medbay, eff_rate)

	# Connection 7: Corridors <-> Cargo Bay (Port Wing Aft)
	var port_aft_open := door_cargo_open or door_wing_port_open
	if port_aft_open or (corr.get("vents_open", true) and cargo.get("vents_open", true)):
		var eff_rate := diff_coeff if port_aft_open else (diff_coeff * 0.3)
		_diffuse_pair(corr, cargo, eff_rate)

	# Connection 8: Corridors <-> Airlock Chamber (Starboard Wing Aft)
	var stbd_aft_open := airlock_inner_open or door_wing_starboard_open
	if stbd_aft_open or (corr.get("vents_open", true) and airlock.get("vents_open", true)):
		var eff_rate := diff_coeff if stbd_aft_open else (diff_coeff * 0.3)
		_diffuse_pair(corr, airlock, eff_rate)

	# Connection 9: Engineering Bay <-> Reactor Subdeck
	if door_subdeck_open or (eng.get("vents_open", true) and subdeck.get("vents_open", true)):
		var eff_rate := diff_coeff if door_subdeck_open else (diff_coeff * 0.3)
		_diffuse_pair(eng, subdeck, eff_rate)

	# Connection 10: Cargo Bay <-> Maintenance Crawlway
	if door_crawlway_cargo_open or (cargo.get("vents_open", true) and crawlway.get("vents_open", true)):
		var eff_rate := diff_coeff if door_crawlway_cargo_open else (diff_coeff * 0.3)
		_diffuse_pair(cargo, crawlway, eff_rate)

	# Connection 11: Reactor Subdeck / Engineering <-> Maintenance Crawlway
	if door_crawlway_eng_open or (subdeck.get("vents_open", true) and crawlway.get("vents_open", true)):
		var eff_rate := diff_coeff if door_crawlway_eng_open else (diff_coeff * 0.3)
		_diffuse_pair(subdeck, crawlway, eff_rate)

	# Airlock Outer Door open to Space Vacuum
	if airlock_outer_open and not airlock.is_empty():
		airlock["pressure"] = maxf(0.0, float(airlock.get("pressure", 101.3)) - (45.0 * delta))
		airlock["o2_level"] = maxf(0.0, float(airlock.get("o2_level", 100.0)) - (45.0 * delta))

func _diffuse_pair(comp_a: Dictionary, comp_b: Dictionary, rate: float) -> void:
	if comp_a.is_empty() or comp_b.is_empty():
		return
	
	var eff_rate := clampf(rate, 0.0, 0.5)
	
	# Volume weights
	var v_a: float = comp_a.get("volume_m3", 300.0)
	var v_b: float = comp_b.get("volume_m3", 300.0)
	var total_v := v_a + v_b
	var weight_a := v_b / total_v
	var weight_b := v_a / total_v
	
	# Oxygen diffusion
	var o2_diff := float(comp_b["o2_level"]) - float(comp_a["o2_level"])
	comp_a["o2_level"] += o2_diff * eff_rate * weight_a
	comp_b["o2_level"] -= o2_diff * eff_rate * weight_b
	
	# CO2 diffusion
	var co2_diff := float(comp_b["co2_ppm"]) - float(comp_a["co2_ppm"])
	comp_a["co2_ppm"] += co2_diff * eff_rate * weight_a
	comp_b["co2_ppm"] -= co2_diff * eff_rate * weight_b
	
	# Temperature diffusion
	var temp_diff := float(comp_b["temperature"]) - float(comp_a["temperature"])
	comp_a["temperature"] += temp_diff * eff_rate * weight_a
	comp_b["temperature"] -= temp_diff * eff_rate * weight_b
	
	# Pressure equalization
	var press_diff := float(comp_b["pressure"]) - float(comp_a["pressure"])
	comp_a["pressure"] += press_diff * eff_rate * weight_a
	comp_b["pressure"] -= press_diff * eff_rate * weight_b

func get_compartment_for_position(pos: Vector3) -> String:
	var x := pos.x
	var z := pos.z
	
	# Specimen vault: z >= 34.0, x in [-10.0, 10.0]
	if z >= 34.0 and x >= -10.0 and x <= 10.0:
		return "specimen_vault"
	
	# Research observatory: z in [-28.0, -13.5], x <= -6.5
	if z >= -28.0 and z <= -13.5 and x <= -6.5:
		return "research_observatory"
	
	# Maintenance crawlway connects Cargo (x ≈ -10, z ≈ 14) to Subdeck/Eng (x ≈ -5, z ≈ 22)
	# Evaluated before reactor_subdeck to correctly handle the west bypass entrance at z in [13.8, 23.0]
	if z >= 13.8 and z <= 23.0 and x <= -3.0:
		return "maintenance_crawlway"
	
	# Subdeck is on lower deck: z in [21.5, 32.0], x in [-7.0, 7.0]
	if z >= 21.5 and x >= -7.0 and x <= 7.0:
		return "reactor_subdeck"
	
	# Engineering bay: z in [10.8, 21.5], x in [-6.0, 6.0]
	if z >= 10.8 and z < 21.5 and x >= -6.0 and x <= 6.0:
		return "engineering_bay"
	
	# Cargo bay: z in [3.5, 14.5], x < -2.0
	if z >= 3.5 and z < 14.5 and x < -2.0:
		return "cargo_bay"
	
	# Airlock chamber: z in [3.5, 14.5], x > 2.0
	if z >= 3.5 and z < 14.5 and x > 2.0:
		return "airlock_chamber"
	
	# Crew quarters: z in [-13.0, -3.5], x < -2.0
	if z >= -13.0 and z < -3.5 and x < -2.0:
		return "crew_quarters"
	
	# Medbay: z in [-13.0, -3.5], x > 2.0
	if z >= -13.0 and z < -3.5 and x > 2.0:
		return "medbay"
	
	# Avionics bay: z <= -10.8, x > 5.0
	if z <= -10.8 and x > 5.0:
		return "avionics_bay"
	
	# Bridge: z <= -10.8, x in [-6.0, 5.0]
	if z <= -10.8 and x >= -6.0 and x <= 5.0:
		return "bridge"
	
	# Life support: z in [-5.0, 5.0], x in [-4.5, 4.5]
	if z >= -5.0 and z <= 5.0 and x >= -4.5 and x <= 4.5:
		return "life_support"
	
	# Corridors: Central spine
	return "corridors"

func _update_player_compartment() -> void:
	if not is_inside_tree():
		return
	
	var root := get_tree().root
	var player = root.find_child("Player", true, false)
	if player != null and is_instance_valid(player):
		var old_id := player_compartment_id
		player_compartment_id = get_compartment_for_position(player.global_position)
		if player_compartment_id != old_id:
			if has_node("/root/MissionManager"):
				var mm = get_node("/root/MissionManager")
				if mm.has_method("mark_room_discovered"):
					mm.mark_room_discovered(player_compartment_id)
			if player_compartment_id == "medbay":
				if poison_environment_active:
					var hud_node: Node = player.get_node_or_null("HUD")
					if hud_node != null and hud_node.has_method("show_notification"):
						hud_node.show_notification("MEDICAL CHAMBER REACHED: Turn the Medical Oxygen Booster Valve [E] to normalize & stabilize O2!", 4.0)
				elif ShipState != null and ShipState.crisis_manager != null:
					if ShipState.crisis_manager.current_crisis == CrisisManager.CrisisType.CREATURE_PREDATORY_HUNT and not ShipState.crisis_manager.is_creature_eliminated:
						var hud_node: Node = player.get_node_or_null("HUD")
						if hud_node != null and hud_node.has_method("show_notification"):
							hud_node.show_notification("SANCTUARY: Medical Bay decontamination field active. Alien cannot seek you here.", 4.5)

func is_compartment_poisoned(cid: String) -> bool:
	if not poison_environment_active:
		return false
	return cid != "airlock_chamber" and cid != "medbay"

func activate_poison_gas_environment() -> void:
	if compartments.is_empty():
		initialize_atmosphere()
	register_expanded_chambers()
	poison_environment_active = true
	medbay_poison_recovery_completed = false
	_left_airlock_after_poison = (player_compartment_id != "airlock_chamber")
	for cid in compartments.keys():
		var comp: Dictionary = compartments[cid]
		if cid == "airlock_chamber" or cid == "medbay":
			comp["o2_level"] = 100.0
			comp["active_hazards"] = []
		else:
			var hazards: Array = comp.get("active_hazards", [])
			if not hazards.has("RED_POISON_GAS"):
				hazards.append("RED_POISON_GAS")
			comp["active_hazards"] = hazards
	if player_compartment_id == "airlock_chamber":
		oxygen_level = 100.0
	oxygen_level_changed.emit(oxygen_level, true)

func normalize_poison_oxygen_in_medbay() -> void:
	poison_environment_active = false
	medbay_poison_recovery_completed = true
	_left_airlock_after_poison = false
	oxygen_level = 100.0
	for cid in compartments.keys():
		var comp: Dictionary = compartments[cid]
		comp["o2_level"] = 100.0
		comp["co2_ppm"] = 420.0
		comp["active_hazards"] = []
	if AudioManager != null:
		AudioManager.stop_alarm()
		AudioManager.play_sfx("repair")
	oxygen_level_changed.emit(oxygen_level, false)
	if is_inside_tree() and has_node("/root/MissionManager"):
		var mm = get_node("/root/MissionManager")
		if mm.has_method("_broadcast_current_objective"):
			mm._broadcast_current_objective()

func _evaluate_player_afflictions(delta: float) -> void:
	var comp: Dictionary = compartments.get(player_compartment_id, {})
	if comp.is_empty():
		return
	
	var afflictions: Array[String] = []
	var o2: float = float(comp.get("o2_level", 100.0))
	var co2: float = float(comp.get("co2_ppm", 420.0))
	var temp: float = float(comp.get("temperature", 294.15))
	var press: float = float(comp.get("pressure", 101.3))
	
	# Hypoxia
	if o2 < 60.0:
		afflictions.append("HYPOXIA")
	
	# CO2 Toxicity (Hypercapnia)
	if co2 > 2000.0:
		afflictions.append("CO2_TOXICITY")
	
	# Thermal Afflictions
	if temp < 283.15: # < 10°C
		afflictions.append("HYPOTHERMIA")
	elif temp > 311.15: # > 38°C
		afflictions.append("HEATSTROKE")
	
	# Decompression
	if press < 75.0:
		afflictions.append("DECOMPRESSION")
	elif press < 99.0 and player_compartment_id == "maintenance_crawlway" and float(comp.get("leak_rate", 0.0)) > 0.0:
		afflictions.append("LOW_PRESSURE")
	
	player_afflictions = afflictions
	
	# Emit updates to UI
	var telem: Dictionary = {
		"compartment_id": player_compartment_id,
		"compartment_name": comp.get("name", "Unknown"),
		"o2_level": o2,
		"co2_ppm": co2,
		"temperature_k": temp,
		"temperature_c": temp - 273.15,
		"pressure_kpa": press,
		"afflictions": afflictions
	}
	player_status_updated.emit(afflictions, telem)
	
	# Diegetic Audio Cue Triggers
	if delta > 0.0 and AudioManager != null:
		# Gas hissing if pressure is actively leaking in current compartment
		var has_leak := float(comp.get("leak_rate", 0.0)) > 0.0
		if ShipState != null and "active_faults" in ShipState:
			if ShipState.active_faults.has("CABIN_PRESSURE_LEAK") and (player_compartment_id == "life_support" or player_compartment_id == "corridors"):
				has_leak = true
		
		if has_leak:
			_hiss_timer += delta
			if _hiss_timer >= 0.7:
				_hiss_timer = 0.0
				AudioManager.play_sfx("gas_hiss")
		
		# Thermal steam release
		if afflictions.has("HEATSTROKE") or (ShipState != null and "active_faults" in ShipState and ShipState.active_faults.has("THERMAL_RUNAWAY")):
			_alarm_timer += delta
			if _alarm_timer >= 2.5:
				_alarm_timer = 0.0
				AudioManager.play_sfx("steam_vent")
		
		# Breathing distress (cough / gasp) when hypoxic or CO2 toxic
		if afflictions.has("HYPOXIA") or afflictions.has("CO2_TOXICITY"):
			_gasp_timer += delta
			if _gasp_timer >= 4.0:
				_gasp_timer = 0.0
				AudioManager.play_sfx("cough_gasp")
		
		# High frequency ear ring on acute decompression
		if press < 60.0 and afflictions.has("DECOMPRESSION"):
			if randf() < (delta * 0.4):
				AudioManager.play_sfx("decomp_ring")

func _on_asphyxiation() -> void:
	is_active = false
	if AudioManager != null:
		AudioManager.stop_all()
	oxygen_depleted.emit()
	if ShipState != null and "death_reason" in ShipState:
		ShipState.death_reason = "ASPHYXIATION"
	if is_inside_tree() and get_tree() != null:
		var cur := get_tree().current_scene
		if cur != null and cur.scene_file_path.contains("test_runner"):
			return
		get_tree().change_scene_to_file.call_deferred("res://scenes/ui/game_over.tscn")

func reset_atmosphere() -> void:
	initialize_atmosphere()
	oxygen_level = 100.0
	is_active = true
	poison_environment_active = false
	medbay_poison_recovery_completed = false
	_critical_alert_active = false
	player_afflictions.clear()
	if AudioManager != null:
		AudioManager.stop_alarm()
	oxygen_level_changed.emit(oxygen_level, false)

func register_expanded_chambers() -> void:
	if not compartments.has("specimen_vault"):
		compartments["specimen_vault"] = {
			"id": "specimen_vault",
			"name": "Deep Specimen Containment Vault",
			"volume_m3": 280.0,
			"o2_level": 94.0,
			"co2_ppm": 850.0,
			"temperature": 288.15,
			"pressure": 99.8,
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		}
	if not compartments.has("research_observatory"):
		compartments["research_observatory"] = {
			"id": "research_observatory",
			"name": "Bio-Research Observatory Dome",
			"volume_m3": 340.0,
			"o2_level": 100.0,
			"co2_ppm": 410.0,
			"temperature": 294.15,
			"pressure": 101.3,
			"vents_open": true,
			"leak_rate": 0.0,
			"heaters_active": true,
			"cooling_active": true,
			"scrubbers_active": true,
			"o2_generators_active": true,
			"active_hazards": []
		}

func get_compartment_atmosphere(cid: String) -> Dictionary:
	if (cid == "specimen_vault" or cid == "research_observatory") and not compartments.has(cid):
		register_expanded_chambers()
	return compartments.get(cid, {})

func get_all_compartments(include_all: bool = false, include_m7: bool = false) -> Dictionary:
	if include_all and include_m7:
		register_expanded_chambers()
		return compartments
	if include_all:
		var m4_comps: Dictionary = {}
		for cid in ["engineering_bay", "corridors", "life_support", "bridge", "avionics_bay", "crew_quarters", "medbay", "cargo_bay", "airlock_chamber", "reactor_subdeck", "maintenance_crawlway"]:
			if compartments.has(cid):
				m4_comps[cid] = compartments[cid]
		return m4_comps
	var core_comps: Dictionary = {}
	for cid in ["engineering_bay", "corridors", "life_support", "bridge"]:
		if compartments.has(cid):
			core_comps[cid] = compartments[cid]
	return core_comps

func set_vent_damper(cid: String, open: bool) -> void:
	if compartments.has(cid):
		compartments[cid]["vents_open"] = open
		atmosphere_updated.emit(cid, compartments[cid])

func set_compartment_leak(cid: String, leak_kpa_per_sec: float) -> void:
	if compartments.has(cid):
		compartments[cid]["leak_rate"] = maxf(0.0, leak_kpa_per_sec)

# Interactive resolution paths & terminal overrides
func trigger_co2_purge() -> bool:
	for c in compartments.values():
		c["co2_ppm"] = 420.0
	if ShipState != null and "active_faults" in ShipState:
		if ShipState.active_faults.has("CO2_SCRUBBER_SATURATION"):
			ShipState.resolve_fault("CO2_SCRUBBER_SATURATION")
	if AudioManager != null:
		AudioManager.play_sfx("repair")
	return true

func trigger_pressurization_override(cid: String = "") -> bool:
	if cid.is_empty() or not compartments.has(cid):
		for c in compartments.values():
			c["pressure"] = 101.3
			c["leak_rate"] = 0.0
	else:
		compartments[cid]["pressure"] = 101.3
		compartments[cid]["leak_rate"] = 0.0
	
	if ShipState != null and "active_faults" in ShipState:
		if ShipState.active_faults.has("CABIN_PRESSURE_LEAK"):
			ShipState.resolve_fault("CABIN_PRESSURE_LEAK")
	if AudioManager != null:
		AudioManager.play_sfx("repair")
	return true

func trigger_thermal_reset() -> bool:
	for c in compartments.values():
		c["temperature"] = 294.15
	if ShipState != null and "active_faults" in ShipState:
		if ShipState.active_faults.has("THERMAL_RUNAWAY"):
			ShipState.resolve_fault("THERMAL_RUNAWAY")
	if AudioManager != null:
		AudioManager.play_sfx("repair")
	return true

func export_save_data() -> Dictionary:
	var comp_save: Dictionary = {}
	for cid in compartments.keys():
		var c: Dictionary = compartments[cid]
		comp_save[cid] = {
			"o2_level": float(c.get("o2_level", 100.0)),
			"co2_ppm": float(c.get("co2_ppm", 420.0)),
			"temperature": float(c.get("temperature", 294.15)),
			"pressure": float(c.get("pressure", 101.3)),
			"vents_open": bool(c.get("vents_open", true)),
			"leak_rate": float(c.get("leak_rate", 0.0))
		}
	return {
		"oxygen_level": oxygen_level,
		"is_active": is_active,
		"player_compartment_id": player_compartment_id,
		"compartments": comp_save
	}

func import_save_data(data: Dictionary) -> void:
	var raw_o2 := float(data.get("oxygen_level", 100.0))
	oxygen_level = maxf(20.0, raw_o2)
	is_active = bool(data.get("is_active", true))
	player_compartment_id = str(data.get("player_compartment_id", "engineering_bay"))
	_critical_alert_active = false
	
	if compartments.is_empty():
		initialize_atmosphere()
	
	var comp_data: Dictionary = data.get("compartments", {})
	for cid in comp_data.keys():
		if compartments.has(cid):
			var cd: Dictionary = comp_data[cid]
			compartments[cid]["o2_level"] = maxf(20.0, float(cd.get("o2_level", 100.0)))
			compartments[cid]["co2_ppm"] = float(cd.get("co2_ppm", 420.0))
			compartments[cid]["temperature"] = float(cd.get("temperature", 294.15))
			compartments[cid]["pressure"] = float(cd.get("pressure", 101.3))
			compartments[cid]["vents_open"] = bool(cd.get("vents_open", true))
			compartments[cid]["leak_rate"] = float(cd.get("leak_rate", 0.0))
	
	if AudioManager != null:
		AudioManager.stop_alarm()
	
	var ls_online: bool = ShipSystemManager.is_system_online("life_support")
	oxygen_level_changed.emit(oxygen_level, not ls_online)
