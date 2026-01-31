extends "res://scenes/interactables/interactable.gd"

func interact() -> void:
	if GameState.get_flag("ordered_food"):
		GameState.apply_intent("give_food")
		print("You gave her the food! Big mood boost!")
		GameState.set_flag("ordered_food", false)  # Food consumed
	else:
		print("You don't have any food to give her. Try ordering from the phone.")
