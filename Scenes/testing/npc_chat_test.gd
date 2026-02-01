extends Node

# Console-based NPC Chat Test System
# Tests AI conversation without UI - all output goes to console
# Includes mood system and game state flags

signal response_received(text: String)
signal mood_changed(new_mood: int, delta: int)
signal game_won
signal game_lost

# --- Configuration ---
const NPC_NAME = "Olivia"
const STARTING_MOOD = 30
const WIN_MOOD = 100
const LOSE_MOOD = 0

const SYSTEM_PROMPT = """You are Olivia, an angry girlfriend confronting your partner who came home late at 2 AM with 100 missed calls.
You are emotional, sarcastic, and reactive. You respond with realistic human dialogue.
Never mention game mechanics or mood numbers. Stay in character.
Be passive-aggressive but can be won over with sincere apologies, empathy, and kind gestures.
React emotionally to what the player says. If they apologize sincerely, soften slightly. If they lie or gaslight, get angrier.
Keep responses short (1-3 sentences) like real conversation."""

# --- Mood Deltas (game controls these, NOT the LLM) ---
const MOOD_DELTAS = {
	"apology": 10,
	"empathy": 12,
	"explanation": 5,
	"compliment": 8,
	"do_dishes": 10,
	"clean": 10,
	"order_food": 5,
	"give_food": 15,
	"lie": -15,
	"gaslight": -25,
	"insult": -20,
	"nonsense": -10,
	"neutral": 0
}

# --- Flag Bonuses (boost future positive gains) ---
const FLAG_BONUS = {
	"apologized": 0.1,      # +10% to positive gains
	"did_dishes": 0.1,
	"cleaned": 0.1,
	"ordered_food": 0.05,
	"gave_food": 0.15
}

# --- Provider Selection ---
enum ProviderType { MOCK, PLAYER2 }
@export var active_provider: ProviderType = ProviderType.PLAYER2

# --- Game State ---
var mood: int = STARTING_MOOD
var flags: Dictionary = {
	"apologized": false,
	"did_dishes": false,
	"cleaned": false,
	"ordered_food": false,
	"gave_food": false
}

# --- Internal State ---
var conversation_history: Array[Dictionary] = []
var is_waiting_for_response: bool = false
var use_mock: bool = false
var game_over: bool = false

# --- Player2AI Integration ---
@onready var ai_npc: Node = null

func _ready() -> void:
	_setup_ai()
	_print_welcome()

func _setup_ai() -> void:
	match active_provider:
		ProviderType.MOCK:
			print("[SYSTEM] Using MOCK AI provider")
			use_mock = true
		ProviderType.PLAYER2:
			print("[SYSTEM] Attempting Player2 AI connection...")
			ai_npc = _create_player2_npc()
			if ai_npc:
				if ai_npc.has_signal("chat_received"):
					ai_npc.chat_received.connect(_on_ai_response)
				if ai_npc.has_signal("chat_failed"):
					ai_npc.chat_failed.connect(_on_ai_failed)
				print("[SYSTEM] Player2AI connected")
			else:
				print("[SYSTEM] Player2AI not available - using mock responses")
				use_mock = true

	# Initialize conversation with system prompt
	conversation_history.append({
		"role": "system",
		"content": SYSTEM_PROMPT
	})

func _create_player2_npc() -> Node:
	var script_path = "res://addons/player2/nodes/Player2AINPC.gd"
	if not ResourceLoader.exists(script_path):
		return null

	var npc_script = load(script_path)
	if not npc_script:
		return null

	var npc = Node.new()
	npc.set_script(npc_script)
	npc.set("character_name", NPC_NAME)
	npc.set("character_description", SYSTEM_PROMPT)
	npc.set("character_system_message", "Keep responses short and emotional. React to what the player says.")
	npc.set("greet_on_entry", false)
	npc.set("auto_store_conversation_history", false)
	add_child(npc)
	return npc

func _print_welcome() -> void:
	print("")
	print("========================================")
	print("  NPC Chat Test - Console Edition")
	print("  Talking to: %s" % NPC_NAME)
	print("  Starting Mood: %d / %d" % [mood, WIN_MOOD])
	print("----------------------------------------")
	print("  Commands:")
	print("    'quit' or 'exit' - End session")
	print("    'mock' - Switch to mock mode")
	print("    'clear' - Clear history")
	print("    'mood' - Show current mood")
	print("    'flags' - Show current flags")
	print("    'status' - Show full game state")
	print("========================================")
	print("")

# =============================================================================
# GAME STATE INTERFACE
# =============================================================================

