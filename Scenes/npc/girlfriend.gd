extends Node2D

# Brain script for the girlfriend NPC
# Runs the dialogue loop with Player2AINPC

signal npc_reply(text: String)
signal npc_thinking

@onready var ai_npc: Node = $Player2AINPC  # Player2AINPC node (to be added in scene)

func _ready() -> void:
	if ai_npc and ai_npc.has_signal("chat_received"):
		ai_npc.chat_received.connect(_on_chat_received)

func receive_player_message(text: String) -> void:
	# 1. Classify intent
	var intent = IntentClassifier.classify(text)

	# 2. Apply mood delta via GameState
	GameState.apply_intent(intent)

	# 3. Call Player2AINPC.chat(text) for LLM response
	npc_thinking.emit()
	if ai_npc and ai_npc.has_method("chat"):
		ai_npc.chat(text)
	else:
		# Fallback for testing without Player2
		_on_chat_received("I'm still mad at you!")

func _on_chat_received(response: String) -> void:
	# 4. Emit reply for UI
	npc_reply.emit(response)
