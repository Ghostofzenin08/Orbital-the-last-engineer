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

func _ready() -> void:
	collision_layer = 2 # bit 1 = Player
	collision_mask = 1  # bit 0 = Environment
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
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
	
	if camera != null:
		if shiver_intensity > 0.0:
			camera.rotation.z = sin(Time.get_ticks_msec() * 0.02) * shiver_intensity
		else:
			camera.rotation.z = 0.0
	
	move_and_slide()

var is_shivering: bool:
	get:
		return shiver_intensity > 0.0

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
