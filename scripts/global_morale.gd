extends Node3D
class_name GlobalMorale3D

@onready var happiness_bar: ProgressBar = %EmployeeBar
@onready var money_bar: ProgressBar = %WorkBar
@onready var happiness_label: Label = %EmployeeBarLabel
@onready var money_label: Label = %WorkBarLabel

@onready var round_label: Label = %RoundLabel
@onready var time_label: Label = %TimeLabel

func update_morale_display(happiness: int, money: int) -> void:
	happiness_bar.value = happiness
	money_bar.value = money
	happiness_label.text = "Company Happiness: %d%%" % happiness
	money_label.text = "Money: $%d" % money

func update_time_and_round(current_day: int, time_left_seconds: float) -> void:
	round_label.text = "DAG: %d" % current_day
	
	var minutes: int = int(time_left_seconds) / 60
	var seconds: int = int(time_left_seconds) % 60
	
	time_label.text = "TID: %02d:%02d" % [minutes, seconds]
