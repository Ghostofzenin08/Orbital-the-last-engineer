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
var lethal_chase_active: bool = false
var is_orbiting_outside_airlock: bool = false
var _airlock_orbit_angle: float = 0.0
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
var _face_thrash_timer: float = 0.0

@onready var alien_model: Node3D = get_node_or_null("AlienModel")
var _anim_player: AnimationPlayer = null
var _skeleton: Skeleton3D = null
var _walk_cycle_phase: float = 0.0
var _stride_blend: float = 0.0
var _bone_indices: Dictionary = {}
var _bone_rest_quats: Dictionary = {}
var _hips_rest_origin: Vector3 = Vector3(0.0, 1.183, 0.01)
var _cached_doors: Array[Node] = []
var _door_check_timer: float = 0.0

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
			mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var alien_mat: Material = load("res://resources/alien_material.tres")
			if alien_mat != null:
				mesh_inst.set_surface_override_material(0, alien_mat)
		_anim_player = alien_model.find_child("AnimationPlayer", true, false)
		var skels := alien_model.find_children("*", "Skeleton3D", true, false)
		if skels.size() > 0:
			_skeleton = skels[0] as Skeleton3D
			_cache_skeleton_bones_and_build_walk_cycle()
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

func is_player_in_airlock_chamber() -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false
	if EnvironmentalManager != null and "instance" in EnvironmentalManager and EnvironmentalManager.instance != null:
		var env = EnvironmentalManager.instance
		if "player_compartment_id" in env and env.player_compartment_id == "airlock_chamber":
			return true
		if env.has_method("get_compartment_for_position"):
			return env.get_compartment_for_position(target_player.global_position) == "airlock_chamber"
	var p := target_player.global_position
	return p.x > 2.0 and p.z >= 3.5 and p.z < 14.5

func _orbit_outside_airlock_chamber(delta: float) -> void:
	is_orbiting_outside_airlock = true
	_airlock_orbit_angle += delta * 2.4
	# Ensure the alien never enters inside the Airlock Chamber (x > 2.2)
	if global_position.x > 2.2 and global_position.z >= 3.5 and global_position.z <= 14.5:
		global_position.x = 1.6
	# Circle menacingly outside the East Airlock Chamber doorway (x=4.0, z=8.0) in the Central Corridor
	var orbit_center := Vector3(0.2, global_position.y, 8.0)
	var orbit_target := orbit_center + Vector3(cos(_airlock_orbit_angle) * 1.1, 0.0, sin(_airlock_orbit_angle) * 2.0)
	var nav_target := _get_navigation_target(global_position, orbit_target)
	var to_target := nav_target - global_position
	to_target.y = 0.0
	if to_target.length() > 0.05:
		var dir := to_target.normalized()
		velocity.x = dir.x * walk_speed
		velocity.z = dir.z * walk_speed
	else:
		velocity.x = cos(_airlock_orbit_angle + PI * 0.5) * walk_speed
		velocity.z = sin(_airlock_orbit_angle + PI * 0.5) * walk_speed
	# Face toward the Airlock Chamber door or movement direction while rounding outside
	if target_player != null and is_instance_valid(target_player):
		var look_pos := Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z)
		if Vector2(global_position.x, global_position.z).distance_to(Vector2(look_pos.x, look_pos.z)) > 0.1:
			look_at(look_pos, Vector3.UP)
	_alien_footstep_timer += delta
	if _alien_footstep_timer >= 0.55:
		_alien_footstep_timer = 0.0
		if AudioManager != null and AudioManager.has_method("play_alien_footstep"):
			AudioManager.play_alien_footstep()
	_stalker_growl_timer += delta
	if _stalker_growl_timer >= 3.2:
		_stalker_growl_timer = 0.0
		if AudioManager != null:
			AudioManager.play_creature_sound()
	move_and_slide()
	if global_position.x > 2.2 and global_position.z >= 3.5 and global_position.z <= 14.5:
		global_position.x = 2.0

