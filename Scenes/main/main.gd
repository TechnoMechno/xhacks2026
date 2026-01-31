extends Node2D

# Wires GameState signals to UI updates

func _ready() -> void:
	GameState.game_won.connect(_on_game_won)
	GameState.game_lost.connect(_on_game_lost)

func _on_game_won() -> void:
	print("Game Won!")
	# TODO: Show end screen with won = true

func _on_game_lost() -> void:
	print("Game Lost!")
	# TODO: Show end screen with won = false
