extends Node2D

# Wires GameState signals to UI updates and dialogue

@onready var player: CharacterBody2D = $player
@onready var girlfriend: CharacterBody2D = $girlfriend
#@onready var dialogue_ui: CanvasLayer = $DialogueUI
#@onready var phone_ui = $HUD/Phone

#@onready var end_screen = $HUD/EndScreen

var power_hud: Node = null

func _ready() -> void:
	print("[Main] _ready() called")
	print("[Main] girlfriend = ", girlfriend)
	#print("[Main] dialogue_ui = ", dialogue_ui)

	# Hide Player2 PowerHUD if it exists
	_hide_power_hud()

	# Game state signals
	GameState.game_won.connect(_on_game_won)
	GameState.game_lost.connect(_on_game_lost)

	# Wire girlfriend interaction to dialogue
	if girlfriend:
		girlfriend.interaction_requested.connect(_on_girlfriend_interaction)
		print("[Main] Connected to girlfriend.interaction_requested")
	else:
		print("[Main] ERROR: girlfriend is null!")

	# Wire dialogue open/close to player freeze
	#if dialogue_ui:
	#	dialogue_ui.dialogue_opened.connect(_on_dialogue_opened)
	#	dialogue_ui.dialogue_closed.connect(_on_dialogue_closed)
	#	print("[Main] Connected to dialogue_ui signals")
	#else:
	#	print("[Main] ERROR: dialogue_ui is null!")

func _on_girlfriend_interaction() -> void:
	# Open dialogue with Penny
	print("[Main] _on_girlfriend_interaction() called")
	#if dialogue_ui:
	#	print("[Main] Calling dialogue_ui.open_dialogue()")
	#	dialogue_ui.open_dialogue(girlfriend)
	#else:
	#	print("[Main] ERROR: dialogue_ui is null in interaction handler!")

func _on_dialogue_opened() -> void:
	# Freeze player
	if player:
		player.set_physics_process(false)

func _on_dialogue_closed() -> void:
	# Unfreeze player
	if player:
		player.set_physics_process(true)

func _on_game_won() -> void:
	#end_screen.show_result(true)
	print("[Main] Game won!")

func _on_game_lost() -> void:
	#end_screen.show_result(false)
	print("[Main] Game lost!")

func _hide_power_hud() -> void:
	# Find and hide the Player2 PowerHUD
	await get_tree().process_frame
	await get_tree().process_frame

	power_hud = _find_power_hud(get_tree().root)
	if power_hud:
		power_hud.visible = false
		print("[Main] Found and hidden PowerHUD: ", power_hud.name)

		# Connect to phone menu to toggle visibility
		#if phone_ui:
		#	phone_ui.visibility_changed.connect(_on_phone_visibility_changed)
	else:
		print("[Main] PowerHUD not found")

func _find_power_hud(node: Node) -> Node:
	var node_name = node.name.to_lower()
	var script_name = ""
	if node.get_script():
		script_name = str(node.get_script().get_path()).to_lower()

	# Check if this is the PowerHUD
	if ("power" in node_name and "hud" in node_name) or "power_hud" in script_name:
		return node

	# Check children recursively
	for child in node.get_children():
		var result = _find_power_hud(child)
		if result:
			return result

	return null

func _on_phone_visibility_changed() -> void:
	# Toggle PowerHUD visibility with phone menu
	#if power_hud:
	#	power_hud.visible = phone_ui.visible
	pass

func _input(event: InputEvent) -> void:
	# Debug: Press R to reset conversation with Penny
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if girlfriend and girlfriend.has_method("reset_conversation"):
			girlfriend.reset_conversation()
			print("[Main] Reset conversation with Penny")
