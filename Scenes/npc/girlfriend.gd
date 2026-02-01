extends CharacterBody2D

signal npc_reply(text: String)
signal npc_thinking
signal interaction_requested  # Emitted when player wants to talk

const SPEED = 40.0

const MOOD_TIER_PROMPTS = {
	0: "You're furious and done. You're considering ending this relationship. Sharp, cold responses only.",
	10: "You're extremely angry. Sarcastic and harsh. They need to prove they care.",
	20: "You're very upset. Demanding real effort and sincerity. No excuses accepted.",
	30: "You're angry but listening. They need to show genuine remorse and action.",
	40: "You're hurt but engaging. Starting to calm down if they keep trying.",
	50: "You're conflicted. Part of you wants to forgive, part is still hurt.",
	60: "You're calming down. Their efforts are working. Still cautious.",
	70: "You're warming up. You appreciate their effort and feel hopeful.",
	80: "You're happy. The fight is mostly resolved. Feeling reconnected.",
	90: "You feel loved and appreciated. Warm, affectionate responses.",
	100: "Pure happiness. You're completely over the fight and feel closer than ever."
}

var _last_mood_tier: int = -1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var ai_npc: Node = $Player2AINPC

func _ready() -> void:
	if ai_npc and ai_npc.has_signal("chat_received"):
		ai_npc.chat_received.connect(_on_chat_received)

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
	# Classify intent
	var intent = IntentClassifier.classify(text)

	# Apply mood delta via GameState
	GameState.apply_intent(intent)

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
	# Emit reply for UI
	npc_reply.emit(response)

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
