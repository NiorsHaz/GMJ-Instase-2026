class_name WordStats extends Resource

@export_group("word_stats")
@export var damage := 0
@export var stun_damage := 0
@export var name := "Nom d'un mot"
@export var animations : SpriteFrames

@export_group("word_type_state")
@export var type_name := "Nom du type"
@export var desc := "description d'un type de mots"
@export_enum("fire_hit","water_hit","light_hit") var hit_type : int = 0
@export var icon := Texture2D
@export var range := 0
@export var cooldown :=0
