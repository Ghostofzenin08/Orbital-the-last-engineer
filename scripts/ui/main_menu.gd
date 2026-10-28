class_name MainMenu
extends Control

# Main Menu controller for ORBITAL: The Last Engineer

@onready var new_game_btn: Button = %NewGameButton
@onready var continue_btn: Button = %ContinueButton
@onready var game_mode_btn: Button = get_node_or_null("%GameModeButton")
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton
@onready var arrow_start: TextureRect = get_node_or_null("%ArrowStart")
@onready var arrow_continue: TextureRect = get_node_or_null("%ArrowContinue")
@onready var arrow_game_mode: TextureRect = get_node_or_null("%ArrowGameMode")
@onready var arrow_settings: TextureRect = get_node_or_null("%ArrowSettings")
@onready var arrow_quit: TextureRect = get_node_or_null("%ArrowQuit")
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

	# Wire up arrow selector indicators for Figma hover/focus state
	_setup_button_hover(new_game_btn, arrow_start)
	_setup_button_hover(continue_btn, arrow_continue)
	if game_mode_btn != null:
		_setup_button_hover(game_mode_btn, arrow_game_mode)
	_setup_button_hover(settings_btn, arrow_settings)
	_setup_button_hover(quit_btn, arrow_quit)
	
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

func _setup_button_hover(btn: Button, arrow: TextureRect) -> void:
	if btn == null or arrow == null:
		return
	arrow.modulate.a = 0.0
	btn.mouse_entered.connect(func():
		_set_arrow_visible(arrow, true)
	)
	btn.mouse_exited.connect(func():
		if not btn.has_focus():
			_set_arrow_visible(arrow, false)
	)
	btn.focus_entered.connect(func():
		_set_arrow_visible(arrow, true)
	)
	btn.focus_exited.connect(func():
		_set_arrow_visible(arrow, false)
	)

func _set_arrow_visible(arrow: TextureRect, show: bool) -> void:
	if arrow == null:
		return
	if is_inside_tree():
		var tween = create_tween()
		if tween:
			tween.tween_property(arrow, "modulate:a", 1.0 if show else 0.0, 0.1)
			return
	arrow.modulate.a = 1.0 if show else 0.0

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
	var mode_text := "Game Mode: Feel (Casual)" if is_feel else "Game Mode: Logical (Engineering)"
	var col := Color(1.0, 0.72, 0.4) if is_feel else Color(0.88, 0.44, 0.44)
	
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
		look_mode_btn.add_theme_color_override("font_color", Color(0.95, 0.65, 0.45) if is_arrows else Color(0.92, 0.42, 0.42))

func _on_new_game() -> void:
	AudioManager.play_sfx("click")
	ShipSystemManager.reset_to_defaults()
	MissionManager.reset_missions()
	get_tree().change_scene_to_file("res://scenes/ui/story_intro.tscn")

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
