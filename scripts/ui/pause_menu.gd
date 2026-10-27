class_name PauseMenu
extends Control

# Pause Menu & INFO Dashboard for ORBITAL: The Last Engineer
# Milestone 6: Presents detailed environmental telemetry, full mission storyline briefing,
# engineer gear status, and game controls upon pause/INFO request.

signal resumed

@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var volume_slider: HSlider = %VolumeSlider
@onready var save_notice_label: Label = %SaveNoticeLabel

# Mode & Look Toggles
@onready var look_mode_btn: Button = get_node_or_null("%LookModeButton")
@onready var game_mode_btn: Button = get_node_or_null("%GameModeButton")
@onready var mode_desc_lbl: Label = get_node_or_null("%ModeDescLabel")
@onready var env_panel: Control = get_node_or_null("%EnvPanel")
@onready var header_title_lbl: Label = get_node_or_null("Center/Panel/Margin/VBox/HeaderHBox/Title")
@onready var mission_header_lbl: Label = get_node_or_null("Center/Panel/Margin/VBox/ColumnsHBox/MissionPanel/MissionMargin/MissionVBox/MissionHeader")
@onready var gear_header_lbl: Label = get_node_or_null("Center/Panel/Margin/VBox/ColumnsHBox/GearPanel/GearMargin/GearVBox/GearHeader")

# Telemetry Nodes
@onready var location_lbl: Label = get_node_or_null("%LocationLabel")
@onready var o2_status_lbl: Label = get_node_or_null("%OxygenStatusLabel")
@onready var o2_bar: ProgressBar = get_node_or_null("%OxygenBar")
@onready var co2_status_lbl: Label = get_node_or_null("%CO2StatusLabel")
@onready var metrics_lbl: Label = get_node_or_null("%AtmosphereMetricsLabel")
@onready var hazard_lbl: Label = get_node_or_null("%HazardLabel")

# Mission Nodes
@onready var mission_title_lbl: Label = get_node_or_null("%PauseMissionTitle")
@onready var immediate_task_lbl: Label = get_node_or_null("%PauseImmediateTask")
@onready var mission_desc_lbl: Label = get_node_or_null("%PauseMissionDesc")

# Gear & Storage Nodes
@onready var equipped_tool_lbl: Label = get_node_or_null("%EquippedToolLabel")
@onready var scanner_charge_lbl: Label = get_node_or_null("%ScannerChargeLabel")
@onready var scanner_charge_bar: ProgressBar = get_node_or_null("%ScannerChargeBar")
@onready var resource_tally_lbl: Label = get_node_or_null("%ResourceTallyLabel")
@onready var quick_slots_lbl: Label = get_node_or_null("%QuickSlotsLabel")
@onready var inventory_lbl: Label = get_node_or_null("%InventoryLabel")

var _player_ref: Node3D = null
var _last_oxygen: float = 100.0
var _is_oxygen_depleting: bool = false
var _last_afflictions: Array[String] = []
var _last_telem: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	save_notice_label.text = ""
	
	%ResumeButton.pressed.connect(resume_game)
	%SaveButton.pressed.connect(_on_save_pressed)
	%MainMenuButton.pressed.connect(_on_main_menu_pressed)
	
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	# Initialize slider values
	sensitivity_slider.value = SaveManager.mouse_sensitivity * 1000.0
	volume_slider.value = SaveManager.master_volume * 100.0
	
	if look_mode_btn != null:
		look_mode_btn.pressed.connect(_on_look_mode_pressed)
	if game_mode_btn != null:
		game_mode_btn.pressed.connect(_on_game_mode_pressed)
	
	if SaveManager.has_signal("look_mode_changed"):
		SaveManager.look_mode_changed.connect(func(_m): _update_look_mode_ui())
	if SaveManager.has_signal("game_mode_changed"):
		SaveManager.game_mode_changed.connect(func(_m): _apply_game_mode())
	
	_update_look_mode_ui()
	_apply_game_mode()

func _on_look_mode_pressed() -> void:
	AudioManager.play_sfx("click")
	SaveManager.toggle_look_mode()
	_update_look_mode_ui()

