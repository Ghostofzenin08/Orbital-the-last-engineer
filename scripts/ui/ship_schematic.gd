class_name ShipSchematic
extends Control

# Ship Schematic UI Controller for ORBITAL: The Last Engineer
# Milestone 4: Displays 11-compartment spatial map across Main Deck and Lower Deck,
# live power & atmospheric hazard telemetry, player position pin, and direct power rerouting.

signal closed

@onready var grid_status_lbl: Label = %GridStatusLabel
@onready var gen_val_lbl: Label = %GenValueLabel
@onready var demand_val_lbl: Label = %DemandValueLabel
@onready var net_val_lbl: Label = %NetValueLabel
@onready var bus_status_lbl: Label = %BusStatusLabel
@onready var battery_bar: ProgressBar = %BatteryBar
@onready var battery_val_lbl: Label = %BatteryValueLabel

@onready var advice_warning_lbl: Label = %AdviceWarningLabel
@onready var advice_action_lbl: Label = %AdviceActionLabel

@onready var selected_room_title: Label = %SelectedRoomTitle
@onready var selected_room_power: Label = %SelectedRoomPower
@onready var selected_room_draw: Label = %SelectedRoomDraw
@onready var selected_room_atmosphere: Label = %SelectedRoomAtmosphere
@onready var selected_room_devices: VBoxContainer = %SelectedRoomDevices

# Compartment UI nodes
@onready var bridge_panel: PanelContainer = %BridgePanel
@onready var crew_panel: PanelContainer = %CrewQuartersPanel
@onready var avionics_panel: PanelContainer = %AvionicsBayPanel
@onready var medbay_panel: PanelContainer = %MedbayPanel
@onready var ls_panel: PanelContainer = %LifeSupportPanel
@onready var corridor_panel: PanelContainer = %CorridorPanel
@onready var cargo_panel: PanelContainer = %CargoBayPanel
@onready var airlock_panel: PanelContainer = %AirlockPanel
@onready var eng_panel: PanelContainer = %EngBayPanel
@onready var subdeck_panel: PanelContainer = %ReactorSubdeckPanel
@onready var crawlway_panel: PanelContainer = %MaintenanceCrawlwayPanel
@onready var vault_panel: PanelContainer = get_node_or_null("%SpecimenVaultPanel")
@onready var obs_panel: PanelContainer = get_node_or_null("%ResearchObservatoryPanel")

# Power Flow Conduit Lines
@onready var conduit_eng_to_corr: ColorRect = %ConduitEngToCorr
@onready var conduit_corr_to_ls: ColorRect = %ConduitCorrToLs
@onready var conduit_ls_to_bridge: ColorRect = %ConduitLsToBridge

var current_selected_compartment: String = "engineering_bay"

func _get_ship_state() -> Node:
	if is_inside_tree():
		var root := get_tree().root
		if root != null and root.has_node("ShipState"):
			return root.get_node("ShipState")
	return null

func _get_env_mgr() -> Node:
	if EnvironmentalManager != null and "instance" in EnvironmentalManager and EnvironmentalManager.instance != null:
		return EnvironmentalManager.instance
	elif is_inside_tree() and has_node("/root/EnvironmentalManager"):
		return get_node("/root/EnvironmentalManager")
	return null

func _get_player_compartment() -> String:
	var env = _get_env_mgr()
	if env != null and "player_compartment_id" in env:
		return env.player_compartment_id
	return ""

func _exit_tree() -> void:
	var state_mgr := _get_ship_state()
	if state_mgr != null:
		if state_mgr.schematic_updated.is_connected(_on_schematic_updated):
			state_mgr.schematic_updated.disconnect(_on_schematic_updated)
		if state_mgr.power_grid_updated.is_connected(_on_power_grid_updated):
			state_mgr.power_grid_updated.disconnect(_on_power_grid_updated)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var button_bindings: Dictionary = {
		%BtnSelectBridge: "bridge",
		%BtnSelectAvionics: "avionics_bay",
		%BtnSelectCrew: "crew_quarters",
		%BtnSelectMedbay: "medbay",
		%BtnSelectLs: "life_support",
		%BtnSelectCorr: "corridors",
		%BtnSelectCargo: "cargo_bay",
		%BtnSelectAirlock: "airlock_chamber",
		%BtnSelectEng: "engineering_bay",
		%BtnSelectSubdeck: "reactor_subdeck",
		%BtnSelectCrawlway: "maintenance_crawlway"
	}
	if has_node("%BtnSelectVault"):
		button_bindings[%BtnSelectVault] = "specimen_vault"
	if has_node("%BtnSelectObservatory"):
		button_bindings[%BtnSelectObservatory] = "research_observatory"
	
	for btn in button_bindings.keys():
		if btn != null:
			var cid: String = button_bindings[btn]
			btn.pressed.connect(func(): _select_compartment(cid, true))
	
	if has_node("%BtnRerouteRoomPower"):
		%BtnRerouteRoomPower.pressed.connect(_on_reroute_room_power_pressed)
	
	var is_embedded: bool = _is_embedded()
	if has_node("%BtnCloseSchematic"):
		if is_embedded:
			%BtnCloseSchematic.visible = false
		else:
			%BtnCloseSchematic.pressed.connect(close_schematic)
	
	var state_mgr := _get_ship_state()
	if state_mgr != null:
		state_mgr.schematic_updated.connect(_on_schematic_updated)
		state_mgr.power_grid_updated.connect(_on_power_grid_updated)
	
	refresh_schematic()

