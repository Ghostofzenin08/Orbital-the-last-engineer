class_name ShipInteriorLevel
extends Node3D

# Ship Interior Level Controller for ORBITAL: The Last Engineer
# Milestone 4: Coordinates 11-compartment 3D geometry, lighting themes, doors, airlocks, and hazard simulation.

@onready var player: PlayerController = $Player
@onready var env_manager: Node = $EnvironmentalManager

# Lighting groups for all 11 compartments
@onready var engineering_lights: Node3D = $Compartments/EngineeringBay/Lights
@onready var corridor_lights: Node3D = $Compartments/Corridors/Lights
@onready var life_support_lights: Node3D = $Compartments/LifeSupport/Lights
@onready var bridge_lights: Node3D = $Compartments/Bridge/Lights
@onready var avionics_lights: Node3D = get_node_or_null("Compartments/AvionicsBay/Lights")
@onready var crew_lights: Node3D = get_node_or_null("Compartments/CrewQuarters/Lights")
@onready var medbay_lights: Node3D = get_node_or_null("Compartments/Medbay/Lights")
@onready var cargo_lights: Node3D = get_node_or_null("Compartments/CargoBay/Lights")
@onready var airlock_lights: Node3D = get_node_or_null("Compartments/AirlockChamber/Lights")
@onready var subdeck_lights: Node3D = get_node_or_null("Compartments/ReactorSubdeck/Lights")
@onready var crawlway_lights: Node3D = get_node_or_null("Compartments/MaintenanceCrawlway/Lights")
@onready var specimen_lights: Node3D = get_node_or_null("Compartments/SpecimenVault/Lights")
@onready var observatory_lights: Node3D = get_node_or_null("Compartments/ResearchObservatory/Lights")
@onready var alien_stalker: Node = get_node_or_null("Compartments/SpecimenVault/AlienStalker")

# Doors
@onready var door_eng_to_ls: BulkheadDoor = $Compartments/Corridors/DoorAft
@onready var door_ls_to_bridge: BulkheadDoor = $Compartments/Corridors/DoorForward

var _crawlway_flash_timer: float = 0.0
var _suspense_timer: float = 0.0
var _suspense_interval: float = 18.0
var _scifi_normal_tex: NoiseTexture2D = null
var _scifi_roughness_tex: NoiseTexture2D = null
var _objective_beacon: Node3D = null
var _beacon_pulse_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Apply sci-fi procedural surface textures, horror WorldEnvironment, and observatory/secret chamber props
	_apply_scifi_horror_textures_and_environment()
	_populate_story_observatory_and_vault_props()
	
	# Start eerie background horror ambience upon docking at the messed-up research facility
	if AudioManager != null and AudioManager.has_method("play_background_horror"):
		var cur_scene := get_tree().current_scene if get_tree() != null else null
		if cur_scene == null or not cur_scene.scene_file_path.contains("test_runner"):
			AudioManager.play_background_horror()
	
	# Connect environment manager to HUD and player
	if player != null and env_manager != null:
		if player.hud != null:
			env_manager.oxygen_level_changed.connect(player.hud.update_oxygen)
			if env_manager.has_signal("player_status_updated") and player.hud.has_method("update_player_status"):
				env_manager.player_status_updated.connect(player.hud.update_player_status)
		if env_manager.has_signal("player_status_updated") and player.has_method("apply_environmental_afflictions"):
			env_manager.player_status_updated.connect(func(afflictions, _telem):
				player.apply_environmental_afflictions(afflictions)
			)
		var pause_menu: PauseMenu = player.hud.get_node_or_null("PauseMenu") if player.hud != null else null
		if pause_menu != null:
			pause_menu.set_player_reference(player)
	
	ShipSystemManager.system_state_changed.connect(_on_system_state_changed)
	
	# Handle pending load if triggered from Main Menu or Game Over
	if SaveManager.has_meta("pending_load"):
		SaveManager.remove_meta("pending_load")
		SaveManager.load_game(player, env_manager)
	
	# Initialize in-game diagnostic tutorial
	if player != null:
		var tut = DiagnosticTutorial.new()
		tut.setup_in_game(self, player)
	
	# Milestone 7: Connect AlienStalker to ShipState CrisisManager and player
	if alien_stalker != null and ShipState != null and ShipState.crisis_manager != null:
		ShipState.crisis_manager.register_stalker(alien_stalker)
	
	# Milestone 6 & 7: Check and trigger creature hunt crisis only when all repairs are complete
	if not MissionManager.objective_completed.is_connected(_on_objective_completed):
		MissionManager.objective_completed.connect(_on_objective_completed)
	if not MissionManager.room_discovered.is_connected(_on_room_discovered):
		MissionManager.room_discovered.connect(_on_room_discovered)
	
	_refresh_environment_lighting()
	_setup_objective_beacon()
	_update_objective_beacon_and_wayfinder(0.0)

