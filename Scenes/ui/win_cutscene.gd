extends CanvasLayer

# Win cutscene that plays the victory video using VLC plugin

@onready var video_player: VLCMediaPlayer = $BorderPanel/VLCMediaPlayer

signal cutscene_finished

var _finished: bool = false
var _playing: bool = false

func _ready() -> void:
	# Load media using VLCMedia.load_from_file
	var media = VLCMedia.load_from_file("res://videos/win.MP4")
	if media:
		video_player.set_media(media)
		# Start playing
		video_player.play()
		_playing = true
		print("[WinCutscene] VLC video started playing")
	else:
		push_error("[WinCutscene] Failed to load video file")
		# Fallback - go to end screen after a delay
		await get_tree().create_timer(2.0).timeout
		_on_video_finished()

func _process(_delta: float) -> void:
	# Check if video finished playing by polling state
	if _playing and not _finished:
		if video_player and not video_player.is_playing():
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
	_playing = false
	print("[WinCutscene] Video finished")
	# VLCMediaPlayer doesn't have stop(), just pause it
	if video_player:
		video_player.pause()
	cutscene_finished.emit()
	# Go directly to menu
	GameState.change_state(GameState.State.MENU)
	get_tree().change_scene_to_file("res://Scenes/ui/menu.tscn")
