class_name AlienStalker
extends CharacterBody3D

# Physical Horror Alien Stalker Entity for ORBITAL: The Last Engineer (Milestone 7)
# Represents the predatory mutant specimen engineered in Project Chimera.
# Features physical 3D horror manifestation, terrifying boss spawn sequence,
# close-range horror camera zoom / jumpscare mechanics, corridor stalking,
# airlock quarantine trapping, and toxic gas elimination.

enum State {
	DORMANT = 0,
	SPAWNING = 1,
	STALKING = 2,
	HORROR_ZOOM = 3,
	AGGRESSIVE = 4,
	TRAPPED = 5,
	ELIMINATED = 6
}

signal state_changed(old_state: int, new_state: int)
signal horror_zoom_started
signal horror_zoom_completed
signal stalker_eliminated

@export var walk_speed: float = 3.4
@export var zoom_speed: float = 16.0
@export var zoom_target_distance: float = 1.8
@export var stalk_chamber_id: String = "specimen_vault"
@export var attack_damage: float = 35.0
@export var attack_range: float = 2.0
@export var attack_interval: float = 1.4
@export var safe_chamber_id: String = "medbay"

var current_state: int = State.DORMANT
var is_trapped: bool = false
var is_eliminated: bool = false
var horror_zoom_executed: bool = false
var _attack_cooldown: float = 0.0

var target_player: Node3D = null
var zoom_progress: float = 0.0
var zoom_duration: float = 1.0
var zoom_start_pos: Vector3 = Vector3.ZERO
var zoom_target_pos: Vector3 = Vector3.ZERO

var _pulse_timer: float = 0.0
var _bob_timer: float = 0.0
var _alien_footstep_timer: float = 0.0
var _proximity_impact_timer: float = 0.0
var _stalker_growl_timer: float = 0.0

@onready var alien_model: Node3D = get_node_or_null("AlienModel")
var _anim_player: AnimationPlayer = null

@onready var torso: MeshInstance3D = get_node_or_null("Torso")
@onready var head: MeshInstance3D = get_node_or_null("Head")
@onready var eye_left_light: OmniLight3D = get_node_or_null("EyeLeftLight")
@onready var eye_right_light: OmniLight3D = get_node_or_null("EyeRightLight")
@onready var claw_left: MeshInstance3D = get_node_or_null("ClawLeft")
@onready var claw_right: MeshInstance3D = get_node_or_null("ClawRight")
@onready var tail: MeshInstance3D = get_node_or_null("Tail")
@onready var spines: MeshInstance3D = get_node_or_null("Spines")
@onready var aura_light: OmniLight3D = get_node_or_null("AuraLight")
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")

func _ready() -> void:
	# Keep dormant until crisis activation
	if current_state == State.DORMANT:
		visible = false
	_refresh_visuals()
	
	if alien_model != null:
		var mesh_inst: MeshInstance3D = alien_model.find_child("alienMonster_001", true, false)
		if mesh_inst != null:
			var alien_mat: Material = load("res://resources/alien_material.tres")
			if alien_mat != null:
				mesh_inst.set_surface_override_material(0, alien_mat)
		_anim_player = alien_model.find_child("AnimationPlayer", true, false)
		if _anim_player != null and _anim_player.has_animation("Armature|Armature|mixamo_com|Layer0"):
			var anim := _anim_player.get_animation("Armature|Armature|mixamo_com|Layer0")
			if anim != null:
				anim.loop_mode = Animation.LOOP_LINEAR
			_anim_player.play("Armature|Armature|mixamo_com|Layer0")
	
	# Auto-register with ShipState crisis manager if active
	if ShipState != null and "crisis_manager" in ShipState and ShipState.crisis_manager != null:
		if ShipState.crisis_manager.has_method("register_stalker"):
			ShipState.crisis_manager.register_stalker(self)

