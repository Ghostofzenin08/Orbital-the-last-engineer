class_name HUDController
extends CanvasLayer

# HUD Controller for ORBITAL: The Last Engineer
# Milestone 6: Compact gameplay HUD with upper-right INFO option, bottom-left compact gear,
# upper-left immediate task display, decreased prompt sizing at object bottom, and paused telemetry.

@onready var prompt_label: Label = %PromptLabel
@onready var reticle_dot: ColorRect = get_node_or_null("%Dot")
@onready var objective_title_lbl: Label = %ObjectiveTitle
@onready var immediate_task_lbl: Label = get_node_or_null("%ImmediateTaskLabel")
@onready var objective_desc_lbl: Label = get_node_or_null("%ObjectiveDesc")
@onready var notification_lbl: Label = %NotificationLabel

# Milestone 6 UI Controls
@onready var info_btn: Button = get_node_or_null("%InfoButton")
@onready var gear_info_btn: Button = get_node_or_null("%GearInfoButton")
@onready var compact_gear_lbl: Label = get_node_or_null("%CompactGearLabel")
@onready var overlay_rect: ColorRect = get_node_or_null("%StatusEffectOverlay")
@onready var vitals_panel: PanelContainer = get_node_or_null("%VitalsPanel")
@onready var health_bar: ProgressBar = get_node_or_null("%HealthBar")
@onready var health_value: Label = get_node_or_null("%HealthValue")
@onready var oxygen_bar: ProgressBar = get_node_or_null("%OxygenBar")
@onready var oxygen_value: Label = get_node_or_null("%OxygenValue")

# Tutorial UI
@onready var tutorial_margin: MarginContainer = get_node_or_null("%TutorialMargin")
@onready var tutorial_title_lbl: Label = get_node_or_null("%TutorialTitleLabel")
@onready var tutorial_desc_lbl: Label = get_node_or_null("%TutorialDescLabel")

# Scanner Telemetry Card
@onready var scan_telemetry_margin: MarginContainer = get_node_or_null("%ScanTelemetryMargin")
@onready var scan_device_name_lbl: Label = get_node_or_null("%ScanDeviceName")
@onready var scan_integrity_lbl: Label = get_node_or_null("%ScanIntegrityLabel")
@onready var scan_metrics_lbl: Label = get_node_or_null("%ScanMetricsLabel")
@onready var scan_faults_lbl: Label = get_node_or_null("%ScanFaultsLabel")
@onready var scan_action_lbl: Label = get_node_or_null("%ScanActionLabel")

@onready var ship_schematic: Control = get_node_or_null("ShipSchematic")
@onready var pause_menu: PauseMenu = get_node_or_null("PauseMenu")

# Legacy compatibility properties for tests or direct references
var o2_bar: ProgressBar:
	get:
		if pause_menu != null and "o2_bar" in pause_menu:
			return pause_menu.o2_bar
		return null
var o2_status_lbl: Label:
	get:
		if pause_menu != null and "o2_status_lbl" in pause_menu:
			return pause_menu.o2_status_lbl
		return null
var inventory_lbl: Label:
	get:
		if pause_menu != null and "inventory_lbl" in pause_menu:
			return pause_menu.inventory_lbl
		return null
var location_lbl: Label:
	get:
		if pause_menu != null and "location_lbl" in pause_menu:
			return pause_menu.location_lbl
		return null
var co2_status_lbl: Label:
	get:
		if pause_menu != null and "co2_status_lbl" in pause_menu:
			return pause_menu.co2_status_lbl
		return null
var metrics_lbl: Label:
	get:
		if pause_menu != null and "metrics_lbl" in pause_menu:
			return pause_menu.metrics_lbl
		return null
var hazard_lbl: Label:
	get:
		if pause_menu != null and "hazard_lbl" in pause_menu:
			return pause_menu.hazard_lbl
		return null
var equipped_tool_lbl: Label:
	get:
		if pause_menu != null and "equipped_tool_lbl" in pause_menu:
			return pause_menu.equipped_tool_lbl
		return null
var scanner_charge_bar: ProgressBar:
	get:
		if pause_menu != null and "scanner_charge_bar" in pause_menu:
			return pause_menu.scanner_charge_bar
		return null
var scanner_charge_lbl: Label:
	get:
		if pause_menu != null and "scanner_charge_lbl" in pause_menu:
			return pause_menu.scanner_charge_lbl
		return null
var resource_tally_lbl: Label:
	get:
		if pause_menu != null and "resource_tally_lbl" in pause_menu:
			return pause_menu.resource_tally_lbl
		return null
var quick_slots_lbl: Label:
	get:
		if pause_menu != null and "quick_slots_lbl" in pause_menu:
			return pause_menu.quick_slots_lbl
		return null

