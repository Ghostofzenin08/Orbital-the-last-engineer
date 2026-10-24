class_name DiagnosticTutorial
extends RefCounted

# In-Game Tactile Diagnostic Tutorial for ORBITAL: The Last Engineer
# Teaches the player how to observe physical symptoms (flicker, alarm, gauge),
# retrieve handheld engineering tools from lockers, scan devices for telemetry,
# identify root causes, and execute multi-step repairs.

signal tutorial_step_changed(step: int, title: String, instruction: String)
signal tutorial_completed

enum Step {
	OBSERVE_SYMPTOMS = 0,
	RETRIEVE_SCANNER = 1,
	EQUIP_SCANNER = 2,
	SCAN_DEVICE = 3,
	UNCLAMP_HOUSING = 4,
	INSTALL_FUSE = 5,
	CALIBRATE_CIRCUIT = 6,
	SYSTEM_TEST = 7,
	TUTORIAL_COMPLETE = 8
}

const STEP_DATA: Array[Dictionary] = [
	{
		"step": Step.OBSERVE_SYMPTOMS,
		"title": "OBSERVE SYMPTOMS",
		"desc": "Inspect the faulted Auxiliary Power Junction in Engineering Bay. Note the warning LED and arcing hum."
	},
	{
		"step": Step.RETRIEVE_SCANNER,
		"title": "RETRIEVE DIAGNOSTIC SCANNER",
		"desc": "Open the Engineering Supply Locker to retrieve the handheld Diagnostic Scanner and spare parts."
	},
	{
		"step": Step.EQUIP_SCANNER,
		"title": "EQUIP DIAGNOSTIC SCANNER",
		"desc": "Press [1] to equip the Diagnostic Scanner. Check the charge meter on your HUD."
	},
	{
		"step": Step.SCAN_DEVICE,
		"title": "PERFORM DIAGNOSTIC SCAN",
		"desc": "Aim crosshair at the Auxiliary Power Junction and press [E] or Left Click to scan for root cause."
	},
	{
		"step": Step.UNCLAMP_HOUSING,
		"title": "UNCLAMP HOUSING BOLTS",
		"desc": "Press [2] to equip the Multitool / Welder, then unclamp the protective junction cover."
	},
	{
		"step": Step.INSTALL_FUSE,
		"title": "INSTALL REPLACEMENT FUSE",
		"desc": "Select Spare Fuse Pack from inventory and insert it into the fuse terminal bracket."
	},
	{
		"step": Step.CALIBRATE_CIRCUIT,
		"title": "CALIBRATE CIRCUIT IMPEDANCE",
		"desc": "Use Multitool [2] to calibrate circuit impedance and seal the terminal cover."
	},
	{
		"step": Step.SYSTEM_TEST,
		"title": "RUN SYSTEM DIAGNOSTIC TEST",
		"desc": "Initiate system diagnostic test to verify auxiliary power restoration."
	},
	{
		"step": Step.TUTORIAL_COMPLETE,
		"title": "DIAGNOSTIC TUTORIAL COMPLETE",
		"desc": "Auxiliary junction restored. You now understand diagnostic scan and multi-step repair workflows."
	}
]

var current_step: int = Step.OBSERVE_SYMPTOMS
var is_active: bool = false

func start_tutorial() -> void:
	current_step = Step.OBSERVE_SYMPTOMS
	is_active = true
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var ship_state = tree.root.get_node_or_null("/root/ShipState")
		if ship_state != null and not ship_state.active_faults.has("CONDUIT_BLOWN_FUSE"):
			ship_state.trigger_fault("CONDUIT_BLOWN_FUSE")
	_broadcast_step()