func set_state(new_state: int) -> void:
	if current_state == new_state:
		return
	var old_state := current_state
	current_state = new_state
	
	match current_state:
		State.DORMANT:
			visible = false
			if collision_shape != null:
				collision_shape.disabled = true
		State.SPAWNING:
			visible = true
			if collision_shape != null:
				collision_shape.disabled = false
			if AudioManager != null:
				AudioManager.play_boss_screech()
		State.STALKING:
			visible = true
			if collision_shape != null:
				collision_shape.disabled = false
			if _anim_player != null:
				_anim_player.speed_scale = 1.0
				if not _anim_player.is_playing():
					_anim_player.play("Armature|Armature|mixamo_com|Layer0")
		State.HORROR_ZOOM:
			visible = true
			horror_zoom_executed = true
			if _anim_player != null:
				_anim_player.speed_scale = 2.0
				if not _anim_player.is_playing():
					_anim_player.play("Armature|Armature|mixamo_com|Layer0")
		State.AGGRESSIVE:
			visible = true
			if _anim_player != null:
				_anim_player.speed_scale = 1.5
				if not _anim_player.is_playing():
					_anim_player.play("Armature|Armature|mixamo_com|Layer0")
		State.TRAPPED:
			is_trapped = true
			visible = true
		State.ELIMINATED:
			is_eliminated = true
			if _anim_player != null:
				_anim_player.stop()
			if collision_shape != null:
				collision_shape.disabled = true
			if eye_left_light != null:
				eye_left_light.light_energy = 0.0
			if eye_right_light != null:
				eye_right_light.light_energy = 0.0
			if aura_light != null:
				aura_light.light_energy = 0.0
			stalker_eliminated.emit()
	
	_refresh_visuals()
	state_changed.emit(old_state, current_state)

func spawn_in_chamber(chamber_id: String, pos: Vector3 = Vector3.ZERO) -> void:
	stalk_chamber_id = chamber_id
	if pos != Vector3.ZERO:
		global_position = pos
	set_state(State.SPAWNING)
	# Smoothly transition from spawning roar to active stalking
	if is_inside_tree() and get_tree() != null:
		get_tree().create_timer(1.2).timeout.connect(func():
			if current_state == State.SPAWNING:
				set_state(State.STALKING)
		)

func is_player_in_safe_room() -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false
	if EnvironmentalManager != null and "instance" in EnvironmentalManager and EnvironmentalManager.instance != null:
		var env = EnvironmentalManager.instance
		if "player_compartment_id" in env and env.player_compartment_id == safe_chamber_id:
			return true
		if env.has_method("get_compartment_for_position"):
			return env.get_compartment_for_position(target_player.global_position) == safe_chamber_id
	elif is_inside_tree() and has_node("/root/EnvironmentalManager"):
		var env = get_node("/root/EnvironmentalManager")
		if "player_compartment_id" in env and env.player_compartment_id == safe_chamber_id:
			return true
		if env.has_method("get_compartment_for_position"):
			return env.get_compartment_for_position(target_player.global_position) == safe_chamber_id
	return false

