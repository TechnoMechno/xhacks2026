extends CanvasLayer

# Visual dialogue box - displays dialogue PNG on Enter key
# Shows girlfriend responses and allows player to type

signal dialogue_opened
signal dialogue_closed
signal message_sent(text: String)

@onready var background: ColorRect = $Background
@onready var dialogue_box: TextureRect = $DialogueBox
@onready var response_area: RichTextLabel = $DialogueBox/ResponseArea
@onready var input_box: LineEdit = $DialogueBox/TypingInputBox
@onready var send_button: TextureButton = $DialogueBox/SendButton
@onready var mic_button: TextureButton = $DialogueBox/MicButton
@onready var stt: Node = $Player2STT

var is_open: bool = false

func _ready() -> void:
	# Start hidden
	visible = false

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

func _input(event: InputEvent) -> void:
	# Close on Escape
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		is_open = false
		if input_box:
			input_box.clear()
		dialogue_closed.emit()

func _on_text_submitted(text: String) -> void:
	_send_message()

func _on_send_button_pressed() -> void:
	_send_message()

func _send_message() -> void:
	var text = input_box.text.strip_edges()
	if text.is_empty():
		return

	# Display player message in response area (each on new line)
	response_area.append_text("[color=#8B4513]You:[/color] %s\n" % text)

	# Scroll to bottom to show latest message
	await get_tree().process_frame
	response_area.scroll_to_line(response_area.get_line_count() - 1)

	# Emit signal for game logic
	message_sent.emit(text)

	# Clear input
	input_box.clear()

func add_npc_message(text: String) -> void:
	# Display girlfriend's response
	response_area.append_text("[color=#D2691E]Penny:[/color] %s\n" % text)
	
	# Scroll to bottom
	await get_tree().process_frame
	response_area.scroll_to_line(response_area.get_line_count() - 1)

func add_thinking_message() -> void:
	# Display thinking indicator
	response_area.append_text("[color=gray][Thinking...][/color]\n")
	
	# Scroll to bottom
	await get_tree().process_frame
	response_area.scroll_to_line(response_area.get_line_count() - 1)

func _on_mic_button_down() -> void:
	# Start recording when mic button is pressed
	if stt and stt.has_method("start_stt"):
		stt.start_stt()
		print("[DialogueUI] Started STT recording")

func _on_mic_button_up() -> void:
	# Stop recording when mic button is released
	if stt and stt.has_method("stop_stt"):
		stt.stop_stt()
		print("[DialogueUI] Stopped STT recording")

func _on_stt_received(message: String) -> void:
	# When speech-to-text is received, put it in the input box
	if input_box:
		input_box.text = message
		print("[DialogueUI] STT received: ", message)
		# Automatically send the message
		_send_message()
