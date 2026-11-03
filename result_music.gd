
extends AudioStreamPlayer2D

# Optional: assign the UI node that is actually
# shown and hidden by GameUI.
@export var visibility_target: Control

var result_screen: Control


func _ready() -> void:
	autoplay = false

	# Use the assigned target, or the parent screen.
	result_screen = visibility_target

	if result_screen == null:
		result_screen = get_parent() as Control

	if result_screen == null:
		push_error("MUSIC: No valid Control node found.")
		return

	result_screen.visibility_changed.connect(update_music)
	update_music()


func update_music() -> void:
	if not is_instance_valid(result_screen):
		return

	if result_screen.is_visible_in_tree():
		if not playing:
			play()
	else:
		if playing:
			stop()
