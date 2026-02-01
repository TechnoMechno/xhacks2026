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
	response_area.append_text("[color=cyan]You:[/color] %s\n" % text)

	# Scroll to bottom to show latest message
	await get_tree().process_frame
	response_area.scroll_to_line(response_area.get_line_count() - 1)

	# Emit signal for game logic
	message_sent.emit(text)

	# Clear input
	input_box.clear()
