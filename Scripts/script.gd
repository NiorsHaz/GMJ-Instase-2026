extends Node2D
@export var cell_count: int = 6
@export var cell_width: int = 64
@export var cell_height: int = 64
@export var start_position: Vector2 = Vector2(100, 200)
var books: Bookstats
const PLAYER_SCENE = preload("res://Scene/player.tscn")
const ENEMY_SCENE = preload("res://Scene/Enemy/enemy.tscn")
var horizontal_grid: Array = []
var player_instance: Node2D = null
var enemy_instance: Node2D = null
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
	generate_grid()
	spawn_player()
	spawn_enemy()
	setup_deck()

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
	player_instance = PLAYER_SCENE.instantiate()
	add_child(player_instance)
	var player_stats = player_instance.get("stats")
	if player_stats != null:
		books = player_stats.get("book")
	player_instance.z_index = 10
	var first_cell = horizontal_grid[0]
	var center_offset = Vector2(
		cell_width / 2.0,
		cell_height / 2.0
	)
	player_instance.call(
		"setup_position",
		first_cell["position"] + center_offset
	)
	first_cell["occupied_by"] = player_instance

func spawn_enemy() -> void:
	if horizontal_grid.size() < 2:
		return
	enemy_instance = ENEMY_SCENE.instantiate()
	add_child(enemy_instance)
	var enemy_index = horizontal_grid.size() - 1
	var enemy_cell = horizontal_grid[enemy_index]
	var center_offset = Vector2(
		cell_width / 2.0,
		cell_height / 2.0
	)
	enemy_instance.call(
		"setup_position",
		enemy_cell["position"] + center_offset,
		enemy_index
	)
	enemy_instance.z_index = 10
	enemy_cell["occupied_by"] = enemy_instance

func _draw() -> void:
	for cell in horizontal_grid:
		var rect = Rect2(
			cell["position"],
			Vector2(cell_width, cell_height)
		)
		draw_rect(rect, Color(0.2, 0.2, 0.3), true)
		draw_rect(rect, Color(0.8, 0.8, 0.8), false, 2.0)
	draw_string(
		ThemeDB.fallback_font,
		HAND_POS + Vector2(0, -15),
		"Main",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.WHITE
	)
	for i in range(player_hand.size()):
		var tile = player_hand[i]
		var tile_rect = Rect2(
			HAND_POS + Vector2(i * TILE_SPACING, 0),
			Vector2(TILE_WIDTH, TILE_HEIGHT)
		)
		draw_rect(tile_rect, tile.tile_color, true)
		draw_rect(tile_rect, Color.WHITE, false, 2.0)
		draw_string(
			ThemeDB.fallback_font,
			tile_rect.position + Vector2(5, 30),
			tile.tile_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			50,
			14,
			Color.WHITE
		)
	draw_string(
		ThemeDB.fallback_font,
		QUEUE_POS + Vector2(0, -15),
		"En attente d'execution",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.YELLOW
	)
	for i in range(action_queue.size()):
		var tile = action_queue[i]
		var queue_rect = Rect2(
			QUEUE_POS + Vector2(i * TILE_SPACING, 0),
			Vector2(TILE_WIDTH, TILE_HEIGHT)
		)
		draw_rect(queue_rect, tile.tile_color, true)
		draw_rect(queue_rect, Color.YELLOW, false, 3.0)
		draw_string(
			ThemeDB.fallback_font,
			queue_rect.position + Vector2(5, 30),
			tile.tile_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			50,
			14,
			Color.WHITE
		)
	draw_string(
		ThemeDB.fallback_font,
		COOLDOWN_POS + Vector2(0, -15),
		"Cooldown",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.GRAY
	)
	for i in range(cooldown_list.size()):
		var tile = cooldown_list[i]
		var cd_rect = Rect2(
			COOLDOWN_POS + Vector2(i * TILE_SPACING, 0),
			Vector2(TILE_WIDTH, TILE_HEIGHT)
		)
		draw_rect(
			cd_rect,
			tile.tile_color.darkened(0.6),
			true
		)
		draw_rect(
			cd_rect,
			Color.DARK_GRAY,
			false,
			2.0
		)
		draw_string(
			ThemeDB.fallback_font,
			cd_rect.position + Vector2(5, 30),
			tile.tile_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			50,
			12,
			Color.LIGHT_GRAY
		)
		draw_string(
			ThemeDB.fallback_font,
			cd_rect.position + Vector2(15, 60),
			"CD: " + str(tile.current_cooldown),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			Color.YELLOW
		)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(player_instance):
		return
	var current_index = int(
		player_instance.get("current_cell_index")
	)
	if event.is_action_pressed("ui_left"):
		try_move_player(current_index - 1)
	elif event.is_action_pressed("ui_right"):
		try_move_player(current_index + 1)
	elif event.is_action_pressed("ui_accept"):
		player_instance.call("flip_direction")
	elif (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_E
	):
		execute_queue()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			execute_queue()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = event.position
			for i in range(player_hand.size()):
				var tile_rect = Rect2(
					HAND_POS + Vector2(i * TILE_SPACING, 0),
					Vector2(TILE_WIDTH, TILE_HEIGHT)
				)
				if tile_rect.has_point(mouse_pos):
					var selected_tile = player_hand[i]
					player_hand.remove_at(i)
					action_queue.append(selected_tile)
					queue_redraw()
					return
			for i in range(action_queue.size()):
				var queue_rect = Rect2(
					QUEUE_POS + Vector2(i * TILE_SPACING, 0),
					Vector2(TILE_WIDTH, TILE_HEIGHT)
				)
				if queue_rect.has_point(mouse_pos):
					var cancelled_tile = action_queue[i]
					action_queue.remove_at(i)
					player_hand.append(cancelled_tile)
					queue_redraw()
					return

