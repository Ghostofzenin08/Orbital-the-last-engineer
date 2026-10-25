class_name PlayerController
extends CharacterBody3D

# 3D First-Person Player Controller for ORBITAL: The Last Engineer
# Handles mouse look, dual-bound movement (WASD + Arrows), sprint, pause, and collision.

@export var walk_speed: float = 3.6
@export var sprint_speed: float = 5.6
@export var acceleration: float = 12.0
@export var deceleration: float = 14.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var interaction_ctrl: InteractionController = $CameraPivot/Camera3D/InteractionController
@onready var hud: Node = $HUD

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _pitch: float = 0.0
var speed_modifier: float = 1.0
var shiver_intensity: float = 0.0

# Health & Survival Mechanics
var player_health: float = 100.0
var max_health: float = 100.0
var is_dead: bool = false
var _footstep_timer: float = 0.0

# Vibration & Structural Tremor Mechanics
var _vibration_timer: float = 0.0
var _vibration_duration: float = 0.0
var _vibration_intensity: float = 0.0

var is_vibrating: bool:
	get:
		return _vibration_timer > 0.0

signal health_changed(new_health: float, max_health: float)
signal player_died(reason: String)

# Milestone 7: Horror Boss Zoom & Camera Trauma Mechanics
var camera_trauma: float = 0.0
var _horror_zoom_timer: float = 0.0
var _horror_zoom_duration: float = 1.0
var _base_fov: float = 75.0
var _target_fov: float = 75.0

func _ready() -> void:
	collision_layer = 2 # bit 1 = Player
	collision_mask = 1  # bit 0 = Environment
	floor_snap_length = 0.35
	floor_constant_speed = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if camera != null:
		_base_fov = camera.fov
		_target_fov = _base_fov
	
	if interaction_ctrl != null and hud != null and hud.has_method("set_prompt"):
		interaction_ctrl.prompt_changed.connect(hud.set_prompt)

func _unhandled_input(event: InputEvent) -> void:
	# Click to recapture mouse if focus was lost while not in a menu
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		var pause_menu: Node = hud.get_node_or_null("PauseMenu") if hud != null else null
		var terminal_dialog: Node = hud.get_node_or_null("TerminalDialog") if hud != null else null
		var ship_schematic: Node = hud.get_node_or_null("ShipSchematic") if hud != null else null
		var in_menu: bool = (pause_menu != null and pause_menu.visible) or (terminal_dialog != null and terminal_dialog.visible) or (ship_schematic != null and ship_schematic.visible)
		if not in_menu:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = SaveManager.mouse_sensitivity
		# Yaw on body
		rotate_y(-event.relative.x * sens)
		# Pitch on camera pivot
		_pitch = clampf(_pitch - (event.relative.y * sens), deg_to_rad(-85.0), deg_to_rad(85.0))
		camera_pivot.rotation.x = _pitch
	
	if event.is_action_pressed("pause"):
		_toggle_pause()
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			InventoryManager.equip_slot(1)
		elif event.keycode == KEY_2:
			if InventoryManager.get_equipped_item_id() == "multitool":
				InventoryManager.cycle_multitool_mode()
			else:
				InventoryManager.equip_slot(2)
		elif event.keycode == KEY_3:
			InventoryManager.equip_slot(3)
		elif event.keycode == KEY_4:
			InventoryManager.equip_slot(4)
			InventoryManager.use_battery_cell()
		elif event.keycode == KEY_Q:
			if InventoryManager.get_equipped_item_id() == "multitool":
				InventoryManager.cycle_multitool_mode()
			else:
				var next_s: int = (InventoryManager.active_slot % 4) + 1
				InventoryManager.equip_slot(next_s)

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if interaction_ctrl != null and interaction_ctrl.current_interactable != null:
			var target = interaction_ctrl.current_interactable
			var equipped = InventoryManager.get_equipped_item_id()
			if target is MultiStepRepairPanel:
				target.interact(self)
			elif target is DatapadPickup and equipped == "diagnostic_scanner" and (not target.is_collected or not target.is_decrypted):
				target.interact(self)
			elif equipped == "diagnostic_scanner":
				InventoryManager.perform_diagnostic_scan(target)
			elif equipped == "multitool":
				InventoryManager.perform_multitool_action("USE", target)
				if target.has_method("interact"):
					target.interact(self)
			elif equipped == "battery_cell":
				InventoryManager.use_battery_cell()
			else:
				if target.has_method("interact"):
					target.interact(self)



