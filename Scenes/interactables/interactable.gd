extends Node2D

# Base class for interactable objects
# Subclasses override interact()

@onready var hitbox: Area2D = $Hitbox

func interact() -> void:
	# Override in subclasses
	pass
