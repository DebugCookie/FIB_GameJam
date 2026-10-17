extends Node3D
class_name Bubble3D

@onready var dialogue_label: Label = $SubViewport/VBoxContainer/DialogueLabel
@onready var character_label: Label = $SubViewport/VBoxContainer/CharacterLabel

@export var bubble_lifetime: float = 5.0

signal action_processed(morale_change: Dictionary)
signal bubble_expired

var current_impact: Dictionary = {}
var active_timer: SceneTreeTimer = null

func _ready() -> void:
	hide_bubble()

func setup_bubble(char_name: String, text: String, impact: Dictionary) -> void:
	character_label.text = char_name
	dialogue_label.text = text
	current_impact = impact
	show()
	
	active_timer = get_tree().create_timer(bubble_lifetime)
	await active_timer.timeout
	if is_visible_in_tree():
		bubble_expired.emit()
		hide_bubble()

func hide_bubble() -> void:
	hide()
	current_impact = {}


func approve_dialogue() -> void:
	if current_impact.is_empty(): return
	action_processed.emit(current_impact)
	hide_bubble()

func reject_dialogue() -> void:
	action_processed.emit({"employee": 0, "work": 0})
	hide_bubble()
