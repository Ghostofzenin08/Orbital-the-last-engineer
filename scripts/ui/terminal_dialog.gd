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

@onready var btn_filter_crew_logs: Button = get_node_or_null("%BtnFilterCrewLogs")
@onready var btn_filter_datapads: Button = get_node_or_null("%BtnFilterDatapads")
@onready var btn_filter_revelations: Button = get_node_or_null("%BtnFilterRevelations")
@onready var investigation_summary_label: Label = get_node_or_null("%InvestigationSummaryLabel")
@onready var datapads_dossier_list: VBoxContainer = get_node_or_null("%DatapadsDossierList")
@onready var revelations_dossier_list: VBoxContainer = get_node_or_null("%RevelationsDossierList")

var current_terminal_type: String = "diagnostics"
var current_log_category: String = "crew_logs"
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
	if has_node("%TabInvestigation"):
		%TabInvestigation.pressed.connect(func(): _show_tab("investigation"))
	if btn_filter_crew_logs != null:
		btn_filter_crew_logs.pressed.connect(func(): set_log_category("crew_logs"))
	if btn_filter_datapads != null:
		btn_filter_datapads.pressed.connect(func(): set_log_category("datapads"))
	if btn_filter_revelations != null:
		btn_filter_revelations.pressed.connect(func(): set_log_category("revelations"))
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
	if MissionManager != null:
		if MissionManager.has_signal("datapad_collected"):
			MissionManager.datapad_collected.connect(func(_id: String, _d: Dictionary):
				_populate_logs()
				_refresh_investigation()
			)
		if MissionManager.has_signal("revelation_unlocked"):
			MissionManager.revelation_unlocked.connect(func(_id: String, _d: Dictionary):
				_populate_logs()
				_refresh_investigation()
				_refresh_diagnostics()
			)
	logs_list.item_selected.connect(_on_log_selected)
	align_button.pressed.connect(_on_align_button_pressed)
	_populate_logs()
	_refresh_investigation()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close_terminal()

func open_terminal(term_type: String = "diagnostics", term_title: String = "Shipboard Console") -> void:
	current_terminal_type = term_type
	current_log_category = "crew_logs"
	title_label.text = "ASTRAEA-7 TERMINAL OS // " + term_title.to_upper()
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	_populate_logs()
	_refresh_investigation()
	
	if term_type == "bridge_comms":
		_show_tab("comms")
	elif term_type == "life_support" or term_title.to_lower().find("atmosphere") != -1 or term_title.to_lower().find("atmospheric") != -1:
		_show_tab("atmosphere")
	elif term_type == "investigation" or term_title.to_lower().find("mystery") != -1:
		_show_tab("investigation")
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
	if has_node("%InvestigationView"):
		%InvestigationView.visible = (tab_name == "investigation")
	
	if tab_name == "diagnostics":
		_refresh_diagnostics()
	elif tab_name == "logs":
		_populate_logs()
	elif tab_name == "investigation":
		_refresh_investigation()
	elif tab_name == "comms":
		_refresh_comms_status()
	elif tab_name == "atmosphere":
		_refresh_atmosphere()

func set_log_category(category: String) -> void:
	current_log_category = category
	_populate_logs()

