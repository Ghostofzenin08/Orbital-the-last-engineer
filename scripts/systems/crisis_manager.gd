class_name CrisisManager
extends RefCounted

# Milestone 6: Dynamic Multi-Stage Crisis Scenarios & Cascading Faults Engine
# Coordinates multi-stage dynamic ship crises, cascading fault propagation,
# creature stalking audio/threat levels, chamber quarantine trapping, and
# poisonous gas decontamination purge.

enum CrisisType {
	NONE = 0,
	POWER_GRID_CASCADE = 1,
	ATMOSPHERIC_BREACH_CASCADE = 2,
	CREATURE_PREDATORY_HUNT = 3
}

enum CreatureState {
	DORMANT = 0,
	STALKING = 1,
	AGGRESSIVE = 2,
	TRAPPED = 3,
	ELIMINATED = 4
}

enum Stage {
	STAGE_0_IDLE = 0,
	STAGE_1_SURGE = 1,
	STAGE_2_CASCADE = 2,
	STAGE_3_CRITICAL = 3,
	STAGE_4_MITIGATION = 4,
	STAGE_5_RESOLVED = 5
}

signal crisis_started(type: int, stage: int, description: String)
signal crisis_stage_advanced(type: int, stage: int, stage_name: String)
signal cascading_fault_triggered(parent_fault: String, cascaded_fault: String)
signal creature_sound_emitted(sound_type: String, compartment_id: String)
signal creature_trapped(chamber_id: String)
signal creature_eliminated(chamber_id: String)
signal crisis_resolved(type: int)

var ship_state: Node = null
var current_crisis: int = CrisisType.NONE
var current_stage: int = Stage.STAGE_0_IDLE
var stage_name: String = "NOMINAL"
var stage_elapsed_time: float = 0.0
var cascading_timer: float = 0.0
var cascade_interval: float = 8.0

var creature_state: int = CreatureState.DORMANT
var target_chamber_id: String = "airlock_chamber"
var is_creature_trapped: bool = false
var is_creature_eliminated: bool = false
var poison_gas_valve_opened: bool = false

var active_cascading_faults: Array[String] = []
var cascading_history: Array[Dictionary] = []

func setup(p_ship_state: Node) -> void:
	ship_state = p_ship_state
	reset()

func reset() -> void:
	current_crisis = CrisisType.NONE
	current_stage = Stage.STAGE_0_IDLE
	stage_name = "NOMINAL"
	stage_elapsed_time = 0.0
	cascading_timer = 0.0
	creature_state = CreatureState.DORMANT
	target_chamber_id = "airlock_chamber"
	is_creature_trapped = false
	is_creature_eliminated = false
	poison_gas_valve_opened = false
	active_cascading_faults.clear()
	cascading_history.clear()

func start_crisis(type: int, start_stage: int = Stage.STAGE_1_SURGE) -> void:
	current_crisis = type
	current_stage = start_stage
	stage_elapsed_time = 0.0
	cascading_timer = 0.0
	
	match current_crisis:
		CrisisType.POWER_GRID_CASCADE:
			stage_name = "GENERATOR_HARMONIC_SURGE"
			if ship_state != null:
				if ship_state.has_method("trigger_fault"):
					ship_state.trigger_fault("GENERATOR_TRIP")
				elif ship_state.has_method("inject_fault"):
					ship_state.inject_fault("GENERATOR_TRIP")
		CrisisType.ATMOSPHERIC_BREACH_CASCADE:
			stage_name = "SCRUBBER_TOXIC_SATURATION"
			if ship_state != null:
				if ship_state.has_method("trigger_fault"):
					ship_state.trigger_fault("COOLANT_COUPLER_FRACTURE")
				elif ship_state.has_method("inject_fault"):
					ship_state.inject_fault("COOLANT_COUPLER_FRACTURE")
		CrisisType.CREATURE_PREDATORY_HUNT:
			stage_name = "SPECIMEN_BREACH_STALKING"
			creature_state = CreatureState.STALKING
			trigger_creature_sound("growl", "life_support")
		_:
			stage_name = "NOMINAL"
	
	var desc := "Crisis %d engaged at Stage %d (%s)" % [current_crisis, current_stage, stage_name]
	crisis_started.emit(current_crisis, current_stage, desc)

