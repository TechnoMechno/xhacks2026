extends Control

# Main menu screen

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	GameState.start_game()
	get_tree().change_scene_to_file("res://Scenes/IntroCutscene.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
