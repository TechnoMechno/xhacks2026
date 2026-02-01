extends PanelContainer

# End screen for win or lose

@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton

var won: bool = false

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	visible = false

func show_result(player_won: bool) -> void:
	won = player_won
	if won:
		message_label.text = "You Win! She forgave you!"
	else:
		message_label.text = "Game Over. She's done with you."
	visible = true

func _on_restart_pressed() -> void:
	GameState.change_state(GameState.State.MENU)
	get_tree().change_scene_to_file("res://Scenes/ui/menu.tscn")