func advance_crisis_stage() -> void:
	if current_crisis == CrisisType.NONE:
		return
	
	current_stage += 1
	stage_elapsed_time = 0.0
	cascading_timer = 0.0
	
	match current_crisis:
		CrisisType.POWER_GRID_CASCADE:
			match current_stage:
				Stage.STAGE_2_CASCADE:
					stage_name = "BUS_ISOLATION_CASCADE"
					trigger_cascading_fault("GENERATOR_TRIP", "BUS_ISOLATION")
				Stage.STAGE_3_CRITICAL:
					stage_name = "AUXILIARY_POWER_STARVATION"
					trigger_cascading_fault("BUS_ISOLATION", "CO2_SCRUBBER_SATURATION")
				Stage.STAGE_4_MITIGATION:
					stage_name = "GRID_RESTORATION_STABILIZED"
				Stage.STAGE_5_RESOLVED, _:
					resolve_current_crisis()
					return
		
		CrisisType.ATMOSPHERIC_BREACH_CASCADE:
			match current_stage:
				Stage.STAGE_2_CASCADE:
					stage_name = "VENT_DAMPER_JAMMED_DIFFUSION"
					trigger_cascading_fault("COOLANT_COUPLER_FRACTURE", "CABIN_PRESSURE_LEAK")
				Stage.STAGE_3_CRITICAL:
					stage_name = "COMPOUND_TOXIC_ASPHYXIATION"
					trigger_cascading_fault("CABIN_PRESSURE_LEAK", "THERMAL_RUNAWAY")
				Stage.STAGE_4_MITIGATION:
					stage_name = "ATMOSPHERE_SCRUBBER_RESTORED"
				Stage.STAGE_5_RESOLVED, _:
					resolve_current_crisis()
					return
		
		CrisisType.CREATURE_PREDATORY_HUNT:
			match current_stage:
				Stage.STAGE_2_CASCADE:
					stage_name = "CREATURE_AGGRESSION_CONDUIT_TEAR"
					creature_state = CreatureState.AGGRESSIVE
					trigger_creature_sound("roar", "corridors")
					trigger_cascading_fault("GENERATOR_TRIP", "BUS_ISOLATION")
				Stage.STAGE_3_CRITICAL:
					stage_name = "CHAMBER_TRAP_OPPORTUNITY"
					trigger_creature_sound("scratch", target_chamber_id)
				Stage.STAGE_4_MITIGATION:
					stage_name = "POISON_GAS_VALVE_PURGE"
				Stage.STAGE_5_RESOLVED, _:
					resolve_current_crisis()
					return
	
	crisis_stage_advanced.emit(current_crisis, current_stage, stage_name)

func trigger_cascading_fault(parent_fault: String, cascaded_fault: String) -> bool:
	if not active_cascading_faults.has(cascaded_fault):
		active_cascading_faults.append(cascaded_fault)
	
	var cascade_entry := {
		"parent": parent_fault,
		"cascaded": cascaded_fault,
		"timestamp": stage_elapsed_time,
		"stage": current_stage
	}
	cascading_history.append(cascade_entry)
	
	if ship_state != null:
		if ship_state.has_method("trigger_fault"):
			ship_state.trigger_fault(cascaded_fault)
		elif ship_state.has_method("inject_fault"):
			ship_state.inject_fault(cascaded_fault)
	
	cascading_fault_triggered.emit(parent_fault, cascaded_fault)
	return true

func resolve_cascade(fault_id: String) -> void:
	if active_cascading_faults.has(fault_id):
		active_cascading_faults.erase(fault_id)
	if ship_state != null and ship_state.has_method("resolve_fault"):
		ship_state.resolve_fault(fault_id)

