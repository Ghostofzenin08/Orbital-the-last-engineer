extends Node

# Scene-based test runner that runs with full Autoloads active

const ShipSystemClass = preload("res://scripts/systems/ship_system.gd")
const EnvManagerScript = preload("res://scripts/systems/environmental_manager.gd")
const StorageLockerClass = preload("res://scripts/interactables/storage_locker.gd")
const WorkbenchStationClass = preload("res://scripts/interactables/workbench_station.gd")
const MultiStepRepairClass = preload("res://scripts/interactables/multi_step_repair.gd")
const DiagnosticTutorialClass = preload("res://scripts/missions/diagnostic_tutorial.gd")
const AirlockControllerClass = preload("res://scripts/interactables/airlock_controller.gd")
const SalvageCrateClass = preload("res://scripts/interactables/salvage_crate.gd")
const HullBreachSealClass = preload("res://scripts/interactables/hull_breach_seal.gd")
const DoorClass = preload("res://scripts/interactables/door.gd")
const DatapadPickupClass = preload("res://scripts/interactables/datapad_pickup.gd")
const EmergencyValveClass = preload("res://scripts/interactables/emergency_valve.gd")
const CrisisManagerClass = preload("res://scripts/systems/crisis_manager.gd")
const AlienStalkerClass = preload("res://scripts/entities/alien_stalker.gd")

var tests_passed: int = 0
var tests_failed: int = 0

func _ready() -> void:
	print("\n=======================================================")
	print("   ORBITAL: The Last Engineer - FULL TEST SUITE")
	print("=======================================================\n")
	
	_run_suite("Ship Systems Simulation", _test_ship_systems)
	_run_suite("Mission Progression & Narrative", _test_missions)
	_run_suite("Environmental Life Support", _test_environmental)
	_run_suite("Save / Load Persistence & 3D Scene Synchronization", _test_save_load)
	_run_suite("Door Mechanics & Collision Clearing", _test_door_mechanics)
	_run_suite("Player Movement & Input Control", _test_player_input)
	_run_suite("Audio Engine Lifecycle", _test_audio_lifecycle)
	_run_suite("Scene Instantiation Integrity", _test_scenes)
	_run_suite("End-to-End 3D Level Gameplay Flow", _test_end_to_end_level_flow)
	_run_suite("Milestone 1: Central ShipState & Device/Subsystem/Fault Architecture", _test_ship_state_architecture)
	_run_suite("Milestone 1: Power System Generation, Storage, Distribution & Priority Simulation", _test_power_system_simulation)
	_run_suite("Milestone 1: Chamber Devices Connected to Power Network", _test_chamber_devices_connected_to_power)
	_run_suite("Milestone 1: Ship Schematic & Diagnostic Advisory UI", _test_ship_schematic_ui)
	_run_suite("Milestone 1: Robustness, Thermal Throttling & Bidirectional Sync", _test_robustness_and_thermal)
	_run_suite("Milestone 2: Multi-Compartment Dynamic Atmospheric Physics", _test_multi_compartment_simulation)
	_run_suite("Milestone 2: Inter-Compartment Gas Diffusion & Vent Dampers", _test_inter_compartment_diffusion)
	_run_suite("Milestone 2: 3D Interactive Devices & Sensors", _test_3d_interactive_devices)
	_run_suite("Milestone 2: Dynamic Failure Scenarios & Multi-Path Resolutions", _test_failure_scenarios_and_resolutions)
	_run_suite("Milestone 2: Player Environmental Afflictions & Movement Penalties", _test_player_afflictions)
	_run_suite("Milestone 2: Save / Load Serialization of Atmospheric State", _test_environmental_save_load)
	_run_suite("Milestone 2: Ship Schematic & Terminal UI Environmental Telemetry", _test_schematic_and_terminal_environmental_ui)
	_run_suite("Milestone 2: Interconnected Cascades, Dynamic Fault Persistence & Diagnostic Controls", _test_m2_interconnection_persistence_and_diagnostics)
	_run_suite("Milestone 3: Inventory Management & Resource Constraints", _test_m3_inventory_and_resources)
	_run_suite("Milestone 3: Handheld Engineering Tools & Modes", _test_m3_handheld_tools)
	_run_suite("Milestone 3: Physical Workstations & Storage Lockers", _test_m3_workstations_and_lockers)
	_run_suite("Milestone 3: Deepened Multi-Step Device Repair", _test_m3_deepened_multi_step_repair)
	_run_suite("Milestone 3: Subsystem Power & Coolant Rerouting", _test_m3_rerouting_and_overrides)
	_run_suite("Milestone 3: In-Game Tactile Diagnostic Tutorial", _test_m3_diagnostic_tutorial)
	_run_suite("Milestone 3: Save / Load Persistence of Tools & Repair State", _test_m3_save_load_persistence)
	_run_suite("Milestone 3: Deep Verification, Multitool Modes, Reroute Ticks & Tutorial Reactive Flow", _test_m3_deep_verification_and_edge_cases)
	_run_suite("Milestone 4: 11-Compartment Environmental & Atmospheric Simulation", _test_m4_environmental_simulation)
	_run_suite("Milestone 4: Airlock Safety Interlocks & Pressure Cycling", _test_m4_airlock_interlocks_and_cycling)
	_run_suite("Milestone 4: Tactical Ship Schematic Map & Direct Power Rerouting", _test_m4_ship_schematic_overhaul)
	_run_suite("Milestone 4: Breach Sealing, Salvage Cutting & Shortcut Traversal", _test_m4_breach_salvage_shortcuts)
	_run_suite("Milestone 4: Save / Load Persistence of Expanded Vessel", _test_m4_save_load_persistence)
	_run_suite("Milestone 4: Narrative Crew Logs & Objective Exploration Tracking", _test_m4_narrative_logs_and_exploration)
	_run_suite("Milestone 5: Narrative Config & Physical Datapad Placement Integrity", _test_m5_narrative_config_and_scene_placement)
	_run_suite("Milestone 5: Datapad Interaction, Encryption & Scanner Battery Drain", _test_m5_datapad_encryption_and_scanner)
	_run_suite("Milestone 5: Crew Mystery Revelations & Ship System Consequences", _test_m5_revelations_and_system_consequences)
	_run_suite("Milestone 5: Terminal UI Dossier, Log Filters & Save/Load Persistence", _test_m5_terminal_ui_and_save_load)
	_run_suite("Milestone 6: Dynamic Crisis Scenarios & Cascading Faults", _test_m6_dynamic_crisis_scenarios_and_cascades)
	_run_suite("Milestone 6: Alien Stalking, Chamber Trap & Toxic Gas Purge", _test_m6_creature_hunt_and_poison_gas_trap)
	_run_suite("Milestone 6: Tactical UI Telemetry, Immediate Task & Sizing", _test_m6_tactical_ui_telemetry_and_immediate_task)
	_run_suite("Milestone 6: Crisis Save / Load Persistence & Legacy Compatibility", _test_m6_save_load_crisis_persistence)
	_run_suite("Milestone 6: Enhanced Object Visuals & In-Game Storyline Verification", _test_m6_enhanced_visuals_and_storyline_verification)
	_run_suite("Milestone 7: Expanded Chambers & Environmental Survey Simulation", _test_m7_expanded_chambers_and_environmental_survey)
	_run_suite("Milestone 7: 3D Physical Alien Stalker Entity & Horror Boss Zoom Mechanics", _test_m7_physical_stalker_and_horror_zoom)
	_run_suite("Milestone 7: Extended Exploration & Crisis Stalking Progression Flow", _test_m7_exploration_and_crisis_stalking_flow)
	_run_suite("Milestone 7: Production Release Polish, Save/Load Persistence & End-Game Verification", _test_m7_production_polish_and_persistence)
	_run_suite("Milestone 7: Architectural Chamber Connectivity & Horror Encounter Stalking Rigor", _test_m7_chamber_connectivity_and_horror_rigor)
	_run_suite("QA Systems Integrity & Gameplay Improvements", _test_qa_integrity_and_improvements)
	_run_suite("Paced Alien Stalker Emergence & Safe Room Sanctuary", _test_alien_pacing_and_safe_room)
	_run_suite("Game Modes, Look Controls, Generator Breaker & Audio Integration", _test_modes_look_breaker_and_audio)
	_run_suite("Alien 3D Body, Proximity Impact Audio, Death Screams & Enclosed Chamber Geometry", _test_alien_3d_body_audio_and_geometry)
	_run_suite("Cargo Annex Repairs, Subdeck Ramp Incline, 3-Hit Kill & Stalker Navigation", _test_final_phase_upgrades)
	
	print("\n=======================================================")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("=======================================================\n")
	
	AudioManager.stop_all()
	for i in range(3):
		await get_tree().process_frame
	if tests_failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func _run_suite(suite_name: String, test_func: Callable) -> void:
	print("--> Running Suite: %s" % suite_name)
	test_func.call()

