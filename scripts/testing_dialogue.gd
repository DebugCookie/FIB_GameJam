extends Node

const FILE_PATH = "Json/dialogue.json"

func _ready():
	if not FileAccess.file_exists(FILE_PATH):
		print("Error: file not found at: ", FILE_PATH)
		return

	var file = FileAccess.open(FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)

	if error == OK:
		var data = json.data
		print("JSON-file found with weights!\n")
		
		# 1. Hämta och skriv ut Pro-Employee
		if data.has("pro_employee"):
			print("--- PRO EMPLOYEE SENTENCES ---")
			for item in data["pro_employee"]:

				var sentence_text = item["text"]
				var sentence_weight = item["weight"]
				print("- Text: \"", sentence_text, "\" [Vikt: ", sentence_weight, "]")
				
		print("") # Tom rad
		
		if data.has("pro_company"):
			print("--- PRO COMPANY SENTENCES ---")
			for item in data["pro_company"]:
				var sentence_text = item["text"]
				var sentence_weight = item["weight"]
				print("- Text: \"", sentence_text, "\" [Vikt: ", sentence_weight, "]")
	else:
		print("Json error: ", json.get_error_message())
