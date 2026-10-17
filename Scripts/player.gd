extends Node2D
var current_cell_index: int = 0
var facing_direction: int = 1:
	set(value):
		facing_direction = value
		update_facing_visual()
@onready var eye_marker: ColorRect = $EyeMarker
func flip_direction() -> void:
	facing_direction *= -1
	
func setup_position(target_position: Vector2, initial_direction: int = 1) -> void:
	global_position = target_position
	facing_direction = initial_direction
	
func move_to(target_position: Vector2, new_index: int) -> void:
	current_cell_index = new_index
	global_position = target_position
	
func update_facing_visual() -> void:
	scale.x = facing_direction
