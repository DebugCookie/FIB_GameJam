extends Label3D

@export var laptop_ui: Node3D

var source_label: Label


func _ready() -> void:
	if not is_instance_valid(laptop_ui):
		push_error("CLOCK: Assign GlobalMorale3D in Inspector.")
		return

	source_label = laptop_ui.get_node_or_null(
		"SubViewport/VBoxContainer/TimeLabel"
	) as Label

	if source_label == null:
		push_error("CLOCK: Original TimeLabel not found.")


func _process(_delta: float) -> void:
	if is_instance_valid(source_label):
		text = source_label.text
