
extends Node2D

@export var stats: EnemyStats

@onready var animation: AnimatedSprite2D = $animation

var current_cell_index: int = -1
var health: int = 0
var current_stun: int = 0


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


func setup_position(target_position: Vector2, cell_index: int) -> void:
	global_position = target_position
	current_cell_index = cell_index


# ----------------------------------------
# ENEMY AI
# ----------------------------------------

func take_turn(grid: Node, player: Node2D) -> void:
	if health <= 0 or not is_instance_valid(player):
		return

	# 1. Skip turn if stunned.
	if current_stun > 0:
		current_stun -= 1
		print(stats.name, " is stunned. Remaining: ", current_stun)
		return

	var player_index = int(player.get("current_cell_index"))

	# 2. Attack if the player is in range.
	if can_attack_player(player_index):
		attack_player(player)
		return

	# 3. Otherwise, move one cell toward the player.
	move_toward_player(grid, player_index)


func move_toward_player(grid: Node, player_index: int) -> void:
	var target_index = current_cell_index

	if player_index < current_cell_index:
		target_index -= 1
	elif player_index > current_cell_index:
		target_index += 1
	else:
		return

	var cells: Array = grid.get("horizontal_grid")

	if target_index < 0 or target_index >= cells.size():
		return

	var target_cell: Dictionary = cells[target_index]

	# Do not enter an occupied cell.
	if target_cell["occupied_by"] != null:
		print(stats.name, " cannot move: cell is occupied.")
		return

	# Free the old cell.
	if current_cell_index >= 0 and current_cell_index < cells.size():
		cells[current_cell_index]["occupied_by"] = null

	# Occupy the new cell.
	target_cell["occupied_by"] = self

	current_cell_index = target_index

	var cell_width = float(grid.get("cell_width"))
	var cell_height = float(grid.get("cell_height"))
	var center = Vector2(cell_width / 2.0, cell_height / 2.0)

	global_position = target_cell["position"] + center

	print(stats.name, " moves to cell ", current_cell_index)


# ----------------------------------------
# COMBAT
# ----------------------------------------

func take_damage(amount: int) -> void:
	if health <= 0:
		return

	health -= amount

	if health < 0:
		health = 0

	print(stats.name, " HP: ", health, "/", stats.hp)

	if health <= 0:
		die()


func apply_stun(amount: int) -> void:
	if health <= 0:
		return

	current_stun += amount
	print(stats.name, " stun: ", current_stun)


func can_attack_player(player_cell_index: int) -> bool:
	var distance = player_cell_index - current_cell_index

	if distance < 0:
		return abs(distance) <= stats.range_left

	if distance > 0:
		return distance <= stats.range_right

	return false


func attack_player(player: Node2D) -> void:
	if health <= 0:
		return

	print(stats.name, " attacks the player for ", stats.damage, " damage!")

	if player.has_method("take_damage"):
		player.call("take_damage", stats.damage)
	else:
		print("Player has no take_damage() method yet.")


func die() -> void:
	print(stats.name, " defeated!")

	queue_free()
