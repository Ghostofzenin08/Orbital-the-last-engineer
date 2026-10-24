class_name DatapadPickup
extends Interactable

# Physical In-World Datapad & Environmental Clue Interactable for ORBITAL: The Last Engineer
# Milestone 5: Supports unencrypted and encrypted/corrupted crew data slates requiring
# the Diagnostic Scanner [1] (5% battery charge) or subsystem restoration to decrypt.

signal datapad_recovered(datapad_id: String)
signal decryption_rejected(datapad_id: String, reason: String)

const DECRYPT_BATTERY_COST: float = 5.0
const ENCRYPTED_PROMPT_MSG: String = "[Encrypted Data Slate] Equip Diagnostic Scanner [1] to decrypt telemetry"

@export var datapad_id: String = "datapad_eng_vasquez"
@export var datapad_title: String = "Crew Datapad"
@export var is_encrypted: bool = false
@export var requires_scanner_to_decrypt: bool = false

var is_collected: bool = false
var is_decrypted: bool = false
var _pulse_time: float = 0.0

@onready var screen_mesh: MeshInstance3D = get_node_or_null("ScreenGlow")
@onready var led_mesh: MeshInstance3D = get_node_or_null("StatusLED")
@onready var datapad_light: OmniLight3D = get_node_or_null("DatapadLight")

func _ready() -> void:
	super._ready()
	_sync_metadata_from_config()
	if has_node("/root/MissionManager"):
		var mm = get_node("/root/MissionManager")
		if mm.has_method("is_datapad_collected") and mm.is_datapad_collected(datapad_id):
			is_collected = true
			is_decrypted = mm.is_datapad_decrypted(datapad_id)
		if mm.has_signal("datapad_collected"):
			mm.datapad_collected.connect(_on_global_datapad_collected)
	if not is_encrypted:
		is_decrypted = true
	_update_visuals()

func _process(delta: float) -> void:
	if is_encrypted and not is_decrypted and not is_collected:
		_pulse_time += delta * 5.0
		if datapad_light != null:
			datapad_light.light_energy = 0.45 + sin(_pulse_time) * 0.35

func _sync_metadata_from_config() -> void:
	if datapad_id == "" or not has_node("/root/MissionManager"):
		return
	var mm = get_node("/root/MissionManager")
	if not mm.has_method("get_datapad_data"):
		return
	var info: Dictionary = mm.get_datapad_data(datapad_id)
	if info.is_empty():
		return
	if datapad_title == "Crew Datapad" or datapad_title == "":
		datapad_title = str(info.get("title", datapad_title))

func _on_global_datapad_collected(collected_id: String, _data: Dictionary) -> void:
	if collected_id == datapad_id and not is_collected:
		is_collected = true
		is_decrypted = true
		_update_visuals()

func _can_decrypt_via_subsystem() -> bool:
	if datapad_id == "datapad_avionics_telemetry" and is_inside_tree():
		var relay = get_tree().root.find_child("AvionicsRelayBank", true, false)
		if relay != null and "is_repaired" in relay and relay.is_repaired:
			return true
	return false

func get_prompt() -> String:
	if is_collected:
		return "[Recovered] %s (Review in Terminal [INCIDENT LOGS])" % datapad_title
	
	if is_encrypted and not is_decrypted:
		if requires_scanner_to_decrypt and not _can_decrypt_via_subsystem():
			var im = get_node_or_null("/root/InventoryManager")
			if im != null and im.get_equipped_item_id() == "diagnostic_scanner":
				if im.get_scanner_battery() < DECRYPT_BATTERY_COST:
					return "[Encrypted Data Slate] Scanner Battery Low (5% Required)"
				return "[E] Decrypt & Recover %s [Scanner -5%%]" % datapad_title
			return ENCRYPTED_PROMPT_MSG
		return "[E] Decrypt & Recover %s" % datapad_title
	
	return "[E / Enter] Recover %s" % datapad_title