func _exit_tree() -> void:
	if MissionManager != null:
		if MissionManager.objective_completed.is_connected(_on_objective_completed):
			MissionManager.objective_completed.disconnect(_on_objective_completed)
		if MissionManager.room_discovered.is_connected(_on_room_discovered):
			MissionManager.room_discovered.disconnect(_on_room_discovered)

func _on_objective_completed(_idx: int, _title: String) -> void:
	# Psychological suspense: mysterious angry animal/alien sounds echo in the vents as each chamber repair step completes
	trigger_psychological_suspense_pulse("repair_step_%d" % _idx)
	if _idx >= 3 or MissionManager.are_all_repairs_complete():
		# Simplify alien attack trigger workflow: completing the 4 station repairs (Bridge Comms)
		# automatically satisfies the chamber discovery gate so the alien awakens immediately
		# without forcing the player to hunt for a 5th hidden room.
		for room_id in ["engineering_bay", "corridors", "life_support", "bridge", "specimen_vault"]:
			if not MissionManager.is_room_discovered(room_id):
				MissionManager.discovered_rooms[room_id] = true
		_check_trigger_final_hunt()

func _on_room_discovered(_room_id: String, _room_name: String) -> void:
	if _room_id == "specimen_vault" or _room_id == "research_observatory" or _room_id == "crew_quarters":
		trigger_psychological_suspense_pulse(_room_id)
	if MissionManager.are_all_repairs_complete():
		_check_trigger_final_hunt()

func trigger_psychological_suspense_pulse(context_tag: String = "ambient") -> void:
	if ShipState != null and ShipState.crisis_manager != null and ShipState.crisis_manager.is_creature_eliminated:
		return
	if AudioManager != null:
		AudioManager.play_creature_sound()
		if context_tag.begins_with("repair_step_") or context_tag == "specimen_vault":
			AudioManager.play_heartbeat_rapid()
	if player != null and is_instance_valid(player):
		if "camera_trauma" in player:
			player.camera_trauma = maxf(float(player.camera_trauma), 0.22)
	_flicker_lights_for_encounter()

func _check_trigger_final_hunt() -> void:
	if ShipState == null or ShipState.crisis_manager == null:
		return
	if ShipState.crisis_manager.current_crisis == CrisisManager.CrisisType.CREATURE_PREDATORY_HUNT or ShipState.crisis_manager.is_creature_eliminated:
		return
	# Alien only appears when ALL spaceship repairs are complete
	if not MissionManager.are_all_repairs_complete():
		return
	if MissionManager.can_engage_final_hunt():
		trigger_creature_horror_encounter()

func trigger_creature_horror_encounter() -> void:
	if ShipState == null or ShipState.crisis_manager == null:
		return
	ShipState.start_crisis(CrisisManager.CrisisType.CREATURE_PREDATORY_HUNT)
	_flicker_lights_for_encounter()
	
	# Alert player with rumbling seismic hull vibrations and horror audio
	if player != null and player.has_method("trigger_vibration_alert"):
		player.trigger_vibration_alert(4.0, 0.7)
	if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
		player.hud.show_notification("ALIEN AWAKENED BY RESTORED STATION POWER! Run to the Airlock Chamber (East off Central Corridor) and turn the Red Poison Gas Valve!", 6.0)
	
	if AudioManager != null:
		if AudioManager.has_method("play_background_horror"):
			AudioManager.play_background_horror()
		AudioManager.play_horror_zoom()
		AudioManager.play_creature_sound()
	
	# Stalker slowly awakens and emerges in the deep lower deck rather than instant jumpscare
	if alien_stalker != null:
		alien_stalker.target_player = player
		alien_stalker.spawn_in_chamber("specimen_vault", Vector3(0, -2, 38))
		if is_inside_tree() and get_tree() != null:
			get_tree().create_timer(3.5).timeout.connect(func():
				if is_instance_valid(alien_stalker) and alien_stalker.current_state == AlienStalker.State.SPAWNING:
					alien_stalker.set_state(AlienStalker.State.STALKING)
					if AudioManager != null:
						AudioManager.play_boss_screech()
			)

