class_name ObjetStats extends Resource

@export_category("Objet_info")
@export var name : String
@export var description : String

@export_category("object_visual")
@export var icon : Texture2D
@export var animation : SpriteFrames

@export_category("objet_stats")
@export var attack_damage : int
@export var stun_damage : int
@export var healing_point : int
