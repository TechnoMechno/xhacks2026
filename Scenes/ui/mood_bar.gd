extends TextureProgressBar

# Smooth animated mood bar (heart bar)

var animation_tween: Tween

func _ready() -> void:
	min_value = 0
	max_value = 100
	value = GameState.mood

	GameState.mood_changed.connect(_on_mood_changed)

func _on_mood_changed(new_mood: int) -> void:
	# Kill previous animation if running
	if animation_tween:
		animation_tween.kill()

	# Animate bar fill from current value to new mood over 0.5 seconds
	animation_tween = create_tween()
	animation_tween.set_trans(Tween.TRANS_CUBIC)
	animation_tween.set_ease(Tween.EASE_OUT)
	animation_tween.tween_property(self, "value", new_mood, 0.5)