func _is_embedded() -> bool:
	var p := get_parent()
	while p != null:
		if p.name == "ContentContainer" or p is TerminalDialog:
			return true
		p = p.get_parent()
	return false

func _input(event: InputEvent) -> void:
	if not visible or _is_embedded():
		return
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M):
		get_viewport().set_input_as_handled()
		close_schematic()

func open_schematic() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh_schematic()

func close_schematic() -> void:
	visible = false
	var in_other_menu := false
	var root := get_tree().root
	var term = root.find_child("TerminalDialog", true, false)
	var pause = root.find_child("PauseMenu", true, false)
	if (term != null and term.visible) or (pause != null and pause.visible):
		in_other_menu = true
	
	if not in_other_menu and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()

func refresh_schematic() -> void:
	var state_mgr := _get_ship_state()
	if state_mgr == null:
		return
	var data: Dictionary = state_mgr.get_schematic_data()
	_update_ui_from_data(data)

func _on_schematic_updated(data: Dictionary) -> void:
	if visible:
		_update_ui_from_data(data)

func _on_power_grid_updated(_telem: Dictionary) -> void:
	if visible:
		refresh_schematic()

func _update_ui_from_data(data: Dictionary) -> void:
	var power: Dictionary = data.get("power", {})
	var comps: Dictionary = data.get("compartments", {})
	
	# Power telemetry
	var gen: float = float(power.get("current_generation", 0.0))
	var demand: float = float(power.get("current_demand", 0.0))
	var net: float = float(power.get("net_power", 0.0))
	var bus_energized: bool = bool(power.get("bus_energized", false))
	var bat_charge: float = float(power.get("battery_charge", 0.0))
	var bat_cap: float = float(power.get("battery_capacity", 60.0))
	var bat_pct: float = float(power.get("battery_percentage", 0.0))
	
	gen_val_lbl.text = "%.1f kW" % gen
	demand_val_lbl.text = "%.1f kW" % demand
	net_val_lbl.text = "%+.1f kW" % net
	if net >= 0.0:
		net_val_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		net_val_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	
	if bus_energized:
		bus_status_lbl.text = "ENERGIZED (CLOSED)"
		bus_status_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		grid_status_lbl.text = "GRID STATUS: BUS ENERGIZED // CIRCUITS ACTIVE"
		grid_status_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		bus_status_lbl.text = "ISOLATED (OPEN)"
		bus_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		grid_status_lbl.text = "GRID STATUS: MAIN BUS ISOLATED // EMERGENCY PROTOCOL"
		grid_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	
	battery_bar.value = bat_pct
	battery_val_lbl.text = "%.1f / %.1f kWh (%d%%)" % [bat_charge, bat_cap, int(bat_pct)]
	
	# Power Conduits visual flow
	var live_color := Color(0.2, 0.85, 1.0, 0.9)
	var dead_color := Color(0.4, 0.1, 0.1, 0.5)
	var gen_online: bool = bool(power.get("reactor_online", false))
	
	conduit_eng_to_corr.color = live_color if gen_online else dead_color
	conduit_corr_to_ls.color = live_color if bus_energized else dead_color
	conduit_ls_to_bridge.color = live_color if bus_energized else dead_color
	
	# 11 Compartment cards
	var player_loc := _get_player_compartment()
	
	var panel_map: Dictionary = {
		"bridge": bridge_panel,
		"avionics_bay": avionics_panel,
		"crew_quarters": crew_panel,
		"medbay": medbay_panel,
		"life_support": ls_panel,
		"corridors": corridor_panel,
		"cargo_bay": cargo_panel,
		"airlock_chamber": airlock_panel,
		"engineering_bay": eng_panel,
		"reactor_subdeck": subdeck_panel,
		"maintenance_crawlway": crawlway_panel,
		"specimen_vault": vault_panel,
		"research_observatory": obs_panel
	}
	
	for cid in panel_map.keys():
		var pnl = panel_map[cid]
		_update_compartment_card(pnl, comps.get(cid, {}), cid, (cid == player_loc))
	
	# Actionable advice
	advice_warning_lbl.text = str(data.get("primary_warning", "ALL SYSTEMS OPERATIONAL"))
	advice_action_lbl.text = "RECOMMENDED ACTION: " + str(data.get("primary_action", "Standby"))
	
	# Detail inspector
	_select_compartment(current_selected_compartment)

