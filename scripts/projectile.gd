extends Area2D

@export var speed: float = 500.0
@export var lifetime: float = 2.0
@export var max_distance: float = 900.0

var _life: float = 0.0
var _dir: Vector2 = Vector2.ZERO
var _owner: String = "enemy"
var _start_pos: Vector2

func _ready() -> void:
	add_to_group("Projectile")
	_start_pos = global_position
	_life = lifetime
	body_entered.connect(_on_body_entered)

func init(direction: Vector2, owner: String = "enemy") -> void:
	_dir = direction.normalized()
	_owner = owner
	_start_pos = global_position
	_life = lifetime

func _physics_process(delta: float) -> void:
	global_position += _dir * speed * delta

	_life -= delta
	if _life <= 0.0:
		queue_free()
		return

	# range cap
	if global_position.distance_to(_start_pos) > max_distance:
		queue_free()

func parry_from(origin: Vector2) -> void:
	_owner = "player"
	_dir = (global_position - origin).normalized()
	_start_pos = global_position
	_life = lifetime

func _on_body_entered(body: Node) -> void:
	if _owner == "enemy" and body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(1, global_position)
		queue_free()
		return

	if _owner == "player" and body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
