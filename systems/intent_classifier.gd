class_name IntentClassifier

# Pure static class for intent classification
# No scene, no state

static func classify(text: String) -> String:
	var lower_text = text.to_lower()

	# Apology keywords
	if _contains_any(lower_text, ["sorry", "apologize", "my bad", "forgive", "didn't mean"]):
		return "apology"

	# Insult keywords
	if _contains_any(lower_text, ["stupid", "idiot", "shut up", "whatever", "don't care"]):
		return "insult"

	# Positive/helpful keywords
	if _contains_any(lower_text, ["love", "beautiful", "care", "help", "understand"]):
		return "apology"  # Treat positive as mood boost

	# Default
	return "nonsense"

static func _contains_any(text: String, keywords: Array) -> bool:
	for keyword in keywords:
		if keyword in text:
			return true
	return false
