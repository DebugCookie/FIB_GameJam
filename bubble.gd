
extends Node3D
class_name Bubble3D


# ==================================================
# REFERENCES
# ==================================================

@onready var dialogue_label: Label = $SubViewport/VBoxContainer/DialogueLabel
@onready var character_label: Label = $SubViewport/VBoxContainer/CharacterLabel

# The new 3D effect spawn point
@onready var effect_spawn_point: EffectBurst3D = $"../EffectSpawnPoint"


# ==================================================
# SETTINGS
# ==================================================

@export var bubble_lifetime: float = 15.0


# ==================================================
# SIGNALS
# ==================================================

signal action_processed(morale_change: Dictionary)
signal bubble_expired(penalty: Dictionary)
signal feedback_triggered(impact: Dictionary)


# ==================================================
# VARIABLES
# ==================================================

var current_impact: Dictionary = {}
var active_timer: SceneTreeTimer = null

var isAlive: bool = false
var is_showing_feedback: bool = false

var bubble_generation: int = 0


# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:
	hide_bubble()


# ==================================================
# SETUP BUBBLE
# ==================================================

func setup_bubble(char_name: String, text: String, impact: Dictionary) -> void:
	bubble_generation += 1
	var my_generation: int = bubble_generation

	character_label.text = char_name
	dialogue_label.text = text
	current_impact = impact.duplicate()

	isAlive = true
	is_showing_feedback = false

	show()

	# Original popup sound
	if has_node("SFX_Popup_Idea"):
		$SFX_Popup_Idea.play()

	# Start the idea timeout
	active_timer = get_tree().create_timer(
		bubble_lifetime,
		false
	)

	await active_timer.timeout

	# Prevent old timers from affecting new ideas
	if my_generation != bubble_generation:
		return

	if isAlive and not is_showing_feedback:
		var ignore_penalty: Dictionary = {
			"Moral": -5,
			"Money": 0
		}

		is_showing_feedback = true

		# First hide the speech bubble
		hide_bubble()

		# Then spawn 3D icons in front of the character
		effect_spawn_point.play_effect(ignore_penalty)

		# Original sound/event
		feedback_triggered.emit(ignore_penalty)

		# Original timeout penalty
		bubble_expired.emit(ignore_penalty)


# ==================================================
# HIDE BUBBLE
# ==================================================

func hide_bubble() -> void:
	isAlive = false
	is_showing_feedback = false

	hide()

	current_impact = {}


# ==================================================
# CLEAR TEXT
# ==================================================

func clear_text_labels() -> void:
	character_label.text = ""
	dialogue_label.text = ""


# ==================================================
# APPROVE IDEA
# ==================================================

func approve_dialogue() -> void:
	if not isAlive or is_showing_feedback:
		return

	if current_impact.is_empty():
		return

	print("Approve")

	var approved_impact: Dictionary = current_impact.duplicate()

	is_showing_feedback = true

	# 1. Hide speech bubble immediately
	hide_bubble()

	# 2. Spawn 3D feedback icons
	effect_spawn_point.play_effect(approved_impact)

	# 3. Trigger original sound/event
	feedback_triggered.emit(approved_impact)

	# 4. Apply money and morale changes
	action_processed.emit(approved_impact)


# ==================================================
# REJECT IDEA
# ==================================================

func reject_dialogue() -> void:
	if not isAlive or is_showing_feedback:
		return

	print("Reject")

	var zero_impact: Dictionary = {
		"Moral": 0,
		"Money": 0
	}

	is_showing_feedback = true

	# 1. Hide speech bubble immediately
	hide_bubble()

	# 2. Spawn three neutral icons
	effect_spawn_point.play_effect(zero_impact)

	# 3. Process rejected idea
	action_processed.emit(zero_impact)