func zoom_near_player(player: Node3D, duration: float = 1.0) -> void:
	target_player = player
	if is_player_in_safe_room():
		return
	zoom_duration = maxf(0.2, duration)
	zoom_progress = 0.0
	
	if player != null:
		# Calculate face-to-face camera vector
		var forward := -player.global_transform.basis.z.normalized()
		# If stalker is distant or dormant, spawn/materialize in front of player
		if global_position.distance_to(player.global_position) > 8.0 or current_state == State.DORMANT:
			zoom_start_pos = player.global_position + (forward * 6.5)
			zoom_start_pos.y = player.global_position.y
			global_position = zoom_start_pos
		else:
			zoom_start_pos = global_position
		
		zoom_target_pos = player.global_position + (forward * zoom_target_distance)
		zoom_target_pos.y = player.global_position.y
		
		var flat_dist := Vector2(global_position.x, global_position.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
		if flat_dist > 0.05:
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	else:
		zoom_start_pos = global_position
		zoom_target_pos = zoom_start_pos + Vector3(0, 0, -2.0)
	
	set_state(State.HORROR_ZOOM)
	horror_zoom_started.emit()
	
	if AudioManager != null:
		AudioManager.play_horror_zoom()
		AudioManager.play_boss_screech()
		AudioManager.play_heartbeat_rapid()
		if AudioManager.has_method("play_impact_hit"):
			AudioManager.play_impact_hit()
	
	if player != null and player.has_method("trigger_horror_zoom"):
		player.trigger_horror_zoom(duration, 25.0, 0.95)

func trap_in_chamber(chamber_id: String, pos: Vector3 = Vector3.ZERO) -> void:
	stalk_chamber_id = chamber_id
	if pos != Vector3.ZERO:
		global_position = pos
	elif chamber_id == "airlock_chamber":
		global_position = Vector3(8.0, 0.0, 8.0)
	set_state(State.TRAPPED)

func eliminate() -> void:
	set_state(State.ELIMINATED)
	if AudioManager != null:
		AudioManager.play_creature_roar()

func _execute_claw_attack() -> void:
	if is_player_in_safe_room():
		return
	_attack_cooldown = attack_interval
	if claw_left != null:
		claw_left.rotation.x = deg_to_rad(-55.0)
	if claw_right != null:
		claw_right.rotation.x = deg_to_rad(-55.0)
	if AudioManager != null:
		if AudioManager.has_method("play_creature_roar"):
			AudioManager.play_creature_roar()
		if AudioManager.has_method("play_impact_hit"):
			AudioManager.play_impact_hit()
	if target_player != null and is_instance_valid(target_player) and target_player.has_method("take_damage"):
		target_player.take_damage(attack_damage, "creature")

func _handle_doors_in_path() -> void:
	if current_state == State.DORMANT or current_state == State.ELIMINATED or current_state == State.TRAPPED:
		return
	if not is_inside_tree() or get_tree() == null:
		return
	var root := get_tree().current_scene
	if root == null:
		return
	var doors := root.find_children("*", "BulkheadDoor", true, false)
	for d in doors:
		if d is BulkheadDoor and is_instance_valid(d):
			var dist := global_position.distance_to(d.global_position)
			if dist <= 3.8:
				if d.is_locked:
					d.is_locked = false
					d.requires_multitool_to_unlock = false
				if not d.is_open:
					d.set_door_state(true)
					if AudioManager != null and AudioManager.has_method("play_gate_opening"):
						AudioManager.play_gate_opening()
				if d.door_panel != null:
					add_collision_exception_with(d.door_panel)

func _get_navigation_target(alien_pos: Vector3, player_pos: Vector3) -> Vector3:
	var ax: float = alien_pos.x
	var az: float = alien_pos.z
	var px: float = player_pos.x
	var pz: float = player_pos.z
	
	# Lower Deck (Subdeck or Specimen Vault)
	if az > 21.2:
		if pz > 21.2:
			return player_pos
		return Vector3(0.0, 0.0, 21.2)
	
	# Engineering Bay
	if az > 11.0:
		if pz > 21.2:
			return Vector3(0.0, 0.0, 21.2)
		if pz > 11.0:
			return player_pos
		return Vector3(0.0, 0.0, 11.0)
	
	# Central Transit Spine (Corridors)
	if az <= 11.0 and az >= -7.0 and absf(ax) <= 3.5:
		if pz > 11.0:
			return Vector3(0.0, 0.0, 11.0)
		if px < -3.5 and pz >= 0.0:
			return Vector3(-3.5, 0.0, 6.0)
		if px > 3.5 and pz >= 0.0:
			return Vector3(3.5, 0.0, 6.0)
		if px < -3.5 and pz < 0.0:
			return Vector3(-3.5, 0.0, -2.0)
		if px > 3.5 and pz < 0.0:
			return Vector3(3.5, 0.0, -2.0)
		if pz < -7.0:
			return Vector3(0.0, 0.0, -7.0)
		return player_pos
	
	# Cargo Bay (West wing aft)
	if ax < -3.5 and az >= 0.0:
		if px < -3.5 and pz >= 0.0:
			return player_pos
		return Vector3(-3.5, 0.0, 6.0)
	
	# Airlock (East wing aft)
	if ax > 3.5 and az >= 0.0:
		if px > 3.5 and pz >= 0.0:
			return player_pos
		return Vector3(3.5, 0.0, 6.0)
	
	# Crew Quarters (West wing forward)
	if ax < -3.5 and az < 0.0:
		if px < -3.5 and pz < 0.0:
			return player_pos
		return Vector3(-3.5, 0.0, -2.0)
	
	# Medbay (East wing forward)
	if ax > 3.5 and az < 0.0:
		if px > 3.5 and pz < 0.0:
			return player_pos
		return Vector3(3.5, 0.0, -2.0)
	
	# Bridge
	if az < -7.0 and az >= -17.0:
		if pz < -17.0:
			return Vector3(0.0, 0.0, -17.0)
		if pz >= -7.0:
			return Vector3(0.0, 0.0, -7.0)
		return player_pos
	
	# Avionics Bay
	if az < -17.0:
		if pz < -17.0:
			return player_pos
		return Vector3(0.0, 0.0, -17.0)
	
	return player_pos

func _physics_process(delta: float) -> void:
	_pulse_timer += delta * 5.0
	_bob_timer += delta * 3.0
	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _proximity_impact_timer > 0.0:
		_proximity_impact_timer = maxf(0.0, _proximity_impact_timer - delta)
	
	# Breathing & eye pulsing visuals
	_update_animation_effects(delta)
	
	# Apply standard gravity when not grounded
	if not is_on_floor() and current_state != State.ELIMINATED:
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	
	# Ensure target player is cached when active
	if (target_player == null or not is_instance_valid(target_player)) and is_inside_tree() and get_tree() != null:
		target_player = get_tree().root.find_child("Player", true, false)
	
	# Proximity door handling - doors do not trap alien
	_handle_doors_in_path()
	
	# Proximity impact sound when near player
	if visible and current_state != State.DORMANT and current_state != State.ELIMINATED and target_player != null and is_instance_valid(target_player):
		var flat_dist := Vector2(global_position.x, global_position.z).distance_to(Vector2(target_player.global_position.x, target_player.global_position.z))
		if flat_dist <= 3.8 and not is_player_in_safe_room() and _proximity_impact_timer <= 0.0:
			_proximity_impact_timer = 2.5
			if AudioManager != null and AudioManager.has_method("play_impact_hit"):
				AudioManager.play_impact_hit()
	
	match current_state:
		State.HORROR_ZOOM:
			zoom_progress += delta / zoom_duration
			var t := clampf(zoom_progress, 0.0, 1.0)
			# Dramatic cubic horror lunge acceleration
			var ease_t := 1.0 - pow(1.0 - t, 3.0)
			global_position = zoom_start_pos.lerp(zoom_target_pos, ease_t)
			
			if target_player != null and is_instance_valid(target_player):
				var flat_dist := Vector2(global_position.x, global_position.z).distance_to(Vector2(target_player.global_position.x, target_player.global_position.z))
				if flat_dist > 0.1:
					look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
			
			if zoom_progress >= 1.0:
				horror_zoom_completed.emit()
				set_state(State.AGGRESSIVE)
		
		State.STALKING:
			if is_player_in_safe_room():
				velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 5.0 * delta)
				move_and_slide()
			elif target_player != null and is_instance_valid(target_player):
				var nav_target := _get_navigation_target(global_position, target_player.global_position)
				var dir := (nav_target - global_position).normalized()
				dir.y = 0.0
				velocity.x = dir.x * walk_speed
				velocity.z = dir.z * walk_speed
				var flat_dist := Vector2(global_position.x, global_position.z).distance_to(Vector2(target_player.global_position.x, target_player.global_position.z))
				if flat_dist <= 8.0:
					look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
				elif dir.length_squared() > 0.01:
					look_at(Vector3(global_position.x + dir.x, global_position.y, global_position.z + dir.z), Vector3.UP)
				
				if flat_dist <= attack_range and _attack_cooldown <= 0.0:
					set_state(State.AGGRESSIVE)
					_execute_claw_attack()
				
				# Footstep sounds when moving
				_alien_footstep_timer += delta
				if _alien_footstep_timer >= 0.65:
					_alien_footstep_timer = 0.0
					if AudioManager != null and AudioManager.has_method("play_alien_footstep"):
						AudioManager.play_alien_footstep()
				
				# Menacing stalking audio atmosphere
				_stalker_growl_timer += delta
				if flat_dist <= 8.5 and _stalker_growl_timer >= 3.8:
					_stalker_growl_timer = randf_range(0.0, 0.8)
					if AudioManager != null:
						AudioManager.play_creature_sound()
						if flat_dist <= 5.0:
							AudioManager.play_heartbeat_rapid()
				
				move_and_slide()
		
		State.AGGRESSIVE:
			if is_player_in_safe_room():
				velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 6.0 * delta)
				move_and_slide()
				set_state(State.STALKING)
			elif target_player != null and is_instance_valid(target_player):
				var nav_target := _get_navigation_target(global_position, target_player.global_position)
				var dir := (nav_target - global_position).normalized()
				dir.y = 0.0
				velocity.x = dir.x * (walk_speed * 1.5)
				velocity.z = dir.z * (walk_speed * 1.5)
				var flat_dist := Vector2(global_position.x, global_position.z).distance_to(Vector2(target_player.global_position.x, target_player.global_position.z))
				if flat_dist <= 8.0:
					look_at(Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z), Vector3.UP)
				elif dir.length_squared() > 0.01:
					look_at(Vector3(global_position.x + dir.x, global_position.y, global_position.z + dir.z), Vector3.UP)
				
				if flat_dist <= attack_range and _attack_cooldown <= 0.0:
					_execute_claw_attack()
				
				# Faster footstep sounds in aggressive pursuit
				_alien_footstep_timer += delta
				if _alien_footstep_timer >= 0.38:
					_alien_footstep_timer = 0.0
					if AudioManager != null and AudioManager.has_method("play_alien_footstep"):
						AudioManager.play_alien_footstep()
				
				_stalker_growl_timer += delta
				if flat_dist <= 8.5 and _stalker_growl_timer >= 2.5:
					_stalker_growl_timer = randf_range(0.0, 0.5)
					if AudioManager != null:
						AudioManager.play_heartbeat_rapid()
				
				move_and_slide()
		
		State.TRAPPED:
			# Shakes violently against chamber bulkhead
			velocity = Vector3(sin(_bob_timer * 12.0) * 0.8, 0.0, cos(_bob_timer * 12.0) * 0.8)
			move_and_slide()
		
		State.ELIMINATED:
			# Collapse downward
			velocity = Vector3.ZERO
			if position.y > -0.6:
				position.y -= delta * 1.5