func _update_compartment_card(panel: PanelContainer, info: Dictionary, comp_id: String = "", is_player_here: bool = false) -> void:
	if panel == null:
		return
	var is_pwr: bool = bool(info.get("is_powered", false))
	var faults: Array = info.get("faults", [])
	var atmo: Dictionary = info.get("atmosphere", {})
	
	var pin_lbl: Label = panel.find_child("PlayerPin", true, false)
	if pin_lbl != null:
		pin_lbl.visible = is_player_here
	
	var status_lbl: Label = panel.find_child("StatusLabel", true, false)
	if status_lbl != null:
		var o2 := float(atmo.get("o2_level", 100.0))
		var co2 := float(atmo.get("co2_ppm", 420.0))
		var temp_c := float(atmo.get("temperature", 294.15)) - 273.15
		var press := float(atmo.get("pressure", 101.3))
		var hazards: Array = atmo.get("active_hazards", [])
		
		if press < 75.0 or hazards.has("LOW_PRESSURE"):
			status_lbl.text = "HAZARD: DECOMPRESSION (%.1f kPa)" % press
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))
		elif o2 < 60.0 or hazards.has("HYPOXIA"):
			status_lbl.text = "HAZARD: HYPOXIA (%d%% O2)" % int(o2)
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
		elif co2 > 2000.0 or hazards.has("HYPERCAPNIA"):
			status_lbl.text = "HAZARD: TOXIC CO2 (%d ppm)" % int(co2)
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		elif temp_c > 38.0 or temp_c < 10.0:
			var tmsg := "OVERHEATING" if temp_c > 38.0 else "FREEZING"
			status_lbl.text = "HAZARD: %s (%.1f°C)" % [tmsg, temp_c]
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
		elif not faults.is_empty():
			status_lbl.text = "FAULT: %s" % faults[0]
			status_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
		elif is_pwr:
			status_lbl.text = "NOMINAL // POWERED"
			status_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		else:
			status_lbl.text = "OFFLINE // UNPOWERED"
			status_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func _select_compartment(comp_id: String, force_rebuild: bool = false) -> void:
	var comp_changed := (comp_id != current_selected_compartment)
	current_selected_compartment = comp_id
	var state_mgr := _get_ship_state()
	if state_mgr == null:
		return
	
	var comp_info: Dictionary = state_mgr.COMPARTMENTS.get(comp_id, {})
	var room_name: String = str(comp_info.get("name", comp_id))
	selected_room_title.text = room_name.to_upper()
	
	var c_devices: Array = state_mgr.get_compartment_devices(comp_id)
	var total_draw: float = 0.0
	var powered_count: int = 0
	var any_rerouted: bool = false
	
	var children := selected_room_devices.get_children()
	var needs_rebuild := comp_changed or force_rebuild or (children.size() != c_devices.size())
	
	if needs_rebuild:
		for child in children:
			child.queue_free()
	
	for i in range(c_devices.size()):
		var dev = c_devices[i]
		var dval: float = dev.get_power_draw() if dev.has_method("get_power_draw") else 0.0
		total_draw += dval
		var pwr: bool = "is_powered" in dev and dev.is_powered
		if pwr: powered_count += 1
		
		var is_dev_rerouted: bool = state_mgr.power_routes.has(dev.device_id)
		if is_dev_rerouted: any_rerouted = true
		
		if needs_rebuild:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			
			var name_lbl := Label.new()
			name_lbl.text = str(dev.device_name)
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
			
			var pwr_lbl := Label.new()
			pwr_lbl.text = "[POWERED]" if pwr else "[UNPOWERED]"
			pwr_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4) if pwr else Color(0.8, 0.2, 0.2))
			
			var draw_lbl := Label.new()
			draw_lbl.text = "%.1f kW" % dval
			draw_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
			
			var dev_reroute_btn := Button.new()
			dev_reroute_btn.text = "⚡ Disconnect" if is_dev_rerouted else "⚡ Reroute"
			var d_id: String = dev.device_id
			dev_reroute_btn.pressed.connect(func():
				_toggle_device_reroute(d_id)
			)
			
			row.add_child(name_lbl)
			row.add_child(pwr_lbl)
			row.add_child(draw_lbl)
			row.add_child(dev_reroute_btn)
			selected_room_devices.add_child(row)
		else:
			var row = children[i]
			if row is HBoxContainer and row.get_child_count() >= 4:
				var pwr_lbl: Label = row.get_child(1) as Label
				var draw_lbl: Label = row.get_child(2) as Label
				var dev_reroute_btn: Button = row.get_child(3) as Button
				if pwr_lbl != null:
					pwr_lbl.text = "[POWERED]" if pwr else "[UNPOWERED]"
					pwr_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4) if pwr else Color(0.8, 0.2, 0.2))
				if draw_lbl != null:
					draw_lbl.text = "%.1f kW" % dval
				if dev_reroute_btn != null:
					dev_reroute_btn.text = "⚡ Disconnect" if is_dev_rerouted else "⚡ Reroute"
	
	selected_room_draw.text = "TOTAL COMPARTMENT DRAW: %.1f kW" % total_draw
	var reactor_on: bool = state_mgr.power_system != null and state_mgr.power_system.reactor_online
	var room_powered: bool = (powered_count > 0) or (comp_id == "engineering_bay" and reactor_on)
	selected_room_power.text = "POWER STATUS: " + ("ONLINE" if room_powered else "OFFLINE")
	selected_room_power.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4) if room_powered else Color(1.0, 0.3, 0.3))
	
	if has_node("%BtnRerouteRoomPower"):
		var btn: Button = %BtnRerouteRoomPower
		if any_rerouted:
			btn.text = "⚡ Disconnect Power Reroutes (%s)" % room_name
		else:
			btn.text = "⚡ Reroute Auxiliary Power to %s" % room_name
	
	if selected_room_atmosphere != null:
		var env_mgr = _get_env_mgr()
		var atmo: Dictionary = {}
		if env_mgr != null and env_mgr.has_method("get_compartment_atmosphere"):
			atmo = env_mgr.get_compartment_atmosphere(comp_id)
		
		var o2 := int(atmo.get("o2_level", 100.0))
		var co2 := int(atmo.get("co2_ppm", 420.0))
		var temp_c := float(atmo.get("temperature", 294.15)) - 273.15
		var press := float(atmo.get("pressure", 101.3))
		var hazards: Array = atmo.get("active_hazards", [])
		
		var status_str := "NOMINAL"
		var status_col := Color(0.2, 1.0, 0.4)
		if not hazards.is_empty():
			status_str = "HAZARD: %s" % "/".join(hazards)
			status_col = Color(1.0, 0.3, 0.2)
		elif o2 < 60 or co2 > 2000 or press < 75.0 or temp_c < 10.0 or temp_c > 38.0:
			status_str = "WARNING"
			status_col = Color(1.0, 0.8, 0.2)
		
		selected_room_atmosphere.text = "ATMOSPHERE: [%s]\nO2: %d%% | CO2: %d ppm | %.1f°C | %.1f kPa" % [
			status_str, o2, co2, temp_c, press
		]
		selected_room_atmosphere.add_theme_color_override("font_color", status_col)

