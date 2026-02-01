extends CanvasLayer

# Lose cutscene that plays the defeat video using built-in VideoStreamPlayer

@onready var video_player: VideoStreamPlayer = $BorderPanel/VideoStreamPlayer

signal cutscene_finished

var _finished: bool = false

func _ready() -> void:
	# Load video using VideoStreamPlayer
	var video_stream = load("res://videos/lose.mp4")
	if video_stream:
		video_player.stream = video_stream
		video_player.play()
		print("[LoseCutscene] Video started playing")
		# Connect the finished signal
		video_player.finished.connect(_on_video_finished)
	else:
		push_error("[LoseCutscene] Failed to load video file")
		# Fallback - go to end screen after a delay
		await get_tree().create_timer(2.0).timeout
		_on_video_finished()

func _input(event: InputEvent) -> void:
	# Allow skipping with space or click
	if _finished:
		return
	if (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE) or \
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_on_video_finished()

func _on_video_finished() -> void:
	if _finished:
		return
	_finished = true
	print("[LoseCutscene] Video finished")
	if video_player:
		video_player.stop()
	cutscene_finished.emit()
	# Go directly to menu
	GameState.change_state(GameState.State.MENU)
	get_tree().change_scene_to_file("res://Scenes/ui/menu.tscn")