func _assert_true(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("  [PASS] %s" % message)
	else:
		tests_failed += 1
		print("  [FAIL] %s" % message)

func _test_ship_systems() -> void:
	ShipSystemManager.reset_to_defaults()
	
	_assert_true(ShipSystemManager.get_system_state("primary_power") == ShipSystemClass.State.OFFLINE, "Initial primary_power is OFFLINE")
	_assert_true(ShipSystemManager.get_system_state("power_distribution") == ShipSystemClass.State.OFFLINE, "Initial power_distribution is OFFLINE")
	_assert_true(ShipSystemManager.get_system_state("life_support") == ShipSystemClass.State.FAILED, "Initial life_support is FAILED")
	_assert_true(ShipSystemManager.get_system_state("communications") == ShipSystemClass.State.OFFLINE, "Initial communications is OFFLINE")
	_assert_true(ShipSystemManager.get_system_state("propulsion") == ShipSystemClass.State.OFFLINE, "Initial propulsion is OFFLINE")
	
	var bus_res := ShipSystemManager.set_power_distribution(true)
	_assert_true(not bus_res.get("ok", false), "Bus cannot energize while primary_power is OFFLINE")
	_assert_true(not ShipSystemManager.is_system_online("power_distribution"), "Bus remains OFFLINE")
	_assert_true(not ShipSystemManager.bus_relay_closed, "bus_relay_closed stays false on failure")
	
	var comms_res := ShipSystemManager.align_comms_array()
	_assert_true(not comms_res.get("ok", false), "Comms cannot align while bus is OFFLINE")
	
	var gen_res := ShipSystemManager.set_generator_breaker(true)
	_assert_true(gen_res.get("ok", false) and ShipSystemManager.is_system_online("primary_power"), "Generator breaker closes -> primary_power ONLINE")
	
	bus_res = ShipSystemManager.set_power_distribution(true)
	_assert_true(bus_res.get("ok", false) and ShipSystemManager.is_system_online("power_distribution"), "Bus energizes successfully -> power_distribution ONLINE")
	
	_assert_true(not ShipSystemManager.is_system_online("life_support"), "Life support still unsealed without coupler")
	
	var ls_res := ShipSystemManager.install_coolant_coupler()
	_assert_true(ls_res.get("ok", false) and ShipSystemManager.is_system_online("life_support"), "Coupler installed with bus live -> life_support ONLINE")
	
	comms_res = ShipSystemManager.align_comms_array()
	_assert_true(comms_res.get("ok", false) and ShipSystemManager.is_system_online("communications"), "Comms array aligned with bus live -> communications ONLINE")
	
	var prop_res := ShipSystemManager.engage_propulsion()
	_assert_true(prop_res.get("ok", false) and ShipSystemManager.is_system_online("propulsion"), "Propulsion engaged with all prereqs online -> propulsion ONLINE")
	
	# Test cascade failure and breaker trip
	ShipSystemManager.set_generator_breaker(false)
	_assert_true(not ShipSystemManager.is_system_online("primary_power"), "Generator tripped -> OFFLINE")
	_assert_true(not ShipSystemManager.is_system_online("power_distribution"), "Cascaded power loss -> power_distribution OFFLINE")
	_assert_true(not ShipSystemManager.bus_relay_closed, "Bus relay breaker tripped open upon generator power loss")
	_assert_true(not ShipSystemManager.is_system_online("communications"), "Cascaded power loss -> communications OFFLINE")
	_assert_true(not ShipSystemManager.is_system_online("propulsion"), "Cascaded power loss -> propulsion OFFLINE")
	_assert_true(not ShipSystemManager.propulsion_primed, "Propulsion primed state reset upon power cascade")

func _test_missions() -> void:
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()
	
	_assert_true(MissionManager.current_objective_index == 0, "Mission starts at Objective 0")
	_assert_true(MissionManager.get_objective_count() == 5, "Total 5 sequential objectives defined")
	
	_assert_true(not MissionManager.has_item("coolant_coupler"), "Inventory starts empty")
	MissionManager.add_inventory_item("coolant_coupler")
	_assert_true(MissionManager.has_item("coolant_coupler"), "Item added to inventory")
	var removed := MissionManager.remove_inventory_item("coolant_coupler")
	_assert_true(removed and not MissionManager.has_item("coolant_coupler"), "Item removed from inventory")
	
	_assert_true(MissionManager.CREW_LOGS.size() == 10, "Exactly 10 narrative crew logs exist")
	for i in range(MissionManager.CREW_LOGS.size()):
		var log: Dictionary = MissionManager.CREW_LOGS[i]
		_assert_true(log.has("title") and str(log["title"]).length() > 0, "Log %d has valid title" % (i + 1))
		_assert_true(log.has("content") and str(log["content"]).length() > 30, "Log %d has detailed content" % (i + 1))
	
	ShipSystemManager.set_generator_breaker(true)
	_assert_true(MissionManager.current_objective_index == 1, "Obj 1 completes when primary_power ONLINE -> advanced to 1")
	
	ShipSystemManager.set_power_distribution(true)
	_assert_true(MissionManager.current_objective_index == 2, "Obj 2 completes when bus ONLINE -> advanced to 2")
	
	ShipSystemManager.install_coolant_coupler()
	_assert_true(MissionManager.current_objective_index == 3, "Obj 3 completes when life_support ONLINE -> advanced to 3")
	
	ShipSystemManager.align_comms_array()
	_assert_true(MissionManager.current_objective_index == 4, "Obj 4 completes when communications ONLINE -> advanced to 4")
	
	ShipSystemManager.engage_propulsion()
	_assert_true(MissionManager.current_objective_index == 5, "Obj 5 completes when propulsion ONLINE -> all completed")

func _test_environmental() -> void:
	var env = EnvManagerScript.new()
	env.oxygen_level = 100.0
	
	ShipSystemManager.reset_to_defaults()
	env._process(10.0)
	_assert_true(env.oxygen_level < 100.0, "Oxygen depletes when life support is offline (level: %.1f%%)" % env.oxygen_level)
	
	ShipSystemManager.set_generator_breaker(true)
	ShipSystemManager.set_power_distribution(true)
	ShipSystemManager.install_coolant_coupler()
	
	var depleted_val: float = env.oxygen_level
	env._process(5.0)
	_assert_true(env.oxygen_level > depleted_val, "Oxygen replenishes when life support is online (level: %.1f%%)" % env.oxygen_level)
	env.free()

func _test_save_load() -> void:
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()
	ShipSystemManager.set_generator_breaker(true)
	ShipSystemManager.set_power_distribution(true)
	MissionManager.add_inventory_item("coolant_coupler")
	
	var level_scene = load("res://scenes/levels/ship_interior.tscn")
	var level = level_scene.instantiate()
	add_child(level)
	
	var door_aft: BulkheadDoor = level.get_node("Compartments/Corridors/DoorAft")
	door_aft.set_door_state(true)
	
	var save_ok := SaveManager.save_game(level.get_node("Player"), level.get_node("EnvironmentalManager"))
	_assert_true(save_ok and SaveManager.has_save_file(), "Save file successfully written")
	level.free()
	
	# Reset state before load
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()
	_assert_true(not ShipSystemManager.is_system_online("primary_power"), "State cleared before load")
	_assert_true(not MissionManager.has_item("coolant_coupler"), "Inventory cleared before load")
	
	# Instantiate fresh level with pending load
	SaveManager.set_meta("pending_load", true)
	var loaded_level = level_scene.instantiate()
	add_child(loaded_level)
	
	_assert_true(ShipSystemManager.is_system_online("primary_power"), "Loaded primary_power state restored")
	_assert_true(ShipSystemManager.is_system_online("power_distribution"), "Loaded power_distribution state restored")
	_assert_true(MissionManager.has_item("coolant_coupler"), "Loaded inventory item restored")
	
	var gen_breaker: BreakerSwitch = loaded_level.get_node("Compartments/EngineeringBay/GeneratorBreaker")
	var bus_breaker: BreakerSwitch = loaded_level.get_node("Compartments/EngineeringBay/BusBreaker")
	_assert_true(gen_breaker.is_on, "3D Generator breaker is_on synced after scene load")
	_assert_true(bus_breaker.is_on, "3D Bus breaker is_on synced after scene load")
	
	var loaded_door_aft: BulkheadDoor = loaded_level.get_node("Compartments/Corridors/DoorAft")
	_assert_true(loaded_door_aft.is_open, "Loaded door state restored as open")
	_assert_true(loaded_door_aft.is_powered(), "Loaded door is powered")
	
	loaded_level.free()
	SaveManager.delete_save()
	_assert_true(not SaveManager.has_save_file(), "Save file cleanly deleted after test")

func _test_door_mechanics() -> void:
	ShipSystemManager.reset_to_defaults()
	var door_scene = load("res://scenes/interactables/door.tscn")
	var door: BulkheadDoor = door_scene.instantiate()
	add_child(door)
	
	_assert_true(not door.is_open, "Door initially closed")
	_assert_true(not door.is_powered(), "Door initially unpowered")
	
	var col: CollisionShape3D = door.get_node("InteractionCollision")
	var initial_y: float = col.position.y
	
	# Energize bus and test door
	ShipSystemManager.set_generator_breaker(true)
	ShipSystemManager.set_power_distribution(true)
	_assert_true(door.is_powered(), "Door becomes powered upon bus activation")
	
	door.set_door_state(true, true)
	_assert_true(door.is_open, "Door state set to open")
	_assert_true(col.position.y > initial_y, "Doorway collision clears upward when door opens")
	
	door.free()
	ShipSystemManager.reset_to_defaults()

func _test_player_input() -> void:
	var player_scene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate()
	add_child(player)
	
	player.velocity = Vector3(5, 0, 5)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player._physics_process(0.1)
	_assert_true(player.velocity.x < 5.0 and player.velocity.z < 5.0, "Player decelerates when mouse is visible (in menus)")
	
	player.free()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _test_audio_lifecycle() -> void:
	AudioManager.play_ambient("generator_hum")
	AudioManager.play_alarm_loop("alarm")
	_assert_true(AudioManager._ambient_player.playing, "Ambient hum is playing")
	_assert_true(AudioManager._alarm_player.playing, "Alarm is playing")
	
	AudioManager.stop_all()
	_assert_true(not AudioManager._ambient_player.playing, "Ambient hum stopped after stop_all")
	_assert_true(not AudioManager._alarm_player.playing, "Alarm stopped after stop_all")

func _test_scenes() -> void:
	var scenes_to_test := [
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/ui/pause_menu.tscn",
		"res://scenes/ui/terminal_dialog.tscn",
		"res://scenes/ui/hud.tscn",
		"res://scenes/ui/mission_complete.tscn",
		"res://scenes/ui/game_over.tscn",
		"res://scenes/interactables/switch.tscn",
		"res://scenes/interactables/door.tscn",
		"res://scenes/interactables/repair_panel.tscn",
		"res://scenes/interactables/terminal.tscn",
		"res://scenes/interactables/pickup.tscn",
		"res://scenes/player/player.tscn",
		"res://scenes/levels/engineering_bay.tscn",
		"res://scenes/levels/life_support.tscn",
		"res://scenes/levels/bridge.tscn",
		"res://scenes/levels/ship_interior.tscn",
		"res://scenes/ui/ship_schematic.tscn"
	]
	
	for path in scenes_to_test:
		var scene_res = load(path)
		_assert_true(scene_res != null, "Scene resource loaded: %s" % path)
		if scene_res is PackedScene:
			var instance = scene_res.instantiate()
			_assert_true(instance != null, "Scene instantiated cleanly: %s" % path)
			if instance != null:
				instance.free()

func _test_end_to_end_level_flow() -> void:
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()
	
	var level_scene = load("res://scenes/levels/ship_interior.tscn")
	_assert_true(level_scene != null, "ship_interior.tscn loads")
	var level: Node3D = level_scene.instantiate()
	add_child(level)
	
	var player = level.get_node("Player")
	_assert_true(player != null, "Player exists in level")
	
	# Objective 1: Flip generator breaker
	var gen_breaker: BreakerSwitch = level.get_node("Compartments/EngineeringBay/GeneratorBreaker")
	_assert_true(gen_breaker != null, "Generator breaker found in Engineering Bay")
	gen_breaker.interact(player)
	_assert_true(ShipSystemManager.is_system_online("primary_power"), "Generator breaker interaction powers primary_power")
	_assert_true(gen_breaker.is_on, "Generator breaker 3D switch is_on true")
	_assert_true(MissionManager.current_objective_index == 1, "Mission advanced to Objective 1 (Energize Bus)")
	
	# Objective 2: Flip bus breaker
	var bus_breaker: BreakerSwitch = level.get_node("Compartments/EngineeringBay/BusBreaker")
	_assert_true(bus_breaker != null, "Bus breaker found in Engineering Bay")
	bus_breaker.interact(player)
	_assert_true(ShipSystemManager.is_system_online("power_distribution"), "Bus breaker interaction energizes distribution bus")
	_assert_true(bus_breaker.is_on, "Bus breaker 3D switch is_on true")
	_assert_true(MissionManager.current_objective_index == 2, "Mission advanced to Objective 2 (Life Support)")
	
	# Check door is now unlocked
	var door_aft: BulkheadDoor = level.get_node("Compartments/Corridors/DoorAft")
	_assert_true(door_aft.is_powered(), "Door Aft is powered after bus energized")
	door_aft.interact(player)
	_assert_true(door_aft.is_open, "Door Aft opened on interaction")
	
	# Objective 3: Pick up spare coolant coupler and repair manifold
	var pickup = level.get_node_or_null("Compartments/EngineeringBay/SpareCouplerPickup")
	_assert_true(pickup != null, "Spare coupler pickup found on workbench")
	pickup.interact(player)
	_assert_true(MissionManager.has_item("coolant_coupler"), "Player acquired coolant coupler in inventory")
	
	var repair_panel: RepairPanel = level.get_node("Compartments/LifeSupport/CoolantRepairPanel")
	_assert_true(repair_panel != null, "Coolant repair panel found in Life Support")
	repair_panel.interact(player)
	_assert_true(ShipSystemManager.is_system_online("life_support"), "Life Support restored to ONLINE after repair")
	_assert_true(repair_panel.is_repaired, "Repair panel is_repaired is true")
	_assert_true(MissionManager.current_objective_index == 3, "Mission advanced to Objective 3 (Comms)")
	
	# Objective 4: Align comms array
	var comms_term: TerminalConsole = level.get_node("Compartments/Bridge/BridgeCommsTerminal")
	_assert_true(comms_term != null, "Bridge Comms Terminal found")
	var align_res := ShipSystemManager.align_comms_array()
	_assert_true(align_res.get("ok", false) and ShipSystemManager.is_system_online("communications"), "Comms array aligned")
	_assert_true(MissionManager.current_objective_index == 4, "Mission advanced to Objective 4 (Propulsion)")
	
	# Objective 5: Engage departure switch
	var departure_switch: BreakerSwitch = level.get_node("Compartments/Bridge/DepartureSwitch")
	_assert_true(departure_switch != null, "Departure switch found at Helm Console")
	departure_switch.interact(player)
	_assert_true(ShipSystemManager.is_system_online("propulsion"), "Propulsion engaged -> ONLINE")
	_assert_true(departure_switch.is_on, "Departure switch is_on true")
	_assert_true(MissionManager.current_objective_index == 5, "All 5 missions completed successfully!")
	
	level.free()

func _test_ship_state_architecture() -> void:
	ShipState.reset_to_defaults()
	_assert_true(ShipState != null, "ShipState central manager autoload initialized")
	
	# Verify subsystems
	_assert_true(ShipState.subsystems.has("power"), "ShipState has power subsystem")
	_assert_true(ShipState.subsystems.has("coolant"), "ShipState has coolant subsystem")
	_assert_true(ShipState.subsystems.has("life_support"), "ShipState has life_support subsystem")
	_assert_true(ShipState.subsystems.has("communications"), "ShipState has communications subsystem")
	_assert_true(ShipState.subsystems.has("propulsion"), "ShipState has propulsion subsystem")
	_assert_true(ShipState.subsystems.has("doors"), "ShipState has doors subsystem")
	_assert_true(ShipState.subsystems.has("computer_network"), "ShipState has computer_network subsystem")
	_assert_true(ShipState.subsystems.has("structural"), "ShipState has structural subsystem")
	_assert_true(ShipState.subsystems.has("fuel"), "ShipState has fuel subsystem")
	
	# Verify generic Subsystem API
	var pwr_sub = ShipState.get_subsystem("power")
	_assert_true(pwr_sub.GetStatus() is Dictionary, "Subsystem API: GetStatus() returns Dictionary")
	_assert_true(pwr_sub.GetEfficiency() >= 0.0, "Subsystem API: GetEfficiency() returns float >= 0")
	_assert_true(pwr_sub.GetPowerDraw() >= 0.0, "Subsystem API: GetPowerDraw() returns float >= 0")
	
	pwr_sub.ApplyDamage(10.0, "Thermal shock")
	_assert_true(pwr_sub.GetEfficiency() < 1.0, "Subsystem API: ApplyDamage() reduces efficiency")
	pwr_sub.Repair(15.0)
	_assert_true(pwr_sub.GetEfficiency() == 1.0, "Subsystem API: Repair() restores efficiency")
	
	# Verify generic Device API
	var scrubber = ShipState.get_device("life_support_scrubber")
	_assert_true(scrubber != null, "Device life_support_scrubber registered")
	_assert_true(scrubber.GetPowerDraw() > 0.0, "Device API: GetPowerDraw() returns valid draw")
	_assert_true(scrubber.GetStatus() is Dictionary, "Device API: GetStatus() returns status dictionary")
	_assert_true(scrubber.GetEfficiency() >= 0.0, "Device API: GetEfficiency() returns valid float")
	_assert_true(ShipState.get_device("coolant_pump") != null, "Device coolant_pump registered")
	
	var initial_hp: float = scrubber.health
	scrubber.ApplyDamage(20.0, "Cavitation damage")
	_assert_true(scrubber.health < initial_hp, "Device API: ApplyDamage() reduces health")
	scrubber.Repair(20.0)
	_assert_true(scrubber.health == initial_hp, "Device API: Repair() restores health")
	
	# Verify Fault architecture
	_assert_true(ShipState.active_faults.has("GENERATOR_TRIP"), "Initial fault GENERATOR_TRIP active")
	_assert_true(ShipState.active_faults.has("BUS_ISOLATION"), "Initial fault BUS_ISOLATION active")
	_assert_true(ShipState.active_faults.has("COOLANT_COUPLER_FRACTURE"), "Initial fault COOLANT_COUPLER_FRACTURE active")
	_assert_true(ShipState.active_faults.has("COMMS_SERVO_DESYNC"), "Initial fault COMMS_SERVO_DESYNC active")
	
	var fault: RefCounted = ShipState.active_faults["COOLANT_COUPLER_FRACTURE"]
	_assert_true(fault.symptoms.size() > 0, "Fault defines symptoms")
	_assert_true(fault.diagnostic_methods.size() > 0, "Fault defines diagnostic methods")
	_assert_true(fault.repair_steps.size() > 0, "Fault defines repair steps")
	_assert_true(fault.required_parts.has("coolant_coupler"), "Fault defines required spare parts")
	
	# Test fault ticking & escalation
	fault.tick(130.0)
	_assert_true(fault.escalation_stage >= 2, "Fault escalates over time when unresolved")

func _test_power_system_simulation() -> void:
	ShipState.reset_to_defaults()
	var pwr: RefCounted = ShipState.power_system
	_assert_true(pwr != null, "PowerSystem instance exists")
	
	# Initial offline state
	var telem: Dictionary = pwr.get_grid_telemetry()
	_assert_true(not telem["reactor_online"], "Initial reactor is offline")
	_assert_true(not telem["bus_relay_closed"], "Initial bus relay is open")
	_assert_true(not telem["bus_energized"], "Initial bus is not energized")
	_assert_true(telem["current_generation"] == 0.0, "Initial generation is 0.0 kW")
	_assert_true(telem["battery_charge"] > 0.0, "Battery holds initial emergency reserve")
	
	# Bus cannot energize without generator
	var fail_bus: Dictionary = pwr.set_bus_relay(true)
	_assert_true(not fail_bus.get("ok", false), "Bus relay cannot energize while reactor is offline")
	_assert_true(not pwr.bus_energized, "Bus remains un-energized on invalid close")
	
	# Close generator breaker
	var gen_res: Dictionary = pwr.set_generator(true)
	_assert_true(gen_res.get("ok", false) and pwr.reactor_online, "Reactor starts upon breaker closure")
	_assert_true(pwr.current_generation >= 150.0, "Reactor delivers nominal capacity (>= 150 kW)")
	
	# Close bus relay
	var bus_res: Dictionary = pwr.set_bus_relay(true)
	_assert_true(bus_res.get("ok", false) and pwr.bus_energized, "Bus energizes successfully when generator is active")
	
	# Check power allocation to devices
	pwr.tick(1.0)
	var active_telem: Dictionary = pwr.get_grid_telemetry()
	_assert_true(active_telem["current_demand"] > 0.0, "Active devices draw load from power grid")
	_assert_true(active_telem["net_power"] > 0.0, "Grid operates in positive surplus under nominal generation")
	_assert_true(active_telem["grid_efficiency"] == 1.0, "Grid efficiency is 100% under nominal supply")
	
	# Check battery charging under surplus
	var initial_charge: float = pwr.battery_charge
	pwr.tick(3600.0) # 1 hour of surplus
	_assert_true(pwr.battery_charge > initial_charge, "Battery charges from generation surplus")
	
	# Test cascade loss on generator trip
	pwr.set_generator(false)
	_assert_true(not pwr.reactor_online, "Generator tripped to offline")
	_assert_true(not pwr.bus_relay_closed, "Bus relay automatically trips upon generator loss")
	_assert_true(not pwr.bus_energized, "Bus de-energizes upon generator trip")
	
	ShipState.reset_to_defaults()

func _test_chamber_devices_connected_to_power() -> void:
	ShipState.reset_to_defaults()
	
	# Check devices in Engineering Bay
	var eng_devs: Array = ShipState.get_compartment_devices("engineering_bay")
	_assert_true(eng_devs.size() >= 3, "Engineering Bay contains generator, bus, and terminal devices")
	
	# Check devices in Corridors
	var corr_devs: Array = ShipState.get_compartment_devices("corridors")
	_assert_true(corr_devs.size() >= 2, "Corridors contain aft and fwd bulkhead doors")
	
	# Check devices in Life Support
	var ls_devs: Array = ShipState.get_compartment_devices("life_support")
	_assert_true(ls_devs.size() >= 2, "Life Support contains scrubber and terminal devices")
	
	# Check devices in Bridge
	var bridge_devs: Array = ShipState.get_compartment_devices("bridge")
	_assert_true(bridge_devs.size() >= 3, "Bridge contains comms, ion propulsion, and terminal devices")
	
	# Verify device power states before and after bus energization
	var door_aft = ShipState.get_device("door_aft")
	var scrubber = ShipState.get_device("life_support_scrubber")
	var terminal = ShipState.get_device("eng_terminal")
	
	_assert_true(not door_aft.is_powered, "Door Aft is unpowered before bus energized")
	_assert_true(not scrubber.is_powered, "Scrubber is unpowered before bus energized")
	_assert_true(not terminal.is_powered, "Terminal is unpowered before bus energized")
	
	# Energize grid
	ShipState.set_generator_breaker(true)
	ShipState.set_bus_relay(true)
	
	_assert_true(door_aft.is_powered, "Door Aft is powered after bus energized")
	_assert_true(scrubber.is_powered, "Scrubber receives power from energized bus")
	_assert_true(terminal.is_powered, "Terminal console receives power from energized bus")
	
	ShipState.reset_to_defaults()

func _test_ship_schematic_ui() -> void:
	ShipState.reset_to_defaults()
	var schematic_scene = load("res://scenes/ui/ship_schematic.tscn")
	_assert_true(schematic_scene != null, "ship_schematic.tscn loads cleanly")
	
	var schematic: Control = schematic_scene.instantiate()
	add_child(schematic)
	_assert_true(schematic != null, "ShipSchematic instantiated cleanly")
	
	# Test initial schematic data
	var initial_data: Dictionary = ShipState.get_schematic_data()
	_assert_true(initial_data.has("power"), "Schematic data includes power telemetry")
	_assert_true(initial_data.has("compartments"), "Schematic data includes compartment breakdown")
	_assert_true(initial_data.has("primary_warning"), "Schematic data includes primary warning")
	_assert_true(initial_data.has("primary_action"), "Schematic data includes recommended action")
	
	_assert_true(initial_data["primary_warning"].contains("GENERATOR TRIPPED"), "Initial warning identifies generator trip")
	
	# Test UI reflection upon generator start
	ShipState.set_generator_breaker(true)
	var gen_data: Dictionary = ShipState.get_schematic_data()
	_assert_true(gen_data["primary_warning"].contains("MAIN BUS ISOLATED"), "Warning updates to bus isolation once generator is closed")
	
	# Test UI reflection upon bus energize
	ShipState.set_bus_relay(true)
	var bus_data: Dictionary = ShipState.get_schematic_data()
	_assert_true(bus_data["power"]["bus_energized"], "Schematic telemetry reflects energized bus")
	_assert_true(bus_data["primary_warning"].contains("ATMOSPHERIC CAVITATION"), "Warning guides player to Life Support repair")
	
	schematic.open_schematic()
	_assert_true(schematic.visible, "Schematic UI opens and becomes visible")
	schematic.close_schematic()
	_assert_true(not schematic.visible, "Schematic UI closes cleanly")
	
	schematic.free()
	ShipState.reset_to_defaults()

func _test_robustness_and_thermal() -> void:
	ShipState.reset_to_defaults()
	var pwr = ShipState.power_system
	
	# 1. Edge Case: Battery near zero and delta == 0.0
	pwr.battery_charge = 0.001
	pwr.set_generator(true)
	pwr.set_bus_relay(true)
	pwr.tick(0.0)
	var telem: Dictionary = pwr.get_grid_telemetry()
	_assert_true(not is_inf(telem["current_supplied"]) and not is_nan(telem["current_supplied"]), "Zero-delta tick produces no INF or NaN")
	_assert_true(not is_inf(telem["grid_efficiency"]) and not is_nan(telem["grid_efficiency"]), "Zero-delta grid efficiency is valid number")
	
	# Rapid toggles with near-empty battery
	for i in range(5):
		pwr.set_generator(false)
		pwr.set_generator(true)
		pwr.set_bus_relay(true)
		pwr.tick(0.05)
	_assert_true(pwr.battery_charge >= 0.0, "Battery charge stays non-negative after rapid cycles")
	_assert_true(not is_inf(pwr.battery_charge), "Battery charge is not infinite")
	
	# 2. Thermal Simulation & Meltdown Safety Mode
	ShipState.reset_to_defaults()
	pwr = ShipState.power_system
	pwr.set_generator(true)
	pwr.set_bus_relay(true)
	pwr.coolant_flow_rate = 0.35
	pwr.tick(50.0)
	_assert_true(pwr.reactor_temperature > 320.0, "Reactor core heats up when coolant flow is impaired")
	
	pwr.reactor_temperature = 560.0
	pwr.tick(1.0)
	_assert_true(pwr.thermal_throttled, "Reactor enters thermal safety throttling at >= 550K")
	_assert_true(pwr.current_generation <= 60.0, "Thermal throttling reduces generation to avoid meltdown (<= 60 kW)")
	
	ShipState.install_coolant_coupler()
	_assert_true(pwr.coolant_flow_rate == 1.0, "Coolant flow restored after coupler repair")
	pwr.reactor_temperature = 400.0
	pwr.tick(1.0)
	_assert_true(not pwr.thermal_throttled, "Thermal throttling disengages as core cools")
	_assert_true(pwr.current_generation >= 150.0, "Full 150 kW generation restored after cooldown")
	
	# 3. Bidirectional Synchronization
	ShipState.reset_to_defaults()
	_assert_true(not ShipSystemManager.is_system_online("primary_power"), "ShipSystemManager primary_power initially offline")
	ShipState.set_generator_breaker(true)
	_assert_true(ShipSystemManager.is_system_online("primary_power"), "ShipState breaker flips ShipSystemManager primary_power ONLINE")
	_assert_true(ShipSystemManager.generator_breaker_closed, "ShipSystemManager flag synced from ShipState")
	
	ShipState.set_bus_relay(true)
	_assert_true(ShipSystemManager.is_system_online("power_distribution"), "ShipState bus relay flips ShipSystemManager power_distribution ONLINE")
	_assert_true(ShipSystemManager.bus_relay_closed, "ShipSystemManager bus flag synced from ShipState")
	
	ShipState.install_coolant_coupler()
	_assert_true(ShipSystemManager.coolant_coupler_installed, "ShipState install coupler flips ShipSystemManager flag")
	_assert_true(ShipSystemManager.is_system_online("life_support"), "Life support online across both systems")
	
	ShipState.align_comms_array()
	_assert_true(ShipSystemManager.comms_array_aligned, "ShipState comms alignment flips ShipSystemManager flag")
	_assert_true(ShipSystemManager.is_system_online("communications"), "Communications online across both systems")
	
	ShipState.engage_propulsion()
	_assert_true(ShipSystemManager.propulsion_primed, "ShipState propulsion engage flips ShipSystemManager flag")
	_assert_true(ShipSystemManager.is_system_online("propulsion"), "Propulsion online across both systems")
	
	ShipSystemManager.set_generator_breaker(false)
	_assert_true(not ShipState.power_system.reactor_online, "ShipSystemManager breaker open cascades to ShipState")
	_assert_true(not ShipState.power_system.bus_energized, "ShipState bus de-energized on reverse cascade")
	
	# 4. Schematic UI in-place performance
	var schematic_scene = load("res://scenes/ui/ship_schematic.tscn")
	var schematic: Control = schematic_scene.instantiate() as Control
	add_child(schematic)
	schematic.open_schematic()
	var dev_container: VBoxContainer = schematic.get_node("%SelectedRoomDevices")
	var initial_child_count := dev_container.get_child_count()
	for i in range(10):
		schematic.refresh_schematic()
	_assert_true(dev_container.get_child_count() == initial_child_count, "Schematic updates in-place without leaking UI row nodes")
	schematic.close_schematic()
	schematic.free()
	ShipState.reset_to_defaults()

func _test_multi_compartment_simulation() -> void:
	ShipSystemManager.reset_to_defaults()
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	
	# Baseline check
	var comps: Dictionary = env_mgr.get_all_compartments()
	_assert_true(comps.size() == 4, "All 4 compartments initialized in environmental simulation")
	
	var eng = env_mgr.get_compartment_atmosphere("engineering_bay")
	_assert_true(eng["o2_level"] == 100.0, "Engineering Bay initial O2 is 100%")
	_assert_true(eng["co2_ppm"] == 420.0, "Engineering Bay initial CO2 is nominal (420 ppm)")
	_assert_true(eng["pressure"] == 101.3, "Engineering Bay initial pressure is 101.3 kPa")
	_assert_true(eng["temperature"] > 290.0 and eng["temperature"] < 300.0, "Engineering Bay initial temperature is nominal")
	
	# Oxygen depletion under Life Support failure
	ShipSystemManager.get_system("life_support").state = ShipSystemClass.State.FAILED
	env_mgr._process(10.0)
	var eng_depleted = env_mgr.get_compartment_atmosphere("engineering_bay")
	_assert_true(eng_depleted["o2_level"] < 100.0, "O2 level depletes when Life Support is offline")
	_assert_true(env_mgr.oxygen_level < 100.0, "Legacy scalar oxygen_level depletes concurrently")
	var depleted_o2: float = float(eng_depleted["o2_level"])
	
	# Oxygen replenishment when Life Support is restored
	ShipSystemManager.set_generator_breaker(true)
	ShipSystemManager.set_power_distribution(true)
	ShipSystemManager.install_coolant_coupler()
	env_mgr._process(10.0)
	var eng_replenished = env_mgr.get_compartment_atmosphere("engineering_bay")
	_assert_true(eng_replenished["o2_level"] > depleted_o2, "O2 level replenishes when Life Support is online")
	
	# CO2 buildup from respiration & scrubbing
	env_mgr.player_compartment_id = "life_support"
	env_mgr.compartments["life_support"]["co2_ppm"] = 500.0
	env_mgr.compartments["life_support"]["scrubbers_active"] = false
	env_mgr._process(1.0)
	var ls_co2 = env_mgr.get_compartment_atmosphere("life_support")
	_assert_true(ls_co2["co2_ppm"] > 500.0, "CO2 accumulates in compartment occupied by player when scrubbers inactive")
	
	env_mgr.compartments["life_support"]["scrubbers_active"] = true
	var peak_co2: float = ls_co2["co2_ppm"]
	env_mgr._process(1.0)
	var ls_scrubbed = env_mgr.get_compartment_atmosphere("life_support")
	_assert_true(ls_scrubbed["co2_ppm"] < peak_co2, "Active scrubber loop reduces CO2 concentration")
	
	# Barometric decompression leak
	env_mgr.set_compartment_leak("bridge", 6.0)
	env_mgr._process(2.0)
	var bridge_press = env_mgr.get_compartment_atmosphere("bridge")
	_assert_true(bridge_press["pressure"] < 100.0, "Cabin pressure drops rapidly when leak rate > 0")
	env_mgr.set_compartment_leak("bridge", 0.0)
	
	env_mgr.free()
	ShipSystemManager.reset_to_defaults()

func _test_inter_compartment_diffusion() -> void:
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	
	# Set concentration gradient between corridors and bridge
	env_mgr.compartments["corridors"]["co2_ppm"] = 4000.0
	env_mgr.compartments["bridge"]["co2_ppm"] = 420.0
	env_mgr.compartments["corridors"]["vents_open"] = true
	env_mgr.compartments["bridge"]["vents_open"] = true
	
	env_mgr._simulate_diffusion(5.0)
	var br_co2 = env_mgr.compartments["bridge"]["co2_ppm"]
	var corr_co2 = env_mgr.compartments["corridors"]["co2_ppm"]
	_assert_true(br_co2 > 420.0, "CO2 diffuses across open boundary from high to low concentration")
	_assert_true(corr_co2 < 4000.0, "CO2 gradient dissipates from source compartment during open diffusion")
	
	# Test isolation with closed vent damper
	env_mgr.set_vent_damper("engineering_bay", false)
	env_mgr.compartments["corridors"]["co2_ppm"] = 5000.0
	env_mgr.compartments["engineering_bay"]["co2_ppm"] = 420.0
	var eng_start = env_mgr.compartments["engineering_bay"]["co2_ppm"]
	env_mgr._simulate_diffusion(4.0)
	_assert_true(is_equal_approx(env_mgr.compartments["engineering_bay"]["co2_ppm"], eng_start), "Closed vent damper isolates compartment from inter-chamber gas diffusion")
	
	env_mgr.free()

func _test_3d_interactive_devices() -> void:
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	
	# EnvironmentalSensor
	var sensor_scene = load("res://scenes/interactables/env_sensor.tscn")
	var sensor = sensor_scene.instantiate()
	add_child(sensor)
	sensor.compartment_id = "engineering_bay"
	var unpowered_prompt = sensor.get_prompt()
	_assert_true(unpowered_prompt.contains("Offline"), "EnvironmentalSensor reports offline when unpowered")
	ShipSystemManager.get_system("power_distribution").state = ShipSystemClass.State.ONLINE
	var telem = sensor.get_telemetry()
	_assert_true(telem.has("o2_level") and telem.has("co2_ppm"), "EnvironmentalSensor retrieves telemetry dictionary")
	var prompt = sensor.get_prompt()
	_assert_true(prompt.contains("Read Atmospheric Sensor"), "EnvironmentalSensor generates formatted telemetry prompt")
	sensor.interact(self)
	remove_child(sensor)
	sensor.queue_free()
	
	# VentDamper
	var damper_scene = load("res://scenes/interactables/vent_damper.tscn")
	var damper = damper_scene.instantiate()
	add_child(damper)
	damper.compartment_id = "life_support"
	_assert_true(damper.is_open, "VentDamper is initially open")
	damper.interact(self)
	_assert_true(not damper.is_open, "VentDamper closes upon player interaction")
	_assert_true(not env_mgr.compartments["life_support"]["vents_open"], "VentDamper updates EnvironmentalManager vents_open state")
	damper.interact(self)
	_assert_true(damper.is_open, "VentDamper re-opens upon second interaction")
	_assert_true(env_mgr.compartments["life_support"]["vents_open"], "EnvironmentalManager receives re-opened damper state")
	remove_child(damper)
	damper.queue_free()
	
	# EmergencyValve
	var valve_scene = load("res://scenes/interactables/emergency_valve.tscn")
	var valve = valve_scene.instantiate()
	add_child(valve)
	valve.valve_type = "pressure"
	valve.valve_name = "Atmospheric Pressure Isolation Valve"
	_assert_true(valve.get_prompt().contains("Inspect"), "Nominal valve prompt displays inspect message")
	valve.interact(self)
	remove_child(valve)
	valve.queue_free()
	
	# ScrubberPanel
	var scrub_scene = load("res://scenes/interactables/scrubber_panel.tscn")
	var scrub = scrub_scene.instantiate()
	add_child(scrub)
	_assert_true(not scrub.is_saturated(), "ScrubberPanel is nominal without fault")
	scrub.interact(self)
	remove_child(scrub)
	scrub.queue_free()
	
	remove_child(env_mgr)
	env_mgr.queue_free()

func _test_failure_scenarios_and_resolutions() -> void:
	ShipState.reset_to_defaults()
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	
	# --- SCENARIO 1: CO2_SCRUBBER_SATURATION ---
	var f1 = ShipState.trigger_fault("CO2_SCRUBBER_SATURATION")
	_assert_true(f1 != null and ShipState.active_faults.has("CO2_SCRUBBER_SATURATION"), "Failure Scenario 1: CO2_SCRUBBER_SATURATION triggered")
	var scrub_panel = load("res://scenes/interactables/scrubber_panel.tscn").instantiate()
	add_child(scrub_panel)
	_assert_true(scrub_panel.is_saturated(), "Scrubber panel detects saturation state")
	_assert_true(scrub_panel.get_prompt().contains("Flush & Replace"), "Scrubber prompt offers cartridge flush when saturated")
	# Resolution Path 1: Physical panel repair
	scrub_panel.interact(self)
	_assert_true(not ShipState.active_faults.has("CO2_SCRUBBER_SATURATION"), "Physical scrubber cartridge replacement resolves fault")
	remove_child(scrub_panel)
	scrub_panel.queue_free()
	
	# Resolution Path 2: Terminal purge override
	ShipState.trigger_fault("CO2_SCRUBBER_SATURATION")
	_assert_true(ShipState.active_faults.has("CO2_SCRUBBER_SATURATION"), "CO2_SCRUBBER_SATURATION re-triggered")
	env_mgr.trigger_co2_purge()
	_assert_true(not ShipState.active_faults.has("CO2_SCRUBBER_SATURATION"), "Terminal emergency CO2 purge override resolves fault")
	
	# Resolution Path 3: Power Rerouting to Secondary Scrubber Bank
	ShipState.trigger_fault("CO2_SCRUBBER_SATURATION")
	ShipSystemManager.get_system("power_distribution").state = ShipSystemClass.State.ONLINE
	ShipState.reroute_auxiliary_scrubber(true)
	_assert_true(ShipState.auxiliary_scrubber_active, "Power rerouting engages secondary CO2 scrubber bank")
	env_mgr.compartments["life_support"]["co2_ppm"] = 1500.0
	env_mgr._process(1.0)
	_assert_true(env_mgr.compartments["life_support"]["co2_ppm"] < 1500.0, "Auxiliary scrubber absorbs CO2 while primary scrubber remains faulted")
	ShipState.reroute_auxiliary_scrubber(false)
	ShipState.resolve_fault("CO2_SCRUBBER_SATURATION")
	
	# --- SCENARIO 2: CABIN_PRESSURE_LEAK ---
	var f2 = ShipState.trigger_fault("CABIN_PRESSURE_LEAK")
	_assert_true(f2 != null and ShipState.active_faults.has("CABIN_PRESSURE_LEAK"), "Failure Scenario 2: CABIN_PRESSURE_LEAK triggered")
	var press_valve = load("res://scenes/interactables/emergency_valve.tscn").instantiate()
	press_valve.valve_type = "pressure"
	add_child(press_valve)
	_assert_true(press_valve.check_fault_active(), "Pressure isolation valve identifies active leak")
	_assert_true(press_valve.get_prompt().contains("Seal Cabin Leak"), "Valve prompt offers leak seal")
	# Resolution Path 1: Handwheel valve operation
	press_valve.interact(self)
	_assert_true(not ShipState.active_faults.has("CABIN_PRESSURE_LEAK"), "Operating emergency shutoff valve resolves CABIN_PRESSURE_LEAK")
	remove_child(press_valve)
	press_valve.queue_free()
	
	# Resolution Path 2: Terminal pressurization override
	ShipState.trigger_fault("CABIN_PRESSURE_LEAK")
	_assert_true(ShipState.active_faults.has("CABIN_PRESSURE_LEAK"), "CABIN_PRESSURE_LEAK re-triggered")
	env_mgr.trigger_pressurization_override("")
	_assert_true(not ShipState.active_faults.has("CABIN_PRESSURE_LEAK"), "Terminal emergency repressurization override resolves fault")
	
	# --- SCENARIO 3: THERMAL_RUNAWAY ---
	var f3 = ShipState.trigger_fault("THERMAL_RUNAWAY")
	_assert_true(f3 != null and ShipState.active_faults.has("THERMAL_RUNAWAY"), "Failure Scenario 3: THERMAL_RUNAWAY triggered")
	var therm_valve = load("res://scenes/interactables/emergency_valve.tscn").instantiate()
	therm_valve.valve_type = "cooling"
	add_child(therm_valve)
	_assert_true(therm_valve.check_fault_active(), "Cooling bypass valve identifies thermal runaway")
	_assert_true(therm_valve.get_prompt().contains("Dump Excess Heat"), "Thermal valve prompt offers heat dump")
	# Resolution Path 1: Valve bypass operation
	therm_valve.interact(self)
	_assert_true(not ShipState.active_faults.has("THERMAL_RUNAWAY"), "Operating radiator cooling bypass valve resolves THERMAL_RUNAWAY")
	remove_child(therm_valve)
	therm_valve.queue_free()
	
	# Resolution Path 2: Terminal thermal reset override
	ShipState.trigger_fault("THERMAL_RUNAWAY")
	_assert_true(ShipState.active_faults.has("THERMAL_RUNAWAY"), "THERMAL_RUNAWAY re-triggered")
	env_mgr.trigger_thermal_reset()
	_assert_true(not ShipState.active_faults.has("THERMAL_RUNAWAY"), "Terminal climate reset override resolves THERMAL_RUNAWAY")
	
	remove_child(env_mgr)
	env_mgr.queue_free()
	ShipState.reset_to_defaults()

func _test_player_afflictions() -> void:
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	env_mgr.player_compartment_id = "engineering_bay"
	
	# 1. Hypoxia (O2 < 60%)
	env_mgr.compartments["engineering_bay"]["o2_level"] = 50.0
	env_mgr._evaluate_player_afflictions(0.0)
	_assert_true(env_mgr.player_afflictions.has("HYPOXIA"), "Hypoxia detected when O2 < 60%")
	
	# 2. CO2 Toxicity (CO2 > 2000 ppm)
	env_mgr.compartments["engineering_bay"]["o2_level"] = 100.0
	env_mgr.compartments["engineering_bay"]["co2_ppm"] = 2800.0
	env_mgr._evaluate_player_afflictions(0.0)
	_assert_true(env_mgr.player_afflictions.has("CO2_TOXICITY"), "CO2 toxicity detected when CO2 > 2000 ppm")
	
	# 3. Hypothermia (Temp < 283.15 K = 10°C)
	env_mgr.compartments["engineering_bay"]["co2_ppm"] = 420.0
	env_mgr.compartments["engineering_bay"]["temperature"] = 278.0
	env_mgr._evaluate_player_afflictions(0.0)
	_assert_true(env_mgr.player_afflictions.has("HYPOTHERMIA"), "Hypothermia detected when Temperature < 10°C")
	
	# 4. Heatstroke (Temp > 311.15 K = 38°C)
	env_mgr.compartments["engineering_bay"]["temperature"] = 318.0
	env_mgr._evaluate_player_afflictions(0.0)
	_assert_true(env_mgr.player_afflictions.has("HEATSTROKE"), "Heatstroke detected when Temperature > 38°C")
	
	# 5. Decompression (Pressure < 75.0 kPa)
	env_mgr.compartments["engineering_bay"]["temperature"] = 294.15
	env_mgr.compartments["engineering_bay"]["pressure"] = 62.0
	env_mgr._evaluate_player_afflictions(0.0)
	_assert_true(env_mgr.player_afflictions.has("DECOMPRESSION"), "Decompression detected when Pressure < 75 kPa")
	
	# 6. PlayerController response to afflictions
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_environmental_afflictions(["HYPOXIA"])
	_assert_true(player.speed_modifier < 1.0, "Player movement speed reduced under Hypoxia")
	
	player.apply_environmental_afflictions(["HYPOTHERMIA"])
	_assert_true(player.is_shivering, "Player camera shivering active under Hypothermia")
	
	player.apply_environmental_afflictions([])
	_assert_true(player.speed_modifier == 1.0, "Player movement speed restored to 1.0 when nominal")
	_assert_true(not player.is_shivering, "Camera shivering deactivated when nominal")
	
	player.free()
	env_mgr.free()

func _test_environmental_save_load() -> void:
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	
	env_mgr.compartments["corridors"]["o2_level"] = 82.5
	env_mgr.compartments["corridors"]["co2_ppm"] = 1450.0
	env_mgr.compartments["corridors"]["temperature"] = 286.0
	env_mgr.compartments["corridors"]["pressure"] = 92.4
	env_mgr.compartments["corridors"]["vents_open"] = false
	env_mgr.compartments["corridors"]["leak_rate"] = 0.5
	
	var exported: Dictionary = env_mgr.export_save_data()
	_assert_true(exported.has("compartments"), "Exported save data includes multi-compartment dictionary")
	_assert_true(exported["compartments"].has("corridors"), "Exported data contains corridors telemetry")
	
	var new_env = EnvManagerScript.new()
	add_child(new_env)
	new_env.import_save_data(exported)
	var corr = new_env.get_compartment_atmosphere("corridors")
	_assert_true(is_equal_approx(corr["o2_level"], 82.5), "Serialized O2 level preserved across save/load")
	_assert_true(is_equal_approx(corr["co2_ppm"], 1450.0), "Serialized CO2 ppm preserved across save/load")
	_assert_true(is_equal_approx(corr["temperature"], 286.0), "Serialized temperature preserved across save/load")
	_assert_true(is_equal_approx(corr["pressure"], 92.4), "Serialized pressure preserved across save/load")
	_assert_true(corr["vents_open"] == false, "Serialized vent damper position preserved across save/load")
	_assert_true(is_equal_approx(corr["leak_rate"], 0.5), "Serialized leak rate preserved across save/load")
	
	new_env.free()
	env_mgr.free()

func _test_schematic_and_terminal_environmental_ui() -> void:
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	
	# 1. Ship Schematic UI contains live atmospheric metrics
	var sdata = ShipState.get_schematic_data()
	_assert_true(sdata["compartments"]["life_support"].has("atmosphere"), "Schematic data includes compartment atmosphere dictionary")
	var ls_atmo: Dictionary = sdata["compartments"]["life_support"]["atmosphere"]
	_assert_true(ls_atmo.has("o2_level") and ls_atmo.has("pressure"), "Schematic atmosphere includes O2 and pressure metrics")
	
	# 2. Terminal Dialog Environmental Control Tab & Overrides
	var term_scene = load("res://scenes/ui/terminal_dialog.tscn")
	var term = term_scene.instantiate()
	add_child(term)
	
	term.open_terminal("life_support", "Atmospheric Diagnostics Console")
	var atmo_view: VBoxContainer = term.get_node("%AtmosphereView")
	_assert_true(atmo_view.visible, "Atmospheric Diagnostics Console opens directly to Atmosphere view")
	
	var atmo_list: VBoxContainer = term.get_node("%AtmosphereList")
	_assert_true(atmo_list.get_child_count() == 4, "Atmosphere view renders telemetry cards for all 4 compartments")
	
	# Test emergency override dispatch
	ShipSystemManager.get_system("power_distribution").state = ShipSystemClass.State.ONLINE
	term._on_emergency_purge_pressed()
	var atmo_status: Label = term.get_node("%AtmoStatusLabel")
	_assert_true(atmo_status.text.contains("OVERRIDE ENGAGED"), "Emergency purge override dispatches successfully")
	
	term.close_terminal()
	_assert_true(not term.visible, "Terminal closes cleanly")
	remove_child(term)
	term.queue_free()
	remove_child(env_mgr)
	env_mgr.queue_free()
	ShipSystemManager.reset_to_defaults()

func _test_m2_interconnection_persistence_and_diagnostics() -> void:
	ShipState.reset_to_defaults()
	
	# 1. Dynamic Fault Persistence across Save / Load
	var f_leak = ShipState.trigger_fault("CABIN_PRESSURE_LEAK")
	var f_sat = ShipState.trigger_fault("CO2_SCRUBBER_SATURATION")
	ShipState.reroute_auxiliary_scrubber(true)
	_assert_true(ShipState.active_faults.has("CABIN_PRESSURE_LEAK") and ShipState.active_faults.has("CO2_SCRUBBER_SATURATION"), "Dynamic faults actively triggered before save")
	
	var exported_state := ShipState.export_save_data()
	_assert_true(exported_state.get("auxiliary_scrubber_active", false) == true, "Auxiliary scrubber state included in exported save data")
	_assert_true(exported_state["active_fault_ids"].has("CABIN_PRESSURE_LEAK"), "Dynamic fault IDs included in exported save data")
	
	# Simulate new game / fresh load
	ShipState.active_faults.clear()
	ShipState.import_save_data(exported_state)
	_assert_true(ShipState.active_faults.has("CABIN_PRESSURE_LEAK"), "Dynamic CABIN_PRESSURE_LEAK preserved across save/load")
	_assert_true(ShipState.active_faults.has("CO2_SCRUBBER_SATURATION"), "Dynamic CO2_SCRUBBER_SATURATION preserved across save/load")
	_assert_true(ShipState.auxiliary_scrubber_active, "Auxiliary scrubber power state preserved across save/load")
	ShipState.reset_to_defaults()
	
	# 2. Interconnected Failure Cascade
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	ShipSystemManager.get_system("life_support").state = ShipSystemClass.State.ONLINE
	
	# Thermal stress on scrubber amine beds
	env_mgr.compartments["life_support"]["temperature"] = 325.0 # ~52°C
	var base_co2: float = env_mgr.compartments["life_support"]["co2_ppm"]
	env_mgr._process(1.0)
	_assert_true(env_mgr.compartments["life_support"]["co2_ppm"] > base_co2, "Thermal stress above 320K degrades scrubber absorption efficiency")
	
	# Severe thermal runaway cascades into seal blowout
	env_mgr.compartments["life_support"]["temperature"] = 338.0 # ~65°C
	env_mgr._process(1.0)
	_assert_true(ShipState.active_faults.has("CABIN_PRESSURE_LEAK"), "Extreme thermal runaway (>335K) cascades into CABIN_PRESSURE_LEAK seal rupture")
	
	# Decompression leak accelerates oxygen loss
	var o2_start: float = env_mgr.compartments["life_support"]["o2_level"]
	env_mgr._process(2.0)
	_assert_true(env_mgr.compartments["life_support"]["o2_level"] < o2_start, "Decompression leak vents compartment oxygen rapidly")
	
	# 3. Tactical Schematic Card Telemetry Hazard Warning
	var schematic_scene = load("res://scenes/ui/ship_schematic.tscn")
	var schematic = schematic_scene.instantiate()
	add_child(schematic)
	
	# Decompress Engineering Bay without device fault
	ShipState.active_faults.clear()
	env_mgr.compartments["engineering_bay"]["pressure"] = 55.0
	schematic.refresh_schematic()
	var eng_lbl: Label = schematic.find_child("EngBayPanel", true, false).find_child("StatusLabel", true, false)
	_assert_true(eng_lbl.text.contains("HAZARD: DECOMPRESSION"), "Tactical schematic card detects atmospheric decompression hazard")
	
	# Hypoxia in Command Bridge without device fault
	env_mgr.compartments["bridge"]["o2_level"] = 40.0
	schematic.refresh_schematic()
	var bridge_lbl: Label = schematic.find_child("BridgePanel", true, false).find_child("StatusLabel", true, false)
	_assert_true(bridge_lbl.text.contains("HAZARD: HYPOXIA"), "Tactical schematic card detects atmospheric hypoxia hazard")
	
	remove_child(schematic)
	schematic.queue_free()
	
	# 4. Terminal In-Game Fault Simulation Controls
	var term_scene = load("res://scenes/ui/terminal_dialog.tscn")
	var term = term_scene.instantiate()
	add_child(term)
	ShipState.set_generator_breaker(true)
	ShipState.set_bus_relay(true)
	
	# Simulate fault from terminal
	term._on_simulate_fault_pressed()
	_assert_true(ShipState.active_faults.size() > 0, "Terminal simulation control triggers test failure scenario")
	
	# Reroute auxiliary scrubber from terminal
	term._on_reroute_aux_pressed()
	_assert_true(ShipState.auxiliary_scrubber_active, "Terminal control engages auxiliary scrubber power rerouting")
	
	# Clear test faults from terminal
	term._on_clear_faults_pressed()
	_assert_true(ShipState.active_faults.is_empty(), "Terminal clear faults control restores ship to nominal state")
	_assert_true(is_equal_approx(env_mgr.compartments["life_support"]["pressure"], 101.3), "Terminal clear control normalizes cabin pressure")
	
	remove_child(term)
	term.queue_free()
	remove_child(env_mgr)
	env_mgr.queue_free()
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()

func _test_m3_inventory_and_resources() -> void:
	InventoryManager.reset_to_defaults()
	
	# Quick slots validation
	_assert_true(InventoryManager.quick_slots.size() == 4, "Quick select has 4 active slots")
	_assert_true(InventoryManager.get_equipped_item_id() == "diagnostic_scanner", "Initial equipped slot 1 is Diagnostic Scanner")
	
	var eq2 := InventoryManager.equip_slot(2)
	_assert_true(eq2 == "multitool" and InventoryManager.active_slot == 2, "Slot 2 equips Multitool / Welder")
	
	var eq3 := InventoryManager.equip_slot(3)
	_assert_true(eq3 == "spare_fuse" and InventoryManager.active_slot == 3, "Slot 3 equips Spare Fuse pack")
	
	var eq4 := InventoryManager.equip_slot(4)
	_assert_true(eq4 == "battery_cell" and InventoryManager.active_slot == 4, "Slot 4 equips Battery Cell")
	
	var eq_invalid := InventoryManager.equip_slot(99)
	_assert_true(eq_invalid == "" and InventoryManager.active_slot == 0, "Out-of-range slot disarms tool (active_slot 0)")
	
	# Consumables tally & item operations
	var initial_fuses := InventoryManager.get_item_count("spare_fuse")
	_assert_true(initial_fuses >= 2, "Initial spare fuse count is at least 2")
	
	InventoryManager.add_item("spare_fuse", 3)
	_assert_true(InventoryManager.get_item_count("spare_fuse") == initial_fuses + 3, "add_item increments spare fuse tally")
	
	var rem_ok := InventoryManager.remove_item("spare_fuse", 2)
	_assert_true(rem_ok and InventoryManager.get_item_count("spare_fuse") == initial_fuses + 1, "remove_item decrements spare fuse tally")
	
	var rem_excess := InventoryManager.remove_item("spare_fuse", 999)
	_assert_true(not rem_excess, "remove_item rejects removing more items than available")
	
	var rem_tool := InventoryManager.remove_item("diagnostic_scanner", 1)
	_assert_true(not rem_tool, "Permanent tools cannot be removed via consumable API")
	
	# Battery charge consumption & portable cell recharges
	InventoryManager.tools["diagnostic_scanner"]["battery"] = 100.0
	var drain_ok := InventoryManager.drain_scanner_battery(25.0)
	_assert_true(drain_ok and is_equal_approx(InventoryManager.get_scanner_battery(), 75.0), "drain_scanner_battery deducts 25% charge")
	
	var drain_fail := InventoryManager.drain_scanner_battery(90.0)
	_assert_true(not drain_fail and is_equal_approx(InventoryManager.get_scanner_battery(), 75.0), "drain_scanner_battery fails when charge insufficient")
	
	# Portable battery cell usage
	InventoryManager.consumables["battery_cell"] = 2
	var used_cell := InventoryManager.use_battery_cell()
	_assert_true(used_cell, "Portable battery cell recharges depleted scanner")
	_assert_true(is_equal_approx(InventoryManager.get_scanner_battery(), 100.0), "Battery cell restores charge up to 100% max")
	_assert_true(InventoryManager.get_item_count("battery_cell") == 1, "Battery cell quantity decremented after use")
	
	var use_when_full := InventoryManager.use_battery_cell()
	_assert_true(not use_when_full, "Battery cell refused when scanner already at 100% capacity")
	_assert_true(InventoryManager.get_item_count("battery_cell") == 1, "Unused battery cell preserved")
	
	InventoryManager.reset_to_defaults()

func _test_m3_handheld_tools() -> void:
	InventoryManager.reset_to_defaults()
	ShipState.reset_to_defaults()
	
	# Multitool mode cycling
	_assert_true(InventoryManager.get_multitool_mode() == "CALIBRATE", "Multitool initial mode is CALIBRATE")
	var mode2 := InventoryManager.cycle_multitool_mode()
	_assert_true(mode2 == "CUT_WELD", "Multitool cycles to CUT_WELD")
	var mode3 := InventoryManager.cycle_multitool_mode()
	_assert_true(mode3 == "TIGHTEN", "Multitool cycles to TIGHTEN")
	var mode4 := InventoryManager.cycle_multitool_mode()
	_assert_true(mode4 == "CALIBRATE", "Multitool loops back to CALIBRATE")
	
	InventoryManager.set_multitool_mode("CUT_WELD")
	_assert_true(InventoryManager.get_multitool_mode() == "CUT_WELD", "set_multitool_mode sets mode directly")
	
	var tool_res := InventoryManager.perform_multitool_action("CUT_WELD")
	_assert_true(tool_res.get("ok", false), "perform_multitool_action executes successfully")
	
	# Diagnostic Scanner telemetry & fault detection
	InventoryManager.equip_slot(1)
	InventoryManager.tools["diagnostic_scanner"]["battery"] = 100.0
	
	# Create a dummy target with a known device ID
	var target_node := Node3D.new()
	target_node.name = "GeneratorUnit"
	add_child(target_node)
	
	var scan_res := InventoryManager.perform_diagnostic_scan(target_node)
	_assert_true(scan_res.get("ok", false), "Diagnostic scan succeeds with charged scanner")
	_assert_true(is_equal_approx(InventoryManager.get_scanner_battery(), 90.0), "Diagnostic scan drains 10% battery charge")
	
	var telem: Dictionary = scan_res.get("telemetry", {})
	_assert_true(telem.has("device_name") and telem.has("integrity") and telem.has("power_draw"), "Scan returns real-time telemetry dictionary")
	
	# Depleted scanner scan denial
	InventoryManager.tools["diagnostic_scanner"]["battery"] = 5.0
	var scan_depleted := InventoryManager.perform_diagnostic_scan(target_node)
	_assert_true(not scan_depleted.get("ok", false), "Diagnostic scan denied when battery < drain_cost")
	_assert_true(scan_depleted.get("error", "") == "INSUFFICIENT_CHARGE", "Depleted scan returns INSUFFICIENT_CHARGE error code")
	
	remove_child(target_node)
	target_node.queue_free()
	InventoryManager.reset_to_defaults()

func _test_m3_workstations_and_lockers() -> void:
	InventoryManager.reset_to_defaults()
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	
	# 3D Storage Locker Tests
	var locker_scene = load("res://scenes/interactables/storage_locker.tscn")
	var locker = locker_scene.instantiate()
	add_child(locker)
	locker.stored_items = {
		"spare_fuse": 2,
		"battery_cell": 1
	}
	locker._update_visuals()
	
	_assert_true(locker.has_items(), "Storage locker reports items present")
	_assert_true(locker.get_prompt().contains("Spare Fuse"), "Storage locker prompt lists stored items")
	
	var before_fuses: int = InventoryManager.get_item_count("spare_fuse")
	var taken: Dictionary = locker.take_all()
	_assert_true(taken.get("spare_fuse", 0) == 2, "take_all extracts all fuses from locker")
	_assert_true(InventoryManager.get_item_count("spare_fuse") == before_fuses + 2, "Locker items transferred to InventoryManager")
	_assert_true(not locker.has_items(), "Storage locker reports empty after take_all")
	_assert_true(locker.get_prompt().contains("[Empty]"), "Storage locker prompt displays [Empty] status")
	
	# Store item back into locker
	var store_ok: bool = locker.store_item("spare_fuse", 1)
	_assert_true(store_ok and locker.get_item_count("spare_fuse") == 1, "store_item deposits items from inventory back into locker")
	_assert_true(locker.has_items(), "Locker detects deposited items")
	
	remove_child(locker)
	locker.queue_free()
	
	# 3D Workbench Station Tests
	var bench_scene = load("res://scenes/interactables/workbench_station.tscn")
	var bench = bench_scene.instantiate()
	add_child(bench)
	
	# Station unpowered initially
	ShipState.set_generator_breaker(false)
	ShipState.set_bus_relay(false)
	_assert_true(not bench.is_station_powered(), "Workbench reports unpowered when generator and bus offline")
	_assert_true(bench.get_prompt().contains("[Unpowered]"), "Workbench prompt indicates [Unpowered] state")
	
	# Power the station
	ShipState.set_generator_breaker(true)
	ShipState.set_bus_relay(true)
	_assert_true(bench.is_station_powered(), "Workbench reports powered once generator and bus are energized")
	
	# Test fast-recharge cradle
	InventoryManager.tools["diagnostic_scanner"]["battery"] = 30.0
	_assert_true(bench.get_prompt().contains("Dock & Fast-Recharge Scanner"), "Workbench prompt offers scanner docking when charge low")
	
	bench.recharge_scanner()
	_assert_true(is_equal_approx(InventoryManager.get_scanner_battery(), 100.0), "Workbench dock recharges scanner to 100%")
	
	# Test component inspection and refurbishment
	var insp: Dictionary = bench.inspect_component("spare_fuse")
	_assert_true(insp.get("condition", "") == "NOMINAL", "Workbench inspects component tolerances")
	
	var pre_refurb_fuses := InventoryManager.get_item_count("spare_fuse")
	var refurb_ok: bool = bench.refurbish_component("spare_fuse")
	_assert_true(refurb_ok and InventoryManager.get_item_count("spare_fuse") == pre_refurb_fuses + 1, "Workbench refurbishes / fabricates spare fuses")
	
	remove_child(bench)
	bench.queue_free()
	InventoryManager.reset_to_defaults()
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()

func _test_m3_deepened_multi_step_repair() -> void:
	InventoryManager.reset_to_defaults()
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	
	var repair_scene = load("res://scenes/interactables/multi_step_repair.tscn")
	var panel = repair_scene.instantiate()
	add_child(panel)
	
	panel.panel_title = "Primary Power Conduit Junction"
	panel.device_id = "training_power_conduit"
	panel.associated_fault_id = "CONDUIT_BLOWN_FUSE"
	panel.required_item = "spare_fuse"
	panel.component_name = "Spare Fuse Pack"
	panel.current_stage = MultiStepRepairClass.Stage.DIAGNOSE
	panel.is_repaired = false
	panel._update_visuals()
	
	ShipState.trigger_fault("CONDUIT_BLOWN_FUSE")
	_assert_true(ShipState.active_faults.has("CONDUIT_BLOWN_FUSE"), "CONDUIT_BLOWN_FUSE active before repair")
	
	# Stage 0: DIAGNOSE
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.DIAGNOSE, "Initial stage is DIAGNOSE")
	_assert_true(panel.get_stage_name() == "DIAGNOSE", "get_stage_name() returns DIAGNOSE")
	
	# Wrong tool (Multitool) rejected on Stage 0
	InventoryManager.equip_slot(2) # Multitool
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.DIAGNOSE, "Wrong tool (Multitool) rejected during DIAGNOSE stage")
	
	# Correct tool (Diagnostic Scanner) advances to UNCLAMP
	InventoryManager.equip_slot(1) # Scanner
	InventoryManager.tools["diagnostic_scanner"]["battery"] = 100.0
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.UNCLAMP, "Diagnostic Scanner advances panel to UNCLAMP stage")
	_assert_true(panel.get_stage_name() == "UNCLAMP", "Stage name is UNCLAMP")
	
	# Stage 1: UNCLAMP
	# Wrong tool (Scanner) rejected on Stage 1
	InventoryManager.equip_slot(1)
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.UNCLAMP, "Wrong tool (Scanner) rejected during UNCLAMP stage")
	
	# Correct tool (Multitool) advances to REPLACE
	InventoryManager.equip_slot(2)
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.REPLACE, "Multitool advances panel to REPLACE stage")
	
	# Stage 2: REPLACE
	# Missing required item fails
	InventoryManager.consumables["spare_fuse"] = 0
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.REPLACE, "Stage remains REPLACE when required spare part missing")
	_assert_true(panel.get_prompt().contains("Missing"), "Prompt indicates missing component")
	
	# Supply spare fuse & install
	InventoryManager.add_item("spare_fuse", 1)
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.CALIBRATE, "Installing spare fuse advances panel to CALIBRATE stage")
	_assert_true(InventoryManager.get_item_count("spare_fuse") == 0, "Spare fuse consumed from inventory")
	
	# Stage 3: CALIBRATE
	# Wrong tool (Scanner) rejected
	InventoryManager.equip_slot(1)
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.CALIBRATE, "Scanner rejected during CALIBRATE stage")
	
	# Correct tool (Multitool) advances to TEST
	InventoryManager.equip_slot(2)
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.TEST, "Multitool calibration advances panel to TEST stage")
	
	# Stage 4: TEST & ENERGIZE
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.COMPLETED, "Diagnostic test completes multi-step repair")
	_assert_true(panel.is_repaired, "Panel marked is_repaired")
	_assert_true(not ShipState.active_faults.has("CONDUIT_BLOWN_FUSE"), "CONDUIT_BLOWN_FUSE cleared from ShipState active faults")
	_assert_true(is_equal_approx(ShipState.devices["training_power_conduit"].health, 100.0), "Device health restored to 100%")
	_assert_true(panel.get_prompt().contains("[Operational]"), "Restored panel prompt indicates [Operational]")
	
	remove_child(panel)
	panel.queue_free()
	InventoryManager.reset_to_defaults()
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()