func _on_game_mode_pressed() -> void:
	AudioManager.play_sfx("click")
	SaveManager.toggle_game_mode()
	_apply_game_mode()

func _update_look_mode_ui() -> void:
	if look_mode_btn != null:
		var is_arrows := (SaveManager.look_mode == "arrow_keys" or SaveManager.look_mode == "arrows")
		look_mode_btn.text = "LOOK: ARROW KEYS (360°)" if is_arrows else "LOOK: MOUSE (360°)"
		look_mode_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6) if is_arrows else Color(0.2, 0.85, 1.0))

func _apply_game_mode() -> void:
	var is_feel: bool = (SaveManager.game_mode == "feel")
	
	if game_mode_btn != null:
		game_mode_btn.text = "MODE: FEEL (CASUAL)" if is_feel else "MODE: LOGICAL (ENGINEERING)"
		game_mode_btn.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2) if is_feel else Color(0.2, 0.85, 1.0))
	
	if mode_desc_lbl != null:
		mode_desc_lbl.text = "Feel Mode: Pure horror atmosphere, tasks & inventory without complex data." if is_feel else "Logical Mode: Full engineering diagnostics & science telemetry."
	
	if header_title_lbl != null:
		header_title_lbl.text = "ORBITAL [PAUSED]" if is_feel else "STATION OPERATIONS & ENVIRONMENTAL TELEMETRY [PAUSED]"
	
	if mission_header_lbl != null:
		mission_header_lbl.text = "MISSION OBJECTIVE" if is_feel else "SCIENTIST MISSION DIRECTIVE"
	
	if gear_header_lbl != null:
		gear_header_lbl.text = "INVENTORY" if is_feel else "SCIENTIST GEAR & STORAGE"
	
	# In Feel Mode: Hide atmospheric / environmental telemetry panel completely
	if env_panel != null:
		env_panel.visible = not is_feel
	
	# In Feel Mode: In MissionPanel, hide long technical briefing
	if mission_desc_lbl != null:
		mission_desc_lbl.visible = not is_feel
	
	# In Feel Mode: In GearPanel, hide all complex engineering gear stats, show only inventory
	if equipped_tool_lbl != null:
		equipped_tool_lbl.visible = not is_feel
	if scanner_charge_lbl != null:
		scanner_charge_lbl.visible = not is_feel
	if scanner_charge_bar != null:
		scanner_charge_bar.visible = not is_feel
	if resource_tally_lbl != null:
		resource_tally_lbl.visible = not is_feel
	if quick_slots_lbl != null:
		quick_slots_lbl.visible = not is_feel
	if inventory_lbl != null:
		inventory_lbl.visible = true

func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_TAB or event.keycode == KEY_I))):
		get_viewport().set_input_as_handled()
		resume_game()

func set_player_reference(player: Node3D) -> void:
	_player_ref = player

func toggle_pause() -> void:
	if visible:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	save_notice_label.text = ""
	refresh_all_info()

func resume_game() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	resumed.emit()

