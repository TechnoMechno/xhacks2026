extends CharacterBody2D
class_name BaseCharacter

@export var speed: float = 60.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var move_dir: Vector2 = Vector2.ZERO
var facing_dir: Vector2 = Vector2.DOWN

func set_move_dir(dir: Vector2) -> void:
	move_dir = dir
	if dir.length() > 0.0:
		facing_dir = dir.normalized()

func _physics_process(_delta: float) -> void:
	velocity = move_dir.normalized() * speed
	move_and_slide()
	_update_anim()

func _update_anim() -> void:
	# Assumes you have animations named: "idle_down", "idle_up", "idle_left", "idle_right"
	# and "walk_down", "walk_up", "walk_left", "walk_right"
	var is_moving := move_dir.length() > 0.01
	var base := "walk_" if is_moving else "idle_"

	var dir_name := "down"
	if abs(facing_dir.x) > abs(facing_dir.y):
		dir_name = "right" if facing_dir.x > 0 else "left"
	else:
		dir_name = "down" if facing_dir.y > 0 else "up"

	var anim_name := base + dir_name
	if anim.animation != anim_name:
		anim.play(anim_name)
