extends TextureProgressBar

# Smooth animated mood bar (heart bar)

@onready var max_health_label = $MaxHealth

var animation_tween: Tween
var test_mode = false  # Set to false to disable auto test

func _ready() -> void:
	# Set visible first
	visible = true
	print("[MoodBar] ========== MOOD BAR READY ==========")
	print("[MoodBar] _ready() called, visible = ", visible)
	print("[MoodBar] Node path: ", get_path())
	print("[MoodBar] Parent: ", get_parent())
	print("[MoodBar] Is inside tree: ", is_inside_tree())

	min_value = 0
	max_value = 100

	# Initialize with current mood from GameState WITHOUT animation
	# Set value directly before connecting signals to prevent initial animation
	var initial_mood = GameState.mood
	value = initial_mood
	print("[MoodBar] Initializing with mood: ", initial_mood)
	print("[MoodBar] Bar size: ", size, " position: ", position)

	if max_health_label:
		max_health_label.text = str(int(value))
		print("[MoodBar] Label updated to: ", max_health_label.text)
	else:
		print("[MoodBar] WARNING: max_health_label is null!")

	# Connect AFTER setting initial value - check if already connected first
	if not GameState.mood_changed.is_connected(_on_mood_changed):
		GameState.mood_changed.connect(_on_mood_changed)
		print("[MoodBar] ✅ Connected to GameState.mood_changed signal")
	else:
		print("[MoodBar] ⚠️ Already connected to mood_changed signal")

	# Print signal connection count for debugging
	var connections = GameState.mood_changed.get_connections()
	print("[MoodBar] mood_changed signal has ", connections.size(), " connection(s)")
	for conn in connections:
		print("[MoodBar]   -> ", conn)
	print("[MoodBar] Ready - value set to: ", value)
	print("[MoodBar] ======================================")

	# Test animation - automatically fill the bar
	if test_mode:
		await get_tree().create_timer(1.0).timeout
		animate_to(100)

func _on_mood_changed(new_mood: int) -> void:
	print("[MoodBar] >>>>>> SIGNAL RECEIVED: _on_mood_changed with value: ", new_mood)
	print("[MoodBar] Current bar value before animation: ", value)
	print("[MoodBar] Is node still in tree: ", is_inside_tree())
	print("[MoodBar] Is node visible: ", visible)
	animate_to(new_mood)

func animate_to(new_value: int) -> void:
	print("[MoodBar] animate_to() called with: ", new_value)

	# Kill previous animation if running
	if animation_tween:
		animation_tween.kill()
		print("[MoodBar] Killed previous tween")

	var start_value = value
	print("[MoodBar] Animating from ", start_value, " to ", new_value)

	# Animate bar fill from current value to new value over 2 seconds
	animation_tween = create_tween()
	if animation_tween == null:
		print("[MoodBar] ERROR: Failed to create tween!")
		# Fallback: set value directly
		value = new_value
		if max_health_label:
			max_health_label.text = str(new_value)
		return

	animation_tween.set_trans(Tween.TRANS_CUBIC)
	animation_tween.set_ease(Tween.EASE_OUT)

	# Animate both the bar value and the label number simultaneously
	animation_tween.tween_property(self, "value", new_value, 2.0)
	animation_tween.parallel().tween_method(_update_label_value, start_value, float(new_value), 2.0)
	print("[MoodBar] Tween started successfully")

func _update_label_value(val: float) -> void:
	if max_health_label:
		max_health_label.text = str(int(val))
