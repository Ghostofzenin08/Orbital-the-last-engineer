class_name TerminalDialog
extends Control

# Terminal Dialog UI for ORBITAL: The Last Engineer
# Displays Ship System Diagnostics, 10 Crew Incident Logs, and Comms Alignment.

signal terminal_closed

@onready var title_label: Label = %TitleLabel
@onready var diagnostics_panel: VBoxContainer = %DiagnosticsList
@onready var logs_list: ItemList = %LogsList
@onready var log_title_label: Label = %LogTitleLabel
@onready var log_author_label: Label = %LogAuthorLabel
@onready var log_content_label: RichTextLabel = %LogContentLabel
@onready var align_button: Button = %AlignButton
@onready var align_status_label: Label = %AlignStatusLabel

@onready var atmo_status_label: Label = %AtmoStatusLabel
@onready var atmo_list: VBoxContainer = %AtmosphereList
@onready var btn_emergency_purge: Button = %BtnEmergencyPurge
@onready var btn_emergency_pressurize: Button = %BtnEmergencyPressurize
@onready var btn_thermal_reset: Button = %BtnThermalReset
@onready var btn_reroute_aux: Button = get_node_or_null("%BtnRerouteAux")
@onready var btn_simulate_fault: Button = get_node_or_null("%BtnSimulateFault")
@onready var btn_clear_faults: Button = get_node_or_null("%BtnClearFaults")

var current_terminal_type: String = "diagnostics"
var _test_fault_index: int = 0
const TEST_FAULTS: Array[String] = ["CO2_SCRUBBER_SATURATION", "CABIN_PRESSURE_LEAK", "THERMAL_RUNAWAY"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%CloseButton.pressed.connect(close_terminal)
	%TabDiagnostics.pressed.connect(func(): _show_tab("diagnostics"))
	%TabLogs.pressed.connect(func(): _show_tab("logs"))
	%TabComms.pressed.connect(func(): _show_tab("comms"))
	if has_node("%TabSchematic"):
		%TabSchematic.pressed.connect(func(): _show_tab("schematic"))
	if has_node("%TabAtmosphere"):
		%TabAtmosphere.pressed.connect(func(): _show_tab("atmosphere"))
	if has_node("%BtnEmergencyPurge"):
		%BtnEmergencyPurge.pressed.connect(_on_emergency_purge_pressed)
	if has_node("%BtnEmergencyPressurize"):
		%BtnEmergencyPressurize.pressed.connect(_on_emergency_pressurize_pressed)
	if has_node("%BtnThermalReset"):
		%BtnThermalReset.pressed.connect(_on_thermal_reset_pressed)
	if btn_reroute_aux != null:
		btn_reroute_aux.pressed.connect(_on_reroute_aux_pressed)
	if btn_simulate_fault != null:
		btn_simulate_fault.pressed.connect(_on_simulate_fault_pressed)
	if btn_clear_faults != null:
		btn_clear_faults.pressed.connect(_on_clear_faults_pressed)
	logs_list.item_selected.connect(_on_log_selected)
	align_button.pressed.connect(_on_align_button_pressed)
	_populate_logs()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close_terminal()

func open_terminal(term_type: String = "diagnostics", term_title: String = "Shipboard Console") -> void:
	current_terminal_type = term_type
	title_label.text = "ASTRAEA-7 TERMINAL OS // " + term_title.to_upper()
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if term_type == "bridge_comms":
		_show_tab("comms")
	elif term_type == "life_support" or term_title.to_lower().find("atmosphere") != -1 or term_title.to_lower().find("atmospheric") != -1:
		_show_tab("atmosphere")
	else:
		_show_tab("diagnostics")
	
	_refresh_diagnostics()
	_refresh_comms_status()

func close_terminal() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	terminal_closed.emit()

func _show_tab(tab_name: String) -> void:
	%DiagnosticsView.visible = (tab_name == "diagnostics")
	%LogsView.visible = (tab_name == "logs")
	%CommsView.visible = (tab_name == "comms")
	if has_node("%SchematicView"):
		%SchematicView.visible = (tab_name == "schematic")
		if tab_name == "schematic" and %SchematicView.has_method("refresh_schematic"):
			%SchematicView.refresh_schematic()
	if has_node("%AtmosphereView"):
		%AtmosphereView.visible = (tab_name == "atmosphere")
	
	if tab_name == "diagnostics":
		_refresh_diagnostics()
	elif tab_name == "comms":
		_refresh_comms_status()
	elif tab_name == "atmosphere":
		_refresh_atmosphere()

func _refresh_diagnostics() -> void:
	# Clear previous entries
	for child in diagnostics_panel.get_children():
		child.queue_free()
	
	var sys_keys := ["primary_power", "power_distribution", "life_support", "communications", "propulsion"]
	for key in sys_keys:
		var sys: ShipSystem = ShipSystemManager.get_system(key)
		if sys == null:
			continue
		
		var row := PanelContainer.new()
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 15)
		
		var name_lbl := Label.new()
		name_lbl.text = sys.display_name
		name_lbl.custom_minimum_size.x = 240
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		
		var state_lbl := Label.new()
		state_lbl.text = "[ %s ]" % sys.get_state_string()
		state_lbl.custom_minimum_size.x = 160
		match sys.state:
			ShipSystem.State.ONLINE:
				state_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
			ShipSystem.State.DEGRADED:
				state_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			ShipSystem.State.FAILED:
				state_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
			_:
				state_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		
		var fault_lbl := Label.new()
		fault_lbl.text = sys.fault_description
		fault_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fault_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		fault_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		
		hbox.add_child(name_lbl)
		hbox.add_child(state_lbl)
		hbox.add_child(fault_lbl)
		row.add_child(hbox)
		diagnostics_panel.add_child(row)

