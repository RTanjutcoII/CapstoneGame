extends Node2D

@onready var player = $Player
@export var dialogue_ui_scene: PackedScene

var dialogue_ui

func _ready() -> void:
	player.dead.connect(_on_player_death)
	dialogue_ui = dialogue_ui_scene.instantiate()
	add_child(dialogue_ui)
	dialogue_ui.hide()

func _on_player_death() -> void:
	player.respawn()
