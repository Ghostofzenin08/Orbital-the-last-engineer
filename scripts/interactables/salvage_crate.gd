class_name SalvageCrate
extends Interactable

# Cuttable Salvage Container for ORBITAL: The Last Engineer
# Milestone 4: Machine staging crate requiring Multitool CUT_WELD mode to torch open.

signal crate_opened(items_received: Dictionary)

@export var crate_name: String = "Reinforced Salvage Container"
@export var is_cut_open: bool = false
@export var device_id: String = "salvage_crate"
@export var required_mode: String = "CUT_WELD"

@export var salvage_contents: Variant = {
	"battery_cell": 2,
	"spare_fuse": 2,
	"coolant_canister": 1
}

@onready var lid_mesh: MeshInstance3D = get_node_or_null("LidMesh")

func _ready() -> void:
	super._ready()
	_update_visuals()

func _update_visuals() -> void:
	if lid_mesh != null:
		lid_mesh.position = Vector3(0.6, 0.4, 0.4) if is_cut_open else Vector3.ZERO
		lid_mesh.rotation_degrees = Vector3(15, 30, 0) if is_cut_open else Vector3.ZERO

func get_prompt() -> String:
	if is_cut_open:
		return "[Opened] %s (Scavenged)" % crate_name
	
	var im = get_node_or_null("/root/InventoryManager")
	if im != null and im.get_equipped_item_id() == "multitool" and im.get_multitool_mode() == required_mode:
		return "[E] Torch Open %s with Multitool [%s]" % [crate_name, required_mode]
	
	return "[Sealed] %s (Requires Multitool in [%s] mode)" % [crate_name, required_mode]

func _on_interacted(_player: Node) -> void:
	if is_cut_open:
		AudioManager.play_sfx("denied")
		return
	
	var im = get_node_or_null("/root/InventoryManager")
	if im == null or im.get_equipped_item_id() != "multitool" or im.get_multitool_mode() != required_mode:
		AudioManager.play_sfx("denied")
		return
	
	# Torch open crate
	is_cut_open = true
	AudioManager.play_sfx("repair")
	_update_visuals()
	
	# Deposit items
	if salvage_contents is Dictionary:
		for item_id in salvage_contents.keys():
			var count: int = int(salvage_contents[item_id])
			im.add_item(str(item_id), count)
			if has_node("/root/MissionManager"):
				var mm = get_node("/root/MissionManager")
				if not mm.inventory.has(str(item_id)):
					mm.add_inventory_item(str(item_id))
	elif salvage_contents is Array:
		for item in salvage_contents:
			im.add_item(str(item), 1)
			if has_node("/root/MissionManager"):
				var mm = get_node("/root/MissionManager")
				if not mm.inventory.has(str(item)):
					mm.add_inventory_item(str(item))
	
	# Update ShipState device health
	if has_node("/root/ShipState"):
		var ss = get_node("/root/ShipState")
		var dev = ss.get_device(device_id)
		if dev != null:
			dev.health = 100.0
	
	crate_opened.emit(salvage_contents)

func export_save_data() -> Dictionary:
	return {
		"is_cut_open": is_cut_open
	}

func import_save_data(data: Dictionary) -> void:
	is_cut_open = bool(data.get("is_cut_open", false))
	_update_visuals()
