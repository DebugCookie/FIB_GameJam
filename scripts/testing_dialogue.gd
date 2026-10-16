class_name DialogueManager
extends Node

var dialogue_data: Dictionary = {}

func load_dialogue_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		printerr("Hittade inte filen: ", file_path)
		return false
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) == OK:
		dialogue_data = json.data
		return true
	return false

func get_category_data(category: String) -> Array:
	return dialogue_data.get(category, [])

func get_all_texts_in_category(category: String) -> Array[String]:
	var texts: Array[String] = []
	for item in get_category_data(category):
		texts.append(item.get("text", ""))
	return texts

func get_item_at_index(category: String, index: int) -> Dictionary:
	var items = get_category_data(category)
	if index >= 0 and index < items.size():
		return items[index]
	printerr("Index ", index, " är utanför listans storlek i kategorin: ", category)
	return {}

func get_text_at_index(category: String, index: int) -> String:
	return get_item_at_index(category, index).get("text", "")

func get_weight_at_index(category: String, index: int) -> int:
	return int(get_item_at_index(category, index).get("weight", 0))

func get_total_weight(category: String) -> int:
	var total: int = 0
	for item in get_category_data(category):
		total += int(item.get("weight", 0))
	return total

func get_category_names() -> Array:
	return dialogue_data.keys()

func get_weighted_text(category: String) -> String:
	var items = get_category_data(category)
	var total_weight = get_total_weight(category)
	if total_weight == 0: return ""
	
	var random_roll = randi() % total_weight
	var current_sum = 0
	for item in items:
		current_sum += int(item.get("weight", 0))
		if random_roll < current_sum:
			return item.get("text", "")
	return ""

func roll_weighted_item(category: String) -> Dictionary:
	var items = get_category_data(category)
	var total_weight = get_total_weight(category)
	if total_weight == 0: return {}
	
	var random_roll = randi() % total_weight
	var current_sum = 0
	for item in items:
		current_sum += int(item.get("weight", 0))
		if random_roll < current_sum:
			return item
	return {}
	

func get_morale_impact_at_index(category: String, index: int) -> Dictionary:
	var item = get_item_at_index(category, index)
	return item.get("morale_impact", {"employee": 0, "work": 0})

func get_employee_morale_change(category: String, index: int) -> int:
	return int(get_morale_impact_at_index(category, index).get("employee", 0))

func get_work_morale_change(category: String, index: int) -> int:
	return int(get_morale_impact_at_index(category, index).get("work", 0))
