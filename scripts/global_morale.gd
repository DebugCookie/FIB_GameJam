extends Node3D
class_name GlobalMorale3D

@onready var happiness_bar: ProgressBar = %EmployeeBar
@onready var money_bar: ProgressBar = %WorkBar
@onready var happiness_label: Label = %EmployeeBarLabel
@onready var money_label: Label = %WorkBarLabel

@onready var round_label: Label = %RoundLabel
@onready var time_label: Label = %TimeLabel

func update_morale_display(happiness: int, money: int, quota: int) -> void:
	if not is_node_ready():
		await ready
		
	happiness_bar.value = happiness
	happiness_label.text = "Company Happiness: %d%%" % happiness
	
	money_bar.max_value = quota
	money_bar.value = money
	money_label.text = "Money: $%d / $%d" % [money, quota]

func update_time_and_round(current_day: int, time_left_seconds: float) -> void:
	if not is_node_ready():
		await ready
		
	round_label.text = "Day: %d" % current_day
	
	var minutes: int = int(time_left_seconds) / 60
	var seconds: int = int(time_left_seconds) % 60
	
	time_label.text = "%02d:%02d" % [minutes, seconds]
