class_name Fault
extends RefCounted

# Fault Definition for ORBITAL: The Last Engineer
# Reusable fault framework modeling root causes, symptoms, diagnosis, and escalation.

enum EscalationStage {
	DORMANT = 0,
	WARNING = 1,
	CRITICAL = 2,
	CATASTROPHIC = 3
}

var fault_id: String = ""
var subsystem_id: String = ""
var device_id: String = ""
var root_cause: String = ""
var symptoms: Array[String] = []
var diagnostic_methods: Array[String] = []
var required_parts: Array[String] = []
var repair_steps: Array[String] = []
var workaround: String = ""
var consequence: String = ""
var narrative_clue: String = ""

var is_active: bool = true
var escalation_stage: int = EscalationStage.WARNING
var time_active: float = 0.0
var time_to_escalate: float = 120.0 # Seconds before stage increases

func _init(
	p_id: String = "",
	p_subsystem: String = "",
	p_device: String = "",
	p_cause: String = "",
	p_symptoms: Array[String] = [],
	p_diagnostic: Array[String] = [],
	p_parts: Array[String] = [],
	p_repair: Array[String] = [],
	p_workaround: String = "",
	p_consequence: String = "",
	p_clue: String = ""
) -> void:
	fault_id = p_id
	subsystem_id = p_subsystem
	device_id = p_device
	root_cause = p_cause
	symptoms = p_symptoms
	diagnostic_methods = p_diagnostic
	required_parts = p_parts
	repair_steps = p_repair
	workaround = p_workaround
	consequence = p_consequence
	narrative_clue = p_clue

func tick(delta: float) -> void:
	if not is_active:
		return
	time_active += delta
	if time_to_escalate > 0.0 and time_active >= time_to_escalate:
		if escalation_stage < EscalationStage.CATASTROPHIC:
			escalation_stage += 1
			time_active = 0.0

func resolve() -> void:
	is_active = false
	escalation_stage = EscalationStage.DORMANT

func get_stage_string() -> String:
	match escalation_stage:
		EscalationStage.DORMANT:
			return "DORMANT"
		EscalationStage.WARNING:
			return "WARNING"
		EscalationStage.CRITICAL:
			return "CRITICAL"
		EscalationStage.CATASTROPHIC:
			return "CATASTROPHIC"
		_:
			return "UNKNOWN"

func to_dict() -> Dictionary:
	return {
		"fault_id": fault_id,
		"subsystem_id": subsystem_id,
		"device_id": device_id,
		"root_cause": root_cause,
		"symptoms": symptoms,
		"diagnostic_methods": diagnostic_methods,
		"required_parts": required_parts,
		"repair_steps": repair_steps,
		"workaround": workaround,
		"consequence": consequence,
		"narrative_clue": narrative_clue,
		"is_active": is_active,
		"escalation_stage": escalation_stage,
		"time_active": time_active
	}

func from_dict(data: Dictionary) -> void:
	fault_id = str(data.get("fault_id", fault_id))
	subsystem_id = str(data.get("subsystem_id", subsystem_id))
	device_id = str(data.get("device_id", device_id))
	root_cause = str(data.get("root_cause", root_cause))
	is_active = bool(data.get("is_active", true))
	escalation_stage = int(data.get("escalation_stage", EscalationStage.WARNING))
	time_active = float(data.get("time_active", 0.0))
	workaround = str(data.get("workaround", workaround))
	consequence = str(data.get("consequence", consequence))
	narrative_clue = str(data.get("narrative_clue", narrative_clue))
	
	if data.has("symptoms"):
		symptoms.clear()
		for s in data["symptoms"]:
			symptoms.append(str(s))
	if data.has("diagnostic_methods"):
		diagnostic_methods.clear()
		for d in data["diagnostic_methods"]:
			diagnostic_methods.append(str(d))
	if data.has("required_parts"):
		required_parts.clear()
		for p in data["required_parts"]:
			required_parts.append(str(p))
	if data.has("repair_steps"):
		repair_steps.clear()
		for r in data["repair_steps"]:
			repair_steps.append(str(r))
