extends Area2D

@export var skelecam_path: NodePath
@export var player_cam_path: NodePath
@export var skeleton_path: NodePath
@export var win_screen_scene: PackedScene

@export var dialogue_lines: Array[String] = [
	"Ha! A weak human!",
	"Your sword will do nothing to me!",
	"My sword is much stronger! It will actually hurt me! Haha!",
	"But it's not like you could ever use my sword against me!",
	"Now DIE!"
]

@export var outro_lines: Array[String] = [
	"No... impossible...",
	"My own blade...",
	"You... win..."
]

var _ending := false
var used := false
var player_ref: Node2D = null
var skelecam: Camera2D
var player_cam: Camera2D
var skeleton: Node

func _ready() -> void:
	skelecam = get_node(skelecam_path) as Camera2D
	player_cam = get_node(player_cam_path) as Camera2D
	skeleton = get_node(skeleton_path)
	skeleton.defeated.connect(_on_skeleton_defeated)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if used:
		return
	if not body.is_in_group("Player"):
		return

	used = true
	player_ref = body as Node2D

	# switch camera
	if skelecam:
		skelecam.make_current()

	# freeze player
	if body.has_method("set_control_enabled"):
		body.set_control_enabled(false)

	# start dialogue
	var ui := get_tree().get_first_node_in_group("DialogueUi")
	if ui == null:
		_finish_encounter() # fallback
		return

	if not ui.dialogue_ended.is_connected(_on_dialogue_ended):
		ui.dialogue_ended.connect(_on_dialogue_ended)

	ui.start_dialogue(dialogue_lines, "Skeleton")

func _on_dialogue_ended() -> void:
	_finish_encounter()

func _finish_encounter() -> void:
	# unfreeze player
	if player_ref and player_ref.has_method("set_control_enabled"):
		player_ref.set_control_enabled(true)

	# activate skeleton
	if skeleton and skeleton.has_method("activate"):
		skeleton.activate(player_ref)
		
func _on_skeleton_defeated() -> void:
	if _ending:
		return
	_ending = true

	# Freeze player
	var player := get_tree().get_first_node_in_group("Player")
	player.set_control_enabled(false)

	# Start outro dialogue
	var ui := get_tree().get_first_node_in_group("DialogueUi")
	if ui == null:
		_show_win()
		return

	ui.dialogue_ended.connect(_on_outro_ended, CONNECT_ONE_SHOT)
	ui.start_dialogue(outro_lines, "Skeleton")

func _on_outro_ended() -> void:
	_show_win()

func _show_win() -> void:
	if win_screen_scene == null:
		return
	
	var win := win_screen_scene.instantiate()
	get_tree().current_scene.add_child(win)