func _refresh_diagnostics() -> void:
	# Clear previous entries
	for child in diagnostics_panel.get_children():
		diagnostics_panel.remove_child(child)
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
	
	if ShipState != null and (ShipState.has_revelation_anomaly or ShipState.has_revelation_quarantine or ShipState.has_revelation_directive):
		var bonus_row := PanelContainer.new()
		var bonus_vbox := VBoxContainer.new()
		var bonus_hdr := Label.new()
		bonus_hdr.text = "ACTIVE CREW MYSTERY SYSTEM OPTIMIZATIONS:"
		bonus_hdr.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0))
		bonus_vbox.add_child(bonus_hdr)
		if ShipState.has_revelation_anomaly:
			var l1 := Label.new()
			l1.text = "• [REVELATION I] Reactor Harmonic Damping Active (-15% Thermal Accumulation | +10.0 kW Headroom)"
			l1.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			bonus_vbox.add_child(l1)
		if ShipState.has_revelation_quarantine:
			var l2 := Label.new()
			l2.text = "• [REVELATION II] Bio-Scrubber Overclock Active (+20% CO2 Scrubbing & O2 Replenishment Rate)"
			l2.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			bonus_vbox.add_child(l2)
		if ShipState.has_revelation_directive:
			var l3 := Label.new()
			l3.text = "• [REVELATION III] Commander Override Authorized [%s] (Quarantine Cleared & Thruster Boost Active)" % ShipState.commander_override_code
			l3.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			bonus_vbox.add_child(l3)
		bonus_row.add_child(bonus_vbox)
		diagnostics_panel.add_child(bonus_row)

func _populate_logs() -> void:
	logs_list.clear()
	var all_logs: Array = MissionManager.get_all_crew_logs() if MissionManager.has_method("get_all_crew_logs") else MissionManager.CREW_LOGS
	var datapads: Array = MissionManager.get_all_narrative_datapads() if MissionManager.has_method("get_all_narrative_datapads") else []
	var revelations: Array = MissionManager.get_all_narrative_revelations() if MissionManager.has_method("get_all_narrative_revelations") else []
	
	if btn_filter_crew_logs != null:
		btn_filter_crew_logs.text = "CREW LOGS (%d)" % all_logs.size()
	if btn_filter_datapads != null:
		btn_filter_datapads.text = "DATAPADS (%d/%d)" % [MissionManager.decrypted_logs.size(), datapads.size()]
	if btn_filter_revelations != null:
		btn_filter_revelations.text = "REVELATIONS (%d/%d)" % [MissionManager.unlocked_revelations.size(), revelations.size()]
	
	if current_log_category == "datapads":
		for dp in datapads:
			var dp_id: String = str(dp.get("id", ""))
			var dp_title: String = str(dp.get("title", dp_id))
			var loc_hint: String = str(dp.get("location_hint", "Unknown Compartment"))
			if MissionManager.is_datapad_decrypted(dp_id):
				logs_list.add_item("[DECRYPTED] %s" % dp_title)
			else:
				logs_list.add_item("[UNRECOVERED - %s] %s" % [loc_hint, dp_title])
	elif current_log_category == "revelations":
		for rev in revelations:
			var rev_id: String = str(rev.get("id", ""))
			var rev_title: String = str(rev.get("title", rev_id))
			var req_list: Array = rev.get("required_datapads", [])
			var found_cnt: int = 0
			for req_id in req_list:
				if MissionManager.is_datapad_decrypted(str(req_id)):
					found_cnt += 1
			if MissionManager.is_revelation_unlocked(rev_id):
				logs_list.add_item("[UNLOCKED] %s" % rev_title)
			else:
				logs_list.add_item("[LOCKED - %d/%d Clues] %s" % [found_cnt, req_list.size(), rev_title])
	else:
		for log in all_logs:
			var item_text: String = "%s - %s" % [log["date"], log["title"]]
			logs_list.add_item(item_text)
	
	if logs_list.item_count > 0:
		logs_list.select(0)
		_on_log_selected(0)