func zoom_near_player(player: Node3D, duration: float = 1.0) -> void:
	target_player = player
	if is_player_in_safe_room() or is_player_in_airlock_chamber():
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
	_face_thrash_timer = maxf(0.9, duration)
	horror_zoom_started.emit()
	
	if AudioManager != null:
		AudioManager.play_horror_zoom()
		AudioManager.play_boss_screech()
		AudioManager.play_heartbeat_rapid()
		if AudioManager.has_method("play_jumpscare_scream"):
			AudioManager.play_jumpscare_scream()
		elif AudioManager.has_method("play_impact_hit"):
			AudioManager.play_impact_hit()
	
	if player != null and player.has_method("trigger_jumpscare_face_zoom"):
		player.trigger_jumpscare_face_zoom(self, duration)
	elif player != null and player.has_method("trigger_horror_zoom"):
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
	if is_player_in_safe_room() or is_player_in_airlock_chamber():
		return
	_attack_cooldown = attack_interval
	_face_thrash_timer = 0.95
	if claw_left != null:
		claw_left.rotation.x = deg_to_rad(-55.0)
	if claw_right != null:
		claw_right.rotation.x = deg_to_rad(-55.0)
	if AudioManager != null:
		if AudioManager.has_method("play_jumpscare_scream"):
			AudioManager.play_jumpscare_scream()
		if AudioManager.has_method("play_creature_roar"):
			AudioManager.play_creature_roar()
		if AudioManager.has_method("play_impact_hit"):
			AudioManager.play_impact_hit()
	if target_player != null and is_instance_valid(target_player):
		if target_player.has_method("trigger_jumpscare_face_zoom"):
			target_player.trigger_jumpscare_face_zoom(self, 0.95)
		if target_player.has_method("take_damage"):
			var dmg: float = maxf(attack_damage, 100.0) if lethal_chase_active else attack_damage
			target_player.take_damage(dmg, "creature")

func _handle_doors_in_path() -> void:
	if current_state == State.DORMANT or current_state == State.ELIMINATED or current_state == State.TRAPPED:
		return
	if not is_inside_tree() or get_tree() == null:
		return
	if _cached_doors.is_empty():
		var root: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
		if root == null:
			return
		var found := root.find_children("*", "BulkheadDoor", true, false)
		if found.is_empty():
			for child in root.find_children("*", "StaticBody3D", true, false):
				if child is BulkheadDoor or child.has_method("set_door_state"):
					found.append(child)
		for d in found:
			if is_instance_valid(d):
				_cached_doors.append(d)
	for d in _cached_doors:
		if is_instance_valid(d) and (d is BulkheadDoor or d.has_method("set_door_state")):
			if d.name == "AirlockInner" or d.name == "AirlockOuter" or ("device_id" in d and str(d.device_id).begins_with("airlock")):
				continue
			var dist := global_position.distance_to(d.global_position)
			if dist <= 4.5:
				if "is_locked" in d and d.is_locked:
					d.is_locked = false
				if "requires_multitool_to_unlock" in d:
					d.requires_multitool_to_unlock = false
				if "is_open" in d and not d.is_open:
					d.set_door_state(true)
					if AudioManager != null and AudioManager.has_method("play_gate_opening"):
						AudioManager.play_gate_opening()
				if "door_panel" in d and d.door_panel != null:
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
	
	# Engineering Bay (Obstacle avoidance around GeneratorUnit at x=0, z=18.0)
	if az > 11.0:
		var target_z := pz if (pz > 11.0 and pz <= 21.2) else (21.2 if pz > 21.2 else 11.0)
		var target_x := px if (pz > 11.0 and pz <= 21.2) else 0.0
		
		var crossing_generator := (az < 16.5 and target_z > 17.0) or (az > 19.5 and target_z < 19.0)
		if crossing_generator or (az >= 16.0 and az <= 20.0 and absf(ax) < 2.2):
			var bypass_x := -2.5 if (ax < 0.0 or (ax == 0.0 and (target_x < 0.0 or px < 0.0))) else 2.5
			if target_z > az:
				return Vector3(bypass_x, 0.0, 20.5)
			else:
				return Vector3(bypass_x, 0.0, 15.5)
		
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
	if _face_thrash_timer > 0.0:
		_face_thrash_timer = maxf(0.0, _face_thrash_timer - delta)
	
	# Breathing & eye pulsing visuals
	_update_animation_effects(delta)
	
	# Apply standard gravity when not grounded
	if not is_on_floor() and current_state != State.ELIMINATED:
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	
	# Auto-seek player when all 4 repair tasks are complete
	if MissionManager != null and MissionManager.has_method("are_all_repairs_complete") and MissionManager.are_all_repairs_complete():
		if current_state == State.DORMANT:
			set_state(State.STALKING)
	
	# Ensure target player is cached when active
	if (target_player == null or not is_instance_valid(target_player)) and is_inside_tree() and get_tree() != null:
		target_player = get_tree().root.find_child("Player", true, false)
	
	# Proximity door handling - throttled to avoid per-frame checks
	_door_check_timer += delta
	if _door_check_timer >= 0.15:
		_door_check_timer = 0.0
		_handle_doors_in_path()
	
	# Proximity impact sound and horror stalking atmosphere when near player
	if visible and current_state != State.DORMANT and current_state != State.ELIMINATED and target_player != null and is_instance_valid(target_player):
		var flat_dist := Vector2(global_position.x, global_position.z).distance_to(Vector2(target_player.global_position.x, target_player.global_position.z))
		if flat_dist <= 9.0 and not is_player_in_safe_room() and _proximity_impact_timer <= 0.0:
			_proximity_impact_timer = 2.4
			if AudioManager != null and AudioManager.has_method("play_impact_hit"):
				AudioManager.play_impact_hit()
			if AudioManager != null and AudioManager.has_method("play_creature_sound"):
				AudioManager.play_creature_sound()
			if flat_dist <= 5.5:
				if AudioManager != null and AudioManager.has_method("play_heartbeat_rapid"):
					AudioManager.play_heartbeat_rapid()
				if "camera_trauma" in target_player:
					target_player.camera_trauma = maxf(float(target_player.camera_trauma), 0.35)
	
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
				is_orbiting_outside_airlock = false
				velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 5.0 * delta)
				move_and_slide()
			elif is_player_in_airlock_chamber():
				# Player reached Airlock Chamber: Alien rounds/circles outside the chamber until poison valve is opened
				_orbit_outside_airlock_chamber(delta)
			elif target_player != null and is_instance_valid(target_player):
				is_orbiting_outside_airlock = false
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
				elif flat_dist <= 3.6 and not horror_zoom_executed and not is_player_in_safe_room():
					zoom_near_player(target_player, 0.85)
					return
				
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
				is_orbiting_outside_airlock = false
				velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 6.0 * delta)
				move_and_slide()
				set_state(State.STALKING)
			elif is_player_in_airlock_chamber():
				set_state(State.STALKING)
				_orbit_outside_airlock_chamber(delta)
			elif target_player != null and is_instance_valid(target_player):
				is_orbiting_outside_airlock = false
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
	
	# Update 2-legged bipedal stride pose on the Mixamo Skeleton3D so the alien walks/runs on its 2 legs instead of sliding
	_update_bipedal_walk_cycle(delta)

