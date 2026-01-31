extends LineEdit

# Simple input handler that sends text to the chat system

func _ready() -> void:
	# Connect to text submitted signal
	text_submitted.connect(_on_text_submitted)

	# Auto-focus the input
	grab_focus()

	print("[SYSTEM] Type a message and press Enter")
	print("")

func _on_text_submitted(new_text: String) -> void:
	if new_text.strip_edges().is_empty():
		return

	# Get parent chat system
	var chat_system = get_parent()
	if chat_system and chat_system.has_method("send_message"):
		chat_system.send_message(new_text)

	# Clear input for next message
	clear()
