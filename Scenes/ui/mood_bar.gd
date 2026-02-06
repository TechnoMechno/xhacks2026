extends Control

# Smooth animated mood bar (heart bar)

# Reference to the actual progress bar child
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var max_health_label: Label = $HealthBar/MaxHealth

var animation_tween: Tween
var test_mode = false  # Set to false to disable auto test

func _ready() -> void:
	# Set visible first
	visible = true
	print("[MoodBar] ========== MOOD BAR READY ==========")
	print("[MoodBar] _ready() called, visible = ", visible)
	print("[MoodBar] Node path: ", get_path())
	print("[MoodBar] Parent: ", get_parent())
	
	# Set min/max on the child TextureProgressBar
	health_bar.min_value = 0
	health_bar.max_value = 100
	
	# Debug texture info
	print("[MoodBar] 🎨 Texture Debug:")
	print("[MoodBar]   texture_under: ", health_bar.texture_under)
	print("[MoodBar]   texture_progress: ", health_bar.texture_progress)
	print("[MoodBar]   tint_under: ", health_bar.tint_under)
	print("[MoodBar]   tint_progress: ", health_bar.tint_progress)
	print("[MoodBar]   fill_mode: ", health_bar.fill_mode)
	
	# Initialize with current mood from GameState WITHOUT animation
	var initial_mood = GameState.mood
	health_bar.value = initial_mood
	print("[MoodBar] Initializing with mood: ", initial_mood)
	print("[MoodBar] Bar value after init: ", health_bar.value, " (should match mood)")

	if max_health_label:
		max_health_label.text = str(int(health_bar.value))
		print("[MoodBar] Label updated to: ", max_health_label.text)

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
	print("[MoodBar] Ready - value set to: ", health_bar.value)
	print("[MoodBar] ======================================")

	# Test animation - automatically fill the bar
	if test_mode:
		await get_tree().create_timer(1.0).timeout
		animate_to(100)

func _on_mood_changed(new_mood: int) -> void:
	print("[MoodBar] >>>>>> SIGNAL RECEIVED: _on_mood_changed with value: ", new_mood)
	print("[MoodBar] Current bar value before animation: ", health_bar.value)
	
	# Visual feedback: flash the bar white briefly to show update received
	var original_modulate = health_bar.modulate
	health_bar.modulate = Color(2, 2, 2, 1)  # Bright flash
	await get_tree().create_timer(0.15).timeout
	health_bar.modulate = original_modulate
	
	animate_to(new_mood)

func animate_to(new_value: int) -> void:
	print("[MoodBar] animate_to() called with: ", new_value)
	
	# Kill previous animation if running
	if animation_tween:
		animation_tween.kill()
		print("[MoodBar] Killed previous tween")
	
	var start_value = health_bar.value
	print("[MoodBar] Animating from ", start_value, " to ", new_value)

	# Animate bar fill from current value to new value over 2 seconds
	animation_tween = create_tween()
	if animation_tween == null:
		print("[MoodBar] ERROR: Failed to create tween!")
		health_bar.value = new_value
		if max_health_label:
			max_health_label.text = str(new_value)
		return

	animation_tween.set_trans(Tween.TRANS_CUBIC)
	animation_tween.set_ease(Tween.EASE_OUT)
	
	# Animate both the bar value and the label number simultaneously
	animation_tween.tween_property(health_bar, "value", new_value, 2.0)
	animation_tween.parallel().tween_method(_update_label_value, start_value, float(new_value), 2.0)
	print("[MoodBar] Tween started successfully")

func _update_label_value(val: float) -> void:
	if max_health_label:
		max_health_label.text = str(int(val))
