extends Node2D

@export var stats : PlayersStats 

@onready var animation: AnimatedSprite2D = $animation

var current_cell_index: int = 0

var facing_direction: int = 1:
	set(value):
		facing_direction = value
		update_facing_visual()


func _ready() -> void:
	if stats != null:
		animation.sprite_frames = stats.animations
		animation.play("idle")

	update_facing_visual()


func flip_direction() -> void:
	facing_direction *= -1

func update_facing_visual() -> void:
	if animation:
		animation.flip_h = facing_direction < 0

func setup_position(target_position: Vector2, initial_direction: int = 1) -> void:
	global_position = target_position
	facing_direction = initial_direction


func move_to(target_position: Vector2, new_index: int) -> void:
	current_cell_index = new_index
	global_position = target_position
