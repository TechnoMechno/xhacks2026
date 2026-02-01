extends CanvasLayer

# Visual dialogue box - displays dialogue PNG on Enter key
# Shows girlfriend responses and allows player to type

signal dialogue_opened
signal dialogue_closed
signal message_sent(text: String)

@onready var background: ColorRect = $Background
@onready var dialogue_box: TextureRect = $DialogueBox
@onready var portrait: TextureRect = $DialogueBox/PortraitClip/Portrait
@onready var response_area: RichTextLabel = $DialogueBox/ResponseArea
@onready var input_box: LineEdit = $DialogueBox/TypingInputBox
@onready var send_button: TextureButton = $DialogueBox/SendButton
@onready var mic_button: TextureButton = $DialogueBox/MicButton
@onready var stt: Node = $Player2STT
# Note: mood_label removed - mood is shown via the MoodBar instead
var mood_label: Label = null  # Kept as null to avoid errors in _update_mood_display

var is_open: bool = false
var is_recording: bool = false
var current_mood: String = "Neutral"
var current_score: int = 0
var girlfriend_node: Node = null  # Reference to girlfriend

# Portrait textures - preload all portraits
var portraits = {
	"angry": preload("res://Assets/Girlfriend/portraits/angry.png"),
	"crying": preload("res://Assets/Girlfriend/portraits/crying.png"),
	"furious": preload("res://Assets/Girlfriend/portraits/furious.png"),
	"happy": preload("res://Assets/Girlfriend/portraits/happy.png"),
	"neutral": preload("res://Assets/Girlfriend/portraits/neutral.png"),
	"sad": preload("res://Assets/Girlfriend/portraits/sad.png"),
	"soft_smile": preload("res://Assets/Girlfriend/portraits/soft_smile.png")
}

var portrait_animated_in: bool = false  # Track if portrait has done initial animation
var portrait_start_y: float = 333.0  # Off-screen below (hidden)
var portrait_end_y: float = 0.0      # Visible at top, cut off at bottom

func _ready() -> void:
	# Start hidden
	visible = false
	
	# Set portrait initial position (off-screen below)
	if portrait:
		portrait.position.y = portrait_start_y

	# Connect input box signals
	if input_box:
		input_box.text_submitted.connect(_on_text_submitted)

	# Connect send button
	if send_button:
		send_button.pressed.connect(_on_send_button_pressed)
	
	# Connect mic button (hold to record)
	if mic_button:
		mic_button.button_down.connect(_on_mic_button_down)
		mic_button.button_up.connect(_on_mic_button_up)
	
	# Connect STT signals
	if stt:
		stt.stt_received.connect(_on_stt_received)
		stt.stt_partial_received.connect(_on_stt_partial)
		stt.listening_started.connect(_on_listening_started)
		stt.listening_stopped.connect(_on_listening_stopped)
		stt.stt_failed.connect(_on_stt_failed)
	
	# Connect visibility changed to handle portrait animation
	visibility_changed.connect(_on_visibility_changed)

func open_dialogue(girlfriend: Node) -> void:
	girlfriend_node = girlfriend

	# Connect to girlfriend signals ONLY ONCE
	if girlfriend_node:
		if girlfriend_node.has_signal("npc_reply") and not girlfriend_node.npc_reply.is_connected(_on_npc_reply):
			girlfriend_node.npc_reply.connect(_on_npc_reply)
		if girlfriend_node.has_signal("npc_thinking") and not girlfriend_node.npc_thinking.is_connected(_on_npc_thinking):
			girlfriend_node.npc_thinking.connect(_on_npc_thinking)
		if girlfriend_node.has_signal("mood_updated") and not girlfriend_node.mood_updated.is_connected(_on_mood_updated):
			girlfriend_node.mood_updated.connect(_on_mood_updated)

	# Show and focus
	visible = true
	is_open = true
	if input_box:
		input_box.grab_focus()

	# Clear previous conversation display
	if response_area:
		response_area.clear()
		response_area.append_text("\n[color=gray]--- Conversation with Penny ---[/color]\n\n")

	dialogue_opened.emit()

func close_dialogue() -> void:
	visible = false
	is_open = false
	if input_box:
		input_box.clear()
	dialogue_closed.emit()

func _input(event: InputEvent) -> void:
	# Close on Escape
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		is_open = false
		if input_box:
			input_box.clear()
		dialogue_closed.emit()

