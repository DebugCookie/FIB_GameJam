extends Node

var employee_morale: int = 50
var work_morale: int = 50

const DIALOGUE_FILE_PATH = "Json/dialogue.json"

func _ready() -> void:
	print("=== STARTAR VERIFIERING AV ALLA HELPERS ===\n")
	
	var manager = DialogueManager.new()
	
	if not manager.load_dialogue_file(DIALOGUE_FILE_PATH):
		print("Fel: Kunde inte ladda filen från: ", DIALOGUE_FILE_PATH)
		return
	print(" load_dialogue_file() fungerar.\n")
	
	var categories = manager.get_category_names()
	print(" get_category_names(): ", categories)
	if categories.is_empty():
		print("Avbryter testet: Inga kategorier hittades.")
		return
		
	var test_cat = categories[0]
	print("Använder kategorin '%s' för resterande tester...\n" % test_cat)
	
	var cat_data = manager.get_category_data(test_cat)
	print(" get_category_data(): Hittade %d objekt." % cat_data.size())
	
	var all_texts = manager.get_all_texts_in_category(test_cat)
	print(" get_all_texts_in_category(): ", all_texts)
	
	var total_weight = manager.get_total_weight(test_cat)
	print(" get_total_weight(): Total vikt är ", total_weight)
	print("")
	
	print("--- Testar index-helpers (Index 0) ---")
	
	var item = manager.get_item_at_index(test_cat, 0)
	print(" get_item_at_index(): ", item)
	
	var text_at = manager.get_text_at_index(test_cat, 0)
	print(" get_text_at_index(): '", text_at, "'")
	
	var weight_at = manager.get_weight_at_index(test_cat, 0)
	print(" get_weight_at_index(): ", weight_at)
	
	var impact = manager.get_morale_impact_at_index(test_cat, 0)
	print(" get_morale_impact_at_index(): ", impact)
	
	var emp_change = manager.get_employee_morale_change(test_cat, 0)
	var wrk_change = manager.get_work_morale_change(test_cat, 0)
	print(" get_employee_morale_change(): ", emp_change)
	print(" get_work_morale_change(): ", wrk_change)
	print("")
	
	print("--- Testar slumpnings-helpers ---")
	
	var rand_text = manager.get_weighted_text(test_cat)
	print(" get_weighted_text() rullade: '", rand_text, "'")
	
	var rand_item = manager.roll_weighted_item(test_cat)
	print(" roll_weighted_item() rullade hela blocket: ", rand_item)
	
	print("\n=== ALLA HELPERS HAR TESTATS ===")
