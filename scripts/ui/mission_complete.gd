class_name MissionCompleteScreen
extends Control

# Mission Complete / Victory screen for ORBITAL: The Last Engineer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.stop_all()
	AudioManager.play_sfx("victory")
	
	%ReturnButton.pressed.connect(func():
		AudioManager.stop_all()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