func _on_visibility_changed() -> void:
	"""Handle portrait animation when dialogue box opens/closes"""
	if visible and not portrait_animated_in:
		# Set portrait to match current mood before animating in
		_set_portrait_for_current_mood()
		# Animate portrait in when dialogue first opens
		_animate_portrait_in()
	elif not visible and portrait_animated_in:
		# Reset portrait position when dialogue closes (for next time)
		if portrait:
			portrait.position.y = portrait_start_y
		portrait_animated_in = false

func _on_text_submitted(text: String) -> void:
	_send_message()

func _on_send_button_pressed() -> void:
	_send_message()

func _send_message() -> void:
	var text = input_box.text.strip_edges()
	if text.is_empty():
		return

	# Display player message in response area (each on new line)
	if response_area:
		response_area.append_text("[color=#8B4513]You:[/color] %s\n" % text)

		# Scroll to bottom to show latest message
		await get_tree().process_frame
		response_area.scroll_to_line(response_area.get_line_count() - 1)
	
	# Send to girlfriend
	if girlfriend_node and girlfriend_node.has_method("receive_player_message"):
		girlfriend_node.receive_player_message(text)

	# Emit signal for game logic
	message_sent.emit(text)

	# Clear input
	input_box.clear()

func add_npc_message(text: String) -> void:
	# Display girlfriend's response
	if response_area:
		response_area.append_text("[color=#D2691E]Penny:[/color] %s\n" % text)

		# Scroll to bottom (check if still in tree before awaiting)
		if not is_inside_tree():
			return
		await get_tree().process_frame
		# Check again after await in case scene changed
		if not is_inside_tree() or not response_area:
			return
		response_area.scroll_to_line(response_area.get_line_count() - 1)

func add_thinking_message() -> void:
	# Removed - no longer showing [Thinking...] text to avoid duplication
	pass

func _on_npc_reply(text: String) -> void:
	# Parse JSON if needed (Player2AI returns JSON)
	var display_text = _parse_response(text)
	add_npc_message(display_text)

func _on_npc_thinking() -> void:
	add_thinking_message()

func _parse_response(response: String) -> String:
	var json = JSON.parse_string(response)
	if json is Dictionary and json.has("reply"):
		return json["reply"]
	return response

func _on_mic_button_down() -> void:
	# Start recording when mic button is pressed
	if stt and stt.has_method("start_stt"):
		stt.start_stt()
		is_recording = true
		print("[DialogueUI] Started STT recording")

func _on_mic_button_up() -> void:
	# Stop recording when mic button is released
	if stt and stt.has_method("stop_stt"):
		stt.stop_stt()
		is_recording = false
		print("[DialogueUI] Stopped STT recording")

func _on_stt_received(message: String) -> void:
	# When speech-to-text is received, put it in the input box
	if input_box:
		input_box.text = message
		print("[DialogueUI] STT received: ", message)
		# Automatically send the message
		_send_message()

func _on_stt_partial(partial_text: String) -> void:
	# Update input box with partial recognition
	if input_box:
		input_box.text = partial_text

func _on_listening_started() -> void:
	print("[DialogueUI] Listening started")
	if input_box:
		input_box.placeholder_text = "Listening..."

func _on_listening_stopped() -> void:
	print("[DialogueUI] Listening stopped")
	if input_box:
		input_box.placeholder_text = "Type your message..."

func _on_stt_failed(message: String, code: int) -> void:
	print("[DialogueUI] STT failed: ", message, " (code: ", code, ")")
	is_recording = false
	if input_box:
		input_box.placeholder_text = "Type your message..."
	if response_area:
		response_area.append_text("[color=red](Voice input failed)[/color]\n")

# =============================================================================
# MOOD DISPLAY
# =============================================================================

func _on_mood_updated(mood_name: String, score: int) -> void:
	print("\n[DialogueUI] 🎨 UPDATING MOOD DISPLAY:")
	print("[DialogueUI]   Mood: ", mood_name)
	print("[DialogueUI]   Score: ", score)
	current_mood = mood_name
	current_score = score
	_update_mood_display()
	# Update portrait to match mood
	_update_portrait_for_mood(mood_name)
	print("[DialogueUI] ✅ Display updated\n")

func _update_mood_display() -> void:
	if not mood_label:
		return
	
	# Get color based on mood
	var color = _get_mood_color(current_mood)
	var emoji = _get_mood_emoji(current_mood)
	
	mood_label.text = "%s Mood: %s (Score: %d)" % [emoji, current_mood, current_score]
	mood_label.add_theme_color_override("font_color", color)

