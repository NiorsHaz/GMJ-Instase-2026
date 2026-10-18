extends Node2D
@export var cell_count: int = 6
@export var cell_width: int = 82
@export var cell_height: int = 32
@export var start_ratio: Vector2 = Vector2(0.3, 0.8)
var start_position: Vector2

var books: Bookstats

const PLAYER_SCENE = preload("res://Scene/player.tscn")
const ENEMY_SCENE = preload("res://Scene/Enemy/enemy.tscn")
const BOSS_SCENE = preload("res://Scene/boss.tscn")

var horizontal_grid: Array = []
var player_instance: Node2D = null
var enemy_instance: Node2D = null
var enemies: Array = []
var player_hand: Array[ActionTile] = []
var action_queue: Array[ActionTile] = []
var cooldown_list: Array[ActionTile] = []
const TILE_WIDTH = 60
const TILE_HEIGHT = 80
const TILE_SPACING = 70
const HAND_POS = Vector2(100, 400)
const QUEUE_POS = Vector2(100, 540)
const COOLDOWN_POS = Vector2(500, 400)

func _ready() -> void:
	_update_start_position()
	get_viewport().size_changed.connect(_update_start_position)
	
	generate_grid()
	spawn_player()
	# spawn_enemy()
	spawn_enemies(3)
	#spawn_boss()
	setup_deck()
	if is_instance_valid(enemy_instance):
		enemy_instance.call("plan_next_action", player_instance)

func _update_start_position() -> void:
	start_position = get_viewport().get_visible_rect().size * start_ratio

func generate_grid() -> void:
	horizontal_grid.clear()
	for i in range(cell_count):
		var cell_pos = start_position + Vector2(i * cell_width, 0)
		horizontal_grid.append({
			"id": "col_" + str(i),
			"position": cell_pos,
			"index": i,
			"occupied_by": null
		})

func spawn_player() -> void:
	if horizontal_grid.is_empty():
		return
	if PLAYER_SCENE == null:
		return
	player_instance = PLAYER_SCENE.instantiate()
	if player_instance == null:
		return
	add_child(player_instance)
	player_instance.z_index = 10
	var player_stats = player_instance.get("stats")
	if player_stats != null:
		books = player_stats.get("book")
	player_instance.z_index = 10
	var first_cell = horizontal_grid[0]
	var actor_offset = Vector2(cell_width / 2.0, -10)
	player_instance.call("setup_position", first_cell["position"] + actor_offset, 0)
	first_cell["occupied_by"] = player_instance

func spawn_enemy() -> void:
	if horizontal_grid.size() < 2:
		return
	enemy_instance = ENEMY_SCENE.instantiate()
	add_child(enemy_instance)
	var enemy_index = horizontal_grid.size() - 1
	var enemy_cell = horizontal_grid[enemy_index]
	var center_offset = Vector2(cell_width / 2.0, cell_height / 2.0)
	enemy_instance.call("setup_position", enemy_cell["position"] + center_offset, enemy_index)
	enemy_instance.z_index = 10
	enemy_cell["occupied_by"] = enemy_instance

func spawn_enemies(count: int) -> void:
	var max_allowed = int(cell_count / 2.0)
	if count > max_allowed:
		print("Attention : Nombre d'ennemis trop élevé (Max autorisé : ", max_allowed, "). Ajusté à ", max_allowed)
		count = max_allowed
	var free_cells: Array = []
	for cell in horizontal_grid:
		if cell["occupied_by"] == null:
			free_cells.append(cell)
	var spawned_count = 0
	for i in range(free_cells.size() - 1, -1, -1):
		if spawned_count >= count:
			break
		var target_cell = free_cells[i]
		var new_enemy = ENEMY_SCENE.instantiate()
		if new_enemy == null:
			continue
		add_child(new_enemy)
		new_enemy.z_index = 10
		var actor_offset = Vector2(cell_width / 2.0, -10)
		new_enemy.call("setup_position", target_cell["position"] + actor_offset, target_cell["index"])
		target_cell["occupied_by"] = new_enemy
		enemies.append(new_enemy)
		new_enemy.call("plan_next_action", player_instance)
		spawned_count += 1
		