func _populate_logs() -> void:
	logs_list.clear()
	var all_logs = MissionManager.get_all_crew_logs() if MissionManager.has_method("get_all_crew_logs") else MissionManager.CREW_LOGS
	for log in all_logs:
		var item_text: String = "%s - %s" % [log["date"], log["title"]]
		logs_list.add_item(item_text)
	
	if logs_list.item_count > 0:
		logs_list.select(0)
		_on_log_selected(0)

func _on_log_selected(index: int) -> void:
	var all_logs = MissionManager.get_all_crew_logs() if MissionManager.has_method("get_all_crew_logs") else MissionManager.CREW_LOGS
	if index < 0 or index >= all_logs.size():
		return
	var log: Dictionary = all_logs[index]
	log_title_label.text = str(log["title"]).to_upper()
	log_author_label.text = "Author: %s | Date: %s" % [log["author"], log["date"]]
	log_content_label.text = str(log["content"])

func _refresh_comms_status() -> void:
	var online := ShipSystemManager.is_system_online("communications")
	var pwr_online := ShipSystemManager.is_system_online("power_distribution")
	
	if online:
		align_status_label.text = "STATUS: ONLINE - Transceiver array aligned to frequency 1420.405 MHz. Beacon active."
		align_status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
		align_button.disabled = true
		align_button.text = "ANTENNA ARRAY SYNCHRONIZED"
	elif not pwr_online:
		align_status_label.text = "STATUS: OFFLINE - Main electrical distribution bus de-energized. Re-route power in Engineering."
		align_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		align_button.disabled = true
		align_button.text = "POWER REQUIRED TO ALIGN"
	else:
		align_status_label.text = "STATUS: DESYNCHRONIZED - Servo drift detected. Ready for automatic frequency lock."
		align_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		align_button.disabled = false
		align_button.text = "CALIBRATE & LOCK COMM ARRAY"

func _on_align_button_pressed() -> void:
	var res := ShipSystemManager.align_comms_array()
	if res.get("ok", false):
		_refresh_comms_status()
		_refresh_diagnostics()

func _get_env_manager() -> Node:
	if EnvironmentalManager != null and "instance" in EnvironmentalManager and EnvironmentalManager.instance != null:
		return EnvironmentalManager.instance
	var root := get_tree().root if is_inside_tree() else null
	if root != null:
		return root.find_child("EnvironmentalManager", true, false)
	return null

