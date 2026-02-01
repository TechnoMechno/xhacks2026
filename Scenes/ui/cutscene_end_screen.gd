extends CanvasLayer

# End screen shown after win/lose cutscene with restart/quit buttons

@onready var message_label: Label = $Panel/VBoxContainer/MessageLabel
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Check if player won or lost from GameState
	if GameState.mood >= 100:
		message_label.text = "You Win!\nShe forgave you!"
	else:
		message_label.text = "Game Over\nShe didn't forgive you..."

func _on_restart_pressed() -> void:
	GameState.change_state(GameState.State.MENU)
	get_tree().change_scene_to_file("res://Scenes/ui/menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
