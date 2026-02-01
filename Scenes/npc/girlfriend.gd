extends CharacterBody2D

signal npc_reply(text: String)
signal npc_thinking
signal interaction_requested  # Emitted when player wants to talk
signal mood_updated(mood_name: String, score: int)  # Emitted when mood is analyzed

const SPEED = 40.0

const MOOD_TIER_PROMPTS = {
	0: "You're furious and seriously questioning this relationship. Cold, sharp, and deeply hurt. They betrayed your trust.",
	10: "You're extremely angry. Bitter and sarcastic. They have a LOT to prove. Don't soften easily.",
	20: "You're very upset and hurt. Demanding real action, not just words. Call out excuses and lies.",
	30: "You're angry and defensive. They need to show genuine remorse and effort. Be skeptical.",
	40: "You're hurt but still listening. Their efforts matter but you're not convinced yet. Stay guarded.",
	50: "You're conflicted. Part of you wants to believe them. Show vulnerability but maintain boundaries.",
	60: "You're cautiously softening. If they keep trying sincerely, acknowledge it. Still somewhat reserved.",
	70: "You're warming up slowly. Appreciate their genuine effort. Show you want to reconnect.",
	80: "You're feeling better. The fight is resolving. Be more affectionate but remember what happened.",
	90: "You feel loved again. Warm and affectionate. The hurt is fading.",
	100: "You're happy and the fight is behind you. Loving and playful. Trust is rebuilding."
}

var _last_mood_tier: int = -1
var _interaction_history: Array = []  # Track last interactions for mood analysis
const MAX_HISTORY: int = 2  # Keep last 2 interactions
var _pending_response: String = ""  # Store response while waiting for mood analysis
var _waiting_for_mood: bool = false  # Flag to track if we're waiting
var _current_mood: String = "Furious"  # Track current mood for context

# WINNING SENTENCES - Say these 4 in sequence to instantly win!
const WINNING_SENTENCES = [
	"I'm so sorry I made you worry, that was completely my fault",
	"You deserve so much better than how I treated you today",
	"I promise I'll always call you first if something comes up",
	"You're the most important person in my life and I love you"
]
var _winning_sequence_progress: int = 0  # Tracks which sentence user is on (0-3)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var ai_npc: Node = $Player2AINPC
@onready var mood_analyzer: Node = $MoodAnalyzer

func _ready() -> void:
	# Set motion mode to floating so girlfriend doesn't get pushed by player
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	if ai_npc and ai_npc.has_signal("chat_received"):
		ai_npc.chat_received.connect(_on_chat_received)
	
	# Connect mood analyzer
	if mood_analyzer:
		if mood_analyzer.has_signal("mood_analyzed"):
			mood_analyzer.mood_analyzed.connect(_on_mood_analyzed)
		if mood_analyzer.has_signal("analysis_failed"):
			mood_analyzer.analysis_failed.connect(_on_mood_analysis_failed)

func _physics_process(_delta: float) -> void:
	# Movement disabled for now
	velocity = Vector2.ZERO
	move_and_slide()

func interact() -> void:
	# Called when player interacts with girlfriend
	# Emit signal to trigger dialogue
	print("[Girlfriend] interact() called")
	interaction_requested.emit()
	print("[Girlfriend] interaction_requested signal emitted")

func receive_player_message(text: String) -> void:
	print("\n[Girlfriend] 💬 Player said: ", text)
	print("[Girlfriend] 🎯 Current winning sequence progress: ", _winning_sequence_progress, "/4")
	
	# Check for winning sentence sequence FIRST - GUARANTEED WIN!
	var normalized_input = text.to_lower().strip_edges()
	print("[Girlfriend] 🔍 Normalized input: '", normalized_input, "'")
	if _check_winning_sentence(normalized_input):
		print("[Girlfriend] 🏆 WINNING SENTENCE DETECTED! Sequence: ", _winning_sequence_progress, "/4")
		if _winning_sequence_progress >= 4:
			print("╔══════════════════════════════════════════════════════════╗")
			print("║  🎉🎉🎉 ALL 4 WINNING SENTENCES! INSTANT WIN! 🎉🎉🎉  ║")
			print("║          YOU CONQUERED THE CHALLENGE!                  ║")
			print("╚══════════════════════════════════════════════════════════╝")
			# Update mood to 100 and Happy immediately - NO CHATGPT INVOLVED
			GameState.set_mood(100)  # Use set_mood to trigger win condition
			_current_mood = "Happy"
			# Emit winning response - bypassing all other logic
			var win_response = "I love you too! I'm so glad we talked. You're amazing. ❤️"
			npc_reply.emit(win_response)
			mood_updated.emit("Happy", 100)
			print("[Girlfriend] ✅ Win condition triggered! Mood = 100, State = Happy")
			return  # EXIT IMMEDIATELY - No further processing!
	else:
		# Reset sequence if they say something else
		if _winning_sequence_progress > 0:
			print("[Girlfriend] ⚠️ Winning sequence broken. Progress reset to 0.")
			_winning_sequence_progress = 0
	
	# REMOVED: Don't classify intent or update mood here anymore
	# The mood will be updated AFTER the girlfriend responds via mood analyzer
	# var intent = IntentClassifier.classify(text)
	# GameState.apply_intent(intent)

	# Call Player2AINPC.chat(text) for LLM response
	npc_thinking.emit()
	if ai_npc:
		# Inject world status via notify (as stimuli) before the chat
		# This ensures the LLM sees the current game state
		if ai_npc.has_method("notify"):
			var world_status = _build_world_status()
			ai_npc.notify(world_status, true)  # silent = true, don't trigger response

		if ai_npc.has_method("chat"):
			ai_npc.chat(text)
	else:
		# Fallback for testing without Player2
		_on_chat_received("I'm still mad at you!")

