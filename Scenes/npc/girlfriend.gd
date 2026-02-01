extends Node2D

# Brain script for the girlfriend NPC
# Runs the dialogue loop with Player2AINPC
# Implements mood-aware responses via world_status and dynamic system prompts

signal npc_reply(text: String)
signal npc_thinking
signal interaction_requested  # Emitted when player wants to talk

@onready var ai_npc: Node = $Player2AINPC

# Track last mood tier to know when to update system prompt
var _last_mood_tier: int = -1

# =============================================================================
# MOOD TIER SYSTEM PROMPTS (every 5 points = new tier, 0-100 = 21 tiers)
# =============================================================================

const MOOD_TIER_PROMPTS = {
	# 0-4: Furious, about to leave
	0: "You are FURIOUS. You've had enough. You're about to walk out the door. Your voice is cold and final. Nothing they say matters anymore unless it's truly sincere. You're done.",

	# 5-9: Extremely angry
	1: "You are extremely angry and deeply hurt. You can barely look at them. Your responses are sharp, cutting, and dismissive. You're close to giving up on this conversation.",

	# 10-14: Very angry
	2: "You are very angry. Your voice is raised. You're demanding answers and not accepting excuses. Every word drips with frustration and betrayal.",

	# 15-19: Angry and hurt
	3: "You are angry and hurt. You're venting your frustrations. You want them to understand how much they hurt you. Sarcasm is your shield.",

	# 20-24: Upset and defensive
	4: "You are upset and defensive. You're still mad but you're at least engaging. You're testing them to see if they actually care.",

	# 25-29: Frustrated but listening
	5: "You are frustrated but willing to listen. You're giving them a chance to explain, but you're skeptical. You need to hear something real.",

	# 30-34: Guarded
	6: "You are guarded but present. You're hurt and wary, but you haven't shut down completely. You want them to try harder.",

	# 35-39: Cautiously engaged
	7: "You are cautiously engaged. You're listening more than attacking now. Small gestures are starting to register, but you're not ready to forgive.",

	# 40-44: Thawing slightly
	8: "You are starting to thaw slightly. The anger is fading into hurt. You're more sad than mad now. Genuine effort is beginning to matter.",

	# 45-49: Conflicted
	9: "You are conflicted. Part of you wants to stay mad, part of you misses them. You're sighing more than yelling. Real apologies hit differently now.",

	# 50-54: Softening
	10: "You are softening. The wall is coming down a little. You're still hurt but you're starting to believe they care. Small smiles might slip through.",

	# 55-59: Warming up
	11: "You are warming up. You're letting your guard down. You might even laugh a little, then catch yourself. Kindness is reaching you.",

	# 60-64: Mostly calm
	12: "You are mostly calm now. The storm has passed. You're having a real conversation. You appreciate the effort they've made.",

	# 65-69: Reconnecting
	13: "You are reconnecting with them. The hurt is fading. You're remembering why you love them. Affection is creeping back into your voice.",

	# 70-74: Forgiving
	14: "You are forgiving. You've decided to let it go. You want to move past this. Your voice is warm, maybe a little tired but relieved.",

	# 75-79: Affectionate
	15: "You are feeling affectionate. The fight is behind you. You're ready to be close again. Maybe even a little clingy now that the tension broke.",

	# 80-84: Happy
	16: "You are happy. You feel loved and appreciated. The effort they made means everything. You're smiling and your voice is light.",

	# 85-89: Very happy
	17: "You are very happy. You feel cherished. All the anger has transformed into appreciation. You might get a little emotional about how much they care.",

	# 90-94: Overjoyed
	18: "You are overjoyed. You feel deeply connected. This fight brought you closer somehow. You're laughing and affectionate.",

	# 95-99: Completely won over
	19: "You are completely won over. Your heart is full. You feel incredibly loved. You might tear up from happiness. This is what you needed.",

	# 100: Perfect - victory state
	20: "You are blissfully happy. All is forgiven and forgotten. You feel closer than ever. Pure love and gratitude in your voice."
}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	if ai_npc and ai_npc.has_signal("chat_received"):
		ai_npc.chat_received.connect(_on_chat_received)

	# Initialize system prompt based on starting mood
	_update_system_prompt_for_mood(GameState.mood)

# =============================================================================
# INTERACTION
# =============================================================================

# Called when player interacts (clicks/presses interact key near Penny)
func interact() -> void:
	interaction_requested.emit()

# Reset conversation history to start fresh
func reset_conversation() -> void:
	if ai_npc and ai_npc.has_method("clear_conversation_history"):
		ai_npc.clear_conversation_history()
	_last_mood_tier = -1  # Force prompt update on next message
	_update_system_prompt_for_mood(GameState.mood)

# =============================================================================
# MESSAGING
# =============================================================================

func receive_player_message(text: String) -> void:
	# 1. Classify intent
	var intent = IntentClassifier.classify(text)

	# 2. Apply mood delta via GameState
	GameState.apply_intent(intent)

	# 3. Update system prompt if mood tier changed
	_update_system_prompt_for_mood(GameState.mood)

	# 4. Build world status with current mood and flags
	var world_status = _build_world_status()

	# 5. Call Player2AINPC with world status context
	npc_thinking.emit()
	if ai_npc:
		# Inject world status via notify (as stimuli) before the chat
		# This ensures the LLM sees the current game state
		if ai_npc.has_method("notify"):
			ai_npc.notify(world_status, true)  # silent = true, don't trigger response

		if ai_npc.has_method("chat"):
			ai_npc.chat(text)
	else:
		# Fallback for testing without Player2
		_on_chat_received("I'm still mad at you!")

func _on_chat_received(response: String) -> void:
	print("[Girlfriend] Received response: ", response)
	# Emit reply for UI
	npc_reply.emit(response)

# =============================================================================
# MOOD-AWARE SYSTEM
# =============================================================================

## Get the mood tier (0-20) from mood value (0-100)
func _get_mood_tier(mood: int) -> int:
	return clampi(mood / 5, 0, 20)

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
	var tier = _get_mood_tier(mood)

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
