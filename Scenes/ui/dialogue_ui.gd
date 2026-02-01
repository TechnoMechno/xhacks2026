extends CanvasLayer

# Simple Dialogue UI - placeholder for future implementation
# Shows chat history and input field
# Can be easily replaced with a better UI later

signal dialogue_opened
signal dialogue_closed
signal message_sent(text: String)

@onready var panel: PanelContainer = $Panel
@onready var history: RichTextLabel = $Panel/VBox/History
@onready var input_field: LineEdit = $Panel/VBox/InputRow/Input
@onready var send_button: Button = $Panel/VBox/InputRow/SendBtn
@onready var close_button: Button = $Panel/VBox/CloseBtn

var girlfriend_node: Node = null
var is_open: bool = false

func _ready() -> void:
	# Connect UI signals
	send_button.pressed.connect(_on_send_pressed)
	input_field.text_submitted.connect(_on_text_submitted)
	close_button.pressed.connect(close_dialogue)

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
