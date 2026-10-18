extends Node2D
@export var cell_count: int = 6
@export var cell_width: int = 64
@export var cell_height: int = 64
@export var start_position: Vector2 = Vector2(100, 200)
const PLAYER_SCENE = preload("res://Scene/player.tscn")
const ENEMY_SCENE = preload("res://Scene/Enemy/enemy.tscn")
var horizontal_grid: Array = []
var player_instance: Node2D = null
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
enum Step {
	MOVE_RIGHT_LEFT, 
	ATTACK_CAC,      
	SWAP_ENEMY,      
	ATTACK_DIST,     
	KILL_ENEMY,      
	COMPLETED        
}
var current_step: Step = Step.MOVE_RIGHT_LEFT
var move_right_done: bool = false
@onready var instruction_label: Label = $UI_Tutorial/InstructionLabel if has_node("UI_Tutorial/InstructionLabel") else null
func _ready() -> void:
	generate_grid()
	spawn_player()
	setup_step(Step.MOVE_RIGHT_LEFT)

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
	if PLAYER_SCENE == null: return
	player_instance = PLAYER_SCENE.instantiate()
	add_child(player_instance)
	player_instance.z_index = 10
	move_player_to(0)

# Configuration de chaque étape
func setup_step(step: Step) -> void:
	current_step = step
	clear_enemies()
	player_hand.clear()
	action_queue.clear()
	cooldown_list.clear()
	var msg = ""
	match step:
		Step.MOVE_RIGHT_LEFT:
			msg = "TUTO (1/5) : Appuyez sur [DROITE] pour avancer, puis sur [GAUCHE] pour reculer."
			move_player_to(0)
			move_right_done = false
		Step.ATTACK_CAC:
			msg = "TUTO (2/5) : Cliquez sur la carte 'Attaque CAC' (portée 1) puis Clic Droit pour frapper !"
			move_player_to(1)
			spawn_enemy_at(2, 5)
			player_hand.append(ActionTile.new("Attaque CAC", Color.DODGER_BLUE, 1, 1, 1))
		Step.SWAP_ENEMY:
			msg = "TUTO (3/5) : L'ennemi attaque ! Avancez sur lui [DROITE] pour Swapper et passer derrière."
			move_player_to(1)
			spawn_enemy_at(2, 5)
		Step.ATTACK_DIST:
			msg = "TUTO (4/5) : L'ennemi est loin ! Utilisez 'Tir Distant' (portée 3) pour le toucher."
			move_player_to(0)
			spawn_enemy_at(3, 5)
			player_hand.append(ActionTile.new("Tir Distant", Color.ORANGE, 1, 3, 1))
		Step.KILL_ENEMY:
			msg = "TUTO (5/5) : L'ennemi n'a plus que 1 PV ! Utilisez votre carte pour le tuer."
			move_player_to(0)
			spawn_enemy_at(2, 1)
			player_hand.append(ActionTile.new("Coup Final", Color.RED, 1, 2, 1))
		Step.COMPLETED:
			msg = "TUTORIEL TERMINÉ ! Appuyez sur [ENTRÉE] pour commencer le jeu."
	if instruction_label != null:
		instruction_label.text = msg
	else:
		print("\n=========================")
		print(msg)
		print("=========================\n")
	queue_redraw()

# input et blocage
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
					var tile_rect = Rect2(HAND_POS + Vector2(i * TILE_SPACING, 0), Vector2(TILE_WIDTH, TILE_HEIGHT))
					if tile_rect.has_point(mouse_pos):
						var tile = player_hand[i]
						player_hand.remove_at(i)
						action_queue.append(tile)
						queue_redraw()
						return
	elif current_step == Step.SWAP_ENEMY:
		if event.is_action_pressed("ui_right"):
			try_move_player(current_index + 1)
			if int(player_instance.get("current_cell_index")) >= 2:
				setup_step(Step.ATTACK_DIST)
		else:
			print("Action bloquée : Avancez sur l'ennemi avec [DROITE] pour Swapper !")

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
		setup_step(Step.SWAP_ENEMY)
	elif current_step == Step.ATTACK_DIST and enemy_hit:
		setup_step(Step.KILL_ENEMY)
	elif current_step == Step.KILL_ENEMY:
		if enemies.is_empty():
			setup_step(Step.COMPLETED)
		else:
			player_hand.append(ActionTile.new("Coup Final", Color.RED, 1, 2, 1))

# Déplacement du joueur
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
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.call("execute_prepared_action", self, player_instance)
	clean_grid_occupants()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.call("plan_next_action", player_instance)
	queue_redraw()

# Nettoyage de la grille
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
			var size = int(enemy.get("boss_size")) if "boss_size" in enemy else 1
			for i in range(size):
				var target_idx = e_idx + i
				if target_idx >= 0 and target_idx < horizontal_grid.size():
					horizontal_grid[target_idx]["occupied_by"] = enemy

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

# Dessin de l'interface et des cartes
func _draw() -> void:
	for cell in horizontal_grid:
		var rect = Rect2(cell["position"], Vector2(cell_width, cell_height))
		var occupant = cell["occupied_by"]
		var fill_color = Color(0.15, 0.15, 0.2)
		var border_color = Color(0.4, 0.4, 0.5)
		var border_thickness = 2.0
		if is_instance_valid(occupant):
			if occupant == player_instance:
				fill_color = Color(0.1, 0.4, 0.6, 0.8)
				border_color = Color(0.3, 0.8, 1.0)
				border_thickness = 3.5
			else:
				fill_color = Color(0.6, 0.15, 0.15, 0.8)
				border_color = Color(1.0, 0.3, 0.3)
				border_thickness = 3.5
		draw_rect(rect, fill_color, true)
		draw_rect(rect, border_color, false, border_thickness)
		draw_string(ThemeDB.fallback_font, cell["position"] + Vector2(5, 18), str(cell["index"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.3))
	if current_step in [Step.ATTACK_CAC, Step.ATTACK_DIST, Step.KILL_ENEMY]:
		draw_string(ThemeDB.fallback_font, HAND_POS + Vector2(0, -15), "Main", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		for i in range(player_hand.size()):
			var tile = player_hand[i]
			var tile_rect = Rect2(HAND_POS + Vector2(i * TILE_SPACING, 0), Vector2(TILE_WIDTH, TILE_HEIGHT))
			draw_rect(tile_rect, tile.tile_color, true)
			draw_rect(tile_rect, Color.WHITE, false, 2.0)
			draw_string(ThemeDB.fallback_font, tile_rect.position + Vector2(5, 30), tile.tile_name, HORIZONTAL_ALIGNMENT_LEFT, 50, 14, Color.WHITE)
		draw_string(ThemeDB.fallback_font, QUEUE_POS + Vector2(0, -15), "En attente (Clic Droit)", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
		for i in range(action_queue.size()):
			var tile = action_queue[i]
			var queue_rect = Rect2(QUEUE_POS + Vector2(i * TILE_SPACING, 0), Vector2(TILE_WIDTH, TILE_HEIGHT))
			draw_rect(queue_rect, tile.tile_color, true)
			draw_rect(queue_rect, Color.YELLOW, false, 3.0)
			draw_string(ThemeDB.fallback_font, queue_rect.position + Vector2(5, 30), tile.tile_name, HORIZONTAL_ALIGNMENT_LEFT, 50, 14, Color.WHITE)