## Get current mood value
func get_mood() -> int:
	return mood

## Get current mood as a descriptive string for the LLM
func get_mood_description() -> String:
	if mood >= 80:
		return "happy and forgiving"
	elif mood >= 60:
		return "warming up, less angry"
	elif mood >= 40:
		return "still upset but listening"
	elif mood >= 20:
		return "very angry and hurt"
	else:
		return "furious and about to leave"

## Get all flags
func get_flags() -> Dictionary:
	return flags.duplicate()

## Set a flag (for when player does an action)
func set_flag(flag_name: String, value: bool = true) -> void:
	if flag_name in flags:
		flags[flag_name] = value
		print("[GAME] Flag '%s' set to %s" % [flag_name, value])

## Apply mood change with flag bonuses
func apply_mood_delta(intent: String) -> int:
	if game_over:
		return 0

	var base_delta = MOOD_DELTAS.get(intent, 0)
	var final_delta = base_delta

	# Apply flag bonuses to positive deltas
	if base_delta > 0:
		var bonus_multiplier = 1.0
		for flag_name in FLAG_BONUS:
			if flags.get(flag_name, false):
				bonus_multiplier += FLAG_BONUS[flag_name]
		final_delta = int(base_delta * bonus_multiplier)

	var old_mood = mood
	mood = clampi(mood + final_delta, LOSE_MOOD, WIN_MOOD)

	if final_delta != 0:
		print("[GAME] Mood: %d -> %d (%s%d from '%s')" % [
			old_mood, mood,
			"+" if final_delta > 0 else "",
			final_delta, intent
		])
		mood_changed.emit(mood, final_delta)

	_check_win_lose()
	return final_delta

## Build context dictionary for the LLM
func build_llm_context() -> Dictionary:
	return {
		"mood_score": mood,
		"mood_description": get_mood_description(),
		"flags": get_flags(),
		"flags_summary": _get_flags_summary()
	}

## Get a human-readable summary of active flags
func _get_flags_summary() -> String:
	var active_flags = []
	for flag_name in flags:
		if flags[flag_name]:
			active_flags.append(flag_name.replace("_", " "))

	if active_flags.is_empty():
		return "Player hasn't done anything helpful yet."
	return "Player has: " + ", ".join(active_flags)

func _check_win_lose() -> void:
	if mood >= WIN_MOOD:
		game_over = true
		print("")
		print("========================================")
		print("  YOU WIN! Olivia has forgiven you!")
		print("========================================")
		print("")
		game_won.emit()
	elif mood <= LOSE_MOOD:
		game_over = true
		print("")
		print("========================================")
		print("  GAME OVER. Olivia has had enough.")
		print("========================================")
		print("")
		game_lost.emit()

# =============================================================================
# MESSAGING
# =============================================================================

func send_message(player_text: String) -> void:
	if player_text.strip_edges().is_empty():
		return

	if game_over:
		print("[SYSTEM] Game is over. Type 'clear' to restart.")
		return

	if is_waiting_for_response:
		print("[SYSTEM] Please wait for response...")
		return

	var text = player_text.strip_edges()

	# Check for commands
	match text.to_lower():
		"quit", "exit", "bye":
			print("[SYSTEM] Exiting conversation.")
			get_tree().quit()
			return
		"mock":
			use_mock = true
			print("[SYSTEM] Switched to MOCK mode")
			return
		"clear":
			_reset_game()
			print("[SYSTEM] Game reset.")
			return
		"mood":
			print("[GAME] Current mood: %d / %d (%s)" % [mood, WIN_MOOD, get_mood_description()])
			return
		"flags":
			print("[GAME] Flags: %s" % str(flags))
			return
		"status":
			_print_status()
			return

	# Log player message with mood context
	print("")
	print("[MOOD] %s" % _get_mood_bar())
	print("[PLAYER]: %s" % text)

	# Add to history
	conversation_history.append({
		"role": "user",
		"content": text
	})

	# Get AI response
	is_waiting_for_response = true
	print("[SYSTEM] %s is thinking..." % NPC_NAME)

	if use_mock:
		_get_mock_response(text)
	else:
		_get_ai_response(text)

func _print_status() -> void:
	print("")
	print("--- GAME STATUS ---")
	print("Mood: %d / %d (%s)" % [mood, WIN_MOOD, get_mood_description()])
	print("Flags:")
	for flag_name in flags:
		var status = "YES" if flags[flag_name] else "no"
		print("  - %s: %s" % [flag_name, status])
	print("LLM Context: %s" % str(build_llm_context()))
	print("-------------------")
	print("")

