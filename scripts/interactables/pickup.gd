class_name PickupItem
extends Interactable

# Pickup interactable for ORBITAL: The Last Engineer
# Used for inventory items like spare couplers and fuses.

@export var item_id: String = "coolant_coupler"
@export var item_name: String = "Spare Coolant Coupler"

func _ready() -> void:
	super._ready()
	_check_if_collected()
	MissionManager.inventory_changed.connect(func(_inv): _check_if_collected())
	ShipSystemManager.system_state_changed.connect(func(_sys, _old, _new): _check_if_collected())

func _check_if_collected() -> void:
	if MissionManager.has_item(item_id):
		queue_free()
		return
	if item_id == "coolant_coupler" and ShipSystemManager.coolant_coupler_installed:
		queue_free()
		return

func get_prompt() -> String:
	return "[E] Take %s" % item_name

func _on_interacted(_player: Node) -> void:
	MissionManager.add_inventory_item(item_id)
	var hud = get_tree().root.find_child("HUD", true, false) if is_inside_tree() else null
	if hud != null and hud.has_method("show_notification"):
		hud.show_notification("Picked up %s" % item_name, 2.2)
	queue_free()
