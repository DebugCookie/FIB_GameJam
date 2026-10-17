extends Node3D
class_name GlobalMorale3D

@onready var employee_bar: ProgressBar = $SubViewport/VBoxContainer/EmployeeBar
@onready var work_bar: ProgressBar = $SubViewport/VBoxContainer/WorkBar
@onready var employee_label: Label = $SubViewport/VBoxContainer/EmployeeBarLabel
@onready var work_label: Label = $SubViewport/VBoxContainer/WorkBarLabel

func update_morale_display(emp_morale: int, wrk_morale: int) -> void:
	employee_bar.value = emp_morale
	work_bar.value = wrk_morale
	employee_label.text = "Morale: %d%%" % emp_morale
	work_label.text = "Money: %d%%" % wrk_morale
