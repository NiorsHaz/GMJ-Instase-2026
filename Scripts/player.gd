extends Node2D
@export var stats: PlayersStats 
@onready var animation: AnimatedSprite2D = $animation
var current_cell_index: int = 0
var health: int = 10
var facing_direction: int = 1:
	set(value):
		facing_direction = value
		update_facing_visual()
var is_invulnerable_this_turn: bool = false

func _ready() -> void:
	if stats != null:
		health = stats.pv
		if stats.animations != null:
			animation.sprite_frames = stats.animations
			animation.play("idle")
	update_facing_visual()

func flip_direction() -> void:
	facing_direction = -facing_direction

func update_facing_visual() -> void:
	if animation:
		animation.flip_h = (facing_direction < 0)

func setup_position(target_position: Vector2, new_index: int = -1) -> void:
	global_position = target_position
	if new_index >= 0:
		current_cell_index = new_index

func move_to(target_position: Vector2, new_index: int) -> void:
	current_cell_index = new_index
	global_position = target_position


func take_damage(amount: int) -> void:
	if is_invulnerable_this_turn:
		print("Dégâts annulés : swap")
		return
	health -= amount
	if health < 0:
		health = 0
	print("Player HP: ", health)
	if health <= 0:
		print("Player defeated!")
		return
	if animation == null or animation.sprite_frames == null:
		return
	if animation.sprite_frames.has_animation("hurt"):
		animation.play("hurt")
		await animation.animation_finished
	if is_instance_valid(animation) and health > 0:
		if animation.sprite_frames.has_animation("idle"):
			animation.play("idle")