func _flicker_lights_for_encounter() -> void:
	# Dramatic horror light flicker across station
	var lights_to_flicker: Array[Node3D] = [
		bridge_lights, corridor_lights, engineering_lights, life_support_lights
	]
	for grp in lights_to_flicker:
		if grp != null:
			for light in grp.get_children():
				if light is Light3D:
					var orig_energy: float = light.light_energy
					light.light_energy = 0.1
					get_tree().create_timer(0.2).timeout.connect(func():
						if is_instance_valid(light):
							light.light_energy = orig_energy * 0.4
					)
					get_tree().create_timer(0.5).timeout.connect(func():
						if is_instance_valid(light):
							light.light_energy = 0.05
					)
					get_tree().create_timer(1.0).timeout.connect(func():
						if is_instance_valid(light):
							light.light_energy = orig_energy
					)

func _process(delta: float) -> void:
	# Flashing red hazard beacons in breached crawlway
	if crawlway_lights != null:
		_crawlway_flash_timer += delta * 4.0
		var energy: float = 0.3 + sin(_crawlway_flash_timer) * 0.7
		for light in crawlway_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_energy = maxf(0.1, energy)
	
	# Psychological suspense: periodic distant animal/alien growls & vent scratching while fixing the station
	var creature_alive: bool = (ShipState == null or ShipState.crisis_manager == null or not ShipState.crisis_manager.is_creature_eliminated)
	if creature_alive:
		_suspense_timer += delta
		if _suspense_timer >= _suspense_interval:
			_suspense_timer = 0.0
			_suspense_interval = randf_range(16.0, 26.0)
			trigger_psychological_suspense_pulse("periodic_stalking")
	
	_update_objective_beacon_and_wayfinder(delta)

func _setup_objective_beacon() -> void:
	if _objective_beacon != null and is_instance_valid(_objective_beacon):
		return
	_objective_beacon = Node3D.new()
	_objective_beacon.name = "ObjectiveBeacon3D"
	
	var beacon_mat := StandardMaterial3D.new()
	beacon_mat.albedo_color = Color(0.15, 1.0, 0.65, 0.72)
	beacon_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beacon_mat.emission_enabled = true
	beacon_mat.emission = Color(0.2, 1.0, 0.7, 1.0)
	beacon_mat.emission_energy_multiplier = 3.2
	
	# Glowing vertical holographic guide beam
	var beam_mesh := MeshInstance3D.new()
	beam_mesh.name = "BeaconBeam"
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 0.06
	bcyl.bottom_radius = 0.14
	bcyl.height = 1.6
	beam_mesh.mesh = bcyl
	beam_mesh.position = Vector3(0.0, 0.8, 0.0)
	beam_mesh.set_surface_override_material(0, beacon_mat)
	_objective_beacon.add_child(beam_mesh)
	
	# Glowing target Halo ring
	var ring_mesh := MeshInstance3D.new()
	ring_mesh.name = "BeaconRing"
	var torus := CylinderMesh.new()
	torus.top_radius = 0.36
	torus.bottom_radius = 0.36
	torus.height = 0.06
	ring_mesh.mesh = torus
	ring_mesh.position = Vector3(0.0, 0.05, 0.0)
	ring_mesh.set_surface_override_material(0, beacon_mat)
	_objective_beacon.add_child(ring_mesh)
	
	var beacon_light := OmniLight3D.new()
	beacon_light.name = "BeaconLight"
	beacon_light.light_color = Color(0.2, 1.0, 0.68, 1.0)
	beacon_light.light_energy = 1.8
	beacon_light.omni_range = 4.5
	beacon_light.position = Vector3(0.0, 0.4, 0.0)
	_objective_beacon.add_child(beacon_light)
	
	add_child(_objective_beacon)

