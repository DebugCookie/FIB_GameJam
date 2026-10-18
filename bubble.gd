extends Node3D
class_name Bubble3D

@onready var dialogue_label: Label = $SubViewport/VBoxContainer/DialogueLabel
@onready var character_label: Label = $SubViewport/VBoxContainer/CharacterLabel

# Referenser till dina 4 dolda sprites/ikoner
@onready var moral_pos_icon: TextureRect = %MoralPosIcon
@onready var moral_neg_icon: TextureRect = %MoralMinusIcon
@onready var money_pos_icon: TextureRect = %MoneyPosIcon
@onready var money_neg_icon: TextureRect = %MoneyMinusIcon

@export var bubble_lifetime: float = 5.0
@export var feedback_duration: float = 0.8 

signal action_processed(morale_change: Dictionary)
signal bubble_expired(penalty: Dictionary)
signal feedback_triggered(impact: Dictionary) 

var current_impact: Dictionary = {}
var active_timer: SceneTreeTimer = null
var isAlive: bool = false
var is_showing_feedback: bool = false 

func _ready() -> void:
	hide_bubble()

func setup_bubble(char_name: String, text: String, impact: Dictionary) -> void:
	character_label.text = char_name
	dialogue_label.text = text
	current_impact = impact
	isAlive = true 
	is_showing_feedback = false
	reset_icons()
	show()
	
	if has_node("SFX_Popup_Idea"):
		$SFX_Popup_Idea.play()
	
	active_timer = get_tree().create_timer(bubble_lifetime, false)
	await active_timer.timeout
	
	if is_visible_in_tree() and isAlive and not is_showing_feedback:
		var ignore_penalty = {"Moral": -5, "Money": 0}
		
		is_showing_feedback = true
		clear_text_labels()
		if moral_neg_icon: moral_neg_icon.show()
		
		# NYTT: Trigga straffljudet direkt när minus-ikonen visas på skärmen
		feedback_triggered.emit(ignore_penalty)
		
		await get_tree().create_timer(feedback_duration, false).timeout
		
		bubble_expired.emit(ignore_penalty)
		hide_bubble()

func hide_bubble() -> void:
	isAlive = false
	is_showing_feedback = false
	hide()
	reset_icons()
	current_impact = {}

func clear_text_labels() -> void:
	character_label.text = ""
	dialogue_label.text = ""

func reset_icons() -> void:
	if moral_pos_icon: moral_pos_icon.hide()
	if moral_neg_icon: moral_neg_icon.hide()
	if money_pos_icon: money_pos_icon.hide()
	if money_neg_icon: money_neg_icon.hide()

func show_visual_feedback(impact: Dictionary) -> void:
	is_showing_feedback = true
	clear_text_labels() 
	reset_icons()
	
	var moral_val = int(impact.get("Moral", 0))
	var money_val = int(impact.get("Money", 0))
	
	if moral_val > 0:
		moral_pos_icon.show()
	elif moral_val < 0:
		moral_neg_icon.show()
		
	if money_val > 0:
		money_pos_icon.show()
	elif money_val < 0:
		money_neg_icon.show()

func approve_dialogue() -> void:
	if not isAlive or is_showing_feedback: return
	if current_impact.is_empty(): return
	print("Approve")
	
	show_visual_feedback(current_impact)
	
	feedback_triggered.emit(current_impact)
	
	await get_tree().create_timer(feedback_duration, false).timeout
	
	action_processed.emit(current_impact)
	hide_bubble()

func reject_dialogue() -> void:
	if not isAlive or is_showing_feedback: return
	
	var zero_impact = {"Moral": 0, "Money": 0}
	action_processed.emit(zero_impact)
	hide_bubble()
