extends Node2D

# Wires GameState signals to UI updates and dialogue

@onready var player: CharacterBody2D = $player
@onready var girlfriend: CharacterBody2D = $girlfriend
@onready var dialogue_ui: CanvasLayer = $DialogueUI

@onready var end_screen = $HUD/EndScreen

func _ready() -> void:
	print("[Main] _ready() called")
	print("[Main] girlfriend = ", girlfriend)
	print("[Main] dialogue_ui = ", dialogue_ui)

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
	if dialogue_ui:
		dialogue_ui.dialogue_opened.connect(_on_dialogue_opened)
		dialogue_ui.dialogue_closed.connect(_on_dialogue_closed)
		print("[Main] Connected to dialogue_ui signals")
	else:
		print("[Main] ERROR: dialogue_ui is null!")

func _on_girlfriend_interaction() -> void:
	# Open dialogue with Penny
	print("[Main] _on_girlfriend_interaction() called")
	if dialogue_ui:
		print("[Main] Calling dialogue_ui.open_dialogue()")
		dialogue_ui.open_dialogue(girlfriend)
	else:
		print("[Main] ERROR: dialogue_ui is null in interaction handler!")

func _on_dialogue_opened() -> void:
	# Freeze player
	if player:
		player.set_physics_process(false)

func _on_dialogue_closed() -> void:
	# Unfreeze player
	if player:
		player.set_physics_process(true)

func _on_game_won() -> void:
	end_screen.show_result(true)

func _on_game_lost() -> void:
	end_screen.show_result(false)

func _input(event: InputEvent) -> void:
	# Debug: Press TAB to reset conversation with Penny
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if girlfriend and girlfriend.has_method("reset_conversation"):
			girlfriend.reset_conversation()
			print("[Main] Reset conversation with Penny")