func get_current_objective_target_info() -> Dictionary:
	var idx: int = MissionManager.current_objective_index if MissionManager != null else 0
	match idx:
		0:
			return {
				"node": get_node_or_null("Compartments/EngineeringBay/GeneratorBreaker"),
				"name": "Generator Breaker Lever (Front of Cylinder)"
			}
		1:
			return {
				"node": get_node_or_null("Compartments/EngineeringBay/BusBreaker"),
				"name": "Main Power Bus Switch (Left Wall)"
			}
		2:
			var pickup := get_node_or_null("Compartments/EngineeringBay/SpareCouplerPickup")
			if pickup != null and is_instance_valid(pickup) and not MissionManager.has_item("coolant_coupler"):
				return {
					"node": pickup,
					"name": "Spare Coolant Coupler (Engineering Table)"
				}
			return {
				"node": get_node_or_null("Compartments/LifeSupport/CoolantRepairPanel"),
				"name": "Life Support Repair Panel (North Room)"
			}
		3:
			return {
				"node": get_node_or_null("Compartments/Bridge/BridgeCommsTerminal"),
				"name": "Bridge Comms Terminal (Far North Room)"
			}
		4:
			if ShipState != null and ShipState.crisis_manager != null and ShipState.crisis_manager.is_creature_eliminated:
				return {
					"node": get_node_or_null("Compartments/Bridge/DepartureSwitch"),
					"name": "Orbital Departure Switch (Command Bridge Helm)"
				}
			return {
				"node": get_node_or_null("Compartments/AirlockChamber/DecontaminationPoisonGasValve"),
				"name": "Red Poison Gas Valve (East Airlock Chamber)"
			}
	return {"node": null, "name": ""}

func _update_objective_beacon_and_wayfinder(delta: float) -> void:
	_beacon_pulse_time += delta * 4.5
	var info := get_current_objective_target_info()
	var target_node: Node3D = info.get("node", null) as Node3D
	var target_name: String = str(info.get("name", ""))
	
	if _objective_beacon != null and is_instance_valid(_objective_beacon):
		if target_node != null and is_instance_valid(target_node):
			_objective_beacon.visible = true
			_objective_beacon.global_position = target_node.global_position + Vector3(0.0, 0.45 + sin(_beacon_pulse_time) * 0.12, 0.0)
			_objective_beacon.rotation.y += delta * 2.2
		else:
			_objective_beacon.visible = false
	
	if player != null and is_instance_valid(player) and "hud" in player and player.hud != null and player.hud.has_method("update_wayfinder"):
		if target_node != null and is_instance_valid(target_node):
			var dist := player.global_position.distance_to(target_node.global_position)
			var to_target := target_node.global_position - player.global_position
			to_target.y = 0.0
			var dir_hint := "STRAIGHT AHEAD ▲"
			if to_target.length() > 0.2:
				to_target = to_target.normalized()
				var fwd := -player.global_transform.basis.z
				fwd.y = 0.0
				fwd = fwd.normalized()
				var right := player.global_transform.basis.x
				right.y = 0.0
				right = right.normalized()
				var forward_dot := fwd.dot(to_target)
				var right_dot := right.dot(to_target)
				if forward_dot >= 0.72:
					dir_hint = "STRAIGHT AHEAD ▲"
				elif forward_dot <= -0.55:
					dir_hint = "BEHIND YOU — TURN AROUND ▼"
				elif right_dot > 0.0:
					dir_hint = "TURN RIGHT ►" if forward_dot < 0.25 else "SLIGHT RIGHT ↗"
				else:
					dir_hint = "TURN LEFT ◄" if forward_dot < 0.25 else "SLIGHT LEFT ↖"
			player.hud.update_wayfinder(target_name, dist, dir_hint)
		else:
			player.hud.update_wayfinder("", 0.0, "")