func _update_animation_effects(_delta: float) -> void:
	if current_state == State.ELIMINATED:
		if eye_left_light != null:
			eye_left_light.light_energy = 0.0
		if eye_right_light != null:
			eye_right_light.light_energy = 0.0
		if aura_light != null:
			aura_light.light_energy = 0.0
		return
	
	# Sinister pulsing crimson eye glow
	var eye_energy := 2.0 + sin(_pulse_timer) * 0.8
	if eye_left_light != null:
		eye_left_light.light_energy = eye_energy
	if eye_right_light != null:
		eye_right_light.light_energy = eye_energy
	
	if aura_light != null:
		aura_light.light_energy = 1.0 + sin(_pulse_timer * 0.5) * 0.4
	
	# Claws & Spine bobbing or strike attack pose
	if _attack_cooldown > 0.8:
		if claw_left != null:
			claw_left.rotation.x = deg_to_rad(-55.0)
			claw_left.rotation.z = deg_to_rad(30.0)
		if claw_right != null:
			claw_right.rotation.x = deg_to_rad(-55.0)
			claw_right.rotation.z = deg_to_rad(-30.0)
	else:
		if claw_left != null:
			claw_left.rotation.x = 0.0
			claw_left.rotation.z = deg_to_rad(sin(_bob_timer) * 6.0)
		if claw_right != null:
			claw_right.rotation.x = 0.0
			claw_right.rotation.z = deg_to_rad(-sin(_bob_timer) * 6.0)
	if tail != null:
		tail.rotation.x = deg_to_rad(-20.0 + sin(_bob_timer * 1.5) * 8.0)

func _refresh_visuals() -> void:
	var active := (current_state != State.DORMANT)
	visible = active
	if current_state == State.ELIMINATED:
		if eye_left_light != null:
			eye_left_light.light_energy = 0.0
		if eye_right_light != null:
			eye_right_light.light_energy = 0.0
		if aura_light != null:
			aura_light.light_energy = 0.0
	if eye_left_light != null:
		eye_left_light.visible = (active and current_state != State.ELIMINATED)
	if eye_right_light != null:
		eye_right_light.visible = (active and current_state != State.ELIMINATED)
	if aura_light != null:
		aura_light.visible = (active and current_state != State.ELIMINATED)