func _on_log_selected(index: int) -> void:
	if current_log_category == "datapads":
		var datapads: Array = MissionManager.get_all_narrative_datapads() if MissionManager.has_method("get_all_narrative_datapads") else []
		if index < 0 or index >= datapads.size():
			return
		var dp: Dictionary = datapads[index]
		var dp_id: String = str(dp.get("id", ""))
		var dp_title: String = str(dp.get("title", dp_id))
		var loc_hint: String = str(dp.get("location_hint", "Unknown Location"))
		if MissionManager.is_datapad_decrypted(dp_id):
			log_title_label.text = "[DECRYPTED] " + dp_title.to_upper()
			log_author_label.text = "Author: %s | Date: %s | Compartment: %s" % [
				str(dp.get("author", "Unknown")),
				str(dp.get("date", "Cycle 2184")),
				str(dp.get("compartment_id", "ship")).capitalize()
			]
			log_content_label.text = str(dp.get("content", ""))
		else:
			log_title_label.text = "[UNRECOVERED] " + dp_title.to_upper()
			log_author_label.text = "STATUS: UNRECOVERED DATA SLATE | Location Hint: %s" % loc_hint
			var enc_note: String = "\n[REQUIRES DIAGNOSTIC SCANNER [1] (-5% BATTERY) TO DECRYPT]" if bool(dp.get("is_encrypted", false)) else ""
			log_content_label.text = "DATA SLATE NOT YET RECOVERED.\n\nLast Known Telemetry Ping: %s%s\n\nSearch the compartment and interact with the physical data slate to archive its contents." % [loc_hint, enc_note]
		return
	elif current_log_category == "revelations":
		var revelations: Array = MissionManager.get_all_narrative_revelations() if MissionManager.has_method("get_all_narrative_revelations") else []
		if index < 0 or index >= revelations.size():
			return
		var rev: Dictionary = revelations[index]
		var rev_id: String = str(rev.get("id", ""))
		var rev_title: String = str(rev.get("title", rev_id))
		var req_list: Array = rev.get("required_datapads", [])
		if MissionManager.is_revelation_unlocked(rev_id):
			log_title_label.text = "[UNLOCKED] " + rev_title.to_upper()
			log_author_label.text = "SYSTEM BONUS ACTIVE: %s" % str(rev.get("bonus_summary", ""))
			log_content_label.text = "%s\n\n[ENGINEERING CONSEQUENCE ACTIVE]\n%s" % [
				str(rev.get("summary", "")),
				str(rev.get("bonus_summary", ""))
			]
		else:
			var clue_lines: Array[String] = []
			for req_id in req_list:
				var dp_info: Dictionary = MissionManager.get_datapad_data(str(req_id))
				var d_title: String = str(dp_info.get("title", req_id))
				var d_hint: String = str(dp_info.get("location_hint", "Ship Interior"))
				if MissionManager.is_datapad_decrypted(str(req_id)):
					clue_lines.append("• [DECRYPTED] %s" % d_title)
				else:
					clue_lines.append("• [UNRECOVERED - %s] %s" % [d_hint, d_title])
			log_title_label.text = "[LOCKED] " + rev_title.to_upper()
			log_author_label.text = "INVESTIGATION INCOMPLETE — Recover & Decrypt Required Data Slates"
			log_content_label.text = "REQUIRED EVIDENCE CLUES:\n%s\n\nEXPECTED SYSTEM OPTIMIZATION ON SYNTHESIS:\n%s" % [
				"\n".join(clue_lines),
				str(rev.get("bonus_summary", ""))
			]
		return
	
	var all_logs = MissionManager.get_all_crew_logs() if MissionManager.has_method("get_all_crew_logs") else MissionManager.CREW_LOGS
	if index < 0 or index >= all_logs.size():
		return
	var log: Dictionary = all_logs[index]
	log_title_label.text = str(log["title"]).to_upper()
	log_author_label.text = "Author: %s | Date: %s" % [log["author"], log["date"]]
	log_content_label.text = str(log["content"])

