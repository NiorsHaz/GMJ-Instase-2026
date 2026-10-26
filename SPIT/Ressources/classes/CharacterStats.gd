class_name Character extends Resource

@export_category("character_info")
@export var name : String
@export var description : String

@export_category("character-stats")
@export var health : int
@export var stun : int
@export var attack_damage : int
@export var stun_damage :int

@export_category("character-visuals")
@export var portrait : Texture2D
@export var icon : Texture2D
