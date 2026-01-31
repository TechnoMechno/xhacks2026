extends Node

# Console-based NPC Chat Test System
# Tests AI conversation without UI - all output goes to console
# Can be integrated into the real game later

signal response_received(text: String)

# --- Configuration ---
const NPC_NAME = "Penny"
const SYSTEM_PROMPT = """You are Penny, an angry girlfriend confronting your partner who came home late at 2 AM with 100 missed calls.
You are emotional, sarcastic, and reactive. You respond with realistic human dialogue.
Never mention game mechanics or mood numbers. Stay in character.
Be passive-aggressive but can be won over with sincere apologies, empathy, and kind gestures.
React emotionally to what the player says. If they apologize sincerely, soften slightly. If they lie or gaslight, get angrier.
Keep responses short (1-3 sentences) like real conversation."""

# --- Provider Selection ---
enum ProviderType { MOCK, PLAYER2 }
@export var active_provider: ProviderType = ProviderType.PLAYER2

# --- State ---
var conversation_history: Array[Dictionary] = []
var is_waiting_for_response: bool = false
var use_mock: bool = false

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
	print("  Type 'quit' or 'exit' to end")
	print("  Type 'mock' to switch to mock mode")
	print("  Type 'clear' to clear history")
	print("========================================")
	print("")

# --- Public API (for integration) ---

func send_message(player_text: String) -> void:
	if player_text.strip_edges().is_empty():
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
			clear_history()
			print("[SYSTEM] Conversation history cleared.")
			return

	# Log player message
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

	# Context-aware mock responses
	if "sorry" in text_lower or "apologize" in text_lower:
		return ["Oh, NOW you're sorry?",
				"Sorry doesn't explain where you were.",
				"*sighs* At least you're apologizing..."].pick_random()

	if "love" in text_lower:
		return ["Don't try to sweet talk me right now.",
				"Love? You have a funny way of showing it.",
				"...I love you too. But I'm still mad."].pick_random()

	if "work" in text_lower or "late" in text_lower:
		return ["Work until 2 AM? Really?",
				"Your boss called. You left at 6.",
				"Don't lie to me."].pick_random()

	if "?" in player_text:
		return ["Are you seriously asking ME questions right now?",
				"I should be the one asking questions!",
				"Don't change the subject."].pick_random()

	# Default responses
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

	# Log NPC response
	print("[NPC - %s]: %s" % [NPC_NAME, response])
	print("")

	# Add to history
	conversation_history.append({
		"role": "assistant",
		"content": response
	})

	# Emit signal for integration
	response_received.emit(response)

# --- Utility ---

func get_conversation_history() -> Array[Dictionary]:
	return conversation_history

func clear_history() -> void:
	conversation_history.clear()
	conversation_history.append({
		"role": "system",
		"content": SYSTEM_PROMPT
	})