func _on_interacted(player: Node) -> void:
	if is_collected:
		if AudioManager != null:
			AudioManager.play_sfx("click")
		if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
			player.hud.show_notification("DATAPAD ARCHIVED: %s" % datapad_title, 3.0)
		return
	
	var used_scanner_decrypt := false
	if is_encrypted and not is_decrypted:
		if requires_scanner_to_decrypt and not _can_decrypt_via_subsystem():
			var im = get_node_or_null("/root/InventoryManager")
			if im == null or im.get_equipped_item_id() != "diagnostic_scanner":
				if AudioManager != null:
					AudioManager.play_sfx("denied")
				if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
					player.hud.show_notification(ENCRYPTED_PROMPT_MSG, 3.5)
				decryption_rejected.emit(datapad_id, ENCRYPTED_PROMPT_MSG)
				return
			
			if not im.drain_scanner_battery(DECRYPT_BATTERY_COST):
				if AudioManager != null:
					AudioManager.play_sfx("denied")
				var low_bat_msg := "[Encrypted Data Slate] Scanner battery depleted (5% charge required)"
				if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
					player.hud.show_notification(low_bat_msg, 3.5)
				decryption_rejected.emit(datapad_id, low_bat_msg)
				return
			
			used_scanner_decrypt = true
		
		is_decrypted = true
		if AudioManager != null:
			if AudioManager.has_method("play_datapad_decrypt"):
				AudioManager.play_datapad_decrypt()
			else:
				AudioManager.play_sfx("scanner_scan")
	
	is_collected = true
	is_decrypted = true
	if not used_scanner_decrypt and AudioManager != null:
		AudioManager.play_sfx("pickup")
	
	_update_visuals()
	
	var prev_rev_count: int = 0
	var mm = get_node_or_null("/root/MissionManager")
	if mm != null:
		prev_rev_count = mm.unlocked_revelations.size()
		mm.collect_datapad(datapad_id, true)
	
	if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
		if mm != null and mm.unlocked_revelations.size() > prev_rev_count:
			var latest_rev_id: String = mm.unlocked_revelations[mm.unlocked_revelations.size() - 1]
			var rev_data: Dictionary = mm.get_revelation_data(latest_rev_id)
			player.hud.show_notification(
				"REVELATION UNLOCKED: %s // %s" % [
					str(rev_data.get("title", latest_rev_id)),
					str(rev_data.get("bonus_summary", "System Optimization Active"))
				],
				5.5
			)
		else:
			player.hud.show_notification("DATAPAD RECOVERED: %s" % datapad_title, 3.5)
	
	datapad_recovered.emit(datapad_id)
	state_changed.emit()

func _update_visuals() -> void:
	var target_color: Color
	var light_energy_val: float
	if is_collected:
		target_color = Color(0.15, 0.55, 0.3, 1.0)
		light_energy_val = 0.2
	elif is_encrypted and not is_decrypted:
		target_color = Color(1.0, 0.3, 0.1, 1.0)
		light_energy_val = 0.75
	else:
		target_color = Color(0.15, 0.85, 1.0, 1.0)
		light_energy_val = 0.65
	
	if screen_mesh != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = target_color.darkened(0.35)
		mat.emission_enabled = true
		mat.emission = target_color
		mat.emission_energy_multiplier = 0.6 if is_collected else 2.2
		screen_mesh.material_override = mat
	
	if led_mesh != null:
		var led_mat := StandardMaterial3D.new()
		led_mat.albedo_color = target_color
		led_mat.emission_enabled = true
		led_mat.emission = target_color
		led_mat.emission_energy_multiplier = 1.0 if is_collected else 3.2
		led_mesh.material_override = led_mat
	
	if datapad_light != null:
		datapad_light.light_color = target_color
		datapad_light.light_energy = light_energy_val

func get_diagnostic_telemetry() -> Dictionary:
	var mm = get_node_or_null("/root/MissionManager")
	var dp_info: Dictionary = mm.get_datapad_data(datapad_id) if mm != null else {}
	return {
		"target_name": datapad_title,
		"device_id": datapad_id,
		"device_name": "Data Slate: " + datapad_title,
		"integrity": 100.0 if is_decrypted else 45.0,
		"power_draw": 0.0,
		"temperature_c": 21.0,
		"is_powered": true,
		"active_faults": [] if is_decrypted else ["TELEMETRY_PARITY_ENCRYPTED"],
		"repair_steps": [] if is_decrypted else ["Interact [E] with Diagnostic Scanner [1] equipped (-5% battery) to decrypt slate"],
		"recommended_tool": "Diagnostic Scanner [1]",
		"revelation_id": str(dp_info.get("revelation_id", ""))
	}

func export_save_data() -> Dictionary:
	return {
		"datapad_id": datapad_id,
		"is_collected": is_collected,
		"is_decrypted": is_decrypted,
		"is_encrypted": is_encrypted,
		"requires_scanner_to_decrypt": requires_scanner_to_decrypt
	}

func import_save_data(data: Dictionary) -> void:
	is_collected = bool(data.get("is_collected", false))
	is_decrypted = bool(data.get("is_decrypted", false))
	if data.has("is_encrypted"):
		is_encrypted = bool(data["is_encrypted"])
	if data.has("requires_scanner_to_decrypt"):
		requires_scanner_to_decrypt = bool(data["requires_scanner_to_decrypt"])
	_update_visuals()
