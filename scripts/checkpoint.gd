extends Node2D

@export var activate_once := true
var activated := false

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.play("default")

func _on_body_entered(body: Node) -> void:
	if activated and activate_once:
		return

	if body.is_in_group("Player") and body.has_method("set_checkpoint"):
		body.set_checkpoint(global_position)
		activated = true

		_on_activated()

func _on_activated() -> void:
	$activate.play()
