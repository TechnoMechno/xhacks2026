extends CanvasLayer

# Visual dialogue box - displays dialogue PNG on Enter key
# Shows girlfriend responses and allows player to type

signal dialogue_opened
signal dialogue_closed
signal message_sent(text: String)

@onready var background: ColorRect = $Background
@onready var dialogue_box: TextureRect = $DialogueBox
@onready var portrait: TextureRect = $DialogueBox/PortraitClip/Portrait
@onready var response_area: RichTextLabel = $DialogueBox/ResponseArea
@onready var input_box: LineEdit = $DialogueBox/TypingInputBox
@onready var send_button: TextureButton = $DialogueBox/SendButton
@onready var mic_button: TextureButton = $DialogueBox/MicButton
@onready var stt: Node = $Player2STT

var is_open: bool = false

# Portrait textures - preload all portraits
var portraits = {
	"angry": preload("res://Assets/Girlfriend/portraits/angry.png"),
	"crying": preload("res://Assets/Girlfriend/portraits/crying.png"),
	"furious": preload("res://Assets/Girlfriend/portraits/furious.png"),
	"happy": preload("res://Assets/Girlfriend/portraits/happy.png"),
	"neutral": preload("res://Assets/Girlfriend/portraits/neutral.png"),
	"sad": preload("res://Assets/Girlfriend/portraits/sad.png"),
	"soft_smile": preload("res://Assets/Girlfriend/portraits/soft_smile.png")
}

var portrait_animated_in: bool = false  # Track if portrait has done initial animation
var portrait_start_y: float = 333.0  # Off-screen below (hidden)
var portrait_end_y: float = 0.0      # Visible at top, cut off at bottom

func _ready() -> void:
	# Start hidden
	visible = false
	
	# Set portrait initial position (off-screen below)
	if portrait:
		portrait.position.y = portrait_start_y

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
	
	# Connect visibility changed to handle portrait animation
	visibility_changed.connect(_on_visibility_changed)

func _input(event: InputEvent) -> void:
	# Close on Escape
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		is_open = false
		if input_box:
			input_box.clear()
		dialogue_closed.emit()

func _on_visibility_changed() -> void:
	"""Handle portrait animation when dialogue box opens/closes"""
	if visible and not portrait_animated_in:
		# Set portrait to match current mood before animating in
		_set_portrait_for_current_mood()
		# Animate portrait in when dialogue first opens
		_animate_portrait_in()
	elif not visible and portrait_animated_in:
		# Reset portrait position when dialogue closes (for next time)
		if portrait:
			portrait.position.y = portrait_start_y
		portrait_animated_in = false

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

# Portrait control functions
func _set_portrait_for_current_mood() -> void:
	"""Set the portrait texture based on GameState.mood without animation"""
	if not portrait:
		return
	
	var mood = GameState.mood
	var portrait_name = "neutral"
	
	# Map mood values to portrait expressions
	if mood >= 80:
		portrait_name = "happy"
	elif mood >= 65:
		portrait_name = "soft_smile"
	elif mood >= 50:
		portrait_name = "neutral"
	elif mood >= 35:
		portrait_name = "sad"
	elif mood >= 20:
		portrait_name = "angry"
	elif mood >= 10:
		portrait_name = "furious"
	else:
		portrait_name = "crying"
	
	if portraits.has(portrait_name):
		portrait.texture = portraits[portrait_name]
		print("[DialogueUI] Set initial portrait to: ", portrait_name, " (mood: ", mood, ")")

func _animate_portrait_in() -> void:
	"""Animate portrait sliding up from bottom (only happens once per dialogue session)"""
	if not portrait:
		return
	
	portrait.position.y = portrait_start_y
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(portrait, "position:y", portrait_end_y, 0.5)
	portrait_animated_in = true
	print("[DialogueUI] Portrait animated in")

func show_portrait(portrait_name: String = "neutral") -> void:
	"""Set portrait to specific expression (no animation if already shown)"""
	if not portrait or not portraits.has(portrait_name):
		print("[DialogueUI] Invalid portrait name: ", portrait_name)
		return
	
	# Just change the texture, don't re-animate position
	if portrait_animated_in:
		# Quick cross-fade if portrait is already visible
		change_portrait(portrait_name)
	else:
		# If somehow called before animation, just set texture
		portrait.texture = portraits[portrait_name]
		print("[DialogueUI] Set portrait to: ", portrait_name)

func change_portrait(portrait_name: String) -> void:
	"""Change to a different portrait with fade transition"""
	if not portrait or not portraits.has(portrait_name):
		print("[DialogueUI] Invalid portrait name: ", portrait_name)
		return
	
	# Quick fade out and in
	var tween = create_tween()
	tween.tween_property(portrait, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): portrait.texture = portraits[portrait_name])
	tween.tween_property(portrait, "modulate:a", 1.0, 0.15)
	print("[DialogueUI] Changed portrait to: ", portrait_name)

func hide_portrait() -> void:
	"""Hide portrait with slide-down animation (not used anymore, kept for compatibility)"""
	if not portrait or not portrait_animated_in:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(portrait, "position:y", portrait_start_y, 0.4)
	portrait_animated_in = false
	print("[DialogueUI] Hiding portrait")