func _on_chat_received(response: String) -> void:
	# Parse the actual dialogue text
	var dialogue_text = _parse_dialogue(response)
	
	print("\n[Girlfriend] 💬 Response received: ", dialogue_text)
	print("[Girlfriend] Waiting for mood analysis before displaying...")
	
	# Store response temporarily - don't emit yet
	_pending_response = response
	_waiting_for_mood = true
	
	# Analyze mood using ChatGPT (thinking indicator already shown earlier)
	if mood_analyzer and mood_analyzer.has_method("analyze_dialogue"):
		print("[Girlfriend] Triggering mood analysis...")
		# Get current score from GameState
		var current_score = GameState.mood if GameState else 50
		mood_analyzer.analyze_dialogue(dialogue_text, current_score, _interaction_history, _current_mood)
	else:
		print("[Girlfriend] ⚠️ Warning: MoodAnalyzer not found or method missing")
		# If no analyzer, emit response immediately
		_waiting_for_mood = false
		npc_reply.emit(response)

func _parse_dialogue(response: String) -> String:
	"""Extract clean dialogue text from response"""
	var json = JSON.parse_string(response)
	if json is Dictionary and json.has("reply"):
		return json["reply"]
	return response

func _on_mood_analyzed(mood_data: Dictionary) -> void:
	print("\n[Girlfriend] 🎯 MOOD ANALYSIS RECEIVED:")
	print("[Girlfriend] Full data: ", mood_data)
	if mood_data.has("mood") and mood_data.has("score"):
		var mood_name: String = mood_data["mood"]
		var score: int = int(mood_data["score"])
		
		# Update GameState with the new mood score
		GameState.set_mood(score)
		
		# Update current mood for next analysis
		_current_mood = mood_name
		
		# Track interaction history
		if mood_data.has("interaction_type"):
			_interaction_history.append({"type": mood_data["interaction_type"]})
			if _interaction_history.size() > MAX_HISTORY:
				_interaction_history.pop_front()
		
		print("[Girlfriend] Emitting mood_updated signal...")
		print("[Girlfriend]   Mood: ", mood_name)
		print("[Girlfriend]   Score: ", score)
		mood_updated.emit(mood_name, score)
		
		# Now emit the NPC response that was waiting
		if _waiting_for_mood and not _pending_response.is_empty():
			print("[Girlfriend] 📤 Now displaying NPC response (synchronized with mood)")
			npc_reply.emit(_pending_response)
			_pending_response = ""
			_waiting_for_mood = false
		
		print("[Girlfriend] ✅ Signal emitted successfully\n")

func _on_mood_analysis_failed(error: String) -> void:
	print("\n[Girlfriend] ❌ MOOD ANALYSIS FAILED:")
	print("[Girlfriend] Error: ", error)
	print("[Girlfriend] Check your API key and internet connection\n")
	push_warning("[Girlfriend] Mood analysis failed: ", error)
	
	# Still emit the NPC response even if mood analysis failed
	if _waiting_for_mood and not _pending_response.is_empty():
		print("[Girlfriend] 📤 Displaying NPC response anyway (mood analysis failed)")
		npc_reply.emit(_pending_response)
		_pending_response = ""
		_waiting_for_mood = false

# =============================================================================
# MOOD-AWARE SYSTEM
# =============================================================================

## Get the mood tier (0-20) from mood value (0-100)
func _get_mood_tier(mood: int) -> int:
	return clampi(int(mood / 5.0), 0, 20)

## Update the system prompt if we've crossed into a new mood tier
func _update_system_prompt_for_mood(mood: int) -> void:
	var tier = _get_mood_tier(mood)

	if tier == _last_mood_tier:
		return  # No change needed

	_last_mood_tier = tier

	if not ai_npc:
		return

	# Build the new system message
	var base_behavior = MOOD_TIER_PROMPTS.get(tier, MOOD_TIER_PROMPTS[10])
	var flags_context = _get_flags_context()

	var new_system_message = base_behavior
	if not flags_context.is_empty():
		new_system_message += "\n\n" + flags_context

	# Update Player2AINPC's system message
	if "character_system_message" in ai_npc:
		ai_npc.character_system_message = new_system_message
		print("[Girlfriend] Updated to mood tier %d (mood: %d)" % [tier, mood])
		print("[Girlfriend] New prompt: %s" % new_system_message.substr(0, 100) + "...")

