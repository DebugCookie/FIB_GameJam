
extends ColorRect
class_name Credits


@onready var back_button: Button = $BackButton

const MAIN_MENU_PATH = "res://main_menu.tscn"


func _ready() -> void:
	get_tree().paused = false

	back_button.pressed.connect(_on_back_pressed)

	# Automatically connect all CreditsLinks labels
	for child in get_children():
		if child is RichTextLabel and child.name.begins_with("CreditsLinks"):
			var credits_label: RichTextLabel = child

			credits_label.bbcode_enabled = true
			credits_label.meta_clicked.connect(_on_link_clicked)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_link_clicked(meta: Variant) -> void:
	var url: String = str(meta).strip_edges()

	# Allow LinkedIn and GitHub profile links
	if url.begins_with("https://www.linkedin.com/") \
	or url.begins_with("https://linkedin.com/") \
	or url.begins_with("https://github.com/") \
	or url.begins_with("https://www.github.com/"):

		# Minimize the game
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_MINIMIZED
		)

		# Open link in default browser
		OS.shell_open(url)
