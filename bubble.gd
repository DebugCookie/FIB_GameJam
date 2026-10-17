extends Node3D
class_name Bubble3D

@onready var dialogue_label: Label = $SubViewport/VBoxContainer/DialogueLabel
@onready var character_label: Label = $SubViewport/VBoxContainer/CharacterLabel


signal bubble_expired

var current_impact: Dictionary = {}
var active_timer: SceneTreeTimer = null

func setup_bubble(char_name: String, text: String, impact: Dictionary) -> void:
	character_label.text = char_name
	dialogue_label.text = text
	current_impact = impact
	show()
	
	active_timer = get_tree().create_timer(5.0)
	await active_timer.timeout
	if is_visible_in_tree():
		bubble_expired.emit()
		hide_bubble()

func _ready() -> void:
	hide_bubble()



func hide_bubble() -> void:
	hide()
	current_impact = {}
