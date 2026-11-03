
extends RichTextLabel


func _ready() -> void:

	bbcode_enabled = false
	scroll_active = true

	if not DayReport.report_changed.is_connected(refresh_report):
		DayReport.report_changed.connect(refresh_report)

	refresh_report()


func refresh_report() -> void:

	text = DayReport.get_report_text()


func _notification(what: int) -> void:

	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if is_inside_tree():
			refresh_report()