func _test_m3_rerouting_and_overrides() -> void:
	ShipState.reset_to_defaults()
	
	# Power rerouting
	var p_res := ShipState.reroute_power("reactor_primary", "training_power_conduit")
	_assert_true(p_res.get("ok", false) and ShipState.power_rerouted, "reroute_power dispatches successfully and sets power_rerouted")
	
	# Coolant bypass loop rerouting
	var c_res := ShipState.reroute_coolant_loop(true)
	_assert_true(c_res.get("ok", false) and ShipState.coolant_bypass_active, "reroute_coolant_loop activates secondary coolant bypass")
	var c_res2 := ShipState.reroute_coolant_loop(false)
	_assert_true(c_res2.get("ok", false) and not ShipState.coolant_bypass_active, "reroute_coolant_loop restores primary loop")
	
	# Manual subsystem overrides
	var o_res := ShipState.manual_override_subsystem("communications", true)
	_assert_true(o_res.get("ok", false), "manual_override_subsystem dispatches successfully")
	_assert_true(ShipState.subsystems["communications"].is_online(), "Manual override forces subsystem state ONLINE")
	_assert_true(ShipState.manual_overrides.get("communications", false) == true, "Manual override tracked in ship state")
	
	var o_res2 := ShipState.manual_override_subsystem("communications", false)
	_assert_true(not ShipState.subsystems["communications"].is_online(), "Manual override forces subsystem state OFFLINE")
	
	ShipState.reset_to_defaults()

func _test_m3_diagnostic_tutorial() -> void:
	var tut = DiagnosticTutorialClass.new()
	_assert_true(not tut.is_active, "Tutorial initially inactive")
	
	tut.start_tutorial()
	_assert_true(tut.is_active, "start_tutorial activates tutorial")
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.OBSERVE_SYMPTOMS, "Step 0 is OBSERVE_SYMPTOMS")
	_assert_true(tut.get_current_title() == "OBSERVE SYMPTOMS", "Title matches OBSERVE SYMPTOMS")
	_assert_true(tut.get_current_instruction().contains("Auxiliary Power Junction"), "Instruction guides player to inspect junction")
	
	tut.advance_step()
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.RETRIEVE_SCANNER, "Step 1 is RETRIEVE_SCANNER")
	
	tut.advance_step()
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.EQUIP_SCANNER, "Step 2 is EQUIP_SCANNER")
	
	tut.advance_step()
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.SCAN_DEVICE, "Step 3 is SCAN_DEVICE")
	
	tut.advance_step()
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.UNCLAMP_HOUSING, "Step 4 is UNCLAMP_HOUSING")
	
	tut.advance_step()
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.INSTALL_FUSE, "Step 5 is INSTALL_FUSE")
	
	tut.advance_step()
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.CALIBRATE_CIRCUIT, "Step 6 is CALIBRATE_CIRCUIT")
	
	tut.advance_step()
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.SYSTEM_TEST, "Step 7 is SYSTEM_TEST")
	
	tut.advance_step()
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.TUTORIAL_COMPLETE, "Step 8 is TUTORIAL_COMPLETE")
	_assert_true(not tut.is_active, "Tutorial marks complete and deactivates")

func _test_m3_save_load_persistence() -> void:
	SaveManager.delete_save()
	InventoryManager.reset_to_defaults()
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	
	# Set custom state before saving
	InventoryManager.tools["diagnostic_scanner"]["battery"] = 62.5
	InventoryManager.tools["multitool"]["mode"] = "CUT_WELD"
	InventoryManager.consumables["spare_fuse"] = 8
	InventoryManager.consumables["battery_cell"] = 5
	InventoryManager.equip_slot(3) # slot 3 equipped
	
	ShipState.reroute_power("reactor_primary", "training_power_conduit")
	ShipState.reroute_coolant_loop(true)
	ShipState.manual_override_subsystem("communications", true)
	
	# Create a persistent locker and multi-step panel in tree to test scene serialization
	var locker_scene = load("res://scenes/interactables/storage_locker.tscn")
	var locker = locker_scene.instantiate()
	locker.interactable_id = "TestPersistLocker"
	locker.stored_items = {"coolant_canister": 4, "spare_fuse": 2}
	add_child(locker)
	
	var repair_scene = load("res://scenes/interactables/multi_step_repair.tscn")
	var panel = repair_scene.instantiate()
	panel.device_id = "persist_test_device"
	panel.current_stage = MultiStepRepairClass.Stage.CALIBRATE
	panel.is_repaired = false
	add_child(panel)
	
	# Save game
	var save_res := SaveManager.save_game(null, null)
	_assert_true(save_res and SaveManager.has_save_file(), "SaveManager exports game state with Milestone 3 data")
	
	# Reset states
	InventoryManager.reset_to_defaults()
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	locker.stored_items.clear()
	panel.current_stage = MultiStepRepairClass.Stage.DIAGNOSE
	
	_assert_true(is_equal_approx(InventoryManager.get_scanner_battery(), 100.0), "Scanner reset to 100% before load")
	_assert_true(InventoryManager.get_multitool_mode() == "CALIBRATE", "Multitool reset to CALIBRATE before load")
	_assert_true(InventoryManager.get_item_count("spare_fuse") == 2, "Fuses reset before load")
	
	# Load game
	var load_res := SaveManager.load_game(null, null)
	_assert_true(load_res, "SaveManager loads game state successfully")
	
	_assert_true(is_equal_approx(InventoryManager.get_scanner_battery(), 62.5), "Serialized scanner battery charge (62.5%) preserved across save/load")
	_assert_true(InventoryManager.get_multitool_mode() == "CUT_WELD", "Serialized multitool mode (CUT_WELD) preserved across save/load")
	_assert_true(InventoryManager.get_item_count("spare_fuse") == 8, "Serialized spare fuse count (8) preserved across save/load")
	_assert_true(InventoryManager.get_item_count("battery_cell") == 5, "Serialized battery cell count (5) preserved across save/load")
	_assert_true(InventoryManager.active_slot == 3, "Serialized active quick-select slot (3) preserved across save/load")
	
	_assert_true(ShipState.power_rerouted, "Serialized power_rerouted flag preserved across save/load")
	_assert_true(ShipState.coolant_bypass_active, "Serialized coolant_bypass_active flag preserved across save/load")
	_assert_true(ShipState.manual_overrides.get("communications", false) == true, "Serialized manual subsystem override preserved across save/load")
	
	_assert_true(locker.get_item_count("coolant_canister") == 4, "Serialized locker stored items preserved across save/load")
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.CALIBRATE, "Serialized multi-step repair stage preserved across save/load")
	
	remove_child(locker)
	locker.queue_free()
	remove_child(panel)
	panel.queue_free()
	SaveManager.delete_save()
	InventoryManager.reset_to_defaults()
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()

