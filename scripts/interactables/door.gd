class_name BulkheadDoor
extends Interactable

# Bulkhead Door interactable for ORBITAL: The Last Engineer
# Connects compartments; requires Power Distribution to be active.

@export var door_name: String = "Bulkhead Door"
@export var device_id: String = ""
@export var is_open: bool = false
@export var is_locked: bool = false
@export var lock_reason: String = "Locked"
@export var requires_multitool_to_unlock: bool = false
@export var multitool_mode_required: String = "CUT_WELD"
@export var auto_open_on_proximity: bool = false

var interlock_controller: Node = null

@onready var door_panel: AnimatableBody3D = get_node_or_null("DoorPanel")
@onready var interaction_col: CollisionShape3D = get_node_or_null("InteractionCollision")
@onready var indicator_light: OmniLight3D = get_node_or_null("StatusLight")
@onready var indicator_mesh: MeshInstance3D = get_node_or_null("StatusLED")

var _closed_pos: Vector3 = Vector3.ZERO
var _open_pos: Vector3 = Vector3(0, 2.6, 0)
var _col_closed_pos: Vector3 = Vector3.ZERO
var _col_open_pos: Vector3 = Vector3(0, 2.6, 0)
var _tween: Tween

var _mat_powered: StandardMaterial3D
var _mat_unpowered: StandardMaterial3D

func _ready() -> void:
	super._ready()
	_create_materials()
	if door_panel != null:
		door_panel.sync_to_physics = false
		_closed_pos = door_panel.position
		_open_pos = _closed_pos + Vector3(0, 2.6, 0)
		if is_open:
			door_panel.position = _open_pos
			var panel_col: CollisionShape3D = door_panel.get_node_or_null("PanelCollision")
			if panel_col != null:
				panel_col.disabled = true
	if interaction_col != null:
		_col_closed_pos = interaction_col.position
		_col_open_pos = _col_closed_pos + Vector3(0, 2.6, 0)
		if is_open:
			interaction_col.position = _col_open_pos
	_update_power_visuals()
	ShipSystemManager.system_state_changed.connect(func(_sys, _old, _new): _update_power_visuals())
	if has_node("/root/ShipState"):
		var ss = get_node("/root/ShipState")
		ss.device_updated.connect(func(did, _pwr, _hp):
			var my_dev := device_id if device_id != "" else ("door_aft" if "Aft" in name else "door_fwd")
			if did == my_dev:
				_update_power_visuals()
		)

func _create_materials() -> void:
	_mat_powered = StandardMaterial3D.new()
	_mat_powered.albedo_color = Color(0.2, 0.8, 1.0)
	_mat_powered.emission_enabled = true
	_mat_powered.emission = Color(0.2, 0.8, 1.0)
	_mat_powered.emission_energy_multiplier = 1.8
	
	_mat_unpowered = StandardMaterial3D.new()
	_mat_unpowered.albedo_color = Color(0.8, 0.1, 0.1)
	_mat_unpowered.emission_enabled = true
	_mat_unpowered.emission = Color(0.8, 0.1, 0.1)
	_mat_unpowered.emission_energy_multiplier = 0.8

func is_powered() -> bool:
	if has_node("/root/ShipState"):
		var ss = get_node("/root/ShipState")
		var my_dev := device_id if device_id != "" else ("door_aft" if "Aft" in name else "door_fwd")
		var dev = ss.get_device(my_dev)
		if dev != null:
			return dev.is_powered
	return ShipSystemManager.is_system_online("power_distribution")

func get_prompt() -> String:
	if is_locked:
		if requires_multitool_to_unlock:
			return "[Locked] %s (Use Multitool [%s] to unlock)" % [door_name, multitool_mode_required]
		return "[Locked] %s (%s)" % [door_name, lock_reason]
	if interlock_controller != null and not is_open:
		if interlock_controller.has_method("can_open_door") and not interlock_controller.can_open_door(self):
			return "[Interlocked] %s (Safety Protocol Active)" % door_name
	if not is_powered():
		return "[Locked] %s (No Bus Power)" % door_name
	var action_txt := "Close" if is_open else "Open"
	return "[E / Enter] %s %s" % [action_txt, door_name]

func _on_interacted(player: Node) -> void:
	if is_locked:
		if requires_multitool_to_unlock:
			var im = get_node_or_null("/root/InventoryManager")
			if im != null and im.get_equipped_item_id() == "multitool" and im.get_multitool_mode() == multitool_mode_required:
				is_locked = false
				requires_multitool_to_unlock = false
				AudioManager.play_sfx("repair")
				set_door_state(true)
				return
		AudioManager.play_sfx("denied")
		return
	if interlock_controller != null and not is_open:
		if interlock_controller.has_method("can_open_door") and not interlock_controller.can_open_door(self):
			AudioManager.play_sfx("denied")
			return
	if not is_powered():
		AudioManager.play_sfx("denied")
		return
	
	toggle_door()

func toggle_door() -> void:
	set_door_state(not is_open)

func set_door_state(open: bool, immediate: bool = false) -> void:
	if is_open == open and not immediate:
		return
	is_open = open
	AudioManager.play_sfx("door")
	
	var target_pos := _open_pos if is_open else _closed_pos
	var col_target := _col_open_pos if is_open else _col_closed_pos
	
	var panel_col: CollisionShape3D = door_panel.get_node_or_null("PanelCollision") if door_panel != null else null
	
	if immediate:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		if door_panel != null:
			door_panel.sync_to_physics = false
			door_panel.position = target_pos
		if interaction_col != null:
			interaction_col.position = col_target
		if panel_col != null:
			panel_col.set_deferred("disabled", is_open)
			panel_col.disabled = is_open
	else:
		if door_panel != null:
			door_panel.sync_to_physics = false
			if _tween != null and _tween.is_valid():
				_tween.kill()
			_tween = create_tween()
			_tween.tween_property(door_panel, "position", target_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			if interaction_col != null:
				_tween.parallel().tween_property(interaction_col, "position", col_target, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			if panel_col != null:
				if is_open:
					_tween.tween_callback(func(): panel_col.set_deferred("disabled", true))
				else:
					panel_col.set_deferred("disabled", false)
	
	_update_power_visuals()

func _update_power_visuals() -> void:
	var powered := is_powered()
	if indicator_mesh != null:
		indicator_mesh.material_override = _mat_powered if powered else _mat_unpowered
	if indicator_light != null:
		indicator_light.light_color = Color(0.2, 0.8, 1.0) if powered else Color(0.8, 0.1, 0.1)
		indicator_light.light_energy = 1.0 if powered else 0.4

func export_save_data() -> Dictionary:
	return {
		"is_open": is_open,
		"is_locked": is_locked,
		"requires_multitool_to_unlock": requires_multitool_to_unlock,
		"multitool_mode_required": multitool_mode_required,
		"device_id": device_id
	}

func import_save_data(data: Dictionary) -> void:
	is_locked = bool(data.get("is_locked", is_locked))
	requires_multitool_to_unlock = bool(data.get("requires_multitool_to_unlock", requires_multitool_to_unlock))
	multitool_mode_required = str(data.get("multitool_mode_required", multitool_mode_required))
	var should_open = bool(data.get("is_open", false))
	set_door_state(should_open, true)
