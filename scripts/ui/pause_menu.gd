class_name PauseMenu
extends Control

# Pause Menu for ORBITAL: The Last Engineer
# Provides Resume, Settings (Sensitivity, Volume), Save Game, and Exit to Main Menu.

signal resumed

@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var volume_slider: HSlider = %VolumeSlider
@onready var save_notice_label: Label = %SaveNoticeLabel

var _player_ref: Node3D = null

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

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
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

func resume_game() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	resumed.emit()

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