func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		move_and_slide()
		return
	
	# Laptop-friendly Keyboard Rotation (Left / Right Arrow keys turn the character sideways)
	var turn_input: float = 0.0
	if Input.is_key_pressed(KEY_LEFT):
		turn_input += 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		turn_input -= 1.0
	if turn_input != 0.0:
		var turn_speed: float = 2.4 # radians per second (~137 deg/s)
		rotate_y(turn_input * turn_speed * delta)
	
	# Optional keyboard pitch (Page Up / Page Down to look up/down)
	var pitch_input: float = 0.0
	if Input.is_key_pressed(KEY_PAGEUP):
		pitch_input += 1.0
	if Input.is_key_pressed(KEY_PAGEDOWN):
		pitch_input -= 1.0
	if pitch_input != 0.0:
		_pitch = clampf(_pitch + (pitch_input * 2.0 * delta), deg_to_rad(-85.0), deg_to_rad(85.0))
		camera_pivot.rotation.x = _pitch

	# Determine movement input
	var input_dir := Vector2.ZERO
	
	# Movement checks: W / Up Arrow for forward, S / Down Arrow for backward, A / D for strafe
	if Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or (Input.is_action_pressed("move_left") and not Input.is_key_pressed(KEY_LEFT)):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or (Input.is_action_pressed("move_right") and not Input.is_key_pressed(KEY_RIGHT)):
		input_dir.x += 1.0
	
	input_dir = input_dir.normalized()
	
	# Transform input direction relative to body facing
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_sprinting := Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)
	var base_speed := sprint_speed if is_sprinting else walk_speed
	var target_speed := base_speed * speed_modifier
	
	var target_vel_x := direction.x * target_speed
	var target_vel_z := direction.z * target_speed
	
	var current_rate := acceleration if direction.length_squared() > 0.001 else deceleration
	velocity.x = move_toward(velocity.x, target_vel_x, current_rate * delta)
	velocity.z = move_toward(velocity.z, target_vel_z, current_rate * delta)
	
	if _horror_zoom_timer > 0.0:
		_horror_zoom_timer -= delta
		var alpha := 1.0 - clampf(_horror_zoom_timer / _horror_zoom_duration, 0.0, 1.0)
		if camera != null:
			camera.fov = lerpf(_target_fov, _base_fov, alpha)
	elif camera != null and absf(camera.fov - _base_fov) > 0.1:
		camera.fov = move_toward(camera.fov, _base_fov, delta * 35.0)

	if camera != null:
		if camera_trauma > 0.0:
			camera_trauma = maxf(0.0, camera_trauma - delta * 1.25)
			var shake := camera_trauma * camera_trauma
			camera.h_offset = (randf() * 2.0 - 1.0) * 0.14 * shake
			camera.v_offset = (randf() * 2.0 - 1.0) * 0.14 * shake
			camera.rotation.z = (randf() * 2.0 - 1.0) * 0.06 * shake
		else:
			camera.h_offset = 0.0
			camera.v_offset = 0.0
			if shiver_intensity > 0.0:
				camera.rotation.z = sin(Time.get_ticks_msec() * 0.02) * shiver_intensity
			else:
				camera.rotation.z = 0.0
	
	if _vibration_timer > 0.0:
		_vibration_timer -= delta
		if camera != null:
			var t := _vibration_timer / _vibration_duration
			var v_amp := _vibration_intensity * t * 0.14
			camera.h_offset += (randf() * 2.0 - 1.0) * v_amp
			camera.v_offset += (randf() * 2.0 - 1.0) * v_amp
			camera.rotation.z += (randf() * 2.0 - 1.0) * 0.05 * _vibration_intensity * t
	
	# Footstep audio triggering when grounded and moving
	var horiz_vel := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz_vel > 0.6:
		var step_interval := 0.32 if is_sprinting else 0.48
		_footstep_timer += delta
		if _footstep_timer >= step_interval:
			_footstep_timer = 0.0
			if AudioManager != null and AudioManager.has_method("play_footstep"):
				AudioManager.play_footstep(is_sprinting)
	else:
		_footstep_timer = 0.0
	
	move_and_slide()

