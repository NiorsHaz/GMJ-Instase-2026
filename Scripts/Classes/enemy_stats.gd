
class_name EnemyStats
extends Resource

@export_group("enemy_stats")
@export var name: String = "Enemy"
@export var desc: String = "Enemy description"
@export var hp: int = 10
@export var stun: int = 0
@export var icon: Texture2D
@export var range_left: int = 1
@export var range_right: int = 1
@export var animations: SpriteFrames

@export_group("enemy_type_stats")
@export var type_name: String = "Enemy type"
@export var type_desc: String = "Enemy type description"
@export_enum("res_fire", "res_light", "res_water")
var res: int = 0

@export_enum("fire_hit", "water_hit", "light_hit")
var hit_type: int = 0

@export var enemy_type_icon: Texture2D