func _get_mood_color(mood: String) -> Color:
	match mood.to_lower():
		"happy":
			return Color(0.2, 1.0, 0.2)  # Bright green
		"soft smile":
			return Color(0.5, 1.0, 0.5)  # Light green
		"neutral":
			return Color(0.8, 0.8, 0.8)  # Gray
		"sad":
			return Color(0.5, 0.5, 1.0)  # Light blue
		"crying":
			return Color(0.3, 0.3, 1.0)  # Blue
		"angry":
			return Color(1.0, 0.5, 0.0)  # Orange
		"furious":
			return Color(1.0, 0.0, 0.0)  # Red
		_:
			return Color.WHITE

func _get_mood_emoji(mood: String) -> String:
	match mood.to_lower():
		"happy":
			return "😊"
		"soft smile":
			return "🙂"
		"neutral":
			return "😐"
		"sad":
			return "😔"
		"crying":
			return "😢"
		"angry":
			return "😠"
		"furious":
			return "😡"
		_:
			return "💭"

func _update_portrait_for_mood(mood_name: String) -> void:
	"""Update portrait to match mood"""
	var portrait_name = "neutral"
	
	# Map mood names to portrait expressions
	match mood_name.to_lower():
		"happy":
			portrait_name = "happy"
		"soft smile":
			portrait_name = "soft_smile"
		"neutral":
			portrait_name = "neutral"
		"sad":
			portrait_name = "sad"
		"crying":
			portrait_name = "crying"
		"angry":
			portrait_name = "angry"
		"furious":
			portrait_name = "furious"
	
	# Change portrait with fade transition
	change_portrait(portrait_name)

# Portrait control functions
func _set_portrait_for_current_mood() -> void:
	"""Set the portrait texture based on GameState.mood without animation"""
	if not portrait:
		return
	
	var mood = GameState.mood
	var portrait_name = "neutral"
	
	# Map mood values to portrait expressions
	if mood >= 80:
		portrait_name = "happy"
	elif mood >= 65:
		portrait_name = "soft_smile"
	elif mood >= 50:
		portrait_name = "neutral"
	elif mood >= 35:
		portrait_name = "sad"
	elif mood >= 20:
		portrait_name = "angry"
	elif mood >= 10:
		portrait_name = "furious"
	else:
		portrait_name = "crying"
	
	if portraits.has(portrait_name):
		portrait.texture = portraits[portrait_name]
		print("[DialogueUI] Set initial portrait to: ", portrait_name, " (mood: ", mood, ")")

func _animate_portrait_in() -> void:
	"""Animate portrait sliding up from bottom (only happens once per dialogue session)"""
	if not portrait:
		return
	
	portrait.position.y = portrait_start_y
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(portrait, "position:y", portrait_end_y, 0.5)
	portrait_animated_in = true
	print("[DialogueUI] Portrait animated in")

func show_portrait(portrait_name: String = "neutral") -> void:
	"""Set portrait to specific expression (no animation if already shown)"""
	if not portrait or not portraits.has(portrait_name):
		print("[DialogueUI] Invalid portrait name: ", portrait_name)
		return
	
	# Just change the texture, don't re-animate position
	if portrait_animated_in:
		# Quick cross-fade if portrait is already visible
		change_portrait(portrait_name)
	else:
		# If somehow called before animation, just set texture
		portrait.texture = portraits[portrait_name]
		print("[DialogueUI] Set portrait to: ", portrait_name)

func change_portrait(portrait_name: String) -> void:
	"""Change to a different portrait with fade transition"""
	if not portrait or not portraits.has(portrait_name):
		print("[DialogueUI] Invalid portrait name: ", portrait_name)
		return
	
	# Quick fade out and in
	var tween = create_tween()
	tween.tween_property(portrait, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): portrait.texture = portraits[portrait_name])
	tween.tween_property(portrait, "modulate:a", 1.0, 0.15)
	print("[DialogueUI] Changed portrait to: ", portrait_name)

func hide_portrait() -> void:
	"""Hide portrait with slide-down animation (not used anymore, kept for compatibility)"""
	if not portrait or not portrait_animated_in:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(portrait, "position:y", portrait_start_y, 0.4)
	portrait_animated_in = false
	print("[DialogueUI] Hiding portrait")
