extends CharacterBody2D

signal health_changed(current: int, max: int)
signal dead

@export var initial_checkpoint: NodePath
var _checkpoint: Vector2

@export var max_health: int = 5
var health: int = max_health

@export var speed: float = 500
@export var gravity: float = 2000
@export var jump_force: float = 600

@export var knockback_force: float = 600.0
@export var knockup_force: float = 200.0
@export var hurt_stun: float = 0.18

@export var attack_cooldown: float = 0.35

var facing_right: bool = true
var cd: float = 0.0
var is_attacking := false
var was_on_floor := false

var alive := true
var can_control := true

var jumps_available: int = 2
var MAX_JUMPS: int = 2

var dying: bool = false


func _ready() -> void:
	$AnimatedSprite2D.play("idle")
	was_on_floor = is_on_floor()
	$AnimatedSprite2D.animation_finished.connect(_on_anim_finished)
	$Explode.visible = false
	$Explode.animation_finished.connect(_on_explode_finished)

	var cp := get_node_or_null(initial_checkpoint) as Node2D
	if cp:
		_checkpoint = cp.global_position
	else:
		_checkpoint = global_position

	emit_signal("health_changed", health, max_health)


func _physics_process(delta: float) -> void:
	if not alive:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		return

	# cooldown
	if cd > 0.0:
		cd = max(cd - delta, 0.0)

	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		if velocity.y > 1200:
			velocity.y = 1200

	# jump
	if Input.is_action_just_pressed("ui_up") and jumps_available > 1 and alive and can_control:
		velocity.y = -jump_force
		jumps_available -= 1
		if not is_attacking:
			$AnimatedSprite2D.play("jump_start")

	# reset jumps
	if is_on_floor():
		jumps_available = MAX_JUMPS

	# movement
	var xdirect := Input.get_axis("ui_left", "ui_right")
	if alive and can_control:
		velocity.x = speed * xdirect

		if xdirect != 0:
			facing_right = xdirect > 0

		$AnimatedSprite2D.flip_h = not facing_right

		if facing_right:
			$SwingRange.scale.x = abs($SwingRange.scale.x)
		else:
			$SwingRange.scale.x = -abs($SwingRange.scale.x)

	move_and_slide()

	# animation state selection
	var on_floor := is_on_floor()
	var moving: bool = absf(velocity.x) > 1.0

	# landing detection
	if on_floor and not was_on_floor and not is_attacking:
		play_anim("jump_end")

	# floor: run/idle unless jump_end is playing
	if on_floor and not is_attacking:
		if $AnimatedSprite2D.animation != "jump_end":
			if moving:
				play_anim("run")
			else:
				play_anim("idle")

	# air: midair unless jump_start is playing
	if not on_floor and not is_attacking:
		if $AnimatedSprite2D.animation != "jump_start":
			play_anim("midair")

	was_on_floor = on_floor

	# attack
	if Input.is_action_just_pressed("attack") and alive and can_control and cd <= 0.0:
		perform_attack()


func take_damage(amount: int, global_pos: Vector2 = Vector2.INF, is_falloff: bool = false) -> void:
	if not alive or dying:
		return
	
	if health != 0:
		$Ouch.play()

	health = max(health - amount, 0)
	emit_signal("health_changed", health, max_health)
	$AnimationPlayer.play("hit_flash")
	$AnimationPlayer.queue("RESET")
	if !is_falloff:
		_knockback(global_pos)

	if health == 0:
		die()


func _knockback(from_global_pos: Vector2) -> void:
	var dir_x := 0.0
	if from_global_pos != Vector2.INF:
		dir_x = sign(global_position.x - from_global_pos.x)
		if dir_x == 0:
			dir_x = 1.0
	else:
		dir_x = -1.0 if velocity.x >= 0.0 else 1.0

	velocity.x = knockback_force * dir_x
	velocity.y = -knockup_force

	can_control = false
	_stun_recover()


func _stun_recover() -> void:
	await get_tree().create_timer(hurt_stun).timeout
	if alive:
		can_control = true


func set_checkpoint(pos: Vector2) -> void:
	_checkpoint = pos


func die() -> void:
	if dying:
		return

	dying = true
	alive = false
	can_control = false
	$Hurtbox.disabled = true

	velocity = Vector2.ZERO

	$Explode.visible = true
	$Explode.play("default")
	$AnimatedSprite2D.play("death")

	await get_tree().create_timer(3.0).timeout
	dead.emit()


func respawn() -> void:
	print("respawn")
	dying = false
	global_position = _checkpoint
	velocity = Vector2.ZERO
	health = max_health
	emit_signal("health_changed", health, max_health)
	alive = true
	can_control = true
	$Hurtbox.disabled = false
	$AnimatedSprite2D.play("idle")


func perform_attack() -> void:
	cd = attack_cooldown
	is_attacking = true
	$AnimatedSprite2D.play("attack")
	$Swing.play()

	for body in $SwingRange.get_overlapping_bodies():
		if body.is_in_group("Enemy") and body.has_method("take_damage"):
			body.take_damage(1)
			$SwingHit.play()

	for area in $SwingRange.get_overlapping_areas():
		if area.is_in_group("Projectile") and area.has_method("parry_from"):
			area.parry_from(global_position)
			$ParryHit.play()

	await $AnimatedSprite2D.animation_finished
	is_attacking = false

	if is_on_floor():
		play_anim("run" if absf(velocity.x) > 1.0 else "idle")
	else:
		play_anim("midair")


func _on_anim_finished() -> void:
	if is_attacking:
		return

	match $AnimatedSprite2D.animation:
		"jump_start":
			if not is_on_floor():
				play_anim("midair")
		"jump_end":
			if is_on_floor():
				play_anim("run" if absf(velocity.x) > 1.0 else "idle")


func play_anim(name: String) -> void:
	if $AnimatedSprite2D.animation != name:
		$AnimatedSprite2D.play(name)
		
func _on_explode_finished() -> void:
	$Explode.play("invisible")
	$Explode.visible = false
	
func set_control_enabled(enabled: bool) -> void:
	can_control = enabled
	if not enabled:
		velocity = Vector2.ZERO