func is_cascade_active() -> bool:
	return not active_cascading_faults.is_empty()

func get_active_cascades() -> Array[String]:
	return active_cascading_faults.duplicate()

func trigger_creature_sound(sound_type: String = "growl", comp_id: String = "life_support") -> void:
	if AudioManager != null:
		match sound_type:
			"roar":
				AudioManager.play_sfx("creature_roar")
			"growl", "scratch", _:
				AudioManager.play_sfx("creature_sound")
	creature_sound_emitted.emit(sound_type, comp_id)

func trap_creature(chamber_id: String = "") -> bool:
	if is_creature_eliminated:
		return false
	if chamber_id != "":
		target_chamber_id = chamber_id
	is_creature_trapped = true
	creature_state = CreatureState.TRAPPED
	creature_trapped.emit(target_chamber_id)
	trigger_creature_sound("roar", target_chamber_id)
	return true

func execute_poison_gas_purge(chamber_id: String = "") -> bool:
	var purge_chamber := chamber_id if chamber_id != "" else target_chamber_id
	poison_gas_valve_opened = true
	is_creature_eliminated = true
	creature_state = CreatureState.ELIMINATED
	
	if AudioManager != null:
		AudioManager.play_sfx("gas_hiss")
		AudioManager.play_sfx("creature_roar")
	
	creature_eliminated.emit(purge_chamber)
	
	if current_crisis == CrisisType.CREATURE_PREDATORY_HUNT:
		resolve_current_crisis()
	
	return true

func resolve_current_crisis() -> void:
	var old_crisis: int = current_crisis
	current_crisis = CrisisType.NONE
	current_stage = Stage.STAGE_5_RESOLVED
	stage_name = "RESOLVED"
	active_cascading_faults.clear()
	crisis_resolved.emit(old_crisis)

func tick(delta: float) -> void:
	if current_crisis == CrisisType.NONE:
		return
	
	stage_elapsed_time += delta
	cascading_timer += delta
	
	# Automatic stage cascading if not mitigated
	if cascading_timer >= cascade_interval and current_stage < Stage.STAGE_3_CRITICAL:
		cascading_timer = 0.0
		advance_crisis_stage()

func serialize() -> Dictionary:
	return {
		"current_crisis": current_crisis,
		"current_stage": current_stage,
		"stage_name": stage_name,
		"stage_elapsed_time": stage_elapsed_time,
		"creature_state": creature_state,
		"target_chamber_id": target_chamber_id,
		"is_creature_trapped": is_creature_trapped,
		"is_creature_eliminated": is_creature_eliminated,
		"poison_gas_valve_opened": poison_gas_valve_opened,
		"active_cascading_faults": active_cascading_faults.duplicate(),
		"cascading_history": cascading_history.duplicate(true)
	}

func deserialize(data: Dictionary) -> void:
	current_crisis = int(data.get("current_crisis", CrisisType.NONE))
	current_stage = int(data.get("current_stage", Stage.STAGE_0_IDLE))
	stage_name = str(data.get("stage_name", "NOMINAL"))
	stage_elapsed_time = float(data.get("stage_elapsed_time", 0.0))
	creature_state = int(data.get("creature_state", CreatureState.DORMANT))
	target_chamber_id = str(data.get("target_chamber_id", "airlock_chamber"))
	is_creature_trapped = bool(data.get("is_creature_trapped", false))
	is_creature_eliminated = bool(data.get("is_creature_eliminated", false))
	poison_gas_valve_opened = bool(data.get("poison_gas_valve_opened", false))
	active_cascading_faults.clear()
	if data.has("active_cascading_faults") and data["active_cascading_faults"] is Array:
		for f in data["active_cascading_faults"]:
			active_cascading_faults.append(str(f))
	cascading_history.clear()
	if data.has("cascading_history") and data["cascading_history"] is Array:
		for h in data["cascading_history"]:
			if h is Dictionary:
				cascading_history.append(h)