## Build world status string for the LLM
func _build_world_status() -> String:
	var mood = GameState.mood

	var parts = []

	# Mood description (without numbers)
	parts.append("Your current emotional state: " + _get_mood_description(mood))

	# Flags context
	var flags_status = _get_flags_status()
	if not flags_status.is_empty():
		parts.append(flags_status)

	return " | ".join(parts)

## Get a descriptive mood string (no numbers exposed to LLM)
func _get_mood_description(mood: int) -> String:
	if mood >= 90:
		return "You feel completely loved and appreciated. Pure happiness."
	elif mood >= 80:
		return "You're very happy. The fight is resolved and you feel close to them."
	elif mood >= 70:
		return "You're warming up and starting to forgive."
	elif mood >= 60:
		return "You're calming down. Still a bit hurt but listening."
	elif mood >= 50:
		return "You're conflicted - hurt but starting to soften."
	elif mood >= 40:
		return "You're upset but at least engaging with them."
	elif mood >= 30:
		return "You're angry and hurt, demanding real effort."
	elif mood >= 20:
		return "You're very angry. Sharp and defensive."
	elif mood >= 10:
		return "You're furious. Close to walking out."
	else:
		return "You've had enough. You're done with this conversation."

## Get context string about completed actions
func _get_flags_context() -> String:
	var parts = []

	if GameState.get_flag("apologized"):
		parts.append("They have apologized to you - acknowledge this if relevant.")
	if GameState.get_flag("did_dishes"):
		parts.append("They did the dishes for you - this kind gesture meant something.")
	if GameState.get_flag("cleaned"):
		parts.append("They cleaned up - they're trying to make things right.")
	if GameState.get_flag("ordered_food"):
		parts.append("They ordered food for you - a peace offering.")
	if GameState.get_flag("gave_food"):
		parts.append("They gave you food - comfort food helps.")

	if parts.is_empty():
		return ""
	return "Remember: " + " ".join(parts)

## Get status string about flags for world_status
func _get_flags_status() -> String:
	var completed = []

	if GameState.get_flag("apologized"):
		completed.append("received an apology")
	if GameState.get_flag("did_dishes"):
		completed.append("they did the dishes")
	if GameState.get_flag("cleaned"):
		completed.append("they cleaned up")
	if GameState.get_flag("gave_food"):
		completed.append("they gave you food")

	if completed.is_empty():
		return "They haven't done anything helpful yet."
	return "So far: " + ", ".join(completed)

func _check_winning_sentence(normalized_input: String) -> bool:
	"""Check if player input matches the next winning sentence in sequence"""
	if _winning_sequence_progress >= WINNING_SENTENCES.size():
		return false
	
	print("[Girlfriend] 🔍 Checking for sentence #", _winning_sequence_progress + 1, " of 4")
	var expected_sentence = WINNING_SENTENCES[_winning_sequence_progress].to_lower().strip_edges()
	
	# Check for exact match
	if normalized_input == expected_sentence:
		print("[Girlfriend] ✅ EXACT MATCH for sentence ", _winning_sequence_progress + 1, "!")
		_winning_sequence_progress += 1
		return true
	
	# Check if it contains the key phrases (fuzzy match)
	var key_phrases = [
		["sorry", "made you worry", "my fault"],  # Sentence 1
		["deserve", "better", "treated you"],  # Sentence 2
		["promise", "call you", "comes up"],  # Sentence 3
		["most important", "life", "love you"]  # Sentence 4
	]
	
	if _winning_sequence_progress < key_phrases.size():
		var required_phrases = key_phrases[_winning_sequence_progress]
		var matches = 0
		print("[Girlfriend] 🔎 Looking for key phrases: ", required_phrases)
		for phrase in required_phrases:
			if normalized_input.contains(phrase):
				matches += 1
				print("[Girlfriend]   ✓ Found: '", phrase, "'")
			else:
				print("[Girlfriend]   ✗ Missing: '", phrase, "'")
		
		print("[Girlfriend] 📊 Matches: ", matches, "/", required_phrases.size())
		# If at least 2 out of 3 key phrases match, count it
		if matches >= 2:
			print("[Girlfriend] ✅ FUZZY MATCH for sentence ", _winning_sequence_progress + 1, "! (", matches, "/3 key phrases)")
			_winning_sequence_progress += 1
			return true
	
	print("[Girlfriend] ❌ No match for sentence ", _winning_sequence_progress + 1)
	return false
