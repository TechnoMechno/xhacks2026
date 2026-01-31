extends Node

# Single source of truth for game state

# Mood ranges from 0 (very angry) to 100 (happy)
var mood: int = 50

# Game flags
var flags: Dictionary = {
	"ordered_food": false,
	"did_dishes": false,
	"cleaned": false
}

# Signals
signal mood_changed(new_mood: int)
signal game_won
signal game_lost

func _ready() -> void:
	pass

func set_mood(new_mood: int) -> void:
	mood = clamp(new_mood, 0, 100)
	mood_changed.emit(mood)
	_check_win_lose()

func apply_mood_delta(delta: int) -> void:
	set_mood(mood + delta)

func set_flag(flag_name: String, value: bool = true) -> void:
	if flag_name in flags:
		flags[flag_name] = value

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func apply_intent(intent: String) -> void:
	# Apply mood changes based on intent
	match intent:
		"apology":
			apply_mood_delta(10)
		"insult":
			apply_mood_delta(-15)
		"do_dishes":
			apply_mood_delta(15)
			set_flag("did_dishes", true)
		"clean":
			apply_mood_delta(10)
			set_flag("cleaned", true)
		"give_food":
			if get_flag("ordered_food"):
				apply_mood_delta(20)
		"nonsense":
			apply_mood_delta(-5)

func _check_win_lose() -> void:
	if mood >= 80:
		game_won.emit()
	elif mood <= 0:
		game_lost.emit()