func refresh_all_info() -> void:
	# 1. Mission Info
	var cur_obj := MissionManager.get_current_objective()
	var imm_task: String = MissionManager.get_current_immediate_task()
	var plain_guide: String = MissionManager.get_current_plain_guide() if MissionManager.has_method("get_current_plain_guide") else str(cur_obj.get("desc", ""))
	var target_room: String = MissionManager.get_current_target_room() if MissionManager.has_method("get_current_target_room") else ""
	if mission_title_lbl != null:
		mission_title_lbl.text = "MISSION %d: %s" % [MissionManager.current_objective_index + 1, str(cur_obj.get("title", "")).to_upper()]
	if immediate_task_lbl != null:
		immediate_task_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if target_room != "":
			immediate_task_lbl.text = "IMMEDIATE TASK: %s [%s]\n%s" % [imm_task, target_room, plain_guide]
		else:
			immediate_task_lbl.text = "IMMEDIATE TASK: %s\n%s" % [imm_task, plain_guide]
	if mission_desc_lbl != null:
		mission_desc_lbl.text = "%s\n\nSTORY BRIEFING: %s" % [plain_guide, str(cur_obj.get("desc", ""))]
	
	# 2. Environmental Telemetry
	var env_mgr = EnvironmentalManager.instance if ("instance" in EnvironmentalManager and EnvironmentalManager.instance != null) else (get_tree().root.find_child("EnvironmentalManager", true, false) if is_inside_tree() else null)
	if env_mgr != null:
		if "oxygen_level" in env_mgr:
			update_oxygen(float(env_mgr.oxygen_level), not ShipSystemManager.is_system_online("life_support"))
		if env_mgr.has_method("get_player_environment_telemetry"):
			var telem: Dictionary = env_mgr.get_player_environment_telemetry()
			var aff: Array[String] = env_mgr.player_afflictions if ("player_afflictions" in env_mgr) else []
			update_player_status(aff, telem)
	
	# 3. Gear & Inventory
	if has_node("/root/InventoryManager"):
		var im = get_node("/root/InventoryManager")
		var equipped: String = im.get_equipped_item_id()
		var battery: float = im.get_scanner_battery()
		var res: Dictionary = {
			"spare_fuse": im.get_item_count("spare_fuse"),
			"coolant_canister": im.get_item_count("coolant_canister"),
			"scrubber_cartridge": im.get_item_count("scrubber_cartridge"),
			"battery_cell": im.get_item_count("battery_cell")
		}
		update_gear(equipped, battery, res)
	update_inventory(MissionManager.inventory)
	_apply_game_mode()

func update_telemetry(p_o2: float, p_co2: float, p_press: float, p_temp: float, p_hazard: String = "Nominal", p_location: String = "Engineering") -> void:
	update_oxygen(p_o2, false)
	var telem := {
		"co2_ppm": p_co2,
		"pressure_kpa": p_press,
		"temperature_c": p_temp,
		"compartment_name": p_location
	}
	update_player_status([], telem)
	if hazard_lbl != null:
		hazard_lbl.text = "STATUS: %s" % p_hazard.to_upper()

func update_oxygen(level: float, is_depleting: bool) -> void:
	_last_oxygen = level
	_is_oxygen_depleting = is_depleting
	if o2_bar != null:
		o2_bar.value = level
	if o2_status_lbl != null:
		if is_depleting:
			o2_status_lbl.text = "O2 LEVEL: %d%% [VENTING - SCRUBBER OFFLINE]" % int(level)
			if level < 25.0:
				o2_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
			else:
				o2_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		else:
			o2_status_lbl.text = "O2 LEVEL: %d%% [STABLE - SCRUBBER NOMINAL]" % int(level)
			o2_status_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))

func update_player_status(afflictions: Array[String], telem: Dictionary) -> void:
	_last_afflictions = afflictions
	_last_telem = telem
	
	if location_lbl != null:
		var cname: String = str(telem.get("compartment_name", "Research Facility")).to_upper()
		location_lbl.text = "LOCATION: %s" % cname
	
	var co2: float = float(telem.get("co2_ppm", 420.0))
	if co2_status_lbl != null:
		if co2 > 2500.0:
			co2_status_lbl.text = "CO2: %d ppm [CRITICAL TOXICITY]" % int(co2)
			co2_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))
		elif co2 > 1200.0:
			co2_status_lbl.text = "CO2: %d ppm [ELEVATED / CAUTION]" % int(co2)
			co2_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
		else:
			co2_status_lbl.text = "CO2: %d ppm [NOMINAL]" % int(co2)
			co2_status_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
	
	var temp_c: float = float(telem.get("temperature_c", 21.0))
	var press: float = float(telem.get("pressure_kpa", 101.3))
	if metrics_lbl != null:
		metrics_lbl.text = "TEMP: %.1f°C | PRESS: %.1f kPa" % [temp_c, press]
		if temp_c < 10.0 or temp_c > 38.0 or press < 75.0:
			metrics_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
		else:
			metrics_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	
	if hazard_lbl != null:
		if afflictions.is_empty():
			hazard_lbl.text = "STATUS: SAFE [ALL NOMINAL]"
			hazard_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		else:
			var hazard_names := []
			for aff in afflictions:
				hazard_names.append("[%s]" % aff)
			hazard_lbl.text = "HAZARD: " + " ".join(hazard_names)
			hazard_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))

