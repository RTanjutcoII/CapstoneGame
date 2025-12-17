extends Area2D

@export var limit_left: int = 0
@export var limit_top: int = -99999
@export var limit_right: int = 99999
@export var limit_bottom: int = 99999

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return

	var cam := get_viewport().get_camera_2d()
	if cam:
		cam.limit_left = limit_left
		cam.limit_right = limit_right
		cam.limit_top = limit_top
		cam.limit_bottom = limit_bottom