func _apply_scifi_horror_textures_and_environment() -> void:
	# 1. Configure sleek, moody, high-contrast Bio-Research Facility WorldEnvironment (no white blowout)
	if get_node_or_null("HorrorWorldEnvironment") == null:
		var world_env := WorldEnvironment.new()
		world_env.name = "HorrorWorldEnvironment"
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.01, 0.02, 0.04, 1.0)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.14, 0.20, 0.28, 1.0)
		env.ambient_light_energy = 0.22
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 0.90
		env.glow_enabled = true
		env.glow_intensity = 0.22
		env.glow_bloom = 0.03
		env.fog_enabled = true
		env.fog_light_color = Color(0.05, 0.09, 0.14, 1.0)
		env.fog_light_energy = 0.22
		env.fog_density = 0.006
		world_env.environment = env
		add_child(world_env)
	
	# 2. Generate ultra-clean, micro-polished architectural surface textures for cleanroom panels & lab floors
	var normal_noise := FastNoiseLite.new()
	normal_noise.seed = 442
	normal_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	normal_noise.frequency = 0.04
	normal_noise.cellular_distance_function = FastNoiseLite.DISTANCE_MANHATTAN
	
	_scifi_normal_tex = NoiseTexture2D.new()
	_scifi_normal_tex.width = 128
	_scifi_normal_tex.height = 128
	_scifi_normal_tex.seamless = true
	_scifi_normal_tex.as_normal_map = true
	_scifi_normal_tex.bump_strength = 1.0
	_scifi_normal_tex.noise = normal_noise
	
	var rough_noise := FastNoiseLite.new()
	rough_noise.seed = 2184
	rough_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	rough_noise.frequency = 0.025
	
	_scifi_roughness_tex = NoiseTexture2D.new()
	_scifi_roughness_tex.width = 128
	_scifi_roughness_tex.height = 128
	_scifi_roughness_tex.seamless = true
	_scifi_roughness_tex.noise = rough_noise
	
	var compartments_root := get_node_or_null("Compartments")
	if compartments_root == null:
		return
	var updated_materials: Dictionary = {}
	for mesh_inst in compartments_root.find_children("*", "MeshInstance3D", true, false):
		if mesh_inst is MeshInstance3D:
			var mat: Material = mesh_inst.get_surface_override_material(0)
			if mat == null and mesh_inst.mesh != null and mesh_inst.mesh.get_surface_count() > 0:
				mat = mesh_inst.mesh.surface_get_material(0)
			if mat is StandardMaterial3D and not updated_materials.has(mat):
				updated_materials[mat] = true
				var smat: StandardMaterial3D = mat as StandardMaterial3D
				if smat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and not smat.emission_enabled:
					smat.normal_enabled = true
					smat.normal_texture = _scifi_normal_tex
					smat.normal_scale = 0.05
					smat.clearcoat_enabled = true
					smat.clearcoat = 0.45
					smat.clearcoat_roughness = 0.14
					smat.uv1_triplanar = true
					smat.uv1_world_triplanar = true
					smat.uv1_scale = Vector3(0.25, 0.25, 0.25)

