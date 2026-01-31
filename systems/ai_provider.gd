extends RefCounted
class_name AIProvider

# Abstract AI Provider Interface
# Extend this class to add new AI backends (Player2, OpenAI, Mock, etc.)

signal response_received(text: String)
signal response_failed(error: String)

var system_prompt: String = ""
var conversation_history: Array[Dictionary] = []

func _init(prompt: String = "") -> void:
	system_prompt = prompt
	if not prompt.is_empty():
		conversation_history.append({"role": "system", "content": prompt})

func send_message(text: String) -> void:
	conversation_history.append({"role": "user", "content": text})
	# Override in subclass
	push_error("AIProvider.send_message() must be overridden")

func _handle_response(text: String) -> void:
	conversation_history.append({"role": "assistant", "content": text})
	response_received.emit(text)

func _handle_error(error: String) -> void:
	response_failed.emit(error)

func clear_history() -> void:
	conversation_history.clear()
	if not system_prompt.is_empty():
		conversation_history.append({"role": "system", "content": system_prompt})
