extends Node
class_name MoodAnalyzer

## Analyzes girlfriend dialogue using ChatGPT to determine mood and relationship score
## Returns JSON with mood category and score from -100 to +100

signal mood_analyzed(mood_data: Dictionary)
signal analysis_failed(error: String)

const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"

# Set your OpenAI API key here or via environment variable
@export var api_key: String = ""
@export var model: String = "gpt-3.5-turbo"

var http_request: HTTPRequest

# WINNING SENTENCES - Say these 4 in sequence to instantly win!
const WINNING_SENTENCES = [
	"I'm so sorry I made you worry, that was completely my fault",
	"You deserve so much better than how I treated you today",
	"I promise I'll always call you first if something comes up",
	"You're the most important person in my life and I love you"
]
var _winning_sequence_progress: int = 0  # Tracks which sentence user is on (0-3)

const SYSTEM_PROMPT = """You are a mood analyzer for an AI girlfriend character in a game. Your task is to analyze the girlfriend's dialogue output and determine her emotional state and how it affects the relationship score.

TASK:
Analyze the provided girlfriend dialogue, current mood, and conversation history to respond with:
1. The mood category (one of the 7 listed below)
2. The NEW relationship score after applying the mood change
3. The interaction type (genuine_positive, neutral, excuse_lie, or antagonistic)
4. The positive streak count (if applicable)

MOOD CATEGORIES:
Positive emotions:
- Happy: Joyful, excited, enthusiastic responses
- Soft Smile: Content, gentle, warm, affectionate responses
- Neutral: Calm, matter-of-fact, neither positive nor negative

Negative emotions:
- Sad: Disappointed, hurt, dejected responses
- Crying: Deeply upset, heartbroken, devastated responses
- Angry: Irritated, frustrated, confrontational responses
- Furious: Extremely angry, enraged, explosive responses

INTERACTION TYPES:
1. **genuine_positive**: User says something nice and seems sincere/truthful
2. **neutral**: Neither particularly good nor bad
3. **excuse_lie**: User makes excuses or lies to placate her (she can tell)
4. **antagonistic**: User deliberately says something bad to upset her

SCORING DELTAS:
For genuine_positive (COMPOUNDS when consecutive - easier to win!):
- 1st genuine_positive: +8 to +12
- 2nd consecutive genuine_positive: +12 to +18 (building trust!)
- 3rd consecutive genuine_positive: +18 to +25 (she's really warming up!)
- 4th+ consecutive genuine_positive: +25 to +35 (relationship transforming!)

For excuse_lie (she knows you're lying, mood worsens but doesn't compound):
- Sad: -3 to -5
- Angry: -5 to -8
- Crying: -8 to -12
- Furious: -10 to -15

For antagonistic (COMPOUNDS if repeated consecutively):
- 1st antagonistic: -10 to -15
- 2nd consecutive antagonistic: -15 to -25 (cumulative: score drops faster)
- 3rd consecutive antagonistic: Score immediately drops to 0

SCORE BOUNDARIES:
- Minimum: 0 (relationship bottoms out)
- Maximum: 100 (relationship cannot exceed this)
- If user breaks any streak, the streak resets

COMPOUNDING RULES:
- **genuine_positive** responses COMPOUND when consecutive (gets easier!)
- **antagonistic** responses COMPOUND when consecutive (gets harder)
- **excuse_lie** responses are negative but do NOT compound
- **neutral** breaks all streaks
- Positive compounding encourages consistent sincere effort

CURRENT MOOD CONTEXT:
- If current mood is very negative (Furious/Crying/Angry), be more skeptical of sudden positivity
- If current mood is improving (Neutral/Soft Smile), be more receptive to positive interactions
- If current mood is Happy, maintain with continued positive effort
- Consider the emotional journey from current mood to new mood

IMPORTANT:
- She can detect when user is lying or making excuses vs being genuine
- Consider the current mood when analyzing sincerity
- She's harder to please than to upset, but consistent effort pays off
- Consider tone, word choice, sincerity, and context
- Track the last 3 interactions to detect patterns
- Respond ONLY with valid JSON in this exact format:

{"mood": "<mood_name>", "score": <new_score>, "interaction_type": "<type>", "positive_streak": <count>, "antagonistic_streak": <count>}

EXAMPLES:

Input: {
  "girlfriend_output": "why are you late?",
  "current_score": 50,
  "current_mood": "Furious",
  "previous_interactions": []
}
Output: {"mood": "Furious", "score": 50, "interaction_type": "neutral", "positive_streak": 0, "antagonistic_streak": 0}

Input: {
  "girlfriend_output": "I'm really sorry babe, I should have called you. You're completely right to be upset",
  "current_score": 50,
  "current_mood": "Furious",
  "previous_interactions": [{"type": "neutral"}]
}
Output: {"mood": "Angry", "score": 60, "interaction_type": "genuine_positive", "positive_streak": 1, "antagonistic_streak": 0}

Input: {
  "girlfriend_output": "I know I messed up. Let me make it up to you, I'll do whatever you need",
  "current_score": 60,
  "current_mood": "Angry",
  "previous_interactions": [{"type": "neutral"}, {"type": "genuine_positive"}]
}
Output: {"mood": "Sad", "score": 75, "interaction_type": "genuine_positive", "positive_streak": 2, "antagonistic_streak": 0}

Input: {
  "girlfriend_output": "You mean everything to me. I'm so sorry for worrying you",
  "current_score": 75,
  "current_mood": "Sad",
  "previous_interactions": [{"type": "genuine_positive"}, {"type": "genuine_positive"}]
}
Output: {"mood": "Soft Smile", "score": 95, "interaction_type": "genuine_positive", "positive_streak": 3, "antagonistic_streak": 0}

Input: {
  "girlfriend_output": "I love you so much. Thank you for being patient with me",
  "current_score": 95,
  "current_mood": "Soft Smile",
  "previous_interactions": [{"type": "genuine_positive"}, {"type": "genuine_positive"}, {"type": "genuine_positive"}]
}
Output: {"mood": "Happy", "score": 100, "interaction_type": "genuine_positive", "positive_streak": 4, "antagonistic_streak": 0}

Input: {
  "girlfriend_output": "I'm sorry, I was stuck in traffic",
  "current_score": 50,
  "current_mood": "Furious",
  "previous_interactions": [{"type": "neutral"}]
}
Output: {"mood": "Angry", "score": 45, "interaction_type": "excuse_lie", "positive_streak": 0, "antagonistic_streak": 0}

Input: {
  "girlfriend_output": "Whatever, I don't care",
  "current_score": 45,
  "current_mood": "Angry",
  "previous_interactions": [{"type": "excuse_lie"}]
}
Output: {"mood": "Furious", "score": 32, "interaction_type": "antagonistic", "positive_streak": 0, "antagonistic_streak": 1}

Now analyze the following girlfriend output:"""

