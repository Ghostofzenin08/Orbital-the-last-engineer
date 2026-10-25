class_name MainMenu
extends Control

# Main Menu controller for ORBITAL: The Last Engineer

@onready var new_game_btn: Button = %NewGameButton
@onready var continue_btn: Button = %ContinueButton
@onready var game_mode_btn: Button = get_node_or_null("%GameModeButton")
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var close_settings_btn: Button = %CloseSettingsButton
@onready var look_mode_btn: Button = get_node_or_null("%LookModeButton")
@onready var settings_game_mode_btn: Button = get_node_or_null("%SettingsGameModeButton")
@onready var sens_slider: HSlider = %SensitivitySlider
@onready var vol_slider: HSlider = %VolumeSlider

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.stop_all()
	
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	if game_mode_btn != null:
		game_mode_btn.pressed.connect(_on_toggle_game_mode)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit)
	close_settings_btn.pressed.connect(_on_close_settings)
	if look_mode_btn != null:
		look_mode_btn.pressed.connect(_on_toggle_look_mode)
	if settings_game_mode_btn != null:
		settings_game_mode_btn.pressed.connect(_on_toggle_game_mode)
	
	sens_slider.value_changed.connect(_on_sens_changed)
	vol_slider.value_changed.connect(_on_vol_changed)
	
	# Load saved settings values
	sens_slider.value = SaveManager.mouse_sensitivity * 1000.0
	vol_slider.value = SaveManager.master_volume * 100.0
	
	if SaveManager.has_signal("game_mode_changed"):
		SaveManager.game_mode_changed.connect(func(_m): _update_mode_labels())
	if SaveManager.has_signal("look_mode_changed"):
		SaveManager.look_mode_changed.connect(func(_m): _update_look_labels())
	
	_update_mode_labels()
	_update_look_labels()
	
	# Check if save file exists
	continue_btn.disabled = not SaveManager.has_save_file()
	settings_panel.visible = false

func _on_toggle_game_mode() -> void:
	AudioManager.play_sfx("click")
	SaveManager.toggle_game_mode()
	_update_mode_labels()

func _on_toggle_look_mode() -> void:
	AudioManager.play_sfx("click")
	SaveManager.toggle_look_mode()
	_update_look_labels()

func _update_mode_labels() -> void:
	var is_feel := (SaveManager.game_mode == "feel")
	var mode_text := "GAME MODE: FEEL (CASUAL)" if is_feel else "GAME MODE: LOGICAL (ENGINEERING)"
	var col := Color(1.0, 0.75, 0.2) if is_feel else Color(0.2, 0.85, 1.0)
	
	if game_mode_btn != null:
		game_mode_btn.text = mode_text
		game_mode_btn.add_theme_color_override("font_color", col)
	if settings_game_mode_btn != null:
		settings_game_mode_btn.text = mode_text
		settings_game_mode_btn.add_theme_color_override("font_color", col)

func _update_look_labels() -> void:
	var is_arrows := (SaveManager.look_mode == "arrow_keys" or SaveManager.look_mode == "arrows")
	var look_text := "360° LOOK CONTROLS: ARROW KEYS" if is_arrows else "360° LOOK CONTROLS: MOUSE"
	if look_mode_btn != null:
		look_mode_btn.text = look_text
		look_mode_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6) if is_arrows else Color(0.2, 0.85, 1.0))

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
