extends CanvasLayer

# Simple Dialogue UI - placeholder for future implementation
# Shows chat history and input field
# Supports both text and voice input via Player2STT
# Can be easily replaced with a better UI later

signal dialogue_opened
signal dialogue_closed
signal message_sent(text: String)

@onready var panel: PanelContainer = $Panel
@onready var history: RichTextLabel = $Panel/VBox/History
@onready var input_field: LineEdit = $Panel/VBox/InputRow/Input
@onready var mic_button: Button = $Panel/VBox/InputRow/MicBtn
@onready var send_button: Button = $Panel/VBox/InputRow/SendBtn
@onready var close_button: Button = $Panel/VBox/CloseBtn
@onready var stt: Node = $Player2STT
@onready var mood_label: Label = $Panel/VBox/MoodLabel

var girlfriend_node: Node = null
var is_open: bool = false
var is_recording: bool = false
var current_mood: String = "Neutral"
var current_score: int = 0

func _ready() -> void:
	# Connect UI signals
	send_button.pressed.connect(_on_send_pressed)
	input_field.text_submitted.connect(_on_text_submitted)
	close_button.pressed.connect(close_dialogue)

	# Connect mic button for push-to-talk
	mic_button.button_down.connect(_on_mic_button_down)
	mic_button.button_up.connect(_on_mic_button_up)

	# Connect STT signals
	if stt:
		stt.stt_received.connect(_on_stt_received)
		stt.stt_partial_received.connect(_on_stt_partial)
		stt.listening_started.connect(_on_listening_started)
		stt.listening_stopped.connect(_on_listening_stopped)
		stt.stt_failed.connect(_on_stt_failed)

	# Start hidden
	panel.visible = false

func open_dialogue(girlfriend: Node) -> void:
	girlfriend_node = girlfriend

	# Connect to girlfriend signals if not already
	if girlfriend_node:
		if girlfriend_node.has_signal("npc_reply") and not girlfriend_node.npc_reply.is_connected(_on_npc_reply):
			girlfriend_node.npc_reply.connect(_on_npc_reply)
		if girlfriend_node.has_signal("npc_thinking") and not girlfriend_node.npc_thinking.is_connected(_on_npc_thinking):
			girlfriend_node.npc_thinking.connect(_on_npc_thinking)
		if girlfriend_node.has_signal("mood_updated") and not girlfriend_node.mood_updated.is_connected(_on_mood_updated):
			girlfriend_node.mood_updated.connect(_on_mood_updated)
		if girlfriend_node.has_signal("mood_updated") and not girlfriend_node.mood_updated.is_connected(_on_mood_updated):
			girlfriend_node.mood_updated.connect(_on_mood_updated)

	# Show and focus
	panel.visible = true
	is_open = true
	input_field.grab_focus()

	# Clear previous conversation display (history persists in AI)
	history.clear()
	history.append_text("[color=gray]--- Conversation with Penny ---[/color]\n\n")

	dialogue_opened.emit()

func close_dialogue() -> void:
	panel.visible = false
	is_open = false
	input_field.clear()
	dialogue_closed.emit()

func _on_send_pressed() -> void:
	_send_message()

func _on_text_submitted(_text: String) -> void:
	_send_message()

func _send_message() -> void:
	var text = input_field.text.strip_edges()
	if text.is_empty():
		return

	# Display player message
	history.append_text("[color=cyan]You:[/color] %s\n" % text)

	# Send to girlfriend
	if girlfriend_node and girlfriend_node.has_method("receive_player_message"):
		girlfriend_node.receive_player_message(text)

	# Emit signal
	message_sent.emit(text)

	# Clear input
	input_field.clear()

func _on_npc_reply(text: String) -> void:
	# Parse JSON if needed (Player2AI returns JSON)
	var display_text = _parse_response(text)
	history.append_text("[color=salmon]Penny:[/color] %s\n" % display_text)
	_scroll_to_bottom()

func _on_npc_thinking() -> void:
	history.append_text("[color=gray]...[/color]\n")
	_scroll_to_bottom()

func _parse_response(response: String) -> String:
	var json = JSON.parse_string(response)
	if json is Dictionary and json.has("reply"):
		return json["reply"]
	return response

func _scroll_to_bottom() -> void:
	# Scroll history to bottom
	await get_tree().process_frame
	history.scroll_to_line(history.get_line_count())

func _input(event: InputEvent) -> void:
	# Close on Escape
	if is_open and event.is_action_pressed("ui_cancel"):
		close_dialogue()

# =============================================================================
# VOICE INPUT (Push-to-Talk)
# =============================================================================

func _on_mic_button_down() -> void:
	if not is_open or not stt:
		return
	print("[DialogueUI] Starting voice recording...")
	stt.start_stt()
	is_recording = true
	mic_button.text = "🔴"
	input_field.placeholder_text = "Listening..."

func _on_mic_button_up() -> void:
	if not stt or not is_recording:
		return
	print("[DialogueUI] Stopping voice recording...")
	stt.stop_stt()

func _on_listening_started() -> void:
	print("[DialogueUI] STT listening started")
	history.append_text("[color=gray](Listening...)[/color]\n")
	_scroll_to_bottom()

func _on_listening_stopped() -> void:
	print("[DialogueUI] STT listening stopped")
	is_recording = false
	mic_button.text = "🎤"
	mic_button.button_pressed = false
	input_field.placeholder_text = "Type your message..."

func _on_stt_partial(partial_text: String) -> void:
	# Show partial transcription in the input field as preview
	input_field.text = partial_text

func _on_stt_received(text: String) -> void:
	print("[DialogueUI] STT received: ", text)
	is_recording = false
	mic_button.text = "🎤"
	mic_button.button_pressed = false
	input_field.placeholder_text = "Type your message..."

	if text.strip_edges().is_empty():
		history.append_text("[color=gray](No speech detected)[/color]\n")
		_scroll_to_bottom()
		return

	# Put the transcribed text in the input field and send it
	input_field.text = text
	_send_message()

func _on_stt_failed(message: String, code: int) -> void:
	print("[DialogueUI] STT failed: ", message, " (code: ", code, ")")
	is_recording = false
	mic_button.text = "🎤"
	mic_button.button_pressed = false
	input_field.placeholder_text = "Type your message..."
	history.append_text("[color=red](Voice input failed)[/color]\n")
	_scroll_to_bottom()

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
