extends AIProvider
class_name AIProviderPlayer2

# Player2AI provider implementation
# Wraps the Player2AINPC node for the provider interface

var _ai_npc: Node = null
var _parent_node: Node = null
var _fallback_provider: AIProviderMock = null

func _init(prompt: String = "", parent: Node = null) -> void:
	super._init(prompt)
	_parent_node = parent
	_fallback_provider = AIProviderMock.new(prompt, parent)
	_fallback_provider.response_received.connect(func(t): response_received.emit(t))
	_setup_npc()

func _setup_npc() -> void:
	if not _parent_node:
		push_error("AIProviderPlayer2 requires a parent node")
		return

	var script_path = "res://addons/player2/nodes/Player2AINPC.gd"
	if not ResourceLoader.exists(script_path):
		print("[AIProviderPlayer2] Player2 addon not found")
		return

	var npc_script = load(script_path)
	if not npc_script:
		print("[AIProviderPlayer2] Failed to load Player2AINPC script")
		return

	_ai_npc = Node.new()
	_ai_npc.set_script(npc_script)
	_ai_npc.set("character_name", "Penny")
	_ai_npc.set("character_description", system_prompt)
	_ai_npc.set("character_system_message", "Keep responses short (1-3 sentences). Be emotional and reactive.")
	_ai_npc.set("greet_on_entry", false)
	_ai_npc.set("auto_store_conversation_history", false)

	_parent_node.add_child(_ai_npc)

	if _ai_npc.has_signal("chat_received"):
		_ai_npc.chat_received.connect(_on_response)
	if _ai_npc.has_signal("chat_failed"):
		_ai_npc.chat_failed.connect(_on_failed)

	print("[AIProviderPlayer2] Player2AINPC initialized")

func send_message(text: String) -> void:
	conversation_history.append({"role": "user", "content": text})

	if _ai_npc and _ai_npc.has_method("chat"):
		print("[AIProviderPlayer2] Sending to Player2AI...")
		_ai_npc.chat(text)
	else:
		print("[AIProviderPlayer2] Falling back to mock provider")
		_fallback_provider.send_message(text)

func _on_response(response: String) -> void:
	var parsed = _parse_response(response)
	_handle_response(parsed)

func _parse_response(response: String) -> String:
	# Player2AI may return JSON
	var json = JSON.parse_string(response)
	if json is Dictionary and json.has("reply"):
		return json["reply"]
	return response

func _on_failed(error_code: int) -> void:
	print("[AIProviderPlayer2] Request failed (code: %d), using fallback" % error_code)
	# Get last user message for mock
	var last_msg = ""
	for i in range(conversation_history.size() - 1, -1, -1):
		if conversation_history[i]["role"] == "user":
			last_msg = conversation_history[i]["content"]
			break
	_fallback_provider.send_message(last_msg)

func is_available() -> bool:
	return _ai_npc != null
