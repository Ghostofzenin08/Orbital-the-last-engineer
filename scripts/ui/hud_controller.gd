class_name HUDController
extends CanvasLayer

# HUD Controller for ORBITAL: The Last Engineer
# Displays reticle, interaction prompt, mission tracker, environmental telemetry, status effects, and inventory.

@onready var prompt_label: Label = %PromptLabel
@onready var objective_title_lbl: Label = %ObjectiveTitle
@onready var objective_desc_lbl: Label = %ObjectiveDesc
@onready var o2_bar: ProgressBar = %OxygenBar
@onready var o2_status_lbl: Label = %OxygenStatusLabel
@onready var inventory_lbl: Label = %InventoryLabel
@onready var notification_lbl: Label = %NotificationLabel

# Milestone 2 Environmental & Status UI
@onready var location_lbl: Label = get_node_or_null("%LocationLabel")
@onready var co2_status_lbl: Label = get_node_or_null("%CO2StatusLabel")
@onready var metrics_lbl: Label = get_node_or_null("%AtmosphereMetricsLabel")
@onready var hazard_lbl: Label = get_node_or_null("%HazardLabel")
@onready var overlay_rect: ColorRect = get_node_or_null("%StatusEffectOverlay")

# Milestone 3 Tool & Resource UI
@onready var equipped_tool_lbl: Label = get_node_or_null("%EquippedToolLabel")
@onready var scanner_charge_bar: ProgressBar = get_node_or_null("%ScannerChargeBar")
@onready var scanner_charge_lbl: Label = get_node_or_null("%ScannerChargeLabel")
@onready var resource_tally_lbl: Label = get_node_or_null("%ResourceTallyLabel")
@onready var quick_slots_lbl: Label = get_node_or_null("%QuickSlotsLabel")

# Scanner Telemetry Card
@onready var scan_telemetry_margin: MarginContainer = get_node_or_null("%ScanTelemetryMargin")
@onready var scan_device_name_lbl: Label = get_node_or_null("%ScanDeviceName")
@onready var scan_integrity_lbl: Label = get_node_or_null("%ScanIntegrityLabel")
@onready var scan_metrics_lbl: Label = get_node_or_null("%ScanMetricsLabel")
@onready var scan_faults_lbl: Label = get_node_or_null("%ScanFaultsLabel")
@onready var scan_action_lbl: Label = get_node_or_null("%ScanActionLabel")

@onready var ship_schematic: Control = get_node_or_null("ShipSchematic")

# Tutorial UI
@onready var tutorial_margin: MarginContainer = get_node_or_null("%TutorialMargin")
@onready var tutorial_title_lbl: Label = get_node_or_null("%TutorialTitleLabel")
@onready var tutorial_desc_lbl: Label = get_node_or_null("%TutorialDescLabel")

