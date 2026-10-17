extends Node2D
@export var cell_count: int = 6
@export var cell_width: int = 64
@export var cell_height: int = 64
@export var start_position: Vector2 = Vector2(100, 200)
var books : Bookstats

const PLAYER_SCENE = preload("res://Scene/player.tscn")
var horizontal_grid: Array = []
var player_instance: Node2D = null
var player_hand: Array[ActionTile] = []
var action_queue: Array[ActionTile] = []
const TILE_WIDTH = 60
const TILE_HEIGHT = 80
const TILE_SPACING = 70
const HAND_POS = Vector2(100, 400)
const QUEUE_POS = Vector2(100, 540)

func _ready() -> void:
	generate_grid()
	spawn_player()
	setup_deck()
	
func generate_grid() -> void:
	horizontal_grid.clear()
	for i in range(cell_count):
		var cell_pos = start_position + Vector2(i * cell_width, 0)
		var cell_data = {
			"id": "col_" + str(i),          
			"position": cell_pos,           
			"index": i,                    
			"occupied_by": null             
		}
		horizontal_grid.append(cell_data)

func _draw() -> void:
	for cell in horizontal_grid:
		var rect = Rect2(cell["position"], Vector2(cell_width, cell_height))
		draw_rect(rect, Color(0.2, 0.2, 0.3), true)
		draw_rect(rect, Color(0.8, 0.8, 0.8), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(100, 380), "", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	for i in range(player_hand.size()):
		var tile = player_hand[i]
		var tile_rect = Rect2(Vector2(100 + (i * 70), 400), Vector2(60, 80))
		draw_rect(tile_rect, tile.tile_color, true)
		draw_rect(tile_rect, Color.WHITE, false, 2.0)
		draw_string(ThemeDB.fallback_font, tile_rect.position + Vector2(5, 30), tile.tile_name, HORIZONTAL_ALIGNMENT_LEFT, 50, 14, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(100, 520), "", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	for i in range(action_queue.size()):
		var tile = action_queue[i]
		var queue_rect = Rect2(Vector2(100 + (i * 70), 540), Vector2(60, 80))
		draw_rect(queue_rect, tile.tile_color, true)
		draw_rect(queue_rect, Color.YELLOW, false, 3.0)
		draw_string(ThemeDB.fallback_font, queue_rect.position + Vector2(5, 30), tile.tile_name, HORIZONTAL_ALIGNMENT_LEFT, 50, 14, Color.WHITE)
		
func get_cell_by_id(id: String) -> Dictionary:
	for cell in horizontal_grid:
		if cell["id"] == id:
			return cell
	return {}

func get_cell_by_index(index: int) -> Dictionary:
	if index >= 0 and index < horizontal_grid.size():
		return horizontal_grid[index]
	return {}

func spawn_player() -> void:
	if horizontal_grid.is_empty():
		return
	player_instance = PLAYER_SCENE.instantiate()
	add_child(player_instance)
	books = player_instance.stats.book
	player_instance.z_index = 10
	var first_cell = horizontal_grid[0]
	var center_offset = Vector2(cell_width / 2.0, cell_height / 2.0)
	player_instance.setup_position(first_cell["position"] + center_offset)

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
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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

func setup_deck() -> void:
	for word in books.word_stats:
		player_hand.append(ActionTile.new(word.name,Color.RED, word.damage, word.range, word.cooldown))
