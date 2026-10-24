class_name ShipSystem
extends RefCounted

# Ship System model for ORBITAL: The Last Engineer

enum State {
	OFFLINE = 0,
	DEGRADED = 1,
	ONLINE = 2,
	FAILED = 3
}

var id: String = ""
var display_name: String = ""
var state: int = State.OFFLINE
var prerequisites: Array[String] = []
var fault_description: String = ""
var required_power: float = 10.0
var description: String = ""

func _init(p_id: String = "", p_name: String = "", p_initial_state: int = State.OFFLINE, p_prereqs: Array[String] = [], p_fault: String = "", p_desc: String = "") -> void:
	id = p_id
	display_name = p_name
	state = p_initial_state
	prerequisites = p_prereqs
	fault_description = p_fault
	description = p_desc

func is_online() -> bool:
	return state == State.ONLINE

func get_state_string() -> String:
	match state:
		State.OFFLINE:
			return "OFFLINE"
		State.DEGRADED:
			return "DEGRADED"
		State.ONLINE:
			return "ONLINE"
		State.FAILED:
			return "FAULT DETECTED"
		_:
			return "UNKNOWN"

func to_dict() -> Dictionary:
	return {
		"id": id,
		"state": state,
		"fault_description": fault_description
	}

func from_dict(data: Dictionary) -> void:
	if data.has("state"):
		state = int(data["state"])
	if data.has("fault_description"):
		fault_description = str(data["fault_description"])