var _notif_timer: SceneTreeTimer
var _notif_seq: int = 0
var _last_recovered_datapad_title: String = ""
var _scan_timer: SceneTreeTimer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	prompt_label.text = ""
	notification_lbl.text = ""
	
	# Connect to MissionManager signals
	MissionManager.objective_updated.connect(_on_objective_updated)
	MissionManager.objective_completed.connect(_on_objective_completed)
	MissionManager.inventory_changed.connect(_on_inventory_changed)
	if MissionManager.has_signal("room_discovered"):
		MissionManager.room_discovered.connect(func(_rid: String, rname: String):
			show_notification("DISCOVERED: %s" % rname, 3.5)
		)
	if MissionManager.has_signal("datapad_collected"):
		MissionManager.datapad_collected.connect(func(_dp_id: String, dp_data: Dictionary):
			var dp_title: String = str(dp_data.get("title", _dp_id))
			_last_recovered_datapad_title = dp_title
			show_notification("DATAPAD RECOVERED: %s [Review in Terminal]" % dp_title, 4.0)
		)
	if MissionManager.has_signal("revelation_unlocked"):
		MissionManager.revelation_unlocked.connect(func(_rev_id: String, rev_data: Dictionary):
			var rev_title: String = str(rev_data.get("title", _rev_id))
			var rev_bonus: String = str(rev_data.get("bonus_summary", "System Optimization Active"))
			if _last_recovered_datapad_title != "":
				show_notification("DATAPAD RECOVERED: %s // REVELATION UNLOCKED: %s (%s)" % [_last_recovered_datapad_title, rev_title, rev_bonus], 5.5)
			else:
				show_notification("REVELATION UNLOCKED: %s // %s" % [rev_title, rev_bonus], 5.5)
		)
	
	# Connect to InventoryManager signals
	if has_node("/root/InventoryManager"):
		var im = get_node("/root/InventoryManager")
		im.tool_equipped.connect(_on_tool_equipped)
		im.scanner_battery_changed.connect(_on_battery_changed)
		im.multitool_mode_changed.connect(_on_multitool_mode_changed)
		im.inventory_updated.connect(_update_tool_and_resource_hud)
		im.tool_used.connect(_on_tool_used)
		_update_tool_and_resource_hud()
	
	# Initial mission sync
	var cur_obj := MissionManager.get_current_objective()
	_on_objective_updated(MissionManager.current_objective_index, cur_obj["title"], cur_obj["desc"])
	_on_inventory_changed(MissionManager.inventory)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		toggle_schematic()

func toggle_schematic() -> void:
	if ship_schematic != null:
		if ship_schematic.visible:
			if ship_schematic.has_method("close_schematic"):
				ship_schematic.close_schematic()
			else:
				ship_schematic.visible = false
		else:
			var pause_menu = get_node_or_null("PauseMenu")
			var terminal_dialog = get_node_or_null("TerminalDialog")
			if (pause_menu == null or not pause_menu.visible) and (terminal_dialog == null or not terminal_dialog.visible):
				if ship_schematic.has_method("open_schematic"):
					ship_schematic.open_schematic()
				else:
					ship_schematic.visible = true

func set_prompt(text: String) -> void:
	prompt_label.text = text

func update_oxygen(level: float, is_depleting: bool) -> void:
	o2_bar.value = level
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
	# 1. Location badge
	if location_lbl != null:
		var cname: String = str(telem.get("compartment_name", "Ship Interior")).to_upper()
		location_lbl.text = "LOCATION: %s" % cname
	
	# 2. CO2 readout
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
	
	# 3. Temp & Pressure
	var temp_c: float = float(telem.get("temperature_c", 21.0))
	var press: float = float(telem.get("pressure_kpa", 101.3))
	if metrics_lbl != null:
		metrics_lbl.text = "TEMP: %.1f°C | PRESS: %.1f kPa" % [temp_c, press]
		if temp_c < 10.0 or temp_c > 38.0 or press < 75.0:
			metrics_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
		else:
			metrics_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	
	# 4. Hazard badge
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
	
	# 5. Vignette & Status Effect Shader Overlay
	_update_status_overlay(afflictions)

