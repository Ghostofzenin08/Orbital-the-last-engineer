class_name HullBreachSeal
extends Interactable

# Hull Breach Seal interactable for ORBITAL: The Last Engineer
# Milestone 4: Breached maintenance crawlway seal requiring Multitool CUT_WELD mode to patch.

signal breach_sealed

@export var panel_name: String = "Hull Breach Rupture"
@export var is_sealed: bool = false
@export var device_id: String = "hull_breach_seal"
@export var compartment_id: String = "maintenance_crawlway"
@export var required_mode: String = "CUT_WELD"

@onready var breach_glow: OmniLight3D = get_node_or_null("BreachLight")
@onready var patch_mesh: MeshInstance3D = get_node_or_null("PatchMesh")

func _ready() -> void:
	super._ready()
	_update_visuals()

func _update_visuals() -> void:
	if patch_mesh != null:
		patch_mesh.visible = is_sealed
	if breach_glow != null:
		breach_glow.light_color = Color(0.2, 0.9, 0.3) if is_sealed else Color(1.0, 0.2, 0.1)
		breach_glow.light_energy = 0.5 if is_sealed else 1.5

func get_prompt() -> String:
	if is_sealed:
		return "[Nominal] %s: Titanium Patch Welded & Airtight" % panel_name
	
	var im = get_node_or_null("/root/InventoryManager")
	if im != null and im.get_equipped_item_id() == "multitool" and im.get_multitool_mode() == required_mode:
		return "[E] Weld Titanium Reinforcement Patch over %s [%s]" % [panel_name, required_mode]
	
	return "[Breach Venting] %s (Equip Multitool in [%s] mode to weld seal)" % [panel_name, required_mode]

func _on_interacted(_player: Node) -> void:
	if is_sealed:
		AudioManager.play_sfx("denied")
		return
	
	var im = get_node_or_null("/root/InventoryManager")
	if im == null or im.get_equipped_item_id() != "multitool" or im.get_multitool_mode() != required_mode:
		AudioManager.play_sfx("denied")
		return
	
	perform_seal()

func perform_seal() -> void:
	is_sealed = true
	AudioManager.play_sfx("repair")
	_update_visuals()
	
	if EnvironmentalManager != null and "instance" in EnvironmentalManager and EnvironmentalManager.instance != null:
		EnvironmentalManager.instance.seal_hull_breach(compartment_id)
	elif has_node("/root/EnvironmentalManager"):
		get_node("/root/EnvironmentalManager").seal_hull_breach(compartment_id)
	
	if has_node("/root/MissionManager"):
		var mm = get_node("/root/MissionManager")
		if mm.has_method("mark_breach_sealed"):
			mm.mark_breach_sealed(compartment_id)
	
	if has_node("/root/ShipState"):
		var ss = get_node("/root/ShipState")
		var dev = ss.get_device(device_id)
		if dev != null:
			dev.health = 100.0
	
	breach_sealed.emit()

func export_save_data() -> Dictionary:
	return {
		"is_sealed": is_sealed
	}

func import_save_data(data: Dictionary) -> void:
	is_sealed = bool(data.get("is_sealed", false))
	if is_sealed:
		if EnvironmentalManager != null and "instance" in EnvironmentalManager and EnvironmentalManager.instance != null:
			EnvironmentalManager.instance.seal_hull_breach(compartment_id)
		elif has_node("/root/EnvironmentalManager"):
			get_node("/root/EnvironmentalManager").seal_hull_breach(compartment_id)
	_update_visuals()