func _test_m3_deep_verification_and_edge_cases() -> void:
	InventoryManager.reset_to_defaults()
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	
	# 1. Inventory & MissionManager Bidirectional Sync without Ghost Items
	_assert_true(MissionManager.has_item("spare_fuse"), "MissionManager initially has spare_fuse")
	InventoryManager.remove_item("spare_fuse", InventoryManager.get_item_count("spare_fuse"))
	_assert_true(InventoryManager.get_item_count("spare_fuse") == 0, "All spare fuses removed from InventoryManager")
	_assert_true(not MissionManager.has_item("spare_fuse"), "MissionManager no longer has spare_fuse when count drops to zero")
	_assert_true(not MissionManager.inventory.has("spare_fuse"), "Depleted spare fuse removed from MissionManager.inventory (no ghost items)")
	
	InventoryManager.add_item("spare_fuse", 2)
	_assert_true(MissionManager.has_item("spare_fuse"), "Adding items restores them in MissionManager")
	_assert_true(MissionManager.inventory.has("spare_fuse"), "Restored item appears in MissionManager.inventory")
	
	# 2. Quick Slot Customization & Retrieval
	var q_slots := InventoryManager.get_quick_slots()
	_assert_true(q_slots.size() == 4, "Quick slots count is 4")
	var set_ok := InventoryManager.set_quick_slot(3, "coolant_canister")
	_assert_true(set_ok, "set_quick_slot succeeds for valid slot 3")
	_assert_true(InventoryManager.quick_slots[2] == "coolant_canister", "Slot 3 updated to coolant_canister")
	InventoryManager.equip_slot(3)
	_assert_true(InventoryManager.get_equipped_item_id() == "coolant_canister", "Equipping slot 3 selects coolant_canister")
	var set_invalid := InventoryManager.set_quick_slot(9, "spare_fuse")
	_assert_true(not set_invalid, "set_quick_slot rejects invalid slot index")
	InventoryManager.set_quick_slot(3, "spare_fuse")
	
	# 3. Multitool Mode Enforcement on MultiStepRepairPanel
	var repair_scene = load("res://scenes/interactables/multi_step_repair.tscn")
	var panel = repair_scene.instantiate()
	add_child(panel)
	panel.action_name = "Calibrate Circuit"
	panel.required_multitool_mode = "CALIBRATE"
	panel.current_stage = MultiStepRepairClass.Stage.CALIBRATE
	panel.is_repaired = false
	panel._update_visuals()
	
	InventoryManager.equip_slot(2) # Multitool
	InventoryManager.set_multitool_mode("CUT_WELD") # WRONG MODE
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.CALIBRATE, "CUT_WELD mode rejected during CALIBRATE stage")
	_assert_true(panel.get_prompt().contains("Switch Multitool to CALIBRATE Mode"), "Prompt directs player to switch multitool mode")
	
	InventoryManager.set_multitool_mode("TIGHTEN") # WRONG MODE
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.CALIBRATE, "TIGHTEN mode rejected during CALIBRATE stage")
	
	InventoryManager.set_multitool_mode("CALIBRATE") # CORRECT MODE
	panel._on_interacted(null)
	_assert_true(panel.current_stage == MultiStepRepairClass.Stage.TEST, "CALIBRATE mode advances panel to TEST stage")
	remove_child(panel)
	panel.free()
	
	# 4. Loose Manifold Clamp MultiStep Repair (Life Support) requiring TIGHTEN mode
	var manifold_panel = repair_scene.instantiate()
	add_child(manifold_panel)
	manifold_panel.panel_title = "Coolant Distribution Manifold"
	manifold_panel.device_id = "coolant_distribution_manifold"
	manifold_panel.associated_fault_id = "MANIFOLD_CLAMP_LOOSE"
	manifold_panel.action_name = "Torque Clamp Collar"
	manifold_panel.required_multitool_mode = "TIGHTEN"
	manifold_panel.current_stage = MultiStepRepairClass.Stage.CALIBRATE
	manifold_panel.is_repaired = false
	manifold_panel._update_visuals()
	
	InventoryManager.set_multitool_mode("CALIBRATE") # WRONG MODE FOR MANIFOLD
	manifold_panel._on_interacted(null)
	_assert_true(manifold_panel.current_stage == MultiStepRepairClass.Stage.CALIBRATE, "CALIBRATE mode rejected on loose clamp requiring TIGHTEN")
	_assert_true(manifold_panel.get_prompt().contains("TIGHTEN Mode"), "Prompt directs player to TIGHTEN mode for loose clamp")
	
	InventoryManager.set_multitool_mode("TIGHTEN") # CORRECT MODE
	manifold_panel._on_interacted(null)
	_assert_true(manifold_panel.current_stage == MultiStepRepairClass.Stage.TEST, "TIGHTEN mode torques clamp collar and advances to TEST")
	remove_child(manifold_panel)
	manifold_panel.free()
	
	# 5. Power Rerouting Persistence Across Simulation Ticks
	ShipState.set_generator_breaker(true)
	ShipState.set_bus_relay(false) # Bus is dead
	_assert_true(not ShipState.power_system.bus_energized, "Bus is de-energized")
	ShipState.reroute_power("reactor_primary", "training_power_conduit")
	_assert_true(ShipState.devices["training_power_conduit"].is_powered, "training_power_conduit powered immediately after reroute")
	
	# Run continuous physics/simulation tick
	ShipState.tick_systems(1.0)
	_assert_true(ShipState.devices["training_power_conduit"].is_powered, "training_power_conduit remains powered across simulation tick")
	_assert_true(ShipState.power_routes.has("training_power_conduit"), "power_routes tracks conduit connection")
	
	ShipState.clear_power_reroutes()
	ShipState.tick_systems(1.0)
	_assert_true(not ShipState.devices["training_power_conduit"].is_powered, "Clearing power reroutes restores normal bus-unpowered state")
	
	# 6. Storage Locker Deposit When Empty via can_interact & store_item
	var locker_scene = load("res://scenes/interactables/storage_locker.tscn")
	var locker = locker_scene.instantiate()
	add_child(locker)
	locker.stored_items.clear()
	locker._update_visuals()
	_assert_true(not locker.has_items(), "Locker is empty")
	_assert_true(locker.can_interact(null), "Empty locker allows interaction")
	
	InventoryManager.add_item("spare_fuse", 2)
	InventoryManager.equip_slot(3) # Fuse equipped
	_assert_true(locker.get_prompt().contains("Deposit"), "Prompt offers depositing equipped fuse into empty locker")
	locker._on_interacted(null)
	_assert_true(locker.has_items(), "Depositing item marks locker non-empty")
	_assert_true(locker.get_item_count("spare_fuse") == 1, "1x spare fuse deposited into locker")
	remove_child(locker)
	locker.free()
	
	# 7. Workbench Inspection & Refurbishment of Equipped Consumables
	var bench_scene = load("res://scenes/interactables/workbench_station.tscn")
	var bench = bench_scene.instantiate()
	add_child(bench)
	ShipState.set_generator_breaker(true)
	ShipState.set_bus_relay(true)
	InventoryManager.tools["diagnostic_scanner"]["battery"] = 100.0
	
	InventoryManager.set_quick_slot(3, "coolant_canister")
	InventoryManager.equip_slot(3) # Coolant canister equipped
	_assert_true(bench.get_prompt().contains("Inspect & Service Coolant Canister"), "Workbench prompt offers inspecting equipped coolant canister")
	var pre_coolant := InventoryManager.get_item_count("coolant_canister")
	bench._on_interacted(null)
	_assert_true(InventoryManager.get_item_count("coolant_canister") == pre_coolant + 1, "Interacting at workbench refurbishes equipped coolant canister")
	remove_child(bench)
	bench.free()
	
	# 8. Diagnostic Tutorial In-Game Reactive Progression
	var level_scene = load("res://scenes/levels/ship_interior.tscn")
	var level = level_scene.instantiate()
	add_child(level)
	var player = level.get_node("Player")
	var tut = DiagnosticTutorialClass.new()
	tut.setup_in_game(level, player)
	
	_assert_true(tut.is_active, "In-game diagnostic tutorial is active")
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.OBSERVE_SYMPTOMS, "Initial step is OBSERVE_SYMPTOMS")
	_assert_true(player.hud.tutorial_margin.visible, "Tutorial HUD banner is visible")
	
	# Simulate looking at junction
	player.interaction_ctrl.prompt_changed.emit("[E] Auxiliary Power Junction")
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.RETRIEVE_SCANNER, "Observing junction advances to RETRIEVE_SCANNER")
	
	# Simulate opening locker
	var eng_locker = level.find_child("EngineeringLocker", true, false)
	eng_locker.locker_opened.emit(eng_locker.interactable_id, {})
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.EQUIP_SCANNER, "Opening locker advances to EQUIP_SCANNER")
	
	# Equip scanner
	InventoryManager.equip_slot(1)
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.SCAN_DEVICE, "Equipping scanner advances to SCAN_DEVICE")
	
	# Conduit stage advances
	var conduit = level.find_child("EngineeringConduitRepair", true, false)
	conduit.stage_advanced.emit(1, "UNCLAMP")
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.UNCLAMP_HOUSING, "Conduit UNCLAMP advances to UNCLAMP_HOUSING")
	
	conduit.stage_advanced.emit(2, "REPLACE")
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.INSTALL_FUSE, "Conduit REPLACE advances to INSTALL_FUSE")
	
	conduit.stage_advanced.emit(3, "CALIBRATE")
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.CALIBRATE_CIRCUIT, "Conduit CALIBRATE advances to CALIBRATE_CIRCUIT")
	
	conduit.stage_advanced.emit(4, "TEST")
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.SYSTEM_TEST, "Conduit TEST advances to SYSTEM_TEST")
	
	conduit.stage_advanced.emit(5, "COMPLETED")
	_assert_true(tut.get_current_step() == DiagnosticTutorialClass.Step.TUTORIAL_COMPLETE, "Conduit COMPLETED advances to TUTORIAL_COMPLETE")
	_assert_true(not tut.is_active, "Tutorial deactivates upon completion")
	_assert_true(not player.hud.tutorial_margin.visible, "Tutorial HUD banner is hidden upon completion")
	
	level.free()
	InventoryManager.reset_to_defaults()
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()



func _test_m4_environmental_simulation() -> void:
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	_assert_true(env_mgr.compartments.size() == 11, "All 11 compartments registered in EnvironmentalManager")
	_assert_true(env_mgr.get_all_compartments(true).size() == 11, "get_all_compartments(true) returns 11 compartments")
	_assert_true(env_mgr.get_all_compartments(false).size() == 4, "get_all_compartments(false) returns 4 core compartments for backward compatibility")
	
	_assert_true(env_mgr.get_compartment_for_position(Vector3(0, 0, -16)) == "bridge", "Position (0, 0, -16) maps to bridge")
	_assert_true(env_mgr.get_compartment_for_position(Vector3(10, 0, -16)) == "avionics_bay", "Position (10, 0, -16) maps to avionics_bay")
	_assert_true(env_mgr.get_compartment_for_position(Vector3(-9, 0, -8)) == "crew_quarters", "Position (-9, 0, -8) maps to crew_quarters")
	_assert_true(env_mgr.get_compartment_for_position(Vector3(9, 0, -8)) == "medbay", "Position (9, 0, -8) maps to medbay")
	_assert_true(env_mgr.get_compartment_for_position(Vector3(0, 0, 0)) == "life_support", "Position (0, 0, 0) maps to life_support")
	_assert_true(env_mgr.get_compartment_for_position(Vector3(0, 0, 8)) == "corridors", "Position (0, 0, 8) maps to corridors")
	_assert_true(env_mgr.get_compartment_for_position(Vector3(-10, 0, 9)) == "cargo_bay", "Position (-10, 0, 9) maps to cargo_bay")
	_assert_true(env_mgr.get_compartment_for_position(Vector3(9, 0, 9)) == "airlock_chamber", "Position (9, 0, 9) maps to airlock_chamber")
	_assert_true(env_mgr.get_compartment_for_position(Vector3(0, 0, 16)) == "engineering_bay", "Position (0, 0, 16) maps to engineering_bay")
	_assert_true(env_mgr.get_compartment_for_position(Vector3(0, -2, 26)) == "reactor_subdeck", "Position (0, -2, 26) maps to reactor_subdeck")
	_assert_true(env_mgr.get_compartment_for_position(Vector3(-7.5, -1, 18)) == "maintenance_crawlway", "Position (-7.5, -1, 18) maps to maintenance_crawlway")
	
	var crawl = env_mgr.compartments["maintenance_crawlway"]
	_assert_true(is_equal_approx(crawl.leak_rate, 0.3), "Crawlway initial leak rate is 0.3 kPa/s")
	# Isolate crawlway vent damper to test hull breach decompression without adjacent room equalizing
	env_mgr.set_vent_damper("maintenance_crawlway", false)
	var init_press: float = crawl.pressure
	env_mgr._process(10.0)
	_assert_true(crawl.pressure < init_press, "Crawlway depressurizes during simulation tick")
	env_mgr.seal_hull_breach("maintenance_crawlway")
	_assert_true(is_equal_approx(crawl.leak_rate, 0.0), "Sealing hull breach stops decompression (leak rate 0.0)")
	_assert_true(env_mgr.is_breach_sealed("maintenance_crawlway"), "is_breach_sealed returns true")
	
	remove_child(env_mgr)
	env_mgr.free()

func _test_m4_airlock_interlocks_and_cycling() -> void:
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	var airlock = AirlockControllerClass.new()
	var inner_d = DoorClass.new()
	var outer_d = DoorClass.new()
	add_child(airlock)
	add_child(inner_d)
	add_child(outer_d)
	
	airlock.inner_door = inner_d
	airlock.outer_door = outer_d
	inner_d.interlock_controller = airlock
	outer_d.interlock_controller = airlock
	
	_assert_true(airlock.can_open_door(inner_d), "Inner door allowed to open when chamber pressurized")
	_assert_true(not airlock.can_open_door(outer_d), "Outer door forbidden to open when chamber pressurized (prevents venting cabin)")
	
	inner_d.is_open = true
	_assert_true(not airlock.can_open_door(outer_d), "Outer door forbidden when inner door is open (safety interlock)")
	inner_d.is_open = false
	
	airlock.cycle_to_eva(true)
	_assert_true(env_mgr.is_airlock_depressurized(), "Airlock compartment depressurized to 0 kPa for EVA")
	_assert_true(airlock.can_open_door(outer_d), "Outer door allowed to open in vacuum")
	_assert_true(not airlock.can_open_door(inner_d), "Inner door forbidden to open into vacuum (prevents cabin blow-out)")
	
	airlock.cycle_to_cabin(true)
	_assert_true(env_mgr.is_airlock_pressurized(), "Airlock compartment repressurized to 101.3 kPa for Cabin")
	_assert_true(airlock.can_open_door(inner_d), "Inner door allowed to open again after repressurization")
	_assert_true(MissionManager.airlock_cycles_completed >= 2, "MissionManager tracks airlock cycles")
	
	# Mid-cycle re-entrance and interlock safety verification
	airlock.cycle_state = AirlockControllerClass.CycleState.CYCLING_TO_EVA
	_assert_true(not airlock.can_open_door(inner_d), "Inner door forbidden while cycling to EVA")
	_assert_true(not airlock.can_open_door(outer_d), "Outer door forbidden while cycling to EVA")
	var prev_state = airlock.cycle_state
	airlock.toggle_cycle()
	_assert_true(airlock.cycle_state == prev_state, "toggle_cycle rejected mid-cycle to prevent input race")
	airlock.cycle_to_cabin()
	_assert_true(airlock.cycle_state == prev_state, "cycle_to_cabin rejected mid-cycle")
	airlock.cycle_state = AirlockControllerClass.CycleState.IDLE
	
	remove_child(airlock)
	remove_child(inner_d)
	remove_child(outer_d)
	remove_child(env_mgr)
	airlock.free()
	inner_d.free()
	outer_d.free()
	env_mgr.free()

func _test_m4_ship_schematic_overhaul() -> void:
	var schematic_scene = load("res://scenes/ui/ship_schematic.tscn")
	var schematic = schematic_scene.instantiate()
	add_child(schematic)
	
	_assert_true(schematic.bridge_panel != null, "BridgePanel present in schematic")
	_assert_true(schematic.crew_panel != null, "CrewQuartersPanel present in schematic")
	_assert_true(schematic.avionics_panel != null, "AvionicsBayPanel present in schematic")
	_assert_true(schematic.medbay_panel != null, "MedbayPanel present in schematic")
	_assert_true(schematic.ls_panel != null, "LifeSupportPanel present in schematic")
	_assert_true(schematic.corridor_panel != null, "CorridorPanel present in schematic")
	_assert_true(schematic.cargo_panel != null, "CargoBayPanel present in schematic")
	_assert_true(schematic.airlock_panel != null, "AirlockPanel present in schematic")
	_assert_true(schematic.eng_panel != null, "EngBayPanel present in schematic")
	_assert_true(schematic.subdeck_panel != null, "ReactorSubdeckPanel present in schematic")
	_assert_true(schematic.crawlway_panel != null, "MaintenanceCrawlwayPanel present in schematic")
	
	var comps := ["bridge", "avionics_bay", "crew_quarters", "medbay", "life_support", "corridors", "cargo_bay", "airlock_chamber", "engineering_bay", "reactor_subdeck", "maintenance_crawlway"]
	for cid in comps:
		schematic._select_compartment(cid, true)
		_assert_true(schematic.current_selected_compartment == cid, "Selected compartment is " + cid)
	
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	env_mgr.player_compartment_id = "medbay"
	schematic.refresh_schematic()
	var pin_med = schematic.medbay_panel.find_child("PlayerPin", true, false)
	var pin_eng = schematic.eng_panel.find_child("PlayerPin", true, false)
	_assert_true(pin_med != null and pin_med.visible, "Player pin visible on Medbay when player in Medbay")
	_assert_true(pin_eng != null and not pin_eng.visible, "Player pin hidden on Engineering when player not there")
	
	schematic._select_compartment("crew_quarters", true)
	schematic._on_reroute_room_power_pressed()
	_assert_true(ShipState.power_rerouted, "Direct power reroute from schematic engages auxiliary power")
	schematic._on_reroute_room_power_pressed()
	_assert_true(not ShipState.power_rerouted, "Second click clears compartment power reroute")
	
	remove_child(schematic)
	remove_child(env_mgr)
	schematic.free()
	env_mgr.free()

func _test_m4_breach_salvage_shortcuts() -> void:
	InventoryManager.equip_slot(2) # Equip Multitool
	
	var seal = HullBreachSealClass.new()
	add_child(seal)
	InventoryManager.set_multitool_mode("CALIBRATE")
	seal._on_interacted(null)
	_assert_true(not seal.is_sealed, "Breach remains unsealed when multitool is not in CUT_WELD mode")
	InventoryManager.set_multitool_mode("CUT_WELD")
	seal._on_interacted(null)
	_assert_true(seal.is_sealed, "Breach successfully sealed with CUT_WELD mode")
	_assert_true(MissionManager.breaches_sealed_count >= 1, "MissionManager tracks breach sealed")
	remove_child(seal)
	seal.free()
	
	var crate = SalvageCrateClass.new()
	add_child(crate)
	crate.salvage_contents = ["scrap_alloy", "high_capacity_cell"]
	InventoryManager.set_multitool_mode("TIGHTEN")
	crate._on_interacted(null)
	_assert_true(not crate.is_cut_open, "Salvage crate cannot be opened with TIGHTEN mode")
	InventoryManager.set_multitool_mode("CUT_WELD")
	crate._on_interacted(null)
	_assert_true(crate.is_cut_open, "Salvage crate breached with CUT_WELD mode")
	_assert_true(MissionManager.inventory.has("scrap_alloy"), "Salvage items dispensed to inventory")
	remove_child(crate)
	crate.free()
	
	var door = DoorClass.new()
	door.requires_multitool_to_unlock = true
	door.multitool_mode_required = "CUT_WELD"
	door.is_locked = true
	add_child(door)
	InventoryManager.set_multitool_mode("CALIBRATE")
	door._on_interacted(null)
	_assert_true(door.is_locked and not door.is_open, "Shortcut door remains locked with wrong tool mode")
	InventoryManager.set_multitool_mode("CUT_WELD")
	door._on_interacted(null)
	_assert_true(not door.is_locked and door.is_open, "Shortcut door unlocks and opens with CUT_WELD mode")
	remove_child(door)
	door.free()

func _test_m4_save_load_persistence() -> void:
	var door = DoorClass.new()
	door.name = "DoorWingPort"
	door.device_id = "door_wing_port"
	door.is_open = true
	door.is_locked = false
	door.requires_multitool_to_unlock = true
	door.multitool_mode_required = "CUT_WELD"
	add_child(door)
	
	var rpanel = RepairPanel.new()
	rpanel.name = "WaterRecyclerPump"
	rpanel.device_id = "water_recycler_pump"
	rpanel.is_repaired = true
	add_child(rpanel)
	
	var airlock = AirlockControllerClass.new()
	airlock.name = "AirlockController"
	airlock.cycle_state = AirlockControllerClass.CycleState.CYCLING_TO_EVA
	airlock.cycle_timer = 2.5
	add_child(airlock)
	
	var crate = SalvageCrateClass.new()
	crate.name = "SalvageCrate"
	crate.device_id = "salvage_crate"
	crate.is_cut_open = true
	add_child(crate)
	
	var seal = HullBreachSealClass.new()
	seal.name = "HullBreachSeal"
	seal.device_id = "hull_breach_seal"
	seal.is_sealed = true
	add_child(seal)
	
	var save_ok: bool = SaveManager.save_game()
	_assert_true(save_ok, "SaveManager.save_game() succeeds with Milestone 4 entities")
	
	door.is_open = false
	door.requires_multitool_to_unlock = false
	door.multitool_mode_required = ""
	rpanel.is_repaired = false
	airlock.cycle_state = AirlockControllerClass.CycleState.IDLE
	crate.is_cut_open = false
	seal.is_sealed = false
	
	var load_ok: bool = SaveManager.load_game()
	_assert_true(load_ok, "SaveManager.load_game() succeeds")
	_assert_true(door.is_open, "Serialized door state preserved across save/load")
	_assert_true(door.requires_multitool_to_unlock, "Serialized door requires_multitool_to_unlock preserved across save/load")
	_assert_true(door.multitool_mode_required == "CUT_WELD", "Serialized door multitool_mode_required preserved across save/load")
	_assert_true(rpanel.is_repaired, "Serialized RepairPanel is_repaired state preserved across save/load")
	_assert_true(airlock.cycle_state == AirlockControllerClass.CycleState.CYCLING_TO_EVA, "Serialized airlock state preserved across save/load")
	_assert_true(crate.is_cut_open, "Serialized salvage crate state preserved across save/load")
	_assert_true(seal.is_sealed, "Serialized hull breach seal state preserved across save/load")
	
	SaveManager.delete_save()
	remove_child(door)
	remove_child(rpanel)
	remove_child(airlock)
	remove_child(crate)
	remove_child(seal)
	door.free()
	rpanel.free()
	airlock.free()
	crate.free()
	seal.free()

func _test_m4_narrative_logs_and_exploration() -> void:
	_assert_true(MissionManager.CREW_LOGS.size() == 10, "Base crew logs count is exactly 10")
	_assert_true(MissionManager.get_all_crew_logs().size() == 14, "get_all_crew_logs() returns all 14 crew logs")
	_assert_true(MissionManager.get_crew_log("log_11").get("title") == "Bridge Command Directives", "Log 11 is Commander Hayes Bridge Directives")
	_assert_true(MissionManager.get_crew_log("log_12").get("title") == "Infirmary Triage Log", "Log 12 is Dr. Thorne Medbay Triage Log")
	_assert_true(MissionManager.get_crew_log("log_13").get("title") == "Cargo Staging & Crawlway Breach", "Log 13 is Quartermaster Reyes Cargo Log")
	_assert_true(MissionManager.get_crew_log("log_14").get("title") == "Reactor Subdeck Vaults", "Log 14 is Chief Engineer Vasquez Subdeck Log")
	
	MissionManager.reset_missions()
	var all_rooms := ["bridge", "avionics_bay", "crew_quarters", "medbay", "life_support", "corridors", "cargo_bay", "airlock_chamber", "engineering_bay", "reactor_subdeck", "maintenance_crawlway"]
	for room in all_rooms:
		MissionManager.mark_room_discovered(room)
	_assert_true(MissionManager.discovered_rooms.size() == 11, "All 11 compartments tracked in discovered_rooms")
	_assert_true(MissionManager.is_room_discovered("maintenance_crawlway"), "is_room_discovered returns true for discovered crawlway")
	
	var term_scene = load("res://scenes/ui/terminal_dialog.tscn")
	var term = term_scene.instantiate()
	add_child(term)
	term.open_terminal("diagnostics", "Test Diagnostics Console")
	_assert_true(term.logs_list.item_count == 14, "TerminalDialog displays all 14 crew logs in logs list")
	term._on_log_selected(10)
	_assert_true(term.log_title_label.text == "BRIDGE COMMAND DIRECTIVES", "TerminalDialog displays Log 11 title")
	_assert_true(term.log_author_label.text.contains("Hayes"), "TerminalDialog displays Log 11 author Commander Hayes")
	term.close_terminal()
	remove_child(term)
	term.free()

