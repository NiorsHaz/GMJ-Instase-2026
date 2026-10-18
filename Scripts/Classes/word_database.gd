class_name WordDatabases extends Resource

@export var words : Array[WordStats] = []

func find_by_id(word_id : int) -> WordStats:
	for word in words:
		if word != null and word.id == word_id:
			return word
	return null

func find_all() -> Array[WordStats]:
	var result: Array[WordStats] = []
	for word in words:
		if word != null:
			result.append(word)
	return result
