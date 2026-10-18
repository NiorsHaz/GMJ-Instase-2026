extends Node2D
@export var cell_count: int = 6
@export var cell_width: int = 82
@export var cell_height: int = 32
var start_position: Vector2
var books: Bookstats
const PLAYER_SCENE = preload("res://Scene/player.tscn")
const ENEMY_SCENE = preload("res://Scene/Enemy/enemy.tscn")
const BOSS_SCENE = preload("res://Scene/boss.tscn")
var horizontal_grid: Array = []
var player_instance: Node2D = null
var enemies: Array = []
var player_hand: Array[ActionTile] = []
var action_queue: Array[ActionTile] = []
var cooldown_list: Array[ActionTile] = []
# ---------------------------------------------------------------
# LAYOUT
# ---------------------------------------------------------------
const GRID_Y := 0.705
const PLAYER_HEARTS_Y := 0.92
const PLAYER_HEART_SIZE := 0.062
const PLAYER_HEART_GAP := 0.007
const HAND_X := 0.924
const HAND_Y := 0.221
const HAND_TILE := 0.105
const HAND_STEP := 0.131
const HAND_SLOTS := 4
const QUEUE_X := 0.26
const QUEUE_Y := 0.422
const QUEUE_TILE := 0.045
const QUEUE_STEP := 0.05
const QUEUE_SLOTS := 3
const COOLDOWN_X := 0.022
const COOLDOWN_Y := 0.275
const COOLDOWN_TILE := 0.088
const COOLDOWN_STEP := 0.099
const COOLDOWN_SLOTS := 4
const DEFAULT_MAX_HP := 10
const ENEMY_HEART_SIZE := 10.0
const ENEMY_HEART_GAP := 2.0
# ---------------------------------------------------------------
# ÉTAPES DU TUTORIEL
# ---------------------------------------------------------------
enum Step {
	MOVE_RIGHT_LEFT, 
	ATTACK_CAC,      
	SWAP,            
	ATTACK_DIST,     
	KILL_ENEMY,      
	COMPLETED        
}
var current_step: Step = Step.MOVE_RIGHT_LEFT
var move_right_done: bool = false
var tutorial_message: String = ""

func _ready() -> void:
	_update_layout()
	get_viewport().size_changed.connect(_update_layout)
	generate_grid()
	spawn_player()
	setup_step(Step.MOVE_RIGHT_LEFT)
# ---------------------------------------------------------------
# LAYOUT HELPERS
# ---------------------------------------------------------------
func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size

func _update_layout() -> void:
	var vp = _screen()
	var new_start = Vector2((vp.x - cell_count * cell_width) / 2.0, vp.y * GRID_Y)
	var delta = new_start - start_position
	start_position = new_start
	if not horizontal_grid.is_empty() and delta != Vector2.ZERO:
		for cell in horizontal_grid:
			cell["position"] += delta
		if is_instance_valid(player_instance):
			player_instance.global_position += delta
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.global_position += delta
	queue_redraw()

func _column_rect(i: int, x_ratio: float, y_ratio: float, tile_ratio: float, step_ratio: float) -> Rect2:
	var vp = _screen()
	var tile = vp.y * tile_ratio
	var pos = Vector2(vp.x * x_ratio, vp.y * y_ratio + i * vp.y * step_ratio)
	return Rect2(pos, Vector2(tile, tile))

func _hand_rect(i: int) -> Rect2:
	return _column_rect(i, HAND_X, HAND_Y, HAND_TILE, HAND_STEP)

func _queue_rect(i: int) -> Rect2:
	return _column_rect(i, QUEUE_X, QUEUE_Y, QUEUE_TILE, QUEUE_STEP)

func _cooldown_rect(i: int) -> Rect2:
	return _column_rect(i, COOLDOWN_X, COOLDOWN_Y, COOLDOWN_TILE, COOLDOWN_STEP)

func _font_for(tile: Rect2) -> int:
	return clampi(int(tile.size.y * 0.2), 8, 16)
