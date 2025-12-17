extends CanvasLayer

@onready var panel: Control = $Panel
@onready var name_label: Label = $Panel/NameLabel
@onready var text_label: Label = $Panel/TextLabel

var lines: Array = []   # untyped to avoid typed-array mismatch
var index: int = 0
var active: bool = false
var _block_advance_until: int = 0
signal dialogue_started
signal dialogue_ended

func _ready() -> void:
	panel.visible = false
	add_to_group("DialogueUI")
	process_mode = Node.PROCESS_MODE_ALWAYS # so it still reads input even if player is paused/frozen

func start_dialogue(dialogue_lines: Array, speaker: String = "") -> void:
	# don't restart if already talking
	if active:
		return

	if dialogue_lines.is_empty():
		return

	lines = dialogue_lines.duplicate()
	index = 0
	active = true

	name_label.text = speaker
	text_label.text = str(lines[index])
	panel.visible = true

	# so press doesn't skip line 0
	_block_advance_until = Time.get_ticks_msec() + 150
	emit_signal("dialogue_started")

func _process(_delta: float) -> void:
	if not active:
		return

	if Input.is_action_just_pressed("interact"):
		if Time.get_ticks_msec() < _block_advance_until:
			return

		index += 1
		if index >= lines.size():
			end_dialogue()
		else:
			text_label.text = str(lines[index])

func end_dialogue() -> void:
	active = false
	panel.visible = false
	lines.clear()
	index = 0
	emit_signal("dialogue_ended")
