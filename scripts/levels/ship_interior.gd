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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
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
	MissionManager.objective_completed.connect(func(_idx: int, _title: String):
		if MissionManager.are_all_repairs_complete():
			_check_trigger_final_hunt()
	)
	MissionManager.room_discovered.connect(func(_room_id: String, _room_name: String):
		if MissionManager.are_all_repairs_complete():
			_check_trigger_final_hunt()
	)
	
	_refresh_environment_lighting()

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
	
	if AudioManager != null:
		AudioManager.play_horror_zoom()
		AudioManager.play_creature_sound()
	
	# Stalker slowly awakens and emerges in the deep lower deck rather than instant jumpscare
	if alien_stalker != null:
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

func _on_system_state_changed(_sys_id: String, _old_st: int, _new_st: int) -> void:
	_refresh_environment_lighting()
	var all_doors = get_tree().root.find_children("*", "BulkheadDoor", true, false)
	for d in all_doors:
		if d.has_method("_update_power_visuals"):
			d._update_power_visuals()

func _refresh_environment_lighting() -> void:
	var gen_online: bool = ShipSystemManager.is_system_online("primary_power")
	var bus_online: bool = ShipSystemManager.is_system_online("power_distribution")
	var ls_online: bool = ShipSystemManager.is_system_online("life_support")
	var comms_online: bool = ShipSystemManager.is_system_online("communications")
	
	# Engineering lights: Amber if online, dim red if offline
	if engineering_lights != null:
		for light in engineering_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(1.0, 0.75, 0.3) if gen_online else Color(0.9, 0.2, 0.1)
				light.light_energy = 1.2 if gen_online else 0.4
	
	# Corridor lights: Clean white/blue if bus online, dark red flicker if offline
	if corridor_lights != null:
		for light in corridor_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.8, 0.9, 1.0) if bus_online else Color(0.6, 0.1, 0.1)
				light.light_energy = 1.0 if bus_online else 0.2
	
	# Life support lights: Bright green when scrubbers online, emergency red when offline
	if life_support_lights != null:
		for light in life_support_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.2, 0.9, 0.4) if ls_online else Color(0.9, 0.3, 0.1)
				light.light_energy = 1.3 if ls_online else 0.35
	
	# Bridge lights: Command Cyan if powered, dim standby if unpowered
	if bridge_lights != null:
		for light in bridge_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.2, 0.8, 1.0) if bus_online else Color(0.4, 0.1, 0.1)
				light.light_energy = 1.4 if bus_online else 0.25
	
	# Avionics lights: Deep Blue
	if avionics_lights != null:
		for light in avionics_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.1, 0.3, 1.0) if bus_online else Color(0.2, 0.1, 0.3)
				light.light_energy = 1.2 if bus_online else 0.25
	
	# Crew Quarters lights: Warm Amber
	if crew_lights != null:
		for light in crew_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(1.0, 0.8, 0.4) if bus_online else Color(0.4, 0.2, 0.1)
				light.light_energy = 1.1 if bus_online else 0.2
	
	# Medbay lights: Clean White
	if medbay_lights != null:
		for light in medbay_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.95, 0.98, 1.0) if bus_online else Color(0.3, 0.3, 0.4)
				light.light_energy = 1.3 if bus_online else 0.25
	
	# Cargo Bay lights: Industrial Orange
	if cargo_lights != null:
		for light in cargo_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(1.0, 0.6, 0.1) if bus_online else Color(0.5, 0.2, 0.1)
				light.light_energy = 1.2 if bus_online else 0.3
	
	# Airlock lights: Hazard Yellow/Black
	if airlock_lights != null:
		for light in airlock_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(1.0, 0.9, 0.2) if bus_online else Color(0.5, 0.4, 0.1)
				light.light_energy = 1.1 if bus_online else 0.3
	
	# Reactor Subdeck lights: Crimson
	if subdeck_lights != null:
		for light in subdeck_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.9, 0.2, 0.2) if gen_online else Color(0.4, 0.05, 0.05)
				light.light_energy = 1.2 if gen_online else 0.25
	
	# Crawlway lights: Red Hazard (base color)
	if crawlway_lights != null:
		for light in crawlway_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(1.0, 0.1, 0.1)
	
	# Specimen Vault lights: Amber when powered, deep crimson emergency glow when unpowered
	if specimen_lights != null:
		for light in specimen_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(1.0, 0.45, 0.15) if bus_online else Color(0.6, 0.05, 0.05)
				light.light_energy = 1.3 if bus_online else 0.35
	
	# Research Observatory lights: Starlight Cyan when powered, dim standby blue when unpowered
	if observatory_lights != null:
		for light in observatory_lights.get_children():
			if light is OmniLight3D or light is SpotLight3D:
				light.light_color = Color(0.2, 0.85, 1.0) if bus_online else Color(0.1, 0.2, 0.4)
				light.light_energy = 1.4 if bus_online else 0.3