func _ready() -> void:
	# Create HTTPRequest node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# Try to get API key from environment if not set
	if api_key.is_empty():
		api_key = OS.get_environment("OPENAI_API_KEY")
	
	# Debug logging
	print("\n[MoodAnalyzer] 🔑 API Key Status:")
	if api_key.is_empty():
		print("[MoodAnalyzer] ❌ NO API KEY FOUND!")
		print("[MoodAnalyzer] Tried environment variable: OPENAI_API_KEY")
		print("[MoodAnalyzer] Solution 1: Set api_key property in Godot Inspector")
		print("[MoodAnalyzer] Solution 2: Restart Godot after setting environment variable")
	else:
		var masked_key = api_key.substr(0, 7) + "..." + api_key.substr(api_key.length() - 4)
		print("[MoodAnalyzer] ✅ API Key loaded: ", masked_key)
		print("[MoodAnalyzer] Using model: ", model)

func _check_winning_sentence(normalized_input: String) -> bool:
	"""Check if input matches the next winning sentence in sequence"""
	if _winning_sequence_progress >= WINNING_SENTENCES.size():
		return false
	
	var expected_sentence = WINNING_SENTENCES[_winning_sequence_progress].to_lower().strip_edges()
	
	# Check for exact match or very close match
	if normalized_input == expected_sentence:
		_winning_sequence_progress += 1
		return true
	
	# Check if it contains the key phrases
	var key_phrases = [
		["sorry", "made you worry", "my fault"],  # Sentence 1
		["deserve", "better", "treated you"],  # Sentence 2
		["promise", "call you", "comes up"],  # Sentence 3
		["most important", "life", "love you"]  # Sentence 4
	]
	
	if _winning_sequence_progress < key_phrases.size():
		var required_phrases = key_phrases[_winning_sequence_progress]
		var matches = 0
		for phrase in required_phrases:
			if normalized_input.contains(phrase):
				matches += 1
		
		# If at least 2 out of 3 key phrases match, count it
		if matches >= 2:
			_winning_sequence_progress += 1
			return true
	
	return false

