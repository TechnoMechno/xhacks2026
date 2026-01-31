extends Node

# Single source of truth for game state

# Constants for mood deltas
const MOOD_DELTA = {
	"gaslight": -20,
	"insult": -15,
	"lie": -10,
	"apology": 10,
	"empathy": 15,
	"explanation": 5,
	"do_dishes": 15,
	"clean": 10,
	"give_food": 20,
	"nonsense": -5
}

# Constants for thresholds
const MOOD_WIN_THRESHOLD = 80
const MOOD_LOSE_THRESHOLD = 0

# Mood ranges from 0 (very angry) to 100 (happy)
var mood: int = 50

# Game flags
var flags: Dictionary = {
	"apologized": false,
	"did_dishes": false,
	"cleaned": false,
	"ordered_food": false,
	"gave_food": false
}

# Signals
signal mood_changed(new_mood: int)
signal game_won
signal game_lost
signal flag_changed(flag_name: String, value: bool)

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
		flag_changed.emit(flag_name, value)

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func apply_intent(intent: String) -> void:
	# Apply mood changes based on intent
	if intent in MOOD_DELTA:
		var delta = MOOD_DELTA[intent]

		# Special handling for specific intents
		match intent:
			"apology":
				set_flag("apologized", true)
				apply_mood_delta(delta)
			"do_dishes":
				set_flag("did_dishes", true)
				apply_mood_delta(delta)
			"clean":
				set_flag("cleaned", true)
				apply_mood_delta(delta)
			"give_food":
				if get_flag("ordered_food"):
					set_flag("gave_food", true)
					apply_mood_delta(delta)
			_:
				apply_mood_delta(delta)

func _check_win_lose() -> void:
	if mood >= MOOD_WIN_THRESHOLD:
		game_won.emit()
	elif mood <= MOOD_LOSE_THRESHOLD:
		game_lost.emit()
