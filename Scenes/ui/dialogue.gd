extends PanelContainer

# Chat panel with history and input

@onready var history: RichTextLabel = $VBoxContainer/History
@onready var input: LineEdit = $VBoxContainer/HBoxContainer/LineEdit
@onready var send_button: Button = $VBoxContainer/HBoxContainer/SendButton

var girlfriend: Node = null

func _ready() -> void:
	send_button.pressed.connect(_on_send_pressed)
	input.text_submitted.connect(_on_text_submitted)

	# Find girlfriend in scene tree
	await get_tree().process_frame
	girlfriend = get_tree().get_first_node_in_group("girlfriend")

	if girlfriend:
		girlfriend.npc_reply.connect(_on_npc_reply)
		girlfriend.npc_thinking.connect(_on_npc_thinking)

func _on_send_pressed() -> void:
	_send_message()

func _on_text_submitted(_text: String) -> void:
	_send_message()

func _send_message() -> void:
	var text = input.text.strip_edges()
	if text.is_empty():
		return

	# Add to history
	history.append_text("[color=cyan]You:[/color] " + text + "\n")

	# Send to girlfriend
	if girlfriend and girlfriend.has_method("receive_player_message"):
		girlfriend.receive_player_message(text)

	input.clear()

func _on_npc_reply(text: String) -> void:
	history.append_text("[color=red]Girlfriend:[/color] " + text + "\n")

func _on_npc_thinking() -> void:
	history.append_text("[color=gray][Thinking...][/color]\n")