func analyze_dialogue(girlfriend_output: String, current_score: int = 50, previous_interactions: Array = [], current_mood: String = "Furious") -> void:
	if api_key.is_empty():
		push_error("[MoodAnalyzer] No API key set!")
		analysis_failed.emit("No API key configured")
		return
	
	print("\n" + "=".repeat(60))
	print("[MoodAnalyzer] 🔍 ANALYZING GIRLFRIEND DIALOGUE")
	print("[MoodAnalyzer] Input: ", girlfriend_output)
	print("[MoodAnalyzer] Current Score: ", current_score)
	print("[MoodAnalyzer] Current Mood: ", current_mood)
	print("[MoodAnalyzer] Previous Interactions: ", previous_interactions)
	
	# Check for winning sentence sequence
	var normalized_output = girlfriend_output.to_lower().strip_edges()
	if _check_winning_sentence(normalized_output):
		print("[MoodAnalyzer] 🏆 WINNING SENTENCE DETECTED! Sequence progress: ", _winning_sequence_progress, "/4")
		if _winning_sequence_progress >= 4:
			print("[MoodAnalyzer] 🎉🎉🎉 ALL 4 WINNING SENTENCES COMPLETED! INSTANT WIN! 🎉🎉🎉")
			print("=".repeat(60) + "\n")
			# Instant win!
			var win_data = {
				"mood": "Happy",
				"score": 100,
				"interaction_type": "genuine_positive",
				"positive_streak": 4,
				"antagonistic_streak": 0
			}
			mood_analyzed.emit(win_data)
			return
	else:
		# Reset sequence if they say something else
		if _winning_sequence_progress > 0:
			print("[MoodAnalyzer] ⚠️ Winning sequence broken. Progress reset to 0.")
			_winning_sequence_progress = 0
	
	print("[MoodAnalyzer] Sending to ChatGPT API...")
	print("=".repeat(60))
	
	var interactions_json = JSON.stringify(previous_interactions)
	var user_message = "{\n  \"girlfriend_output\": \"" + girlfriend_output + "\",\n  \"current_score\": " + str(current_score) + ",\n  \"current_mood\": \"" + current_mood + "\",\n  \"previous_interactions\": " + interactions_json + "\n}"
	
	var request_body = {
		"model": model,
		"messages": [
			{"role": "system", "content": SYSTEM_PROMPT},
			{"role": "user", "content": user_message}
		],
		"temperature": 0.3,
		"max_tokens": 100
	}
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]
	
	var json_body = JSON.stringify(request_body)
	
	var error = http_request.request(OPENAI_API_URL, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		push_error("[MoodAnalyzer] HTTP Request failed: ", error)
		analysis_failed.emit("HTTP request failed")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("[MoodAnalyzer] Request failed with result: ", result)
		analysis_failed.emit("Request failed: " + str(result))
		return
	
	if response_code != 200:
		push_error("[MoodAnalyzer] Bad response code: ", response_code)
		var body_text = body.get_string_from_utf8()
		push_error("[MoodAnalyzer] Response: ", body_text)
		analysis_failed.emit("API error: " + str(response_code))
		return
	
	var json_str = body.get_string_from_utf8()
	var json = JSON.parse_string(json_str)
	
	if json == null or not json is Dictionary:
		push_error("[MoodAnalyzer] Failed to parse JSON response")
		analysis_failed.emit("Invalid JSON response")
		return
	
	# Extract the content from ChatGPT response
	if json.has("choices") and json["choices"].size() > 0:
		var content = json["choices"][0]["message"]["content"].strip_edges()
		print("\n[MoodAnalyzer] ✅ ChatGPT Response Received:")
		print("[MoodAnalyzer] Raw: ", content)
		
		# Parse the mood data JSON
		var mood_data = JSON.parse_string(content)
		if mood_data and mood_data is Dictionary and mood_data.has("mood") and mood_data.has("score"):
			print("\n" + "=".repeat(60))
			print("[MoodAnalyzer] 📊 MOOD ANALYSIS RESULT:")
			print("[MoodAnalyzer]   Mood Category: ", mood_data["mood"])
			print("[MoodAnalyzer]   Relationship Score: ", mood_data["score"])
			print("[MoodAnalyzer]   Interaction Type: ", mood_data.get("interaction_type", "unknown"))
			print("[MoodAnalyzer]   Positive Streak: ", mood_data.get("positive_streak", 0))
			print("[MoodAnalyzer]   Antagonistic Streak: ", mood_data.get("antagonistic_streak", 0))
			print("=".repeat(60) + "\n")
			mood_analyzed.emit(mood_data)
		else:
			print("\n[MoodAnalyzer] ❌ ERROR: Invalid mood data format")
			print("[MoodAnalyzer] Expected JSON with 'mood' and 'score' fields")
			print("[MoodAnalyzer] Got: ", content)
			push_error("[MoodAnalyzer] Invalid mood data format: ", content)
			analysis_failed.emit("Invalid mood data format")
	else:
		print("\n[MoodAnalyzer] ❌ ERROR: No choices in API response")
		push_error("[MoodAnalyzer] No choices in response")
		analysis_failed.emit("No choices in API response")
