extends "res://scenes/interactables/interactable.gd"

func interact() -> void:
	if not GameState.get_flag("cleaned"):
		GameState.apply_intent("clean")
		print("You cleaned the floor! Mood improved.")
	else:
		print("The floor is already clean.")
