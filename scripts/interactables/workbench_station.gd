class_name WorkbenchStation
extends Interactable

# Interactive Workbench & Repair Station for ORBITAL: The Last Engineer
# Located in the Engineering Bay.
# Allows component inspection, component refurbishment/fabrication, and Diagnostic Scanner battery recharging.

signal scanner_recharged(new_battery: float)
signal component_refurbished(item_id: String)

@export var station_name: String = "Engineering Bay Workbench"
@export var requires_power: bool = true

@onready var cradle_led: MeshInstance3D = get_node_or_null("CradleLED")
@onready var cradle_light: OmniLight3D = get_node_or_null("CradleLight")

var _mat_powered: StandardMaterial3D
var _mat_unpowered: StandardMaterial3D

func _ready() -> void:
	super._ready()
	_create_materials()
	_update_visuals()
	ShipSystemManager.system_state_changed.connect(func(_sys, _old, _new): _update_visuals())

func _create_materials() -> void:
	_mat_powered = StandardMaterial3D.new()
	_mat_powered.albedo_color = Color(0.1, 0.7, 1.0)
	_mat_powered.emission_enabled = true
	_mat_powered.emission = Color(0.1, 0.8, 1.0)
	_mat_powered.emission_energy_multiplier = 2.0

	_mat_unpowered = StandardMaterial3D.new()
	_mat_unpowered.albedo_color = Color(0.3, 0.2, 0.1)
	_mat_unpowered.emission_enabled = true
	_mat_unpowered.emission = Color(0.6, 0.2, 0.05)
	_mat_unpowered.emission_energy_multiplier = 0.4

func is_station_powered() -> bool:
	if not requires_power:
		return true
	return ShipSystemManager.is_system_online("primary_power") or ShipSystemManager.is_system_online("power_distribution")

func get_prompt() -> String:
	if not is_station_powered():
		return "[Unpowered] %s (Requires Generator / Bus Power)" % station_name
	
	var scanner_battery := InventoryManager.get_scanner_battery()
	if scanner_battery < 99.0:
		return "[E / Enter] Dock & Fast-Recharge Scanner [Charge: %d%%]" % int(scanner_battery)
	
	var equipped := InventoryManager.get_equipped_item_id()
	if equipped != "" and equipped != "diagnostic_scanner" and equipped != "multitool":
		var dname := _get_item_display_name(equipped)
		return "[E / Enter] Inspect & Service %s at Workbench" % dname
	
	# If scanner is full, prompt offers component fabrication/refurbishment
	return "[E / Enter] Access Workbench [Refurbish Fuses / Consumables]"

func can_interact(_player: Node) -> bool:
	return true

func _on_interacted(player: Node) -> void:
	if not is_station_powered():
		AudioManager.play_sfx("denied")
		_notify(player, "WORKBENCH OFFLINE: Close Fusion Generator Breaker first.")
		return
	
	var cur_battery := InventoryManager.get_scanner_battery()
	if cur_battery < 99.0:
		recharge_scanner(player)
		return
	
	var equipped := InventoryManager.get_equipped_item_id()
	if equipped != "" and equipped != "diagnostic_scanner" and equipped != "multitool":
		var info := inspect_component(equipped)
		refurbish_component(equipped, player)
		_notify(player, "INSPECTION: %s - %s" % [info.get("condition", "NOMINAL"), info.get("analysis", "")])
		return
	
	# Refurbish or fabricate consumable
	refurbish_component("spare_fuse", player)

func _get_item_display_name(item_id: String) -> String:
	match item_id:
		"diagnostic_scanner":
			return "Diagnostic Scanner"
		"multitool":
			return "Multitool"
		"spare_fuse":
			return "Spare Fuse"
		"coolant_canister":
			return "Coolant Canister"
		"scrubber_cartridge":
			return "Filter Cartridge"
		"battery_cell":
			return "Battery Cell"
		"coolant_coupler":
			return "Coolant Coupler"
		_:
			return item_id.replace("_", " ").capitalize()

func recharge_scanner(player: Node = null) -> bool:
	if not is_station_powered():
		return false
	
	var new_bat := InventoryManager.recharge_scanner(100.0)
	scanner_recharged.emit(new_bat)
	_notify(player, "Scanner Recharged to 100% at Workbench Cradle.")
	return true

func refurbish_component(target_item: String, player: Node = null) -> bool:
	if not is_station_powered():
		return false
	
	InventoryManager.add_item(target_item, 1)
	AudioManager.play_sfx("repair")
	component_refurbished.emit(target_item)
	var dname := target_item.replace("_", " ").capitalize()
	_notify(player, "Workbench Refurbished: 1x %s." % dname)
	return true

func inspect_component(item_id: String) -> Dictionary:
	var info := {
		"item_id": item_id,
		"condition": "NOMINAL",
		"analysis": "Specification matches Astraea-7 engineering tolerances."
	}
	match item_id:
		"coolant_coupler":
			info["analysis"] = "Ceramic composite coolant coupler with reinforced hermetic O-ring."
		"spare_fuse":
			info["analysis"] = "High-voltage ceramic fuse rated for 600V / 50A power conduits."
		"coolant_canister":
			info["analysis"] = "Pressurized liquid fluorocarbon coolant cylinder for thermal dissipation loops."
		"scrubber_cartridge":
			info["analysis"] = "Amine chemical absorption bed for regenerative carbon dioxide scrubbing."
		"battery_cell":
			info["analysis"] = "High-density solid-state lithium-sulfur emergency power cell."
	return info

func _update_visuals() -> void:
	var pwr := is_station_powered()
	if cradle_led != null:
		cradle_led.material_override = _mat_powered if pwr else _mat_unpowered
	if cradle_light != null:
		cradle_light.light_color = Color(0.2, 0.8, 1.0) if pwr else Color(0.8, 0.3, 0.1)
		cradle_light.light_energy = 1.0 if pwr else 0.3

func _notify(player: Node, msg: String) -> void:
	if player != null and "hud" in player and player.hud != null and player.hud.has_method("show_notification"):
		player.hud.show_notification(msg)
	elif get_tree() != null and get_tree().root != null:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud != null and hud.has_method("show_notification"):
			hud.show_notification(msg)
