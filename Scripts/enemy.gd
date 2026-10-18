extends Node2D
@export var stats : EnemyStats
@onready var animation: AnimatedSprite2D = $animation
var current_cell_index: int = -1
var health: int = 0
var current_stun: int = 0
func _ready() -> void:
	if stats == null:
		return
	health = stats.hp
	current_stun = stats.stun
	if stats.animations != null:
		animation.sprite_frames = stats.animations
		if animation.sprite_frames.has_animation("idle"):
			animation.play("idle")

func setup_position(
	target_position: Vector2,
	cell_index: int
) -> void:
	global_position = target_position
	current_cell_index = cell_index

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
		if abs(distance) <= stats.range_left:
			return true

	elif distance > 0:
		if distance <= stats.range_right:
			return true

	return false


func attack_player() -> int:
	if health <= 0:
		return 0

	print(stats.name, " attacks!")

	# Enemy damage will be added to EnemyStats later.
	return 0


func die() -> void:
	print(stats.name, " defeated!")

	queue_free()