var is_shivering: bool:
	get:
		return shiver_intensity > 0.0

var is_in_horror_shock: bool:
	get:
		return _horror_zoom_timer > 0.0 or camera_trauma > 0.15

func take_damage(amount: float, source: String = "creature") -> void:
	if is_dead:
		return
	player_health = maxf(0.0, player_health - amount)
	health_changed.emit(player_health, max_health)
	
	# Violent camera trauma kick and horror vignette
	camera_trauma = clampf(camera_trauma + 0.85, 0.0, 1.0)
	if hud != null and hud.has_method("trigger_horror_vignette"):
		hud.trigger_horror_vignette(0.6)
	
	if AudioManager != null:
		AudioManager.play_sfx("cough_gasp", 0.9)
	
	if player_health <= 0.0:
		is_dead = true
		player_died.emit(source)
		_handle_player_death(source)

func _handle_player_death(source: String) -> void:
	if ShipState != null and "death_reason" in ShipState:
		if source == "creature":
			ShipState.death_reason = "CREATURE_ATTACK"
		else:
			ShipState.death_reason = source
	if is_inside_tree() and get_tree() != null:
		var cur := get_tree().current_scene
		if cur != null and cur.scene_file_path.contains("test_runner"):
			return
		get_tree().change_scene_to_file.call_deferred("res://scenes/ui/game_over.tscn")

func trigger_horror_zoom(duration: float = 1.2, fov_drop: float = 24.0, trauma: float = 0.85) -> void:
	if camera != null:
		_target_fov = maxf(42.0, _base_fov - fov_drop)
		camera.fov = _target_fov
		_horror_zoom_duration = maxf(0.1, duration)
		_horror_zoom_timer = _horror_zoom_duration
	camera_trauma = clampf(camera_trauma + trauma, 0.0, 1.0)
	if hud != null and hud.has_method("trigger_horror_vignette"):
		hud.trigger_horror_vignette(duration)

func trigger_vibration_alert(duration: float = 3.5, intensity: float = 0.6) -> void:
	_vibration_duration = maxf(0.1, duration)
	_vibration_timer = _vibration_duration
	_vibration_intensity = intensity
	camera_trauma = clampf(camera_trauma + intensity * 0.75, 0.0, 1.0)
	if hud != null and hud.has_method("show_notification"):
		hud.show_notification("WARNING: SEISMIC VIBRATION DETECTED // BULKHEAD STRUCTURAL ANOMALY", duration)

func apply_environmental_afflictions(afflictions: Array) -> void:
	if afflictions.has("DECOMPRESSION"):
		speed_modifier = 0.55
		shiver_intensity = 0.0
	elif afflictions.has("HYPOTHERMIA"):
		speed_modifier = 0.65
		shiver_intensity = 0.035
	elif afflictions.has("HEATSTROKE"):
		speed_modifier = 0.70
		shiver_intensity = 0.0
	elif afflictions.has("HYPOXIA") or afflictions.has("CO2_TOXICITY"):
		speed_modifier = 0.75
		shiver_intensity = 0.0
	else:
		speed_modifier = 1.0
		shiver_intensity = 0.0

func _toggle_pause() -> void:
	var pause_menu: Node = hud.get_node_or_null("PauseMenu")
	if pause_menu != null and pause_menu.has_method("toggle_pause"):
		pause_menu.toggle_pause()
