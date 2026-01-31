extends CharacterBody2D

const SPEED = 200.0

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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # E key
		_interact_with_closest()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("interact") and body not in nearby_interactables:
		nearby_interactables.append(body)

func _on_body_exited(body: Node2D) -> void:
	if body in nearby_interactables:
		nearby_interactables.erase(body)

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.has_method("interact") and parent not in nearby_interactables:
		nearby_interactables.append(parent)

func _on_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent in nearby_interactables:
		nearby_interactables.erase(parent)

func _interact_with_closest() -> void:
	if nearby_interactables.is_empty():
		return

	# Get closest interactable
	var closest = nearby_interactables[0]
	var closest_dist = global_position.distance_to(closest.global_position)

	for interactable in nearby_interactables:
		var dist = global_position.distance_to(interactable.global_position)
		if dist < closest_dist:
			closest = interactable
			closest_dist = dist

	closest.interact()