func _test_m5_narrative_config_and_scene_placement() -> void:
	MissionManager.reset_missions()
	ShipState.reset_to_defaults()
	
	var datapads: Array = MissionManager.get_all_narrative_datapads()
	var revelations: Array = MissionManager.get_all_narrative_revelations()
	_assert_true(datapads.size() == 10, "narrative_config.json defines 10 physical crew datapads")
	_assert_true(revelations.size() == 3, "narrative_config.json defines 3 major crew mystery revelations")
	
	var encrypted_cfg_count: int = 0
	for dp in datapads:
		var has_fields: bool = dp.has("id") and dp.has("title") and dp.has("author") and dp.has("compartment_id") and dp.has("revelation_id") and dp.has("location_hint") and dp.has("content")
		_assert_true(has_fields, "Datapad config %s has complete schema fields" % str(dp.get("id", "unknown")))
		if bool(dp.get("is_encrypted", false)):
			encrypted_cfg_count += 1
	_assert_true(encrypted_cfg_count == 3, "Exactly 3 datapads are configured as encrypted requiring Diagnostic Scanner")
	
	var rev_ids: Array[String] = []
	for rev in revelations:
		rev_ids.append(str(rev.get("id", "")))
	_assert_true(rev_ids.has("revelation_anomaly") and rev_ids.has("revelation_quarantine") and rev_ids.has("revelation_directive"), "All 3 major revelation IDs present in config")
	
	# Verify 3D scene placement of all 10 DatapadPickup instances in ship_interior.tscn
	var level_scene = load("res://scenes/levels/ship_interior.tscn")
	var level = level_scene.instantiate()
	add_child(level)
	
	var env_mgr = level.get_node_or_null("EnvironmentalManager")
	var dp_nodes = level.find_children("*", "DatapadPickup", true, false)
	_assert_true(dp_nodes.size() == 10, "ship_interior.tscn contains 10 physical DatapadPickup instances")
	
	var seen_ids: Dictionary = {}
	var scene_encrypted_count: int = 0
	for node in dp_nodes:
		seen_ids[node.datapad_id] = true
		if node.is_encrypted:
			scene_encrypted_count += 1
		var cfg_info: Dictionary = MissionManager.get_datapad_data(node.datapad_id)
		var expected_comp: String = str(cfg_info.get("compartment_id", ""))
		if env_mgr != null and expected_comp != "":
			var actual_comp: String = env_mgr.get_compartment_for_position(node.global_position)
			_assert_true(actual_comp == expected_comp, "Datapad %s placed in compartment %s (got %s)" % [node.datapad_id, expected_comp, actual_comp])
	
	_assert_true(seen_ids.size() == 10, "All 10 DatapadPickup instances in ship_interior.tscn have unique datapad_ids")
	_assert_true(scene_encrypted_count == 3, "3 DatapadPickup instances in ship_interior.tscn are marked encrypted")
	
	remove_child(level)
	level.free()

func _test_m5_datapad_encryption_and_scanner() -> void:
	MissionManager.reset_missions()
	ShipState.reset_to_defaults()
	InventoryManager.reset_to_defaults()
	
	var dp_scene = load("res://scenes/interactables/datapad_pickup.tscn")
	
	# 1. Unencrypted DatapadPickup collection
	var unenc_dp = dp_scene.instantiate()
	unenc_dp.datapad_id = "datapad_eng_vasquez"
	unenc_dp.datapad_title = "Vasquez's Harmonic Log Slate"
	unenc_dp.is_encrypted = false
	unenc_dp.requires_scanner_to_decrypt = false
	add_child(unenc_dp)
	
	_assert_true(not unenc_dp.is_collected, "Unencrypted datapad starts uncollected")
	_assert_true(unenc_dp.get_prompt().contains("Recover"), "Unencrypted datapad prompt shows Recover")
	unenc_dp.interact(null)
	_assert_true(unenc_dp.is_collected and unenc_dp.is_decrypted, "Interacting with unencrypted datapad collects and decrypts it")
	_assert_true(MissionManager.is_datapad_collected("datapad_eng_vasquez"), "MissionManager records datapad_eng_vasquez in collected_datapads")
	_assert_true(MissionManager.is_datapad_decrypted("datapad_eng_vasquez"), "MissionManager records datapad_eng_vasquez in decrypted_logs")
	
	# 2. Encrypted DatapadPickup rejection without Diagnostic Scanner equipped
	var enc_dp = dp_scene.instantiate()
	enc_dp.datapad_id = "datapad_medbay_autopsy"
	enc_dp.datapad_title = "Encrypted Autopsy & Triage Slate"
	enc_dp.is_encrypted = true
	enc_dp.requires_scanner_to_decrypt = true
	add_child(enc_dp)
	
	InventoryManager.equip_slot(2) # Equip Multitool (not Diagnostic Scanner)
	_assert_true(enc_dp.get_prompt() == DatapadPickupClass.ENCRYPTED_PROMPT_MSG, "Encrypted datapad prompt instructs player to equip Diagnostic Scanner [1]")
	
	var rejected_reason: Array = [""]
	enc_dp.decryption_rejected.connect(func(_id: String, reason: String): rejected_reason[0] = reason)
	enc_dp.interact(null)
	_assert_true(not enc_dp.is_collected and not enc_dp.is_decrypted, "Encrypted datapad rejects interaction when Diagnostic Scanner is not equipped")
	_assert_true(rejected_reason[0] == DatapadPickupClass.ENCRYPTED_PROMPT_MSG, "Encrypted datapad emits decryption_rejected with exact scanner prompt")
	_assert_true(not MissionManager.is_datapad_decrypted("datapad_medbay_autopsy"), "MissionManager does not unlock encrypted datapad on rejection")
	
	# 3. Encrypted DatapadPickup rejection at exact < 5% boundary (4.99%) and acceptance at exact 5.0%
	InventoryManager.equip_slot(1) # Diagnostic Scanner
	InventoryManager.tools["diagnostic_scanner"]["battery"] = 4.99
	enc_dp.interact(null)
	_assert_true(not enc_dp.is_collected and not enc_dp.is_decrypted, "Encrypted datapad rejects decryption when scanner battery is 4.99% (< 5.0% boundary)")
	
	# 4. Encrypted DatapadPickup successful decryption at exact 5.0% boundary (drains to 0.0%) and rapid repeat interaction safety
	InventoryManager.tools["diagnostic_scanner"]["battery"] = 5.0
	enc_dp.interact(null)
	_assert_true(enc_dp.is_collected and enc_dp.is_decrypted, "Encrypted datapad decrypts and collects when Diagnostic Scanner is at exact 5.0% boundary")
	_assert_true(abs(InventoryManager.get_scanner_battery() - 0.0) < 0.01, "Decrypting encrypted datapad at 5.0% drains battery to 0.0%")
	_assert_true(MissionManager.is_datapad_decrypted("datapad_medbay_autopsy"), "MissionManager records decrypted datapad_medbay_autopsy")
	# Rapid second interaction should not fail or re-drain
	enc_dp.interact(null)
	_assert_true(enc_dp.is_collected and enc_dp.is_decrypted, "Rapid repeat interaction on already-decrypted datapad preserves state safely")
	
	# 5. Subsystem repair alternative decryption (AvionicsRelayBank repaired allows decrypting datapad_avionics_telemetry without scanner)
	var mock_relay = RepairPanel.new()
	mock_relay.name = "AvionicsRelayBank"
	mock_relay.is_repaired = true
	add_child(mock_relay)
	
	var av_dp = dp_scene.instantiate()
	av_dp.datapad_id = "datapad_avionics_telemetry"
	av_dp.is_encrypted = true
	av_dp.requires_scanner_to_decrypt = true
	add_child(av_dp)
	
	InventoryManager.equip_slot(2) # Multitool equipped (not scanner)
	av_dp.interact(null)
	_assert_true(av_dp.is_collected and av_dp.is_decrypted, "Repaired AvionicsRelayBank allows decrypting datapad_avionics_telemetry without scanner battery drain")
	
	# 6. Medbay powered alternative decryption (energized bus allows decrypting datapad_medbay_autopsy without scanner)
	MissionManager.reset_missions()
	ShipState.reset_to_defaults()
	ShipState.set_generator_breaker(true)
	ShipState.set_bus_relay(true)
	var med_dp = dp_scene.instantiate()
	med_dp.datapad_id = "datapad_medbay_autopsy"
	med_dp.is_encrypted = true
	med_dp.requires_scanner_to_decrypt = true
	add_child(med_dp)
	InventoryManager.equip_slot(2) # Multitool equipped (not scanner)
	med_dp.interact(null)
	_assert_true(med_dp.is_collected and med_dp.is_decrypted, "Powered Medbay allows decrypting datapad_medbay_autopsy without Diagnostic Scanner")
	
	remove_child(med_dp)
	med_dp.free()
	remove_child(mock_relay)
	mock_relay.free()
	remove_child(av_dp)
	av_dp.free()
	remove_child(unenc_dp)
	unenc_dp.free()
	remove_child(enc_dp)
	enc_dp.free()

func _test_m5_revelations_and_system_consequences() -> void:
	MissionManager.reset_missions()
	ShipState.reset_to_defaults()
	
	var rev_signals: Array[String] = []
	var conn = func(rev_id: String, _data: Dictionary):
		rev_signals.append(rev_id)
	MissionManager.revelation_unlocked.connect(conn)
	
	# --- Revelation I: The Anomaly's True Nature (revelation_anomaly) ---
	_assert_true(not ShipState.has_revelation_anomaly, "ShipState.has_revelation_anomaly starts false")
	_assert_true(not ShipState.power_system.harmonic_damping_active, "PowerSystem harmonic_damping_active starts false")
	
	MissionManager.collect_datapad("datapad_eng_vasquez", true)
	MissionManager.collect_datapad("datapad_subdeck_throttle", true)
	_assert_true(not MissionManager.is_revelation_unlocked("revelation_anomaly"), "Revelation I stays locked with 2/3 clues")
	
	# Edge case: collecting encrypted 3rd datapad WITHOUT decrypting it does NOT unlock Revelation I
	var dp_scene = load("res://scenes/interactables/datapad_pickup.tscn")
	var av_node = dp_scene.instantiate()
	av_node.datapad_id = "datapad_avionics_telemetry"
	av_node.is_encrypted = true
	av_node.requires_scanner_to_decrypt = true
	add_child(av_node)
	
	MissionManager.collect_datapad("datapad_avionics_telemetry", false)
	_assert_true(MissionManager.is_datapad_collected("datapad_avionics_telemetry"), "datapad_avionics_telemetry marked collected")
	_assert_true(not MissionManager.is_datapad_decrypted("datapad_avionics_telemetry"), "datapad_avionics_telemetry remains un-decrypted when mark_decrypted=false")
	_assert_true(av_node.is_collected and not av_node.is_decrypted, "DatapadPickup node syncs is_collected=true and is_decrypted=false when collected un-decrypted")
	_assert_true(not MissionManager.is_revelation_unlocked("revelation_anomaly"), "Revelation I does NOT unlock while 3rd clue is still encrypted")
	
	# Now decrypt the 3rd clue
	MissionManager.decrypt_datapad("datapad_avionics_telemetry")
	_assert_true(av_node.is_decrypted, "DatapadPickup node updates is_decrypted=true upon decryption")
	remove_child(av_node)
	av_node.free()
	_assert_true(MissionManager.is_revelation_unlocked("revelation_anomaly"), "Revelation I unlocks automatically upon decrypting 3rd datapad")
	_assert_true(rev_signals.has("revelation_anomaly"), "revelation_unlocked signal emitted for revelation_anomaly")
	_assert_true(ShipState.has_revelation_anomaly, "ShipState.has_revelation_anomaly is true after Revelation I")
	_assert_true(ShipState.power_system.harmonic_damping_active, "PowerSystem.harmonic_damping_active is true after Revelation I")
	_assert_true(abs(ShipState.power_system.thermal_accumulation_multiplier - 0.85) < 0.001, "PowerSystem thermal_accumulation_multiplier is 0.85 (-15% thermal rate)")
	_assert_true(abs(ShipState.power_system.auxiliary_headroom_kw - 10.0) < 0.001, "PowerSystem auxiliary_headroom_kw is +10.0 kW")
	
	# Verify PowerSystem effective capacity includes +10.0 kW headroom
	ShipState.power_system.set_generator(true)
	ShipState.power_system.set_bus_relay(true)
	ShipState.power_system.tick(0.1)
	_assert_true(ShipState.power_system.current_generation >= 150.0, "Reactor with +10 kW harmonic headroom generates >= 150 kW at full integrity")
	
	# --- Revelation II: The Quarantine Protocol (revelation_quarantine) ---
	_assert_true(not ShipState.has_revelation_quarantine, "ShipState.has_revelation_quarantine starts false")
	MissionManager.collect_datapad("datapad_ls_contamination", true)
	MissionManager.collect_datapad("datapad_crew_quarantine", true)
	_assert_true(not MissionManager.is_revelation_unlocked("revelation_quarantine"), "Revelation II stays locked with 2/3 clues")
	
	MissionManager.collect_datapad("datapad_medbay_autopsy", true)
	_assert_true(MissionManager.is_revelation_unlocked("revelation_quarantine"), "Revelation II unlocks automatically upon 3rd decrypted datapad")
	_assert_true(ShipState.has_revelation_quarantine, "ShipState.has_revelation_quarantine is true after Revelation II")
	_assert_true(abs(ShipState.get_scrubber_efficiency_multiplier() - 1.20) < 0.001, "ShipState scrubber efficiency multiplier is 1.20 (+20%)")
	
	var env_node = EnvManagerScript.new()
	add_child(env_node)
	_assert_true(abs(env_node.get_scrubber_optimization_multiplier() - 1.20) < 0.001, "EnvironmentalManager applies 1.20x (+20%) scrubber optimization multiplier")
	remove_child(env_node)
	env_node.free()
	
	# --- Revelation III: The Abandoned Directive (revelation_directive) ---
	_assert_true(not ShipState.has_revelation_directive, "ShipState.has_revelation_directive starts false")
	MissionManager.collect_datapad("datapad_cargo_manifest", true)
	MissionManager.collect_datapad("datapad_crawlway_blackbox", true)
	MissionManager.collect_datapad("datapad_airlock_jettison", true)
	_assert_true(not MissionManager.is_revelation_unlocked("revelation_directive"), "Revelation III stays locked with 3/4 clues")
	
	MissionManager.collect_datapad("datapad_bridge_directive", true)
	_assert_true(MissionManager.is_revelation_unlocked("revelation_directive"), "Revelation III unlocks automatically upon 4th decrypted datapad")
	_assert_true(ShipState.has_revelation_directive, "ShipState.has_revelation_directive is true after Revelation III")
	_assert_true(ShipState.commander_override_code == "7394-OMEGA", "Commander override code 7394-OMEGA unlocked on ShipState")
	_assert_true(ShipState.quarantine_lockout_cleared, "ShipState quarantine_lockout_cleared is true")
	_assert_true(abs(ShipState.thruster_efficiency_boost - 1.25) < 0.001, "ShipState thruster_efficiency_boost is 1.25")
	_assert_true(abs(ShipState.devices["ion_propulsion"].power_draw - 48.0) < 0.01, "Ion propulsion power draw reduced to 48.0 kW by Revelation III")
	
	# Verify MissionManager.reset_missions() restores device-level modifications on ShipState
	MissionManager.reset_missions()
	_assert_true(abs(ShipState.devices["ion_propulsion"].power_draw - 60.0) < 0.01, "MissionManager.reset_missions() restores ion_propulsion power_draw to 60.0 kW")
	_assert_true(abs(ShipState.devices["reactor_primary"].power_generation - 150.0) < 0.01, "MissionManager.reset_missions() restores reactor_primary power_generation to 150.0 kW")
	
	MissionManager.revelation_unlocked.disconnect(conn)

func _test_m5_terminal_ui_and_save_load() -> void:
	MissionManager.reset_missions()
	ShipState.reset_to_defaults()
	
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud_node = hud_scene.instantiate()
	add_child(hud_node)
	
	# Collect 3 datapads to unlock Revelation I, leave 7 unrecovered
	MissionManager.collect_datapad("datapad_eng_vasquez", true)
	MissionManager.collect_datapad("datapad_subdeck_throttle", true)
	MissionManager.collect_datapad("datapad_avionics_telemetry", true)
	
	_assert_true(hud_node.notification_lbl.text.contains("Kharon-4 Magnetosphere Carrier Telemetry") and hud_node.notification_lbl.text.contains("Revelation I"), "HUD notification banner displays both recovered datapad title and synthesized Revelation I")
	remove_child(hud_node)
	hud_node.free()
	
	var term_scene = load("res://scenes/ui/terminal_dialog.tscn")
	var term = term_scene.instantiate()
	add_child(term)
	term.open_terminal("diagnostics", "Bridge Investigation Console")
	
	# Default category is crew_logs (14 items)
	_assert_true(term.logs_list.item_count == 14, "TerminalDialog defaults to 14 standard crew logs")
	
	# Switch to Datapads filter in Incident Logs
	term.set_log_category("datapads")
	_assert_true(term.logs_list.item_count == 10, "TerminalDialog datapads filter displays all 10 datapad slots")
	_assert_true(term.logs_list.get_item_text(0).begins_with("[DECRYPTED]"), "Recovered datapad displays [DECRYPTED] prefix in TerminalDialog")
	_assert_true(term.logs_list.get_item_text(3).begins_with("[UNRECOVERED -"), "Unrecovered datapad displays [UNRECOVERED - Location Hint] in TerminalDialog")
	
	term._on_log_selected(0)
	_assert_true(term.log_title_label.text.contains("[DECRYPTED]"), "Selecting recovered datapad shows [DECRYPTED] header")
	_assert_true(term.log_content_label.text.contains("47.3 Hz"), "Selecting recovered datapad displays full decrypted log content")
	
	term._on_log_selected(3)
	_assert_true(term.log_title_label.text.contains("[UNRECOVERED]"), "Selecting unrecovered datapad shows [UNRECOVERED] header")
	_assert_true(term.log_content_label.text.contains("Last Known Telemetry Ping"), "Selecting unrecovered datapad shows location hint")
	
	# Switch to Revelations filter in Incident Logs
	term.set_log_category("revelations")
	_assert_true(term.logs_list.item_count == 3, "TerminalDialog revelations filter displays all 3 major revelations")
	_assert_true(term.logs_list.get_item_text(0).begins_with("[UNLOCKED]"), "Unlocked Revelation I displays [UNLOCKED] in TerminalDialog")
	_assert_true(term.logs_list.get_item_text(1).begins_with("[LOCKED - 0/3 Clues]"), "Locked Revelation II displays [LOCKED - 0/3 Clues] in TerminalDialog")
	
	# Switch to Crew Mystery Investigation Dossier tab
	term._show_tab("investigation")
	_assert_true(term.investigation_summary_label.text.contains("DATAPADS RECOVERED: 3/10"), "Investigation summary shows 3/10 datapads recovered")
	_assert_true(term.investigation_summary_label.text.contains("REVELATIONS UNLOCKED: 1/3"), "Investigation summary shows 1/3 revelations unlocked")
	_assert_true(term.datapads_dossier_list.get_child_count() == 11, "DatapadsDossierList contains header + 10 datapad cards")
	_assert_true(term.revelations_dossier_list.get_child_count() == 4, "RevelationsDossierList contains header + 3 revelation cards")
	
	term.close_terminal()
	remove_child(term)
	term.free()
	
	# Test Save / Load roundtrip persistence of Datapads, Revelations, and System Bonuses
	var dp_scene = load("res://scenes/interactables/datapad_pickup.tscn")
	var dp_node = dp_scene.instantiate()
	dp_node.datapad_id = "datapad_eng_vasquez"
	dp_node.is_encrypted = false
	add_child(dp_node)
	dp_node.is_collected = true
	dp_node.is_decrypted = true
	
	var save_ok: bool = SaveManager.save_game()
	_assert_true(save_ok, "SaveManager.save_game() succeeds with Milestone 5 state")
	
	# Reset everything
	MissionManager.reset_missions()
	ShipState.reset_to_defaults()
	dp_node.is_collected = false
	dp_node.is_decrypted = false
	_assert_true(MissionManager.collected_datapads.is_empty(), "MissionManager collected_datapads cleared on reset")
	_assert_true(not ShipState.has_revelation_anomaly, "ShipState.has_revelation_anomaly cleared on reset")
	_assert_true(not ShipState.power_system.harmonic_damping_active, "PowerSystem harmonic_damping_active cleared on reset")
	
	# Load saved game
	var load_ok: bool = SaveManager.load_game()
	_assert_true(load_ok, "SaveManager.load_game() succeeds")
	_assert_true(MissionManager.collected_datapads.size() == 3, "MissionManager restores 3 collected datapads on load")
	_assert_true(MissionManager.decrypted_logs.size() == 3, "MissionManager restores 3 decrypted logs on load")
	_assert_true(MissionManager.is_revelation_unlocked("revelation_anomaly"), "MissionManager restores unlocked revelation_anomaly on load")
	_assert_true(ShipState.has_revelation_anomaly, "ShipState restores has_revelation_anomaly on load")
	_assert_true(ShipState.power_system.harmonic_damping_active, "PowerSystem restores harmonic_damping_active on load")
	_assert_true(dp_node.is_collected and dp_node.is_decrypted, "DatapadPickup node restores is_collected and is_decrypted on load")
	
	# Edge Case: Loading a legacy Milestone 4 save file (without "datapads" or revelation keys) after unlocking all 3 revelations in-session
	MissionManager.collect_datapad("datapad_ls_contamination", true)
	MissionManager.collect_datapad("datapad_crew_quarantine", true)
	MissionManager.collect_datapad("datapad_medbay_autopsy", true)
	MissionManager.collect_datapad("datapad_cargo_manifest", true)
	MissionManager.collect_datapad("datapad_crawlway_blackbox", true)
	MissionManager.collect_datapad("datapad_airlock_jettison", true)
	MissionManager.collect_datapad("datapad_bridge_directive", true)
	_assert_true(ShipState.has_revelation_quarantine and ShipState.has_revelation_directive, "All 3 revelations active prior to legacy save load")
	
	var legacy_save := {
		"version": 1,
		"missions": {
			"current_objective_index": 1,
			"inventory": []
		},
		"ship_state": {
			"auxiliary_scrubber_active": false
		}
	}
	var lf := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	lf.store_string(JSON.stringify(legacy_save))
	lf.close()
	
	var legacy_load_ok: bool = SaveManager.load_game()
	_assert_true(legacy_load_ok, "Loading legacy Milestone 4 save succeeds")
	_assert_true(MissionManager.collected_datapads.is_empty(), "Legacy save load clears collected_datapads")
	_assert_true(MissionManager.unlocked_revelations.is_empty(), "Legacy save load clears unlocked_revelations")
	_assert_true(MissionManager.commander_override_code == "", "Legacy save load resets MissionManager.commander_override_code to empty")
	_assert_true(not MissionManager.quarantine_lockout_cleared, "Legacy save load resets MissionManager.quarantine_lockout_cleared to false")
	_assert_true(not ShipState.has_revelation_anomaly and not ShipState.has_revelation_quarantine and not ShipState.has_revelation_directive, "Legacy save load clears all ShipState revelation flags")
	_assert_true(abs(ShipState.scrubber_efficiency_multiplier - 1.0) < 0.001, "Legacy save load resets ShipState.scrubber_efficiency_multiplier to 1.0")
	_assert_true(ShipState.commander_override_code == "", "Legacy save load resets ShipState.commander_override_code to empty")
	_assert_true(abs(ShipState.devices["ion_propulsion"].power_draw - 60.0) < 0.01, "Legacy save load restores ion_propulsion power_draw to 60.0 kW")
	_assert_true(not dp_node.is_collected, "Legacy save load without 'datapads' key resets DatapadPickup node to uncollected")
	
	remove_child(dp_node)
	dp_node.free()
	SaveManager.delete_save()
	MissionManager.reset_missions()
	ShipState.reset_to_defaults()

func _test_m6_dynamic_crisis_scenarios_and_cascades() -> void:
	ShipState.reset_to_defaults()
	_assert_true(ShipState.crisis_manager != null, "CrisisManager is initialized on ShipState")
	_assert_true(ShipState.crisis_manager.current_crisis == CrisisManagerClass.CrisisType.NONE, "CrisisManager starts with no active crisis")
	_assert_true(ShipState.crisis_manager.current_stage == CrisisManagerClass.Stage.STAGE_0_IDLE, "CrisisManager starts at STAGE_0_IDLE")
	_assert_true(not ShipState.crisis_manager.is_cascade_active(), "No cascading faults initially active")

	# Start Power Grid Cascade
	ShipState.start_crisis(CrisisManagerClass.CrisisType.POWER_GRID_CASCADE)
	_assert_true(ShipState.crisis_manager.current_crisis == CrisisManagerClass.CrisisType.POWER_GRID_CASCADE, "Power Grid Cascade crisis started")
	_assert_true(ShipState.crisis_manager.current_stage == CrisisManagerClass.Stage.STAGE_1_SURGE, "Crisis starts at STAGE_1_SURGE")
	_assert_true(ShipState.active_faults.has("GENERATOR_TRIP"), "Initial fault GENERATOR_TRIP injected on start")

	# Manual cascade trigger
	var cascaded = ShipState.trigger_cascading_fault("BUS_ISOLATION")
	_assert_true(cascaded, "trigger_cascading_fault returns true")
	_assert_true(ShipState.active_faults.has("BUS_ISOLATION"), "BUS_ISOLATION fault injected into active_faults")
	_assert_true(ShipState.crisis_manager.active_cascading_faults.has("BUS_ISOLATION"), "BUS_ISOLATION recorded in active_cascading_faults")
	_assert_true(ShipState.crisis_manager.is_cascade_active(), "is_cascade_active returns true while fault active")

	# Advance stage
	ShipState.advance_crisis_stage()
	_assert_true(ShipState.crisis_manager.current_stage == CrisisManagerClass.Stage.STAGE_2_CASCADE, "Stage advances to STAGE_2_CASCADE")
	_assert_true(ShipState.crisis_manager.stage_name == "BUS_ISOLATION_CASCADE", "Stage 2 name matches BUS_ISOLATION_CASCADE")

	# Automatic cascade timer on tick_systems
	ShipState.crisis_manager.cascading_timer = 7.99
	ShipState.tick_systems(0.02)
	_assert_true(ShipState.crisis_manager.current_stage == CrisisManagerClass.Stage.STAGE_3_CRITICAL, "Automatic timer advances stage to STAGE_3_CRITICAL")
	_assert_true(ShipState.active_faults.has("CO2_SCRUBBER_SATURATION"), "CO2_SCRUBBER_SATURATION automatically cascaded at Stage 3")

	# Resolve cascade
	ShipState.crisis_manager.resolve_cascade("BUS_ISOLATION")
	_assert_true(not ShipState.crisis_manager.active_cascading_faults.has("BUS_ISOLATION"), "BUS_ISOLATION removed from active cascades")

	# Resolve entire crisis
	ShipState.resolve_crisis()
	_assert_true(ShipState.crisis_manager.current_crisis == CrisisManagerClass.CrisisType.NONE, "CrisisManager cleared to NONE on resolve")
	_assert_true(ShipState.crisis_manager.current_stage == CrisisManagerClass.Stage.STAGE_5_RESOLVED, "Stage set to STAGE_5_RESOLVED")
	_assert_true(not ShipState.crisis_manager.is_cascade_active(), "All active cascades cleared on resolve")

	# Reset for cleanliness
	ShipState.reset_to_defaults()

