extends PanelContainer

# Phone overlay panel

@onready var order_button: Button = $VBoxContainer/OrderButton
@onready var close_button: Button = $VBoxContainer/CloseButton

func _ready() -> void:
	order_button.pressed.connect(_on_order_pressed)
	close_button.pressed.connect(_on_close_pressed)
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC to open phone
		visible = !visible

func _on_order_pressed() -> void:
	GameState.set_flag("ordered_food", true)
	print("Food ordered! Go give it to your girlfriend.")
	visible = false

func _on_close_pressed() -> void:
	visible = false
