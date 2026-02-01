extends Node2D

var current_animation = 0
var animations = []

func _ready() -> void:
	# Initialize the animations array after nodes are available
	$title.visible = false
	animations = [
		{"player": $player/AnimationPlayer, "anim": "appear"},
		{"player": $player/AnimationPlayer, "anim": "show phone"},
		{"player": $player/AnimationPlayer, "anim": "pan camera"},
		{"player": $title/AnimationPlayer, "anim": "appear"}
	]

	# Play the first animation
	animations[current_animation]["player"].play(animations[current_animation]["anim"])

func _input(event):
	# Detect left mouse click or space bar
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		# Wait a brief moment before advancing to let sounds start playing
		await get_tree().create_timer(0.1).timeout
		next_animation()

func next_animation():
	# Move to next animation
	current_animation += 1

	# Check if we've reached the end
	if current_animation < animations.size():
		animations[current_animation]["player"].play(animations[current_animation]["anim"])
	else:
		print("All animations complete!")
		# Transition to gameplay
		GameState.change_state(GameState.State.GAMEPLAY)
		get_tree().change_scene_to_file("res://Scenes/main/main.tscn")
