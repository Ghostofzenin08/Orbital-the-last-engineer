class_name TerminalConsole
extends Interactable

# 3D Terminal Console interactable for ORBITAL: The Last Engineer
# Triggers the interactive terminal dialog modal.

@export var terminal_type: String = "diagnostics" # "diagnostics", "bridge_comms"
@export var terminal_title: String = "Engineering Diagnostics Console"

@onready var screen_mesh: MeshInstance3D = get_node_or_null("ScreenMesh")
@onready var screen_light: OmniLight3D = get_node_or_null("ScreenLight")

func get_prompt() -> String:
	return "[E / Enter] Access %s" % terminal_title

func _on_interacted(player: Node) -> void:
	AudioManager.play_sfx("click")
	
	# Find terminal dialog in UI layer
	var dialog: TerminalDialog = null
	if player != null and player.has_node("HUD/TerminalDialog"):
		dialog = player.get_node("HUD/TerminalDialog")
	else:
		dialog = get_tree().root.find_child("TerminalDialog", true, false)
	
	if dialog != null:
		dialog.open_terminal(terminal_type, terminal_title)
	else:
		push_warning("TerminalDialog not found in scene tree")
