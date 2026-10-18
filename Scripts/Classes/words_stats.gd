
class_name WordStats
extends Resource

@export var id: int = 0

@export_group("word_stats")
@export var damage: int = 0
@export var stun_damage: int = 0
@export var name: String = "Nom d'un mot"
@export var animations: SpriteFrames
@export var icon: Texture2D

@export_group("word_type_stats")
@export var type_name: String = "Nom du type"
@export var desc: String = "Description d'un type de mots"

@export_enum("fire_hit", "water_hit", "light_hit")
var hit_type: int = 0

@export_group("word_combat_stats")
@export var range: int = 0
@export var cooldown: int = 0