func update_mission(idx: int, title: String, immediate_task: String, desc: String) -> void:
	var plain_guide: String = MissionManager.get_current_plain_guide() if MissionManager.has_method("get_current_plain_guide") else desc
	var target_room: String = MissionManager.get_current_target_room() if MissionManager.has_method("get_current_target_room") else ""
	if mission_title_lbl != null:
		mission_title_lbl.text = "MISSION %d: %s" % [idx + 1, title.to_upper()]
	if immediate_task_lbl != null:
		immediate_task_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if target_room != "":
			immediate_task_lbl.text = "IMMEDIATE TASK: %s [%s]\n%s" % [immediate_task, target_room, plain_guide]
		else:
			immediate_task_lbl.text = "IMMEDIATE TASK: %s\n%s" % [immediate_task, plain_guide]
	if mission_desc_lbl != null:
		mission_desc_lbl.text = "%s\n\nSTORY BRIEFING: %s" % [plain_guide, desc]

func update_inventory(items: Array[String]) -> void:
	if inventory_lbl == null:
		return
	if items.is_empty():
		inventory_lbl.text = "INVENTORY: [ Empty ]"
	else:
		var display_names := []
		for item in items:
			match item:
				"coolant_coupler":
					display_names.append("Coolant Coupler")
				"scrubber_cartridge":
					display_names.append("Scrubber Cartridge")
				_:
					display_names.append(item.capitalize())
		inventory_lbl.text = "INVENTORY: [ " + ", ".join(display_names) + " ]"

func update_gear(equipped: String, battery: float, resources: Dictionary) -> void:
	if equipped_tool_lbl != null:
		match equipped:
			"diagnostic_scanner":
				equipped_tool_lbl.text = "EQUIPPED: [1] Diagnostic Scanner [Charge: %d%%]" % int(battery)
				equipped_tool_lbl.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
			"multitool":
				var im = get_node_or_null("/root/InventoryManager")
				var mode: String = im.get_multitool_mode() if im != null else "CALIBRATE"
				equipped_tool_lbl.text = "EQUIPPED: [2] Multitool / Welder [%s MODE]" % mode
				equipped_tool_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
			"spare_fuse":
				equipped_tool_lbl.text = "EQUIPPED: [3] Spare Fuse Pack"
				equipped_tool_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
			"battery_cell":
				equipped_tool_lbl.text = "EQUIPPED: [4] Portable Battery Cell"
				equipped_tool_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			_:
				equipped_tool_lbl.text = "EQUIPPED: [ Hands / Unequipped ]"
				equipped_tool_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	
	if scanner_charge_bar != null:
		scanner_charge_bar.value = battery
	if scanner_charge_lbl != null:
		scanner_charge_lbl.text = "SCANNER CHARGE: %d%%" % int(battery)
	
	if resource_tally_lbl != null:
		resource_tally_lbl.text = "FUSES: %d | COOLANT: %d | FILTERS: %d | CELLS: %d" % [
			int(resources.get("spare_fuse", 0)),
			int(resources.get("coolant_canister", 0)),
			int(resources.get("scrubber_cartridge", 0)),
			int(resources.get("battery_cell", 0))
		]

func _on_sensitivity_changed(value: float) -> void:
	SaveManager.mouse_sensitivity = value / 1000.0
	SaveManager.save_settings()

func _on_volume_changed(value: float) -> void:
	var vol := value / 100.0
	SaveManager.master_volume = vol
	AudioManager.set_volume(vol)
	SaveManager.save_settings()

func _on_save_pressed() -> void:
	var env_mgr: Node = get_tree().root.find_child("EnvironmentalManager", true, false)
	var ok := SaveManager.save_game(_player_ref, env_mgr)
	if ok:
		save_notice_label.text = "Game state successfully saved to user://savegame.json"
		AudioManager.play_sfx("repair")
	else:
		save_notice_label.text = "Failed to save game state."

func _on_main_menu_pressed() -> void:
	AudioManager.stop_all()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
