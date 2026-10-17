extends Node2D
@export var cell_count: int = 6
@export var cell_width: int = 64
@export var cell_height: int = 64
@export var start_position: Vector2 = Vector2(100, 200)
var books: Bookstats
const PLAYER_SCENE = preload("res://Scene/player.tscn")
var horizontal_grid: Array = []
var player_instance: Node2D = null
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
	if "stats" in player_instance and player_instance.stats:
		books = player_instance.stats.book
	player_instance.z_index = 10
	var first_cell = horizontal_grid[0]
	player_instance.setup_position(first_cell["position"] + Vector2(cell_width / 2.0, cell_height / 2.0))

func _draw() -> void:
	for cell in horizontal_grid:
		var rect = Rect2(cell["position"], Vector2(cell_width, cell_height))
		draw_rect(rect, Color(0.2, 0.2, 0.3), true)
		draw_rect(rect, Color(0.8, 0.8, 0.8), false, 2.0)
	draw_string(ThemeDB.fallback_font, HAND_POS + Vector2(0, -15), "main", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	for i in range(player_hand.size()):
		var tile = player_hand[i]
		var tile_rect = Rect2(HAND_POS + Vector2(i * TILE_SPACING, 0), Vector2(TILE_WIDTH, TILE_HEIGHT))
		draw_rect(tile_rect, tile.tile_color, true)
		draw_rect(tile_rect, Color.WHITE, false, 2.0)
		draw_string(ThemeDB.fallback_font, tile_rect.position + Vector2(5, 30), tile.tile_name, HORIZONTAL_ALIGNMENT_LEFT, 50, 14, Color.WHITE)
	draw_string(ThemeDB.fallback_font, QUEUE_POS + Vector2(0, -15), "en attente d'execution", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
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
	if not player_instance:
		return
	var current_index = player_instance.current_cell_index
	if event.is_action_pressed("ui_left"):
		try_move_player(current_index - 1)
	elif event.is_action_pressed("ui_right"):
		try_move_player(current_index + 1)
	elif event.is_action_pressed("ui_accept"):
		player_instance.flip_direction()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_E:
		execute_queue()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			execute_queue()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = event.position
			for i in range(player_hand.size()):
				var tile_rect = Rect2(HAND_POS + Vector2(i * TILE_SPACING, 0), Vector2(TILE_WIDTH, TILE_HEIGHT))
				if tile_rect.has_point(mouse_pos):
					var selected_tile = player_hand[i]
					player_hand.remove_at(i)
					action_queue.append(selected_tile)
					queue_redraw()
					return
			for i in range(action_queue.size()):
				var queue_rect = Rect2(QUEUE_POS + Vector2(i * TILE_SPACING, 0), Vector2(TILE_WIDTH, TILE_HEIGHT))
				if queue_rect.has_point(mouse_pos):
					var cancelled_tile = action_queue[i]
					action_queue.remove_at(i)
					player_hand.append(cancelled_tile)
					queue_redraw()
					return

func try_move_player(target_index: int) -> void:
	if target_index >= 0 and target_index < horizontal_grid.size():
		var target_cell = horizontal_grid[target_index]
		var center_offset = Vector2(cell_width / 2.0, cell_height / 2.0)
		player_instance.move_to(target_cell["position"] + center_offset, target_index)
		advance_turn()

func setup_deck() -> void:
	player_hand.clear()
	action_queue.clear()
	cooldown_list.clear()
	if books and books.word_stats and books.word_stats.size() > 0:
		for word in books.word_stats:
			var cd = word.cooldown if word.cooldown > 0 else 2
			player_hand.append(ActionTile.new(word.name, Color.RED, word.damage, word.range, cd))
	while player_hand.size() < 3:
		var extra_id = player_hand.size() + 1
		player_hand.append(ActionTile.new("A" + str(extra_id), Color.DODGER_BLUE, 1, 1, 2))
	queue_redraw()

func execute_queue() -> void:
	if action_queue.is_empty():
		return
	for tile in action_queue:
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