func _refresh_atmosphere() -> void:
	if atmo_list == null:
		return
	for child in atmo_list.get_children():
		atmo_list.remove_child(child)
		child.queue_free()
	
	var env_mgr = _get_env_manager()
	var comp_dict: Dictionary = {}
	if env_mgr != null and env_mgr.has_method("get_all_compartments"):
		comp_dict = env_mgr.get_all_compartments()
	
	var comp_keys := ["engineering_bay", "corridors", "life_support", "bridge"]
	var comp_names := {
		"engineering_bay": "Engineering Bay (Aft)",
		"corridors": "Primary Access Corridors",
		"life_support": "Life Support & Environmental Systems",
		"bridge": "Command Bridge (Forward)"
	}
	
	for cid in comp_keys:
		var cinfo: Dictionary = comp_dict.get(cid, {})
		var o2 := float(cinfo.get("o2_level", 100.0))
		var co2 := float(cinfo.get("co2_ppm", 420.0))
		var temp_k := float(cinfo.get("temperature", 294.15))
		var temp_c := temp_k - 273.15
		var press := float(cinfo.get("pressure", 101.3))
		var vents := bool(cinfo.get("vents_open", true))
		var hazards: Array = cinfo.get("active_hazards", [])
		
		var card := PanelContainer.new()
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		
		var top_hbox := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = comp_names.get(cid, cid.capitalize())
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		name_lbl.add_theme_font_size_override("font_size", 14)
		
		var status_badge := Label.new()
		var badge_text := "[ NOMINAL ]"
		var badge_col := Color(0.2, 1.0, 0.3)
		if not hazards.is_empty():
			badge_text = "[ %s ]" % "/".join(hazards)
			badge_col = Color(1.0, 0.2, 0.2)
		elif o2 < 60.0 or co2 > 2000.0 or press < 75.0 or temp_c < 10.0 or temp_c > 38.0:
			badge_text = "[ CRITICAL ]"
			badge_col = Color(1.0, 0.3, 0.2)
		elif o2 < 80.0 or co2 > 1000.0 or press < 90.0 or temp_c < 18.0 or temp_c > 26.0:
			badge_text = "[ WARNING ]"
			badge_col = Color(1.0, 0.8, 0.2)
		
		status_badge.text = badge_text
		status_badge.add_theme_color_override("font_color", badge_col)
		top_hbox.add_child(name_lbl)
		top_hbox.add_child(status_badge)
		vbox.add_child(top_hbox)
		
		var metrics_lbl := Label.new()
		metrics_lbl.text = "O2: %.1f%%  |  CO2: %d ppm  |  Temp: %.1f°C  |  Pressure: %.1f kPa  |  Vents: %s" % [
			o2, int(co2), temp_c, press, ("OPEN" if vents else "ISOLATED")
		]
		metrics_lbl.add_theme_font_size_override("font_size", 12)
		metrics_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		vbox.add_child(metrics_lbl)
		
		card.add_child(vbox)
		atmo_list.add_child(card)
	
	if btn_reroute_aux != null:
		var aux_on := bool(ShipState != null and "auxiliary_scrubber_active" in ShipState and ShipState.auxiliary_scrubber_active)
		btn_reroute_aux.text = "AUX SCRUBBER: [ACTIVE]" if aux_on else "REROUTE AUX SCRUBBER (OFF)"
	if btn_simulate_fault != null:
		btn_simulate_fault.text = "TRIGGER TEST: %s" % TEST_FAULTS[_test_fault_index]

func _on_emergency_purge_pressed() -> void:
	if not ShipSystemManager.is_system_online("power_distribution"):
		if atmo_status_label != null:
			atmo_status_label.text = "ERROR: Main electrical distribution bus offline. Cannot cycle purge blowers."
			atmo_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		if AudioManager != null:
			AudioManager.play_sfx("denied")
		return
	
	var env_mgr = _get_env_manager()
	if env_mgr != null and env_mgr.has_method("trigger_co2_purge"):
		env_mgr.trigger_co2_purge()
	
	if atmo_status_label != null:
		atmo_status_label.text = "OVERRIDE ENGAGED: Emergency CO2 purge completed. Auxiliary blowers scrubbed toxic buildup."
		atmo_status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	_refresh_atmosphere()

