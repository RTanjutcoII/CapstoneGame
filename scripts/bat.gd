extends CharacterBody2D

@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 1.2
@export var health: int = 3

@onready var detect_area: Area2D = $DetectArea
@onready var muzzle: Node2D = $Muzzle
@onready var spr: AnimatedSprite2D = $AnimatedSprite2D

@export var bob_height: float = 5.0
@export var bob_speed: float = 5.0

var player: Node2D = null
var _t: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	spr.play("default")
	_t = randf() * shoot_cooldown

	detect_area.body_entered.connect(_on_detect_body_entered)
	detect_area.body_exited.connect(_on_detect_body_exited)

	spr.animation_finished.connect(_on_anim_finished)

func _process(delta: float) -> void:
	_time += delta * bob_speed
	position.y += sin(_time) * (bob_height * delta)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	# face player
	var dx := player.global_position.x - global_position.x
	spr.flip_h = (dx < 0)

	_t -= delta
	if _t <= 0.0:
		_t = shoot_cooldown
		shoot()

func shoot() -> void:
	if projectile_scene == null or player == null:
		return

	spr.play("attack")

	var dir := (player.global_position - muzzle.global_position).normalized()

	# nerf vertical aim so shots aren't absurd
	dir.y = clamp(dir.y, -0.6, 0.6)
	dir = dir.normalized()

	var p := projectile_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(p)
	p.global_position = muzzle.global_position

	if p.has_method("init"):
		p.init(dir, "enemy")

func take_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		queue_free()

func _on_detect_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player = body
		# shoot a bit sooner when player enters
		_t = min(_t, 0.15)

func _on_detect_body_exited(body: Node) -> void:
	if body == player:
		player = null

func _on_anim_finished() -> void:
	if spr.animation == "attack":
		spr.play("default")
