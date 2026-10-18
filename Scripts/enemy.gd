extends Node2D
@export var stats: EnemyStats
@onready var animation: AnimatedSprite2D = $animation
var current_cell_index: int = -1
var health: int = 0
var current_stun: int = 0
var facing_direction: int = 1:
	set(value):
		facing_direction = value
		update_facing_visual()
var planned_action: String = "NONE"

func _ready() -> void:
	if stats == null:
		push_warning("EnemyStats has not been assigned to this enemy.")
		return
	health = stats.hp
	current_stun = stats.stun
	if stats.animations != null:
		animation.sprite_frames = stats.animations
		if animation.sprite_frames.has_animation("idle"):
			animation.play("idle")
	update_facing_visual()

func update_facing_visual() -> void:
	if animation:
		animation.flip_h = (facing_direction > 0)

func setup_position(target_position: Vector2, cell_index: int, _grid_size: int = 0) -> void:
	global_position = Vector2(target_position.x, target_position.y)
	current_cell_index = cell_index

func execute_prepared_action(grid: Node, player: Node2D) -> void:
	if health <= 0 or not is_instance_valid(player):
		return
	if current_stun > 0:
		current_stun -= 1
		print(stats.name, " est étourdi !")
		return
	match planned_action:
		"TURN":
			facing_direction = -facing_direction
			print(stats.name, " se retourne !")
		"ATTACK":
			print(stats.name, " attaque à distance !")
			if player.has_method("take_damage"):
				var player_index = int(player.get("current_cell_index"))
				var offset = player_index - current_cell_index
				var is_in_front = (facing_direction == 1 and offset > 0) or (facing_direction == -1 and offset < 0)
				var distance = abs(offset)
				var max_range = stats.range_right if facing_direction == 1 else stats.range_left
				if is_in_front and distance <= max_range:
					var dmg = stats.damage if "damage" in stats else 1
					player.call("take_damage", dmg)
					print("Touché ! Le joueur subit ", dmg, " dégâts à distance.")
				else:
					print("L'ennemi a frappé dans le vide (joueur hors de portée).")
		"MOVE":
			var player_index = int(player.get("current_cell_index"))
			move_toward_player(grid, player_index)

func plan_next_action(player: Node2D) -> void:
	if health <= 0 or not is_instance_valid(player):
		planned_action = "NONE"
		return
	var player_index = int(player.get("current_cell_index"))
	var target_facing = 1 if player_index > current_cell_index else -1
	if facing_direction != target_facing:
		planned_action = "TURN"
		print(stats.name, " prépare de se retourner au prochain tour.")
		return
	if can_attack_player(player_index):
		planned_action = "ATTACK"
		print(stats.name, " prépare une attaque !")
		return
	planned_action = "MOVE"
	print(stats.name, " prépare d'avancer.")

func move_toward_player(grid: Node, player_index: int) -> void:
	var target_index = current_cell_index + facing_direction
	var cells: Array = grid.get("horizontal_grid")
	if target_index < 0 or target_index >= cells.size():
		return
	var target_cell: Dictionary = cells[target_index]
	if target_cell["occupied_by"] != null:
		print(stats.name, " ne peut pas avancer (case occupée).")
		return
	if current_cell_index >= 0 and current_cell_index < cells.size():
		cells[current_cell_index]["occupied_by"] = null
	target_cell["occupied_by"] = self
	current_cell_index = target_index
	global_position = grid.call("get_actor_position", target_index)
	#var cell_width = float(grid.get("cell_width"))
	#var cell_height = float(grid.get("cell_height"))
	#var actor_offset = Vector2(cell_width / 2.0, -10)
	#global_position = target_cell["position"] + actor_offset

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	if health < 0:
		health = 0
	print(stats.name, " HP: ", health, "/", stats.hp)
	if health <= 0:
		die()
		return
	if animation.sprite_frames.has_animation("hurt"):
		animation.play("hurt")
		await animation.animation_finished
	if health > 0 and animation.sprite_frames.has_animation("idle"):
		animation.play("idle")

func can_attack_player(player_cell_index: int) -> bool:
	var distance = player_cell_index - current_cell_index
	if distance < 0 and facing_direction == -1:
		return abs(distance) <= stats.range_left
	if distance > 0 and facing_direction == 1:
		return distance <= stats.range_right
	return false

func die() -> void:
	print(stats.name, " est vaincu !")
	queue_free()
