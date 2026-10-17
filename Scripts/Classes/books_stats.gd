class_name Bookstats extends Resource

@export var id := 0
@export_group("book_stats")
@export var name := "Test"
@export var hit_bonus := 0
@export var stun_bonus := 0
@export var desc := "Test de description"
@export var animations : SpriteFrames
@export var icons : Texture2D 
@export var word_stats : Array[WordStats] 

@export_group("type_book_stats")
@export var book_type_id := 0
@export var book_type_name := "Test"
@export var book_type_desc := "Test de description"
@export var res_fire := 0
@export var res_light := 0
@export var res_water := 0
