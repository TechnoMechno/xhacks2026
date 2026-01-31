class_name IntentClassifier

# Pure static class for intent classification
# No scene, no state

static func classify(text: String) -> String:
	var lower_text = text.to_lower()

	# Gaslight keywords - manipulative or dismissive
	if _contains_any(lower_text, ["overreacting", "crazy", "imagining", "dramatic", "sensitive", "not a big deal", "you're making this up"]):
		return "gaslight"

	# Insult keywords
	if _contains_any(lower_text, ["stupid", "idiot", "shut up", "pathetic", "annoying", "ridiculous"]):
		return "insult"

	# Lie keywords - deflecting or avoiding truth
	if _contains_any(lower_text, ["wasn't me", "didn't do", "never said", "you're wrong", "not my fault", "whatever"]):
		return "lie"

	# Apology keywords - genuine remorse
	if _contains_any(lower_text, ["sorry", "apologize", "my bad", "forgive me", "i was wrong", "i messed up"]):
		return "apology"

	# Empathy keywords - understanding and caring
	if _contains_any(lower_text, ["understand how you feel", "must be hard", "i hear you", "you're right", "that makes sense", "i see why"]):
		return "empathy"

	# Explanation keywords - genuine attempt to communicate
	if _contains_any(lower_text, ["because", "the reason", "let me explain", "what happened was", "i thought", "didn't realize"]):
		return "explanation"

	# Default - nonsense or unclear
	return "nonsense"

static func _contains_any(text: String, keywords: Array) -> bool:
	for keyword in keywords:
		if keyword in text:
			return true
	return false
