class_name GameOverScreen
extends Control

# Game Over / Asphyxiation / Specimen Termination screen for ORBITAL: The Last Engineer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.stop_all()
	AudioManager.play_sfx("denied")
	
	%ReloadButton.pressed.connect(_on_reload)
	%MainMenuButton.pressed.connect(_on_main_menu)
	
	if not SaveManager.has_save_file():
		%ReloadButton.text = "RESTART MISSION"
	
	_configure_death_cause()

func _configure_death_cause() -> void:
	var title_lbl: Label = get_node_or_null("%Title")
	if title_lbl == null:
		title_lbl = get_node_or_null("Center/Panel/Margin/VBox/Title")
	
	var body_lbl: Label = get_node_or_null("%BodyText")
	if body_lbl == null:
		body_lbl = get_node_or_null("Center/Panel/Margin/VBox/BodyText")
	
	var reason: String = ""
	if ShipState != null and "death_reason" in ShipState:
		reason = ShipState.death_reason
	
	if reason == "CREATURE_ATTACK":
		if title_lbl != null:
			title_lbl.text = "CRITICAL FAILURE - BIOLOGICAL SPECIMEN TERMINATION"
		if body_lbl != null:
			body_lbl.text = "The engineered Project Chimera specimen intercepted and eliminated the station engineer. Containment has completely collapsed across all sectors of the Astraea-7."
	else:
		if title_lbl != null:
			title_lbl.text = "CRITICAL FAILURE - ATMOSPHERIC COLLAPSE"
		if body_lbl != null:
			body_lbl.text = "Ambient oxygen depleted to 0.0%. The atmospheric scrubbers in Life Support remained unpowered or unsealed. Environmental containment has collapsed across all bays of the Astraea-7."

func _on_reload() -> void:
	AudioManager.stop_all()
	if ShipState != null and "death_reason" in ShipState:
		ShipState.death_reason = ""
	if SaveManager.has_save_file():
		SaveManager.set_meta("pending_load", true)
	else:
		ShipSystemManager.reset_to_defaults()
		MissionManager.reset_missions()
	get_tree().change_scene_to_file("res://scenes/levels/ship_interior.tscn")

func _on_main_menu() -> void:
	AudioManager.stop_all()
	if ShipState != null and "death_reason" in ShipState:
		ShipState.death_reason = ""
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
