
extends Node

signal report_changed

var current_day: int = 1
var approved_ideas: Array[Dictionary] = []
var accepting_ideas: bool = false


# ==========================================
# START NEW DAY
# ==========================================

func start_day(day_number: int) -> void:
	current_day = day_number
	approved_ideas.clear()
	accepting_ideas = true
	report_changed.emit()


# ==========================================
# RECORD AN APPROVED IDEA
# ==========================================

func record_approval(
	idea_text: String,
	impact: Dictionary
) -> void:

	if not accepting_ideas:
		return

	approved_ideas.append({
		"text": idea_text,
		"Money": int(impact.get("Money", 0)),
		"Moral": int(impact.get("Moral", 0))
	})

	report_changed.emit()


# ==========================================
# END DAY
# ==========================================

func finish_day() -> void:
	accepting_ideas = false
	report_changed.emit()


# ==========================================
# NUMBER FORMATTING
# ==========================================

func format_effect(value: int) -> String:
	if value > 0:
		return "+" + str(value)

	return str(value)


# ==========================================
# GENERATE REPORT
# ==========================================

func get_report_text() -> String:

	var lines: PackedStringArray = []

	lines.append(
		"DAY %d - APPROVED IDEAS" % current_day
	)
	lines.append("")

	if approved_ideas.is_empty():
		lines.append("No ideas approved today.")
		return "\n".join(lines)

	var total_money: int = 0
	var total_morale: int = 0

	for i in range(approved_ideas.size()):

		var idea: Dictionary = approved_ideas[i]

		var money: int = int(idea.get("Money", 0))
		var morale: int = int(idea.get("Moral", 0))
		var idea_text: String = str(idea.get("text", ""))

		total_money += money
		total_morale += morale

		lines.append(
			"%d. \"%s\"" % [i + 1, idea_text]
		)

		lines.append(
			"Profit: %s $" % format_effect(money)
		)

		lines.append(
			"Employee Morale: %s%%" % format_effect(morale)
		)

		lines.append("")

	lines.append("------------------------")
	lines.append("TOTAL APPROVED EFFECTS")

	lines.append(
		"Profit: %s $" % format_effect(total_money)
	)

	lines.append(
		"Employee Morale: %s%%" % format_effect(total_morale)
	)

	return "\n".join(lines)
