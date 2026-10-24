class_name Interactable
extends StaticBody3D

# Base class for all interactable 3D objects in ORBITAL: The Last Engineer
# Sits on Physics Layer 3 (Interactables) and responds to Player RayCast3D.

signal interacted(player: Node)
signal state_changed

@export var prompt_text: String = "Interact"
@export var interactable_id: String = ""
@export var is_enabled: bool = true

func _ready() -> void:
	# Ensure physics layer 3 is enabled
	collision_layer = 4 # bit 3 (1-indexed layer 3 = 1 << 2 = 4)
	collision_mask = 0

func can_interact(_player: Node) -> bool:
	return is_enabled

func get_prompt() -> String:
	return "[E / Enter] " + prompt_text

func interact(player: Node) -> void:
	if not can_interact(player):
		return
	interacted.emit(player)
	_on_interacted(player)

func _on_interacted(_player: Node) -> void:
	# Virtual method for subclasses
	pass

func highlight(active: bool) -> void:
	# Optional visual hover feedback
	pass
