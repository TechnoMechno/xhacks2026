extends CharacterBody2D

signal npc_reply(text: String)
signal npc_thinking

const SPEED = 40.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var ai_npc: Node = $Player2AINPC

func _ready() -> void:
	if ai_npc and ai_npc.has_signal("chat_received"):
		ai_npc.chat_received.connect(_on_chat_received)

func _physics_process(_delta: float) -> void:
	# Movement disabled for now
	velocity = Vector2.ZERO
	move_and_slide()

func interact() -> void:
	# Called when player interacts with girlfriend
	# Can trigger dialogue or other interactions
	pass

func receive_player_message(text: String) -> void:
	# Classify intent
	var intent = IntentClassifier.classify(text)

	# Apply mood delta via GameState
	GameState.apply_intent(intent)

	# Call Player2AINPC.chat(text) for LLM response
	npc_thinking.emit()
	if ai_npc and ai_npc.has_method("chat"):
		ai_npc.chat(text)
	else:
		# Fallback for testing without Player2
		_on_chat_received("I'm still mad at you!")

func _on_chat_received(response: String) -> void:
	# Emit reply for UI
	npc_reply.emit(response)
