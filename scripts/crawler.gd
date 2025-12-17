extends CharacterBody2D

@export var health: int = 1
@export var speed: float = 100.0

var _dir: int = -1 # start moving left

signal defeated

func _ready() -> void:
	# make sure visuals/collisions are on
	$AnimatedSprite2D.visible = true
	$Area2D/Hurtbox.disabled = false
	$Hitbox.disabled = false

	$AnimatedSprite2D.play("move")

	# Player damage on touch
	$Area2D.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	velocity.x = speed * _dir
	move_and_slide()

	# Face direction
	$AnimatedSprite2D.flip_h = (_dir > 0)

	# Turn around on wall hit
	if is_on_wall():
		_dir *= -1

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(1, global_position)

func take_damage(amount: int) -> void:
	health -= amount
	$AnimationPlayer.play("hit_flash")
	$AnimationPlayer.queue("RESET")

	if health <= 0:
		die()

func die() -> void:
	defeated.emit()
	queue_free()
