class_name EnemyStats extends Resource

@export_group("enemy_stats")
@export var name := "name"
@export var desc := "Enemy description"
@export var hp := 0
@export var stun := 0
@export var icon : Texture2D
@export var range_left := 0
@export var range_right := 0
@export var animations := SpriteFrames

@export_group("enemy_type_stats")
@export var type_name := "enemy type name"
@export var type_desc := "enemy type description "
@export_enum("res_fire","res_light","res_water") var res : int = 0
@export_enum("fire_hit","water_hit","light_hit") var hit_type : int = 0
@export var enemy_type_icon : Texture2D