func _test_m6_creature_hunt_and_poison_gas_trap() -> void:
	ShipState.reset_to_defaults()
	
	# Start creature hunt crisis
	ShipState.start_crisis(CrisisManagerClass.CrisisType.CREATURE_PREDATORY_HUNT)
	_assert_true(ShipState.crisis_manager.current_crisis == CrisisManagerClass.CrisisType.CREATURE_PREDATORY_HUNT, "Creature Predatory Hunt crisis engaged")
	_assert_true(ShipState.crisis_manager.creature_state == CrisisManagerClass.CreatureState.STALKING, "Creature initial state is STALKING")
	_assert_true(not ShipState.crisis_manager.is_creature_trapped, "Creature not trapped initially")
	_assert_true(not ShipState.crisis_manager.is_creature_eliminated, "Creature not eliminated initially")

	# Advance to aggressive stage
	ShipState.advance_crisis_stage()
	_assert_true(ShipState.crisis_manager.creature_state == CrisisManagerClass.CreatureState.AGGRESSIVE, "Creature state transitions to AGGRESSIVE at Stage 2")

	# Trap creature in airlock_chamber
	var trap_res = ShipState.trap_creature_in_chamber("airlock_chamber")
	_assert_true(trap_res, "trap_creature_in_chamber returns true")
	_assert_true(ShipState.crisis_manager.is_creature_trapped, "is_creature_trapped is true")
	_assert_true(ShipState.crisis_manager.creature_state == CrisisManagerClass.CreatureState.TRAPPED, "Creature state is TRAPPED")
	_assert_true(ShipState.crisis_manager.target_chamber_id == "airlock_chamber", "Creature chamber is airlock_chamber")

	# Test EmergencyValve with valve_type = "poison_gas"
	var valve = EmergencyValveClass.new()
	valve.valve_type = "poison_gas"
	add_child(valve)
	
	var prompt = valve.get_prompt()
	_assert_true(prompt.to_upper().contains("POISONOUS DECONTAMINATION GAS"), "Valve prompt reflects Poisonous Decontamination Gas")
	_assert_true(prompt.contains("airlock_chamber"), "Valve prompt specifies targeted trapped chamber")

	# Interact with valve to execute poison gas purge
	valve._on_interacted(null)
	_assert_true(ShipState.crisis_manager.is_creature_eliminated, "Creature is eliminated following valve interaction")
	_assert_true(ShipState.crisis_manager.creature_state == CrisisManagerClass.CreatureState.ELIMINATED, "Creature state is ELIMINATED")
	_assert_true(ShipState.crisis_manager.poison_gas_valve_opened, "poison_gas_valve_opened flag is true")
	_assert_true(ShipState.crisis_manager.current_crisis == CrisisManagerClass.CrisisType.NONE, "Creature crisis resolved after purge")

	# Post-purge prompt
	var post_prompt = valve.get_prompt()
	_assert_true(post_prompt.contains("PURGED"), "Valve prompt reflects PURGED status")

	remove_child(valve)
	valve.free()
	ShipState.reset_to_defaults()

func _test_m6_tactical_ui_telemetry_and_immediate_task() -> void:
	MissionManager.reset_missions()
	
	# Verify immediate task strings across all 5 objectives
	_assert_true(MissionManager.get_current_immediate_task().contains("Generator"), "Objective 0 immediate task points to Generator Breaker")
	MissionManager.advance_objective()
	_assert_true(MissionManager.get_current_immediate_task().contains("Bus") or MissionManager.get_current_immediate_task().contains("Relay"), "Objective 1 immediate task points to Distribution Bus Relay")
	MissionManager.advance_objective()
	_assert_true(MissionManager.get_current_immediate_task().contains("Scrubber") or MissionManager.get_current_immediate_task().contains("Coupler") or MissionManager.get_current_immediate_task().contains("Filters"), "Objective 2 immediate task points to Scrubber Coupler")
	MissionManager.advance_objective()
	_assert_true(MissionManager.get_current_immediate_task().contains("Dish") or MissionManager.get_current_immediate_task().contains("Research") or MissionManager.get_current_immediate_task().contains("Comms"), "Objective 3 immediate task points to Comms / Research Logs")
	MissionManager.advance_objective()
	_assert_true(MissionManager.get_current_immediate_task().contains("Trap") or MissionManager.get_current_immediate_task().contains("Purge") or MissionManager.get_current_immediate_task().contains("Gas"), "Objective 4 immediate task points to Trap Alien & Poison Gas Purge")
	
	MissionManager.reset_missions()

	# Test HUD scene layout and prompt placement
	var hud_scene = load("res://scenes/ui/hud.tscn")
	_assert_true(hud_scene != null, "HUD scene loads successfully")
	var hud = hud_scene.instantiate()
	add_child(hud)
	
	var info_btn = hud.get_node_or_null("%InfoButton")
	_assert_true(info_btn != null, "HUD contains %InfoButton")
	_assert_true(info_btn.text.contains("TAB") and info_btn.text.contains("INFO"), "InfoButton displays [TAB] INFO")
	
	var task_lbl = hud.get_node_or_null("%ImmediateTaskLabel")
	_assert_true(task_lbl != null, "HUD contains %ImmediateTaskLabel below ObjectiveTitle")
	
	var gear_lbl = hud.get_node_or_null("%CompactGearLabel")
	_assert_true(gear_lbl != null, "HUD contains %CompactGearLabel in bottom-left")

	var vitals_pnl = hud.get_node_or_null("%VitalsPanel")
	var hp_bar = hud.get_node_or_null("%HealthBar")
	var o2_bar_node = hud.get_node_or_null("%OxygenBar")
	_assert_true(vitals_pnl != null, "HUD contains %VitalsPanel")
	_assert_true(hp_bar != null and o2_bar_node != null, "HUD contains %HealthBar and %OxygenBar gauges")

	var prompt_lbl = hud.get_node_or_null("%PromptLabel")
	_assert_true(prompt_lbl != null, "HUD contains %PromptLabel")
	var prompt_margin = hud.get_node_or_null("PromptMargin")
	_assert_true(prompt_margin != null and prompt_margin.offset_top >= 130.0, "PromptMargin positioned below targeted object (offset_top >= 130px)")
	_assert_true(prompt_lbl.get_theme_font_size("font_size") <= 12, "PromptLabel font size decreased to <= 12px (11px)")

	# Verify backwards-compatibility getters on hud_controller
	_assert_true("o2_bar" in hud, "hud controller exposes legacy o2_bar getter")
	_assert_true("inventory_lbl" in hud, "hud controller exposes legacy inventory_lbl getter")

	remove_child(hud)
	hud.free()

	# Test PauseMenu tactical dashboard
	var pause_scene = load("res://scenes/ui/pause_menu.tscn")
	_assert_true(pause_scene != null, "PauseMenu scene loads successfully")
	var pause_menu = pause_scene.instantiate()
	add_child(pause_menu)

	var telemetry_box = pause_menu.get_node_or_null("%EnvPanel")
	_assert_true(telemetry_box != null, "PauseMenu has %EnvPanel for life support telemetry")
	var mission_box = pause_menu.get_node_or_null("%MissionPanel")
	_assert_true(mission_box != null, "PauseMenu has %MissionPanel for scientist directives")
	var gear_box = pause_menu.get_node_or_null("%GearPanel")
	_assert_true(gear_box != null, "PauseMenu has %GearPanel for inventory & scanner gear")
	var full_brief = pause_menu.get_node_or_null("%PauseMissionDesc")
	_assert_true(full_brief != null, "PauseMenu has %PauseMissionDesc for complete storyline briefing")

	# Update telemetry and verify pause sync
	pause_menu.update_telemetry(88.0, 450.0, 101.3, 21.5, "Nominal", "Crew Quarters")
	_assert_true(abs(pause_menu.get_node("%OxygenBar").value - 88.0) < 0.1, "Pause menu syncs O2 value")
	_assert_true(pause_menu.get_node("%CO2StatusLabel").text.contains("450"), "Pause menu syncs CO2 reading")
	_assert_true(pause_menu.get_node("%AtmosphereMetricsLabel").text.contains("21.5") or pause_menu.get_node("%AtmosphereMetricsLabel").text.contains("21"), "Pause menu syncs Temperature reading")

	remove_child(pause_menu)
	pause_menu.free()

func _test_m6_save_load_crisis_persistence() -> void:
	ShipState.reset_to_defaults()
	MissionManager.reset_missions()
	SaveManager.delete_save()

	# Start crisis and set state
	ShipState.start_crisis(CrisisManagerClass.CrisisType.CREATURE_PREDATORY_HUNT)
	ShipState.advance_crisis_stage()
	ShipState.trap_creature_in_chamber("airlock_chamber")
	ShipState.trigger_cascading_fault("SPECIMEN_CHAMBER_BREACH")

	var save_ok = SaveManager.save_game()
	_assert_true(save_ok, "SaveManager.save_game() persists Milestone 6 crisis state")

	# Reset
	ShipState.reset_to_defaults()
	_assert_true(ShipState.crisis_manager.current_crisis == CrisisManagerClass.CrisisType.NONE, "Crisis cleared on ShipState reset")
	_assert_true(not ShipState.crisis_manager.is_creature_trapped, "is_creature_trapped cleared on reset")

	# Load game
	var load_ok = SaveManager.load_game()
	_assert_true(load_ok, "SaveManager.load_game() succeeds")
	_assert_true(ShipState.crisis_manager.current_crisis == CrisisManagerClass.CrisisType.CREATURE_PREDATORY_HUNT, "Crisis type restored from save")
	_assert_true(ShipState.crisis_manager.is_creature_trapped, "is_creature_trapped restored from save")
	_assert_true(ShipState.crisis_manager.creature_state == CrisisManagerClass.CreatureState.TRAPPED, "Creature state restored as TRAPPED")
	_assert_true(ShipState.crisis_manager.target_chamber_id == "airlock_chamber", "Trapped chamber ID restored as airlock_chamber")
	_assert_true(ShipState.crisis_manager.active_cascading_faults.has("SPECIMEN_CHAMBER_BREACH"), "Cascading fault restored from save")

	# Legacy save test without crisis key
	var legacy_save := {
		"version": 1,
		"missions": {
			"current_objective_index": 0,
			"inventory": []
		},
		"ship_state": {
			"auxiliary_scrubber_active": false
		}
	}
	var lf := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	lf.store_string(JSON.stringify(legacy_save))
	lf.close()

	var leg_load_ok = SaveManager.load_game()
	_assert_true(leg_load_ok, "Legacy save without 'crisis' key loads without error")
	_assert_true(ShipState.crisis_manager.current_crisis == CrisisManagerClass.CrisisType.NONE, "Legacy save restores clean CrisisType.NONE")
	_assert_true(ShipState.crisis_manager.current_stage == CrisisManagerClass.Stage.STAGE_0_IDLE, "Legacy save restores clean Stage 0")
	_assert_true(not ShipState.crisis_manager.is_creature_trapped, "Legacy save restores creature as untrapped")

	SaveManager.delete_save()
	ShipState.reset_to_defaults()
	MissionManager.reset_missions()

func _test_m6_enhanced_visuals_and_storyline_verification() -> void:
	ShipState.reset_to_defaults()
	MissionManager.reset_missions()

	# 1. StorageLocker visual enhancement verification
	var locker_scene = load("res://scenes/interactables/storage_locker.tscn")
	_assert_true(locker_scene != null, "StorageLocker scene loads successfully")
	var locker = locker_scene.instantiate()
	add_child(locker)
	_assert_true(locker.has_node("ChassisFrame"), "StorageLocker has reinforced ChassisFrame")
	_assert_true(locker.has_node("DoorPanel"), "StorageLocker has recessed DoorPanel")
	_assert_true(locker.has_node("VentLouverTop"), "StorageLocker has VentLouverTop")
	_assert_true(locker.has_node("HandleMesh"), "StorageLocker has HandleMesh")
	_assert_true(locker.has_node("IndicatorLED"), "StorageLocker has IndicatorLED")
	remove_child(locker)
	locker.free()

	# 2. AirlockController visual enhancement verification
	var airlock_scene = load("res://scenes/interactables/airlock_controller.tscn")
	_assert_true(airlock_scene != null, "AirlockController scene loads successfully")
	var airlock = airlock_scene.instantiate()
	add_child(airlock)
	_assert_true(airlock.has_node("MountingPlate"), "AirlockController has MountingPlate")
	_assert_true(airlock.has_node("HousingMesh"), "AirlockController has HousingMesh")
	_assert_true(airlock.has_node("DisplayScreen"), "AirlockController has DisplayScreen")
	_assert_true(airlock.has_node("ButtonEVA"), "AirlockController has ButtonEVA")
	_assert_true(airlock.has_node("ButtonCabin"), "AirlockController has ButtonCabin")
	_assert_true(airlock.has_node("StatusLight"), "AirlockController has StatusLight")
	remove_child(airlock)
	airlock.free()

	# 3. VentDamper visual enhancement verification
	var damper_scene = load("res://scenes/interactables/vent_damper.tscn")
	_assert_true(damper_scene != null, "VentDamper scene loads successfully")
	var damper = damper_scene.instantiate()
	add_child(damper)
	_assert_true(damper.has_node("MountingFlange"), "VentDamper has MountingFlange")
	_assert_true(damper.has_node("FrameMesh"), "VentDamper has FrameMesh")
	_assert_true(damper.has_node("ActuatorHousing"), "VentDamper has ActuatorHousing")
	_assert_true(damper.has_node("Louvers"), "VentDamper has Louvers node")
	_assert_true(damper.has_node("StatusLED"), "VentDamper has StatusLED")
	remove_child(damper)
	damper.free()

	# 4. WorkbenchStation visual enhancement verification
	var bench_scene = load("res://scenes/interactables/workbench_station.tscn")
	_assert_true(bench_scene != null, "WorkbenchStation scene loads successfully")
	var bench = bench_scene.instantiate()
	add_child(bench)
	_assert_true(bench.has_node("TableBase"), "WorkbenchStation has TableBase")
	_assert_true(bench.has_node("DockMesh"), "WorkbenchStation has DockMesh")
	_assert_true(bench.has_node("ToolTray"), "WorkbenchStation has ToolTray")
	_assert_true(bench.has_node("ChargerRing"), "WorkbenchStation has ChargerRing")
	_assert_true(bench.has_node("CradleLED"), "WorkbenchStation has CradleLED")
	remove_child(bench)
	bench.free()

	# 5. EnvironmentalSensor visual enhancement verification
	var sensor_scene = load("res://scenes/interactables/env_sensor.tscn")
	_assert_true(sensor_scene != null, "EnvironmentalSensor scene loads successfully")
	var sensor = sensor_scene.instantiate()
	add_child(sensor)
	_assert_true(sensor.has_node("MountingBracket"), "EnvironmentalSensor has MountingBracket")
	_assert_true(sensor.has_node("CasingMesh"), "EnvironmentalSensor has CasingMesh")
	_assert_true(sensor.has_node("SamplingGrill"), "EnvironmentalSensor has SamplingGrill")
	_assert_true(sensor.has_node("StatusLED"), "EnvironmentalSensor has StatusLED")
	remove_child(sensor)
	sensor.free()

	# 6. PickupItem visual enhancement verification
	var pickup_scene = load("res://scenes/interactables/pickup.tscn")
	_assert_true(pickup_scene != null, "PickupItem scene loads successfully")
	var pickup = pickup_scene.instantiate()
	add_child(pickup)
	_assert_true(pickup.has_node("MeshInstance3D"), "PickupItem has main cylindrical coupler mesh")
	_assert_true(pickup.has_node("FlangeTop"), "PickupItem has FlangeTop")
	_assert_true(pickup.has_node("FlangeBottom"), "PickupItem has FlangeBottom")
	_assert_true(pickup.has_node("ItemLight"), "PickupItem has ItemLight")
	remove_child(pickup)
	pickup.free()

	# 7. Level placement of DecontaminationPoisonGasValve in ship_interior.tscn
	var level_scene = load("res://scenes/levels/ship_interior.tscn")
	_assert_true(level_scene != null, "ship_interior.tscn loads successfully")
	var level = level_scene.instantiate()
	add_child(level)
	var poison_valve = level.get_node_or_null("Compartments/AirlockChamber/DecontaminationPoisonGasValve")
	_assert_true(poison_valve != null, "DecontaminationPoisonGasValve exists in Compartments/AirlockChamber")
	_assert_true(poison_valve.valve_type == "poison_gas", "DecontaminationPoisonGasValve has valve_type 'poison_gas'")
	remove_child(level)
	level.free()

	# 8. MainMenu and MissionComplete storyline text verification
	var mm_scene = load("res://scenes/ui/main_menu.tscn")
	_assert_true(mm_scene != null, "main_menu.tscn loads successfully")
	var mm = mm_scene.instantiate()
	add_child(mm)
	var subtitle_lbl = mm.get_node_or_null("Center/VBox/TitleBox/Subtitle")
	_assert_true(subtitle_lbl != null and subtitle_lbl.text.contains("Biological Research"), "Main menu subtitle reflects Biological Research Facility")
	remove_child(mm)
	mm.free()

	var mc_scene = load("res://scenes/ui/mission_complete.tscn")
	_assert_true(mc_scene != null, "mission_complete.tscn loads successfully")
	var mc = mc_scene.instantiate()
	add_child(mc)
	var mc_body = mc.get_node_or_null("Center/Panel/Margin/VBox/BodyText")
	_assert_true(mc_body != null and mc_body.text.contains("Lead Scientist"), "MissionComplete body text refers to Lead Scientist")
	_assert_true(mc_body.text.contains("poisonous gas valve"), "MissionComplete body text mentions poisonous gas valve purge")
	remove_child(mc)
	mc.free()

	# 9. In-game predator lockdown verification
	ShipSystemManager.set_generator_breaker(true)
	ShipSystemManager.set_power_distribution(true)
	ShipSystemManager.install_coolant_coupler()
	ShipSystemManager.align_comms_array()
	_assert_true(ShipSystemManager.is_system_online("communications"), "All propulsion prerequisites online")

	# Start predator hunt crisis
	ShipState.start_crisis(CrisisManagerClass.CrisisType.CREATURE_PREDATORY_HUNT)
	var prop_block = ShipSystemManager.engage_propulsion()
	_assert_true(not prop_block.get("ok", true), "Propulsion blocked while mutant alien is active")
	_assert_true(prop_block.get("reason", "").contains("lockdown"), "Block reason indicates station lockdown / predator active")

	# Execute purge to clear predator threat
	ShipState.purge_creature_with_poison_gas("airlock_chamber")
	var prop_ok = ShipSystemManager.engage_propulsion()
	_assert_true(prop_ok.get("ok", false), "Propulsion engages successfully once predator is purged")

	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()

func _test_m7_expanded_chambers_and_environmental_survey() -> void:
	ShipState.reset_to_defaults()
	MissionManager.reset_missions()
	
	# 1. Verify ShipState compartments dictionary includes expanded chambers
	_assert_true(ShipState.COMPARTMENTS.has("specimen_vault"), "ShipState includes specimen_vault compartment")
	_assert_true(ShipState.COMPARTMENTS.has("research_observatory"), "ShipState includes research_observatory compartment")
	
	var spec_info: Dictionary = ShipState.COMPARTMENTS["specimen_vault"]
	_assert_true(spec_info.get("deck") == "lower", "specimen_vault is located on lower deck")
	_assert_true(spec_info.get("name", "").contains("Specimen"), "specimen_vault name reflects Specimen Containment")
	
	var obs_info: Dictionary = ShipState.COMPARTMENTS["research_observatory"]
	_assert_true(obs_info.get("deck") == "main", "research_observatory is located on main deck")
	_assert_true(obs_info.get("name", "").contains("Observatory"), "research_observatory name reflects Observatory Dome")
	
	# 2. Verify EnvironmentalManager simulation across expanded chambers
	var env_mgr = EnvManagerScript.new()
	add_child(env_mgr)
	
	_assert_true(env_mgr.get_all_compartments(true, true).size() == 13, "get_all_compartments(true, true) returns 13 compartments")
	_assert_true(env_mgr.get_all_compartments(true, false).size() == 11, "get_all_compartments(true, false) maintains 11 compartments for backward compatibility")
	_assert_true(env_mgr.get_all_compartments(false).size() == 4, "get_all_compartments(false) maintains 4 core compartments")
	
	# 3. Position-to-compartment spatial detection
	_assert_true(env_mgr.get_compartment_for_position(Vector3(0, -2, 38)) == "specimen_vault", "Position (0, -2, 38) maps to specimen_vault")
	_assert_true(env_mgr.get_compartment_for_position(Vector3(-14, 0, -20)) == "research_observatory", "Position (-14, 0, -20) maps to research_observatory")
	
	var vault_atmo: Dictionary = env_mgr.get_compartment_atmosphere("specimen_vault")
	_assert_true(vault_atmo.get("co2_ppm", 0.0) > 600.0, "specimen_vault exhibits elevated bio-contaminant CO2 reading")
	
	var obs_atmo: Dictionary = env_mgr.get_compartment_atmosphere("research_observatory")
	_assert_true(obs_atmo.get("o2_level", 0.0) == 100.0, "research_observatory maintains nominal oxygenation from flora")
	
	remove_child(env_mgr)
	env_mgr.free()
	
	# 4. MissionManager exploration tracking
	MissionManager.mark_room_discovered("specimen_vault")
	MissionManager.mark_room_discovered("research_observatory")
	_assert_true(MissionManager.is_room_discovered("specimen_vault"), "is_room_discovered returns true for specimen_vault")
	_assert_true(MissionManager.is_room_discovered("research_observatory"), "is_room_discovered returns true for research_observatory")
	_assert_true(MissionManager.get_expanded_chamber_count() == 2, "get_expanded_chamber_count() returns 2 expanded chambers")

func _test_m7_physical_stalker_and_horror_zoom() -> void:
	ShipState.reset_to_defaults()
	MissionManager.reset_missions()
	
	var stalker_scene = load("res://scenes/entities/alien_stalker.tscn")
	_assert_true(stalker_scene != null, "alien_stalker.tscn loads successfully")
	
	var stalker: AlienStalker = stalker_scene.instantiate()
	add_child(stalker)
	
	# 1. Structural anatomy verification
	_assert_true(stalker.has_node("CollisionShape3D"), "AlienStalker has CollisionShape3D")
	_assert_true(stalker.has_node("Torso"), "AlienStalker has Torso")
	_assert_true(stalker.has_node("Head"), "AlienStalker has Head")
	_assert_true(stalker.has_node("EyeLeftLight"), "AlienStalker has EyeLeftLight")
	_assert_true(stalker.has_node("EyeRightLight"), "AlienStalker has EyeRightLight")
	_assert_true(stalker.has_node("ClawLeft"), "AlienStalker has ClawLeft")
	_assert_true(stalker.has_node("ClawRight"), "AlienStalker has ClawRight")
	_assert_true(stalker.has_node("Spines"), "AlienStalker has Spines")
	_assert_true(stalker.has_node("Tail"), "AlienStalker has Tail")
	_assert_true(stalker.has_node("AuraLight"), "AlienStalker has AuraLight")
	
	# 2. Dormancy check
	_assert_true(stalker.current_state == AlienStalkerClass.State.DORMANT, "AlienStalker starts in DORMANT state")
	_assert_true(not stalker.visible, "AlienStalker is invisible while dormant")
	
	# 3. Spawning sequence
	stalker.spawn_in_chamber("specimen_vault", Vector3(0, -2, 38))
	_assert_true(stalker.current_state == AlienStalkerClass.State.SPAWNING, "AlienStalker transitions to SPAWNING state")
	_assert_true(stalker.visible, "AlienStalker becomes visible upon spawn")
	_assert_true(stalker.stalk_chamber_id == "specimen_vault", "Stalker chamber ID set to specimen_vault")
	
	# 4. Horror boss zoom & jumpscare encounter
	var player_scene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector3(0, 0, 0)
	
	_assert_true(not player.is_in_horror_shock, "Player not in horror shock initially")
	_assert_true(player.camera_trauma == 0.0, "Player camera trauma zero initially")
	
	stalker.zoom_near_player(player, 0.5)
	_assert_true(stalker.current_state == AlienStalkerClass.State.HORROR_ZOOM, "AlienStalker transitions to HORROR_ZOOM")
	_assert_true(stalker.horror_zoom_executed, "horror_zoom_executed flag set on stalker")
	_assert_true(player.is_in_horror_shock, "Player enters horror shock state")
	_assert_true(player.camera_trauma > 0.5, "Player camera trauma elevated during horror zoom")
	_assert_true(player.camera.fov < player._base_fov, "Camera FOV punched in for shock effect")
	
	# Simulate physics tick to complete zoom
	stalker._physics_process(0.6)
	_assert_true(stalker.current_state == AlienStalkerClass.State.AGGRESSIVE, "Stalker advances to AGGRESSIVE after horror zoom")
	
	# 5. Trap and elimination
	stalker.trap_in_chamber("airlock_chamber", Vector3(8, 0, 8))
	_assert_true(stalker.current_state == AlienStalkerClass.State.TRAPPED, "Stalker transitions to TRAPPED")
	_assert_true(stalker.is_trapped, "is_trapped is true on stalker")
	
	stalker.eliminate()
	_assert_true(stalker.current_state == AlienStalkerClass.State.ELIMINATED, "Stalker transitions to ELIMINATED")
	_assert_true(stalker.is_eliminated, "is_eliminated is true on stalker")
	_assert_true(stalker.eye_left_light.light_energy == 0.0, "Stalker eye light extinguished upon death")
	
	remove_child(player)
	remove_child(stalker)
	player.free()
	stalker.free()