func _populate_story_observatory_and_vault_props() -> void:
	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = Color(0.88, 0.92, 0.96, 1.0)
	trim_mat.metallic = 0.35
	trim_mat.roughness = 0.14
	trim_mat.clearcoat_enabled = true
	trim_mat.clearcoat = 0.7
	trim_mat.clearcoat_roughness = 0.1
	
	var led_cyan_mat := StandardMaterial3D.new()
	led_cyan_mat.albedo_color = Color(0.75, 0.96, 1.0, 1.0)
	led_cyan_mat.emission_enabled = true
	led_cyan_mat.emission = Color(0.45, 0.92, 1.0, 1.0)
	led_cyan_mat.emission_energy_multiplier = 2.2
	
	var led_bio_mat := StandardMaterial3D.new()
	led_bio_mat.albedo_color = Color(0.65, 1.0, 0.85, 1.0)
	led_bio_mat.emission_enabled = true
	led_bio_mat.emission = Color(0.25, 0.95, 0.72, 1.0)
	led_bio_mat.emission_energy_multiplier = 2.0
	
	# Minimalist Recessed Cleanroom LED Ceiling Trim Strips across core Bio-Research Chambers
	var strip_configs: Array[Dictionary] = [
		{"path": "Compartments/EngineeringBay", "pos": Vector3(0.0, 3.35, 16.0), "size": Vector3(6.4, 0.05, 0.18), "mat": led_cyan_mat},
		{"path": "Compartments/Corridors", "pos": Vector3(0.0, 3.35, 8.0), "size": Vector3(0.18, 0.05, 5.2), "mat": led_cyan_mat},
		{"path": "Compartments/LifeSupport", "pos": Vector3(0.0, 3.35, 0.0), "size": Vector3(6.4, 0.05, 0.18), "mat": led_bio_mat},
		{"path": "Compartments/Bridge", "pos": Vector3(0.0, 3.35, -16.0), "size": Vector3(6.4, 0.05, 0.18), "mat": led_cyan_mat},
		{"path": "Compartments/Medbay", "pos": Vector3(9.0, 3.35, -8.0), "size": Vector3(5.2, 0.05, 0.18), "mat": led_bio_mat},
		{"path": "Compartments/ResearchObservatory", "pos": Vector3(-15.0, 3.35, -20.0), "size": Vector3(0.18, 0.05, 6.4), "mat": led_bio_mat}
	]
	for cfg in strip_configs:
		var comp_node := get_node_or_null(str(cfg["path"]))
		if comp_node != null and comp_node.get_node_or_null("BioLabCeilingStrip") == null:
			var strip := MeshInstance3D.new()
			strip.name = "BioLabCeilingStrip"
			var sbox := BoxMesh.new()
			sbox.size = cfg["size"]
			strip.mesh = sbox
			strip.position = cfg["pos"]
			strip.set_surface_override_material(0, cfg["mat"])
			comp_node.add_child(strip)
	
	# 1. Bio-Research Observatory: Polished Glass Hydroponic Flora & Zoological Bio-Chambers + Minimalist Analysis Island
	var obs_node := get_node_or_null("Compartments/ResearchObservatory")
	if obs_node != null and obs_node.get_node_or_null("BotanicalFloraPod") == null:
		var flora_mat := StandardMaterial3D.new()
		flora_mat.albedo_color = Color(0.22, 0.85, 0.58, 0.42)
		flora_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flora_mat.metallic = 0.25
		flora_mat.roughness = 0.06
		flora_mat.emission_enabled = true
		flora_mat.emission = Color(0.18, 0.92, 0.62, 1.0)
		flora_mat.emission_energy_multiplier = 1.25
		
		var flora_pod := MeshInstance3D.new()
		flora_pod.name = "BotanicalFloraPod"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.78
		cyl.bottom_radius = 0.78
		cyl.height = 2.3
		flora_pod.mesh = cyl
		flora_pod.position = Vector3(-16.5, 1.15, -18.0)
		flora_pod.set_surface_override_material(0, flora_mat)
		
		# Polished white-silver cleanroom pedestal & cap ring for BotanicalFloraPod
		var ped_mesh := CylinderMesh.new()
		ped_mesh.top_radius = 0.88
		ped_mesh.bottom_radius = 0.92
		ped_mesh.height = 0.18
		var flora_base := MeshInstance3D.new()
		flora_base.name = "CleanroomPedestalBase"
		flora_base.mesh = ped_mesh
		flora_base.position = Vector3(0.0, -1.1, 0.0)
		flora_base.set_surface_override_material(0, trim_mat)
		flora_pod.add_child(flora_base)
		
		var flora_cap := MeshInstance3D.new()
		flora_cap.name = "CleanroomPedestalCap"
		flora_cap.mesh = ped_mesh
		flora_cap.position = Vector3(0.0, 1.1, 0.0)
		flora_cap.set_surface_override_material(0, trim_mat)
		flora_pod.add_child(flora_cap)
		obs_node.add_child(flora_pod)
		
		var fauna_mat := StandardMaterial3D.new()
		fauna_mat.albedo_color = Color(0.25, 0.78, 0.96, 0.40)
		fauna_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fauna_mat.metallic = 0.25
		fauna_mat.roughness = 0.06
		fauna_mat.emission_enabled = true
		fauna_mat.emission = Color(0.22, 0.82, 1.0, 1.0)
		fauna_mat.emission_energy_multiplier = 1.2
		
		var fauna_pod := MeshInstance3D.new()
		fauna_pod.name = "ZoologicalSpecimenTerrarium"
		var tcyl := CylinderMesh.new()
		tcyl.top_radius = 0.85
		tcyl.bottom_radius = 0.85
		tcyl.height = 2.3
		fauna_pod.mesh = tcyl
		fauna_pod.position = Vector3(-16.5, 1.15, -22.0)
		fauna_pod.set_surface_override_material(0, fauna_mat)
		
		var fauna_base := MeshInstance3D.new()
		fauna_base.name = "CleanroomTerrariumBase"
		fauna_base.mesh = ped_mesh
		fauna_base.position = Vector3(0.0, -1.1, 0.0)
		fauna_base.set_surface_override_material(0, trim_mat)
		fauna_pod.add_child(fauna_base)
		
		var fauna_cap := MeshInstance3D.new()
		fauna_cap.name = "CleanroomTerrariumCap"
		fauna_cap.mesh = ped_mesh
		fauna_cap.position = Vector3(0.0, 1.1, 0.0)
		fauna_cap.set_surface_override_material(0, trim_mat)
		fauna_pod.add_child(fauna_cap)
		obs_node.add_child(fauna_pod)
		
		var island := MeshInstance3D.new()
		island.name = "BioAnalysisIsland"
		var ibox := BoxMesh.new()
		ibox.size = Vector3(1.1, 0.88, 2.6)
		island.mesh = ibox
		island.position = Vector3(-13.8, 0.44, -20.0)
		island.set_surface_override_material(0, trim_mat)
		obs_node.add_child(island)
	
	# 2. Deep Specimen Containment Vault: Clinical Cryo-Breeding Pod & Key-Security Panel
	var vault_node := get_node_or_null("Compartments/SpecimenVault")
	if vault_node != null and vault_node.get_node_or_null("ShatteredSecretIncubator") == null:
		var pod_mat := StandardMaterial3D.new()
		pod_mat.albedo_color = Color(0.85, 0.22, 0.28, 0.55)
		pod_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pod_mat.metallic = 0.45
		pod_mat.roughness = 0.12
		pod_mat.emission_enabled = true
		pod_mat.emission = Color(0.95, 0.18, 0.22, 1.0)
		pod_mat.emission_energy_multiplier = 1.65
		
		var incubator := MeshInstance3D.new()
		incubator.name = "ShatteredSecretIncubator"
		var icyl := CylinderMesh.new()
		icyl.top_radius = 1.0
		icyl.bottom_radius = 1.05
		icyl.height = 2.6
		incubator.mesh = icyl
		incubator.position = Vector3(2.8, -0.9, 40.2)
		incubator.set_surface_override_material(0, pod_mat)
		vault_node.add_child(incubator)
		
		var sec_panel := MeshInstance3D.new()
		sec_panel.name = "SecretChamberKeySecurityPanel"
		var sbox := BoxMesh.new()
		sbox.size = Vector3(0.45, 0.65, 0.12)
		sec_panel.mesh = sbox
		sec_panel.position = Vector3(-2.4, -0.5, 33.3)
		sec_panel.set_surface_override_material(0, trim_mat)
		vault_node.add_child(sec_panel)

