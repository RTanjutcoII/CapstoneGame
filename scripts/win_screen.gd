extends CanvasLayer

func _ready() -> void:
	$Sprite2D/Quit.pressed.connect(_on_quit)

func _on_quit() -> void:
	get_tree().quit()