func _update_status_overlay(afflictions: Array[String]) -> void:
	if overlay_rect == null or overlay_rect.material == null:
		return
	
	var mat: ShaderMaterial = overlay_rect.material as ShaderMaterial
	if mat == null:
		return
	
	if afflictions.is_empty():
		mat.set_shader_parameter("strength", 0.0)
		mat.set_shader_parameter("distortion", 0.0)
		mat.set_shader_parameter("pulse_speed", 0.0)
		return
	
	# Prioritized affliction presentation
	if afflictions.has("DECOMPRESSION"):
		mat.set_shader_parameter("strength", 0.72)
		mat.set_shader_parameter("tint_color", Color(0.85, 0.1, 0.1, 0.85))
		mat.set_shader_parameter("pulse_speed", 6.0)
		mat.set_shader_parameter("distortion", 0.015)
	elif afflictions.has("HEATSTROKE"):
		mat.set_shader_parameter("strength", 0.65)
		mat.set_shader_parameter("tint_color", Color(0.95, 0.3, 0.05, 0.85))
		mat.set_shader_parameter("pulse_speed", 3.5)
		mat.set_shader_parameter("distortion", 0.035)
	elif afflictions.has("HYPOTHERMIA"):
		mat.set_shader_parameter("strength", 0.7)
		mat.set_shader_parameter("tint_color", Color(0.55, 0.85, 1.0, 0.85))
		mat.set_shader_parameter("pulse_speed", 0.0)
		mat.set_shader_parameter("distortion", 0.0)
	elif afflictions.has("CO2_TOXICITY"):
		mat.set_shader_parameter("strength", 0.58)
		mat.set_shader_parameter("tint_color", Color(0.4, 0.65, 0.15, 0.8))
		mat.set_shader_parameter("pulse_speed", 2.0)
		mat.set_shader_parameter("distortion", 0.02)
	elif afflictions.has("HYPOXIA"):
		mat.set_shader_parameter("strength", 0.68)
		mat.set_shader_parameter("tint_color", Color(0.0, 0.0, 0.0, 0.9))
		mat.set_shader_parameter("pulse_speed", 2.8)
		mat.set_shader_parameter("distortion", 0.0)

func _on_objective_updated(idx: int, title: String, desc: String) -> void:
	objective_title_lbl.text = "MISSION %d: %s" % [idx + 1, title.to_upper()]
	objective_desc_lbl.text = desc

func _on_objective_completed(idx: int, title: String) -> void:
	show_notification("OBJECTIVE COMPLETED: %s" % title, 4.0)

func _on_inventory_changed(items: Array[String]) -> void:
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
					display_names.append(item)
		inventory_lbl.text = "INVENTORY: [ " + ", ".join(display_names) + " ]"

func show_notification(msg: String, duration: float = 3.0) -> void:
	notification_lbl.text = msg
	_notif_seq += 1
	var seq: int = _notif_seq
	if not is_inside_tree() or get_tree() == null:
		return
	_notif_timer = get_tree().create_timer(duration)
	_notif_timer.timeout.connect(func():
		if _notif_seq == seq and is_instance_valid(notification_lbl):
			notification_lbl.text = ""
	)

func _on_tool_equipped(_slot_idx: int, _item_id: String) -> void:
	_update_tool_and_resource_hud()

func _on_tool_used(tool_id: String, details: Dictionary) -> void:
	if tool_id == "diagnostic_scanner":
		display_scan_telemetry(details)

func show_tutorial_step(_step: int, title: String, instruction: String) -> void:
	if tutorial_margin != null:
		tutorial_margin.visible = true
	if tutorial_title_lbl != null:
		tutorial_title_lbl.text = "TRAINING: %s" % title
	if tutorial_desc_lbl != null:
		tutorial_desc_lbl.text = instruction

func hide_tutorial() -> void:
	if tutorial_margin != null:
		tutorial_margin.visible = false

func _on_battery_changed(cur: float, max_charge: float) -> void:
	if scanner_charge_bar != null:
		scanner_charge_bar.max_value = max_charge
		scanner_charge_bar.value = cur
	if scanner_charge_lbl != null:
		scanner_charge_lbl.text = "SCANNER: %d%%" % int(cur)

func _on_multitool_mode_changed(_mode: String) -> void:
	_update_tool_and_resource_hud()

