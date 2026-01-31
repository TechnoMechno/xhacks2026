extends Node

# Template tool functions for Player2AINPC
# The AI can call these functions during conversation.
# Add documentation comments (##) above each function to describe what it does.
# The Player2AINPC will scan this node and expose these functions to the AI.

## Get the current game world status including what actions the player has taken
func get_world_status() -> String:
	var status_parts: Array[String] = []

	if GameState.flags.get("did_dishes", false):
		status_parts.append("Player has done the dishes")
	if GameState.flags.get("cleaned", false):
		status_parts.append("Player has cleaned the room")
	if GameState.flags.get("ordered_food", false):
		status_parts.append("Player has ordered food")
	if GameState.flags.get("gave_food", false):
		status_parts.append("Player gave you food")
	if GameState.flags.get("apologized", false):
		status_parts.append("Player has apologized")

	if status_parts.is_empty():
		return "The player hasn't done anything helpful yet."

	return "Player actions: " + ", ".join(status_parts)

## Express a specific emotion through animation or visual feedback
func express_emotion(emotion: String) -> String:
	# Placeholder - implement animation changes here
	# Valid emotions: "angry", "very_angry", "sad", "hopeful", "happy"
	print("[Girlfriend] Expressing emotion: ", emotion)
	return "Expressed " + emotion

## Storm off angrily - use when extremely upset
func storm_off() -> String:
	print("[Girlfriend] Storming off!")
	# Placeholder - implement movement/animation here
	# Could emit a signal that main.gd listens to
	return "Stormed off angrily"

## Sigh in frustration
func sigh() -> String:
	print("[Girlfriend] *sigh*")
	return "Sighed"

## Cry - use when very hurt emotionally
func cry() -> String:
	print("[Girlfriend] Crying...")
	return "Started crying"

## Calm down slightly - use when player shows genuine remorse
func calm_down() -> String:
	print("[Girlfriend] Calming down a bit...")
	return "Calmed down slightly"
