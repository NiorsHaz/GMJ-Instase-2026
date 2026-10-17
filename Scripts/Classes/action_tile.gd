class_name ActionTile extends RefCounted
var tile_name: String
var tile_color: Color
var damage: int
var range_distance: int
var cooldown_max: int
var current_cooldown: int = 0

func _init(p_name: String,p_color: Color,p_damage: int,p_range: int,p_cooldown: int) -> void:
	tile_name = p_name
	tile_color = p_color
	damage = p_damage
	range_distance = p_range
	cooldown_max = p_cooldown
	current_cooldown = 0

func start_cooldown() -> void:
	current_cooldown = cooldown_max

func tick_cooldown() -> bool:
	if current_cooldown > 0:
		current_cooldown -= 1
		if current_cooldown == 0:
			return true
	return false