func try_move_player(target_index: int) -> void:
	if target_index < 0 or target_index >= horizontal_grid.size():
		return
	if is_instance_valid(enemy_instance):
		var enemy_index = int(
			enemy_instance.get("current_cell_index")
		)
		if target_index == enemy_index:
			return
	var target_cell = horizontal_grid[target_index]
	var center_offset = Vector2(
		cell_width / 2.0,
		cell_height / 2.0
	)
	player_instance.call(
		"move_to",
		target_cell["position"] + center_offset,
		target_index
	)
	target_cell["occupied_by"] = player_instance
	for cell in horizontal_grid:
		if cell["occupied_by"] == player_instance:
			cell["occupied_by"] = null
	target_cell["occupied_by"] = player_instance
	advance_turn()

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
			player_hand.append(
				ActionTile.new(
					word.name,
					Color.RED,
					word.damage,
					word.range,
					word.cooldown
				)
			)
	while player_hand.size() < 3:
		var extra_id = player_hand.size() + 1
		player_hand.append(
			ActionTile.new(
				"A" + str(extra_id),
				Color.DODGER_BLUE,
				1,
				1,
				2
			)
		)
	queue_redraw()

func execute_queue() -> void:
	if action_queue.is_empty():
		return
	for tile in action_queue:
		if is_instance_valid(enemy_instance):
			var enemy_index = int(
				enemy_instance.get("current_cell_index")
			)
			var player_index = int(
				player_instance.get("current_cell_index")
			)
			var distance = abs(enemy_index - player_index)
			if distance <= tile.range_distance:
				enemy_instance.call("take_damage", tile.damage)
				print(
					tile.tile_name,
					" dealt ",
					tile.damage,
                    " damage!"
				)
			else:
				print(
					tile.tile_name,
					" is out of range! Distance: ",
					distance
				)
		if tile.cooldown_max > 0:
			tile.start_cooldown()
			cooldown_list.append(tile)
		else:
			player_hand.append(tile)
	action_queue.clear()
	queue_redraw()

func advance_turn() -> void:
	var i = cooldown_list.size() - 1
	while i >= 0:
		var tile = cooldown_list[i]
		tile.current_cooldown -= 1
		if tile.current_cooldown <= 0:
			tile.current_cooldown = 0
			player_hand.append(tile)
			cooldown_list.remove_at(i)
		i -= 1
	queue_redraw()

	# Enemy takes its turn after the player's action.
	if is_instance_valid(enemy_instance):
		enemy_instance.take_turn(self, player_instance)