# ---------------------------------------------------------------
# CONFIGURATION DES ÉTAPES
# ---------------------------------------------------------------
func setup_step(step: Step) -> void:
	current_step = step
	clear_enemies()
	player_hand.clear()
	action_queue.clear()
	cooldown_list.clear()
	match step:
		Step.MOVE_RIGHT_LEFT:
			tutorial_message = "TUTO (1/5) : Appuyez sur [DROITE] pour avancer, puis sur [GAUCHE] pour reculer."
			move_player_to(0)
			move_right_done = false
		Step.ATTACK_CAC:
			tutorial_message = "TUTO (2/5) : Cliquez sur 'Attaque CAC' puis faites Clic Droit pour frapper !"
			move_player_to(1)
			spawn_enemy_at(2, 5)
			player_hand.append(ActionTile.new("Attaque CAC", Color.DODGER_BLUE, 1, 1, 1))
		Step.SWAP:
			tutorial_message = "TUTO (3/5) : Avancez sur l'ennemi [DROITE] pour Swapper et passer derrière lui !"
			move_player_to(1)
			spawn_enemy_at(2, 5)
		Step.ATTACK_DIST:
			tutorial_message = "TUTO (4/5) : L'ennemi est loin ! Utilisez 'Tir Distant' (Portée 3)."
			move_player_to(0)
			spawn_enemy_at(3, 5)
			player_hand.append(ActionTile.new("Tir Distant", Color.ORANGE, 1, 3, 1))
		Step.KILL_ENEMY:
			tutorial_message = "TUTO (5/5) : L'ennemi n'a plus que 1 PV ! Utilisez votre carte pour l'achever."
			move_player_to(0)
			spawn_enemy_at(2, 1)
			player_hand.append(ActionTile.new("Coup Final", Color.RED, 1, 2, 1))
		Step.COMPLETED:
			tutorial_message = "TUTORIEL TERMINÉ ! Appuyez sur [ENTRÉE] pour lancer le jeu."
	queue_redraw()
# ---------------------------------------------------------------
# GRID / SPAWN
# ---------------------------------------------------------------
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
	if horizontal_grid.is_empty() or PLAYER_SCENE == null:
		return
	player_instance = PLAYER_SCENE.instantiate()
	add_child(player_instance)
	player_instance.z_index = 10
	move_player_to(0)

func move_player_to(index: int) -> void:
	if is_instance_valid(player_instance):
		var target_cell = horizontal_grid[index]
		var actor_offset = Vector2(cell_width / 2.0, -10)
		player_instance.call("setup_position", target_cell["position"] + actor_offset, index)
		clean_grid_occupants()

func spawn_enemy_at(index: int, hp: int) -> void:
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	enemy.z_index = 10
	var actor_offset = Vector2(cell_width / 2.0, -10)
	enemy.call("setup_position", horizontal_grid[index]["position"] + actor_offset, index)
	if "health" in enemy:
		enemy.set("health", hp)
	enemies.append(enemy)
	enemy.call("plan_next_action", player_instance)
	clean_grid_occupants()

