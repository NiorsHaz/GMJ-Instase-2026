class_name Bookstats
extends Resource

@export var id: int = 0

@export_group("book_stats")
@export var name: String = "Test"
@export var hit_bonus: int = 0
@export var stun_bonus: int = 0
@export var desc: String = "Test de description"
@export var animations: SpriteFrames
@export var icons: Texture2D
@export var selling_price : int = 0
@export var buying_price : int = 0

@export_group("book_words")
@export var word_database: WordDatabases
@export var word_ids: Array[int] = []


func get_words() -> Array[WordStats]:
	var result: Array[WordStats] = []

	if word_database == null:
		return result

	for word_id in word_ids:
		var word = word_database.find_by_id(word_id)

		if word != null:
			result.append(word)

	return result


@export_group("type_book_stats")
@export var book_type_id: int = 0
@export var book_type_name: String = "Test"
@export var book_type_desc: String = "Test de description"
@export var res_fire: int = 0
@export var res_light: int = 0
@export var res_water: int = 0
