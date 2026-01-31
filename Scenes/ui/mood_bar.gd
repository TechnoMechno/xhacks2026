extends ProgressBar

# Updates based on GameState.mood_changed signal

func _ready() -> void:
	min_value = 0
	max_value = 100
	value = GameState.mood

	GameState.mood_changed.connect(_on_mood_changed)
	_update_color(GameState.mood)

func _on_mood_changed(new_mood: int) -> void:
	value = new_mood
	_update_color(new_mood)

func _update_color(mood_value: int) -> void:
	# Change color based on mood
	if mood_value >= 80:
		modulate = Color(0.2, 1.0, 0.2)  # Green
	elif mood_value >= 50:
		modulate = Color(1.0, 1.0, 0.2)  # Yellow
	elif mood_value >= 20:
		modulate = Color(1.0, 0.6, 0.2)  # Orange
	else:
		modulate = Color(1.0, 0.2, 0.2)  # Red
