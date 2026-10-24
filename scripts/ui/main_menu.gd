class_name MainMenu
extends Control

# Main Menu controller for ORBITAL: The Last Engineer

@onready var new_game_btn: Button = %NewGameButton
@onready var continue_btn: Button = %ContinueButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var close_settings_btn: Button = %CloseSettingsButton
@onready var sens_slider: HSlider = %SensitivitySlider
@onready var vol_slider: HSlider = %VolumeSlider

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.stop_all()
	
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit)
	close_settings_btn.pressed.connect(_on_close_settings)
	
	sens_slider.value_changed.connect(_on_sens_changed)
	vol_slider.value_changed.connect(_on_vol_changed)
	
	# Load saved settings values
	sens_slider.value = SaveManager.mouse_sensitivity * 1000.0
	vol_slider.value = SaveManager.master_volume * 100.0
	
	# Check if save file exists
	continue_btn.disabled = not SaveManager.has_save_file()
	settings_panel.visible = false

func _on_new_game() -> void:
	AudioManager.play_sfx("click")
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()
	get_tree().change_scene_to_file("res://scenes/levels/ship_interior.tscn")

func _on_continue() -> void:
	if not SaveManager.has_save_file():
		return
	AudioManager.play_sfx("click")
	# Store pending load request
	SaveManager.set_meta("pending_load", true)
	get_tree().change_scene_to_file("res://scenes/levels/ship_interior.tscn")

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	settings_panel.visible = true

func _on_close_settings() -> void:
	AudioManager.play_sfx("click")
	settings_panel.visible = false

func _on_sens_changed(val: float) -> void:
	SaveManager.mouse_sensitivity = val / 1000.0
	SaveManager.save_settings()

func _on_vol_changed(val: float) -> void:
	var vol := val / 100.0
	SaveManager.master_volume = vol
	AudioManager.set_volume(vol)
	SaveManager.save_settings()

func _on_quit() -> void:
	get_tree().quit()
