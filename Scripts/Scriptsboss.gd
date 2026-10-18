extends Node2D
@export var stats: EnemyStats
@export var boss_size: int = 2
@onready var animation: AnimatedSprite2D = get_node_or_null("animation")
var current_cell_index: int = -1
var health: int = 10
var current_stun: int = 0
var facing_direction: int = -1:
	set(value):
		facing_direction = value
		update_facing_visual()
var planned_action: String = "NONE"
var planned_attack_type: String = "ATTACK_QUICK"

func _ready() -> void:
	if stats == null:
		push_warning("BossStats n'est pas assigné. Utilisation des stats par défaut.")
		health = 20
	else:
		health = stats.hp
		current_stun = stats.stun
		if stats.animations != null and animation != null:
			animation.sprite_frames = stats.animations
			if animation.sprite_frames.has_animation("idle"):
				animation.play("idle")
	update_facing_visual()
	print(stats.name if stats else "Boss", " initialisé avec ", health, " PV.")

func update_facing_visual() -> void:
	if animation:
		animation.flip_h = (facing_direction < 0)

func setup_position(target_position: Vector2, start_cell_index: int, grid_cells_count: int) -> void:
	current_cell_index = start_cell_index
	if current_cell_index + boss_size > grid_cells_count:
		current_cell_index = grid_cells_count - boss_size
	global_position = target_position
	print("Boss positionné à l'index : ", current_cell_index)

func execute_prepared_action(grid: Node, player: Node2D) -> void:
	if health <= 0 or not is_instance_valid(player):
		print("Boss : Action ignorée (mort ou joueur invalide).")
		return
	if current_stun > 0:
		current_stun -= 1
		print(stats.name if stats else "Boss", " est étourdi !")
		return
	print("Boss exécute l'action préparée : ", planned_action)
	match planned_action:
		"TURN":
			facing_direction = -facing_direction
			print("Le Boss se retourne ! Nouvelle direction : ", facing_direction)
		"ATTACK":
			execute_boss_attack(player, planned_attack_type)
		"MOVE":
			var player_index = int(player.get("current_cell_index"))
			move_toward_player(grid, player_index)

func plan_next_action(player: Node2D) -> void:
	if health <= 0 or not is_instance_valid(player):
		planned_action = "NONE"
		return
	var player_index = int(player.get("current_cell_index"))
	var target_facing = 1 if player_index > current_cell_index else -1
	if facing_direction != target_facing and not is_player_in_boss_range(player_index):
		planned_action = "TURN"
		print("Boss planifie : TURN")
		return
	if can_attack_player(player_index):
		planned_action = "ATTACK"
		var attacks = ["ATTACK_QUICK", "ATTACK_HEAVY", "ATTACK_AREA"]
		planned_attack_type = attacks[randi() % attacks.size()]
		print("Boss planifie : ATTACK (", planned_attack_type, ")")
		return
	planned_action = "MOVE"
	print("Boss planifie : MOVE")

func execute_boss_attack(player: Node2D, attack_type: String) -> void:
	var player_index = int(player.get("current_cell_index"))
	var base_dmg = stats.damage if (stats != null and "damage" in stats) else 2
	match attack_type:
		"ATTACK_QUICK":
			print("Boss utilise Tir Rapide (Portée 1-2) !")
			if is_player_in_range(player_index, 2):
				player.call("take_damage", base_dmg)
				print("-> Le joueur subit ", base_dmg, " dégâts.")
		"ATTACK_HEAVY":
			print("Boss utilise Canon Lourd (Portée 3) !")
			if is_player_in_range(player_index, 3):
				player.call("take_damage", base_dmg * 2)
				print("-> Le joueur subit ", base_dmg * 2, " dégâts lourds !")
		"ATTACK_AREA":
			print("Boss utilise Onde de Choc Globale !")
			if abs(player_index - current_cell_index) <= boss_size + 2:
				player.call("take_damage", base_dmg + 1)
				print("-> Le joueur est touché par l'onde de choc à distance.")

func is_player_in_range(player_index: int, max_range: int) -> bool:
	var boss_left = current_cell_index
	var boss_right = current_cell_index + boss_size - 1
	var distance_left = boss_left - player_index
	var distance_right = player_index - boss_right
	if facing_direction == -1 and distance_left > 0 and distance_left <= max_range:
		return true
	if facing_direction == 1 and distance_right > 0 and distance_right <= max_range:
		return true
	return false

func can_attack_player(player_cell_index: int) -> bool:
	return is_player_in_range(player_cell_index, 2)

func is_player_in_boss_range(player_index: int) -> bool:
	return player_index >= current_cell_index and player_index < current_cell_index + boss_size

func move_toward_player(grid: Node, _player_index: int) -> void:
	var next_index = current_cell_index + facing_direction
	var cells: Array = grid.get("horizontal_grid")
	if next_index < 0 or next_index + boss_size > cells.size():
		print("Boss bloqué : bord de grille atteint.")
		return
	var target_cell = cells[next_index if facing_direction < 0 else next_index + boss_size - 1]
	if target_cell["occupied_by"] != null and target_cell["occupied_by"] != self:
		print("Boss bloqué par un occupant sur la case : ", target_cell["index"])
		return
	for i in range(boss_size):
		var old_idx = current_cell_index + i
		if old_idx >= 0 and old_idx < cells.size():
			cells[old_idx]["occupied_by"] = null
	current_cell_index = next_index
	for i in range(boss_size):
		var new_idx = current_cell_index + i
		cells[new_idx]["occupied_by"] = self
	var cell_width = float(grid.get("cell_width"))
	var actor_offset = Vector2((cell_width * boss_size) / 2.0, -10)
	global_position = cells[current_cell_index]["position"] + actor_offset
	print("Boss s'est déplacé vers la case index : ", current_cell_index)

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	if health < 0:
		health = 0
	print("Boss subit ", amount, " dégâts. PV restants : ", health)
	if health <= 0:
		die()

func die() -> void:
	print("Boss vaincu ! VICTOIRE !")
	queue_free()
