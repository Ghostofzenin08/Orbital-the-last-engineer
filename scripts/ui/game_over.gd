class_name GameOverScreen
extends Control

# Game Over / Asphyxiation screen for ORBITAL: The Last Engineer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.stop_all()
	AudioManager.play_sfx("denied")
	
	%ReloadButton.pressed.connect(_on_reload)
	%MainMenuButton.pressed.connect(_on_main_menu)
	
	if not SaveManager.has_save_file():
		%ReloadButton.text = "RESTART MISSION"

func _on_reload() -> void:
	AudioManager.stop_all()
	if SaveManager.has_save_file():
		SaveManager.set_meta("pending_load", true)
	else:
		ShipSystemManager.reset_to_defaults()
		MissionManager.reset_missions()
	get_tree().change_scene_to_file("res://scenes/levels/ship_interior.tscn")

func _on_main_menu() -> void:
	AudioManager.stop_all()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
