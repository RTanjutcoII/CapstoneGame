extends CharacterBody2D

@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 1.2
@export var shoot_range: float = 650.0
@export var health: int = 3

@onready var spr: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Node2D = $Muzzle

var active := false
var player: Node2D = null
var _t := 0.0
signal defeated

func _ready() -> void:
	add_to_group("Enemy")
	spr.play("idle")
	_t = shoot_cooldown
	spr.animation_finished.connect(_on_anim_finished)

func activate(p: Node2D) -> void:
	active = true
	player = p
	spr.play("idle")

func _physics_process(delta: float) -> void:
	if not active or player == null:
		return

	# face player
	var dx := player.global_position.x - global_position.x
	spr.flip_h = (dx < 0)

	# only shoot in range
	if global_position.distance_to(player.global_position) > shoot_range:
		return

	_t -= delta
	if _t <= 0.0:
		_t = shoot_cooldown
		shoot()

func shoot() -> void:
	if projectile_scene == null or player == null:
		return

	spr.play("attack")

	var dir := (player.global_position - muzzle.global_position).normalized()
	dir.y = clamp(dir.y, -0.6, 0.6)
	dir = dir.normalized()

	var p := projectile_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(p)
	p.global_position = muzzle.global_position

	p.init(dir, "enemy")

func take_damage_from_projectile(amount: int) -> void:
	health -= amount
	if health <= 0:
		defeated.emit()
		queue_free()

# ignore sword damage completely
func take_damage(_amount: int) -> void:
	# do nothing
	pass
	
func _on_anim_finished() -> void:
	if spr.animation == "attack":
		spr.play("idle")