func _update_tool_and_resource_hud() -> void:
	if not has_node("/root/InventoryManager"):
		return
	var im = get_node("/root/InventoryManager")
	var equipped: String = im.get_equipped_item_id()
	
	if equipped_tool_lbl != null:
		match equipped:
			"diagnostic_scanner":
				equipped_tool_lbl.text = "EQUIPPED: [1] Diagnostic Scanner [Charge: %d%%]" % int(im.get_scanner_battery())
				equipped_tool_lbl.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
			"multitool":
				var mode: String = im.get_multitool_mode()
				equipped_tool_lbl.text = "EQUIPPED: [2] Multitool / Welder [%s MODE]" % mode
				equipped_tool_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
			"spare_fuse":
				equipped_tool_lbl.text = "EQUIPPED: [3] Spare Fuse Pack (Qty: %d)" % im.get_item_count("spare_fuse")
				equipped_tool_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
			"battery_cell":
				equipped_tool_lbl.text = "EQUIPPED: [4] Portable Battery Cell (Qty: %d)" % im.get_item_count("battery_cell")
				equipped_tool_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			_:
				equipped_tool_lbl.text = "EQUIPPED: [ Hands / Unequipped ]"
				equipped_tool_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	
	if scanner_charge_bar != null:
		scanner_charge_bar.value = im.get_scanner_battery()
		scanner_charge_bar.visible = (equipped == "diagnostic_scanner")
	if scanner_charge_lbl != null:
		scanner_charge_lbl.visible = (equipped == "diagnostic_scanner")
		scanner_charge_lbl.text = "SCANNER: %d%%" % int(im.get_scanner_battery())
	
	if resource_tally_lbl != null:
		resource_tally_lbl.text = "FUSES: %d | COOLANT: %d | FILTERS: %d | CELLS: %d" % [
			im.get_item_count("spare_fuse"),
			im.get_item_count("coolant_canister"),
			im.get_item_count("scrubber_cartridge"),
			im.get_item_count("battery_cell")
		]
	
	if quick_slots_lbl != null:
		var mode_str: String = str(im.get_multitool_mode()).capitalize()
		quick_slots_lbl.text = "[1] Scanner  [2] Multitool (%s)  [3] Parts  [4] Recharge" % mode_str


func display_scan_telemetry(data: Dictionary) -> void:
	if scan_telemetry_margin == null:
		return
	
	scan_telemetry_margin.visible = true
	if scan_device_name_lbl != null:
		scan_device_name_lbl.text = str(data.get("device_name", "Unknown Unit")).to_upper()
	
	var hp: float = float(data.get("integrity", 100.0))
	if scan_integrity_lbl != null:
		scan_integrity_lbl.text = "INTEGRITY: %d%%" % int(hp)
		if hp < 40.0:
			scan_integrity_lbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.1))
		elif hp < 80.0:
			scan_integrity_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
		else:
			scan_integrity_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	
	var pwr: float = float(data.get("power_draw", 0.0))
	var temp: float = float(data.get("temperature_c", 21.0))
	if scan_metrics_lbl != null:
		scan_metrics_lbl.text = "POWER DRAW: %.1f kW | CORE TEMP: %.1f°C" % [pwr, temp]
	
	var faults: Array = data.get("active_faults", [])
	if scan_faults_lbl != null:
		if faults.is_empty():
			scan_faults_lbl.text = "FAULTS: [ NOMINAL - No Faults Detected ]"
			scan_faults_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		else:
			var causes: Array[String] = []
			for f in faults:
				if f is Dictionary:
					causes.append(str(f.get("root_cause", "Component Failure")))
				else:
					causes.append(str(f))
			scan_faults_lbl.text = "FAULT: " + " | ".join(causes)
			scan_faults_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	
	var repair_steps: Array = data.get("repair_steps", [])
	var rec_tool: String = str(data.get("recommended_tool", "Multitool [2]"))
	if scan_action_lbl != null:
		if repair_steps.is_empty():
			scan_action_lbl.text = "STATUS: System operational"
		else:
			scan_action_lbl.text = "TOOL REQUIRED: %s\nPROCEDURE: %s" % [rec_tool, str(repair_steps[0])]
	
	if _scan_timer != null:
		_scan_timer = null
	_scan_timer = get_tree().create_timer(6.0)
	_scan_timer.timeout.connect(func():
		if is_instance_valid(scan_telemetry_margin):
			scan_telemetry_margin.visible = false
	)