func _on_system_state_changed(_sys_id: String, _old_st: int, _new_st: int) -> void:
	_refresh_environment_lighting()
	_update_objective_beacon_and_wayfinder(0.0)
	var all_doors = get_tree().root.find_children("*", "BulkheadDoor", true, false)
	for d in all_doors:
		if d.has_method("_update_power_visuals"):
			d._update_power_visuals()

func _refresh_environment_lighting() -> void:
	var gen_online: bool = ShipSystemManager.is_system_online("primary_power")
	var bus_online: bool = ShipSystemManager.is_system_online("power_distribution")
	var ls_online: bool = ShipSystemManager.is_system_online("life_support")
	var _comms_online: bool = ShipSystemManager.is_system_online("communications")
	
	# Keep WorldEnvironment ambient low-key so walls have rich contrast and shadows instead of washing out white
	var world_env := get_node_or_null("HorrorWorldEnvironment") as WorldEnvironment
	if world_env != null and world_env.environment != null:
		world_env.environment.ambient_light_energy = 0.28 if bus_online else (0.24 if gen_online else 0.18)
	
	# Engineering Lab: Moody amber standby when offline, crisp cool-cyan when online
	if engineering_lights != null:
		for light in engineering_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.72, 0.88, 1.0) if gen_online else Color(0.95, 0.42, 0.18)
				light.light_energy = 0.85 if gen_online else 0.38
	
	# Central Cleanroom Corridors: Atmospheric ice-blue standby when offline, sleek cyan-white when online
	if corridor_lights != null:
		for light in corridor_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.75, 0.90, 1.0) if bus_online else Color(0.35, 0.58, 0.82)
				light.light_energy = 0.80 if bus_online else 0.32
	
	# Life Support Bio-Filtration Lab: Bioluminescent mint when online, dim amber-red when offline
	if life_support_lights != null:
		for light in life_support_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.45, 0.95, 0.78) if ls_online else Color(0.92, 0.38, 0.22)
				light.light_energy = 0.85 if ls_online else 0.36
	
	# Command Bridge: Sleek sapphire-cyan
	if bridge_lights != null:
		for light in bridge_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.58, 0.86, 1.0) if bus_online else Color(0.32, 0.52, 0.78)
				light.light_energy = 0.88 if bus_online else 0.35
	
	# Avionics Telemetry Lab: Deep sapphire
	if avionics_lights != null:
		for light in avionics_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.48, 0.78, 1.0) if bus_online else Color(0.28, 0.45, 0.72)
				light.light_energy = 0.78 if bus_online else 0.30
	
	# Science Team Quarters: Soft warm tungsten
	if crew_lights != null:
		for light in crew_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.92, 0.82, 0.68) if bus_online else Color(0.55, 0.42, 0.35)
				light.light_energy = 0.75 if bus_online else 0.30
	
	# Medbay Cleanroom Sanctuary: Clean surgical cyan-white
	if medbay_lights != null:
		for light in medbay_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.68, 0.94, 0.98) if bus_online else Color(0.38, 0.65, 0.78)
				light.light_energy = 0.88 if bus_online else 0.38
	
	# Cargo & Bio-Supply Staging: Moody industrial amber
	if cargo_lights != null:
		for light in cargo_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.88, 0.76, 0.58) if bus_online else Color(0.58, 0.38, 0.24)
				light.light_energy = 0.75 if bus_online else 0.30
	
	# Airlock Decontamination Chamber: Hazard amber-emerald
	if airlock_lights != null:
		for light in airlock_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.65, 0.92, 0.75) if bus_online else Color(0.85, 0.45, 0.22)
				light.light_energy = 0.82 if bus_online else 0.36
	
	# Reactor Subdeck: Deep reactor cyan-amber
	if subdeck_lights != null:
		for light in subdeck_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.58, 0.82, 0.96) if gen_online else Color(0.75, 0.32, 0.20)
				light.light_energy = 0.78 if gen_online else 0.32
	
	# Crawlway: Crimson diagnostic alert
	if crawlway_lights != null:
		for light in crawlway_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(1.0, 0.25, 0.18)
	
	# Specimen Containment Vault: Eerie crimson-violet bio-containment glow
	if specimen_lights != null:
		for light in specimen_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.78, 0.58, 0.92) if bus_online else Color(0.72, 0.22, 0.32)
				light.light_energy = 0.82 if bus_online else 0.36
	
	# Bio-Research Observatory Dome: Bioluminescent cyan-emerald glow
	if observatory_lights != null:
		for light in observatory_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.38, 0.95, 0.82) if bus_online else Color(0.25, 0.68, 0.62)
				light.light_energy = 0.92 if bus_online else 0.42
