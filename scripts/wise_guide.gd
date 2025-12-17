extends Node2D

@onready var interact_arrow := $InteractArrow
@onready var interact_area := $InteractArea
@onready var letter := $E

@export var dialogue_lines: Array[String] = [
	"Hello there.",
	"Use the arrow keys to move.",
	"Yes, that includes jumping.",
	"You can even press up arrow midair to perform a double jump.",
	"Press Z to swing your sword.",
	"Press E to interact, like you're doing now.",
	"Although, you're not gonna find much company in a place like this.",
	"You can parry projectiles if you get the timing right.",
	"There are checkpoints, so feel free to die if you want.",
	"Oh, and also give Ryan an A and convince his other professors to do the same.",
	"Good luck!"
]

var player_in_range := false
var talking := false
var player_ref: Node = null

func _ready() -> void:
	interact_arrow.visible = false
	letter.visible = false
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	$AnimatedSprite2D.play("talking")
	interact_arrow.visible = false
	letter.visible = false
	var ui := get_tree().get_first_node_in_group("DialogueUi")
	if ui:
		ui.start_dialogue(dialogue_lines, "Wise Guide")
	if player_ref and player_ref.has_method("set_control_enabled"):
		player_ref.set_control_enabled(false)
	if not ui.dialogue_ended.is_connected(_on_dialogue_ended):
		ui.dialogue_ended.connect(_on_dialogue_ended)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		interact_arrow.visible = true
		letter.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		$AnimatedSprite2D.play("default")
		player_in_range = false
		interact_arrow.visible = false
		letter.visible = false
		
func _on_dialogue_ended() -> void:
	talking = false

	# unfreeze player
	if player_ref and player_ref.has_method("set_control_enabled"):
		player_ref.set_control_enabled(true)

	$AnimatedSprite2D.play("default")