func _draw() -> void:
	for cell in horizontal_grid:
		var rect = Rect2(cell["position"], Vector2(cell_width, cell_height))
		var occupant = cell["occupied_by"]
		var fill_color = Color(0.15, 0.15, 0.2)
		var border_color = Color(0.4, 0.4, 0.5)
		var border_thickness = 2.0
		if is_instance_valid(occupant):
			if occupant == player_instance:
				#fill_color = Color(0.1, 0.4, 0.6, 0.8)
				#border_color = Color(0.3, 0.8, 1.0)
				border_thickness = 3.5
			else:
				#fill_color = Color(0.6, 0.15, 0.15, 0.8)
				#border_color = Color(1.0, 0.3, 0.3)
				border_thickness = 3.5
		draw_rect(rect, fill_color, true)
		draw_rect(rect, border_color, false, border_thickness)
		draw_string(ThemeDB.fallback_font, cell["position"] + Vector2(5, 18), str(cell["index"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.3))
	if is_instance_valid(player_instance):
		var p_hp = player_instance.get("health")
		var p_pos = player_instance.global_position + Vector2(-20, -cell_height / 2.0 - 10)
		draw_string(ThemeDB.fallback_font, p_pos, "PV: " + str(p_hp), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.CYAN)
	for enemy in enemies:
		if is_instance_valid(enemy):
			var e_hp = enemy.get("health")
			var e_pos = enemy.global_position + Vector2(-20, -cell_height / 2.0 - 10)
			draw_string(ThemeDB.fallback_font, e_pos, "PV: " + str(e_hp), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.RED)
	draw_string(ThemeDB.fallback_font, HAND_POS + Vector2(0, -15), "Main", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	for i in range(player_hand.size()):
		var tile = player_hand[i]
		var tile_rect = Rect2(HAND_POS + Vector2(i * TILE_SPACING, 0), Vector2(TILE_WIDTH, TILE_HEIGHT))
		draw_rect(tile_rect, tile.tile_color, true)
		draw_rect(tile_rect, Color.WHITE, false, 2.0)
		draw_string(ThemeDB.fallback_font, tile_rect.position + Vector2(5, 30), tile.tile_name, HORIZONTAL_ALIGNMENT_LEFT, 50, 14, Color.WHITE)
	draw_string(ThemeDB.fallback_font, QUEUE_POS + Vector2(0, -15), "En attente d'execution (Clic Droit)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	for i in range(action_queue.size()):
		var tile = action_queue[i]
		var queue_rect = Rect2(QUEUE_POS + Vector2(i * TILE_SPACING, 0), Vector2(TILE_WIDTH, TILE_HEIGHT))
		draw_rect(queue_rect, tile.tile_color, true)
		draw_rect(queue_rect, Color.YELLOW, false, 3.0)
		draw_string(ThemeDB.fallback_font, queue_rect.position + Vector2(5, 30), tile.tile_name, HORIZONTAL_ALIGNMENT_LEFT, 50, 14, Color.WHITE)
	draw_string(ThemeDB.fallback_font, COOLDOWN_POS + Vector2(0, -15), "Cooldown", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GRAY)
	for i in range(cooldown_list.size()):
		var tile = cooldown_list[i]
		var cd_rect = Rect2(COOLDOWN_POS + Vector2(i * TILE_SPACING, 0), Vector2(TILE_WIDTH, TILE_HEIGHT))
		draw_rect(cd_rect, tile.tile_color.darkened(0.6), true)
		draw_rect(cd_rect, Color.DARK_GRAY, false, 2.0)
		draw_string(ThemeDB.fallback_font, cd_rect.position + Vector2(5, 30), tile.tile_name, HORIZONTAL_ALIGNMENT_LEFT, 50, 12, Color.LIGHT_GRAY)
		draw_string(ThemeDB.fallback_font, cd_rect.position + Vector2(15, 60), "CD: " + str(tile.current_cooldown), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
		
func _input(event: InputEvent) -> void:
	if not is_instance_valid(player_instance):
		return
	var current_index = int(player_instance.get("current_cell_index"))
	if event.is_action_pressed("ui_left"):
		try_move_player(current_index - 1)
	elif event.is_action_pressed("ui_right"):
		try_move_player(current_index + 1)
	elif event.is_action_pressed("ui_accept"):
		player_instance.call("flip_direction")
		queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		execute_queue()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			execute_queue()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = event.position
			for i in range(player_hand.size() - 1, -1, -1):
				var tile_rect = Rect2(HAND_POS + Vector2(i * TILE_SPACING, 0), Vector2(TILE_WIDTH, TILE_HEIGHT))
				if tile_rect.has_point(mouse_pos):
					var selected_tile = player_hand[i]
					player_hand.remove_at(i)
					action_queue.append(selected_tile)
					queue_redraw()
					return
			for i in range(action_queue.size() - 1, -1, -1):
				var queue_rect = Rect2(QUEUE_POS + Vector2(i * TILE_SPACING, 0), Vector2(TILE_WIDTH, TILE_HEIGHT))
				if queue_rect.has_point(mouse_pos):
					var cancelled_tile = action_queue[i]
					action_queue.remove_at(i)
					player_hand.append(cancelled_tile)
					queue_redraw()
					return

# logique du swap de position
func try_move_player(target_index: int) -> void:
	if target_index < 0 or target_index >= horizontal_grid.size():
		return
	clean_grid_occupants()
	var target_cell = horizontal_grid[target_index]
	var occupant_before_turn = target_cell["occupied_by"]
	var enemy_on_target_before: Node2D = null
	if is_instance_valid(occupant_before_turn) and occupant_before_turn != player_instance:
		enemy_on_target_before = occupant_before_turn
	# invulnerabilite
	if is_instance_valid(player_instance):
		player_instance.set("is_invulnerable_this_turn", false)
		# swap/faufilage
		if enemy_on_target_before != null and is_instance_valid(enemy_on_target_before):
			player_instance.set("is_invulnerable_this_turn", true)
			print("Swap détecté : Le joueur est invulnérable pour ce tour !")
	# attaque enemie
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.call("execute_prepared_action", self, player_instance)
	clean_grid_occupants()
	if is_instance_valid(player_instance):
		var current_index = int(player_instance.get("current_cell_index"))
		var current_cell = horizontal_grid[current_index]
		var actor_offset = Vector2(cell_width / 2.0, -10)
		if enemy_on_target_before != null and is_instance_valid(enemy_on_target_before):
			var occupant = enemy_on_target_before
			var occupant_size = int(occupant.get("boss_size")) if "boss_size" in occupant else 1
			var occupant_start_index = int(occupant.get("current_cell_index"))
			var movement_dir = target_index - current_index 
			if occupant_size == 1:
				var behind_enemy_index = occupant_start_index + movement_dir
				var is_behind_free = false
				if behind_enemy_index >= 0 and behind_enemy_index < horizontal_grid.size():
					is_behind_free = (horizontal_grid[behind_enemy_index]["occupied_by"] == null)
				if is_behind_free:
					var behind_cell = horizontal_grid[behind_enemy_index]
					current_cell["occupied_by"] = null
					behind_cell["occupied_by"] = player_instance
					player_instance.call("move_to", behind_cell["position"] + actor_offset, behind_enemy_index)
					print("Faufilage : Le joueur s'est faufilé derrière l'ennemi !")
				else:
					current_cell["occupied_by"] = occupant
					occupant.call("setup_position", current_cell["position"] + actor_offset, current_index, cell_count)
					target_cell["occupied_by"] = player_instance
					player_instance.call("move_to", target_cell["position"] + actor_offset, target_index)
					print("Swap Sandwich : Échange de position avec l'ennemi direct !")
			else:
				var new_boss_index = occupant_start_index - movement_dir
				var player_new_index = 0
				if movement_dir > 0:
					player_new_index = occupant_start_index + occupant_size - 1
				else:
					player_new_index = occupant_start_index
				if player_new_index >= 0 and player_new_index < horizontal_grid.size() and new_boss_index >= 0 and (new_boss_index + occupant_size) <= horizontal_grid.size():
					current_cell["occupied_by"] = null
					var cell_width_val = float(cell_width)
					var boss_offset = Vector2((cell_width_val * occupant_size) / 2.0, -10.0)
					var new_boss_cell = horizontal_grid[new_boss_index]
					occupant.call("setup_position", new_boss_cell["position"] + boss_offset, new_boss_index, cell_count)
					var target_swap_cell = horizontal_grid[player_new_index]
					target_swap_cell["occupied_by"] = player_instance
					player_instance.call("move_to", target_swap_cell["position"] + actor_offset, player_new_index)
					print("Vrai Swap Boss ajusté : Atterrissage du joueur reculé de 1 case !")
				else:
					print("Swap Boss impossible : le boss ou le joueur sortirait de la grille.")
		else:
			if target_cell["occupied_by"] != null and target_cell["occupied_by"] != player_instance:
				print("Bloqué : Un ennemi vient de prendre cette case pendant son mouvement !")
			else:
				current_cell["occupied_by"] = null
				target_cell["occupied_by"] = player_instance
				player_instance.call("move_to", target_cell["position"] + actor_offset, target_index)
	clean_grid_occupants()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.call("plan_next_action", player_instance)
	tick_cooldowns()
	queue_redraw()
	
func setup_deck() -> void:
	player_hand.clear()
	action_queue.clear()
	cooldown_list.clear()
	if books != null:
		var words = books.get_words()
		for word in words:
			var cd = word.cooldown
			if cd <= 0:
				cd = 2
			player_hand.append(ActionTile.new(word.name, Color.RED, word.damage, word.range, cd))
	while player_hand.size() < 3:
		var extra_id = player_hand.size() + 1
		player_hand.append(ActionTile.new("Attaque " + str(extra_id), Color.DODGER_BLUE, 1, 1, 2))
	queue_redraw()

# gestion des action
func execute_queue() -> void:
	if action_queue.is_empty():
		return
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.call("execute_prepared_action", self, player_instance)
	var executing_tiles = action_queue.duplicate()
	action_queue.clear()
	for tile in executing_tiles:
		var player_index = int(player_instance.get("current_cell_index"))
		var facing = int(player_instance.get("facing_direction"))
		var hit_any_enemy = false
		for enemy in enemies:
			if is_instance_valid(enemy):
				var enemy_index = int(enemy.get("current_cell_index"))
				var enemy_size = int(enemy.get("boss_size")) if "boss_size" in enemy else 1
				var is_hit = false
				if facing == 1:
					for i in range(enemy_size):
						var target_cell_idx = enemy_index + i
						var distance = target_cell_idx - player_index
						if distance > 0 and distance <= tile.range_distance:
							is_hit = true
							break
				else:
					for i in range(enemy_size):
						var target_cell_idx = enemy_index + i
						var distance = player_index - target_cell_idx
						if distance > 0 and distance <= tile.range_distance:
							is_hit = true
							break
				if is_hit:
					enemy.call("take_damage", tile.damage)
					print(tile.tile_name, " (Portée: ", tile.range_distance, ") inflige ", tile.damage, " dégâts à l'entité !")
					hit_any_enemy = true
		if not hit_any_enemy:
			print(tile.tile_name, " rate sa cible (aucun ennemi à portée).")
		if tile.cooldown_max > 0:
			tile.current_cooldown = tile.cooldown_max
			cooldown_list.append(tile)
			print(tile.tile_name, " part en cooldown pour ", tile.current_cooldown, " tours.")
		else:
			player_hand.append(tile)
	clean_grid_occupants()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.call("plan_next_action", player_instance)
	tick_cooldowns()
	queue_redraw()

func tick_cooldowns() -> void:
	clean_grid_occupants()
	var i = cooldown_list.size() - 1
	while i >= 0:
		var tile = cooldown_list[i]
		tile.current_cooldown -= 1
		if tile.current_cooldown <= 0:
			tile.current_cooldown = 0
			player_hand.append(tile)
			cooldown_list.remove_at(i)
		i -= 1

# degager les enemies mort
func clean_grid_occupants() -> void:
	for cell in horizontal_grid:
		cell["occupied_by"] = null
	for i in range(enemies.size() - 1, -1, -1):
		if not is_instance_valid(enemies[i]):
			enemies.remove_at(i)
	if is_instance_valid(player_instance):
		var p_idx = int(player_instance.get("current_cell_index"))
		if p_idx >= 0 and p_idx < horizontal_grid.size():
			horizontal_grid[p_idx]["occupied_by"] = player_instance
	for enemy in enemies:
		if is_instance_valid(enemy):
			var e_idx = int(enemy.get("current_cell_index"))
			var size = 1
			if "boss_size" in enemy:
				size = int(enemy.get("boss_size"))
			for i in range(size):
				var target_idx = e_idx + i
				if target_idx >= 0 and target_idx < horizontal_grid.size():
					horizontal_grid[target_idx]["occupied_by"] = enemy

func spawn_boss() -> void:
	if horizontal_grid.is_empty() or BOSS_SCENE == null:
		print("Erreur : Impossible de charger BOSS_SCENE.")
		return
	var boss_instance = BOSS_SCENE.instantiate()
	if boss_instance == null:
		return
	add_child(boss_instance)
	boss_instance.z_index = 10
	var boss_size = boss_instance.get("boss_size")
	if boss_size == null:
		boss_size = 2
	var start_index = cell_count - boss_size
	if start_index <= 0:
		start_index = 1
	var target_cell = horizontal_grid[start_index]
	var cell_width_val = float(cell_width)
	var actor_offset = Vector2((cell_width_val * boss_size) / 2.0, -10.0)
	boss_instance.call("setup_position", target_cell["position"] + actor_offset, start_index, cell_count)
	for i in range(boss_size):
		if start_index + i < horizontal_grid.size():
			horizontal_grid[start_index + i]["occupied_by"] = boss_instance
	enemies.append(boss_instance)
	boss_instance.call("plan_next_action", player_instance)
	print("Boss apparu sur la case ", start_index, " (Taille : ", boss_size, " cases) !")