var _notif_timer: SceneTreeTimer
var _notif_seq: int = 0
var _last_recovered_datapad_title: String = ""
var _scan_timer: SceneTreeTimer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	prompt_label.text = ""
	notification_lbl.text = ""
	
	if info_btn != null:
		info_btn.pressed.connect(toggle_info)
	if gear_info_btn != null:
		gear_info_btn.pressed.connect(toggle_info)
	
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
	_on_objective_updated(MissionManager.current_objective_index, cur_obj.get("title", ""), cur_obj.get("desc", ""))
	_on_inventory_changed(MissionManager.inventory)
	
	if SaveManager.has_signal("game_mode_changed"):
		SaveManager.game_mode_changed.connect(func(_m): _apply_game_mode())
	_apply_game_mode()

func _apply_game_mode() -> void:
	var is_feel: bool = (SaveManager.game_mode == "feel")
	var bottom_right = get_node_or_null("BottomRightMargin")
	if bottom_right != null:
		bottom_right.visible = not is_feel
	if tutorial_margin != null and is_feel:
		tutorial_margin.visible = false
	if scan_telemetry_margin != null and is_feel:
		scan_telemetry_margin.visible = false
	if info_btn != null:
		info_btn.text = "[TAB] PAUSE" if is_feel else "[TAB] INFO"
	if gear_info_btn != null:
		gear_info_btn.visible = not is_feel
	_update_tool_and_resource_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			toggle_schematic()
		elif event.keycode == KEY_TAB or event.keycode == KEY_I:
			get_viewport().set_input_as_handled()
			toggle_info()

func toggle_info() -> void:
	if pause_menu != null and pause_menu.has_method("toggle_pause"):
		pause_menu.toggle_pause()

func toggle_schematic() -> void:
	if SaveManager.game_mode == "feel":
		return
	if ship_schematic != null:
		if ship_schematic.visible:
			if ship_schematic.has_method("close_schematic"):
				ship_schematic.close_schematic()
			else:
				ship_schematic.visible = false
		else:
			var terminal_dialog = get_node_or_null("TerminalDialog")
			if (pause_menu == null or not pause_menu.visible) and (terminal_dialog == null or not terminal_dialog.visible):
				if ship_schematic.has_method("open_schematic"):
					ship_schematic.open_schematic()
				else:
					ship_schematic.visible = true

func set_prompt(text: String) -> void:
	prompt_label.text = text
	if reticle_dot != null:
		if text != "":
			reticle_dot.color = Color(0.2, 0.9, 1.0, 1.0)
			reticle_dot.custom_minimum_size = Vector2(6, 6)
		else:
			reticle_dot.color = Color(1.0, 1.0, 1.0, 0.8)
			reticle_dot.custom_minimum_size = Vector2(4, 4)

func update_health(current: float, maximum: float) -> void:
	if health_bar != null:
		health_bar.max_value = maximum
		health_bar.value = current
	if health_value != null:
		var pct := int(clampf((current / maximum) * 100.0, 0.0, 100.0)) if maximum > 0.0 else 0
		health_value.text = "%d%%" % pct
		if pct <= 35:
			health_value.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
		elif pct <= 65:
			health_value.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
		else:
			health_value.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))

func update_oxygen(level: float, is_depleting: bool) -> void:
	if oxygen_bar != null:
		oxygen_bar.value = level
	if oxygen_value != null:
		oxygen_value.text = "%d%%" % int(level)
		if is_depleting:
			oxygen_value.add_theme_color_override("font_color", Color(1.0, 0.35, 0.15))
		else:
			oxygen_value.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	if pause_menu != null and pause_menu.has_method("update_oxygen"):
		pause_menu.update_oxygen(level, is_depleting)

func update_player_status(afflictions: Array[String], telem: Dictionary) -> void:
	if pause_menu != null and pause_menu.has_method("update_player_status"):
		pause_menu.update_player_status(afflictions, telem)
	
	if info_btn != null:
		if afflictions.is_empty():
			info_btn.text = "[TAB] INFO"
			info_btn.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
		else:
			info_btn.text = "[TAB] INFO [!]"
			info_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	
	_update_status_overlay(afflictions)

# Milestone 7: Horror Boss Encounter Vignette
var _horror_vignette_timer: float = 0.0
var _horror_vignette_duration: float = 1.0

func _process(delta: float) -> void:
	if _horror_vignette_timer > 0.0:
		_horror_vignette_timer -= delta
		if _horror_vignette_timer <= 0.0 and overlay_rect != null and overlay_rect.material != null:
			var mat: ShaderMaterial = overlay_rect.material as ShaderMaterial
			if mat != null:
				mat.set_shader_parameter("strength", 0.0)
				mat.set_shader_parameter("distortion", 0.0)
				mat.set_shader_parameter("pulse_speed", 0.0)

func trigger_horror_vignette(duration: float = 1.2) -> void:
	_horror_vignette_duration = maxf(0.1, duration)
	_horror_vignette_timer = _horror_vignette_duration
	if overlay_rect != null and overlay_rect.material != null:
		var mat: ShaderMaterial = overlay_rect.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("strength", 0.95)
			mat.set_shader_parameter("tint_color", Color(0.92, 0.04, 0.04, 0.95))
			mat.set_shader_parameter("pulse_speed", 8.0)
			mat.set_shader_parameter("distortion", 0.04)
	show_notification("[!] PREDATORY ENTITY ENGAGED — EVACUATE TO AIRLOCK!", duration + 1.0)

