extends "res://scenes/interactables/interactable.gd"

func interact() -> void:
	if not GameState.get_flag("did_dishes"):
		GameState.apply_intent("do_dishes")
		print("You did the dishes! Mood improved.")
	else:
		print("The dishes are already clean.")
