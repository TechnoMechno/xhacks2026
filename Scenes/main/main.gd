extends Node2D

# Wires GameState signals to UI updates and dialogue

@onready var player: CharacterBody2D = $player
@onready var girlfriend: Node2D = $Girlfriend
@onready var dialogue_ui: CanvasLayer = $DialogueUI

@onready var end_screen = $HUD/EndScreen

func _ready() -> void:
	# Game state signals
	GameState.game_won.connect(_on_game_won)
	GameState.game_lost.connect(_on_game_lost)

	# Wire girlfriend interaction to dialogue
	if girlfriend:
		girlfriend.interaction_requested.connect(_on_girlfriend_interaction)

	# Wire dialogue open/close to player freeze
	if dialogue_ui:
		dialogue_ui.dialogue_opened.connect(_on_dialogue_opened)
		dialogue_ui.dialogue_closed.connect(_on_dialogue_closed)

func _on_girlfriend_interaction() -> void:
	# Open dialogue with Penny
	if dialogue_ui:
		dialogue_ui.open_dialogue(girlfriend)

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