func _update_status_overlay(afflictions: Array[String]) -> void:
	if _horror_vignette_timer > 0.0:
		return
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
	if objective_title_lbl != null:
		objective_title_lbl.text = "MISSION %d: %s" % [idx + 1, title.to_upper()]
	
	var cur_obj := MissionManager.get_current_objective()
	var immediate_task: String = str(cur_obj.get("immediate_task", "Follow Mission Directives"))
	if immediate_task_lbl != null:
		immediate_task_lbl.text = "IMMEDIATE TASK: %s" % immediate_task
	if objective_desc_lbl != null:
		objective_desc_lbl.text = immediate_task
	
	if pause_menu != null and pause_menu.has_method("update_mission"):
		pause_menu.update_mission(idx, title, immediate_task, desc)

func _on_objective_completed(_idx: int, title: String) -> void:
	show_notification("OBJECTIVE COMPLETED: %s" % title, 4.0)

func _on_inventory_changed(items: Array[String]) -> void:
	if pause_menu != null and pause_menu.has_method("update_inventory"):
		pause_menu.update_inventory(items)
	_update_tool_and_resource_hud()

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
	if SaveManager.game_mode == "feel":
		return
	if tutorial_margin != null:
		tutorial_margin.visible = true
	if tutorial_title_lbl != null:
		tutorial_title_lbl.text = "TRAINING: %s" % title
	if tutorial_desc_lbl != null:
		tutorial_desc_lbl.text = instruction

func hide_tutorial() -> void:
	if tutorial_margin != null:
		tutorial_margin.visible = false

func _on_battery_changed(cur: float, _max_charge: float) -> void:
	_update_tool_and_resource_hud()

func _on_multitool_mode_changed(_mode: String) -> void:
	_update_tool_and_resource_hud()

func _update_tool_and_resource_hud() -> void:
	if not has_node("/root/InventoryManager"):
		return
	var im = get_node("/root/InventoryManager")
	var equipped: String = im.get_equipped_item_id()
	var battery: float = im.get_scanner_battery()
	var mode: String = im.get_multitool_mode().capitalize()
	
	if SaveManager.game_mode == "feel":
		if compact_gear_lbl != null:
			var inv_list: Array[String] = MissionManager.inventory
			var inv_str: String = "Empty"
			if not inv_list.is_empty():
				var names: Array[String] = []
				for item in inv_list:
					match item:
						"coolant_coupler": names.append("Coolant Coupler")
						"scrubber_cartridge": names.append("Scrubber Filter")
						"spare_fuse": names.append("Spare Fuse")
						"battery_cell": names.append("Battery")
						_: names.append(item.capitalize())
				inv_str = ", ".join(names)
			
			var eq_name: String = "Hands"
			match equipped:
				"diagnostic_scanner": eq_name = "Scanner"
				"multitool": eq_name = "Repair Tool"
				"spare_fuse": eq_name = "Spare Fuse"
				"battery_cell": eq_name = "Battery"
				_:
					if equipped != "":
						eq_name = equipped.capitalize()
			
			compact_gear_lbl.text = "EQUIPPED: %s  |  INVENTORY: [ %s ]" % [eq_name, inv_str]
		if pause_menu != null and pause_menu.has_method("update_gear"):
			var res: Dictionary = {
				"spare_fuse": im.get_item_count("spare_fuse"),
				"coolant_canister": im.get_item_count("coolant_canister"),
				"scrubber_cartridge": im.get_item_count("scrubber_cartridge"),
				"battery_cell": im.get_item_count("battery_cell")
			}
			pause_menu.update_gear(equipped, battery, res)
		return
	
	if compact_gear_lbl != null:
		match equipped:
			"diagnostic_scanner":
				compact_gear_lbl.text = "[1] SCANNER (%d%%)  [2] Multitool  |  [TAB] Full Info" % int(battery)
			"multitool":
				compact_gear_lbl.text = "[1] Scanner  [2] MULTITOOL (%s)  |  [TAB] Full Info" % mode
			"spare_fuse":
				compact_gear_lbl.text = "[3] FUSE PACK (Qty: %d)  |  [TAB] Full Info" % im.get_item_count("spare_fuse")
			"battery_cell":
				compact_gear_lbl.text = "[4] BATTERY CELL (Qty: %d)  |  [TAB] Full Info" % im.get_item_count("battery_cell")
			_:
				compact_gear_lbl.text = "[1] Scanner  [2] Multitool (%s)  |  [TAB] Full Info & Gear" % mode
	
	if pause_menu != null and pause_menu.has_method("update_gear"):
		var res: Dictionary = {
			"spare_fuse": im.get_item_count("spare_fuse"),
			"coolant_canister": im.get_item_count("coolant_canister"),
			"scrubber_cartridge": im.get_item_count("scrubber_cartridge"),
			"battery_cell": im.get_item_count("battery_cell")
		}
		pause_menu.update_gear(equipped, battery, res)

func display_scan_telemetry(data: Dictionary) -> void:
	if SaveManager.game_mode == "feel":
		if scan_telemetry_margin != null:
			scan_telemetry_margin.visible = false
		return
	
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
