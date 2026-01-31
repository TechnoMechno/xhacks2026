extends Node2D

# Wires GameState signals to UI updates

@onready var end_screen = $HUD/EndScreen

func _ready() -> void:
	GameState.game_won.connect(_on_game_won)
	GameState.game_lost.connect(_on_game_lost)

func _on_game_won() -> void:
	end_screen.show_result(true)

func _on_game_lost() -> void:
	end_screen.show_result(false)