func _cache_skeleton_bones_and_build_walk_cycle() -> void:
	if _skeleton == null:
		return
	var bone_names: Array[String] = [
		"mixamorig_Hips",
		"mixamorig_Spine",
		"mixamorig_Spine1",
		"mixamorig_Spine2",
		"mixamorig_Neck",
		"mixamorig_Head",
		"mixamorig_LeftShoulder",
		"mixamorig_LeftArm",
		"mixamorig_LeftForeArm",
		"mixamorig_LeftHand",
		"mixamorig_RightShoulder",
		"mixamorig_RightArm",
		"mixamorig_RightForeArm",
		"mixamorig_RightHand",
		"mixamorig_LeftUpLeg",
		"mixamorig_LeftLeg",
		"mixamorig_LeftFoot",
		"mixamorig_LeftToeBase",
		"mixamorig_RightUpLeg",
		"mixamorig_RightLeg",
		"mixamorig_RightFoot",
		"mixamorig_RightToeBase"
	]
	for bname in bone_names:
		var idx := _skeleton.find_bone(bname)
		if idx >= 0:
			_bone_indices[bname] = idx
			var rest := _skeleton.get_bone_rest(idx)
			_bone_rest_quats[bname] = rest.basis.get_rotation_quaternion()
			if bname == "mixamorig_Hips":
				_hips_rest_origin = rest.origin
	
	# Replace the static 1-keyframe T-pose in AnimationPlayer with a real multi-keyframe bipedal walk cycle
	if _anim_player != null and _anim_player.has_animation("Armature|Armature|mixamo_com|Layer0"):
		var anim := _anim_player.get_animation("Armature|Armature|mixamo_com|Layer0")
		if anim != null:
			while anim.get_track_count() > 0:
				anim.remove_track(0)
			anim.length = 1.0
			anim.loop_mode = Animation.LOOP_LINEAR
			var skel_path := "Armature/Skeleton3D"
			if _anim_player.get_parent() != null:
				skel_path = str(_anim_player.get_parent().get_path_to(_skeleton))
			var sample_count := 12
			var tracked_bones: Array[String] = [
				"mixamorig_LeftUpLeg", "mixamorig_RightUpLeg",
				"mixamorig_LeftLeg", "mixamorig_RightLeg",
				"mixamorig_LeftFoot", "mixamorig_RightFoot",
				"mixamorig_Hips", "mixamorig_Spine", "mixamorig_Spine1",
				"mixamorig_LeftArm", "mixamorig_RightArm",
				"mixamorig_LeftForeArm", "mixamorig_RightForeArm"
			]
			var rot_tracks: Dictionary = {}
			for bname in tracked_bones:
				if _bone_rest_quats.has(bname):
					var tidx := anim.add_track(Animation.TYPE_ROTATION_3D)
					anim.track_set_path(tidx, NodePath(skel_path + ":" + bname))
					rot_tracks[bname] = tidx
			var pos_tidx := anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(pos_tidx, NodePath(skel_path + ":mixamorig_Hips"))
			for s in range(sample_count + 1):
				var t_norm := float(s) / float(sample_count)
				var phase := t_norm * TAU
				var l_swing := sin(phase)
				var r_swing := sin(phase + PI)
				var l_knee := maxf(0.0, cos(phase - 0.35))
				var r_knee := maxf(0.0, cos(phase + PI - 0.35))
				if rot_tracks.has("mixamorig_LeftUpLeg"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_LeftUpLeg"], t_norm, _bone_rest_quats["mixamorig_LeftUpLeg"] * Quaternion(Vector3.RIGHT, l_swing * deg_to_rad(38.0)))
				if rot_tracks.has("mixamorig_RightUpLeg"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_RightUpLeg"], t_norm, _bone_rest_quats["mixamorig_RightUpLeg"] * Quaternion(Vector3.RIGHT, r_swing * deg_to_rad(38.0)))
				if rot_tracks.has("mixamorig_LeftLeg"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_LeftLeg"], t_norm, _bone_rest_quats["mixamorig_LeftLeg"] * Quaternion(Vector3.RIGHT, -deg_to_rad(12.0 + 42.0 * l_knee)))
				if rot_tracks.has("mixamorig_RightLeg"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_RightLeg"], t_norm, _bone_rest_quats["mixamorig_RightLeg"] * Quaternion(Vector3.RIGHT, -deg_to_rad(12.0 + 42.0 * r_knee)))
				if rot_tracks.has("mixamorig_LeftFoot"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_LeftFoot"], t_norm, _bone_rest_quats["mixamorig_LeftFoot"] * Quaternion(Vector3.RIGHT, deg_to_rad(10.0 * l_knee - 14.0 * l_swing)))
				if rot_tracks.has("mixamorig_RightFoot"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_RightFoot"], t_norm, _bone_rest_quats["mixamorig_RightFoot"] * Quaternion(Vector3.RIGHT, deg_to_rad(10.0 * r_knee - 14.0 * r_swing)))
				if rot_tracks.has("mixamorig_Hips"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_Hips"], t_norm, _bone_rest_quats["mixamorig_Hips"] * Quaternion(Vector3.UP, l_swing * deg_to_rad(8.0)) * Quaternion(Vector3.BACK, l_swing * deg_to_rad(4.0)))
				if rot_tracks.has("mixamorig_Spine"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_Spine"], t_norm, _bone_rest_quats["mixamorig_Spine"] * Quaternion(Vector3.RIGHT, deg_to_rad(10.0)) * Quaternion(Vector3.UP, -l_swing * deg_to_rad(5.0)))
				if rot_tracks.has("mixamorig_Spine1"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_Spine1"], t_norm, _bone_rest_quats["mixamorig_Spine1"] * Quaternion(Vector3.RIGHT, deg_to_rad(8.0)))
				if rot_tracks.has("mixamorig_LeftArm"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_LeftArm"], t_norm, _bone_rest_quats["mixamorig_LeftArm"] * Quaternion(Vector3.RIGHT, deg_to_rad(22.0) - l_swing * deg_to_rad(28.0)))
				if rot_tracks.has("mixamorig_RightArm"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_RightArm"], t_norm, _bone_rest_quats["mixamorig_RightArm"] * Quaternion(Vector3.RIGHT, deg_to_rad(22.0) - r_swing * deg_to_rad(28.0)))
				if rot_tracks.has("mixamorig_LeftForeArm"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_LeftForeArm"], t_norm, _bone_rest_quats["mixamorig_LeftForeArm"] * Quaternion(Vector3.RIGHT, deg_to_rad(28.0)))
				if rot_tracks.has("mixamorig_RightForeArm"):
					anim.rotation_track_insert_key(rot_tracks["mixamorig_RightForeArm"], t_norm, _bone_rest_quats["mixamorig_RightForeArm"] * Quaternion(Vector3.RIGHT, deg_to_rad(28.0)))
				var step_bob := (absf(sin(phase)) - 0.5) * 0.08
				var hip_sway := cos(phase) * 0.035
				anim.position_track_insert_key(pos_tidx, t_norm, _hips_rest_origin + Vector3(hip_sway, step_bob - 0.04, 0.0))

func _set_bone_rot_offset(bone_name: String, local_offset: Quaternion) -> void:
	if _skeleton == null or not _bone_indices.has(bone_name) or not _bone_rest_quats.has(bone_name):
		return
	var idx: int = _bone_indices[bone_name]
	var rest_q: Quaternion = _bone_rest_quats[bone_name]
	_skeleton.set_bone_pose_rotation(idx, rest_q * local_offset)

func _update_bipedal_walk_cycle(delta: float) -> void:
	if _skeleton == null or current_state == State.DORMANT or current_state == State.ELIMINATED:
		return
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if current_state == State.HORROR_ZOOM:
		horiz_speed = walk_speed * 2.2
	elif current_state == State.SPAWNING:
		horiz_speed = walk_speed * 0.65
	var is_moving := horiz_speed > 0.12
	var target_blend := clampf(horiz_speed / maxf(0.5, walk_speed), 0.25 if is_moving else 0.0, 1.45)
	_stride_blend = move_toward(_stride_blend, target_blend, delta * 6.0)
	if is_moving:
		_walk_cycle_phase = fmod(_walk_cycle_phase + delta * maxf(3.2, horiz_speed * 2.85), TAU)
	
	# Let native C++ AnimationPlayer drive the multi-track bipedal walk cycle in real time without double-dirtying Skeleton3D!
	if _anim_player != null and _anim_player.has_animation("Armature|Armature|mixamo_com|Layer0"):
		if is_moving:
			_anim_player.speed_scale = clampf(horiz_speed / maxf(0.5, walk_speed), 0.65, 2.2)
			if not _anim_player.is_playing():
				_anim_player.play("Armature|Armature|mixamo_com|Layer0")
		else:
			_anim_player.speed_scale = 0.25
		return
	
	var l_swing := sin(_walk_cycle_phase) * _stride_blend
	var r_swing := sin(_walk_cycle_phase + PI) * _stride_blend
	var l_knee_lift := maxf(0.0, cos(_walk_cycle_phase - 0.35)) * _stride_blend
	var r_knee_lift := maxf(0.0, cos(_walk_cycle_phase + PI - 0.35)) * _stride_blend
	
	# 1. Bipedal Thighs (LeftUpLeg & RightUpLeg swing forward/backward in opposite phase)
	_set_bone_rot_offset("mixamorig_LeftUpLeg", Quaternion(Vector3.RIGHT, l_swing * deg_to_rad(38.0)))
	_set_bone_rot_offset("mixamorig_RightUpLeg", Quaternion(Vector3.RIGHT, r_swing * deg_to_rad(38.0)))
	
	# 2. Knees (LeftLeg & RightLeg bend backward when lifting forward, straighten on plant)
	_set_bone_rot_offset("mixamorig_LeftLeg", Quaternion(Vector3.RIGHT, -deg_to_rad(12.0 + 42.0 * l_knee_lift)))
	_set_bone_rot_offset("mixamorig_RightLeg", Quaternion(Vector3.RIGHT, -deg_to_rad(12.0 + 42.0 * r_knee_lift)))
	
	# 3. Feet & Toes (LeftFoot & RightFoot flex with the stride)
	_set_bone_rot_offset("mixamorig_LeftFoot", Quaternion(Vector3.RIGHT, deg_to_rad(10.0 * l_knee_lift - 14.0 * l_swing)))
	_set_bone_rot_offset("mixamorig_RightFoot", Quaternion(Vector3.RIGHT, deg_to_rad(10.0 * r_knee_lift - 14.0 * r_swing)))
	
	# 4. Hips (vertical step bobbing + lateral weight shift + pelvis yaw twist)
	if _bone_indices.has("mixamorig_Hips"):
		var step_bob := (absf(sin(_walk_cycle_phase)) - 0.5) * 0.08 * minf(1.0, _stride_blend)
		var hip_sway := cos(_walk_cycle_phase) * 0.035 * minf(1.0, _stride_blend)
		_skeleton.set_bone_pose_position(_bone_indices["mixamorig_Hips"], _hips_rest_origin + Vector3(hip_sway, step_bob - 0.04, 0.0))
		_set_bone_rot_offset("mixamorig_Hips", Quaternion(Vector3.UP, l_swing * deg_to_rad(8.0)) * Quaternion(Vector3.BACK, l_swing * deg_to_rad(4.0)))
	
	# 5. Predatory Spine & Head Hunch
	_set_bone_rot_offset("mixamorig_Spine", Quaternion(Vector3.RIGHT, deg_to_rad(10.0)) * Quaternion(Vector3.UP, -l_swing * deg_to_rad(5.0)))
	_set_bone_rot_offset("mixamorig_Spine1", Quaternion(Vector3.RIGHT, deg_to_rad(8.0)))
	_set_bone_rot_offset("mixamorig_Neck", Quaternion(Vector3.RIGHT, deg_to_rad(-8.0)))
	_set_bone_rot_offset("mixamorig_Head", Quaternion(Vector3.RIGHT, deg_to_rad(-6.0)) * Quaternion(Vector3.UP, sin(_bob_timer * 1.4) * deg_to_rad(6.0)))
	
	# 6. Arms & Forearms (counter-swing with legs, or slash forward during claw attack)
	var slash_boost := deg_to_rad(42.0) if _attack_cooldown > 0.8 else 0.0
	_set_bone_rot_offset("mixamorig_LeftArm", Quaternion(Vector3.RIGHT, deg_to_rad(22.0) + slash_boost - l_swing * deg_to_rad(28.0)))
	_set_bone_rot_offset("mixamorig_RightArm", Quaternion(Vector3.RIGHT, deg_to_rad(22.0) + slash_boost - r_swing * deg_to_rad(28.0)))
	_set_bone_rot_offset("mixamorig_LeftForeArm", Quaternion(Vector3.RIGHT, deg_to_rad(28.0) + slash_boost * 0.5))
	_set_bone_rot_offset("mixamorig_RightForeArm", Quaternion(Vector3.RIGHT, deg_to_rad(28.0) + slash_boost * 0.5))

func _update_animation_effects(_delta: float) -> void:
	if current_state == State.ELIMINATED:
		if eye_left_light != null:
			eye_left_light.light_energy = 0.0
		if eye_right_light != null:
			eye_right_light.light_energy = 0.0
		if aura_light != null:
			aura_light.light_energy = 0.0
		return
	
	# Sinister pulsing crimson eye glow (blazing bright during jumpscare)
	var is_jumpscaring := (current_state == State.HORROR_ZOOM or _face_thrash_timer > 0.0)
	var eye_energy := (5.5 + sin(_pulse_timer * 8.0) * 2.0) if is_jumpscaring else (2.0 + sin(_pulse_timer) * 0.8)
	if eye_left_light != null:
		eye_left_light.light_energy = eye_energy
	if eye_right_light != null:
		eye_right_light.light_energy = eye_energy
	
	if aura_light != null:
		aura_light.light_energy = (3.2 + sin(_pulse_timer * 6.0) * 1.2) if is_jumpscaring else (1.0 + sin(_pulse_timer * 0.5) * 0.4)
	
	# Hotel Shrek 1 / Five Nights at Doraemon's style Alien Face Rapid Zoom-In / Zoom-Out Thrash
	if is_jumpscaring:
		var thrash_wave := sin(_pulse_timer * 11.0)
		var face_scale := 1.18 + 0.24 * thrash_wave
		if head != null:
			head.scale = Vector3(face_scale, face_scale, face_scale)
			head.rotation.z = sin(_pulse_timer * 15.0) * 0.28
		if alien_model != null:
			alien_model.position.z = thrash_wave * 0.26
			alien_model.rotation.z = cos(_pulse_timer * 14.0) * 0.12
	else:
		if head != null:
			head.scale = Vector3.ONE
			head.rotation.z = 0.0
		if alien_model != null:
			alien_model.position.z = 0.0
			alien_model.rotation.z = 0.0
	
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