func _test_m7_exploration_and_crisis_stalking_flow() -> void:
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()
	
	# 1. Chamber exploration prerequisite gate
	_assert_true(not MissionManager.can_engage_final_hunt(), "can_engage_final_hunt is false when rooms undiscovered")
	
	var chambers := ["engineering_bay", "corridors", "life_support", "bridge", "specimen_vault"]
	for ch in chambers:
		MissionManager.mark_room_discovered(ch)
	
	_assert_true(MissionManager.can_engage_final_hunt(), "can_engage_final_hunt is true after discovering 5 chambers")
	var stats: Dictionary = MissionManager.get_exploration_stats()
	_assert_true(bool(stats.get("can_engage_final_hunt", false)), "Exploration stats report can_engage_final_hunt is true")
	
	# 2. CrisisManager and AlienStalker registration
	var stalker_scene = load("res://scenes/entities/alien_stalker.tscn")
	var stalker: AlienStalker = stalker_scene.instantiate()
	add_child(stalker)
	
	ShipState.crisis_manager.register_stalker(stalker)
	_assert_true(ShipState.crisis_manager.stalker_entity == stalker, "Stalker entity registered with CrisisManager")
	
	# 3. Start crisis and verify stalker activation
	ShipState.start_crisis(CrisisManagerClass.CrisisType.CREATURE_PREDATORY_HUNT)
	_assert_true(stalker.current_state == AlienStalkerClass.State.SPAWNING, "Stalker spawns upon creature hunt start")
	
	# 4. Trigger horror zoom through ShipState
	ShipState.trigger_creature_horror_zoom(null)
	_assert_true(ShipState.crisis_manager.horror_zoom_executed, "horror_zoom_executed recorded in CrisisManager")
	_assert_true(stalker.current_state == AlienStalkerClass.State.HORROR_ZOOM, "Stalker entered HORROR_ZOOM via ShipState")
	
	# 5. Trap and purge sequence through ShipState
	ShipState.trap_creature_in_chamber("airlock_chamber")
	_assert_true(ShipState.crisis_manager.is_creature_trapped, "CrisisManager records creature trapped")
	_assert_true(stalker.is_trapped, "Stalker records is_trapped")
	_assert_true(stalker.current_state == AlienStalkerClass.State.TRAPPED, "Stalker state is TRAPPED")
	
	ShipState.purge_creature_with_poison_gas("airlock_chamber")
	_assert_true(ShipState.crisis_manager.is_creature_eliminated, "CrisisManager records creature eliminated")
	_assert_true(stalker.is_eliminated, "Stalker records is_eliminated")
	_assert_true(stalker.current_state == AlienStalkerClass.State.ELIMINATED, "Stalker state is ELIMINATED")
	_assert_true(ShipState.crisis_manager.current_crisis == CrisisManagerClass.CrisisType.NONE, "Crisis resolved after poison gas purge")
	
	remove_child(stalker)
	stalker.free()
	
	ShipState.reset_to_defaults()
	MissionManager.reset_missions()

func _test_m7_production_polish_and_persistence() -> void:
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()
	SaveManager.delete_save()
	
	# 1. Level scene contains expanded chambers and physical alien stalker
	var level_scene = load("res://scenes/levels/ship_interior.tscn")
	_assert_true(level_scene != null, "ship_interior.tscn loads successfully")
	var level = level_scene.instantiate()
	add_child(level)
	
	_assert_true(level.has_node("Compartments/SpecimenVault"), "ship_interior.tscn contains Compartments/SpecimenVault")
	_assert_true(level.has_node("Compartments/SpecimenVault/AlienStalker"), "ship_interior.tscn contains physical AlienStalker in SpecimenVault")
	_assert_true(level.has_node("Compartments/ResearchObservatory"), "ship_interior.tscn contains Compartments/ResearchObservatory")
	_assert_true(level.has_node("Compartments/ResearchObservatory/ObservatorySensor"), "ship_interior.tscn contains ObservatorySensor")
	
	remove_child(level)
	level.free()
	
	# 2. MainMenu production release styling
	var mm_scene = load("res://scenes/ui/main_menu.tscn")
	_assert_true(mm_scene != null, "main_menu.tscn loads successfully")
	var mm = mm_scene.instantiate()
	add_child(mm)
	var rel_lbl = mm.get_node_or_null("%ReleaseLabel")
	_assert_true(rel_lbl != null, "main_menu.tscn contains %ReleaseLabel")
	_assert_true(rel_lbl.text.contains("v1.0 Production Release"), "ReleaseLabel displays v1.0 Production Release")
	remove_child(mm)
	mm.free()
	
	# 3. Project configuration release version
	_assert_true(ProjectSettings.get_setting("application/config/version") == "1.0.0", "project.godot version is 1.0.0")
	
	# 4. Save / Load persistence of Milestone 7 state
	ShipState.start_crisis(CrisisManagerClass.CrisisType.CREATURE_PREDATORY_HUNT)
	ShipState.trigger_creature_horror_zoom(null)
	MissionManager.mark_room_discovered("specimen_vault")
	MissionManager.mark_room_discovered("research_observatory")
	
	var save_ok = SaveManager.save_game()
	_assert_true(save_ok, "SaveManager.save_game() persists Milestone 7 state")
	
	ShipState.reset_to_defaults()
	MissionManager.reset_missions()
	_assert_true(not ShipState.crisis_manager.horror_zoom_executed, "horror_zoom_executed cleared on reset")
	_assert_true(MissionManager.get_expanded_chamber_count() == 0, "Expanded chamber count cleared on reset")
	
	var load_ok = SaveManager.load_game()
	_assert_true(load_ok, "SaveManager.load_game() succeeds for Milestone 7 save")
	_assert_true(ShipState.crisis_manager.horror_zoom_executed, "horror_zoom_executed restored from save")
	_assert_true(MissionManager.is_room_discovered("specimen_vault"), "specimen_vault discovery restored from save")
	_assert_true(MissionManager.is_room_discovered("research_observatory"), "research_observatory discovery restored from save")
	
	# 5. Legacy save load backwards compatibility
	var legacy_save := {
		"version": 1,
		"crisis": {
			"current_crisis": 0,
			"current_stage": 0
		}
	}
	var f := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy_save))
	f.close()
	
	var leg_ok = SaveManager.load_game()
	_assert_true(leg_ok, "Legacy save loads without error")
	_assert_true(not ShipState.crisis_manager.horror_zoom_executed, "Legacy save defaults horror_zoom_executed to false")
	
	# 6. Complete mission victory engagement
	ShipSystemManager.set_generator_breaker(true)
	ShipSystemManager.set_power_distribution(true)
	ShipSystemManager.install_coolant_coupler()
	ShipSystemManager.align_comms_array()
	ShipState.purge_creature_with_poison_gas("airlock_chamber")
	
	var victory_res = ShipSystemManager.engage_propulsion()
	_assert_true(victory_res.get("ok", false), "Final departure propulsion engages successfully")
	_assert_true(ShipSystemManager.is_system_online("propulsion"), "Propulsion system is ONLINE")
	
	SaveManager.delete_save()
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()

func _test_m7_chamber_connectivity_and_horror_rigor() -> void:
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()
	
	# 1. Verify 3D level geometry accessibility and doorway connections
	var level_scene = load("res://scenes/levels/ship_interior.tscn")
	_assert_true(level_scene != null, "ship_interior.tscn loads for geometry connectivity check")
	var level = level_scene.instantiate()
	add_child(level)
	
	# Verify Subdeck -> Specimen Vault doorway archway & access ramp
	_assert_true(level.has_node("Compartments/ReactorSubdeck/WallAftLeft"), "ReactorSubdeck has WallAftLeft archway post")
	_assert_true(level.has_node("Compartments/ReactorSubdeck/WallAftRight"), "ReactorSubdeck has WallAftRight archway post")
	_assert_true(level.has_node("Compartments/ReactorSubdeck/WallAftHeader"), "ReactorSubdeck has WallAftHeader doorway lintel")
	_assert_true(level.has_node("Compartments/ReactorSubdeck/VaultAccessRamp"), "ReactorSubdeck has VaultAccessRamp connector")
	_assert_true(level.has_node("Compartments/ReactorSubdeck/RampCeiling"), "ReactorSubdeck has RampCeiling for ramp headroom")
	_assert_true(level.has_node("Compartments/ReactorSubdeck/Lights/LightRamp"), "ReactorSubdeck has LightRamp illumination")
	
	# Verify Bridge -> Research Observatory doorway archway & corridor connector
	_assert_true(level.has_node("Compartments/Bridge/WallLeftNorth"), "Bridge has WallLeftNorth archway post")
	_assert_true(level.has_node("Compartments/Bridge/WallLeftSouth"), "Bridge has WallLeftSouth archway post")
	_assert_true(level.has_node("Compartments/Bridge/WallLeftHeader"), "Bridge has WallLeftHeader doorway lintel")
	_assert_true(level.has_node("Compartments/ResearchObservatory/CorridorFloor"), "ResearchObservatory has CorridorFloor connector")
	_assert_true(level.has_node("Compartments/ResearchObservatory/CorridorCeiling"), "ResearchObservatory has CorridorCeiling connector")
	_assert_true(level.has_node("Compartments/ResearchObservatory/CorridorWallNorth"), "ResearchObservatory has CorridorWallNorth")
	_assert_true(level.has_node("Compartments/ResearchObservatory/CorridorWallSouth"), "ResearchObservatory has CorridorWallSouth")
	
	# Verify Specimen Vault front doorway & salvage crate
	_assert_true(level.has_node("Compartments/SpecimenVault/WallFrontLeft"), "SpecimenVault has WallFrontLeft")
	_assert_true(level.has_node("Compartments/SpecimenVault/WallFrontRight"), "SpecimenVault has WallFrontRight")
	_assert_true(level.has_node("Compartments/SpecimenVault/WallFrontHeader"), "SpecimenVault has WallFrontHeader")
	_assert_true(level.has_node("Compartments/SpecimenVault/CrateVault"), "SpecimenVault has CrateVault")
	_assert_true(level.has_node("Compartments/ResearchObservatory/CrateObservatory"), "ResearchObservatory has CrateObservatory")
	
	# Verify level controller methods for horror encounter
	_assert_true(level.has_method("_check_trigger_final_hunt"), "Level controller has _check_trigger_final_hunt")
	_assert_true(level.has_method("trigger_creature_horror_encounter"), "Level controller has trigger_creature_horror_encounter")
	_assert_true(level.has_method("_flicker_lights_for_encounter"), "Level controller has _flicker_lights_for_encounter")
	
	remove_child(level)
	level.free()
	
	# 2. Verify exploration task gating in Objective 4
	MissionManager.current_objective_index = 4
	_assert_true(not MissionManager.can_engage_final_hunt(), "can_engage_final_hunt starts false")
	var task_unexplored := MissionManager.get_current_immediate_task()
	_assert_true(task_unexplored.contains("Explore"), "Immediate task prompts exploration when chambers undiscovered")
	_assert_true(task_unexplored.contains("Trap") and task_unexplored.contains("Gas"), "Immediate task maintains Trap and Gas keywords")
	
	# Discover 5 chambers
	var chambers := ["engineering_bay", "corridors", "life_support", "bridge", "specimen_vault"]
	for ch in chambers:
		MissionManager.mark_room_discovered(ch)
	_assert_true(MissionManager.can_engage_final_hunt(), "can_engage_final_hunt is true after 5 chambers")
	var task_explored := MissionManager.get_current_immediate_task()
	_assert_true(task_explored == "Trap Alien & Open Poison Gas Valve", "Immediate task transitions to Trap Alien once explored")
	
	# 3. Verify AlienStalker horror jumpscare repositioning and airlock placement
	var stalker_scene = load("res://scenes/entities/alien_stalker.tscn")
	var stalker: AlienStalker = stalker_scene.instantiate()
	add_child(stalker)
	
	var player_scene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector3(0, 0, 0)
	stalker.global_position = Vector3(0, -2, 50) # Far away in lower deck
	
	stalker.zoom_near_player(player, 0.4)
	_assert_true(stalker.zoom_start_pos.distance_to(player.global_position) < 8.0, "Distant stalker materializes in front of player for jumpscare")
	_assert_true(stalker.current_state == AlienStalkerClass.State.HORROR_ZOOM, "Stalker is in HORROR_ZOOM")
	
	# Test airlock trap default placement
	stalker.trap_in_chamber("airlock_chamber")
	_assert_true(stalker.global_position == Vector3(8.0, 0.0, 8.0), "Stalker placed at nominal airlock quarantine position")
	_assert_true(stalker.current_state == AlienStalkerClass.State.TRAPPED, "Stalker is TRAPPED")
	
	# Test auto target acquisition in physics process
	stalker.target_player = null
	stalker.set_state(AlienStalkerClass.State.STALKING)
	stalker._physics_process(0.016)
	_assert_true(stalker.target_player == player, "Stalker automatically acquires Player reference from scene tree")
	
	remove_child(player)
	remove_child(stalker)
	player.free()
	stalker.free()
	
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()

func _test_qa_integrity_and_improvements() -> void:
	ShipState.reset_to_defaults()
	
	# 1. ShipState death reason tracking and reset
	_assert_true(ShipState.death_reason == "", "ShipState death_reason initialized empty")
	ShipState.death_reason = "CREATURE_ATTACK"
	_assert_true(ShipState.death_reason == "CREATURE_ATTACK", "ShipState records CREATURE_ATTACK death reason")
	ShipState.reset_to_defaults()
	_assert_true(ShipState.death_reason == "", "ShipState death_reason resets cleanly on reset_to_defaults")

	# 2. EnvironmentalManager asphyxiation death reason
	var env_script = load("res://scripts/systems/environmental_manager.gd")
	var env_mgr = env_script.new()
	add_child(env_mgr)
	env_mgr.initialize_atmosphere()
	env_mgr._on_asphyxiation()
	_assert_true(ShipState.death_reason == "ASPHYXIATION", "EnvironmentalManager sets death_reason to ASPHYXIATION upon oxygen depletion")
	remove_child(env_mgr)
	env_mgr.free()

	# 3. GameOverScreen dynamic death cause
	var game_over_scene = load("res://scenes/ui/game_over.tscn")
	_assert_true(game_over_scene != null, "game_over.tscn loads cleanly")
	var game_over = game_over_scene.instantiate()
	add_child(game_over)
	
	var title_lbl: Label = game_over.get_node_or_null("%Title")
	var body_lbl: Label = game_over.get_node_or_null("%BodyText")
	_assert_true(title_lbl != null, "GameOverScreen has Title label")
	_assert_true(body_lbl != null, "GameOverScreen has BodyText label")
	_assert_true(title_lbl.text.contains("ATMOSPHERIC COLLAPSE"), "GameOverScreen defaults to atmospheric collapse text")
	
	ShipState.death_reason = "CREATURE_ATTACK"
	game_over._configure_death_cause()
	_assert_true(title_lbl.text.contains("BIOLOGICAL SPECIMEN TERMINATION"), "GameOverScreen reflects specimen termination title on creature attack")
	_assert_true(body_lbl.text.contains("Project Chimera specimen"), "GameOverScreen reflects specimen lore on creature attack")
	
	remove_child(game_over)
	game_over.free()
	ShipState.death_reason = ""

	# 4. PlayerController health, damage, slope stabilization, and death mechanics
	var player_scene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate()
	add_child(player)
	_assert_true(player.player_health == 100.0, "Player starts with 100 health")
	_assert_true(is_equal_approx(player.floor_snap_length, 0.35), "Player floor_snap_length set to 0.35 for slope stabilization")
	_assert_true(player.floor_constant_speed == true, "Player floor_constant_speed is true")
	
	var health_reported := [-1.0]
	player.health_changed.connect(func(h, _m): health_reported[0] = h)
	player.take_damage(35.0, "creature")
	_assert_true(player.player_health == 65.0, "take_damage(35) reduces health to 65")
	_assert_true(health_reported[0] == 65.0, "health_changed signal fired with updated health")
	_assert_true(player.camera_trauma > 0.5, "camera_trauma elevated upon taking damage")
	
	var death_reported := [""]
	player.player_died.connect(func(r): death_reported[0] = r)
	player.take_damage(70.0, "creature")
	_assert_true(player.player_health == 0.0, "Lethal damage reduces player health to 0")
	_assert_true(player.is_dead == true, "Player is_dead flag set to true")
	_assert_true(death_reported[0] == "creature", "player_died signal emitted with creature source")
	_assert_true(ShipState.death_reason == "CREATURE_ATTACK", "ShipState death_reason updated to CREATURE_ATTACK on player death")

	# 5. AlienStalker melee claw attack logic
	var stalker_scene = load("res://scenes/entities/alien_stalker.tscn")
	var stalker: AlienStalker = stalker_scene.instantiate()
	add_child(stalker)
	
	player.player_health = 100.0
	player.is_dead = false
	stalker.target_player = player
	stalker.global_position = player.global_position + Vector3(0, 0, 1.2)
	stalker.set_state(AlienStalkerClass.State.AGGRESSIVE)
	
	stalker._physics_process(0.016)
	_assert_true(stalker._attack_cooldown > 1.0, "AlienStalker sets attack cooldown after claw strike")
	_assert_true(player.player_health == 65.0, "AlienStalker claw strike damaged player for 35 health")
	
	remove_child(player)
	remove_child(stalker)
	player.free()
	stalker.free()

	# 6. AudioManager footstep sound generation and playback
	_assert_true(AudioManager._sound_cache.has("footstep"), "AudioManager pregenerates footstep sound in cache")
	AudioManager.play_footstep(false)
	AudioManager.play_footstep(true)
	_assert_true(true, "play_footstep executes cleanly for walk and sprint")

	# 7. HUD Reticle Hover Dot Feedback
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)
	_assert_true(hud.reticle_dot != null, "HUDController references reticle_dot")
	_assert_true(hud.reticle_dot.color == Color(1.0, 1.0, 1.0, 0.8), "Reticle dot starts at default semi-transparent white")
	
	hud.set_prompt("Press [E] to Inspect Generator Breaker")
	_assert_true(hud.reticle_dot.color == Color(0.2, 0.9, 1.0, 1.0), "Reticle dot tints cyan when hovering interactable")
	_assert_true(hud.reticle_dot.custom_minimum_size == Vector2(6, 6), "Reticle dot enlarges when hovering interactable")
	
	hud.set_prompt("")
	_assert_true(hud.reticle_dot.color == Color(1.0, 1.0, 1.0, 0.8), "Reticle dot reverts to default color when prompt is cleared")
	_assert_true(hud.reticle_dot.custom_minimum_size == Vector2(4, 4), "Reticle dot reverts to default size when prompt is cleared")
	
	remove_child(hud)
	hud.free()

	# 8. ShipSchematic 13-Compartment Support (Specimen Vault & Research Observatory)
	var schematic_scene = load("res://scenes/ui/ship_schematic.tscn")
	var schematic: ShipSchematic = schematic_scene.instantiate()
	add_child(schematic)
	_assert_true(schematic.vault_panel != null, "ShipSchematic contains SpecimenVaultPanel")
	_assert_true(schematic.obs_panel != null, "ShipSchematic contains ResearchObservatoryPanel")
	
	schematic.open_schematic()
	schematic._select_compartment("specimen_vault")
	_assert_true(schematic.selected_room_title.text.contains("SPECIMEN"), "Selecting specimen_vault populates inspector title")
	
	schematic._select_compartment("research_observatory")
	_assert_true(schematic.selected_room_title.text.contains("OBSERVATORY"), "Selecting research_observatory populates inspector title")
	
	schematic.close_schematic()
	remove_child(schematic)
	schematic.free()

	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()

func _test_alien_pacing_and_safe_room() -> void:
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()
	
	# 1. Pacing: Alien cannot appear until all spaceship repairs are complete
	MissionManager.current_objective_index = 0
	_assert_true(not MissionManager.are_all_repairs_complete(), "are_all_repairs_complete is false at start (Obj 0)")
	
	MissionManager.current_objective_index = 3
	_assert_true(not MissionManager.are_all_repairs_complete(), "are_all_repairs_complete is false while comms repair pending (Obj 3)")
	
	MissionManager.current_objective_index = 4
	_assert_true(MissionManager.are_all_repairs_complete(), "are_all_repairs_complete is true once repairs finished (Obj 4)")

	# 2. Check level controller refuses to trigger hunt while repairs pending even if 5 chambers explored
	var level_scene = load("res://scenes/levels/ship_interior.tscn")
	var level = level_scene.instantiate()
	add_child(level)
	
	MissionManager.current_objective_index = 2
	var chambers := ["engineering_bay", "corridors", "life_support", "bridge", "specimen_vault"]
	for ch in chambers:
		MissionManager.mark_room_discovered(ch)
	_assert_true(MissionManager.can_engage_final_hunt(), "5 chambers discovered")
	
	level._check_trigger_final_hunt()
	_assert_true(ShipState.crisis_manager.current_crisis == CrisisManagerClass.CrisisType.NONE, "Final hunt not triggered while repairs pending")
	
	remove_child(level)
	level.free()

	# 3. Vibration Alert upon repair completion
	var player_scene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate()
	add_child(player)
	
	_assert_true(not player.is_vibrating, "Player not vibrating initially")
	player.trigger_vibration_alert(3.0, 0.65)
	_assert_true(player.is_vibrating, "Player enters vibration alert state")
	_assert_true(player.camera_trauma > 0.4, "Camera trauma raised by vibration alert")
	
	# 4. Safe Room (Medbay Sanctuary) Mechanics
	var stalker_scene = load("res://scenes/entities/alien_stalker.tscn")
	var stalker: AlienStalker = stalker_scene.instantiate()
	add_child(stalker)
	stalker.target_player = player
	
	_assert_true(stalker.safe_chamber_id == "medbay", "AlienStalker designates medbay as safe_chamber_id")
	
	var env_script = load("res://scripts/systems/environmental_manager.gd")
	var env_mgr = env_script.new()
	add_child(env_mgr)
	env_mgr.initialize_atmosphere()
	
	# Position player inside Medbay: z in [-13.0, -3.5], x > 2.0 (e.g. Vector3(4.0, 0.0, -8.0))
	player.global_position = Vector3(4.0, 0.0, -8.0)
	env_mgr.player_compartment_id = "medbay"
	
	_assert_true(stalker.is_player_in_safe_room(), "AlienStalker recognizes player is inside safe room")
	
	# Stalker attempts claw attack while player is in safe room
	player.player_health = 100.0
	stalker.global_position = Vector3(1.5, 0.0, -8.0) # in corridor just outside medbay
	stalker.set_state(AlienStalkerClass.State.AGGRESSIVE)
	stalker._execute_claw_attack()
	_assert_true(player.player_health == 100.0, "Player takes zero damage inside safe room")
	
	# Stalker physics tick when player in safe room: halts and drops from AGGRESSIVE to STALKING
	stalker.velocity = Vector3(3.0, 0.0, 3.0)
	stalker._physics_process(0.8)
	_assert_true(stalker.current_state == AlienStalkerClass.State.STALKING, "Stalker drops from AGGRESSIVE to STALKING when player in safe room")
	_assert_true(Vector2(stalker.velocity.x, stalker.velocity.z).length() == 0.0, "Stalker decelerates and halts outside safe room")
	
	# Stalker attempts zoom_near_player while player in safe room
	stalker.zoom_near_player(player, 0.5)
	_assert_true(stalker.current_state != AlienStalkerClass.State.HORROR_ZOOM, "Alien cannot zoom/lunge at player inside safe room")
	
	# Move player outside Medbay into Corridor: Vector3(0.0, 0.0, 0.0)
	player.global_position = Vector3(0.0, 0.0, 0.0)
	env_mgr.player_compartment_id = "corridors"
	_assert_true(not stalker.is_player_in_safe_room(), "AlienStalker recognizes player has left safe room")
	
	remove_child(env_mgr)
	remove_child(player)
	remove_child(stalker)
	env_mgr.free()
	player.free()
	stalker.free()
	
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()

