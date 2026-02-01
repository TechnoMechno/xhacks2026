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
var mood: int = 50  # Starting relationship score

# Game flags
var flags: Dictionary = {
	"apologized": false,
	"did_dishes": false,
	"cleaned": false,
	"ordered_food": false,
	"gave_food": false
}

# Game states
enum State {
	MENU,
	INTRO,
	GAMEPLAY,
	END
}

var current_state: State = State.MENU

# Signals
signal mood_changed(new_mood: int)
signal game_won
signal game_lost
signal flag_changed(flag_name: String, value: bool)
signal state_changed(new_state: State)

func _ready() -> void:
	pass

func start_game() -> void:
	# Called when start button is pressed
	# Reset game state
	mood = 50
	for key in flags:
		flags[key] = false
	change_state(State.INTRO)

func change_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	print("[STATE] Changed to: %s" % State.keys()[new_state])

func set_mood(new_mood: int) -> void:
	var old_mood = mood
	mood = clamp(new_mood, 0, 100)
	var delta = mood - old_mood
	print("[MOOD] %s" % _get_mood_bar(old_mood, delta))
	print("[GameState] ====== EMITTING mood_changed signal ======")
	print("[GameState] New mood value: ", mood)
	var connections = mood_changed.get_connections()
	print("[GameState] Signal has ", connections.size(), " listener(s)")
	for conn in connections:
		print("[GameState]   -> ", conn.callable)
	mood_changed.emit(mood)
	print("[GameState] ====== Signal emitted ======")
	_check_win_lose()

func _get_mood_bar(old_mood: int, delta: int) -> String:
	var bar_length = 20
	var filled = int((float(mood) / 100.0) * bar_length)
	var empty = bar_length - filled
	var bar = "[" + "=".repeat(filled) + "-".repeat(empty) + "]"
	var delta_str = ""
	if delta != 0:
		delta_str = " (%s%d)" % ["+" if delta > 0 else "", delta]
	return "%d -> %d %s%s" % [old_mood, mood, bar, delta_str]

func apply_mood_delta(delta: int) -> void:
	set_mood(mood + delta)

func set_flag(flag_name: String, value: bool = true) -> void:
	if flag_name in flags:
		flags[flag_name] = value
		print("[FLAG] %s = %s" % [flag_name, value])
		flag_changed.emit(flag_name, value)

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func apply_intent(intent: String) -> void:
	print("[INTENT] Detected: '%s'" % intent)
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
