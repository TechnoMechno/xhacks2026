extends AIProvider
class_name AIProviderMock

# Mock AI provider for testing without API
# Returns contextual responses based on keywords

var _parent_node: Node = null

func _init(prompt: String = "", parent: Node = null) -> void:
	super._init(prompt)
	_parent_node = parent

func send_message(text: String) -> void:
	conversation_history.append({"role": "user", "content": text})

	# Simulate async delay
	if _parent_node:
		await _parent_node.get_tree().create_timer(0.3).timeout

	var response = _generate_response(text)
	_handle_response(response)

func _generate_response(player_text: String) -> String:
	var text_lower = player_text.to_lower()

	# Apology responses
	if "sorry" in text_lower or "apologize" in text_lower or "my bad" in text_lower:
		return [
			"Oh, NOW you're sorry?",
			"Sorry doesn't explain where you were.",
			"*sighs* At least you're apologizing...",
			"Words are cheap. What are you going to DO about it?"
		].pick_random()

	# Empathy responses
	if "understand" in text_lower or "i know" in text_lower or "you're right" in text_lower:
		return [
			"Do you though? Do you really understand?",
			"...okay. At least you're trying.",
			"That's... actually nice to hear."
		].pick_random()

	# Love/affection
	if "love" in text_lower:
		return [
			"Don't try to sweet talk me right now.",
			"Love? You have a funny way of showing it.",
			"...I love you too. But I'm still mad."
		].pick_random()

	# Excuses about work/being late
	if "work" in text_lower or "boss" in text_lower or "meeting" in text_lower:
		return [
			"Work until 2 AM? Really?",
			"Your boss doesn't make you stay that late.",
			"I called your office. They said you left hours ago."
		].pick_random()

	# Lying/gaslighting detection
	if "didn't" in text_lower or "never" in text_lower or "wasn't" in text_lower:
		return [
			"Don't lie to me. I'm not stupid.",
			"I have EYES. I can see what's happening.",
			"Are you seriously gaslighting me right now?"
		].pick_random()

	# Questions back at her
	if "?" in player_text:
		return [
			"Are you seriously asking ME questions right now?",
			"I should be the one asking questions here!",
			"Don't try to change the subject."
		].pick_random()

	# Insults
	if "stupid" in text_lower or "crazy" in text_lower or "overreacting" in text_lower:
		return [
			"Excuse me?! Did you just call me that?",
			"WOW. Just... wow.",
			"You're making this SO much worse right now."
		].pick_random()

	# Default frustrated responses
	return [
		"I can't believe you right now.",
		"Do you even hear yourself?",
		"Just... explain yourself. Please.",
		"I waited for HOURS, you know.",
		"100 missed calls. ONE HUNDRED.",
		"I was worried SICK about you!",
		"This isn't okay."
	].pick_random()