func setup_in_game(level: Node3D, player: Node3D) -> void:
	if level == null or player == null:
		return
	
	# If conduit repair panel is already repaired, tutorial is already completed
	var conduit_panel = level.find_child("EngineeringConduitRepair", true, false)
	if conduit_panel != null and "is_repaired" in conduit_panel and conduit_panel.is_repaired:
		set_step(Step.TUTORIAL_COMPLETE)
		return
	
	# Connect to HUD
	var hud = player.get_node_or_null("HUD")
	if hud != null and hud.has_method("show_tutorial_step"):
		tutorial_step_changed.connect(func(s, t, i):
			hud.show_tutorial_step(s, t, i)
		)
		tutorial_completed.connect(func():
			if hud.has_method("hide_tutorial"):
				hud.hide_tutorial()
			if hud.has_method("show_notification"):
				hud.show_notification("DIAGNOSTIC TUTORIAL COMPLETE: All repair fundamentals mastered!", 5.0)
		)
	
	start_tutorial()
	
	# Hook into locker
	var locker = level.find_child("EngineeringLocker", true, false)
	if locker != null and locker.has_signal("locker_opened"):
		locker.locker_opened.connect(func(_lid, _items):
			if current_step == Step.RETRIEVE_SCANNER:
				advance_step()
		)
	
	# Hook into tool equipped
	var tree := level.get_tree()
	if tree != null and tree.root != null:
		var im = tree.root.get_node_or_null("/root/InventoryManager")
		if im != null:
			im.tool_equipped.connect(func(_slot_idx, item_id):
				if current_step == Step.EQUIP_SCANNER and item_id == "diagnostic_scanner":
					advance_step()
			)
	
	# Hook into interaction controller for Step 0 (observing junction)
	var interaction_ctrl = player.find_child("InteractionController", true, false)
	if interaction_ctrl != null and interaction_ctrl.has_signal("prompt_changed"):
		interaction_ctrl.prompt_changed.connect(func(prompt_text):
			if current_step == Step.OBSERVE_SYMPTOMS and (prompt_text.contains("Auxiliary Power Junction") or prompt_text.contains("Primary Power Conduit")):
				advance_step()
		)
	
	# Hook into conduit repair panel stages
	if conduit_panel != null and conduit_panel.has_signal("stage_advanced"):
		conduit_panel.stage_advanced.connect(func(new_stage, _sname):
			match new_stage:
				1: # UNCLAMP
					if current_step < Step.UNCLAMP_HOUSING:
						set_step(Step.UNCLAMP_HOUSING)
				2: # REPLACE
					if current_step < Step.INSTALL_FUSE:
						set_step(Step.INSTALL_FUSE)
				3: # CALIBRATE
					if current_step < Step.CALIBRATE_CIRCUIT:
						set_step(Step.CALIBRATE_CIRCUIT)
				4: # TEST
					if current_step < Step.SYSTEM_TEST:
						set_step(Step.SYSTEM_TEST)
				5: # COMPLETED
					if current_step < Step.TUTORIAL_COMPLETE:
						set_step(Step.TUTORIAL_COMPLETE)
		)

func get_current_step() -> int:
	return current_step

func get_current_title() -> String:
	if current_step < STEP_DATA.size():
		return STEP_DATA[current_step]["title"]
	return "Tutorial Completed"

func get_current_instruction() -> String:
	if current_step < STEP_DATA.size():
		return STEP_DATA[current_step]["desc"]
	return "All diagnostic steps nominal."

func advance_step() -> void:
	if current_step < Step.TUTORIAL_COMPLETE:
		current_step += 1
		_broadcast_step()
		if current_step == Step.TUTORIAL_COMPLETE:
			is_active = false
			tutorial_completed.emit()

func set_step(step_idx: int) -> void:
	current_step = clamp(step_idx, 0, Step.TUTORIAL_COMPLETE)
	_broadcast_step()
	if current_step == Step.TUTORIAL_COMPLETE:
		is_active = false
		tutorial_completed.emit()

func is_completed() -> bool:
	return current_step >= Step.TUTORIAL_COMPLETE

func reset_tutorial() -> void:
	current_step = Step.OBSERVE_SYMPTOMS
	is_active = false
	_broadcast_step()

func _broadcast_step() -> void:
	tutorial_step_changed.emit(current_step, get_current_title(), get_current_instruction())
