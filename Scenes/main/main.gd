extends Node2D

# Wires GameState signals to UI updates and dialogue

@onready var player: CharacterBody2D = $player
@onready var girlfriend: CharacterBody2D = $girlfriend
@onready var dialogue_ui: CanvasLayer = $DialogueUI
@onready var phone_ui = $HUD/Phone
@onready var music_player: AudioStreamPlayer = $MusicPlayer

@onready var end_screen = $HUD/EndScreen

var power_hud: Node = null

func _ready() -> void:
	print("[Main] _ready() called")
	print("[Main] girlfriend = ", girlfriend)
	print("[Main] dialogue_ui = ", dialogue_ui)

	# Setup music looping
	if music_player:
		music_player.finished.connect(_on_music_finished)
		print("[Main] Music player connected for looping")

	# Hide Player2 PowerHUD if it exists
	_hide_power_hud()

	# Game state signals
	GameState.game_won.connect(_on_game_won)
	GameState.game_lost.connect(_on_game_lost)
	GameState.mood_changed.connect(_on_mood_changed)

	# Wire girlfriend interaction to dialogue
	if girlfriend:
		girlfriend.interaction_requested.connect(_on_girlfriend_interaction)
		print("[Main] Connected to girlfriend.interaction_requested")
	else:
		print("[Main] ERROR: girlfriend is null!")

	# Wire dialogue open/close to player freeze
	if dialogue_ui:
		dialogue_ui.dialogue_opened.connect(_on_dialogue_opened)
		dialogue_ui.dialogue_closed.connect(_on_dialogue_closed)
		dialogue_ui.message_sent.connect(_on_player_message_sent)
		print("[Main] Connected to dialogue_ui signals")
	else:
		print("[Main] ERROR: dialogue_ui is null!")

func _on_girlfriend_interaction() -> void:
	# Open visual dialogue box only (Enter key)
	print("[Main] _on_girlfriend_interaction() called")
	if dialogue_ui and dialogue_ui.has_method("open_dialogue"):
		print("[Main] Opening dialogue box")
		dialogue_ui.open_dialogue(girlfriend)
	else:
		print("[Main] ERROR: dialogue_ui is null or missing open_dialogue method!")

func _on_player_message_sent(text: String) -> void:
	# Forward player message to girlfriend
	if girlfriend and girlfriend.has_method("receive_player_message"):
		girlfriend.receive_player_message(text)

func _on_girlfriend_reply(text: String) -> void:
	# Display girlfriend response in dialogue UI
	if dialogue_ui and dialogue_ui.has_method("add_npc_message"):
		dialogue_ui.add_npc_message(text)

func _on_girlfriend_thinking() -> void:
	# Show thinking indicator in dialogue UI
	if dialogue_ui and dialogue_ui.has_method("add_thinking_message"):
		dialogue_ui.add_thinking_message()

func _on_dialogue_opened() -> void:
	# Freeze player
	if player:
		player.set_physics_process(false)

func _on_dialogue_closed() -> void:
	# Unfreeze player
	if player:
		player.set_physics_process(true)

func _on_game_won() -> void:
	# Stop music before cutscene
	_stop_music()
	end_screen.show_result(true)

func _on_game_lost() -> void:
	# Stop music before cutscene
	_stop_music()
	end_screen.show_result(false)

func _on_music_finished() -> void:
	# Loop the music by playing it again
	if music_player:
		music_player.play()
		print("[Main] Music looped")

func _stop_music() -> void:
	if music_player:
		music_player.stop()
		print("[Main] Music stopped for cutscene")

func _hide_power_hud() -> void:
	# Find and hide the Player2 PowerHUD
	await get_tree().process_frame
	await get_tree().process_frame

	power_hud = _find_power_hud(get_tree().root)
	if power_hud:
		power_hud.visible = false
		print("[Main] Found and hidden PowerHUD: ", power_hud.name)

		# Connect to phone menu to toggle visibility
		if phone_ui:
			phone_ui.visibility_changed.connect(_on_phone_visibility_changed)
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
	if power_hud:
		power_hud.visible = phone_ui.visible

func _input(event: InputEvent) -> void:
	# Debug: Press R to reset conversation with Penny
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if girlfriend and girlfriend.has_method("reset_conversation"):
			girlfriend.reset_conversation()
			print("[Main] Reset conversation with Penny")

	# Debug: Press = to win, - to lose
	if event is InputEventKey and event.pressed and event.keycode == KEY_EQUAL:
		GameState.set_mood(GameState.MOOD_WIN_THRESHOLD)
		print("[Main] DEBUG: Triggered win state")
	elif event is InputEventKey and event.pressed and event.keycode == KEY_MINUS:
		GameState.set_mood(GameState.MOOD_LOSE_THRESHOLD)
		print("[Main] DEBUG: Triggered lose state")

func _on_mood_changed(new_mood: int) -> void:
	# Update portrait when mood changes (if dialogue is open)
	if dialogue_ui and dialogue_ui.visible:
		_update_portrait()

func _update_portrait() -> void:
	"""Update the dialogue portrait based on current mood"""
	if not dialogue_ui or not dialogue_ui.has_method("show_portrait"):
		return
	
	var mood = GameState.mood
	var portrait_name = "neutral"
	
	# Map mood values to portrait expressions
	if mood >= 80:
		portrait_name = "happy"
	elif mood >= 65:
		portrait_name = "soft_smile"
	elif mood >= 50:
		portrait_name = "neutral"
	elif mood >= 35:
		portrait_name = "sad"
	elif mood >= 20:
		portrait_name = "angry"
	elif mood >= 10:
		portrait_name = "furious"
	else:
		portrait_name = "crying"
	
	dialogue_ui.show_portrait(portrait_name)
	print("[Main] Updated portrait to: ", portrait_name, " (mood: ", mood, ")")
