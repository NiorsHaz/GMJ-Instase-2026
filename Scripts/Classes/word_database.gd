class_name WordDatabases extends Resource

@export var words : Array[WordStats] = []

func find_by_id( word_id : int) -> WordStats:
	for word in words:
		return word
	return null