func _toggle_device_reroute(dev_id: String) -> void:
	var state_mgr := _get_ship_state()
	if state_mgr == null:
		return
	if state_mgr.power_routes.has(dev_id):
		state_mgr.power_routes.erase(dev_id)
		state_mgr.power_rerouted = not state_mgr.power_routes.is_empty()
		state_mgr.tick_systems(0.0)
		AudioManager.play_sfx("switch")
	else:
		state_mgr.reroute_power("reactor_primary", dev_id)
		AudioManager.play_sfx("repair")
	refresh_schematic()

func _on_reroute_room_power_pressed() -> void:
	var state_mgr := _get_ship_state()
	if state_mgr == null:
		return
	var c_devices: Array = state_mgr.get_compartment_devices(current_selected_compartment)
	var any_rerouted := false
	for dev in c_devices:
		if state_mgr.power_routes.has(dev.device_id):
			any_rerouted = true
			break
	if any_rerouted:
		for dev in c_devices:
			state_mgr.power_routes.erase(dev.device_id)
		state_mgr.power_rerouted = not state_mgr.power_routes.is_empty()
		state_mgr.tick_systems(0.0)
		AudioManager.play_sfx("switch")
	else:
		# Reroute power to all unpowered devices in this room
		for dev in c_devices:
			if not ("is_powered" in dev and dev.is_powered):
				state_mgr.reroute_power("reactor_primary", dev.device_id)
		if not state_mgr.power_rerouted and not c_devices.is_empty():
			state_mgr.reroute_power("reactor_primary", c_devices[0].device_id)
		AudioManager.play_sfx("repair")
	refresh_schematic()