func clear_enemies() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	clean_grid_occupants()
# ---------------------------------------------------------------
# DRAW
# ---------------------------------------------------------------
func _draw() -> void:
	var vp = _screen()
	var font = ThemeDB.fallback_font
	var title_size = clampi(int(vp.y * 0.032), 12, 22)
	var banner_rect = Rect2(Vector2(vp.x * 0.05, vp.y * 0.03), Vector2(vp.x * 0.9, vp.y * 0.08))
	draw_rect(banner_rect, Color(0.1, 0.1, 0.15, 0.85), true)
	draw_rect(banner_rect, Color(0.4, 0.6, 1.0), false, 2.5)
	draw_string(font, banner_rect.position + Vector2(10, banner_rect.size.y * 0.65), tutorial_message, HORIZONTAL_ALIGNMENT_CENTER, banner_rect.size.x - 20, title_size, Color.WHITE)
	for cell in horizontal_grid:
		var rect = Rect2(cell["position"], Vector2(cell_width, cell_height))
		var occupant = cell["occupied_by"]
		var fill_color = Color(0.15, 0.15, 0.2)
		var border_color = Color(0.4, 0.4, 0.5)
		var border_thickness = 2.0
		if is_instance_valid(occupant):
			border_thickness = 3.5
		draw_rect(rect, fill_color, true)
		draw_rect(rect, border_color, false, border_thickness)
		draw_string(font, cell["position"] + Vector2(5, 18), str(cell["index"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.3))
	for enemy in enemies:
		if is_instance_valid(enemy):
			var e_hp = int(enemy.get("health"))
			var e_max = _get_max_hp(enemy, e_hp)
			var head_pos = enemy.global_position + Vector2(0, -cell_height / 2.0 - 10 - ENEMY_HEART_SIZE)
			_draw_hearts(e_hp, e_max, head_pos.x, head_pos.y, ENEMY_HEART_SIZE, ENEMY_HEART_GAP, Color(0.9, 0.2, 0.3))
	if is_instance_valid(player_instance):
		var p_hp = int(player_instance.get("health"))
		var p_max = _get_max_hp(player_instance, p_hp)
		_draw_hearts(p_hp, p_max, vp.x / 2.0, vp.y * PLAYER_HEARTS_Y, vp.y * PLAYER_HEART_SIZE, vp.y * PLAYER_HEART_GAP, Color(0.9, 0.2, 0.3))
	if current_step in [Step.ATTACK_CAC, Step.ATTACK_DIST, Step.KILL_ENEMY]:
		for i in range(player_hand.size()):
			var tile = player_hand[i]
			var tile_rect = _hand_rect(i)
			draw_rect(tile_rect, tile.tile_color, true)
			draw_rect(tile_rect, Color.WHITE, false, 2.0)
			draw_string(font, tile_rect.position + Vector2(tile_rect.size.x * 0.08, tile_rect.size.y * 0.5), tile.tile_name, HORIZONTAL_ALIGNMENT_LEFT, tile_rect.size.x * 0.84, _font_for(tile_rect), Color.WHITE)
		for i in range(action_queue.size()):
			var tile = action_queue[i]
			var queue_rect = _queue_rect(i)
			draw_rect(queue_rect, tile.tile_color, true)
			draw_rect(queue_rect, Color.YELLOW, false, 2.0)
			draw_string(font, queue_rect.position + Vector2(queue_rect.size.x * 0.08, queue_rect.size.y * 0.65), tile.tile_name, HORIZONTAL_ALIGNMENT_LEFT, queue_rect.size.x * 0.84, _font_for(queue_rect), Color.WHITE)

func _draw_hearts(hp: int, max_hp: int, center_x: float, top_y: float, heart_size: float, gap: float, color: Color) -> void:
	var heart_count = ceili(max_hp / 2.0)
	if heart_count <= 0:
		return
	var total_width = heart_count * heart_size + (heart_count - 1) * gap
	var start_x = center_x - total_width / 2.0
	for i in range(heart_count):
		var pos = Vector2(start_x + i * (heart_size + gap), top_y)
		var heart_rect = Rect2(pos, Vector2(heart_size, heart_size))
		var hp_in_heart = clampi(hp - i * 2, 0, 2)
		draw_rect(heart_rect, Color(0.2, 0.2, 0.2), true)
		if hp_in_heart == 2:
			draw_rect(heart_rect, color, true)
		elif hp_in_heart == 1:
			draw_rect(Rect2(pos, Vector2(heart_size / 2.0, heart_size)), color, true)
		draw_rect(heart_rect, Color.WHITE, false, 1.0)

func _get_max_hp(actor: Node, current_hp: int) -> int:
	var m = actor.get("max_health")
	if m != null:
		return int(m)
	return maxi(current_hp, DEFAULT_MAX_HP)
# ---------------------------------------------------------------
# INPUTS & BLOCAGE STRICT
# ---------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if not is_instance_valid(player_instance):
		return
	var current_index = int(player_instance.get("current_cell_index"))
	if current_step == Step.COMPLETED:
		if event.is_action_pressed("ui_accept"):
			get_tree().change_scene_to_file("res://Scene/level.tscn")
		return
	if current_step == Step.MOVE_RIGHT_LEFT:
		if not move_right_done:
			if event.is_action_pressed("ui_right"):
				try_move_player(current_index + 1)
				if int(player_instance.get("current_cell_index")) == 1:
					move_right_done = true
			elif event.is_action_pressed("ui_left"):
				print("Action bloquée : Avancez d'abord avec [DROITE] !")
		else:
			if event.is_action_pressed("ui_left"):
				try_move_player(current_index - 1)
				if int(player_instance.get("current_cell_index")) == 0:
					setup_step(Step.ATTACK_CAC)
			elif event.is_action_pressed("ui_right"):
				print("Action bloquée : Reculez maintenant avec [GAUCHE] !")
	elif current_step in [Step.ATTACK_CAC, Step.ATTACK_DIST, Step.KILL_ENEMY]:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			print("Action bloquée : Pas de déplacement ! Utilisez vos cartes.")
			return
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
			execute_queue_tutorial()
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				execute_queue_tutorial()
			elif event.button_index == MOUSE_BUTTON_LEFT:
				var mouse_pos = event.position
				for i in range(player_hand.size() - 1, -1, -1):
					if _hand_rect(i).has_point(mouse_pos):
						var selected_tile = player_hand[i]
						player_hand.remove_at(i)
						action_queue.append(selected_tile)
						queue_redraw()
						return
				for i in range(action_queue.size() - 1, -1, -1):
					if _queue_rect(i).has_point(mouse_pos):
						var cancelled_tile = action_queue[i]
						action_queue.remove_at(i)
						player_hand.append(cancelled_tile)
						queue_redraw()
						return
	elif current_step == Step.SWAP:
		if event.is_action_pressed("ui_right"):
			try_move_player(current_index + 1)
			if int(player_instance.get("current_cell_index")) >= 2:
				setup_step(Step.ATTACK_DIST)
		else:
			print("Action bloquée : Avancez sur l'ennemi avec [DROITE] pour effectuer un Swap !")

func execute_queue_tutorial() -> void:
	if action_queue.is_empty():
		print("Action bloquée : Sélectionnez une carte d'abord !")
		return
	var executing_tiles = action_queue.duplicate()
	action_queue.clear()
	var enemy_hit = false
	for tile in executing_tiles:
		var p_idx = int(player_instance.get("current_cell_index"))
		for enemy in enemies:
			if is_instance_valid(enemy):
				var e_idx = int(enemy.get("current_cell_index"))
				var dist = e_idx - p_idx
				if dist > 0 and dist <= tile.range_distance:
					enemy.call("take_damage", tile.damage)
					enemy_hit = true
					print("Tuto : Ennemi touché !")
	clean_grid_occupants()
	if current_step == Step.ATTACK_CAC and enemy_hit:
		setup_step(Step.SWAP)
	elif current_step == Step.ATTACK_DIST and enemy_hit:
		setup_step(Step.KILL_ENEMY)
	elif current_step == Step.KILL_ENEMY:
		if enemies.is_empty():
			setup_step(Step.COMPLETED)
		else:
			player_hand.append(ActionTile.new("Coup Final", Color.RED, 1, 2, 1))
	queue_redraw()

func try_move_player(target_index: int) -> void:
	if target_index < 0 or target_index >= horizontal_grid.size():
		return
	clean_grid_occupants()
	var target_cell = horizontal_grid[target_index]
	var occupant_before = target_cell["occupied_by"]
	var enemy_on_target: Node2D = null
	if is_instance_valid(occupant_before) and occupant_before != player_instance:
		enemy_on_target = occupant_before
	if is_instance_valid(player_instance):
		var current_index = int(player_instance.get("current_cell_index"))
		var current_cell = horizontal_grid[current_index]
		var actor_offset = Vector2(cell_width / 2.0, -10)
		var movement_dir = target_index - current_index
		if enemy_on_target != null and is_instance_valid(enemy_on_target):
			var occupant = enemy_on_target
			var occupant_start_index = int(occupant.get("current_cell_index"))
			var behind_enemy_index = occupant_start_index + movement_dir
			var is_behind_free = false
			if behind_enemy_index >= 0 and behind_enemy_index < horizontal_grid.size():
				is_behind_free = (horizontal_grid[behind_enemy_index]["occupied_by"] == null)
			if is_behind_free:
				var behind_cell = horizontal_grid[behind_enemy_index]
				current_cell["occupied_by"] = null
				behind_cell["occupied_by"] = player_instance
				player_instance.call("move_to", behind_cell["position"] + actor_offset, behind_enemy_index)
			else:
				current_cell["occupied_by"] = occupant
				occupant.call("setup_position", current_cell["position"] + actor_offset, current_index, cell_count)
				target_cell["occupied_by"] = player_instance
				player_instance.call("move_to", target_cell["position"] + actor_offset, target_index)
		else:
			current_cell["occupied_by"] = null
			target_cell["occupied_by"] = player_instance
			player_instance.call("move_to", target_cell["position"] + actor_offset, target_index)
	clean_grid_occupants()
	queue_redraw()

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