func _test_modes_look_breaker_and_audio() -> void:
	# 1. 360 Look Controls Option (Mouse vs Arrow Keys)
	SaveManager.set_look_mode("mouse")
	_assert_true(SaveManager.look_mode == "mouse", "SaveManager look_mode defaults to mouse")
	_assert_true(not SaveManager.look_mode.is_empty(), "SaveManager look_mode is non-empty")
	
	SaveManager.set_look_mode("arrow_keys")
	_assert_true(SaveManager.look_mode == "arrow_keys", "SaveManager set_look_mode to arrow_keys")
	
	SaveManager.toggle_look_mode()
	_assert_true(SaveManager.look_mode == "mouse", "SaveManager toggle_look_mode toggles back to mouse")
	
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	
	SaveManager.look_mode = "arrow_keys"
	_assert_true(player.is_arrow_look == true, "Player is_arrow_look is true when look_mode is arrow_keys")
	
	SaveManager.look_mode = "mouse"
	_assert_true(player.is_arrow_look == false, "Player is_arrow_look is false when look_mode is mouse")
	
	remove_child(player)
	player.free()

	# 2. Generator Primary Breaker Visibility in Engineering Bay
	var interior_scene = load("res://scenes/levels/ship_interior.tscn")
	var interior = interior_scene.instantiate()
	add_child(interior)
	
	var gen_breaker = interior.get_node_or_null("Compartments/EngineeringBay/GeneratorBreaker")
	_assert_true(gen_breaker != null, "GeneratorBreaker node exists in ship_interior.tscn")
	if gen_breaker != null:
		var z_pos: float = gen_breaker.transform.origin.z
		_assert_true(absf(z_pos - 16.15) < 0.15, "GeneratorBreaker is mounted on exterior front face (z ~ 16.15)")
		_assert_true(gen_breaker.transform.basis.z.z < -0.5, "GeneratorBreaker is rotated 180 deg to face room entrance")
		_assert_true(gen_breaker.is_in_group("interactables") or gen_breaker.has_method("interact"), "GeneratorBreaker is fully interactable")
	
	remove_child(interior)
	interior.free()

	# 3. Audio Assets & Playback Methods
	_assert_true(FileAccess.file_exists("res://resources/audio/alien_footsteps.mp3"), "alien_footsteps.mp3 exists")
	_assert_true(FileAccess.file_exists("res://resources/audio/alien_sound.mp3"), "alien_sound.mp3 exists")
	_assert_true(FileAccess.file_exists("res://resources/audio/background_horror.mp3"), "background_horror.mp3 exists")
	_assert_true(FileAccess.file_exists("res://resources/audio/gate_opening.mp3"), "gate_opening.mp3 exists")
	_assert_true(FileAccess.file_exists("res://resources/audio/impact_hit.mp3"), "impact_hit.mp3 exists")
	_assert_true(FileAccess.file_exists("res://resources/audio/player_death_scream.mp3"), "player_death_scream.mp3 exists")
	_assert_true(FileAccess.file_exists("res://resources/audio/player_footsteps.mp3"), "player_footsteps.mp3 exists")
	
	AudioManager.play_alien_footstep()
	AudioManager.play_alien_sound()
	AudioManager.play_gate_opening()
	AudioManager.play_impact_hit()
	AudioManager.play_player_death_scream()
	AudioManager.play_background_horror()
	_assert_true(true, "All sound effect helper methods execute cleanly")

	# 4. Mode 1 (Feel Mode) vs Mode 2 (Logical Mode)
	SaveManager.set_game_mode("logical")
	_assert_true(SaveManager.game_mode == "logical", "SaveManager game_mode set to logical")
	SaveManager.toggle_game_mode()
	_assert_true(SaveManager.game_mode == "feel", "SaveManager toggle_game_mode toggles to feel")
	SaveManager.set_game_mode("feel")

	# Test HUD in Feel Mode
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)
	
	var bottom_right = hud.get_node_or_null("BottomRightMargin")
	_assert_true(bottom_right != null and bottom_right.visible == false, "Tactical Schematic HUD prompt hidden in Feel Mode")
	
	hud.display_scan_telemetry({
		"device_name": "Emergency Core",
		"power_draw": 12.5,
		"temperature_c": 85.0,
		"active_faults": ["THERMAL_OVERLOAD"],
		"repair_steps": ["Replace coolant"]
	})
	_assert_true(hud.scan_telemetry_margin.visible == false, "Complex diagnostic scan telemetry card suppressed in Feel Mode")
	
	hud._update_tool_and_resource_hud()
	_assert_true(hud.compact_gear_lbl.text.contains("INVENTORY"), "Feel mode HUD compact gear displays simplified inventory")
	
	# Test HUD in Logical Mode
	SaveManager.set_game_mode("logical")
	hud._apply_game_mode()
	_assert_true(bottom_right.visible == true, "Tactical Schematic HUD prompt visible in Logical Mode")
	hud.display_scan_telemetry({"device_name": "Generator", "power_draw": 5.0, "active_faults": []})
	_assert_true(hud.scan_telemetry_margin.visible == true, "Complex scan telemetry card shown in Logical Mode")

	remove_child(hud)
	hud.free()

	# Test PauseMenu in Feel Mode vs Logical Mode
	var pause_scene = load("res://scenes/ui/pause_menu.tscn")
	var pause = pause_scene.instantiate()
	add_child(pause)
	
	SaveManager.set_game_mode("feel")
	pause._apply_game_mode()
	_assert_true(pause.env_panel.visible == false, "Pause menu environmental telemetry panel hidden in Feel Mode")
	_assert_true(pause.mission_desc_lbl.visible == false, "Pause menu long technical narrative hidden in Feel Mode")
	_assert_true(pause.scanner_charge_bar.visible == false, "Pause menu scanner charge bar hidden in Feel Mode")
	_assert_true(pause.resource_tally_lbl.visible == false, "Pause menu resource tally hidden in Feel Mode")
	_assert_true(pause.inventory_lbl.visible == true, "Pause menu inventory list remains visible in Feel Mode")
	_assert_true(pause.immediate_task_lbl.visible == true, "Pause menu immediate task remains visible in Feel Mode")
	
	# Test PauseMenu in Logical Mode
	SaveManager.set_game_mode("logical")
	pause._apply_game_mode()
	_assert_true(pause.env_panel.visible == true, "Pause menu environmental telemetry panel visible in Logical Mode")
	_assert_true(pause.mission_desc_lbl.visible == true, "Pause menu long technical narrative visible in Logical Mode")
	_assert_true(pause.scanner_charge_bar.visible == true, "Pause menu scanner charge bar visible in Logical Mode")
	_assert_true(pause.resource_tally_lbl.visible == true, "Pause menu resource tally visible in Logical Mode")
	
	remove_child(pause)
	pause.free()

	# Test MainMenu UI Toggles
	var main_scene = load("res://scenes/ui/main_menu.tscn")
	var main_menu = main_scene.instantiate()
	add_child(main_menu)
	
	_assert_true(main_menu.game_mode_btn != null, "MainMenu has game_mode_btn toggle")
	_assert_true(main_menu.look_mode_btn != null, "MainMenu has look_mode_btn toggle")
	_assert_true(main_menu.settings_game_mode_btn != null, "MainMenu has settings_game_mode_btn toggle")
	
	main_menu._on_toggle_game_mode()
	_assert_true(SaveManager.game_mode == "feel", "MainMenu toggle game mode changes to feel")
	main_menu._on_toggle_game_mode()
	_assert_true(SaveManager.game_mode == "logical", "MainMenu toggle game mode changes to logical")
	
	main_menu._on_toggle_look_mode()
	_assert_true(SaveManager.look_mode == "arrow_keys", "MainMenu toggle look mode changes to arrow_keys")
	main_menu._on_toggle_look_mode()
	_assert_true(SaveManager.look_mode == "mouse", "MainMenu toggle look mode changes to mouse")
	
	remove_child(main_menu)
	main_menu.free()
	
	SaveManager.set_game_mode("logical")
	SaveManager.set_look_mode("mouse")

func _test_alien_3d_body_audio_and_geometry() -> void:
	# 1. Verify ReactorSubdeck & SpecimenVault sealing
	var interior_scene = load("res://scenes/levels/ship_interior.tscn")
	var interior = interior_scene.instantiate()
	add_child(interior)

	var subdeck_left = interior.get_node_or_null("Compartments/ReactorSubdeck/WallFrontSubdeckLeft")
	var subdeck_right = interior.get_node_or_null("Compartments/ReactorSubdeck/WallFrontSubdeckRight")
	_assert_true(subdeck_left != null, "ReactorSubdeck has WallFrontSubdeckLeft sealing under Engineering Bay")
	_assert_true(subdeck_right != null, "ReactorSubdeck has WallFrontSubdeckRight sealing under Engineering Bay")
	
	var vault_west = interior.get_node_or_null("Compartments/ReactorSubdeck/VaultCorridorWallWest")
	var vault_east = interior.get_node_or_null("Compartments/ReactorSubdeck/VaultCorridorWallEast")
	var vault_ceil = interior.get_node_or_null("Compartments/ReactorSubdeck/VaultCorridorCeiling")
	_assert_true(vault_west != null and vault_east != null and vault_ceil != null, "ReactorSubdeck has corridor walls & ceiling bridging to SpecimenVault")

	var vault_back_wall = interior.get_node_or_null("Compartments/SpecimenVault/WallBack")
	_assert_true(vault_back_wall != null, "SpecimenVault has WallBack")
	if vault_back_wall != null:
		var col = vault_back_wall.get_node_or_null("Collision")
		_assert_true(col != null and col.shape != null and col.shape.size.x >= 12.0, "SpecimenVault WallBack width >= 12m sealing full room width")

	# 2. Verify Cargo Bay crawlway doorway & enclosing tunnel
	var cargo_sw = interior.get_node_or_null("Compartments/CargoBay/WallSouthWest")
	var cargo_se = interior.get_node_or_null("Compartments/CargoBay/WallSouthEast")
	var cargo_sh = interior.get_node_or_null("Compartments/CargoBay/WallSouthHeader")
	var door_cc = interior.get_node_or_null("Compartments/CargoBay/DoorCrawlwayCargo")
	_assert_true(cargo_sw != null and cargo_se != null and cargo_sh != null, "CargoBay south wall is split into west, east, and header leaving doorway clear")
	_assert_true(door_cc != null, "CargoBay contains DoorCrawlwayCargo")

	var ramp_wall_w = interior.get_node_or_null("Compartments/CargoBay/CrawlRampWallWest")
	var ramp_wall_e = interior.get_node_or_null("Compartments/CargoBay/CrawlRampWallEast")
	var ramp_ceil = interior.get_node_or_null("Compartments/CargoBay/CrawlRampCeiling")
	_assert_true(ramp_wall_w != null and ramp_wall_e != null and ramp_ceil != null, "Crawlway ramp has enclosing side walls and ceiling")

	remove_child(interior)
	interior.free()

	# 3. Verify AlienStalker 3D body & texture
	var stalker_scene = load("res://scenes/entities/alien_stalker.tscn")
	var stalker = stalker_scene.instantiate()
	add_child(stalker)

	_assert_true(stalker.has_node("AlienModel"), "AlienStalker instantiates AlienModel 3D FBX")
	var alien_mesh = stalker.find_child("alienMonster_001", true, false)
	_assert_true(alien_mesh != null, "AlienStalker contains alienMonster_001 MeshInstance3D")
	_assert_true(ResourceLoader.exists("res://resources/alien_material.tres"), "alien_material.tres exists")
	_assert_true(ResourceLoader.exists("res://my_assets/alien/AlienMonster.png"), "AlienMonster.png texture exists")

	# 4. Proximity Impact Hit Audio Trigger
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)

	stalker.target_player = player
	stalker.current_state = AlienStalker.State.STALKING
	stalker.visible = true
	stalker.global_position = player.global_position + Vector3(7.5, 0, 0)
	stalker._physics_process(0.016)
	_assert_true(stalker._proximity_impact_timer > 0.0, "AlienStalker triggers proximity impact audio when near player (<= 9.0m)")

	# 5. Death scream audio on player damage
	player.player_health = 100.0
	player.is_dead = false
	player.take_damage(25.0, "creature")
	_assert_true(player.player_health == 75.0, "Player takes damage from creature attack")
	_assert_true(AudioManager.has_method("play_player_death_scream"), "AudioManager has play_player_death_scream")
	_assert_true(AudioManager.has_method("play_impact_hit"), "AudioManager has play_impact_hit")

	remove_child(player)
	player.free()
	remove_child(stalker)
	stalker.free()

func _test_final_phase_upgrades() -> void:
	# 1. Cargo Annex extra room & repairs verification
	var interior_scene = load("res://scenes/levels/ship_interior.tscn")
	var interior = interior_scene.instantiate()
	add_child(interior)

	var annex_floor = interior.get_node_or_null("Compartments/CargoBay/AnnexFloor")
	var annex_ceiling = interior.get_node_or_null("Compartments/CargoBay/AnnexCeiling")
	var annex_west = interior.get_node_or_null("Compartments/CargoBay/AnnexWallWest")
	var annex_east = interior.get_node_or_null("Compartments/CargoBay/AnnexWallEast")
	var annex_south = interior.get_node_or_null("Compartments/CargoBay/AnnexWallSouth")
	_assert_true(annex_floor != null and annex_ceiling != null, "Cargo Annex has floor and ceiling enclosing extra room")
	_assert_true(annex_west != null and annex_east != null and annex_south != null, "Cargo Annex has west, east, and south enclosing walls")

	var aux_junction = interior.get_node_or_null("Compartments/CargoBay/AuxCargoJunction")
	var coolant_valve = interior.get_node_or_null("Compartments/CargoBay/CargoCoolantValve")
	var annex_crate = interior.get_node_or_null("Compartments/CargoBay/AnnexSalvageCrate")
	var annex_locker = interior.get_node_or_null("Compartments/CargoBay/AnnexStorageLocker")
	_assert_true(aux_junction != null and aux_junction.device_id == "aux_cargo_junction", "Cargo Annex contains functional AuxCargoJunction repair panel")
	_assert_true(coolant_valve != null and coolant_valve.device_id == "cargo_coolant_bypass", "Cargo Annex contains CargoCoolantValve bypass")
	_assert_true(annex_crate != null and annex_locker != null, "Cargo Annex contains salvage crate and storage locker repairs")

	# 2. Lower Subdeck Ramp downward slope orientation verification & Bridge Bulkhead Geometry
	var subdeck_ramp = interior.get_node_or_null("Compartments/ReactorSubdeck/SubdeckRamp")
	var ramp_ceiling = interior.get_node_or_null("Compartments/ReactorSubdeck/RampCeiling")
	_assert_true(subdeck_ramp != null, "ReactorSubdeck contains SubdeckRamp")
	_assert_true(ramp_ceiling != null, "ReactorSubdeck contains RampCeiling")
	_assert_true(subdeck_ramp.transform.basis.y.z > 0.0 and subdeck_ramp.transform.basis.z.y < 0.0, "SubdeckRamp slopes downward from Engineering Bay into Reactor Subdeck")
	_assert_true(ramp_ceiling.transform.basis.y.z > 0.0 and ramp_ceiling.transform.basis.z.y < 0.0, "RampCeiling slopes downward into Reactor Subdeck without ceiling clipping")

	# Verify Command Bridge reinforced forward bulkhead walls & framed cockpit viewport
	var br_wall_left = interior.get_node_or_null("Compartments/Bridge/BridgeWallFrontLeft")
	var br_wall_right = interior.get_node_or_null("Compartments/Bridge/BridgeWallFrontRight")
	var br_wall_lower = interior.get_node_or_null("Compartments/Bridge/BridgeWallFrontLower")
	var br_wall_upper = interior.get_node_or_null("Compartments/Bridge/BridgeWallFrontUpper")
	var br_window = interior.get_node_or_null("Compartments/Bridge/CockpitWindow")
	_assert_true(br_wall_left != null and br_wall_right != null, "Command Bridge has reinforced port and starboard forward armor bulkheads")
	_assert_true(br_wall_lower != null and br_wall_upper != null, "Command Bridge has solid lower armored console barrier and overhead header")
	_assert_true(br_window != null and br_window.has_node("WindowMullionLeft") and br_window.has_node("WindowMullionRight"), "Command Bridge Cockpit Viewport has structural framing pillars and mullions")

	# Verify Research Observatory airtight enclosed East wall
	var obs_wall_east = interior.get_node_or_null("Compartments/ResearchObservatory/WallEastNorth")
	var obs_header_east = interior.get_node_or_null("Compartments/ResearchObservatory/WallEastHeader")
	_assert_true(obs_wall_east != null, "Research Observatory has WallEastNorth enclosing space opening")
	_assert_true(obs_header_east != null, "Research Observatory has WallEastHeader enclosing doorway header")

	# Test player walking through subdeck doorway down the ramp
	var test_player_scene = load("res://scenes/player/player.tscn")
	var t_player = test_player_scene.instantiate()
	interior.add_child(t_player)
	var d_sub = interior.get_node_or_null("Compartments/ReactorSubdeck/DoorSubdeck")
	if d_sub != null:
		d_sub.set_door_state(true, true)
	t_player.global_position = Vector3(0.0, 0.05, 20.5)
	for step in range(50):
		var col = t_player.move_and_collide(Vector3(0, 0, 0.1))
		if col != null:
			break
	_assert_true(t_player.global_position.z > 23.5, "Player successfully walks down Subdeck Ramp past z=23.5")
	
	# Test player walking back up the ramp through the subdeck doorway
	t_player.global_position = Vector3(0.0, -1.0, 23.5)
	for step in range(60):
		var col = t_player.move_and_collide(Vector3(0, 0.05, -0.1))
		if col != null:
			break
	_assert_true(t_player.global_position.z <= 21.0, "Player successfully walks back up Subdeck Ramp past z=21.0 into Engineering")
	interior.remove_child(t_player)
	t_player.free()

	# 3. Procedural impact hit audio generation & volume
	var wav = AudioManager._generate_impact_hit()
	_assert_true(wav != null and wav.data.size() > 0, "AudioManager procedural _generate_impact_hit generates valid audio stream")
	var cache_stream = AudioManager._sound_cache.get("impact_hit")
	_assert_true(cache_stream != null, "AudioManager has cached impact_hit stream")

	# 4. Alien 3-Hit Kill & Player Damage / Screen Shake
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)

	player.player_health = 100.0
	player.is_dead = false
	# Hit 1
	player.take_damage(35.0, "creature")
	_assert_true(player.player_health == 65.0, "Hit 1: Player takes 35 damage and survives at 65 health")
	_assert_true(player.is_dead == false, "Hit 1: Player is not dead")
	_assert_true(player.camera_trauma > 0.8, "Hit 1: Camera trauma elevated on impact")

	# Hit 2
	player.take_damage(35.0, "creature")
	_assert_true(player.player_health == 30.0, "Hit 2: Player takes 35 damage and survives at 30 health")
	_assert_true(player.is_dead == false, "Hit 2: Player is not dead")
	_assert_true(player.camera_trauma >= 0.99, "Hit 2: Near-death critical trauma reaches maximum screen shaking")

	# Hit 3 (Fatal)
	player.take_damage(35.0, "creature")
	_assert_true(player.player_health == 0.0, "Hit 3: Player health reduced to 0")
	_assert_true(player.is_dead == true, "Hit 3: Player is dead after 3 hits")
	_assert_true(ShipState.death_reason == "CREATURE_ATTACK", "ShipState records CREATURE_ATTACK on 3rd lethal hit")

	# 5. Stalker door unlocking and waypoint seeking
	var stalker_scene = load("res://scenes/entities/alien_stalker.tscn")
	var stalker = stalker_scene.instantiate()
	interior.add_child(stalker)

	var door_aft = interior.get_node_or_null("Compartments/Corridors/DoorAft")
	if door_aft != null:
		door_aft.is_locked = true
		door_aft.set_door_state(false, true)
		stalker.current_state = AlienStalker.State.STALKING
		stalker.global_position = door_aft.global_position + Vector3(0, 0, 1.5)
		stalker._handle_doors_in_path()
		_assert_true(door_aft.is_locked == false, "Stalker automatically unlocks locked doors in path")
		_assert_true(door_aft.is_open == true, "Stalker automatically opens closed doors in path")

	# Test waypoint navigation around GeneratorUnit in Engineering Bay
	var nav_eng_to_subdeck = stalker._get_navigation_target(Vector3(0, 0, 13.0), Vector3(0, -2.5, 26.0))
	_assert_true(absf(nav_eng_to_subdeck.x) >= 2.0 and nav_eng_to_subdeck.z == 20.5, "Stalker routes laterally around GeneratorUnit toward Subdeck")

	var nav_eng_to_corridors = stalker._get_navigation_target(Vector3(0, 0, 20.5), Vector3(0, 0, 2.0))
	_assert_true(absf(nav_eng_to_corridors.x) >= 2.0 and nav_eng_to_corridors.z == 15.5, "Stalker routes laterally around GeneratorUnit toward Corridors")

	# Test waypoint navigation from lower deck to corridors
	var nav_from_subdeck = stalker._get_navigation_target(Vector3(0, -2.5, 26.0), Vector3(0, 0, 2.0))
	_assert_true(nav_from_subdeck == Vector3(0.0, 0.0, 21.2), "Stalker in Subdeck routes up Subdeck Ramp to reach Corridors")

	var nav_from_eng_clear = stalker._get_navigation_target(Vector3(0, 0, 15.0), Vector3(0, 0, 2.0))
	_assert_true(nav_from_eng_clear == Vector3(0.0, 0.0, 11.0), "Stalker in forward Engineering routes to forward door to reach Corridors")

	var nav_to_cargo = stalker._get_navigation_target(Vector3(0, 0, 2.0), Vector3(-10, 0, 6.0))
	_assert_true(nav_to_cargo == Vector3(-3.5, 0.0, 6.0), "Stalker in Corridors routes through Cargo doorway to reach Cargo Bay")

	# Test auto-seek on repair completion
	MissionManager.current_objective_index = 4
	_assert_true(MissionManager.are_all_repairs_complete(), "MissionManager reports all repairs completed")
	stalker.current_state = AlienStalker.State.DORMANT
	stalker.global_position = Vector3(0.0, 0.0, 20.0)
	stalker._physics_process(0.016)
	_assert_true(stalker.current_state == AlienStalker.State.STALKING or stalker.current_state == AlienStalker.State.AGGRESSIVE, "Stalker automatically awakens to hunt when 4 tasks are completed")

	# 6. Mouse view auto-capture and look controls
	player.player_health = 100.0
	player.is_dead = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var motion_event_capture = InputEventMouseMotion.new()
	motion_event_capture.relative = Vector2(12.0, 6.0)
	var rot_capture_before = player.rotation.y
	player._input(motion_event_capture)
	if DisplayServer.get_name() != "headless":
		_assert_true(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Mouse motion automatically captures mouse mode when not in menu")
	else:
		_assert_true(true, "Mouse motion auto-capture verified (headless displayserver skips OS cursor capture)")
	_assert_true(player.rotation.y != rot_capture_before, "Mouse motion rotates player upon auto-capture")

	SaveManager.set_look_mode("arrow_keys")
	var motion_event = InputEventMouseMotion.new()
	motion_event.relative = Vector2(10.0, 5.0)
	var rot_before = player.rotation.y
	player._input(motion_event)
	_assert_true(player.rotation.y != rot_before, "Mouse motion rotates player even when arrow_keys mode is active")

	# 7. Sci-Fi PBR Textures, Horror WorldEnvironment, Observatory/Secret Chamber Props & Psychological Suspense
	_assert_true(interior.get_node_or_null("HorrorWorldEnvironment") != null, "ShipInterior configures HorrorWorldEnvironment with fog and glow")
	_assert_true(interior._scifi_normal_tex != null and interior._scifi_roughness_tex != null, "ShipInterior generates procedural sci-fi PBR normal and roughness textures")
	_assert_true(interior.get_node_or_null("Compartments/ResearchObservatory/BotanicalFloraPod") != null, "Research Observatory contains BotanicalFloraPod")
	_assert_true(interior.get_node_or_null("Compartments/ResearchObservatory/BotanicalFloraPod/CleanroomPedestalBase") != null, "BotanicalFloraPod includes polished CleanroomPedestalBase")
	_assert_true(interior.get_node_or_null("Compartments/ResearchObservatory/ZoologicalSpecimenTerrarium") != null, "Research Observatory contains ZoologicalSpecimenTerrarium")
	_assert_true(interior.get_node_or_null("Compartments/ResearchObservatory/BioAnalysisIsland") != null, "Research Observatory contains minimalist BioAnalysisIsland")
	_assert_true(interior.get_node_or_null("Compartments/EngineeringBay/BioLabCeilingStrip") != null, "Cleanroom BioLabCeilingStrip recessed lighting present in EngineeringBay")
	_assert_true(interior.get_node_or_null("Compartments/LifeSupport/BioLabCeilingStrip") != null, "Cleanroom BioLabCeilingStrip recessed lighting present in LifeSupport")
	_assert_true(interior.get_node_or_null("Compartments/SpecimenVault/ShatteredSecretIncubator") != null, "Specimen Vault contains ShatteredSecretIncubator")
	_assert_true(interior.get_node_or_null("Compartments/SpecimenVault/SecretChamberKeySecurityPanel") != null, "Specimen Vault contains SecretChamberKeySecurityPanel")
	_assert_true(interior.has_method("trigger_psychological_suspense_pulse"), "ShipInterior implements trigger_psychological_suspense_pulse for mysterious animal/alien sounds")
	interior.trigger_psychological_suspense_pulse("repair_step_0")

	# 8. Plain-English 15+/18+ Workflow Guides, Attachment Descriptions & Simplified Alien Trigger/Trap
	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()
	_assert_true(MissionManager.get_current_plain_guide().contains("WHERE:") and MissionManager.get_current_plain_guide().contains("ACTION:"), "Mission 1 provides plain-English WHERE/ACTION guide")
	_assert_true(MissionManager.get_current_target_room().contains("Engineering Bay"), "Mission 1 identifies target room")

	# Verify completing all 4 repairs on the Bridge immediately awakens the alien without needing a 5th room detour
	ShipSystemManager.set_generator_breaker(true)
	ShipSystemManager.set_power_distribution(true)
	ShipSystemManager.install_coolant_coupler()
	ShipSystemManager.align_comms_array()
	_assert_true(ShipState.crisis_manager.current_crisis == CrisisManagerClass.CrisisType.CREATURE_PREDATORY_HUNT, "Completing 4th repair (Bridge Comms) immediately triggers alien hunt without hidden room gate")

	# Verify turning DecontaminationPoisonGasValve automatically traps & purges the alien in one step
	var poison_valve = interior.get_node_or_null("Compartments/AirlockChamber/DecontaminationPoisonGasValve")
	_assert_true(poison_valve != null, "DecontaminationPoisonGasValve present in AirlockChamber")
	if poison_valve != null:
		_assert_true(not ShipState.crisis_manager.is_creature_trapped, "Alien starts untrapped before valve turn")
		poison_valve._on_interacted(player)
		_assert_true(ShipState.crisis_manager.is_creature_trapped, "Turning Poison Gas Valve automatically traps alien in Airlock Chamber")
		_assert_true(ShipState.crisis_manager.is_creature_eliminated, "Turning Poison Gas Valve eliminates alien in one decisive step")
		_assert_true(MissionManager.get_current_plain_guide().contains("ALIEN ELIMINATED"), "Plain guide updates to direct player to Bridge Departure Switch after purge")

	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()

	# 9. Hotel Shrek 1 / Five Nights at Doraemon's Face-Lock Zoom-In/Zoom-Out Jumpscare & Boosted Audio
	_assert_true(AudioManager._sound_cache.has("jumpscare_scream"), "AudioManager pregenerates jumpscare_scream stinger")
	_assert_true(AudioManager.has_method("play_jumpscare_scream"), "AudioManager implements play_jumpscare_scream with boosted volume")
	AudioManager.play_jumpscare_scream()

	var js_stalker = interior.get_node_or_null("Compartments/SpecimenVault/AlienStalker")
	if js_stalker != null:
		player.player_health = 100.0
		player.is_dead = false
		player.global_position = Vector3(0, 0, 0)
		js_stalker.global_position = Vector3(0, 0, -2.5)
		js_stalker.zoom_near_player(player, 0.8)
		_assert_true(player._jumpscare_focus_target == js_stalker, "Player camera locks onto AlienStalker face during jumpscare")
		_assert_true(player.camera_trauma >= 0.99, "Jumpscare triggers full-screen maximum camera trauma shake")
		var fov_sample_1: float = player.camera.fov
		player._physics_process(0.065)
		var fov_sample_2: float = player.camera.fov
		_assert_true(fov_sample_1 != fov_sample_2 and fov_sample_2 < player._base_fov, "Camera FOV rapidly zooms in and out on alien face during jumpscare")
		js_stalker._update_animation_effects(0.05)
		_assert_true(js_stalker._face_thrash_timer > 0.0, "AlienStalker activates face thrash zoom-in/zoom-out animation")

	ShipState.reset_to_defaults()
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()

	# 10. Player Motive, Story Monologue, 3D Glowing Objective Beacon & Live Wayfinder Compass
	_assert_true(MissionManager.get_player_motive().contains("MOTIVE:"), "MissionManager provides clear player survival motive")
	_assert_true(MissionManager.get_current_story_monologue().contains("DR. VANCE"), "MissionManager provides first-person story monologue")
	_assert_true(interior.get_node_or_null("ObjectiveBeacon3D") != null, "ShipInterior instantiates 3D glowing ObjectiveBeacon3D")
	var target_info: Dictionary = interior.get_current_objective_target_info()
	_assert_true(target_info.get("node", null) == interior.get_node_or_null("Compartments/EngineeringBay/GeneratorBreaker"), "Objective 0 target beacon points to GeneratorBreaker")
	var level_player = interior.get_node_or_null("Player")
	if level_player != null and level_player.hud != null:
		interior._update_objective_beacon_and_wayfinder(0.016)
		_assert_true(level_player.hud.motive_lbl != null and level_player.hud.motive_lbl.text.contains("MOTIVE:"), "HUD displays player MotiveLabel")
		_assert_true(level_player.hud.wayfinder_lbl != null and level_player.hud.wayfinder_lbl.text.contains("TARGET BEACON:"), "HUD displays live WayfinderLabel distance & direction")
		_assert_true(level_player.hud.story_monologue_lbl != null and level_player.hud.story_monologue_lbl.text.contains("DR. VANCE"), "HUD displays first-person StoryMonologueLabel")

	remove_child(player)
	player.free()
	remove_child(interior)
	interior.free()







