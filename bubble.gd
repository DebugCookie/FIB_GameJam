extends Node3D
class_name Bubble3D

@onready var dialogue_label: Label = $SubViewport/VBoxContainer/DialogueLabel
@onready var character_label: Label = $SubViewport/VBoxContainer/CharacterLabel

@export var bubble_lifetime: float = 5.0

signal action_processed(morale_change: Dictionary)
signal bubble_expired(penalty: Dictionary)

var current_impact: Dictionary = {}
var active_timer: SceneTreeTimer = null
var isAlive = false

func _ready() -> void:
	hide_bubble()

func setup_bubble(char_name: String, text: String, impact: Dictionary) -> void:
	character_label.text = char_name
	dialogue_label.text = text
	current_impact = impact
	isAlive = true 
	show()
	
	if has_node("SFX_Popup_Idea"):
		$SFX_Popup_Idea.play()
	
	active_timer = get_tree().create_timer(bubble_lifetime, false)
	await active_timer.timeout
	if is_visible_in_tree():
		var ignore_penalty = {"Moral": -5, "Money": 0}
		bubble_expired.emit(ignore_penalty)
		hide_bubble()



func hide_bubble() -> void:
	isAlive = false
	hide()
	current_impact = {}


func approve_dialogue() -> void:
	if (isAlive == false):
		print("No Approve")
		return
	if current_impact.is_empty(): 
		return
	print("Approve")
	action_processed.emit(current_impact)
	hide_bubble()

func reject_dialogue() -> void:
	if isAlive == false:
		print("No Reject")
		return
	print("Reject")
	
	var zero_impact = {"Moral": 0, "Money": 0}
	action_processed.emit(zero_impact)
	hide_bubble()
