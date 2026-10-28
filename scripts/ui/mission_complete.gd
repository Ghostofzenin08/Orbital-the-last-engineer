class_name MissionCompleteScreen
extends Control

# Mission Complete / Epilogue screen for ORBITAL: The Last Engineer
# Displays last.png (back story) then "Thank you For Playing" on solid black background with calm chime audio

@onready var backstory_container: VBoxContainer = %BackstoryContainer
@onready var thank_you_container: VBoxContainer = %ThankYouContainer
@onready var prompt_texture: TextureRect = %PromptTexture
@onready var return_button: Button = %ReturnButton

var in_thank_you_phase: bool = false
var is_transitioning: bool = false
var pulse_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	AudioManager.stop_all()
	if AudioManager.has_method("play_revelation_chime"):
		AudioManager.play_revelation_chime()
	else:
		AudioManager.play_sfx("revelation_chime")
	
	if return_button != null:
		return_button.pressed.connect(_return_to_main_menu)
	
	_start_prompt_pulse()
	
	# Smooth initial fade-in on pure black
	modulate.a = 0.0
	var in_tween := create_tween()
	in_tween.tween_property(self, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)

func _start_prompt_pulse() -> void:
	if prompt_texture == null:
		return
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(prompt_texture, "modulate:a", 0.3, 0.8).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(prompt_texture, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
	
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if not in_thank_you_phase:
				_show_thank_you()
			else:
				_return_to_main_menu()
	elif event is InputEventMouseButton:
		if event.pressed:
			if not in_thank_you_phase:
				_show_thank_you()

func _show_thank_you() -> void:
	if in_thank_you_phase or is_transitioning:
		return
	in_thank_you_phase = true
	is_transitioning = true
	AudioManager.play_sfx("click")
	
	if pulse_tween != null and pulse_tween.is_valid():
		pulse_tween.kill()
	
	# Fade out backstory and prompt
	var tween := create_tween()
	if backstory_container != null:
		tween.tween_property(backstory_container, "modulate:a", 0.0, 0.35)
	if prompt_texture != null:
		tween.parallel().tween_property(prompt_texture, "modulate:a", 0.0, 0.35)
	
	tween.finished.connect(func():
		if backstory_container != null:
			backstory_container.visible = false
		if prompt_texture != null:
			prompt_texture.visible = false
		
		if thank_you_container != null:
			thank_you_container.visible = true
			thank_you_container.modulate.a = 0.0
		if return_button != null:
			return_button.visible = true
			return_button.modulate.a = 0.0
		
		AudioManager.play_sfx("revelation_chime")
		
		var reveal_tween := create_tween().set_parallel(true)
		if thank_you_container != null:
			reveal_tween.tween_property(thank_you_container, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
		if return_button != null:
			reveal_tween.tween_property(return_button, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
		reveal_tween.finished.connect(func(): is_transitioning = false)
	)

func _return_to_main_menu() -> void:
	if is_transitioning and in_thank_you_phase:
		return
	is_transitioning = true
	AudioManager.play_sfx("click")
	
	var fade_out := create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.45)
	fade_out.finished.connect(func():
		AudioManager.stop_all()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
