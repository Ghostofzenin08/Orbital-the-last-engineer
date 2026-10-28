class_name StoryIntro
extends Control

# Story Intro prologue for ORBITAL: The Last Engineer
# Displays initial storyline 1 to 5 with Instrument Serif styling

@onready var story_texture: TextureRect = %StoryTexture
@onready var story_label: Label = %StoryLabel
@onready var story_container: VBoxContainer = %StoryContainer
@onready var prompt_texture: TextureRect = %PromptTexture
@onready var skip_btn: Button = %SkipButton
@onready var fade_rect: ColorRect = %FadeRect

var current_index: int = 0
var is_transitioning: bool = false
var has_finished: bool = false
var pulse_tween: Tween

const STORY_SLIDES: Array[Dictionary] = [
	{
		"texture": "res://assets_ui/Story01.png",
		"text": "The research team specializing in plant and animal biochemistry on the space station is specifically working on the new species..."
	},
	{
		"texture": "res://assets_ui/Story02.png",
		"text": "During the routine check, engineers found some suspicious organic matter that grows and adapts quickly, with a creepy appearance...."
	},
	{
		"texture": "res://assets_ui/story03.png",
		"text": "According to official space station authorities, a major incident suddenly occurred, and contact with the space station was lost..."
	},
	{
		"texture": "res://assets_ui/story04.png",
		"text": "One of the routine maintenance engineer docked at the space station and discovered a mysterious condition.."
	},
	{
		"texture": "res://assets_ui/story05.png",
		"alt_texture": "res://assets_ui/Story05.png",
		"text": "You are the last engineer aboard Astraea Station.\nRestore power, investigate the breach, and survive what lurks within..."
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if skip_btn != null:
		skip_btn.pressed.connect(_finish_story)
	
	_start_prompt_pulse()
	_show_slide(0)

func _unhandled_input(event: InputEvent) -> void:
	if has_finished:
		return
	
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				_finish_story()
			else:
				_next_slide()
	elif event is InputEventMouseButton:
		if event.pressed:
			_next_slide()

func _start_prompt_pulse() -> void:
	if prompt_texture == null:
		return
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(prompt_texture, "modulate:a", 0.3, 0.8).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(prompt_texture, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _show_slide(idx: int) -> void:
	if idx >= STORY_SLIDES.size():
		_finish_story()
		return
	
	current_index = idx
	var data: Dictionary = STORY_SLIDES[idx]
	
	# Determine if a texture is available
	var tex_path: String = data.get("texture", "")
	var alt_path: String = data.get("alt_texture", "")
	var tex: Texture2D = null
	
	if tex_path != "" and ResourceLoader.exists(tex_path):
		tex = load(tex_path)
	elif alt_path != "" and ResourceLoader.exists(alt_path):
		tex = load(alt_path)
	
	if tex != null and story_texture != null:
		story_texture.texture = tex
		story_texture.visible = true
		if story_label != null:
			story_label.visible = false
	else:
		if story_texture != null:
			story_texture.visible = false
		if story_label != null:
			story_label.text = data.get("text", "")
			story_label.visible = true
	
	# Fade in the story container
	if story_container != null:
		story_container.modulate.a = 0.0
		var in_tween := create_tween()
		in_tween.tween_property(story_container, "modulate:a", 1.0, 0.35)
		in_tween.finished.connect(func(): is_transitioning = false)

func _next_slide() -> void:
	if is_transitioning or has_finished:
		return
	
	is_transitioning = true
	AudioManager.play_sfx("click")
	
	if story_container != null:
		var out_tween := create_tween()
		out_tween.tween_property(story_container, "modulate:a", 0.0, 0.2)
		out_tween.finished.connect(func():
			_show_slide(current_index + 1)
		)
	else:
		_show_slide(current_index + 1)

func _finish_story() -> void:
	if has_finished:
		return
	has_finished = true
	is_transitioning = true
	
	if pulse_tween != null and pulse_tween.is_valid():
		pulse_tween.kill()
	
	if fade_rect != null:
		fade_rect.visible = true
		fade_rect.modulate.a = 0.0
		var fade_tween := create_tween()
		fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 0.45)
		fade_tween.finished.connect(_transition_to_game)
	else:
		_transition_to_game()

func _transition_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/ship_interior.tscn")