func _on_emergency_pressurize_pressed() -> void:
	if not ShipSystemManager.is_system_online("power_distribution"):
		if atmo_status_label != null:
			atmo_status_label.text = "ERROR: Main electrical distribution bus offline. Cannot open ballast solenoids."
			atmo_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		if AudioManager != null:
			AudioManager.play_sfx("denied")
		return
	
	var env_mgr = _get_env_manager()
	if env_mgr != null and env_mgr.has_method("trigger_pressurization_override"):
		env_mgr.trigger_pressurization_override("")
	
	if atmo_status_label != null:
		atmo_status_label.text = "OVERRIDE ENGAGED: Emergency repressurization active. Reserve ballast equalized to 101.3 kPa."
		atmo_status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	_refresh_atmosphere()

func _on_thermal_reset_pressed() -> void:
	if not ShipSystemManager.is_system_online("power_distribution"):
		if atmo_status_label != null:
			atmo_status_label.text = "ERROR: Main electrical distribution bus offline. Cannot reset thermal exchanger logic."
			atmo_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		if AudioManager != null:
			AudioManager.play_sfx("denied")
		return
	
	var env_mgr = _get_env_manager()
	if env_mgr != null and env_mgr.has_method("trigger_thermal_reset"):
		env_mgr.trigger_thermal_reset()
	
	if atmo_status_label != null:
		atmo_status_label.text = "OVERRIDE ENGAGED: Climate exchangers recalibrated to 21.0°C nominal."
		atmo_status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	_refresh_atmosphere()

func _on_reroute_aux_pressed() -> void:
	if not ShipSystemManager.is_system_online("power_distribution"):
		if atmo_status_label != null:
			atmo_status_label.text = "ERROR: Bus offline. Power needed to reroute to auxiliary scrubber."
			atmo_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		if AudioManager != null:
			AudioManager.play_sfx("denied")
		return
	
	if ShipState != null and "auxiliary_scrubber_active" in ShipState:
		var nstate := not ShipState.auxiliary_scrubber_active
		ShipState.reroute_auxiliary_scrubber(nstate)
		if AudioManager != null:
			AudioManager.play_sfx("click")
		if atmo_status_label != null:
			atmo_status_label.text = "POWER REROUTED: Secondary CO2 Scrubber Bank is now %s." % ("ACTIVE" if nstate else "STANDBY")
			atmo_status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4) if nstate else Color(0.8, 0.8, 0.9))
	_refresh_atmosphere()

func _on_simulate_fault_pressed() -> void:
	var f_id: String = TEST_FAULTS[_test_fault_index]
	_test_fault_index = (_test_fault_index + 1) % TEST_FAULTS.size()
	if ShipState != null and "trigger_fault" in ShipState:
		ShipState.trigger_fault(f_id)
		if AudioManager != null:
			AudioManager.play_sfx("alarm_single")
		if atmo_status_label != null:
			atmo_status_label.text = "DIAGNOSTIC TEST TRIGGERED: Active fault [%s]." % f_id
			atmo_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
	_refresh_atmosphere()

func _on_clear_faults_pressed() -> void:
	for f_id in TEST_FAULTS:
		if ShipState != null and "resolve_fault" in ShipState:
			ShipState.resolve_fault(f_id)
	var env_mgr = _get_env_manager()
	if env_mgr != null:
		if env_mgr.has_method("trigger_co2_purge"): env_mgr.trigger_co2_purge()
		if env_mgr.has_method("trigger_pressurization_override"): env_mgr.trigger_pressurization_override("")
		if env_mgr.has_method("trigger_thermal_reset"): env_mgr.trigger_thermal_reset()
	if AudioManager != null:
		AudioManager.play_sfx("repair")
	if atmo_status_label != null:
		atmo_status_label.text = "DIAGNOSTIC TEST COMPLETE: All test faults cleared. Environment nominal."
		atmo_status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	_refresh_atmosphere()
