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

const SYSTEM_PROMPT = """You are a mood analyzer for an AI girlfriend character in a game. Your task is to analyze the girlfriend's dialogue output and determine her emotional state and how it affects the relationship score.

TASK:
Analyze the provided girlfriend dialogue and conversation history to respond with:
1. The mood category (one of the 7 listed below)
2. The NEW relationship score after applying the mood change
3. The interaction type (genuine_positive, neutral, excuse_lie, or antagonistic)

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
For genuine_positive (harder to gain trust):
- Happy: +8 to +12
- Soft Smile: +3 to +7
- Neutral: +0 to +2

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
- If user breaks the antagonistic streak with genuine_positive or even excuse_lie, the streak resets

COMPOUNDING RULES:
- Only "antagonistic" responses compound when consecutive
- "excuse_lie" responses are negative but do NOT compound
- "genuine_positive" responses reset the antagonistic streak
- After 3 consecutive antagonistic responses, score = 0 and mood = Furious/Crying

IMPORTANT:
- She can detect when user is lying or making excuses vs being genuine
- The girlfriend starts at Furious mood with score 50
- She's harder to please than to upset
- Consider tone, word choice, sincerity, and context
- Track the last 2 interactions to detect patterns
- Respond ONLY with valid JSON in this exact format:

{"mood": "<mood_name>", "score": <new_score>, "interaction_type": "<type>", "antagonistic_streak": <count>}

EXAMPLES:

Input: {
  "girlfriend_output": "why are you late?",
  "current_score": 50,
  "previous_interactions": []
}
Output: {"mood": "Furious", "score": 50, "interaction_type": "neutral", "antagonistic_streak": 0}

Input: {
  "girlfriend_output": "I'm sorry, I was stuck in traffic",
  "current_score": 50,
  "previous_interactions": [{"type": "neutral"}]
}
Output: {"mood": "Angry", "score": 45, "interaction_type": "excuse_lie", "antagonistic_streak": 0}

Input: {
  "girlfriend_output": "Whatever, I don't care",
  "current_score": 45,
  "previous_interactions": [{"type": "excuse_lie"}]
}
Output: {"mood": "Furious", "score": 32, "interaction_type": "antagonistic", "antagonistic_streak": 1}

Input: {
  "girlfriend_output": "You're so annoying",
  "current_score": 32,
  "previous_interactions": [{"type": "excuse_lie"}, {"type": "antagonistic"}]
}
Output: {"mood": "Crying", "score": 10, "interaction_type": "antagonistic", "antagonistic_streak": 2}

Input: {
  "girlfriend_output": "I hate you",
  "current_score": 10,
  "previous_interactions": [{"type": "antagonistic"}, {"type": "antagonistic"}]
}
Output: {"mood": "Crying", "score": 0, "interaction_type": "antagonistic", "antagonistic_streak": 3}

Input: {
  "girlfriend_output": "I'm really sorry, I should have called you. You're right to be upset",
  "current_score": 32,
  "previous_interactions": [{"type": "antagonistic"}]
}
Output: {"mood": "Soft Smile", "score": 37, "interaction_type": "genuine_positive", "antagonistic_streak": 0}

Input: {
  "girlfriend_output": "Traffic was really bad, but I know I should have left earlier. I'm sorry for making you worry",
  "current_score": 50,
  "previous_interactions": []
}
Output: {"mood": "Soft Smile", "score": 55, "interaction_type": "genuine_positive", "antagonistic_streak": 0}

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

func analyze_dialogue(girlfriend_output: String, current_score: int = 50, previous_interactions: Array = []) -> void:
	if api_key.is_empty():
		push_error("[MoodAnalyzer] No API key set!")
		analysis_failed.emit("No API key configured")
		return
	
	print("\n" + "=".repeat(60))
	print("[MoodAnalyzer] 🔍 ANALYZING GIRLFRIEND DIALOGUE")
	print("[MoodAnalyzer] Input: ", girlfriend_output)
	print("[MoodAnalyzer] Current Score: ", current_score)
	print("[MoodAnalyzer] Previous Interactions: ", previous_interactions)
	print("[MoodAnalyzer] Sending to ChatGPT API...")
	print("=".repeat(60))
	
	var interactions_json = JSON.stringify(previous_interactions)
	var user_message = "{\n  \"girlfriend_output\": \"" + girlfriend_output + "\",\n  \"current_score\": " + str(current_score) + ",\n  \"previous_interactions\": " + interactions_json + "\n}"
	
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
