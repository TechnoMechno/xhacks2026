extends CharacterBody2D

const SPEED = 130.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detect_area: Area2D = $DetectArea

var nearby_interactables: Array = []

func _ready() -> void:
	if detect_area:
		detect_area.body_entered.connect(_on_body_entered)
		detect_area.body_exited.connect(_on_body_exited)
		detect_area.area_entered.connect(_on_area_entered)
		detect_area.area_exited.connect(_on_area_exited)

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()
	_update_animation(direction)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_interact_with_closest()

func _update_animation(direction: Vector2) -> void:
	if not anim or not anim.sprite_frames:
		return

	var is_moving = direction.length() > 0.01
	var base = "walk_" if is_moving else "idle_"

	var dir_name = "down"
	if abs(direction.x) > abs(direction.y):
		dir_name = "right" if direction.x > 0 else "left"
	elif direction.length() > 0:
		dir_name = "down" if direction.y > 0 else "up"

	var anim_name = base + dir_name
	if anim.sprite_frames.has_animation(anim_name) and anim.animation != anim_name:
		anim.play(anim_name)

func _on_body_entered(body: Node2D) -> void:
	print("[Player] Body entered: ", body.name, " has interact: ", body.has_method("interact"))
	if body.has_method("interact") and body not in nearby_interactables:
		nearby_interactables.append(body)
		print("[Player] Added to nearby_interactables: ", body.name)

func _on_body_exited(body: Node2D) -> void:
	print("[Player] Body exited: ", body.name)
	if body in nearby_interactables:
		nearby_interactables.erase(body)

func _on_area_entered(area: Area2D) -> void:
	print("[Player] Area entered: ", area.name)
	var interactable = _find_interactable(area)
	if interactable and interactable not in nearby_interactables:
		nearby_interactables.append(interactable)
		print("[Player] Added interactable from area: ", interactable.name)

func _on_area_exited(area: Area2D) -> void:
	print("[Player] Area exited: ", area.name)
	var interactable = _find_interactable(area)
	if interactable in nearby_interactables:
		nearby_interactables.erase(interactable)

func _find_interactable(node: Node) -> Node:
	# Traverse up the tree to find a node with interact() method
	var current = node.get_parent()
	while current:
		if current.has_method("interact"):
			return current
		current = current.get_parent()
	return null

func _interact_with_closest() -> void:
	print("[Player] Spacebar pressed, nearby_interactables: ", nearby_interactables.size())
	if nearby_interactables.is_empty():
		print("[Player] No nearby interactables")
		return

	var closest = nearby_interactables[0]
	var closest_dist = global_position.distance_to(closest.global_position)

	for interactable in nearby_interactables:
		var dist = global_position.distance_to(interactable.global_position)
		if dist < closest_dist:
			closest = interactable
			closest_dist = dist

	print("[Player] Interacting with: ", closest.name)
	closest.interact()
