extends Camera2D

@export var player_path: NodePath
@export var y_deadzone_px: float = 120.0
@export var y_smooth_speed: float = 10.0

var player: Node2D
var target_y: float

func _ready() -> void:
	player = get_node(player_path) as Node2D
	make_current()

	target_y = player.global_position.y
	global_position = Vector2(player.global_position.x, target_y)

func _physics_process(delta: float) -> void:
	if not player:
		return

	# always track x
	global_position.x = player.global_position.x

	# only update target_y when player moves enough vertically
	var dy := player.global_position.y - target_y
	if absf(dy) >= y_deadzone_px:
		target_y = player.global_position.y

	# move camera Y toward target_y
	if y_smooth_speed <= 0.0:
		global_position.y = target_y
	else:
		var t := 1.0 - exp(-y_smooth_speed * delta)
		global_position.y = lerp(global_position.y, target_y, t)
