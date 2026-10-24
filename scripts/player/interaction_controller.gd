class_name InteractionController
extends Node3D

# Interaction Controller for ORBITAL: The Last Engineer
# Raycasts forward from the player's camera to detect and trigger Interactables on layer 3.

signal prompt_changed(prompt_text: String)

@export var ray_cast: RayCast3D
@export var player_body: CharacterBody3D

var current_interactable: Interactable = null

func _ready() -> void:
	if ray_cast == null:
		ray_cast = get_node_or_null("RayCast3D")

func _process(_delta: float) -> void:
	if ray_cast == null:
		return
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if current_interactable != null:
			current_interactable = null
			prompt_changed.emit("")
		return
	
	if ray_cast.is_colliding():
		var collider := ray_cast.get_collider()
		if collider is Interactable:
			if current_interactable != collider:
				current_interactable = collider
			prompt_changed.emit(current_interactable.get_prompt())
		else:
			if current_interactable != null:
				current_interactable = null
				prompt_changed.emit("")
	else:
		if current_interactable != null:
			current_interactable = null
			prompt_changed.emit("")

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)):
		if current_interactable != null and is_instance_valid(current_interactable):
			current_interactable.interact(player_body)
			# Refresh prompt immediately
			prompt_changed.emit(current_interactable.get_prompt())