func _reset_game() -> void:
	mood = STARTING_MOOD
	game_over = false
	flags = {
		"apologized": false,
		"did_dishes": false,
		"cleaned": false,
		"ordered_food": false,
		"gave_food": false
	}
	clear_history()

func _get_ai_response(text: String) -> void:
	if ai_npc and ai_npc.has_method("chat"):
		ai_npc.chat(text)
	else:
		print("[SYSTEM] AI not available, falling back to mock")
		_get_mock_response(text)

func _get_mock_response(text: String) -> void:
	# Simulate async delay
	await get_tree().create_timer(0.5).timeout

	var response = _generate_mock_response(text)
	_handle_response(response)

func _generate_mock_response(player_text: String) -> String:
	var text_lower = player_text.to_lower()

	# Mood-aware responses
	if mood >= 60:
		# Warmer responses
		if "sorry" in text_lower:
			return ["I know... I believe you.",
					"Okay... I'm still a little upset but thank you.",
					"*softens* I appreciate that."].pick_random()
		if "love" in text_lower:
			return ["I love you too... but don't do this again.",
					"*small smile* I love you too.",
					"You're lucky I love you."].pick_random()
	elif mood >= 40:
		# Neutral-ish responses
		if "sorry" in text_lower:
			return ["Oh, NOW you're sorry?",
					"Sorry doesn't explain where you were.",
					"*sighs* At least you're apologizing..."].pick_random()
		if "love" in text_lower:
			return ["Don't try to sweet talk me right now.",
					"Love? You have a funny way of showing it.",
					"...I love you too. But I'm still mad."].pick_random()
	else:
		# Angry responses
		if "sorry" in text_lower:
			return ["Sorry isn't going to cut it!",
					"Are you though? ARE YOU?",
					"Don't even start."].pick_random()
		if "love" in text_lower:
			return ["Don't you DARE say that right now.",
					"Love doesn't mean disappearing for hours!",
					"Save it."].pick_random()

	# Context-aware mock responses
	if "work" in text_lower or "late" in text_lower:
		return ["Work until 2 AM? Really?",
				"Your boss called. You left at 6.",
				"Don't lie to me."].pick_random()

	if "?" in player_text:
		return ["Are you seriously asking ME questions right now?",
				"I should be the one asking questions!",
				"Don't change the subject."].pick_random()

	# Default responses based on mood
	if mood < 30:
		return ["I can't even look at you right now.",
				"This is unbelievable.",
				"I'm done. I'm SO done."].pick_random()
	else:
		return ["I can't believe you right now.",
				"Do you even hear yourself?",
				"Just... explain yourself.",
				"I waited for HOURS.",
				"100 missed calls. ONE HUNDRED."].pick_random()

func _on_ai_response(response: String) -> void:
	# Player2AI returns JSON, try to parse it
	var parsed = _parse_ai_response(response)
	_handle_response(parsed)

func _parse_ai_response(response: String) -> String:
	# Player2AI may return JSON with "reply" field
	var json = JSON.parse_string(response)
	if json is Dictionary and json.has("reply"):
		return json["reply"]
	return response

func _on_ai_failed(error_code: int) -> void:
	print("[SYSTEM] AI request failed (code: %d) - using mock response" % error_code)
	var last_player_msg = ""
	for i in range(conversation_history.size() - 1, -1, -1):
		if conversation_history[i]["role"] == "user":
			last_player_msg = conversation_history[i]["content"]
			break
	_get_mock_response(last_player_msg)

func _handle_response(response: String) -> void:
	is_waiting_for_response = false

	# Log NPC response with mood
	print("[NPC - %s]: %s" % [NPC_NAME, response])
	print("[MOOD] %s" % _get_mood_bar())
	print("")

## Generate a visual mood bar for logging
func _get_mood_bar() -> String:
	var bar_length = 20
	var filled = int((float(mood) / WIN_MOOD) * bar_length)
	var empty = bar_length - filled
	var bar = "[" + "=".repeat(filled) + "-".repeat(empty) + "]"
	return "%d/%d %s (%s)" % [mood, WIN_MOOD, bar, get_mood_description()]

	# Add to history
	conversation_history.append({
		"role": "assistant",
		"content": response
	})

	# Emit signal for integration
	response_received.emit(response)

# =============================================================================
# UTILITY
# =============================================================================

func get_conversation_history() -> Array[Dictionary]:
	return conversation_history

func clear_history() -> void:
	conversation_history.clear()
	conversation_history.append({
		"role": "system",
		"content": SYSTEM_PROMPT
	})