func _refresh_investigation() -> void:
	var datapads: Array = MissionManager.get_all_narrative_datapads() if MissionManager.has_method("get_all_narrative_datapads") else []
	var revelations: Array = MissionManager.get_all_narrative_revelations() if MissionManager.has_method("get_all_narrative_revelations") else []
	
	if investigation_summary_label != null:
		investigation_summary_label.text = "CREW MYSTERY DOSSIER // DATAPADS RECOVERED: %d/%d | REVELATIONS UNLOCKED: %d/%d" % [
			MissionManager.decrypted_logs.size(),
			datapads.size(),
			MissionManager.unlocked_revelations.size(),
			revelations.size()
		]
	
	if datapads_dossier_list != null:
		for child in datapads_dossier_list.get_children():
			datapads_dossier_list.remove_child(child)
			child.queue_free()
		
		var hdr := Label.new()
		hdr.text = "RECOVERED CREW DATAPADS (%d/%d)" % [MissionManager.decrypted_logs.size(), datapads.size()]
		hdr.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		datapads_dossier_list.add_child(hdr)
		
		for dp in datapads:
			var dp_id: String = str(dp.get("id", ""))
			var dp_title: String = str(dp.get("title", dp_id))
			var loc_hint: String = str(dp.get("location_hint", "Ship Interior"))
			var recovered: bool = MissionManager.is_datapad_decrypted(dp_id)
			
			var card := PanelContainer.new()
			var vbox := VBoxContainer.new()
			var title_lbl := Label.new()
			if recovered:
				title_lbl.text = "[DECRYPTED] %s" % dp_title
				title_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.45))
			else:
				title_lbl.text = "[UNRECOVERED - %s] %s" % [loc_hint, dp_title]
				title_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.25))
			title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(title_lbl)
			
			var body_lbl := Label.new()
			if recovered:
				body_lbl.text = "%s (%s): %s" % [
					str(dp.get("author", "Unknown")),
					str(dp.get("date", "Cycle 2184")),
					str(dp.get("content", ""))
				]
				body_lbl.add_theme_color_override("font_color", Color(0.8, 0.88, 0.95))
			else:
				body_lbl.text = "Location Hint: %s" % loc_hint
				body_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.72))
			body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			body_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(body_lbl)
			
			card.add_child(vbox)
			datapads_dossier_list.add_child(card)
	
	if revelations_dossier_list != null:
		for child in revelations_dossier_list.get_children():
			revelations_dossier_list.remove_child(child)
			child.queue_free()
		
		var rev_hdr := Label.new()
		rev_hdr.text = "CREW MYSTERY REVELATIONS (%d/%d)" % [MissionManager.unlocked_revelations.size(), revelations.size()]
		rev_hdr.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		revelations_dossier_list.add_child(rev_hdr)
		
		for rev in revelations:
			var rev_id: String = str(rev.get("id", ""))
			var rev_title: String = str(rev.get("title", rev_id))
			var req_list: Array = rev.get("required_datapads", [])
			var unlocked: bool = MissionManager.is_revelation_unlocked(rev_id)
			var found_cnt: int = 0
			for req_id in req_list:
				if MissionManager.is_datapad_decrypted(str(req_id)):
					found_cnt += 1
			
			var card := PanelContainer.new()
			var vbox := VBoxContainer.new()
			var title_lbl := Label.new()
			if unlocked:
				title_lbl.text = "[UNLOCKED] %s" % rev_title
				title_lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0))
			else:
				title_lbl.text = "[LOCKED - %d/%d CLUES] %s" % [found_cnt, req_list.size(), rev_title]
				title_lbl.add_theme_color_override("font_color", Color(0.95, 0.55, 0.25))
			title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(title_lbl)
			
			var sum_lbl := Label.new()
			if unlocked:
				sum_lbl.text = str(rev.get("summary", ""))
				sum_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
			else:
				sum_lbl.text = "Recover and decrypt all %d linked compartment datapads to synthesize this revelation." % req_list.size()
				sum_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
			sum_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			sum_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(sum_lbl)
			
			var bonus_lbl := Label.new()
			bonus_lbl.text = "GAMEPLAY CONSEQUENCE: %s [%s]" % [
				str(rev.get("bonus_summary", "")),
				"ACTIVE" if unlocked else "LOCKED"
			]
			bonus_lbl.add_theme_color_override("font_color", Color(0.25, 1.0, 0.45) if unlocked else Color(0.6, 0.65, 0.7))
			bonus_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			bonus_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(bonus_lbl)
			
			card.add_child(vbox)
			revelations_dossier_list.add_child(card)

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
