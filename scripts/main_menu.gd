extends CanvasLayer

@export var level_scene: PackedScene

func _ready() -> void:
	$Sprite2D/Start.pressed.connect(_on_start)
	$Sprite2D/Quit.pressed.connect(_on_quit)

func _on_start() -> void:
	get_tree().change_scene_to_packed(level_scene)

func _on_quit() -> void:
	get_tree().quit()
