extends ColorRect
class_name DayWinScreen

@onready var congrats_label: Label = %CongratsLabel
@onready var next_day_button: Button = %NextDayButton

signal next_day_requested

func _ready() -> void:
	next_day_button.pressed.connect(func(): next_day_requested.emit())

func setup_screen(money_earned: int, target_quota: int) -> void:
	congrats_label.text = "Bra jobbat! Du fick ihop $%d av målet på $%d." % [money_earned, target_quota]
